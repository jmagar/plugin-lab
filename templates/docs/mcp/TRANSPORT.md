# Transport Methods Reference

## Overview

my-plugin supports three transport methods for MCP communication:

| Transport | Auth | Use Case | Config Value |
|-----------|------|----------|--------------|
| stdio | None (process isolation) | Claude Desktop, Codex CLI | `stdio` |
| HTTP/SSE | Bearer token | Docker, remote servers | `http` |
| Streamable-HTTP | Bearer token | Docker, remote (recommended) | `streamable-http` |

Set the transport via:

```env
MY_PLUGIN_MCP_TRANSPORT=http  # default
```

## stdio

JSON-RPC messages over stdin/stdout. No network listener, no auth required — the parent process owns the communication channel.

```env
MY_PLUGIN_MCP_TRANSPORT=stdio
```

### Claude Desktop Configuration

`~/.claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "my-plugin": {
      "command": "my-plugin-mcp",
      "args": [],
      "env": {
        "MY_PLUGIN_URL": "https://my-service.example.com",
        "MY_PLUGIN_API_KEY": "your-api-key"
      }
    }
  }
}
```

### Codex CLI Configuration

`.codex/mcp.json` (project) or `~/.codex/mcp.json` (global):

```json
{
  "mcpServers": {
    "my-plugin": {
      "command": "my-plugin-mcp",
      "args": [],
      "env": {
        "MY_PLUGIN_URL": "https://my-service.example.com",
        "MY_PLUGIN_API_KEY": "your-api-key"
      }
    }
  }
}
```

### When to Use

- Local development with Claude Desktop or Codex CLI
- Single-user setups where the MCP server runs as a child process
- No network exposure needed

## HTTP/SSE

HTTP server with Server-Sent Events for streaming responses. Requires bearer token authentication.

```env
MY_PLUGIN_MCP_TRANSPORT=http
MY_PLUGIN_MCP_HOST=0.0.0.0
MY_PLUGIN_MCP_PORT=8000
MY_PLUGIN_MCP_TOKEN=your-token-here
```

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/mcp` | POST | MCP JSON-RPC endpoint |
| `/sse` | GET | Server-Sent Events stream |
| `/health` | GET | Health check (unauthenticated) |

### Claude Code Configuration

`.claude/mcp.json`:

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
```

### Docker Compose

```yaml
services:
  my-plugin-mcp:
    image: my-plugin-mcp:latest
    ports:
      - "8000:8000"
    env_file: .env
    healthcheck:
      test: ["CMD", "curl", "-sf", "http://localhost:8000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
```

### When to Use

- Docker deployments
- Remote/shared MCP server
- Multiple clients connecting to one server
- Behind a reverse proxy (SWAG, nginx, Caddy)

## Streamable-HTTP

Enhanced HTTP transport with proper streaming support via Server-Sent Events. The newest transport method, recommended for new deployments.

```env
MY_PLUGIN_MCP_TRANSPORT=streamable-http
MY_PLUGIN_MCP_HOST=0.0.0.0
MY_PLUGIN_MCP_PORT=8000
MY_PLUGIN_MCP_TOKEN=your-token-here
```

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/mcp` | POST | MCP JSON-RPC with streaming responses |
| `/health` | GET | Health check (unauthenticated) |

### Configuration

Same as HTTP/SSE — clients connect to `/mcp`. The transport negotiation happens at the protocol level.

### When to Use

- New deployments (preferred over HTTP/SSE)
- Long-running operations that benefit from streaming progress
- Clients that support streamable-http (Claude Code, latest MCP SDK versions)

## Transport Selection Guide

```
Local dev with Claude Desktop?
  -> stdio (no setup needed)

Running in Docker or on a remote host?
  -> streamable-http (modern, streaming)
  -> http (wider client compatibility)

Behind a reverse proxy with its own auth?
  -> http or streamable-http + MY_PLUGIN_MCP_NO_AUTH=true
```

## Port Assignment Conventions

Each MCP server in a homelab uses a unique port to avoid conflicts:

<!-- scaffold:specialize — assign the actual port for this service -->

| Service | Default Port |
|---------|-------------|
| my-plugin | 8000 |

When running multiple MCP servers, assign sequential ports or use a reverse proxy to multiplex on a single port with path-based routing.

## See Also

- [AUTH.md](AUTH.md) — Bearer token setup for HTTP transports
- [ENV.md](ENV.md) — Transport-related environment variables
