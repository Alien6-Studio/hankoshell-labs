#!/usr/bin/env bash
set -euo pipefail
export HANKOSHELL_LAB_MODULE=inventory
source "$(dirname "$0")/lab.sh"
unchanged() {
  client example existing-portal | jq -S . >"$STATE/existing-current.json"
  jq -S . "$STATE/existing-before.json" | cmp -s - "$STATE/existing-current.json" || die 'Read-only inventory changed the client.'
}
case "${1:-}" in
  setup) setup ;;
  check-preview)
    forward; login
    wait_object 'dry-run report' hankoimport/preview '.status.phase == "Done" and .status.discovered.realms == 1 and .status.discovered.applications > 0 and (.status.applied.total // 0) == 0'
    [[ "$(k get hankorealms -o json | jq '.items | length')" == 0 ]] || die 'Dry run created a realm CR.'
    unchanged
    echo 'PASS: dry-run inventory found the realm and clients without creating CRs or modifying Keycloak.'
    ;;
  check-import)
    forward; login
    wait_object 'Observe import' hankoimport/discover '.status.phase == "Done" and .status.applied.applications > 0'
    k get hankoapplications -o json >"$STATE/imported.json"
    jq -e '.items | length > 0 and all(.[]; .spec.mode == "Observe" and .metadata.labels["hanko.sh/imported-by"] == "discover")' "$STATE/imported.json" >/dev/null
    unchanged
    echo 'PASS: generated application declarations are Observe-only; provider configuration is unchanged.'
    ;;
  check-snapshot)
    check_api
    wait_object 'configuration snapshot' hankosnapshot/before-change '.status.phase == "Done" and (.status.configHash | length > 0) and (.status.dbJobRef // "") == ""'
    name="$(k get hankosnapshot before-change -o jsonpath='{.status.configMapRef}')"
    k get configmap "$name" -o json | jq -e '.immutable == true and (.data | length > 0)' >/dev/null
    echo 'PASS: immutable operator configuration captured. No database backup or portable restore is claimed.'
    ;;
  review-snapshot)
    check_api
    wait_object 'snapshot approval request' hankosnapshot/before-change \
      '.metadata.generation as $generation | any(.status.conditions[]?; .type == "Authorized" and .reason == "ApprovalRequired" and .observedGeneration == $generation)'
    k get hankosnapshot before-change -o json | jq '{uid:.metadata.uid,generation:.metadata.generation,spec,conditions:.status.conditions}'
    ;;
  approve-snapshot)
    check_api
    k get hankosnapshot before-change -o json >"$STATE/snapshot-review.json"
    approval="$(jq -er '.status.conditions[] | select(.type == "Authorized" and .reason == "ApprovalRequired") | .message | select(startswith("Approval required: v1|")) | ltrimstr("Approval required: ")' "$STATE/snapshot-review.json")"
    IFS='|' read -r version object_uid generation instance_uid intent_hash <<<"$approval"
    [[ "$object_uid" == "$(jq -er .metadata.uid "$STATE/snapshot-review.json")" && "$generation" == "$(jq -er .metadata.generation "$STATE/snapshot-review.json")" && "$instance_uid" == "$(k get hankokeycloakinstance inventory-keycloak -o jsonpath='{.metadata.uid}')" && "$intent_hash" =~ ^[a-f0-9]{64}$ ]] || die 'Snapshot approval identity changed; review again.'
    k annotate hankosnapshot before-change "hanko.sh/lifecycle-approval=$approval"
    ;;
  restart)
    forward; login; ready hankoapplication/customer-portal
    client example customer-portal | jq -er .id >"$STATE/portal-provider-id"
    k rollout restart deployment/demo-operator
    k rollout status deployment/demo-operator --timeout=180s
    k annotate hankoapplication customer-portal academy.hanko.sh/recheck="$(date +%s)" --overwrite
    ;;
  check-recovery)
    forward; login; ready hankoapplication/customer-portal
    client example customer-portal | jq -e --arg id "$(cat "$STATE/portal-provider-id")" '.id == $id and .publicClient and .redirectUris == ["https://portal.example.com/callback"]' >/dev/null
    unchanged
    echo 'PASS: the replacement controller reconciles current desired state and leaves imported clients untouched. This is restart recovery, not multi-node HA.'
    ;;
  *) die 'Usage: lesson.sh setup|restart|review-snapshot|approve-snapshot|check-preview|check-import|check-snapshot|check-recovery' ;;
esac
