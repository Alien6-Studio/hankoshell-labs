# Contributing

Open a lab problem or scenario proposal before a substantial change. Keep each
journey independent, runnable within a free Killercoda session and clear about
what it proves. Use Markdown, fixtures and narrow shell checks; no additional
qualification framework is needed.

## Workflow

1. Branch from `main` and edit the scenario's lessons or `assets/`.
2. Run `bash -n` on changed shell files and `jq -e .` on changed JSON. Keep
   executable blocks in Killercoda's documented format.
3. Rehearse changed executable steps in a fresh disposable environment, following
   the [local rehearsal boundaries](README.md#contribute). Never use a shared
   cluster, real identity or private registry. Do not print credentials.
4. Commit with `git commit -S -s` and open a pull request describing the learner
   outcome, validation and limits. Every contributor commit needs a GitHub-verified
   signature and an author-matching sign-off certifying the
   [Developer Certificate of Origin](https://developercertificate.org/).

Content CI validates shell/JSON syntax, lesson references and commit sign-offs.
CodeQL checks Actions workflows. Fork workflows may need maintainer approval;
they receive no project secrets. Automated checks do not replace a hosted run.

## Merging and publication

Maintainers squash through a pull request after required checks and review
threads pass. Retain contributor sign-offs, add the resulting author's sign-off
and verify the merged commit's GitHub signature. `main` is protected against
direct changes, deletion and force pushes. Killercoda synchronizes `main` through
the existing read-only deploy key and signed webhook; merging publishes content.
Promote a new scenario only after a fresh hosted walkthrough succeeds.
The reviewed branch and tag rules are kept in [`.github/rulesets/`](.github/rulesets/).

Operator defects belong in the [operator repository](https://github.com/Alien6-Studio/hankoshell-operator/issues).
Report vulnerabilities through [SECURITY.md](SECURITY.md) and follow the
[Code of Conduct](CODE_OF_CONDUCT.md).
