The fixture names a real immutable operator image, deliberately not an approved theme builder/artifact. A digest alone does not authorize a workload purpose or prove publisher trust. The image must be rejected before any Job runs. No JAR, PVC installation or Keycloak restart is performed.

```sh
cat /root/lab/theme.yaml
kubectl -n auth apply -f /root/lab/theme.yaml
bash /root/lab/lesson.sh check-image
```{{exec}}

Use **CHECK** to verify the specific result.
