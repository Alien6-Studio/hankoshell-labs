Expand only this permission to owned descendants. Fresh provider authorization decisions should now allow the engineering identity to read. The outsider and undeclared write action remain denied. Group role inheritance and direct organization policies are different mechanisms.

```
kubectl -n auth patch hankoresourceserver invoices --type json --patch '[{"op":"replace","path":"/spec/permissions/0/principals/0/includeDescendants","value":true}]'
bash /root/lab/lesson.sh check-descendants
```{{exec}}

Use **CHECK** to verify the actual result.
