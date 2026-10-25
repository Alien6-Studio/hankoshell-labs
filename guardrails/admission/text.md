Reserved platform, fleet and cluster roles cannot be created by a tenant role declaration. This check uses server-side dry-run and requires the specific admission refusal; a connection error does not count.

```
cat /root/lab/reserved-role.yaml
bash /root/lab/lesson.sh check-admission
```{{exec}}

Use **CHECK** to verify the specific result.
