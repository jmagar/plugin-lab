#!/usr/bin/env bash
# Target path relative to plugin root: scripts/check-no-baked-env.sh

set -euo pipefail

repo_root="${1:-.}"

if grep -Eq '^\s*environment:' "${repo_root}/docker-compose.yaml"; then
  echo "docker-compose.yaml must not use environment: blocks" >&2
  exit 1
fi

if grep -Eq '^ENV .*(TOKEN|KEY|PASSWORD|SECRET)=' "${repo_root}/Dockerfile"; then
  echo "Dockerfile bakes sensitive env vars" >&2
  exit 1
fi

if grep -Eq '(^|/)\.env$' "${repo_root}/.dockerignore"; then
  exit 0
fi

echo ".dockerignore must exclude .env" >&2
exit 1
