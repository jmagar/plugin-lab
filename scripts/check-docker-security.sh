#!/usr/bin/env bash
# Target path relative to plugin root: scripts/check-docker-security.sh

set -euo pipefail

dockerfile="${1:-Dockerfile}"

grep -Eq '^FROM .+ AS .+' "$dockerfile"
grep -Eq '^USER ' "$dockerfile"
grep -Eq '^HEALTHCHECK ' "$dockerfile"

if grep -Eq '^ENV .*(TOKEN|KEY|PASSWORD|SECRET)=' "$dockerfile"; then
  echo "Sensitive ENV found in Dockerfile" >&2
  exit 1
fi
