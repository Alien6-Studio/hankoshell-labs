Create a separate managed client, then restart the actual controller and trigger a fresh reconciliation. Check both the managed provider configuration and the unchanged imported client. This single-node restart does not qualify infrastructure HA.

```sh
kubectl -n auth apply -f /root/lab/customer-portal.yaml
bash /root/lab/lab.sh check-oidc
bash /root/lab/lesson.sh restart
bash /root/lab/lesson.sh check-recovery
```{{exec}}

Use **CHECK** to verify the actual result.
