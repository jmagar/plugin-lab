# Plugin Settings -- plugin-lab

Configuration patterns for plugin-lab and plugins it scaffolds.

## plugin-lab Configuration

plugin-lab itself has minimal configuration. It does not expose `userConfig` fields because it is not an MCP server and does not need runtime credentials.

The `.claude-plugin/plugin.json` declares the plugin identity but does not include a `userConfig` section.

## Scaffolded Plugin Configuration

Plugins scaffolded by plugin-lab follow a standard configuration pattern.

### userConfig Pattern

The `userConfig` section in `.claude-plugin/plugin.json` declares settings that users configure through the Claude Code UI:

```json
{
  "userConfig": {
    "MY_SERVICE_URL": {
      "type": "string",
      "title": "Service URL",
      "description": "Base URL of the service instance",
      "sensitive": false
    },
    "MY_SERVICE_API_KEY": {
      "type": "string",
      "title": "API Key",
      "description": "API key for authentication",
      "sensitive": true
    },
    "MY_SERVICE_MCP_TOKEN": {
      "type": "string",
      "title": "MCP Bearer Token",
      "description": "Bearer token for MCP HTTP transport",
      "sensitive": true
    }
  }
}
```

**Required attributes for each entry:**

| Attribute | Type | Description |
| --- | --- | --- |
| `type` | string | Data type (`string`, `number`, `boolean`) |
| `title` | string | Human-readable label |
| `description` | string | Help text shown in the UI |
| `sensitive` | boolean | If true, value is masked in the UI |

### Environment Variable Naming

Service-specific env vars use a consistent prefix:

```
<SERVICE>_URL           -- Upstream service URL
<SERVICE>_API_KEY       -- Upstream service API key
<SERVICE>_MCP_HOST      -- MCP server bind address
<SERVICE>_MCP_PORT      -- MCP server port
<SERVICE>_MCP_TRANSPORT -- Transport mode (http/stdio)
<SERVICE>_MCP_TOKEN     -- Bearer token for HTTP auth
<SERVICE>_MCP_NO_AUTH   -- Disable auth (dev only)
<SERVICE>_MCP_LOG_LEVEL -- Logging level
```

Never use generic, unprefixed names (e.g., `API_KEY`, `PORT`).

### userConfig to .env Sync

The `sync-env.sh` hook script syncs `userConfig` values (exposed as `CLAUDE_PLUGIN_OPTION_*` environment variables) into the plugin's `.env` file at session start. This bridge allows the same credentials to flow from the Claude Code UI into the container runtime.

## Homelab Credential Store

For the broader homelab ecosystem, all service credentials live in `~/.claude-homelab/.env`. This is separate from individual plugin `.env` files and is managed by the `/setup-homelab` command.

See [CONFIG.md](../CONFIG.md) for the full environment variable reference.
