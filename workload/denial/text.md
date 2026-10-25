The outsider Pod has a valid assertion signed by the same cluster for the same audience. Its different subject must not authenticate as federated-worker. This is a real negative token exchange, not an edited or forged JWT. Assertion lifetime and provider validation apply; immediate Pod-deletion revocation is not claimed.

```sh
bash /root/lab/lesson.sh check-denial
```{{exec}}

Use **CHECK** to verify the actual result.
