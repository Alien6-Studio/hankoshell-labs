This compatibility resource is retained for old configurations. Even enabled: true must report Deprecated and DeliveryReady=False with DelegatedToAPI. It does not configure SMTP, read Microsoft Graph credentials or send a message.

```sh
cat /root/lab/email.yaml
kubectl -n auth apply -f /root/lab/email.yaml
bash /root/lab/lesson.sh check-email
```{{exec}}

Use **CHECK** to verify the specific result.
