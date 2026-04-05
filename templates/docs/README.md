# MyPlugin MCP

<!-- mcp-name: tv.tootie/my-plugin -->
<!-- scaffold:specialize — update badge URLs, mcp-name, and overview paragraph -->

[![PyPI](https://img.shields.io/pypi/v/my-plugin)](https://pypi.org/project/my-plugin/) [![ghcr.io](https://img.shields.io/badge/ghcr.io-jmagar%2Fmy--plugin-blue?logo=docker)](https://github.com/jmagar/my-plugin/pkgs/container/my-plugin)

MCP server for self-hosted my-service. Exposes a unified `my_plugin` action router and a `my_plugin_help` companion tool for interacting with my-service.

## Overview

Two MCP tools are exposed:

| Tool | Purpose |
| --- | --- |
| `my_plugin` | Unified action router for all my-service operations |
| `my_plugin_help` | Returns markdown documentation for all actions and parameters |

The server supports HTTP (default) and stdio transports. HTTP transport requires bearer authentication via `MY_PLUGIN_MCP_TOKEN`.

## What this repository ships

<!-- scaffold:specialize — update file paths to match language and project layout -->

- `my_plugin/server.py`: FastMCP server, action router, and BearerAuth middleware
- `my_plugin/services/my_service.py`: Async client for the my-service API
- `skills/my-plugin/SKILL.md`: Client-facing skill documentation
- `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `gemini-extension.json`: Client manifests
- `docker-compose.yml`, `Dockerfile`, `entrypoint.sh`: Container deployment
- `scripts/`: Smoke tests and contract checks

## Tools

### `my_plugin`

Single entry point for all my-service operations. Select the operation with the `action` parameter.

<!-- scaffold:specialize — replace with actual actions table -->

| Action | Subaction | Description |
| --- | --- | --- |
| `list_items` | — | List all items |
| `get_item` | — | Get item by ID |
| `create_item` | — | Create a new item |
| `delete_item` | — | Delete an item (destructive, requires `confirm=True`) |
| `health` | — | Check upstream service health |

### `my_plugin_help`

Returns the full action reference as Markdown. Call this to discover available actions.

```python
my_plugin_help()
```

## Installation

### Marketplace

```bash
/plugin marketplace add jmagar/claude-homelab
/plugin install my-plugin @jmagar-claude-homelab
```

### Local development

<!-- scaffold:specialize — adjust for language: uv/pnpm/cargo -->

```bash
uv sync --dev
uv run my-plugin-server
```

### Docker

```bash
just up
```

Or manually:

```bash
docker compose up -d
```

## Authentication

The MCP server uses bearer token authentication for HTTP transport.

Generate a token:

```bash
openssl rand -hex 32
```

Set it in `.env`:

```bash
MY_PLUGIN_MCP_TOKEN=<generated-token>
```

Configure your MCP client to send the token as a Bearer header. See [AUTH](docs/mcp/AUTH.md) for detailed setup.

To disable auth (only behind a trusted reverse proxy):

```bash
MY_PLUGIN_MCP_NO_AUTH=true
```

## Configuration

Copy `.env.example` to `.env` and fill in the required values:

```bash
cp .env.example .env
chmod 600 .env
```

### Environment variables

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `MY_PLUGIN_URL` | yes | — | Base URL of your my-service instance (no trailing slash) |
| `MY_PLUGIN_API_KEY` | yes | — | API key for my-service |
| `MY_PLUGIN_MCP_TOKEN` | yes* | — | Bearer token for MCP auth. Generate with `openssl rand -hex 32` |
| `MY_PLUGIN_MCP_PORT` | no | `8000` | Port for the MCP HTTP server |

*Required when `MY_PLUGIN_MCP_TRANSPORT=http` and `MY_PLUGIN_MCP_NO_AUTH=false`.

See [CONFIG](docs/CONFIG.md) for all variables including logging, safety, and Docker settings.

## Quick start

<!-- scaffold:specialize — replace with real tool call examples -->

```python
# List items
my_plugin(action="list_items")

# Get a specific item
my_plugin(action="get_item", id=42)

# Create an item
my_plugin(action="create_item", name="example")

# Delete (destructive)
my_plugin(action="delete_item", id=42, confirm=True)

# Health check
my_plugin(action="health")
```

## Docker usage

```bash
# Build and start
just up

# View logs
just logs

# Health check
just health
# or: curl http://localhost:8000/health

# Stop
just down
```

The `/health` endpoint is unauthenticated for liveness probes.

## Related plugins

<!-- scaffold:specialize — keep only relevant plugins -->

| Plugin | Category | Description |
|--------|----------|-------------|
| [homelab-core](https://github.com/jmagar/claude-homelab) | core | Core agents, commands, skills, and setup/health workflows for homelab management. |
| [overseerr-mcp](https://github.com/jmagar/overseerr-mcp) | media | Search movies and TV shows, submit requests, and monitor failed requests via Overseerr. |
| [unraid-mcp](https://github.com/jmagar/unraid-mcp) | infrastructure | Query, monitor, and manage Unraid servers. |
| [unifi-mcp](https://github.com/jmagar/unifi-mcp) | infrastructure | Monitor and manage UniFi devices and network health. |
| [swag-mcp](https://github.com/jmagar/swag-mcp) | infrastructure | Manage SWAG nginx reverse proxy configurations. |
| [synapse-mcp](https://github.com/jmagar/synapse-mcp) | infrastructure | Docker management and SSH remote operations across homelab hosts. |
| [arcane-mcp](https://github.com/jmagar/arcane-mcp) | infrastructure | Manage Docker environments, containers, images, volumes, and networks. |
| [syslog-mcp](https://github.com/jmagar/syslog-mcp) | infrastructure | Receive, index, and search syslog streams via SQLite FTS5. |
| [gotify-mcp](https://github.com/jmagar/gotify-mcp) | utilities | Send push notifications and manage Gotify messages and applications. |
| [plugin-lab](https://github.com/jmagar/plugin-lab) | dev-tools | Scaffold, review, align, and deploy homelab MCP plugins. |

## License

MIT
