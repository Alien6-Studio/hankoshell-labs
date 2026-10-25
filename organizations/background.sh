#!/usr/bin/env bash
set -euo pipefail
umask 077
trap 'touch /root/lab/setup-failed' ERR
BASE='https://raw.githubusercontent.com/Alien6-Studio/hankoshell-labs/d89f78b003bc81af713c1e019dce4d86b7452a67'
curl --fail --silent --show-error --retry 3 --connect-timeout 10 --max-time 120 "$BASE/operator/assets/lab.sh" -o '/root/lab/lab.sh'
echo '5bdb198ecf9978c3f0fb14b71d6f13f4e434e9896176f20d62e507e8cf036d6d  /root/lab/lab.sh' | sha256sum -c -
curl --fail --silent --show-error --retry 3 --connect-timeout 10 --max-time 120 "$BASE/operator/assets/keycloak.yaml" -o '/root/lab/keycloak.yaml'
echo '65eb4c5df1ae06e9289740da4be6b9c85fc62c04c6659b293c87e14d0819b7a8  /root/lab/keycloak.yaml' | sha256sum -c -
curl --fail --silent --show-error --retry 3 --connect-timeout 10 --max-time 120 "$BASE/operator/assets/cilium-api.yaml" -o '/root/lab/cilium-api.yaml'
echo '15e93ede127f655af1d651978b7d0678a5678ca345d8850527ed97fcb8412f09  /root/lab/cilium-api.yaml' | sha256sum -c -
curl --fail --silent --show-error --retry 3 --connect-timeout 10 --max-time 120 "$BASE/operator/background.sh" -o '/root/lab/background.sh'
echo 'aa07cc4c733b9fbca070ebc5ecddb47ace37934abce63e56debea2df7404d6ad  /root/lab/background.sh' | sha256sum -c -
bash /root/lab/background.sh
