# Scripts Reference — my-plugin

Scripts used for maintenance, hooks, and testing.

## Maintenance scripts (`scripts/`)

| Script | Purpose |
| --- | --- |
| `check-docker-security.sh` | Lint Dockerfile for security issues (non-root, no secrets) |
| `check-no-baked-env.sh` | Verify Docker images contain no baked environment variables |
| `ensure-ignore-files.sh` | Confirm `.gitignore` and `.dockerignore` include required patterns |
| `check-outdated-deps.sh` | Report outdated dependencies |

### Usage

```bash
# Run individually
bash scripts/check-docker-security.sh

# Run all via just
just verify
```

## Hook scripts (`hooks/scripts/`)

Hook scripts execute automatically during plugin lifecycle events.

| Script | Trigger | Purpose |
| --- | --- | --- |
| `sync-env.sh` | Post-install | Sync `userConfig` values from plugin settings into `.env` |
| `fix-env-perms.sh` | Post-install | Enforce `chmod 600` on `.env` if present |
| `ensure-ignore-files.sh` | Pre-commit | Prevent credential files from being committed |

### Environment

Hook scripts receive `$CLAUDE_PLUGIN_ROOT` pointing to the plugin installation directory. Use this for all path resolution:

```bash
#!/bin/bash
set -euo pipefail
ENV_FILE="$CLAUDE_PLUGIN_ROOT/.env"
```

## Test scripts (`tests/`)

| Script | Purpose |
| --- | --- |
| `test_live.sh` | Live integration smoke test against a running upstream service |

### Live test requirements

- Upstream service must be running and reachable
- `.env` must contain valid credentials
- Run with: `just test-live`

```bash
#!/bin/bash
set -euo pipefail
source "$CLAUDE_PLUGIN_ROOT/.env"
curl -sf "$MY_PLUGIN_URL/api/health" > /dev/null || { echo "FAIL: upstream unreachable"; exit 1; }
echo "PASS: upstream reachable"
```

## Script conventions

All scripts follow these rules:

### Shebang and strict mode

```bash
#!/bin/bash
set -euo pipefail
```

### Variable quoting

Always quote variables to prevent word splitting:

```bash
# Correct
curl -sf "$MY_PLUGIN_URL/health"

# Wrong — unquoted variable
curl -sf $MY_PLUGIN_URL/health
```

### Help flag

Every script supports `--help`:

```bash
if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $(basename "$0") [options]"
    echo "  Checks Dockerfile for security best practices."
    exit 0
fi
```

### JSON output

Return structured JSON where appropriate:

```bash
cat <<EOF
{
  "status": "pass",
  "checks": ["non-root", "no-secrets", "no-latest-tag"],
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

### Path resolution

Use `$CLAUDE_PLUGIN_ROOT` for paths in hook scripts. For maintenance scripts, resolve relative to the script location:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
```

### Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Success / all checks pass |
| `1` | Failure / check violation |
| `2` | Usage error / missing arguments |
