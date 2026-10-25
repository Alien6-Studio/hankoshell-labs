#!/usr/bin/env bash
set -euo pipefail
umask 077
trap 'touch /root/lab/setup-failed' ERR
# Official Helm distribution, pinned and checksum-verified.
if ! command -v helm >/dev/null; then
  curl -fsSL --connect-timeout 10 --max-time 120 https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz -o /root/lab/helm.tgz
  echo 'fb5d12662fde6eeff36ac4ccacbf3abed96b0ee2de07afdde4edb14e613aee24  /root/lab/helm.tgz' | sha256sum -c -
  tar -xzf /root/lab/helm.tgz -C /root/lab
  install -m 755 /root/lab/linux-amd64/helm /usr/local/bin/helm
  rm -r /root/lab/linux-amd64 /root/lab/helm.tgz
fi
if [[ -f /root/lab/lesson.sh ]]; then
  bash /root/lab/lesson.sh setup > /root/lab/setup.log 2>&1
else
  bash /root/lab/lab.sh setup > /root/lab/setup.log 2>&1
fi
touch /root/lab/setup-ready
