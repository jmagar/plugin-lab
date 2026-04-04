# MCP Integration Testing Standard

Standard for adding mcporter-based integration tests to all homelab MCP server repos.

## Overview

Each MCP server repo gets a `mcp-integration` CI job that:
1. Pulls and starts the published Docker image (HTTP transport)
2. Starts the server locally from source via `uvx`/`npx` (HTTP + stdio transport)
3. Runs `npx -y mcporter@latest call` against each mode
4. Tears down processes on exit

The composite action at `plugin-lab/actions/mcp-integration/action.yml` handles health-polling and log dumping. Per-repo `tests/test-tools.sh` scripts contain the actual tool calls.

---

## Composite Action

```yaml
- uses: jmagar/plugin-lab/actions/mcp-integration@main
  with:
    url: http://localhost:8001
    token: ${{ secrets.OVERSEERR_MCP_TOKEN }}
    test-script: tests/test-tools.sh
    service-name: overseerr-mcp (docker)
    log-file: /tmp/overseerr-mcp.log   # optional
```

Inputs:

| Input | Required | Description |
|-------|----------|-------------|
| `url` | yes | MCP server base URL (e.g. `http://localhost:8001`) |
| `token` | yes | Bearer token for the MCP endpoint |
| `test-script` | yes | Path to `test-tools.sh` relative to repo root |
| `service-name` | yes | Human label for job output |
| `log-file` | no | Path to server log — printed on failure |

---

## Key Rules

### Accept header

All curl health-poll calls MUST include:
```
-H 'Accept: application/json, text/event-stream'
```
FastMCP servers return **406 Not Acceptable** without it.

### Health poll pattern

```bash
for i in $(seq 1 30); do
  curl -sf -H 'Accept: application/json, text/event-stream' "$URL/health" && break
  sleep 1
done
```

### mcporter invocation

Always use `npx -y mcporter@latest` (no pinned version):

```bash
# List tools
npx -y mcporter@latest list --config tests/mcporter/http.json

# Call a tool
npx -y mcporter@latest call \
  --config tests/mcporter/http.json \
  --server myservice-mcp \
  --tool myservice \
  --args '{"action":"help"}'
```

### Local source invocation

```bash
# Python repos
uvx --from . <package-name>

# TypeScript repos
npx --yes .
```

Never pull from the registry for source tests — always use `--from .` / `--yes .`.

### Process teardown

For background processes:
```bash
trap 'kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null' EXIT
```

For Docker:
```yaml
- name: Stop container
  if: always()
  run: docker rm -f myservice-mcp-test
```

---

## mcporter Config File Templates

### HTTP transport (`tests/mcporter/http.json`)

```json
{
  "mcpServers": {
    "SERVICE-mcp": {
      "url": "http://localhost:PORT"
    }
  }
}
```

For authenticated servers, the test script passes `--token` via env var `MCP_TOKEN` or an `Authorization` header injected by the test script.

### stdio transport — Python (`tests/mcporter/stdio-uvx.json`)

```jsonc
{
  "mcpServers": {
    "SERVICE-mcp": {
      "command": "uvx",
      "args": ["--from", ".", "PACKAGE_NAME"],
      "env": {
        "SERVICE_URL": "${SERVICE_URL}",
        "SERVICE_API_KEY": "${SERVICE_API_KEY}",
        "SERVICE_MCP_TRANSPORT": "stdio"
      }
    }
  }
}
```

### stdio transport — TypeScript (`tests/mcporter/stdio-npx.json`)

```jsonc
{
  "mcpServers": {
    "SERVICE-mcp": {
      "command": "npx",
      "args": ["--yes", "."],
      "env": {
        "SERVICE_URL": "${SERVICE_URL}",
        "SERVICE_API_KEY": "${SERVICE_API_KEY}",
        "SERVICE_MCP_TRANSPORT": "stdio"
      }
    }
  }
}
```

---

## test-tools.sh Interface

Each repo provides `tests/test-tools.sh`. It MUST:
- Accept `--url <url>` and `--token <token>` arguments
- Exit non-zero on any tool failure
- Use `npx -y mcporter@latest call` for every tool invocation
- Cover: list (smoke), help tool, at least one read-only data tool

Minimal skeleton:
```bash
#!/usr/bin/env bash
set -euo pipefail

URL=""
TOKEN=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)   URL="$2";   shift 2 ;;
    --token) TOKEN="$2"; shift 2 ;;
    *)       shift ;;
  esac
done

CFG=$(mktemp /tmp/mcporter-XXXXXX.json)
trap 'rm -f "$CFG"' EXIT

cat > "$CFG" <<JSON
{
  "mcpServers": {
    "SERVICE-mcp": {
      "url": "$URL",
      "headers": { "Authorization": "Bearer $TOKEN" }
    }
  }
}
JSON

run() {
  local label="$1"; shift
  echo "── $label"
  npx -y mcporter@latest call \
    --config "$CFG" \
    --server "SERVICE-mcp" \
    "$@"
}

run "list tools"     --tool-list
run "help"           --tool SERVICE --args '{"action":"help"}'
```

