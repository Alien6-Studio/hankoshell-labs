Workload owners pre-create their targets and approve the exact application and ServiceAccount UIDs. The helper prepares synthetic targets and their explicit consent, then attaches the runtime binding. The operator delivers public identity.json metadata and a credential reference/value in separate targets while preserving unrelated fields. No ADK or web app is deployed.

```
bash /root/lab/lesson.sh bind-runtime
bash /root/lab/lesson.sh check-runtime
```{{exec}}

Use **CHECK** to verify the actual result.
