# Environment Variable Reference

<!-- scaffold:specialize — add service-specific variables and remove placeholders -->

## Upstream Service

| Variable | Required | Default | Description | Sensitive |
|----------|----------|---------|-------------|-----------|
| `MY_PLUGIN_URL` | yes | — | Base URL of the my-service instance | no |
| `MY_PLUGIN_API_KEY` | yes | — | API key for my-service authentication | **yes** |
| `MY_PLUGIN_VERIFY_SSL` | no | `true` | Verify TLS certificates on upstream requests | no |

## MCP Server

| Variable | Required | Default | Description | Sensitive |
|----------|----------|---------|-------------|-----------|
| `MY_PLUGIN_MCP_HOST` | no | `0.0.0.0` | Bind address for HTTP transport | no |
| `MY_PLUGIN_MCP_PORT` | no | `8000` | Listen port for HTTP transport | no |
| `MY_PLUGIN_MCP_TOKEN` | yes* | — | Bearer token for inbound MCP auth | **yes** |
| `MY_PLUGIN_MCP_TRANSPORT` | no | `http` | Transport mode: `http`, `stdio`, `streamable-http` | no |
| `MY_PLUGIN_MCP_NO_AUTH` | no | `false` | Disable inbound auth (use behind reverse proxy only) | no |

\* Not required when `MY_PLUGIN_MCP_NO_AUTH=true` or when using `stdio` transport.

## Logging

| Variable | Required | Default | Description | Sensitive |
|----------|----------|---------|-------------|-----------|
| `LOG_LEVEL` | no | `INFO` | Log verbosity: `DEBUG`, `INFO`, `WARN`, `ERROR` | no |
| `MY_PLUGIN_LOG_FILE` | no | — | Path to log file (stdout if unset) | no |

## Safety Gates

| Variable | Required | Default | Description | Sensitive |
|----------|----------|---------|-------------|-----------|
| `MY_PLUGIN_MCP_ALLOW_DESTRUCTIVE` | no | `false` | Auto-confirm destructive operations | no |
| `MY_PLUGIN_MCP_ALLOW_YOLO` | no | `false` | Skip elicitation entirely (CI/testing only) | no |

## Docker / Runtime

| Variable | Required | Default | Description | Sensitive |
|----------|----------|---------|-------------|-----------|
| `PUID` | no | `1000` | Container user ID | no |
| `PGID` | no | `1000` | Container group ID | no |
| `DOCKER_NETWORK` | no | — | Docker network to join | no |
| `PYTHONUNBUFFERED` | no | `1` | Disable Python output buffering (Python stack) | no |
| `NODE_ENV` | no | `production` | Node.js environment (TS stack) | no |
| `RUST_LOG` | no | `info` | Rust log filter (Rust stack) | no |

## Token Generation

Generate a secure MCP token:

```bash
openssl rand -hex 32
```

Store the result in `MY_PLUGIN_MCP_TOKEN` in your `.env` file.

## Precedence

Environment variables are resolved in order (first match wins):

1. `.env` file (loaded by the server at startup)
2. Container environment (`docker run -e` or `docker-compose.yml`)
3. System environment (host shell)

## See Also

- [AUTH.md](AUTH.md) — How tokens are used for authentication
- [TRANSPORT.md](TRANSPORT.md) — Transport-specific variable usage
- [../plugin/CONFIG.md](../plugin/CONFIG.md) — Plugin userConfig fields that sync to `.env`
