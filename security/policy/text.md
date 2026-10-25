Read the profile and realm together. The lab identity can manage only the synthetic example realm. MFA settings are inspected in Keycloak; a Ready policy is not evidence of a completed human login.

```
cat /root/lab/policy.yaml
kubectl -n auth apply -f /root/lab/policy.yaml
bash /root/lab/lesson.sh check-policy
```{{exec}}

Use **CHECK** to verify the actual result.
