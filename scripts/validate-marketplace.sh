#!/usr/bin/env bash
# Validate .claude-plugin/marketplace.json for local-path and GitHub-sourced plugins.
#
# Usage: validate-marketplace.sh [repo-root]
#   repo-root  Path to the plugin repo to validate (default: current directory)
#
# Checks:
# - marketplace.json exists and is valid JSON
# - required top-level and per-plugin fields exist
# - local plugin source paths exist and expose .claude-plugin/plugin.json
# - GitHub repos are reachable
# - if a remote repo exposes .claude-plugin/plugin.json on its default branch,
#   compare marketplace name/version against the remote manifest

set -euo pipefail

REPO_ROOT="${1:-$(pwd)}"
MARKETPLACE_FILE="$REPO_ROOT/.claude-plugin/marketplace.json"

PASS=0
FAIL=0
WARN=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1 — $2"; FAIL=$((FAIL + 1)); }
warn() { echo "  WARN: $1 — $2"; WARN=$((WARN + 1)); }

tmp_files=()
cleanup() {
  if [[ ${#tmp_files[@]} -gt 0 ]]; then
    rm -f "${tmp_files[@]}"
  fi
}
trap cleanup EXIT

fetch_url() {
  local url="$1"
  local out="$2"
  curl -fsSL \
    -H 'Accept: application/vnd.github+json' \
    -H 'User-Agent: claude-homelab/validate-marketplace' \
    "$url" -o "$out"
}

validate_local_plugin() {
  local plugin_name="$1"
  local marketplace_version="$2"
  local source_path="$3"
  local resolved_path="$REPO_ROOT/${source_path#./}"
  local manifest_path="$resolved_path/.claude-plugin/plugin.json"

  if [[ ! -d "$resolved_path" ]]; then
    fail "$plugin_name source path" "local source not found: $source_path"
    return
  fi
  pass "$plugin_name source path exists"

  if [[ ! -f "$manifest_path" ]]; then
    fail "$plugin_name manifest" "missing .claude-plugin/plugin.json in $source_path"
    return
  fi

  if ! jq empty "$manifest_path" >/dev/null 2>&1; then
    fail "$plugin_name manifest" "invalid JSON: $manifest_path"
    return
  fi
  pass "$plugin_name manifest JSON valid"

  local manifest_name manifest_version
  manifest_name="$(jq -r '.name // empty' "$manifest_path")"
  manifest_version="$(jq -r '.version // empty' "$manifest_path")"

  if [[ "$manifest_name" == "$plugin_name" ]]; then
    pass "$plugin_name manifest name matches marketplace"
  else
    fail "$plugin_name manifest name" "marketplace=$plugin_name manifest=$manifest_name"
  fi

  if [[ -n "$marketplace_version" && "$manifest_version" == "$marketplace_version" ]]; then
    pass "$plugin_name manifest version matches marketplace"
  else
    fail "$plugin_name manifest version" "marketplace=$marketplace_version manifest=$manifest_version"
  fi
}

validate_github_plugin() {
  local plugin_name="$1"
  local marketplace_version="$2"
  local repo="$3"
  local homepage="$4"

  local repo_meta manifest_tmp manifest_url default_branch repo_url remote_name remote_version
  repo_meta="$(mktemp)"
  tmp_files+=("$repo_meta")

  if ! fetch_url "https://api.github.com/repos/$repo" "$repo_meta"; then
    fail "$plugin_name GitHub repo" "repo not reachable: $repo"
    return
  fi
  pass "$plugin_name GitHub repo reachable"

  default_branch="$(jq -r '.default_branch // empty' "$repo_meta")"
  if [[ -z "$default_branch" ]]; then
    fail "$plugin_name GitHub repo" "could not determine default branch"
    return
  fi
  pass "$plugin_name default branch detected: $default_branch"

  repo_url="https://github.com/$repo"
  if [[ -n "$homepage" && "$homepage" == "$repo_url" ]]; then
    pass "$plugin_name homepage matches repo URL"
  else
    warn "$plugin_name homepage" "homepage does not match repo URL ($repo_url)"
  fi

  manifest_tmp="$(mktemp)"
  tmp_files+=("$manifest_tmp")
  manifest_url="https://raw.githubusercontent.com/$repo/$default_branch/.claude-plugin/plugin.json"

  if ! fetch_url "$manifest_url" "$manifest_tmp"; then
    warn "$plugin_name remote manifest" "no .claude-plugin/plugin.json at $manifest_url"
    return
  fi

  if ! jq empty "$manifest_tmp" >/dev/null 2>&1; then
    warn "$plugin_name remote manifest" "fetched manifest is not valid JSON"
    return
  fi
  pass "$plugin_name remote manifest fetched"

  remote_name="$(jq -r '.name // empty' "$manifest_tmp")"
  remote_version="$(jq -r '.version // empty' "$manifest_tmp")"

  if [[ -n "$remote_name" && "$remote_name" == "$plugin_name" ]]; then
    pass "$plugin_name remote manifest name matches marketplace"
  else
    fail "$plugin_name remote manifest name" "marketplace=$plugin_name manifest=$remote_name"
  fi

  if [[ -n "$marketplace_version" && -n "$remote_version" && "$remote_version" == "$marketplace_version" ]]; then
    pass "$plugin_name remote manifest version matches marketplace"
  else
    fail "$plugin_name remote manifest version" "marketplace=$marketplace_version manifest=$remote_version"
  fi
}

echo "=== Validating Claude Homelab Marketplace ==="
echo

if [[ ! -f "$MARKETPLACE_FILE" ]]; then
  echo "FAIL: marketplace file missing: $MARKETPLACE_FILE"
  exit 1
fi

if ! jq empty "$MARKETPLACE_FILE" >/dev/null 2>&1; then
  echo "FAIL: invalid JSON in $MARKETPLACE_FILE"
  exit 1
fi
pass "marketplace JSON syntax valid"

marketplace_name="$(jq -r '.name // empty' "$MARKETPLACE_FILE")"
owner_name="$(jq -r '.owner.name // empty' "$MARKETPLACE_FILE")"
plugin_count="$(jq '.plugins | length' "$MARKETPLACE_FILE")"

[[ -n "$marketplace_name" ]] && pass "marketplace name: $marketplace_name" || fail "marketplace name" "missing"
[[ -n "$owner_name" ]] && pass "marketplace owner: $owner_name" || fail "marketplace owner" "missing owner.name"
[[ "$plugin_count" -gt 0 ]] && pass "marketplace plugin count: $plugin_count" || fail "marketplace plugins" "plugins array is empty"

echo
echo "=== Validating Plugin Entries ==="
echo

while IFS= read -r plugin_json; do
  plugin_name="$(jq -r '.name // empty' <<<"$plugin_json")"
  plugin_version="$(jq -r '.version // empty' <<<"$plugin_json")"
  plugin_description="$(jq -r '.description // empty' <<<"$plugin_json")"
  plugin_category="$(jq -r '.category // empty' <<<"$plugin_json")"
  plugin_homepage="$(jq -r '.homepage // empty' <<<"$plugin_json")"
  source_type="$(jq -r 'if (.source | type) == "string" then "string" else (.source.source // empty) end' <<<"$plugin_json")"

  echo "Plugin: ${plugin_name:-<missing>}"

  [[ -n "$plugin_name" ]] && pass "$plugin_name name present" || { fail "plugin name" "missing"; continue; }
  [[ -n "$plugin_version" ]] && pass "$plugin_name version present" || fail "$plugin_name version" "missing"
  [[ -n "$plugin_description" ]] && pass "$plugin_name description present" || fail "$plugin_name description" "missing"
  [[ -n "$plugin_category" ]] && pass "$plugin_name category present" || fail "$plugin_name category" "missing"
  [[ -n "$plugin_homepage" ]] && pass "$plugin_name homepage present" || warn "$plugin_name homepage" "missing"

  case "$source_type" in
    string)
      source_path="$(jq -r '.source' <<<"$plugin_json")"
      validate_local_plugin "$plugin_name" "$plugin_version" "$source_path"
      ;;
    local)
      source_path="$(jq -r '.source.path // empty' <<<"$plugin_json")"
      if [[ -z "$source_path" ]]; then
        fail "$plugin_name source" "local source missing path"
      else
        validate_local_plugin "$plugin_name" "$plugin_version" "$source_path"
      fi
      ;;
    github)
      source_repo="$(jq -r '.source.repo // empty' <<<"$plugin_json")"
      if [[ -z "$source_repo" ]]; then
        fail "$plugin_name source" "github source missing repo"
      else
        validate_github_plugin "$plugin_name" "$plugin_version" "$source_repo" "$plugin_homepage"
      fi
      ;;
    *)
      fail "$plugin_name source" "unsupported source type: ${source_type:-<missing>}"
      ;;
  esac

  echo
done < <(jq -c '.plugins[]' "$MARKETPLACE_FILE")

echo "=== Summary ==="
echo "  $PASS passed"
echo "  $WARN warnings"
echo "  $FAIL failed"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
