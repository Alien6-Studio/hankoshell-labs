This binding records the exact Kubernetes ServiceAccount UID, the source connection and trust. No client-secret output is authorized or required. Ready verifies native configuration; the next step proves authentication.

```sh
cat /root/lab/identity.json
kubectl -n auth apply -f /root/lab/identity.json
bash /root/lab/lesson.sh check-identity
```{{exec}}

Use **CHECK** to verify the actual result.
