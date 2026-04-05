# Connect to MCP

How to connect to the my-plugin MCP server from every supported client and transport.

<!-- scaffold:specialize -- update tool names, ports, package names -->

## Automatically via plugin

The simplest path. The plugin manifest handles transport, auth, and tool registration.

```bash
# Claude Code
/plugin marketplace add jmagar/my-plugin

# Codex CLI
codex plugin add jmagar/my-plugin
```

No further configuration needed -- the manifest wires stdio transport and tool permissions.

## Claude Code CLI

### stdio

```bash
# Python (uvx)
claude mcp add my-plugin -- uvx my-plugin-mcp

# Node (npx)
claude mcp add my-plugin -- npx my-plugin-mcp

# Rust (cargo)
claude mcp add my-plugin -- cargo run -p my-plugin-mcp
```

### HTTP

```bash
claude mcp add --transport http my-plugin http://localhost:8000/mcp
```

With bearer auth:

```bash
claude mcp add --transport http \
  --header "Authorization: Bearer $MY_PLUGIN_MCP_TOKEN" \
  my-plugin http://localhost:8000/mcp
```

### Scopes

| Flag | Scope | Config file |
|------|-------|-------------|
| `--scope project` | Current project only | `.claude/settings.local.json` |
| `--scope user` | All projects (local) | `~/.claude/settings.json` |
| _(none)_ | Defaults to project | `.claude/settings.local.json` |

## Codex CLI

### stdio

```bash
codex --mcp-config .mcp.json
```

Where `.mcp.json` contains:

```json
{
  "mcpServers": {
    "my-plugin": {
      "command": "uvx",
      "args": ["my-plugin-mcp"],
      "env": {
        "MY_PLUGIN_URL": "https://my-service.example.com",
        "MY_PLUGIN_API_KEY": "your-api-key"
      }
    }
  }
}
```

### HTTP

```json
{
  "mcpServers": {
    "my-plugin": {
      "type": "http",
      "url": "http://localhost:8000/mcp",
      "headers": {
        "Authorization": "Bearer ${MY_PLUGIN_MCP_TOKEN}"
      }
    }
  }
}
```

### Scopes

| Scope | Config file |
|-------|-------------|
| Project | `.codex/mcp.json` |
| User | `~/.codex/mcp.json` |

## Gemini CLI

### stdio

In `gemini-extension.json` (project root or `~/.gemini/`):

```json
{
  "mcpServers": {
    "my-plugin": {
      "command": "uvx",
      "args": ["my-plugin-mcp"],
      "env": {
        "MY_PLUGIN_URL": "https://my-service.example.com",
        "MY_PLUGIN_API_KEY": "your-api-key"
      }
    }
  }
}
```

### HTTP

```json
{
  "mcpServers": {
    "my-plugin": {
      "type": "http",
      "url": "http://localhost:8000/mcp",
      "headers": {
        "Authorization": "Bearer ${MY_PLUGIN_MCP_TOKEN}"
      }
    }
  }
}
```

### Scopes

| Scope | Config file |
|-------|-------------|
| Project | `gemini-extension.json` (project root) |
| Global | `~/.gemini/gemini-extension.json` |

## Manual configuration reference

All three clients use the same `mcpServers` JSON structure. The only difference is the file path. The JSON examples in the per-client sections above are the exact content to place in these files:

### Config file locations

| Client | Scope | File |
|--------|-------|------|
| Claude Code | Project | `.claude/settings.local.json` |
| Claude Code | User | `~/.claude/settings.json` |
| Codex CLI | Project | `.codex/mcp.json` |
| Codex CLI | User | `~/.codex/mcp.json` |
| Gemini CLI | Project | `gemini-extension.json` |
| Gemini CLI | Global | `~/.gemini/gemini-extension.json` |

### stdio config (all clients)

```json
{
  "mcpServers": {
    "my-plugin": {
      "command": "uvx",
      "args": ["my-plugin-mcp"],
      "env": {
        "MY_PLUGIN_URL": "https://my-service.example.com",
        "MY_PLUGIN_API_KEY": "your-api-key"
      }
    }
  }
}
```

### HTTP config (all clients)

```json
{
  "mcpServers": {
    "my-plugin": {
      "type": "http",
      "url": "http://localhost:8000/mcp",
      "headers": {
        "Authorization": "Bearer your-token-here"
      }
    }
  }
}

## Verifying connection

After configuring, verify the server is reachable:

```bash
# HTTP health check (unauthenticated)
curl -s http://localhost:8000/health
# Expected: {"status":"ok"}

# Test a tool call via Claude Code
claude "call my_plugin_help()"

# Test via Codex
codex "call my_plugin_help()"
```

If connection fails, check:

1. Server is running (`just up` or `just dev`)
2. Port `8000` is not blocked by firewall
3. Bearer token matches between client config and server `.env`
4. For stdio: the command (`uvx`, `npx`, `cargo`) is on PATH

See also: [AUTH](AUTH.md) | [ENV](ENV.md) | [TRANSPORT](TRANSPORT.md)
