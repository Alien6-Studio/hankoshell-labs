The web client has an exact callback, web origin, logout redirect and a client-scoped role. The operator can write only the named credential Secrets listed in this lab installation. Secret values stay in private files.

```
cat /root/lab/clients.yaml
kubectl -n auth apply -f /root/lab/clients.yaml
bash /root/lab/lesson.sh check-web
```{{exec}}

Use **CHECK** to verify the actual result.
