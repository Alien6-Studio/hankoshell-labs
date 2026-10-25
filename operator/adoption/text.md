# Approve, then manage

For this synthetic client, approve the exact candidate you just inspected:

```bash
candidate=$(kubectl -n auth get hankoapplication existing-portal \
  -o jsonpath='{.status.adoptionCandidate.candidateHash}')
kubectl -n auth annotate hankoapplication existing-portal \
  hanko.sh/adoption-contract=hanko.sh/adoption-contract/v1alpha1 \
  "hanko.sh/adoption-candidate=$candidate"
bash /root/lab/lab.sh check-receipt
```{{exec}}

The receipt check verifies that acquisition changed only ownership metadata. Configuration management is a **separate decision**:

```bash
kubectl -n auth patch hankoapplication existing-portal --type merge \
  --patch '{"spec":{"mode":"Manage"}}'
kubectl -n auth annotate hankoapplication existing-portal \
  hanko.sh/adoption-source- hanko.sh/adoption-contract- hanko.sh/adoption-candidate-
bash /root/lab/lab.sh check-adoption
```{{exec}}

`bash /root/lab/lab.sh client existing-portal`{{exec}}

The UUID remains unchanged and the adoption receipt is verified. The operator can now reconcile the configuration it owns.

In your own environment, use the supported adoption contract and review every candidate. This example is not permission to take over objects owned by another manager.
