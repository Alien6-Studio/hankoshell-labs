Setup created `existing-portal` directly in Keycloak, before installing the operator. It has no HankoShell ownership markers.

`bash /root/lab/lab.sh client existing-portal`{{exec}}

Inspect and apply the read-only inventory connection and application declaration:

```bash
cat /root/lab/existing-portal.yaml
kubectl -n auth apply -f /root/lab/existing-portal.yaml
bash /root/lab/lab.sh check-observe
```{{exec}}

Inspect the candidate:

```bash
kubectl -n auth get hankoapplication existing-portal -o json \
  | jq '.status.adoptionCandidate | {candidateHash,complete,truncated,approvable,providerIdentity}'
```{{exec}}

The inventory account has only `view-realm` and `view-clients` permissions in this test realm. The check compares the complete client representation with its original snapshot: **Observe must not change it**.

A candidate identifies the exact provider object and configuration proposed for adoption. Review it before approving; a stale or incomplete candidate is not a safe shortcut to management.
