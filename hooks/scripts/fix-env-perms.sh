#!/usr/bin/env bash
# Target path relative to plugin root: hooks/scripts/fix-env-perms.sh

set -euo pipefail

ENV_FILE="${CLAUDE_PLUGIN_ROOT}/.env"
[ -f "$ENV_FILE" ] || exit 0

cat > /dev/null

chmod 600 "$ENV_FILE"
for bak in "${ENV_FILE}".bak.*; do
  [ -f "$bak" ] && chmod 600 "$bak"
done
