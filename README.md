# HankoShell Academy

[![Content](https://github.com/Alien6-Studio/hankoshell-labs/actions/workflows/content.yml/badge.svg)](https://github.com/Alien6-Studio/hankoshell-labs/actions/workflows/content.yml)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Killercoda](https://img.shields.io/badge/labs-Killercoda-f5c542)](https://killercoda.com/alien6)

The public learning scenarios of **HankoShell Academy**. Start with [HankoShell Operator](https://github.com/Alien6-Studio/hankoshell-operator), running on disposable Kubernetes environments.

[Start the browser lab](https://killercoda.com/alien6/scenario/operator) · [Operator documentation](https://github.com/Alien6-Studio/hankoshell-operator#readme)

## Operator curriculum

Each lab starts its own disposable cluster and synthetic Keycloak. No previous
session is required. Allow 20–25 minutes plus image downloads. Killercoda requires
a free account; free sessions last up to one hour. All eight scenarios have
completed local rehearsal and a fresh hosted walkthrough.

| Scenario | What you practice |
| --- | --- |
| [Start here](https://killercoda.com/alien6/scenario/operator) | OIDC reconciliation, read-only observation, explicit adoption and machine authentication. |
| [Realm security](https://killercoda.com/alien6/scenario/security) | Shared IAM profiles, password/MFA/session policy, disabled broker configuration and issuer projection. |
| [Applications](https://killercoda.com/alien6/scenario/applications) | Confidential OIDC, signed SAML configuration, token claims, credential rotation, runtime delivery and withdrawn consent. |
| [Organizations and authorization](https://killercoda.com/alien6/scenario/organizations) | Hierarchy, composite/group roles, direct/descendant grants and real UMA allow/deny/revocation decisions. |
| [Inventory and recovery](https://killercoda.com/alien6/scenario/inventory) | Dry-run/Observe import, locally approved configuration snapshot and controller restart. |
| [Workload identity](https://killercoda.com/alien6/scenario/workload) | Cluster-bound trust, native federated authentication, kubelet-projected assertions and wrong-subject rejection. |
| [Safety boundaries](https://killercoda.com/alien6/scenario/guardrails) | Lifecycle plans and approval, image trust, Hub/mesh prerequisites and notification ownership. |
| [Secure metrics](https://killercoda.com/alien6/scenario/metrics) | TLS 1.3, exact SPIFFE client identity, anonymous/wrong-identity rejection and listener shutdown. |

Together these scenarios address all 17 CRD surfaces. This is **not complete
end-to-end coverage of every feature**: the safety-boundaries module deliberately
demonstrates refusal, not successful advanced execution. Positive labs for managed
provisioning, Upgrade/Clone/DBSwitch, database backup, signed theme installation,
bounded delegation, connected Fleet/mesh and the experimental authentik
adapter remain tracked in [#3](https://github.com/Alien6-Studio/hankoshell-labs/issues/3).
Successful single-node exercises do not qualify production HA or upgrades.

The labs use the published **1.0.0** chart and image, pinned by OCI digest, with
Keycloak **26.8.1**. All credentials are generated per session. Do not enter real
credentials or connect an existing cluster. APIs remain experimental
(`hanko.sh/v1alpha1`). New scenarios fetch the shared foundation at an immutable
signed source revision and verify each file's SHA-256 before running it.

Killercoda uses Cilium. The lab adds a namespaced policy allowing only the operator to reach the `kube-apiserver` entity on its discovered port, alongside the chart’s NetworkPolicy. Cilium does not match node-hosted API servers with `ipBlock` peers by default; see [Cilium’s policy documentation](https://docs.cilium.io/en/stable/security/policy/layer3/#access-to-from-kube-apiserver). No cluster-wide Cilium settings are changed.

## Contribute

Edit a scenario's Markdown lessons or `assets/`. Step checks compare Kubernetes
status with actual provider state or a specific expected refusal. Keep scenarios
self-contained and use only public images and synthetic data. Each module states
its prerequisites and what its checks do not prove.

Before a change, run `bash -n` on shell files, review the JSON, and rehearse every lesson in a fresh Killercoda session. For local rehearsal, use an owned kind cluster named `hankoshell-lab-<12 hex characters>` with its own kubeconfig; set `HANKOSHELL_LAB_LOCAL_CONTEXT` to that context and `HANKOSHELL_LAB_STATE` to a fresh private directory before running `operator/assets/lab.sh setup`. Delete only that disposable cluster afterwards.

Killercoda synchronizes `main`. This repository contains learning content, not the operator release or its qualification evidence. See [contribution guidance](CONTRIBUTING.md) and [security reporting](SECURITY.md).

Apache-2.0. Provider helpers and Keycloak fixtures are adapted from HankoShell Operator, copyright Alien6 and contributors.
