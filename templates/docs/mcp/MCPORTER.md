# Live Smoke Testing (mcporter)

End-to-end verification against a running `my-plugin-mcp` server. Complements unit/integration tests in [TESTS.md](TESTS.md).

## Purpose

`tests/test_live.sh` exercises the full MCP server stack: auth, tool dispatch, resource retrieval, and error handling against real upstream services.

## Location

```
tests/test_live.sh
```

## Modes

| Mode | Command | Description |
|------|---------|-------------|
| `http` | `bash tests/test_live.sh http` | Tests against HTTP transport (default) |
| `docker` | `bash tests/test_live.sh docker` | Starts container, tests, tears down |
| `stdio` | `bash tests/test_live.sh stdio` | Tests via stdin/stdout pipe |

Shortcut: `just test-live`

## Test Structure

```bash
#!/bin/bash
set -euo pipefail

MODE="${1:-http}"
BASE="http://localhost:${MY_PLUGIN_PORT:-8000}"
TOKEN="${MCP_TOKEN:-test-token}"
PASS=0; FAIL=0

# ── helpers ──────────────────────────────────────────────────────────────
assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $label"; ((PASS++))
  else
    echo "  FAIL: $label (expected=$expected actual=$actual)"; ((FAIL++))
  fi
}

mcp_call() {
  curl -sf -X POST "$BASE/mcp" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$1"
}

# ── setup ────────────────────────────────────────────────────────────────
echo "=== Setup ($MODE) ==="
# Start server or verify running instance
# ...

# ── auth verification ────────────────────────────────────────────────────
echo "=== Auth ==="
status=$(curl -so /dev/null -w '%{http_code}' "$BASE/health")
assert_eq "health no-auth" "200" "$status"

status=$(curl -so /dev/null -w '%{http_code}' -H "Authorization: Bearer bad-token" "$BASE/mcp")
assert_eq "reject bad token" "401" "$status"

# ── tool invocation ──────────────────────────────────────────────────────
echo "=== Tools ==="
# scaffold:specialize — add one block per action/subaction
result=$(mcp_call '{"tool":"my_plugin","arguments":{"action":"list"}}' | jq -r '.success')
assert_eq "list action" "true" "$result"

# ── resource retrieval ───────────────────────────────────────────────────
echo "=== Resources ==="
status=$(curl -sf -o /dev/null -w '%{http_code}' \
  -H "Authorization: Bearer $TOKEN" "$BASE/resources")
assert_eq "resources endpoint" "200" "$status"

# ── error handling ───────────────────────────────────────────────────────
echo "=== Errors ==="
result=$(mcp_call '{"tool":"my_plugin","arguments":{"action":"nonexistent"}}' | jq -r '.error.code')
assert_eq "unknown action" "UNKNOWN_ACTION" "$result"

# ── cleanup ──────────────────────────────────────────────────────────────
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
```

## Environment

Required env vars (from `.env` or CI secrets):

| Variable | Purpose |
|----------|---------|
| `MY_SERVICE_URL` | Upstream service URL |
| `MY_SERVICE_API_KEY` | Upstream API key |
| `MCP_TOKEN` | MCP Bearer token (defaults to `test-token`) |
| `MY_PLUGIN_PORT` | Server port (defaults to `8000`) |

## CI Integration

Live tests run on `main` push only (requires secrets). Skipped on PRs from forks.

```yaml
# From ci.yml
mcp-integration:
  needs: [lint, typecheck, test]
  if: github.event_name == 'push'
  steps:
    - uses: actions/checkout@v4
    - uses: jmagar/plugin-lab/.github/actions/mcp-integration@main
      with:
        server-start-cmd: "just serve &"
        health-url: "http://localhost:8000/health"
        test-cmd: "bash tests/test_live.sh http"
      env:
        MY_SERVICE_URL: ${{ secrets.MY_SERVICE_URL }}
        MY_SERVICE_API_KEY: ${{ secrets.MY_SERVICE_API_KEY }}
```

## Running Locally

```bash
# Start server in background
just serve &

# Run smoke tests
just test-live

# Or directly
bash tests/test_live.sh http
```

## Related Docs

- [TESTS.md](TESTS.md) — unit and integration tests
- [CICD.md](CICD.md) — CI workflow that runs these tests
- [AUTH.md](AUTH.md) — authentication details
