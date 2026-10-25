Authenticate a workload using a short-lived Kubernetes assertion instead of a client secret. Allow 25 minutes. The lab administrator exposes only this disposable cluster’s public OIDC discovery/JWKS endpoints and prepares native client authentication plus separate scoped identities. No TokenReview, private API data or existing cluster is shared. Public signing keys do not contain credentials.

Wait for **Ready** in the terminal. The published operator **1.0.0** and Keycloak **26.8.1** are pinned by digest. Use synthetic data only. Do not connect another cluster or enter real credentials.
