# Plugin Settings — my-plugin

Plugin configuration, user-facing settings, and environment sync.

## Configuration layers

Settings flow through three layers with clear precedence:

| Priority | Source | Managed by |
| --- | --- | --- |
| 1 (highest) | `userConfig` in plugin.json | User at install time |
| 2 | `.env` file | User or hooks |
| 3 (lowest) | System environment variables | OS/container |

Higher-priority sources override lower ones for the same key.

## userConfig

User-facing configuration declared in `.claude-plugin/plugin.json`. Claude Code prompts the user for these values during plugin installation.

<!-- scaffold:specialize — adjust to match actual plugin settings -->

```json
{
  "userConfig": {
    "my_plugin_url": {
      "type": "string",
      "title": "my-service URL",
      "description": "Base URL of your my-service instance",
      "default": "http://localhost:8000",
      "sensitive": false
    },
    "my_plugin_token": {
      "type": "string",
      "title": "API Token",
      "description": "API token for my-service authentication",
      "sensitive": true
    }
  }
}
```

### Field schema

| Property | Type | Description |
| --- | --- | --- |
| `type` | string | Value type: `string`, `number`, `boolean` |
| `title` | string | Human-readable label |
| `description` | string | Help text shown during configuration |
| `default` | any | Default value (omit for required fields with no default) |
| `sensitive` | boolean | `true` masks the value in logs and UI |

### Sensitive fields

Fields with `"sensitive": true`:

- Masked in Claude Code UI (shown as `****`)
- Excluded from debug logs
- Never included in error messages
- Stored securely by Claude Code

Use `sensitive: true` for: API keys, tokens, passwords, secrets.

## settings.json

Plugin-level settings that control internal behavior. Not user-facing.

```json
{
  "log_level": "INFO",
  "max_results": 50,
  "timeout_seconds": 30,
  "features": {
    "destructive_actions": false,
    "auto_health_check": true
  }
}
```

Settings are read by the plugin at runtime. They are not prompted during installation.

## Environment sync

Hooks sync `userConfig` values to `.env` at session start. This bridges plugin settings to scripts and MCP servers that read environment variables.

### Flow

```
userConfig (plugin.json)
  --> sync-env.sh (SessionStart hook)
    --> .env file
      --> MCP server / scripts read $MY_PLUGIN_URL, $MY_PLUGIN_TOKEN
```

### sync-env.sh behavior

1. Reads current `userConfig` values
2. Reads existing `.env` (if present)
3. Updates keys that changed, preserves keys not in userConfig
4. Writes `.env` with `chmod 600`

See [HOOKS.md](HOOKS.md) for the full hook configuration.

## .env conventions

```bash
# Service credentials
MY_PLUGIN_URL=https://my-service.example.com
MY_PLUGIN_API_KEY=your_api_key_here

# MCP server
MY_PLUGIN_MCP_PORT=8000
MY_PLUGIN_MCP_TOKEN=generated_token_here
```

- Group variables with comment headers
- Required variables first in each group
- No actual secrets in `.env.example` — use descriptive placeholders
- File permissions: `chmod 600`

## Configuration validation

Validate configuration at startup:

```bash
# Check required variables are set
source scripts/load-env.sh
load_env_file || exit 1
validate_env_vars "MY_PLUGIN_URL" "MY_PLUGIN_API_KEY"
```

Missing required variables produce a clear error with the variable name and expected format.

## Cross-references

- [PLUGINS.md](PLUGINS.md) — Plugin manifest where userConfig is declared
- [HOOKS.md](HOOKS.md) — Hooks that perform environment sync
- See [CONFIG](../CONFIG.md) for full environment variable reference
- See [GUARDRAILS](../GUARDRAILS.md) for credential security patterns
