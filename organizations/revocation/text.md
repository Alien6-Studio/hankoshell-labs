Remove the permission while leaving the API, scopes, resource, organizations and roles in place. Both former readers must now receive HTTP 403. This checks revocation at the authorization server; your API must still enforce its authorization decision.

```sh
kubectl -n auth patch hankoresourceserver invoices --type merge --patch '{"spec":{"permissions":[]}}'
bash /root/lab/lesson.sh check-revocation
```{{exec}}

Use **CHECK** to verify the actual result.
