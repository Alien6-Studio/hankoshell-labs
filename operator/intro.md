# Keycloak as code

In about **20 minutes**, use HankoShell Operator to:

1. Create an OIDC client and change its callback through Kubernetes.
2. Observe an existing client, review its adoption candidate, then explicitly take ownership.
3. Obtain an OAuth token with a machine identity.

A real Kubernetes cluster, Keycloak **26.8.1** and the published operator **1.0.0** are prepared for you. Initial image downloads can take several minutes. Wait for **Ready** in the terminal before continuing.

Click a command to execute it. Each **Check** validates both Kubernetes status and actual Keycloak state. You can inspect the YAML under `/root/lab/`.

**Use only this disposable environment.** All credentials are generated for the session. Do not enter production credentials or import a kubeconfig. Free Killercoda sessions expire after one hour.

This lab tests configuration and machine authentication. It does not host a login application, exercise browser SSO, or qualify production availability. HankoShell's Kubernetes API remains experimental: `hanko.sh/v1alpha1`.
