A fresh non-dry-run operation must stop at an exact UID/generation/instance/intent approval request. Enabling the controller is not approval. This lesson intentionally does not approve or execute the operation. Configuration snapshot approval is exercised in the inventory lab.

```
kubectl -n auth apply -f /root/lab/unapproved.yaml
bash /root/lab/lesson.sh check-approval
kubectl -n auth get hankooperation unapproved-upgrade -o jsonpath='{.status.conditions}{"\n"}'
```{{exec}}

Use **CHECK** to verify the specific result.
