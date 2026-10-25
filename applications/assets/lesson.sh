#!/usr/bin/env bash
set -euo pipefail
export HANKOSHELL_LAB_MODULE=applications
source "$(dirname "$0")/lab.sh"
machine_token() {
  local secret=$1 output=$2
  curl --silent --show-error --cacert "$STATE/ca.crt" --connect-timeout 5 --max-time 30 \
    --data-urlencode client_id=report-worker --data-urlencode grant_type=client_credentials \
    --data-urlencode "client_secret@$secret" --output "$output" --write-out '%{http_code}' \
    "$ENDPOINT/realms/example/protocol/openid-connect/token"
}
case "${1:-}" in
  setup) setup ;;
  check-web)
    forward; login; ready hankoapplication/storefront
    client example storefront >"$STATE/storefront.json"
    jq -e '.protocol == "openid-connect" and (.publicClient | not) and .standardFlowEnabled and
      (.directAccessGrantsEnabled | not) and .redirectUris == ["https://store.example.com/callback"] and
      .attributes["post.logout.redirect.uris"] == "https://store.example.com/"' "$STATE/storefront.json" >/dev/null
    id="$(jq -er .id "$STATE/storefront.json")"
    api GET "/admin/realms/example/clients/$id/roles/operator" | jq -e '.name == "operator"' >/dev/null
    echo 'PASS: confidential OIDC, client role, callback and logout configuration are present.'
    ;;
  check-saml)
    forward; login; ready hankoapplication/legacy-saml
    api GET /admin/realms/example/clients | jq -e '.[] | select(.clientId == "https://legacy.example.com/entity") |
      .protocol == "saml" and .attributes["saml.server.signature"] == "true" and .attributes["saml.assertion.signature"] == "true"' >/dev/null
    curl --fail --silent --show-error --cacert "$STATE/ca.crt" --max-time 30 \
      "$ENDPOINT/realms/example/protocol/saml/descriptor" >"$STATE/saml-metadata.xml"
    [[ "$(cat "$STATE/saml-metadata.xml")" == *'X509Certificate'* ]] || die 'Missing public SAML signing certificate.'
    echo 'PASS: signed SAML configuration and public IdP metadata are available; no SP login is simulated.'
    ;;
  check-claims)
    forward; login; ready hankoserviceaccount/report-worker
    k get secret hanko-sa-report-worker -o json | jq -r '.data.client_secret | @base64d' | tr -d '\n' >"$STATE/worker-before"
    [[ "$(machine_token "$STATE/worker-before" "$STATE/token-before.json")" == 200 ]] || die 'Machine authentication failed.'
    jq -r '.access_token | split(".")[1] | @base64d' "$STATE/token-before.json" >"$STATE/claims.json"
    jq -e '.environment == "academy" and (.aud == "reporting-api" or (.aud | type == "array" and index("reporting-api") != null))' "$STATE/claims.json" >/dev/null
    client example report-worker | jq -er .id >"$STATE/worker-id"
    echo 'PASS: an actual provider-issued token carries the declared audience and environment. Decoding alone is not JWT verification.'
    ;;
  check-rotation)
    forward; login; ready hankoserviceaccount/report-worker
    k get secret hanko-sa-report-worker -o json | jq -r '.data.client_secret | @base64d' | tr -d '\n' >"$STATE/worker-after"
    ! cmp -s "$STATE/worker-before" "$STATE/worker-after" || die 'Credential did not rotate.'
    [[ "$(machine_token "$STATE/worker-before" "$STATE/old-token.json")" == 401 ]] || die 'Old secret was not rejected.'
    [[ "$(machine_token "$STATE/worker-after" "$STATE/new-token.json")" == 200 ]] || die 'New secret was rejected.'
    client example report-worker | jq -e --arg id "$(cat "$STATE/worker-id")" '.id == $id' >/dev/null
    echo 'PASS: new credentials work, old credentials are rejected, and the client UUID is unchanged.'
    ;;
  bind-runtime)
    check_api; ready hankoapplication/storefront
    k apply -f - <<'YAML'
apiVersion: v1
kind: ServiceAccount
metadata: {name: storefront}
automountServiceAccountToken: false
YAML
    app_uid="$(k get hankoapplication storefront -o jsonpath='{.metadata.uid}')"
    workload_uid="$(k get serviceaccount storefront -o jsonpath='{.metadata.uid}')"
    for kind in ConfigMap Secret; do
      target=metadata
      [[ "$kind" == Secret ]] && target=credentials
      jq -n --arg kind "$kind" --arg target "$target" --arg app "$app_uid" --arg workload "$workload_uid" \
        '{apiVersion:"v1",kind:$kind,metadata:{name:"storefront-runtime",labels:{"hanko.sh/runtime-target":$target},annotations:{
        "hanko.sh/runtime-application-namespace":"auth","hanko.sh/runtime-application-name":"storefront","hanko.sh/runtime-application-uid":$app,
        "hanko.sh/runtime-binding-name":"web","hanko.sh/runtime-service-account":"storefront","hanko.sh/runtime-service-account-uid":$workload}}} |
        if $kind == "ConfigMap" then .data={unrelated:"preserve-this-field"} else .stringData={unrelated:"preserve-this-field"} end' | k apply -f -
    done
    k patch hankoapplication storefront --type merge --patch '{"spec":{"runtimeBindings":[{"name":"web","workload":{"namespace":"auth","serviceAccountRef":"storefront"},"publicMetadata":{"configMapRef":"storefront-runtime"},"credentials":{"secretRef":"storefront-runtime"}}]}}'
    ;;
  check-runtime)
    check_api; ready hankoapplication/storefront
    k get configmap storefront-runtime -o json >"$STATE/runtime-metadata.json"
    jq -S .data "$STATE/runtime-metadata.json" >"$STATE/runtime-public-before.json"
    jq -e '.data.unrelated == "preserve-this-field" and (.data["identity.json"] | fromjson | .schemaVersion == "hanko.sh/application-runtime/v1alpha1" and .clientID == "storefront" and .credentials.secretRef == "storefront-runtime")' "$STATE/runtime-metadata.json" >/dev/null
    k get secret hanko-app-storefront -o json | jq -r '.data.client_secret' >"$STATE/runtime-source"
    k get secret storefront-runtime -o json | jq -r '.data.client_secret' >"$STATE/runtime-copy"
    cmp -s "$STATE/runtime-source" "$STATE/runtime-copy" || die 'Runtime credential differs from the owned source.'
    k get secret storefront-runtime -o json | jq -e '.data.unrelated | @base64d == "preserve-this-field"' >/dev/null
    echo 'PASS: UID-authorized metadata and credential delivery succeeded and preserved unrelated workload fields.'
    ;;
  check-runtime-refusal)
    forward; login
    wait_object 'revoked runtime consent' hankoapplication/storefront '.metadata.generation as $generation | .status.phase == "Error" and any(.status.conditions[]?; .type == "RuntimeBindings" and .reason == "TargetNotAuthorized" and .status == "False" and .observedGeneration == $generation)'
    client example storefront | jq -e --arg id "$(jq -er .id "$STATE/storefront.json")" '.id == $id' >/dev/null
    k get configmap storefront-runtime -o json | jq -S .data | cmp -s - "$STATE/runtime-public-before.json" || die 'Refused delivery changed last-known metadata.'
    echo 'PASS: withdrawn target consent stopped delivery without replacing the provider client.'
    ;;
  *) die 'Usage: lesson.sh setup|bind-runtime|check-web|check-saml|check-claims|check-rotation|check-runtime|check-runtime-refusal' ;;
esac
