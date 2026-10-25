Request a rotation now rather than waiting 30 days. The check authenticates with both credentials, expects rejection of the old one and acceptance of the new one, and verifies the same native client UUID. Running applications must reload their credential; already-issued tokens have their own expiry.

```sh
rotation="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
kubectl -n auth patch hankoserviceaccount report-worker --type merge \
  --patch "$(jq -nc --arg at "$rotation" '{spec:{secretRotationPolicy:{forceRotateAt:$at}}}')"
bash /root/lab/lesson.sh check-rotation
```{{exec}}

Use **CHECK** to verify the actual result.
