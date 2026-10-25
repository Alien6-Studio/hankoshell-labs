# Change the callback

Modify the declaration without using the Keycloak console:

```bash
kubectl -n auth patch hankoapplication customer-portal --type merge \
  --patch '{"spec":{"redirectURIs":["https://portal.example.com/oidc/callback"]}}'
bash /root/lab/lab.sh check-callback
```{{exec}}

`bash /root/lab/lab.sh client customer-portal`{{exec}}

The provider now contains `/oidc/callback`. The check compares the UUID with the one recorded in the previous step: the client was updated in place.

In a delivery workflow, commit this change to the manifest and let your CI or GitOps controller apply it. This lab uses `kubectl` so you can see each step directly.
