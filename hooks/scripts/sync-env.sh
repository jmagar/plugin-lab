#!/usr/bin/env bash
# Target path relative to plugin root: hooks/scripts/sync-env.sh

set -euo pipefail

ENV_FILE="${CLAUDE_PLUGIN_ROOT}/.env"
LOCK_FILE="${CLAUDE_PLUGIN_ROOT}/.env.lock"

exec 9>"$LOCK_FILE"
flock -w 10 9 || { echo "sync-env: failed to acquire lock after 10s" >&2; exit 1; }

declare -A MANAGED=(
  [MY_SERVICE_URL]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL:-}"
  [MY_SERVICE_API_KEY]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY:-}"
  [MY_SERVICE_MCP_URL]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_MCP_URL:-}"
  [MY_SERVICE_MCP_TOKEN]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_MCP_TOKEN:-}"
)

touch "$ENV_FILE"

if [ -s "$ENV_FILE" ]; then
  cp "$ENV_FILE" "${ENV_FILE}.bak.$(date +%s)"
fi

for key in "${!MANAGED[@]}"; do
  value="${MANAGED[$key]}"
  [ -z "$value" ] && continue
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    awk -v k="$key" -v v="$value" '$0 ~ "^"k"=" { print k"="v; next } { print }' \
      "$ENV_FILE" > "${ENV_FILE}.tmp" && mv "${ENV_FILE}.tmp" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
done

if ! grep -q "^MY_SERVICE_MCP_TOKEN=.\+" "$ENV_FILE" 2>/dev/null; then
  echo "sync-env: ERROR — MY_SERVICE_MCP_TOKEN is not set." >&2
  echo "  Generate one:  openssl rand -hex 32" >&2
  echo "  Then paste it into the plugin's userConfig MCP token field." >&2
  exit 1
fi

chmod 600 "$ENV_FILE"

mapfile -t baks < <(ls -t "${ENV_FILE}".bak.* 2>/dev/null)
for bak in "${baks[@]}"; do chmod 600 "$bak"; done
for bak in "${baks[@]:3}"; do rm -f "$bak"; done
