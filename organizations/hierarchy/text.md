Inspect the root native Organization, child group, composite role and group-role mappings. This lab explicitly adds target-realm manage-users/view-users to its disposable organization writer. No real members or platform projection are involved.

```
cat /root/lab/organization.yaml
kubectl -n auth apply -f /root/lab/organization.yaml
bash /root/lab/lesson.sh check-hierarchy
bash /root/lab/lesson.sh arrange-members
```{{exec}}

Use **CHECK** to verify the actual result.
