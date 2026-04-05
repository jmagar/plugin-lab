# MCP Server Documentation

Documentation for the my-plugin MCP server.

## Files

| File | Description |
|------|-------------|
| [TOOLS.md](TOOLS.md) | Tool definitions, action/subaction routing, parameters, and examples |
| [RESOURCES.md](RESOURCES.md) | MCP resource URIs, registration patterns, and response formats |
| [SCHEMA.md](SCHEMA.md) | Tool schema definitions (Zod/Pydantic/serde) and generation |
| [ENV.md](ENV.md) | All environment variables with types, defaults, and sensitivity |
| [AUTH.md](AUTH.md) | Inbound (client) and outbound (upstream) authentication patterns |
| [TRANSPORT.md](TRANSPORT.md) | stdio, HTTP/SSE, and streamable-http configuration |

<!-- scaffold:specialize — add files specific to this MCP server -->

## Reading Order

**New to this MCP server:**
1. ENV.md — understand required configuration
2. AUTH.md — set up authentication
3. TRANSPORT.md — choose a transport and connect
4. TOOLS.md — learn available operations
5. RESOURCES.md — discover read-only data endpoints
6. SCHEMA.md — reference for schema generation

**Experienced developers:**
- TOOLS.md and RESOURCES.md for the API surface
- ENV.md for configuration reference
- SCHEMA.md for contributing new tools

## Cross-References

- [plugin/](../plugin/) — Plugin manifest, hooks, and marketplace config
- [stack/](../stack/) — Language-specific implementation details
- [upstream/](../upstream/) — Upstream service API documentation
- [repo/](../repo/) — Repository structure and development workflow
