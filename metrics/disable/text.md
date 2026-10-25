Restore the original reviewed values. The helper waits for the rollout, then checks that the metrics Service and container port are gone and the bind address is disabled. This does not revoke the Kubernetes administrator’s port-forward permission.

```
bash /root/lab/lesson.sh disable
bash /root/lab/lesson.sh check-default
```{{exec}}

Use **CHECK** to verify the actual result.