---

## GitHub Secrets — Canonical Names

Add these secrets to each repo via `just push-secrets` (from claude-homelab).

| Repo | Secrets |
|------|---------|
| overseerr-mcp | `OVERSEERR_MCP_TOKEN`, `OVERSEERR_URL`, `OVERSEERR_API_KEY` |
| gotify-mcp | `GOTIFY_MCP_TOKEN`, `GOTIFY_URL`, `GOTIFY_APP_TOKEN` |
| unifi-mcp | `UNIFI_MCP_TOKEN`, `UNIFI_URL`, `UNIFI_USERNAME`, `UNIFI_PASSWORD` |
| swag-mcp | `SWAG_MCP_TOKEN` |
| unraid-mcp | `UNRAID_MCP_TOKEN`, `UNRAID_API_URL`, `UNRAID_API_KEY` |
| synapse-mcp | `SYNAPSE_MCP_TOKEN`, `SYNAPSE_MCP_URL`, `SYNAPSE_HOSTS_CONFIG` |
| arcane-mcp | `ARCANE_MCP_TOKEN`, `ARCANE_API_URL`, `ARCANE_API_KEY` |
| syslog-mcp | `SYSLOG_MCP_TOKEN` |

Secret naming convention:
- `${SERVICE}_MCP_TOKEN` — the MCP server's own bearer token
- Upstream credentials use the server's own env var names (e.g. `OVERSEERR_URL`, not `OVERSEERR_MCP_URL`)

---

## CI Job Structure

Each repo's `.github/workflows/ci.yml` gains a `mcp-integration` job:

```yaml
mcp-integration:
  name: MCP Integration
  runs-on: ubuntu-latest
  needs: [lint, typecheck, test]  # adjust to repo's existing jobs
  steps:
    - uses: actions/checkout@v4

    # Mode 1: Docker HTTP
    - name: Pull and start container
      run: |
        docker pull ghcr.io/jmagar/SERVICE-mcp:latest
        docker run -d --name SERVICE-mcp-test \
          -p PORT:PORT \
          -e SERVICE_URL=${{ secrets.SERVICE_URL }} \
          -e SERVICE_MCP_TOKEN=${{ secrets.SERVICE_MCP_TOKEN }} \
          ghcr.io/jmagar/SERVICE-mcp:latest

    - uses: jmagar/plugin-lab/actions/mcp-integration@main
      with:
        url: http://localhost:PORT
        token: ${{ secrets.SERVICE_MCP_TOKEN }}
        test-script: tests/test-tools.sh
        service-name: SERVICE-mcp (docker)

    - name: Stop container
      if: always()
      run: docker rm -f SERVICE-mcp-test

    # Mode 2: Local HTTP (uvx)
    - uses: astral-sh/setup-uv@v5
    - name: Start server (local HTTP)
      run: |
        SERVICE_URL=${{ secrets.SERVICE_URL }} \
        SERVICE_MCP_TOKEN=${{ secrets.SERVICE_MCP_TOKEN }} \
        SERVICE_MCP_TRANSPORT=http \
        uvx --from . SERVICE-mcp &
        echo "LOCAL_PID=$!" >> "$GITHUB_ENV"

    - uses: jmagar/plugin-lab/actions/mcp-integration@main
      with:
        url: http://localhost:PORT
        token: ${{ secrets.SERVICE_MCP_TOKEN }}
        test-script: tests/test-tools.sh
        service-name: SERVICE-mcp (local HTTP)

    - name: Stop local HTTP server
      if: always()
      run: kill "$LOCAL_PID" 2>/dev/null || true

    # Mode 3: stdio (uvx)
    - name: Run mcporter via stdio
      run: |
        SERVICE_URL=${{ secrets.SERVICE_URL }} \
        npx -y mcporter@latest call \
          --config tests/mcporter/stdio-uvx.json \
          --server SERVICE-mcp \
          --tool SERVICE \
          --args '{"action":"help"}'
```

---

## Repo-Specific Notes

### overseerr-mcp, gotify-mcp, unifi-mcp, unraid-mcp, swag-mcp
Python / FastMCP. All three transport modes (Docker HTTP, local HTTP, stdio via `uvx`).

### synapse-mcp, arcane-mcp
TypeScript / Node. Docker HTTP + local HTTP + stdio via `npx --yes .`.

### syslog-mcp
Rust / axum. HTTP only (no stdio transport implemented). Docker HTTP + local HTTP.
`uvx`/`npx` not applicable — use `cargo run` for local HTTP if needed.

---

## Validation Checklist

Before closing `claude-homelab-09lm.1`:

- [ ] `plugin-lab/actions/mcp-integration/action.yml` valid YAML, all inputs documented
- [ ] Reference doc covers all 8 repos' secret names
- [ ] `push-github-secrets.sh` updated for any new secrets discovered
- [ ] At least one per-repo bead implementor (overseerr-mcp preferred) smoke-tests the template
