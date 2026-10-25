A resource server declares the invoice resource, read/write scopes and one company-read grant. Direct company membership can read. A member of the engineering child and an outsider cannot; even the company member cannot write.

```sh
cat /root/lab/permissions.yaml
kubectl -n auth apply -f /root/lab/permissions.yaml
bash /root/lab/lesson.sh check-direct
```{{exec}}

Use **CHECK** to verify the actual result.
