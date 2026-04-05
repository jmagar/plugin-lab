# Plugin Manifest Reference — my-plugin

Structure and conventions for plugin manifest files.

## File locations

| Platform | Path | Required |
| --- | --- | --- |
| Claude Code | `.claude-plugin/plugin.json` | yes |
| Codex | `.codex-plugin/plugin.json` | yes |
| Gemini | `gemini-extension.json` | optional |

All manifests must declare the same version. Validate with `just check-contract` or `scripts/lint-plugin.sh`.

## Claude / Codex manifest

`.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` share identical structure.

### Required fields

```json
{
  "name": "my-plugin",
  "version": "0.1.0",
  "description": "Short description of what my-plugin does",
  "author": {
    "name": "jmagar",
    "email": "jmagar@users.noreply.github.com"
  },
  "repository": "https://github.com/jmagar/my-plugin",
  "license": "MIT"
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `name` | string | kebab-case, matches repo name |
| `version` | string | Semver — synced across all manifests |
| `description` | string | One sentence, no period |
| `author` | object | `name` and `email` |
| `repository` | string | Full GitHub URL |
| `license` | string | SPDX identifier |

### Optional fields

| Field | Type | Notes |
| --- | --- | --- |
| `author_url` | string | Author profile URL |
| `homepage` | string | Plugin homepage or docs URL |
| `keywords` | string[] | Discovery tags |
| `mcpServers` | object | MCP server declarations (see below) |
| `userConfig` | object | User-facing configuration schema (see below) |

### userConfig schema

<!-- scaffold:specialize — adjust variable names and descriptions -->

Defines settings the user provides at install time. Values are accessible to hooks and MCP servers.

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

Fields marked `sensitive: true` are masked in logs and UI. Generate tokens with `openssl rand -hex 32`.

### mcpServers configuration

Declares MCP servers the plugin provides. Two transport modes:

**stdio** — subprocess spawned by Claude Code:

```json
{
  "mcpServers": {
    "my-plugin": {
      "type": "stdio",
      "command": "uv",
      "args": ["run", "--directory", "${CLAUDE_PLUGIN_ROOT}", "my_plugin"]
    }
  }
}
```

**HTTP** — remote server with bearer auth:

```json
{
  "mcpServers": {
    "my-plugin": {
      "type": "http",
      "url": "${user_config.my_plugin_url}/mcp",
      "headers": {
        "Authorization": "Bearer ${user_config.my_plugin_token}"
      }
    }
  }
}
```

| Variable | Scope | Description |
| --- | --- | --- |
| `${CLAUDE_PLUGIN_ROOT}` | runtime | Absolute path to the plugin directory |
| `${user_config.<key>}` | runtime | Value from userConfig |

## Gemini manifest

`gemini-extension.json` uses a Gemini-specific format:

```json
{
  "name": "my-plugin",
  "version": "0.1.0",
  "description": "Short description of what my-plugin does",
  "author": "jmagar"
}
```

## Version sync

All manifests must declare identical versions. Files to update on every bump:

| File | Field |
| --- | --- |
| `.claude-plugin/plugin.json` | `"version"` |
| `.codex-plugin/plugin.json` | `"version"` |
| `gemini-extension.json` | `"version"` |
| `Cargo.toml` / `package.json` / `pyproject.toml` | `version` |
| `CHANGELOG.md` | New entry |

Run `just check-contract` to verify all versions match.

## Validation

```bash
# Lint plugin structure and version sync
just check-contract

# Or run directly
scripts/lint-plugin.sh
```

The linter checks: required fields present, versions in sync, userConfig schema valid, mcpServers well-formed.

## Cross-references

- [CONFIG.md](CONFIG.md) — userConfig and settings patterns
- [MARKETPLACES.md](MARKETPLACES.md) — Publishing and marketplace registration
- See [CONFIG](../CONFIG.md) for environment variable conventions
