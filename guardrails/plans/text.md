The source is an external connection. Each dry run skips every execution step. Done therefore means that the dry run finished; it does not validate a database, approve an image, clone data or establish upgrade feasibility. Positive managed lifecycle execution belongs to a separate lab.

```sh
kubectl -n auth apply -f /root/lab/source.yaml
cat /root/lab/operations.yaml
kubectl -n auth apply -f /root/lab/operations.yaml
bash /root/lab/lesson.sh check-plans
```{{exec}}

Use **CHECK** to verify the specific result.
