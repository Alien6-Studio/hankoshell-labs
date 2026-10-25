# HankoShell Academy

The public learning scenarios of **HankoShell Academy**. Start with [HankoShell Operator](https://github.com/Alien6-Studio/hankoshell-operator), running on disposable Kubernetes environments.

[Start the browser lab](https://killercoda.com/alien6/scenario/operator) · [Operator documentation](https://github.com/Alien6-Studio/hankoshell-operator#readme)

## Operator curriculum

Each lab starts its own disposable cluster and synthetic Keycloak. No previous
session is required. Allow 20–25 minutes plus image downloads. Killercoda requires
a free account; free sessions last up to one hour. New modules marked **preview**
are undergoing hosted verification and are not yet promoted on hanko.sh.

| Scenario | What you practice |
| --- | --- |
| [Start here](https://killercoda.com/alien6/scenario/operator) | OIDC reconciliation, read-only observation, explicit adoption and machine authentication. |
| [Realm security](security/) — preview | Shared IAM profiles, password/MFA/session policy, disabled broker configuration and issuer projection. |
| [Applications](applications/) — preview | Confidential OIDC, signed SAML configuration, token claims, credential rotation, runtime delivery and withdrawn consent. |
| [Organizations and authorization](organizations/) — preview | Hierarchy, composite/group roles, direct/descendant grants and real UMA allow/deny/revocation decisions. |
| [Inventory and recovery](inventory/) — preview | Dry-run/Observe import, locally approved configuration snapshot and controller restart. |
| [Workload identity](workload/) — preview | Cluster-bound trust, native federated authentication, kubelet-projected assertions and wrong-subject rejection. |
| [Safety boundaries](guardrails/) — preview | Lifecycle dry runs and approval, theme image-trust refusal, Hub/mesh prerequisites and deprecated messaging. |

Together these scenarios address all 17 CRD surfaces. This is **not complete
end-to-end coverage of every feature**: the last module deliberately demonstrates
refusal, not successful advanced execution. Positive labs for managed provisioning,
Upgrade/Clone/DBSwitch, database backup, signed theme installation, bounded
delegation, connected Fleet/mesh, secure metrics and the experimental authentik
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

Killercoda synchronizes `main`. This repository contains learning content, not the operator release or its qualification evidence.

Apache-2.0. Provider helpers and Keycloak fixtures are adapted from HankoShell Operator, copyright Alien6 and contributors.
