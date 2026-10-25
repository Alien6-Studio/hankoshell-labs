#!/usr/bin/env bash
set -euo pipefail
# Reuse the baseline realm-only bootstrap; metrics need no additional provider rights.
export HANKOSHELL_LAB_MODULE=operator
source "$(dirname "$0")/lab.sh"
certificate() {
  local name=$1 usage=$2 san=$3
  printf 'basicConstraints=critical,CA:false\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=%s\nsubjectAltName=%s\n' "$usage" "$san" >"$STATE/metrics-$name.ext"
  openssl req -new -newkey rsa:2048 -nodes -sha256 -subj "/CN=academy-$name" \
    -keyout "$STATE/metrics-$name.key" -out "$STATE/metrics-$name.csr" 2>>"$STATE/metrics-certificates.log"
  openssl x509 -req -sha256 -days 1 -in "$STATE/metrics-$name.csr" \
    -CA "$STATE/metrics-ca.crt" -CAkey "$STATE/metrics-ca.key" -set_serial "0x$(openssl rand -hex 16)" \
    -extfile "$STATE/metrics-$name.ext" -out "$STATE/metrics-$name.crt" 2>>"$STATE/metrics-certificates.log"
}
metrics_forward() {
  finish; FORWARD_PID=""
  check_api
  k port-forward service/demo-operator-metrics :8080 --address 127.0.0.1 >"$STATE/metrics-forward.log" 2>&1 &
  FORWARD_PID=$!
  local deadline=$((SECONDS + 30)) port
  while [[ $SECONDS -lt $deadline ]]; do
    port="$(sed -n 's/^Forwarding from 127.0.0.1:\([0-9]*\) ->.*/\1/p' "$STATE/metrics-forward.log" | head -1)"
    if [[ -n "$port" ]]; then METRICS_ENDPOINT="https://localhost:$port/metrics"; return; fi
    kill -0 "$FORWARD_PID" 2>/dev/null || die 'Metrics port-forward stopped.'
    sleep 1
  done
  die 'Metrics port-forward timed out.'
}
request_metrics() {
  local identity=$1
  local args=()
  if [[ "$identity" != anonymous ]]; then args=(--cert "$STATE/metrics-$identity.crt" --key "$STATE/metrics-$identity.key"); fi
  curl --silent --show-error --cacert "$STATE/metrics-ca.crt" --tlsv1.3 --tls-max 1.3 \
    --connect-timeout 5 --max-time 15 --header 'Connection: close' "${args[@]}" \
    --output "$STATE/metrics-response.txt" --write-out '%{http_code}' "$METRICS_ENDPOINT"
}
check_authorized() {
  [[ "$(request_metrics scraper)" == 200 ]] || die 'Authorized metrics request failed.'
  grep -q '^controller_runtime_reconcile_total' "$STATE/metrics-response.txt" || \
    grep -q '^go_goroutines ' "$STATE/metrics-response.txt" || die 'Expected actual operator metrics.'
}
case "${1:-}" in
  setup) setup ;;
  check-default)
    check_api
    k get deployment demo-operator -o json | jq -e '.metadata.generation as $g | .status.observedGeneration == $g and .status.availableReplicas == 1 and any(.spec.template.spec.containers[]; (.args | index("--metrics-bind-address=0")) != null and all(.ports[]?; .name != "metrics"))' >/dev/null
    service="$(k get service demo-operator-metrics --ignore-not-found -o name)"
    [[ "$service" == '' ]] || die 'Metrics Service still exists.'
    echo 'PASS: metrics are disabled; the reconciler remains available.'
    ;;
  enable)
    check_api
    [[ ! -e "$STATE/metrics-ca.key" ]] || die 'Metrics credentials already exist; continue with the checks.'
    openssl req -new -x509 -newkey rsa:2048 -nodes -sha256 -days 1 -subj /CN=academy-metrics-ca \
      -addext 'basicConstraints=critical,CA:true' -addext 'keyUsage=critical,keyCertSign,cRLSign' \
      -keyout "$STATE/metrics-ca.key" -out "$STATE/metrics-ca.crt" 2>"$STATE/metrics-certificates.log"
    certificate server serverAuth 'DNS:localhost,DNS:demo-operator-metrics.auth.svc'
    certificate scraper clientAuth 'URI:spiffe://academy.example/monitoring/scraper'
    certificate outsider clientAuth 'URI:spiffe://academy.example/monitoring/outsider'
    k create secret tls metrics-server --cert "$STATE/metrics-server.crt" --key "$STATE/metrics-server.key"
    k create secret generic metrics-client-ca --from-file="ca.crt=$STATE/metrics-ca.crt"
    jq -n '{metrics:{enabled:true,tls:{serverSecret:"metrics-server",clientCASecret:"metrics-client-ca",allowedClientURIs:["spiffe://academy.example/monitoring/scraper"]},networkPolicy:{namespaceSelector:{matchLabels:{"kubernetes.io/metadata.name":"auth"}},podSelector:{matchLabels:{app:"academy-scraper"}}}}}' >"$ASSETS/metrics-values.json"
    helm upgrade demo "$CHART" --reset-values --kubeconfig "$STATE/kubeconfig" --kube-context "$(cat "$STATE/context")" --namespace auth \
      --values "$STATE/values.json" --values "$ASSETS/metrics-values.json" --wait --timeout 180s
    ;;
  check-enabled)
    metrics_forward; check_authorized
    echo 'PASS: the actual metrics endpoint accepts the reviewed SPIFFE client over verified TLS 1.3.'
    ;;
  check-refusal)
    for identity in anonymous outsider; do
      metrics_forward; check_authorized
      # A rejected handshake can close a kubectl forwarding stream. Use a new one.
      metrics_forward
      result=0
      status="$(request_metrics "$identity" 2>"$STATE/metrics-refusal.log")" || result=$?
      [[ "$status" == 000 && ( "$result" == 35 || "$result" == 56 ) ]] || die "$identity was not refused during the TLS handshake."
      printf 'PASS: %s was refused during TLS authentication.\n' "$identity"
    done
    metrics_forward; check_authorized
    ;;
  disable)
    check_api
    helm upgrade demo "$CHART" --reset-values --kubeconfig "$STATE/kubeconfig" --kube-context "$(cat "$STATE/context")" --namespace auth \
      --values "$STATE/values.json" --wait --timeout 180s
    ;;
  *) die 'Usage: lesson.sh setup|enable|disable|check-default|check-enabled|check-refusal' ;;
esac
