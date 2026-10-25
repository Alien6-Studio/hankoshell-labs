The operator is installed in `auth`, connected to a dedicated Keycloak realm named `example`. It runs without the HankoShell Hub, API or dashboard.

Inspect the declaration:

`cat /root/lab/customer-portal.yaml`{{exec}}

The SPA client uses the authorization-code flow. Its callback is an example URL; this exercise does not deploy a web application there.

Apply it:

`kubectl -n auth apply -f /root/lab/customer-portal.yaml`{{exec}}

Validate reconciliation and the actual Keycloak client:

`bash /root/lab/lab.sh check-oidc`{{exec}}

Inspect the provider result:

`bash /root/lab/lab.sh client customer-portal`{{exec}}

The check requires `Ready` **for the current generation**, then confirms that Keycloak contains the public OIDC client and declared callback. It also records the UUID for the next step.
