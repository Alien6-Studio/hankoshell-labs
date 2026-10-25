A trusted certificate alone is insufficient: its SPIFFE URI must match the allowlist. The check surrounds refused handshakes with successful authorized requests, so an unavailable endpoint cannot count as a pass.

```
bash /root/lab/lesson.sh check-refusal
```{{exec}}

Use **CHECK** to verify the actual result.
