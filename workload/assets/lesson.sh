#!/usr/bin/env bash
set -euo pipefail
export HANKOSHELL_LAB_MODULE=workload
source "$(dirname "$0")/lab.sh"
customize_keycloak() {
  k create --dry-run=client --validate=false -f "$1" -o json | jq -s '{apiVersion:"v1",kind:"List",items:map(
    if .kind == "Deployment" then
      .spec.template.spec.containers[0].args += ["--truststore-paths=/kubernetes-ca/ca.crt"] |
      .spec.template.spec.containers[0].volumeMounts += [{name:"kubernetes-ca",mountPath:"/kubernetes-ca",readOnly:true}] |
      .spec.template.spec.volumes += [{name:"kubernetes-ca",configMap:{name:"kube-root-ca.crt"}}]
    else . end)}' >"$1.new"
  mv "$1.new" "$1"
}
pod() {
  local name=$1 audience=$2
  k create serviceaccount "$name"
  jq -n --arg name "$name" --arg audience "$audience" --arg image "$(k get deployment keycloak -o jsonpath='{.spec.template.spec.containers[0].image}')" \
    '{apiVersion:"v1",kind:"Pod",metadata:{name:$name},spec:{serviceAccountName:$name,automountServiceAccountToken:false,
      securityContext:{runAsNonRoot:true,runAsUser:1000,runAsGroup:1000,seccompProfile:{type:"RuntimeDefault"}},
      containers:[{name:"worker",image:$image,command:["/bin/bash","-c","sleep 3600"],
        resources:{requests:{cpu:"10m",memory:"16Mi"},limits:{memory:"64Mi"}},
        securityContext:{allowPrivilegeEscalation:false,readOnlyRootFilesystem:true,capabilities:{drop:["ALL"]}},
        volumeMounts:[{name:"assertion",mountPath:"/var/run/identity",readOnly:true}]}],
      volumes:[{name:"assertion",projected:{defaultMode:292,sources:[{serviceAccountToken:{audience:$audience,expirationSeconds:600,path:"assertion"}}]}}]}}' | k apply -f -
}
exchange() {
  local pod_name=$1 expected=$2 status
  k wait --for=condition=Ready "pod/$pod_name" --timeout=120s >/dev/null
  k exec "$pod_name" -- cat /var/run/identity/assertion >"$STATE/assertion"
  status="$(curl --silent --show-error --cacert "$STATE/ca.crt" --max-time 30 \
    --data-urlencode grant_type=client_credentials --data-urlencode client_id=federated-worker \
    --data-urlencode client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer \
    --data-urlencode "client_assertion@$STATE/assertion" --output "$STATE/federated-token.json" --write-out '%{http_code}' \
    "$ENDPOINT/realms/example/protocol/openid-connect/token")"
  [[ "$status" == "$expected" ]] || die "$pod_name assertion returned HTTP $status, expected $expected."
  if [[ "$expected" == 200 ]]; then jq -e '.token_type == "Bearer" and .expires_in > 0' "$STATE/federated-token.json" >/dev/null; fi
  echo "PASS: $pod_name assertion → HTTP $status; token bytes remain private."
}
case "${1:-}" in
  setup)
    setup
    login
    # Only public OIDC discovery/JWKS endpoints, on this disposable cluster.
    k apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata: {name: academy-public-oidc-discovery}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: ClusterRole, name: system:service-account-issuer-discovery}
