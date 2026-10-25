The SAML client uses HTTPS POST ACS destinations and signed assertions/responses. The check reads the public IdP signing certificate from metadata. It does not claim a browser or SP login, request signing, encryption or SAML logout support.

```sh
bash /root/lab/lesson.sh check-saml
kubectl -n auth get hankoapplication legacy-saml
```{{exec}}

Use **CHECK** to verify the actual result.
