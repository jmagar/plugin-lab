#!/usr/bin/env bash
# fix-env-perms.sh — Re-enforce chmod 600 on .env and backups
# Template hook script for MCP server plugins.
# Runs as PostToolUse hook (matcher: Write|Edit|MultiEdit|Bash) to ensure
# .env permissions are always correct, even if a tool accidentally changes them.
#
# Usage in hooks/hooks.json:
#   "matcher": "Write|Edit|MultiEdit|Bash",
#   "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/fix-env-perms.sh"
set -euo pipefail

ENV_FILE="${CLAUDE_PLUGIN_ROOT:-.}/.env"
[ -f "$ENV_FILE" ] || exit 0

# Read and discard stdin (PostToolUse hooks receive JSON on stdin)
cat > /dev/null

# Unconditionally enforce permissions — the PostToolUse matcher already limits
# this to Write|Edit|MultiEdit|Bash. Checking whether the command string
# contains ".env" is a heuristic that misses variable-based paths like:
#   f=".env"; echo "KEY=val" >> "$f"
chmod 600 "$ENV_FILE"
for bak in "${CLAUDE_PLUGIN_ROOT:-.}/backups"/.env.bak.*; do
  [ -f "$bak" ] && chmod 600 "$bak"
done
