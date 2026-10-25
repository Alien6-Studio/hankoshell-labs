Import is discovery, not adoption. Inspect the imported-by label and Observe mode. A matching client name does not grant ownership. Explicit adoption is a separate reviewed operation, covered by the introductory operator lab.

```sh
cat /root/lab/import.yaml
kubectl -n auth apply -f /root/lab/import.yaml
bash /root/lab/lesson.sh check-import
kubectl -n auth get hankoimport,hankoapplication,hankorealm
```{{exec}}

Use **CHECK** to verify the actual result.
