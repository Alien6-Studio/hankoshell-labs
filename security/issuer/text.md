HankoIssuer writes a host-to-realm binding into a Hanko API deployment. Here that deployment is a zero-replica fixture: no private API image, DNS record, ingress or functioning Hanko API is provided. The exact deployment name is locally allowlisted.

```sh
cat /root/lab/issuer.yaml
kubectl -n auth apply -f /root/lab/issuer.yaml
bash /root/lab/lesson.sh check-issuer
kubectl -n auth get hankorealm,hankoiamprofile,hankoissuer
```{{exec}}

Use **CHECK** to verify the actual result.
