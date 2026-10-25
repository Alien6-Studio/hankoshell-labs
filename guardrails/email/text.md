Email delivery and operator alerts have different owners:

- **Keycloak** sends authentication email, including verification and password recovery, through the realm's SMTP configuration.
- **The Hanko platform API** owns platform email provider configuration, vault credential lookup and explicit provider tests. A successful Graph test does not configure Keycloak's SMTP or prove final mailbox delivery.
- **The operator** publishes Kubernetes events, resource conditions and Prometheus metrics. A monitoring stack can route alerts to email or other channels.

`HankoEmailProvider` is a legacy configuration resource retained for compatibility. Its controller reports `Deprecated` and `DeliveryReady=False`, with reason `DelegatedToAPI`, even when `enabled: true`. It does not configure SMTP, read Microsoft Graph credentials or send a message. The deprecation applies to this CRD, not to notification delivery.

```
cat /root/lab/email.yaml
kubectl -n auth apply -f /root/lab/email.yaml
bash /root/lab/lesson.sh check-email
```{{exec}}

Use **CHECK** to verify the compatibility status. This exercise sends no email and needs no mail account.

[Operator email migration guidance](https://github.com/Alien6-Studio/hankoshell-operator/blob/main/docs/secure-deployment.md#upgrade-and-rollback)
