# Authenticate a machine

A service does not need a human login. Declare its dedicated identity:

```bash
cat /root/lab/report-worker.yaml
kubectl -n auth apply -f /root/lab/report-worker.yaml
bash /root/lab/lab.sh check-machine
```{{exec}}

The operator creates the Keycloak client and projects its credential into the explicitly permitted Kubernetes Secret `hanko-sa-report-worker`.

The check reads that synthetic credential privately and requests a real OAuth **client_credentials** token over verified HTTPS. It displays only the token type and lifetime; the token and secret stay out of the output.

```bash
kubectl -n auth get hankoapplication,hankoserviceaccount
kubectl -n auth get secret hanko-sa-report-worker \
  -o custom-columns=NAME:.metadata.name,TYPE:.type
```{{exec}}

A successful token request proves machine authentication. It does not prove access to a business API: that API must validate the token and enforce its own audience and permissions. The configured 30-day rotation policy cannot be qualified in a one-hour lab.
