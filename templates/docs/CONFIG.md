# Configuration Reference — my-plugin

Complete environment variable reference and configuration options.

## Environment file

```bash
cp .env.example .env
chmod 600 .env
```

Precedence (highest to lowest):
1. `.env` file in project root
2. Container environment variables (Docker `environment:` or `-e` flags)
3. System environment variables

## Environment variables

### Service credentials

<!-- scaffold:specialize — adjust variable names and add service-specific vars -->

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `MY_PLUGIN_URL` | yes | — | no | Base URL of the my-service instance (no trailing slash) |
| `MY_PLUGIN_API_KEY` | yes | — | yes | API key for my-service authentication |

### MCP server

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `MY_PLUGIN_MCP_HOST` | no | `0.0.0.0` | no | Network interface to bind |
| `MY_PLUGIN_MCP_PORT` | no | `8000` | no | HTTP server port |
| `MY_PLUGIN_MCP_TOKEN` | yes* | — | yes | Bearer token for HTTP auth. Generate: `openssl rand -hex 32` |
| `MY_PLUGIN_MCP_TRANSPORT` | no | `http` | no | Transport mode: `http` or `stdio` |
| `MY_PLUGIN_MCP_NO_AUTH` | no | `false` | no | Disable bearer auth (only behind trusted proxy) |

*Required when transport is `http` and `MY_PLUGIN_MCP_NO_AUTH` is not `true`.

### Logging

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `LOG_LEVEL` | no | `INFO` | no | `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL` |
| `MY_PLUGIN_LOG_FILE` | no | `logs/my_plugin.log` | no | Log file path (rotating, 5 MB max, 3 backups) |

### Safety

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `ALLOW_DESTRUCTIVE` | no | `false` | no | Skip `confirm=True` for destructive actions |
| `ALLOW_YOLO` | no | `false` | no | Alias for `ALLOW_DESTRUCTIVE` |

### Docker / container

| Variable | Required | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `PUID` | no | `1000` | no | UID for container process |
| `PGID` | no | `1000` | no | GID for container process |
| `DOCKER_NETWORK` | no | — | no | External Docker network name (empty = default bridge) |

## Plugin userConfig

When installed as a Claude Code plugin, these fields map to `userConfig` in `.claude-plugin/plugin.json`:

<!-- scaffold:specialize — adjust to match actual plugin.json userConfig -->

```json
{
  "userConfig": {
    "url": {
      "label": "my-service URL",
      "description": "Base URL of your my-service instance",
      "required": true
    },
    "apiKey": {
      "label": "API Key",
      "description": "API key for my-service",
      "required": true
    },
    "mcpToken": {
      "label": "MCP Token",
      "description": "Bearer token for MCP auth (openssl rand -hex 32)",
      "required": true
    }
  }
}
```

## .env.example conventions

- Group variables by section with comment headers
- Required variables first within each group
- No actual secrets — use descriptive placeholders
- Include usage instructions at the bottom

Example structure:

```bash
# =============================================================================
# SERVICE CONFIGURATION
# =============================================================================
MY_PLUGIN_URL=https://your-instance.example.com
MY_PLUGIN_API_KEY=your_api_key_here

# =============================================================================
# MCP SERVER CONFIGURATION
# =============================================================================
MY_PLUGIN_MCP_HOST=0.0.0.0
MY_PLUGIN_MCP_PORT=8000
MY_PLUGIN_MCP_TRANSPORT=http
MY_PLUGIN_MCP_TOKEN=
MY_PLUGIN_MCP_NO_AUTH=false

# =============================================================================
# LOGGING
# =============================================================================
LOG_LEVEL=INFO

# =============================================================================
# DOCKER / CONTAINER
# =============================================================================
PUID=1000
PGID=1000
DOCKER_NETWORK=
```
