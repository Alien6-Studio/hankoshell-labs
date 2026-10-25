#!/usr/bin/env bash
set -euo pipefail
export HANKOSHELL_LAB_MODULE=organizations
source "$(dirname "$0")/lab.sh"
decision() {
  local name=$1 scope=$2 expected=$3 status
  k get secret "hanko-sa-$name" -o json | jq -r '.data.client_secret | @base64d' | tr -d '\n' >"$STATE/subject-secret"
  curl --fail --silent --show-error --cacert "$STATE/ca.crt" --max-time 30 \
    --data-urlencode "client_id=$name" --data-urlencode grant_type=client_credentials \
    --data-urlencode "client_secret@$STATE/subject-secret" \
    "$ENDPOINT/realms/example/protocol/openid-connect/token" >"$STATE/subject-token.json"
  jq -er '"header = \"Authorization: Bearer " + .access_token + "\""' "$STATE/subject-token.json" >"$STATE/subject-curl.conf"
  status="$(curl --silent --show-error --cacert "$STATE/ca.crt" --config "$STATE/subject-curl.conf" --max-time 30 \
    --data-urlencode grant_type=urn:ietf:params:oauth:grant-type:uma-ticket --data-urlencode audience=invoice-api \
    --data-urlencode "permission=invoice#$scope" --data-urlencode response_mode=decision \
    --output "$STATE/decision.json" --write-out '%{http_code}' "$ENDPOINT/realms/example/protocol/openid-connect/token")"
  [[ "$status" == "$expected" ]] || die "$name $scope returned HTTP $status, expected $expected."
  if [[ "$expected" == 200 ]]; then jq -e '.result == true' "$STATE/decision.json" >/dev/null; fi
  printf 'PASS: %s / invoice:%s → HTTP %s\n' "$name" "$scope" "$status"
}
case "${1:-}" in
  setup) setup ;;
  check-hierarchy)
    forward; login
    for resource in hankorealm/example hankorole/reader hankorole/editor hankoorganization/company hankoorganization/engineering hankoapplication/invoice-api hankoserviceaccount/root-worker hankoserviceaccount/team-worker hankoserviceaccount/outside-worker; do ready "$resource"; done
    parent="$(k get hankoorganization company -o jsonpath='{.status.groupID}')"
    child="$(k get hankoorganization engineering -o jsonpath='{.status.groupID}')"
    api GET "/admin/realms/example/groups/$child" | jq -e --arg parent "$parent" '.parentId == $parent and .path == "/Sample Company/Engineering"' >/dev/null
    api GET /admin/realms/example/roles/editor/composites | jq -e 'any(.[]; .name == "reader")' >/dev/null
    api GET "/admin/realms/example/groups/$child/role-mappings/realm" | jq -e 'any(.[]; .name == "editor")' >/dev/null
    echo 'PASS: native organization, owned group hierarchy, composite role and group-role mappings exist.'
    ;;
  arrange-members)
    forward; login
    for pair in 'root-worker company' 'team-worker engineering'; do
      read -r name organization <<<"$pair"
      ready "hankoorganization/$organization"; ready "hankoserviceaccount/$name"
      id="$(client example "$name" | jq -er .id)"
      user="$(api GET "/admin/realms/example/clients/$id/service-account-user" | jq -er .id)"
      group="$(k get hankoorganization "$organization" -o jsonpath='{.status.groupID}')"
      api PUT "/admin/realms/example/users/$user/groups/$group" >/dev/null
    done
    echo 'Synthetic fixture membership prepared by the lab administrator; the operator does not provision users.'
    ;;
  check-direct)
    forward; login; ready hankoresourceserver/invoices
    decision root-worker read 200
    decision team-worker read 403
    decision outside-worker read 403
    decision root-worker write 403
    ;;
  check-descendants)
    forward; login; ready hankoresourceserver/invoices
    decision root-worker read 200
    decision team-worker read 200
    decision outside-worker read 403
    decision team-worker write 403
    ;;
  check-revocation)
    forward; login; ready hankoresourceserver/invoices
    decision root-worker read 403
    decision team-worker read 403
    api GET /admin/realms/example/roles/reader | jq -e '.name == "reader"' >/dev/null
    echo 'PASS: removing the grant revoked access while retaining the organization and roles.'
    ;;
  *) die 'Usage: lesson.sh setup|arrange-members|check-hierarchy|check-direct|check-descendants|check-revocation' ;;
esac
