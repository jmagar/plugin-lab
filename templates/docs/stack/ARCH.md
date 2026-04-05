# Architecture Overview — my-plugin

MCP server architecture patterns used across plugin repositories.

## Request flow

```
MCP Client (Claude Code / Codex / Gemini)
    │
    ▼
Transport Layer (stdio / HTTP+SSE / streamable-http)
    │
    ▼
Auth Middleware (bearer token validation)
    │
    ▼
Tool Router (dispatch by tool name)
    │
    ▼
Tool Handler (validate input, call service)
    │
    ▼
Upstream Client (HTTP client with auth, retries, timeouts)
    │
    ▼
Upstream Service (my-service API)
```

## Module structure

All MCP servers follow a layered module structure regardless of language:

| Layer | Responsibility |
| --- | --- |
| Entry point | Server setup, transport binding, signal handling |
| Transport | stdio, HTTP+SSE, or streamable-http |
| Middleware | Authentication, request timing, logging |
| Tool router | Dispatch incoming tool calls to handlers |
| Handlers | Input validation, business logic, response formatting |
| Service client | Upstream HTTP client with auth headers and error mapping |
| Models | Request/response schemas, validation |

## Python architecture (FastMCP)

```
my_plugin_mcp/
├── __init__.py
├── server.py            # FastMCP app, tool registration, lifespan
├── client.py            # Upstream API client (httpx.AsyncClient)
├── tools/
│   ├── __init__.py
│   ├── search.py        # Search-related tool handlers
│   └── manage.py        # CRUD tool handlers
├── models/
│   ├── __init__.py
│   └── schemas.py       # Pydantic models for request/response
└── utils/
    ├── __init__.py
    └── formatting.py    # Response formatting helpers
```

Key patterns:

- `server.py` creates the `FastMCP` instance and registers all tools
- `client.py` provides `get_client()` returning a configured `httpx.AsyncClient`
- Tools are async functions decorated with `@mcp.tool()`
- Pydantic models validate all inputs and serialize outputs

## TypeScript architecture (MCP SDK)

```
src/
├── index.ts             # Express app, session management, transport
├── mcp/
│   ├── server.ts        # McpServer factory function
│   └── tools/
│       ├── index.ts     # Tool registration (all tools)
│       ├── search.ts    # Search tool definitions
│       └── manage.ts    # CRUD tool definitions
├── services/
│   ├── client.ts        # Upstream API client (fetch/axios)
│   └── auth.ts          # Auth header construction
├── middleware/
│   ├── bearer.ts        # Bearer token validation
│   └── timing.ts        # Request duration logging
└── types/
    └── index.ts         # TypeScript interfaces and Zod schemas
```

Key patterns:

- `index.ts` creates the Express app and attaches MCP transport
- `server.ts` exports a factory that builds a configured `McpServer`
- Tools are registered via `server.tool()` with Zod input schemas
- Services wrap upstream API calls with error handling

## Rust architecture (axum)

```
src/
├── main.rs              # Entry point, axum router, signal handling
├── mcp/
│   ├── mod.rs           # MCP server setup
│   ├── tools.rs         # Tool definitions and dispatch
│   └── transport.rs     # stdio / HTTP transport
├── services/
│   ├── mod.rs
│   └── client.rs        # Upstream API client (reqwest)
├── models/
│   ├── mod.rs
│   └── api.rs           # serde structs for API types
└── error.rs             # Error types with thiserror
```

Key patterns:

- `main.rs` sets up tokio runtime and axum router
- Tools are dispatched via match on tool name
- `reqwest::Client` is shared via axum state
- Workspace crate pattern (`crates/`) for larger projects

## Data flow

```
Tool call: my-plugin.search(query="test", limit=10)

1. Transport receives JSON-RPC request
2. Auth middleware validates bearer token
3. Router matches tool name "search"
4. Handler validates input (Pydantic/Zod/serde)
5. Client builds upstream request:
   GET https://my-service.example.com/api/search?q=test&limit=10
   Authorization: Bearer <MY_PLUGIN_API_KEY>
6. Client parses upstream response, maps errors
7. Handler formats result as MCP tool response
8. Transport sends JSON-RPC response
```

## Error handling

All layers map errors to structured MCP error responses:

| Source | Error | MCP response |
| --- | --- | --- |
| Auth middleware | Missing/invalid token | `isError: true`, "Unauthorized" |
| Input validation | Invalid parameters | `isError: true`, validation details |
| Upstream client | Connection refused | `isError: true`, "Upstream unreachable" |
| Upstream client | 401/403 from upstream | `isError: true`, "Upstream auth failed" |
| Upstream client | 404 from upstream | `isError: true`, "Not found" |
| Upstream client | 429 rate limited | `isError: true`, "Rate limited, retry later" |
| Upstream client | 500+ server error | `isError: true`, "Upstream error" |

## Cross-references

- [TECH](TECH.md) — technology stack choices
- [TOOLS](../mcp/TOOLS.md) — MCP tool definitions
- [UPSTREAM](../upstream/CLAUDE.md) — upstream service integration patterns
