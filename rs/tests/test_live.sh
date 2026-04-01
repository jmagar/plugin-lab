#!/usr/bin/env bash
# Target path relative to plugin root: tests/test_live.sh

set -euo pipefail

MCP_URL="${MY_SERVICE_MCP_URL:-http://localhost:9000}"
TOKEN="${MY_SERVICE_MCP_TOKEN:?MY_SERVICE_MCP_TOKEN must be set}"
SERVER_NAME="my-service-mcp"
AUTH_HEADER="Authorization: Bearer $TOKEN"
PASS=0
FAIL=0
SKIP=0

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1 — $2"; ((FAIL++)); }
skip() { echo "  SKIP: $1 — $2"; ((SKIP++)); }

header() { echo; echo "=== $1 ==="; }

header "Schema: external vs internal"

EXTERNAL_SCHEMA=$(npx mcporter list "$SERVER_NAME" --http-url "$MCP_URL" \
  --header "$AUTH_HEADER" --json 2>/dev/null) || fail "schema/list" "mcporter list failed"

if echo "$EXTERNAL_SCHEMA" | jq -e '.tools[] | select(.name == "my_service")' > /dev/null 2>&1; then
  pass "schema/tool-exists: my_service"
else
  fail "schema/tool-exists" "my_service tool not found"
fi

if echo "$EXTERNAL_SCHEMA" | jq -e '.tools[] | select(.name == "my_service_help")' > /dev/null 2>&1; then
  pass "schema/tool-exists: my_service_help"
else
  fail "schema/tool-exists" "my_service_help tool not found"
fi

header "Health"

health=$(curl -sf "${MCP_URL}/health") && pass "health/endpoint" || fail "health/endpoint" "HTTP error"
echo "$health" | jq -e '.status == "ok"' > /dev/null 2>&1 \
  && pass "health/status-ok" || fail "health/status-ok" "status != ok"

header "Tool: my_service — action=list"

result=$(npx mcporter call "${SERVER_NAME}.my_service" \
  --http-url "$MCP_URL" --header "$AUTH_HEADER" action=list 2>/dev/null) \
  && pass "action/list" || fail "action/list" "call failed"

echo "$result" | jq -e '
  has("items") and has("total") and has("limit") and has("offset") and has("has_more")
' > /dev/null 2>&1 \
  && pass "action/list-pagination-shape" \
  || fail "action/list-pagination-shape" "missing pagination metadata"

header "Tool: my_service_help"

HELP=$(npx mcporter call "${SERVER_NAME}.my_service_help" \
  --http-url "$MCP_URL" --header "$AUTH_HEADER" 2>/dev/null) \
  && pass "help/overview" || fail "help/overview" "call failed"

printf '%s' "$HELP" | grep -q "delete" \
  && pass "help/includes-action-delete" || fail "help/includes-action-delete" "delete action missing"

printf '%s' "$HELP" | grep -Eq "DESTRUCTIVE|destructive" \
  && pass "help/marks-destructive" || fail "help/marks-destructive" "destructive marker missing"

header "Bearer token enforcement"

UNAUTH=$(curl -s -o /dev/null -w "%{http_code}" "${MCP_URL}/mcp" \
  -X POST -H "Content-Type: application/json" -d '{}')
[ "$UNAUTH" = "401" ] \
  && pass "auth/unauthenticated-rejected" \
  || fail "auth/unauthenticated-rejected" "expected 401, got $UNAUTH"

echo
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" && exit 0
echo "FAILURES DETECTED" && exit 1
