#!/usr/bin/env bash
set -euo pipefail
export HANKOSHELL_LAB_MODULE=security
source "$(dirname "$0")/lab.sh"
case "${1:-}" in
  setup)
    setup
    openssl rand -hex 32 | tr -d '\n' >"$STATE/upstream-secret"
    k create secret generic upstream-credentials --from-file="client-secret=$STATE/upstream-secret"
    # Zero-replica fixture: demonstrates the issuer projection contract only.
    jq -n --arg image "$OPERATOR_IMAGE" '{apiVersion:"apps/v1",kind:"Deployment",metadata:{name:"hanko-api"},
      spec:{replicas:0,selector:{matchLabels:{app:"issuer-fixture"}},template:{metadata:{labels:{app:"issuer-fixture"}},
      spec:{automountServiceAccountToken:false,securityContext:{runAsNonRoot:true,runAsUser:65532,seccompProfile:{type:"RuntimeDefault"}},
      containers:[{name:"hanko-api",image:$image,securityContext:{allowPrivilegeEscalation:false,readOnlyRootFilesystem:true,capabilities:{drop:["ALL"]}}}]}}}}' | k apply -f -
    ;;
  check-policy)
    forward; login; ready hankoiamprofile/workforce; ready hankorealm/example
    api GET /admin/realms/example | jq -e '.displayName == "Academy workforce" and
      (.passwordPolicy | contains("length(20)")) and .bruteForceProtected and .failureFactor == 5 and
      .ssoSessionMaxLifespan == 28800 and .ssoSessionIdleTimeout == 1800 and .sslRequired == "all" and .revokeRefreshToken' >/dev/null
    api GET /admin/realms/example/authentication/required-actions | jq -e 'any(.[]; .alias == "CONFIGURE_TOTP" and .enabled)' >/dev/null
    k get hankorealm example -o json | jq -er '.status.effectivePolicyHash' >"$STATE/policy-before"
    echo 'PASS: password, session, TLS, brute-force and TOTP policy reached Keycloak.'
    ;;
  check-broker)
    forward; login; ready hankorealm/example
    api GET /admin/realms/example/identity-provider/instances/upstream | jq -e '.alias == "upstream" and .providerId == "oidc" and .enabled == false and .trustEmail == false and .config.validateSignature == "true"' >/dev/null
    echo 'PASS: the disabled synthetic broker is configured; no external identity provider was contacted.'
    ;;
  check-update)
    forward; login
    wait_object 'new effective policy' hankorealm/example \
      ".status.phase == \"Ready\" and .status.effectivePolicyHash != \"$(cat "$STATE/policy-before")\""
    api GET /admin/realms/example | jq -e '.passwordPolicy | contains("length(24)")' >/dev/null
    echo 'PASS: editing the shared profile updated the realm policy.'
    ;;
  check-issuer)
    check_api
    wait_object 'configured issuer' hankoissuer/workforce '.status.phase == "Ready" and .status.configuredHost == "login.example.com" and any(.status.conditions[]?; .type == "Allowlisted" and .status == "True" and .reason == "Configured")'
    k get deployment hanko-api -o json | jq -e '.spec.replicas == 0 and
      any(.spec.template.spec.containers[] | select(.name == "hanko-api").env[]; .name == "HANKO_PUBLIC_ISSUERS" and (.value | contains("login.example.com")) and (.value | contains("example")))' >/dev/null
    echo 'PASS: the issuer binding was projected into the zero-replica API fixture, without creating DNS or an ingress.'
    ;;
  *) die 'Usage: lesson.sh setup|check-policy|check-broker|check-update|check-issuer' ;;
esac
