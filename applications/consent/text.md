Remove only the target authorization, then trigger a fresh check. RuntimeBindings must report TargetNotAuthorized for the current generation. The existing client and last-known target data remain intact; names alone do not authorize a replacement target.

```sh
kubectl -n auth annotate configmap storefront-runtime hanko.sh/runtime-application-uid-
kubectl -n auth annotate hankoapplication storefront academy.hanko.sh/runtime-review="$(date +%s)" --overwrite
bash /root/lab/lesson.sh check-runtime-refusal
```{{exec}}

Use **CHECK** to verify the actual result.
