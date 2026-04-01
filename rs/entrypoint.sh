#!/usr/bin/env bash
# Target path relative to plugin root: entrypoint.sh

set -euo pipefail

echo "my-service-mcp: initializing..."

if [ -z "${MY_SERVICE_URL:-}" ]; then
    echo "Error: MY_SERVICE_URL is required" >&2
    exit 1
fi

if [ -z "${MY_SERVICE_API_KEY:-}" ]; then
    echo "Warning: MY_SERVICE_API_KEY not set — some functionality may be limited" >&2
fi

export MY_SERVICE_MCP_HOST="${MY_SERVICE_MCP_HOST:-0.0.0.0}"
export MY_SERVICE_MCP_PORT="${MY_SERVICE_MCP_PORT:-9000}"
export MY_SERVICE_MCP_TRANSPORT="${MY_SERVICE_MCP_TRANSPORT:-http}"

echo "my-service-mcp: starting server (${MY_SERVICE_MCP_TRANSPORT} on ${MY_SERVICE_MCP_HOST}:${MY_SERVICE_MCP_PORT})"

exec /usr/local/bin/my-plugin-mcp
