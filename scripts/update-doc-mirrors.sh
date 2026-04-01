#!/usr/bin/env bash
# update-doc-mirrors.sh — Refresh mirrored markdown docs from first-line source URLs
#
# Any .md file whose first line matches:
#   # https://example.com/path/to/doc.md
# is treated as a mirrored doc and will be fully overwritten by the fetched content.
#
# Usage:
#   bash scripts/update-doc-mirrors.sh
#   bash scripts/update-doc-mirrors.sh path/to/dir
#
# Notes:
# - No files are hardcoded.
# - Local edits to mirrored docs are discarded on update.
# - When a mirrored doc changes, a sidecar diff is appended to <file>.diff.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: update-doc-mirrors.sh [root]

Refresh all mirrored markdown docs under [root] (default: current directory).

A mirrored doc is any .md file whose first line is:
  # https://.../something.md

The file is fully overwritten with the fetched content.
If content changes, a unified diff is appended to <file>.diff.
EOF
  exit 0
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
fi

ROOT="${1:-.}"

if [[ ! -d "$ROOT" ]]; then
  echo "update-doc-mirrors: root directory not found: $ROOT" >&2
  exit 1
fi

updated=0
unchanged=0
skipped=0
failed=0
changed_files=()

while IFS= read -r -d '' file; do
  first_line="$(sed -n '1p' "$file")"
  diff_file="${file}.diff"
  url=""

  if [[ "$first_line" =~ ^#\ (https://[^[:space:]]+\.md)$ ]]; then
    url="${BASH_REMATCH[1]}"
  elif [[ -f "$diff_file" ]]; then
    recovered_url="$(
      sed -n 's/^-# \(https:\/\/[^[:space:]]\+\.md\)$/\1/p' "$diff_file" | head -n 1
    )"
    if [[ -n "$recovered_url" ]]; then
      url="$recovered_url"
      echo "recovered: $file <- $url"
    fi
  fi

  if [[ -n "$url" ]]; then
    fetched_tmp="$(mktemp)"
    assembled_tmp="$(mktemp)"
    if wget -q -O "$fetched_tmp" "$url"; then
      {
        printf '# %s\n' "$url"
        cat "$fetched_tmp"
      } > "$assembled_tmp"

      if cmp -s "$file" "$assembled_tmp"; then
        rm -f "$fetched_tmp" "$assembled_tmp"
        echo "unchanged: $file"
        unchanged=$((unchanged + 1))
      else
        {
          printf '===== %s =====\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
          diff -u "$file" "$assembled_tmp" || true
          printf '\n'
        } >> "$diff_file"
        mv "$assembled_tmp" "$file"
        rm -f "$fetched_tmp"
        echo "updated:   $file <- $url"
        echo "diff:      $diff_file"
        changed_files+=("$file")
        updated=$((updated + 1))
      fi
    else
      rm -f "$fetched_tmp" "$assembled_tmp"
      echo "failed:  $file <- $url" >&2
      failed=$((failed + 1))
    fi
  else
    skipped=$((skipped + 1))
  fi
done < <(find "$ROOT" -type f -name '*.md' -print0)

echo
echo "update-doc-mirrors: $updated updated, $unchanged unchanged, $failed failed, $skipped skipped"

if [[ "${#changed_files[@]}" -gt 0 ]]; then
  echo
  echo "changed files:"
  printf '  %s\n' "${changed_files[@]}"
fi

if [[ "$failed" -gt 0 ]]; then
  exit 1
fi
