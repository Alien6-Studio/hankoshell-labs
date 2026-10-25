#!/usr/bin/env bash
# Apache-2.0. Provider helpers adapted from hankoshell-operator examples/kind.
set -euo pipefail
umask 077
ASSETS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="${HANKOSHELL_LAB_STATE:-/root/.hankoshell-lab}"
CHART='oci://ghcr.io/alien6-studio/charts/hankoshell-operator@sha256:a044bdb46471f9383f5123f1ff48f8b3d8f2329aaedb45c61d9d73edde8af540'
OPERATOR_IMAGE='ghcr.io/alien6-studio/hankoshell-operator@sha256:ec9a186a44a465d02f6d3279d87b86e39b2ee1d26314a6d8d04ec78c3235fe28'
FORWARD_PID=""
die() { echo "Lab: $*" >&2; exit 1; }
k() { kubectl --kubeconfig "$STATE/kubeconfig" --context "$(cat "$STATE/context")" --request-timeout=30s -n auth "$@"; }
finish() {
  if [[ -n "$FORWARD_PID" ]]; then
    kill "$FORWARD_PID" 2>/dev/null || true
    wait "$FORWARD_PID" 2>/dev/null || true
  fi
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
check_api() {
  [[ -f "$STATE/cluster-uid" && -f "$STATE/auth-uid" ]] || die "Setup has not completed."
  [[ "$(k get namespace kube-system -o jsonpath='{.metadata.uid}')" == "$(cat "$STATE/cluster-uid")" ]] || die "Cluster identity changed."
  [[ "$(k get namespace auth -o jsonpath='{.metadata.uid}')" == "$(cat "$STATE/auth-uid")" ]] || die "Lab namespace changed."
}
forward() {
  check_api
  k port-forward service/keycloak :8443 --address 127.0.0.1 >"$STATE/forward.log" 2>&1 &
  FORWARD_PID=$!
  local deadline=$((SECONDS + 30)) port=""
  while [[ $SECONDS -lt $deadline ]]; do
    port="$(sed -n 's/^Forwarding from 127.0.0.1:\([0-9]*\) ->.*/\1/p' "$STATE/forward.log" | head -1)"
    if [[ -n "$port" ]]; then ENDPOINT="https://localhost:$port"; return; fi
    kill -0 "$FORWARD_PID" 2>/dev/null || die "Keycloak port-forward stopped."
    sleep 1
  done
  die "Keycloak port-forward timed out."
}
login() {
  curl --fail --silent --show-error --cacert "$STATE/ca.crt" --connect-timeout 5 --max-time 30 \
    --data-urlencode client_id=admin-cli --data-urlencode grant_type=password \
    --data-urlencode username=demo-admin --data-urlencode "password@$STATE/admin-password" \
    "$ENDPOINT/realms/master/protocol/openid-connect/token" >"$STATE/admin-token.json"
  jq -er '"header = \"Authorization: Bearer " + .access_token + "\""' \
    "$STATE/admin-token.json" >"$STATE/admin-curl.conf"
}
api() {
  local method=$1 path=$2 status
  shift 2
  status="$(curl --silent --show-error --cacert "$STATE/ca.crt" --connect-timeout 5 --max-time 30 \
    --config "$STATE/admin-curl.conf" --request "$method" --header 'Content-Type: application/json' \
    --output "$STATE/response.json" --write-out '%{http_code}' "$ENDPOINT$path" "$@")"
  [[ "$status" =~ ^20[0-9]$ ]] || die "Keycloak $method $path returned HTTP $status."
  cat "$STATE/response.json"
}
client() {
  api GET "/admin/realms/$1/clients?clientId=$2" |
    jq -e 'if length == 1 then .[0] else error("Expected exactly one client") end'
}
identity() {
  local name=$1 secret=$2 id user role entry roles='[]'
  shift 2
  jq -n --arg name "$name" --rawfile secret "$secret" \
    '{clientId:$name,secret:$secret,enabled:true,protocol:"openid-connect",publicClient:false,
      serviceAccountsEnabled:true,standardFlowEnabled:false,directAccessGrantsEnabled:false,fullScopeAllowed:false}' \
    >"$STATE/identity.json"
  api POST /admin/realms/master/clients --data-binary "@$STATE/identity.json" >/dev/null
  id="$(client master "$name" | jq -er .id)"
  user="$(api GET "/admin/realms/master/clients/$id/service-account-user" | jq -er .id)"
  for role in "$@"; do
    entry="$(api GET "/admin/realms/master/clients/$PROXY/roles/$role")"
    roles="$(printf '%s' "$roles" | jq --argjson role "$entry" '. + [$role]')"
  done
  printf '%s\n' "$roles" >"$STATE/roles.json"
  api POST "/admin/realms/master/users/$user/role-mappings/clients/$PROXY" \
    --data-binary "@$STATE/roles.json" >/dev/null
  api POST "/admin/realms/master/clients/$id/scope-mappings/clients/$PROXY" \
    --data-binary "@$STATE/roles.json" >/dev/null
}
wait_object() {
  local label=$1 resource=$2 query=$3 deadline=$((SECONDS + 180))
  while [[ $SECONDS -lt $deadline ]]; do
    if k get "$resource" -o json >"$STATE/object.json" &&
      jq -e "$query" "$STATE/object.json" >/dev/null; then return; fi
    sleep 2
  done
  k get pods
  die "$label did not become ready within 180 seconds."
}
ready() {
  wait_object "$1" "$1" '.status.phase == "Ready" and .status.observedGeneration == .metadata.generation'
}
setup() {
  local context cluster actual tool service endpoint api_port image
  local roles=(manage-realm manage-clients manage-events)
  local inventory_roles=(view-realm view-clients)
  case "${HANKOSHELL_LAB_MODULE:-operator}" in
    organizations) roles+=(manage-users view-users) ;;
    inventory) roles+=(view-users view-realm view-clients); inventory_roles+=(view-users) ;;
    security) roles+=(manage-identity-providers view-identity-providers view-realm view-clients) ;;
    operator|applications|workload|operations|guardrails) ;;
    *) die "Unknown learning module." ;;
  esac
  for tool in kubectl helm openssl curl jq cmp; do command -v "$tool" >/dev/null || die "Missing $tool."; done
  [[ ! -e "$STATE" && ! -L "$STATE" ]] || die "State already exists; start a fresh lab session."
  context="$(kubectl config current-context)"
  if [[ ! -f /etc/killercoda/host ]]; then
    # An explicit owned kind context is the only supported local rehearsal target.
    [[ -n "${HANKOSHELL_LAB_LOCAL_CONTEXT:-}" && "$context" == "$HANKOSHELL_LAB_LOCAL_CONTEXT" && "$context" =~ ^kind-hankoshell-lab-[a-f0-9]{12}$ ]] || die "Run in Killercoda or an explicitly selected disposable lab kind cluster."
    cluster="${context#kind-}"
    actual="$(docker inspect --format '{{index .Config.Labels "io.x-k8s.kind.cluster"}}' "$cluster-control-plane")"
    [[ "$actual" == "$cluster" ]] || die "The kind container does not belong to this lab."
  fi
  mkdir -m 700 "$STATE"
  kubectl config view --raw --minify --flatten >"$STATE/kubeconfig"
  printf '%s\n' "$context" >"$STATE/context"
  k get namespace kube-system -o jsonpath='{.metadata.uid}' >"$STATE/cluster-uid"
  [[ "$(k get crd -o json | jq '[.items[] | select(.spec.group == "hanko.sh")] | length')" == 0 ]] || die "HankoShell is already installed; refusing to use this cluster."
  if k get namespace auth >/dev/null 2>&1; then die "Namespace auth already exists; refusing to use it."; fi
  k create namespace auth
  k get namespace auth -o jsonpath='{.metadata.uid}' >"$STATE/auth-uid"
  local keycloak_image="quay.io/keycloak/keycloak:26.8.1@sha256:a78d6b79572168cb25886b80a8b5b8d4ed4390743e3eecb810538683e209dd6b"
  k label namespace auth pod-security.kubernetes.io/enforce=restricted
  openssl rand -hex 32 | tr -d '\n' >"$STATE/admin-password"
  openssl rand -hex 32 | tr -d '\n' >"$STATE/operator-secret"
  openssl rand -hex 32 | tr -d '\n' >"$STATE/inventory-secret"
  openssl req -new -x509 -newkey rsa:2048 -nodes -sha256 -days 1 \
    -keyout "$STATE/tls.key" -out "$STATE/ca.crt" -subj /CN=keycloak.auth.svc \
    -addext 'subjectAltName=DNS:keycloak.auth.svc,DNS:localhost' \
    -addext 'basicConstraints=critical,CA:true' 2>"$STATE/certificate.log"
  k create secret generic keycloak-bootstrap --from-file="password=$STATE/admin-password"
  k create secret tls keycloak-tls --cert "$STATE/ca.crt" --key "$STATE/tls.key"
  k create secret generic operator-ca --from-file="ca.crt=$STATE/ca.crt"
  sed "s|KEYCLOAK_IMAGE|$keycloak_image|" "$ASSETS/keycloak.yaml" >"$STATE/keycloak.yaml"
  if declare -F customize_keycloak >/dev/null; then customize_keycloak "$STATE/keycloak.yaml"; fi
  k apply -f "$STATE/keycloak.yaml"
  k rollout status deployment/keycloak --timeout=240s
  forward
  login

  echo "Preparing the test realm and scoped credentials…"
  api POST /admin/realms --data-binary '{"realm":"example","enabled":true}' >/dev/null
  PROXY="$(client master example-realm | jq -er .id)"
  identity demo-operator "$STATE/operator-secret" "${roles[@]}"
  identity demo-inventory "$STATE/inventory-secret" "${inventory_roles[@]}"
  k create secret generic operator-credentials --from-literal=client-id=demo-operator \
    --from-file="client-secret=$STATE/operator-secret"
  printf 'https://keycloak.auth.svc:8443' >"$STATE/provider-url"
  k create secret generic inventory-credentials --from-file="HANKO_KEYCLOAK_URL=$STATE/provider-url" \
    --from-literal=HANKO_KC_CLIENT_ID=demo-inventory --from-file="HANKO_KC_CLIENT_SECRET=$STATE/inventory-secret"
  api POST /admin/realms/example/clients --data-binary '{
    "clientId":"existing-portal","name":"existing-portal","protocol":"openid-connect","enabled":true,
    "publicClient":true,"standardFlowEnabled":true,"directAccessGrantsEnabled":false,
    "serviceAccountsEnabled":false,"implicitFlowEnabled":false,"fullScopeAllowed":false,
    "redirectUris":["https://existing.example.com/callback"],"webOrigins":["+"],
    "defaultClientScopes":[],"optionalClientScopes":[],
    "attributes":{"realm_client":"false","backchannel.logout.session.required":"true",
      "backchannel.logout.revoke.offline.tokens":"false"}}' >/dev/null
  client example existing-portal >"$STATE/existing-before.json"
  jq -er .id "$STATE/existing-before.json" >"$STATE/existing-id"

  echo "Installing the public release…"
  image="$OPERATOR_IMAGE"
  service="$(k get service kubernetes -n default -o jsonpath='{.spec.clusterIP}')"
  endpoint="$(k get endpointslices -n default -l kubernetes.io/service-name=kubernetes -o json |
    jq -er '.items[0].endpoints[0].addresses[0]')"
  api_port="$(k get endpointslices -n default -l kubernetes.io/service-name=kubernetes -o json | jq -er '.items[0].ports[] | select(.name == "https") | .port')"
  jq -n --arg digest "$(printf '%s' "$image" | cut -d@ -f2)" --arg service "$service/32" --arg endpoint "$endpoint/32" --argjson apiPort "$api_port" \
    '{fullnameOverride:"demo-operator",image:{digest:$digest},
      keycloak:{url:"https://keycloak.auth.svc:8443",credentialsSecret:"operator-credentials",caSecret:"operator-ca"},
      networkPolicy:{kubernetesAPIServiceCIDRs:[$service],kubernetesAPIEndpointCIDRs:[$endpoint],kubernetesAPIEndpointPorts:[$apiPort]},
      sensitiveWrites:{secrets:["hanko-sa-report-worker"]},resources:{limits:{cpu:"1",memory:"256Mi"}}}' >"$STATE/values.json"
  if [[ -f "$ASSETS/values-extra.json" ]]; then
    jq -s '.[0] * .[1]' "$STATE/values.json" "$ASSETS/values-extra.json" >"$STATE/merged-values.json"
    mv "$STATE/merged-values.json" "$STATE/values.json"
  fi
  if k get crd ciliumnetworkpolicies.cilium.io >/dev/null 2>&1; then
    sed "s/API_PORT/$api_port/" "$ASSETS/cilium-api.yaml" | k apply -f -
  fi
  helm install demo "$CHART" \
    --kubeconfig "$STATE/kubeconfig" --kube-context "$(cat "$STATE/context")" --namespace auth \
    --values "$STATE/values.json" --wait --timeout 180s
  touch "$STATE/ready"
  echo "Ready: operator 1.0.0 and Keycloak 26.8.1 in namespace auth."
}
check_oidc() {
  ready hankoapplication/customer-portal
  client example customer-portal >"$STATE/portal.json"
  jq -e '.publicClient and .protocol == "openid-connect" and .redirectUris == ["https://portal.example.com/callback"]' "$STATE/portal.json" >/dev/null
  jq -er .id "$STATE/portal.json" >"$STATE/portal-id"
  echo "PASS: the declared OIDC client exists in Keycloak."
}
check_callback() {
  ready hankoapplication/customer-portal
  client example customer-portal | jq -e --arg id "$(cat "$STATE/portal-id")" \
    '.id == $id and .redirectUris == ["https://portal.example.com/oidc/callback"]' >/dev/null
  echo "PASS: the callback changed in Keycloak; the UUID is unchanged."
}
check_observe() {
  wait_object "approvable candidate" hankoapplication/existing-portal \
    '.status.adoptionCandidate | .complete == true and .truncated == false and .approvable == true'
  k get hankoapplication existing-portal -o json >"$STATE/candidate.json"
  jq -e --arg id "$(cat "$STATE/existing-id")" \
    '.spec.mode == "Observe" and (.status.adoptionCandidate.providerIdentity.objectIDs | index($id) != null)' "$STATE/candidate.json" >/dev/null
  client example existing-portal | jq -S . >"$STATE/existing-observed.json"
  jq -S . "$STATE/existing-before.json" | cmp -s - "$STATE/existing-observed.json" || die "Observation changed the native client."
  echo "PASS: observation produced a candidate without changing the client."
}
check_receipt() {
  wait_object "verified adoption receipt" hankoapplication/existing-portal '.status.adoptionReceipt.state == "Verified"'
  client example existing-portal | jq -S \
    'del(.access, .attributes["hanko.sh/application-owner"], .attributes["hanko.sh/adoption-receipt"])' >"$STATE/existing-acquired.json"
  jq -S 'del(.access)' "$STATE/existing-before.json" | cmp -s - "$STATE/existing-acquired.json" || die "Acquisition changed more than ownership metadata."
  echo "PASS: acquisition changed only ownership metadata."
}
check_adoption() {
  ready hankoapplication/existing-portal
  k get hankoapplication existing-portal -o json | jq -e \
    '.spec.mode == "Manage" and .status.adoptionReceipt.state == "Verified"' >/dev/null
  client example existing-portal | jq -e --arg id "$(cat "$STATE/existing-id")" '.id == $id' >/dev/null
  echo "PASS: the adopted client is managed with its original UUID."
}
check_machine() {
  ready hankoserviceaccount/report-worker
  k get secret hanko-sa-report-worker -o json | jq -r '.data.client_secret | @base64d' | tr -d '\n' >"$STATE/worker-secret"
  curl --fail --silent --show-error --cacert "$STATE/ca.crt" --connect-timeout 5 --max-time 30 \
    --data-urlencode client_id=report-worker --data-urlencode grant_type=client_credentials \
    --data-urlencode "client_secret@$STATE/worker-secret" \
    "$ENDPOINT/realms/example/protocol/openid-connect/token" >"$STATE/worker-token.json"
  jq -e '.token_type == "Bearer" and (.access_token | length > 0) and .expires_in > 0' "$STATE/worker-token.json" >/dev/null
  jq '{token_type,expires_in}' "$STATE/worker-token.json"
  echo "PASS: the machine identity obtained a token; its value stays private."
}
# Independent lessons reuse the verified bootstrap and provider helpers.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then return 0; fi
case "${1:-}" in
  setup) setup ;;
  client)
    [[ "${2:-}" == customer-portal || "${2:-}" == existing-portal ]] || die "Unknown lab client."
    forward; login; client example "$2" | jq '{id,clientId,protocol,publicClient,redirectUris}' ;;
  check-oidc|check-callback|check-observe|check-receipt|check-adoption|check-machine)
    action="${1//-/_}"; forward; login; "$action" ;;
  *) die "Usage: $0 setup|client NAME|check-{oidc,callback,observe,receipt,adoption,machine}" ;;
esac
