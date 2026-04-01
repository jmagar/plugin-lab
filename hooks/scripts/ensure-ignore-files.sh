#!/usr/bin/env bash
# Target path relative to plugin root: hooks/scripts/ensure-ignore-files.sh

set -euo pipefail

mode="${1:-}"
repo_root="${2:-${CLAUDE_PLUGIN_ROOT:-.}}"

gitignore="${repo_root}/.gitignore"
dockerignore="${repo_root}/.dockerignore"

git_patterns=(
  ".env"
  ".env.*"
  "!.env.example"
  "logs/*"
  "!logs/.gitkeep"
  "*.log"
  ".claude/settings.local.json"
  ".claude/worktrees/"
  ".omc/"
  ".lavra/"
  ".beads/"
  ".serena/"
  ".worktrees"
  ".full-review/"
  ".full-review-archive-*"
  ".vscode/"
  ".cursor/"
  ".windsurf/"
  ".1code/"
  ".cache/"
  "docs/plans/"
  "docs/sessions/"
  "docs/reports/"
  "docs/research/"
  "docs/superpowers/"
)

docker_patterns=(
  ".git"
  ".github"
  ".env"
  ".env.*"
  "!.env.example"
  ".claude"
  ".claude-plugin"
  ".codex-plugin"
  ".omc"
  ".lavra"
  ".beads"
  ".serena"
  ".worktrees"
  ".full-review"
  ".full-review-archive-*"
  ".vscode"
  ".cursor"
  ".windsurf"
  ".1code"
  "docs"
  "tests"
  "scripts"
  "*.md"
  "!README.md"
  "logs"
  "*.log"
  ".cache"
)

check_or_append() {
  local file="$1"
  shift
  local failed=0
  touch "$file"
  for pattern in "$@"; do
    if ! grep -Fqx "$pattern" "$file" 2>/dev/null; then
      if [ "$mode" = "--check" ]; then
        echo "missing: $file -> $pattern" >&2
        failed=1
      else
        printf '%s\n' "$pattern" >> "$file"
      fi
    fi
  done
  return "$failed"
}

check_or_append "$gitignore" "${git_patterns[@]}"
git_status=$?
check_or_append "$dockerignore" "${docker_patterns[@]}"
docker_status=$?

if [ "$mode" = "--check" ] && { [ "$git_status" -ne 0 ] || [ "$docker_status" -ne 0 ]; }; then
  exit 1
fi
