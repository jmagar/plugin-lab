# Authentication Reference

## Overview

my-plugin has two authentication boundaries:

1. **Inbound** — MCP clients authenticating to the MCP server
2. **Outbound** — MCP server authenticating to the upstream my-service instance

## Inbound Authentication (Client to MCP Server)

### Bearer Token

All HTTP requests to the MCP server require a bearer token:

```
Authorization: Bearer {MY_PLUGIN_MCP_TOKEN}
```

The token is set via the `MY_PLUGIN_MCP_TOKEN` environment variable. Generate one with:

```bash
openssl rand -hex 32
```

### BearerAuthMiddleware

The server validates inbound tokens using `BearerAuthMiddleware`:

```
Request -> BearerAuthMiddleware -> Route Handler
                |
                v (401)
          Missing/invalid token
```

- Returns `401 Unauthorized` if the token is missing or does not match
- Applies to all routes except `/health`

### Unauthenticated Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Health check — always returns `{"status": "ok"}` |

The health endpoint is intentionally unauthenticated so load balancers and monitoring can probe without credentials.

### No-Auth Mode

When running behind a reverse proxy that handles authentication:

```env
MY_PLUGIN_MCP_NO_AUTH=true
```

This disables `BearerAuthMiddleware` entirely. Only use when the proxy enforces its own auth layer (e.g., SWAG with Authelia, Cloudflare Access).

### stdio Transport

stdio transport does not use bearer tokens. Process-level isolation provides the security boundary — only the parent process (Claude Desktop, Codex CLI) can communicate with the server.

## Outbound Authentication (MCP Server to Upstream)

### API Key Pattern

Most upstream services authenticate via API key in a request header:

```env
MY_PLUGIN_URL=https://my-service.example.com
MY_PLUGIN_API_KEY=your-api-key-here
```

<!-- scaffold:specialize — document the actual header name and format for this service -->

The API key is sent as a header on every request to the upstream service. Common patterns:

| Service Pattern | Header |
|-----------------|--------|
| `X-Api-Key` | `X-Api-Key: {MY_PLUGIN_API_KEY}` |
| `Authorization` | `Authorization: Bearer {MY_PLUGIN_API_KEY}` |
| `ApiKey` | `ApiKey: {MY_PLUGIN_API_KEY}` |

### Username/Password Pattern

Some services use basic auth or session-based authentication:

<!-- scaffold:specialize — remove this section if not applicable -->

```env
MY_PLUGIN_USERNAME=admin
MY_PLUGIN_PASSWORD=secret
```

### Token / Session Pattern

Services using OAuth or session tokens:

<!-- scaffold:specialize — remove this section if not applicable -->

```env
MY_PLUGIN_TOKEN=session-token
```

## Plugin userConfig Integration

When installed as a Claude Code plugin, credentials are managed via `userConfig` in `plugin.json`:

```json
{
  "userConfig": {
    "MY_PLUGIN_URL": {
      "description": "URL of your my-service instance",
      "required": true
    },
    "MY_PLUGIN_API_KEY": {
      "description": "API key for my-service",
      "required": true,
      "sensitive": true
    },
    "MY_PLUGIN_MCP_TOKEN": {
      "description": "Bearer token for MCP authentication",
      "required": true,
      "sensitive": true
    }
  }
}
```

Fields marked `"sensitive": true` are stored encrypted and synced to `.env` by the `sync-env.sh` hook.

## Security Best Practices

- **Never log tokens** — not even at DEBUG level
- **Rotate credentials regularly** — update `.env` and restart the server
- **Use HTTPS in production** — set `MY_PLUGIN_VERIFY_SSL=true` (default)
- **Restrict token scope** — generate a dedicated API key for the MCP server, not a personal admin key
- **Minimal permissions** — configure upstream API keys with read-only access unless write operations are needed

## See Also

- [ENV.md](ENV.md) — Full environment variable reference
- [TRANSPORT.md](TRANSPORT.md) — Transport-specific auth behavior
