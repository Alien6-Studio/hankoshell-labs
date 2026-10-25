The worker obtains an actual client_credentials token using its owned Secret. Only the assertion results are printed. The token contains an audience and a public environment claim; decoding that payload is not a replacement for an application validating its signature, issuer and audience.

```sh
bash /root/lab/lesson.sh check-claims
kubectl -n auth get secret hanko-sa-report-worker -o custom-columns=NAME:.metadata.name,TYPE:.type
```{{exec}}

Use **CHECK** to verify the actual result.
