Learn how the operator checks lifecycle plans, approval, image trust and connected-resource prerequisites. You will inspect dry runs and deliberate refusals. Successful managed upgrades, theme installation, connected Hub synchronization and mesh enforcement are outside this lab.

The final step explains notification ownership: Keycloak sends authentication email, the Hanko API owns platform messaging configuration, and the operator exposes events and metrics. The deprecated resource is the legacy `HankoEmailProvider` CRD.

Allow 20 minutes and wait for **Ready**. Operator **1.0.0** and Keycloak **26.8.1** are pinned by digest. All identities and credentials are generated for this disposable session. No existing cluster, Hub, registry credential or mail account is required. Lifecycle controllers are enabled in this sandbox; every non-dry-run action still needs its own local approval.
