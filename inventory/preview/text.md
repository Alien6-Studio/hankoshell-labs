The external instance references a dedicated inventory identity. Dry-run reports authorized realm/client inventory without generating desired-state CRs. The check compares the existing client before and after the scan.

```sh
cat /root/lab/source.yaml
kubectl -n auth apply -f /root/lab/source.yaml
bash /root/lab/lesson.sh check-preview
```{{exec}}

Use **CHECK** to verify the actual result.
