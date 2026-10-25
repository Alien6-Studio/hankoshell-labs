#!/usr/bin/env bash
set -euo pipefail
export HANKOSHELL_LAB_MODULE=guardrails
source "$(dirname "$0")/lab.sh"
no_jobs() {
  [[ "$(k get jobs -o json | jq '.items | length')" == 0 ]] || die 'An unexpected Job was created.'
}
case "${1:-}" in
  setup) setup ;;
  check-admission)
    check_api
    if k apply --dry-run=server -f "$ASSETS/reserved-role.yaml" >"$STATE/admission.txt" 2>&1; then die 'Reserved authority role was accepted.'; fi
    rg_pattern='reserved platform, fleet and cluster roles cannot be defined'
    [[ "$(cat "$STATE/admission.txt")" == *"$rg_pattern"* ]] || die 'Expected a specific reserved-role admission refusal.'
    echo 'PASS: Kubernetes rejected a reserved authority role before reconciliation.'
    ;;
  check-plans)
    check_api
    for name in preview-upgrade preview-clone preview-dbswitch; do
      wait_object "$name dry-run plan" "hankooperation/$name" '.status.phase == "Done" and (.status.steps | length > 0) and all(.status.steps[]; .status == "Skipped")'
    done
    no_jobs
    echo 'PASS: all three dry runs completed with skipped steps. They do not validate target feasibility or perform a migration.'
    ;;
  check-approval)
    check_api
    wait_object 'explicit lifecycle approval request' hankooperation/unapproved-upgrade '.metadata.generation as $generation | any(.status.conditions[]?; .type == "Authorized" and .status == "False" and .reason == "ApprovalRequired" and .observedGeneration == $generation)'
    no_jobs
    [[ "$(k get hankosnapshots -o json | jq '.items | length')" == 0 ]] || die 'Unapproved operation created a snapshot.'
    echo 'PASS: enabling lifecycle controllers did not grant this operation authority; no child work was submitted.'
    ;;
  check-image)
    check_api
    wait_object 'unapproved theme image refusal' hankotheme/unapproved-theme '.status.phase == "Error" and any(.status.conditions[]?; .reason == "UntrustedImageRef")'
    no_jobs
    echo 'PASS: an immutable image alone did not authorize theme execution. No theme installation was performed.'
    ;;
  check-connections)
    check_api
    wait_object 'missing Hub credential refusal' hankotenant/unconfigured-tenant '.status.phase == "Error" and any(.status.conditions[]?; .reason == "HubTokenMissing")'
    wait_object 'unattested mesh refusal' hankomeshservice/unconfigured-mesh '.status.phase == "Error" and any(.status.conditions[]?; .type == "Attested" and .reason == "InvalidBinding" and (.message | contains("no Synced Hub identity")))'
    if k get secret unconfigured-hub-credential >/dev/null 2>&1; then die 'An unapproved Hub credential was created.'; fi
    echo 'PASS: missing enrollment/identity prevented synchronization and mesh attestation. This is not a connected Hub or network-enforcement test.'
    ;;
  check-email)
    check_api
    wait_object 'deprecated messaging status' hankoemailprovider/legacy-mail '.metadata.generation as $generation | .status.phase == "Deprecated" and .status.observedGeneration == $generation and any(.status.conditions[]?; .type == "DeliveryReady" and .status == "False" and .reason == "DelegatedToAPI")'
    no_jobs
    echo 'PASS: the compatibility CRD explicitly delegates messaging to the platform API; the operator did not send mail.'
    ;;
  *) die 'Usage: lesson.sh setup|check-admission|check-plans|check-approval|check-image|check-connections|check-email' ;;
esac
