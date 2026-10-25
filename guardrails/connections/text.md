The .invalid endpoint is a deliberately unconfigured placeholder, and no Hub credential exists. The tenant cannot synchronize and its mesh registration cannot attest a current identity. This demonstrates prerequisite refusal, not Hub protocol compatibility or network enforcement.

```
cat /root/lab/connections.yaml
kubectl -n auth apply -f /root/lab/connections.yaml
bash /root/lab/lesson.sh check-connections
```{{exec}}

Use **CHECK** to verify the specific result.
