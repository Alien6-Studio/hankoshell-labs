Strengthen the minimum password length in the profile, without editing the realm. The check waits for a new effective policy hash and compares the native provider configuration.

```
kubectl -n auth patch hankoiamprofile workforce --type merge --patch '{"spec":{"security":{"passwordMinLength":24}}}'
bash /root/lab/lesson.sh check-update
```{{exec}}

Use **CHECK** to verify the actual result.
