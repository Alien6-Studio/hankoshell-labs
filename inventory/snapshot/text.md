The configuration snapshot contains the supported realm, application, service-account and issuer declarations in scope. It does not capture all 17 CRDs, provider state, passwords or a database dump. It is not a portable backup/restore promise.

```
cat /root/lab/snapshot.yaml
kubectl -n auth apply -f /root/lab/snapshot.yaml
bash /root/lab/lesson.sh review-snapshot
```{{exec}}

Review the displayed specification, object UID, generation, source instance UID and exact intent. The lifecycle feature is explicitly enabled in this lab. Its local administrator policy recognizes `system:masters` and the kubeadm `kubeadm:cluster-admins` group; the operator ServiceAccount belongs to neither. Inspect your session identity before approving. It still requires independent local administrator approval. This snapshot has `includeData: false`. After reviewing, approve only this exact request:

```
kubectl auth whoami
bash /root/lab/lesson.sh approve-snapshot
bash /root/lab/lesson.sh check-snapshot
```{{exec}}

Use **CHECK** to verify the actual result.
