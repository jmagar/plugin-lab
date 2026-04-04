#!/usr/bin/env bash
# Target path relative to plugin root: scripts/lint-plugin.sh

set -euo pipefail

fail() {
  echo "lint-plugin: $1" >&2
  exit 1
}

run_language_checks() {
  if [ -f pyproject.toml ]; then
    uv run ruff check .
    uv run ruff format --check .
    uv run ty check
    return
  fi

  if [ -f package.json ]; then
    npx biome check .
    npm test -- --runInBand
    return
  fi

  if [ -f Cargo.toml ]; then
    cargo fmt --check
    cargo clippy -- -D warnings
    return
  fi

  fail "unable to determine language toolchain from project manifest"
}

read_project_version() {
  if [ -f Cargo.toml ]; then
    python3 - <<'PY'
import tomllib
from pathlib import Path
data = tomllib.loads(Path("Cargo.toml").read_text())
print(data["package"]["version"])
PY
    return
  fi

  if [ -f package.json ]; then
    python3 - <<'PY'
import json
from pathlib import Path
data = json.loads(Path("package.json").read_text())
print(data["version"])
PY
    return
  fi

  if [ -f pyproject.toml ]; then
    python3 - <<'PY'
import tomllib
from pathlib import Path
data = tomllib.loads(Path("pyproject.toml").read_text())
print(data["project"]["version"])
PY
    return
  fi

  fail "missing project manifest (Cargo.toml, package.json, or pyproject.toml)"
}

[ -f .claude-plugin/plugin.json ] || fail "missing .claude-plugin/plugin.json"
[ -f .codex-plugin/plugin.json ] || fail "missing .codex-plugin/plugin.json"
[ -f .mcp.json ] || fail "missing .mcp.json"
[ -f .env.example ] || fail "missing .env.example"
[ -f CHANGELOG.md ] || fail "missing CHANGELOG.md"
[ -f tests/test_live.sh ] || fail "missing tests/test_live.sh"

project_version="$(read_project_version)"
claude_plugin_version="$(jq -r '.version // empty' .claude-plugin/plugin.json)"
codex_plugin_version="$(jq -r '.version // empty' .codex-plugin/plugin.json)"

[ -n "$project_version" ] || fail "project manifest version is empty"
[ -n "$claude_plugin_version" ] || fail ".claude-plugin/plugin.json version is empty"
[ -n "$codex_plugin_version" ] || fail ".codex-plugin/plugin.json version is empty"

[ "$project_version" = "$claude_plugin_version" ] \
  || fail "version mismatch: project manifest=$project_version .claude-plugin/plugin.json=$claude_plugin_version"
[ "$project_version" = "$codex_plugin_version" ] \
  || fail "version mismatch: project manifest=$project_version .codex-plugin/plugin.json=$codex_plugin_version"

grep -q "MY_SERVICE_MCP_TOKEN" .env.example || fail ".env.example must define MY_SERVICE_MCP_TOKEN"
grep -q "my_service_help" tests/test_live.sh || fail "tests/test_live.sh must cover my_service_help"
grep -q "confirm" tests/test_live.sh || fail "tests/test_live.sh must cover destructive confirmation"
grep -q "pagination" tests/test_live.sh || fail "tests/test_live.sh must validate pagination metadata"

if grep -Rq "MCP_BEARER_TOKEN" .; then
  fail "generic MCP_BEARER_TOKEN naming found; use MY_SERVICE_MCP_TOKEN"
fi

if [ -x hooks/scripts/ensure-ignore-files.sh ] || [ -f hooks/scripts/ensure-ignore-files.sh ]; then
  bash hooks/scripts/ensure-ignore-files.sh --check .
fi

if [ -f .env ] && { [ -x hooks/scripts/fix-env-perms.sh ] || [ -f hooks/scripts/fix-env-perms.sh ]; }; then
  CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/scripts/fix-env-perms.sh < /dev/null
fi

run_language_checks

echo "lint-plugin: OK"