subjects: [{apiGroup: rbac.authorization.k8s.io, kind: Group, name: system:unauthenticated}]
YAML
    for pair in 'workload-observer view-identity-providers' 'workload-writer manage-identity-providers' 'workload-dependent-reader view-clients' 'workload-client-writer manage-clients'; do
      read -r name role <<<"$pair"
      openssl rand -hex 32 | tr -d '\n' >"$STATE/$name-secret"
      identity "$name" "$STATE/$name-secret" "$role" view-realm
      k create secret generic "$name" --from-file="HANKO_KEYCLOAK_URL=$STATE/provider-url" \
        --from-literal="HANKO_KC_CLIENT_ID=$name" --from-file="HANKO_KC_CLIENT_SECRET=$STATE/$name-secret"
      jq -n --arg name "$name" '{apiVersion:"hanko.sh/v1alpha1",kind:"HankoKeycloakInstance",metadata:{name:$name},
        spec:{mode:"external",adminRef:{name:$name},tlsCARef:"operator-ca"}}' | k apply -f -
    done
    # The administrator prepares the native authentication prerequisite;
    # the operator only reads it and never repairs authentication flows.
    login
    api GET /admin/realms/example/authentication/flows/clients/executions >"$STATE/executions.json"
    jq -e 'any(.[]; .providerId == "federated-jwt")' "$STATE/executions.json" >/dev/null || die 'Native federated-jwt authenticator is unavailable.'
    jq '.[] | select(.providerId == "federated-jwt") | .requirement="ALTERNATIVE"' "$STATE/executions.json" >"$STATE/federated-execution.json"
    api PUT /admin/realms/example/authentication/flows/clients/executions --data-binary "@$STATE/federated-execution.json" >/dev/null
    issuer="$(k get --raw /.well-known/openid-configuration | jq -er .issuer)"
    anchor="$(k get namespace kube-system -o jsonpath='{.metadata.uid}')"
    ca_hash="$(k get configmap kube-root-ca.crt -o json | jq -r '.data["ca.crt"]' | openssl x509 -outform DER | openssl dgst -sha256 | awk '{print $NF}')"
    jq -n --arg issuer "$issuer" --arg anchor "$anchor" --arg hash "sha256:$ca_hash" \
      '{apiVersion:"hanko.sh/v1alpha1",kind:"HankoWorkloadTrust",metadata:{name:"cluster"},spec:{mode:"Manage",realmRef:"example",
      sourceRef:"workload-observer",writerRef:"workload-writer",dependentReaderRef:"workload-dependent-reader",keycloakAlias:"academy-cluster",
      provider:"Kubernetes",qualifiedKeycloakVersion:"26.8.1",kubernetes:{issuer:$issuer,clusterAnchor:{kubeSystemNamespaceUID:$anchor,apiServerCAHash:$hash},assertionMaxAgeSeconds:600}}}' >"$ASSETS/trust.json"
    audience='https://keycloak.auth.svc:8443/realms/example'
    pod worker "$audience"
    pod outsider "$audience"
    uid="$(k get serviceaccount worker -o jsonpath='{.metadata.uid}')"
    jq -n --arg uid "$uid" '{apiVersion:"hanko.sh/v1alpha1",kind:"HankoServiceAccount",metadata:{name:"federated-worker"},
      spec:{realmRef:"example",clientID:"federated-worker",authentication:{mode:"Kubernetes",kubernetes:{trustRef:"cluster",sourceRef:"workload-client-writer",
      workload:{namespace:"auth",serviceAccountRef:"worker",expectedUID:$uid},expirationSeconds:600}}}}' >"$ASSETS/identity.json"
    ;;
  check-source)
    check_api; ready hankorealm/example
    for name in workload-observer workload-writer workload-dependent-reader workload-client-writer; do
      wait_object "$name connection" "hankokeycloakinstance/$name" '.metadata.generation as $generation | .status.phase == "Ready" and any(.status.conditions[]?; .type == "AdminAPIReachable" and .status == "True" and .observedGeneration == $generation)'
    done
    echo 'PASS: distinct reader, trust writer, dependency reader and client writer connections are available.'
    ;;
  check-trust)
    forward; login; ready hankoworkloadtrust/cluster
    api GET /admin/realms/example/identity-provider/instances/academy-cluster | jq -e '.providerId == "kubernetes" and .alias == "academy-cluster"' >/dev/null
    echo 'PASS: the actual cluster anchor and public OIDC metadata were verified; the native Kubernetes trust exists.'
    ;;
  check-identity)
    forward; login; ready hankoserviceaccount/federated-worker
    client example federated-worker | jq -e '.clientAuthenticatorType == "federated-jwt" and .serviceAccountsEnabled and (.fullScopeAllowed | not)' >/dev/null
    if k get secret hanko-sa-federated-worker >/dev/null 2>&1; then die 'An unexpected workload credential Secret was created.'; fi
    echo 'PASS: native federated authentication is active with no projected client-secret credential.'
    ;;
  check-token) forward; exchange worker 200 ;;
  check-denial) forward; exchange outsider 401 ;;
  *) die 'Usage: lesson.sh setup|check-source|check-trust|check-identity|check-token|check-denial' ;;
esac
