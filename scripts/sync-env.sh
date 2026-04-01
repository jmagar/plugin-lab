#!/usr/bin/env bash
# sync-env.sh — Sync Claude Code userConfig → .env
# Template hook script for MCP server plugins.
# Runs at SessionStart. Maps CLAUDE_PLUGIN_OPTION_* → .env keys.
# Uses flock to prevent concurrent session races.
# Uses awk for value replacement (not sed — avoids pipe-delimiter injection).
# Keeps max 3 backups, all chmod 600.
#
# IMPORTANT: Customize the MANAGED associative array for your service.
# Replace MY_SERVICE with your actual service prefix.
#
# Usage in hooks/hooks.json:
#   "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/sync-env.sh"
set -euo pipefail

ENV_FILE="${CLAUDE_PLUGIN_ROOT:-.}/.env"
BACKUP_DIR="${CLAUDE_PLUGIN_ROOT:-.}/backups"
LOCK_FILE="${CLAUDE_PLUGIN_ROOT:-.}/.env.lock"
mkdir -p "$BACKUP_DIR"

# Serialize concurrent sessions (two tabs starting at the same time)
exec 9>"$LOCK_FILE"
flock -w 10 9 || { echo "sync-env: failed to acquire lock after 10s" >&2; exit 1; }

# ── Customize this block for your service ─────────────────────────────────────
# Map each userConfig key (CLAUDE_PLUGIN_OPTION_*) to the .env key the server reads.
declare -A MANAGED=(
  [MY_SERVICE_URL]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL:-}"
  [MY_SERVICE_API_KEY]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY:-}"
  [MY_SERVICE_MCP_URL]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_MCP_URL:-}"
  [MY_SERVICE_MCP_TOKEN]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_MCP_TOKEN:-}"
)
# ── End customization ─────────────────────────────────────────────────────────

touch "$ENV_FILE"

# Backup before writing (max 3 retained)
if [ -s "$ENV_FILE" ]; then
  cp "$ENV_FILE" "${BACKUP_DIR}/.env.bak.$(date +%s)"
fi

# Write managed keys — awk handles arbitrary values safely (no delimiter injection)
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

# Fail if bearer token is not set — do NOT auto-generate.
# Auto-generated tokens cause a mismatch: the server reads the generated token
# but Claude Code sends the (empty) userConfig value. Every MCP call returns 401.
if ! grep -q "^MY_SERVICE_MCP_TOKEN=.\+" "$ENV_FILE" 2>/dev/null; then
  echo "sync-env: ERROR — MY_SERVICE_MCP_TOKEN is not set." >&2
  echo "  Generate one:  openssl rand -hex 32" >&2
  echo "  Then paste it into the plugin's userConfig MCP token field." >&2
  exit 1
fi

chmod 600 "$ENV_FILE"

# Prune old backups
mapfile -t baks < <(ls -t "${BACKUP_DIR}"/.env.bak.* 2>/dev/null)
for bak in "${baks[@]}"; do chmod 600 "$bak"; done
for bak in "${baks[@]:3}"; do rm -f "$bak"; done
