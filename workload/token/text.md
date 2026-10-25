The worker Pod has an explicit projected service-account token for the Keycloak realm audience, with a requested 600-second lifetime. The check reads it into a private file and performs client authentication over verified TLS. Tokens are not printed. This does not implement application authorization.

```
bash /root/lab/lesson.sh check-token
```{{exec}}

Use **CHECK** to verify the actual result.
