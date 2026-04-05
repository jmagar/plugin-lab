# Web MCP Integration

Browser-accessible MCP endpoints for web dashboards, admin panels, and browser extensions.

<!-- scaffold:specialize -- update endpoints and CORS origins -->

## What is Web MCP

Web MCP exposes MCP server capabilities over HTTP with browser-compatible configuration. This enables web applications to call MCP tools directly, without requiring a CLI client or stdio transport.

The server's existing HTTP transport (`http://localhost:8000/mcp`) is the foundation. Web MCP adds CORS headers, session management, and browser-specific security to make that endpoint callable from frontend code.

## Use cases

| Use case | Description |
|----------|-------------|
| Admin dashboards | Web UI that calls my-plugin tools to display status, trigger actions |
| Browser extensions | Chrome/Firefox extension that interacts with my-service via MCP |
| Internal tools | Retool, Appsmith, or custom apps calling MCP endpoints |
| Mobile web | Responsive admin panel for on-the-go management |

## Implementation considerations

### CORS configuration

The MCP server must allow cross-origin requests from trusted frontends.

```python
from starlette.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("MY_PLUGIN_CORS_ORIGINS", "http://localhost:3000").split(","),
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
    allow_credentials=True,
)
```

Set allowed origins in `.env`:

```bash
MY_PLUGIN_CORS_ORIGINS=https://dashboard.example.com,http://localhost:3000
```

### Session management

For browser clients, consider session-based auth as an alternative to bearer tokens:

- Bearer tokens work but must be stored securely (no localStorage for sensitive tokens).
- Session cookies with `HttpOnly`, `Secure`, `SameSite=Strict` are safer for browser contexts.
- The MCP server can support both: bearer for CLI clients, session cookies for web clients.

### Streaming: WebSocket vs SSE

| Transport | Use case | Browser support |
|-----------|----------|----------------|
| SSE | Server-to-client streaming (logs, progress) | All modern browsers |
| WebSocket | Bidirectional (interactive tools) | All modern browsers |
| HTTP POST | Simple request/response (most tool calls) | Universal |

For most MCP tool calls, standard HTTP POST is sufficient. Use SSE for long-running operations that stream progress.

## Security

Web MCP inherits the same bearer auth as HTTP transport, plus additional browser-specific protections:

- **CSRF protection** -- validate `Origin` header on state-changing requests.
- **Content-Security-Policy** -- restrict script sources if serving a dashboard.
- **Rate limiting** -- browser clients may generate more frequent requests than CLI clients.
- **Token scope** -- consider read-only tokens for dashboard views vs read-write for admin actions.

## Current status

Web MCP is an emerging pattern. Current implementation status:

- HTTP transport with bearer auth: **stable**.
- CORS middleware: **available** in all language frameworks.
- SSE streaming: **supported** by FastMCP and TypeScript SDK.
- Session-based auth: **not yet standardized** -- implement per-project as needed.
- MCP UI integration: **emerging** -- see [MCPUI](MCPUI.md).

## Future direction

- Standardized browser authentication flow via MCP protocol.
- Integration with the MCP UI specification for rich tool forms and result rendering.
- OAuth 2.1 flows for third-party web clients.
- WebSocket transport as a first-class MCP option.

See also: [AUTH](AUTH.md) | [TRANSPORT](TRANSPORT.md) | [MCPUI](MCPUI.md)
