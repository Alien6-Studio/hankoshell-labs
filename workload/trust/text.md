The manifest was generated from this session’s actual issuer, kube-system UID and public CA DER hash. Review those values. Names alone do not authorize a replacement cluster.

```
cat /root/lab/trust.json
kubectl -n auth apply -f /root/lab/trust.json
bash /root/lab/lesson.sh check-trust
```{{exec}}

Use **CHECK** to verify the actual result.
