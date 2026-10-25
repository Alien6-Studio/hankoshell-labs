# HankoShell Academy

The public learning scenarios of **HankoShell Academy**. Start with [HankoShell Operator](https://github.com/Alien6-Studio/hankoshell-operator), running on disposable Kubernetes environments.

[Start the browser lab](https://killercoda.com/alien6/scenario/operator) · [Operator documentation](https://github.com/Alien6-Studio/hankoshell-operator#readme)

The first lab covers OIDC client reconciliation, explicit adoption of an existing Keycloak client and machine authentication. Allow 20 minutes plus image downloads. Killercoda requires a free account; free sessions last up to one hour.

The lab uses the published **1.0.0** chart and image, pinned by OCI digest, with Keycloak **26.8.1**. All credentials are generated per session. Do not enter real credentials or connect an existing cluster. APIs remain experimental (`hanko.sh/v1alpha1`).

Killercoda uses Cilium. The lab adds a namespaced policy allowing only the operator to reach the `kube-apiserver` entity on its discovered port, alongside the chart’s NetworkPolicy. Cilium does not match node-hosted API servers with `ipBlock` peers by default; see [Cilium’s policy documentation](https://docs.cilium.io/en/stable/security/policy/layer3/#access-to-from-kube-apiserver). No cluster-wide Cilium settings are changed.

## Contribute

Edit the Markdown lessons or `operator/assets/`. Step checks compare Kubernetes status with actual Keycloak state. Keep the lab self-contained and use only public images and synthetic data.

Before a change, run `bash -n` on shell files, review the JSON, and rehearse every lesson in a fresh Killercoda session. For local rehearsal, use an owned kind cluster named `hankoshell-lab-<12 hex characters>` with its own kubeconfig; set `HANKOSHELL_LAB_LOCAL_CONTEXT` to that context and `HANKOSHELL_LAB_STATE` to a fresh private directory before running `operator/assets/lab.sh setup`. Delete only that disposable cluster afterwards.

Killercoda synchronizes `main`. This repository contains learning content, not the operator release or its qualification evidence.

Apache-2.0. Provider helpers and Keycloak fixtures are adapted from HankoShell Operator, copyright Alien6 and contributors.
