This broker is deliberately disabled and uses example.com URLs plus a random per-session secret. Inspect the signature-validation and trust-email choices. No Microsoft, Google or other account is required.

```sh
cat /root/lab/broker.yaml
kubectl -n auth apply -f /root/lab/broker.yaml
bash /root/lab/lesson.sh check-broker
```{{exec}}

Use **CHECK** to verify the actual result.
