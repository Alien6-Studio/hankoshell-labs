#!/usr/bin/env bash
set -euo pipefail
printf 'Preparing your disposable Keycloak and operator'
for ((attempt=0; attempt<420; attempt++)); do
  if [[ -f /root/lab/setup-ready ]]; then printf '\nReady. Start with the first lesson.\n'; exit 0; fi
  if [[ -f /root/lab/setup-failed ]]; then printf '\nSetup failed. See /root/lab/setup.log and start a fresh session.\n'; exit 1; fi
  printf '.'
  sleep 2
done
printf '\nSetup timed out. See /root/lab/setup.log.\n'
exit 1
