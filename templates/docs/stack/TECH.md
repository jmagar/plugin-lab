# Technology Choices — my-plugin

Technology stack reference for MCP server plugin development.

## Language options

<!-- scaffold:specialize — keep only the relevant language row -->

| Language | Runtime | Package manager | Framework | Hook runner |
| --- | --- | --- | --- | --- |
| Python 3.10+ | uv | uv | FastMCP | pre-commit |
| TypeScript | Node 22+ | pnpm | MCP SDK + Express | lefthook |
| Rust 1.86+ | cargo | cargo | axum + tokio | pre-commit |

## MCP SDKs

| Language | SDK | Package |
| --- | --- | --- |
| Python | FastMCP | `fastmcp` |
| TypeScript | MCP SDK | `@modelcontextprotocol/sdk` |
| Rust | Custom | Hand-rolled with `axum` + `serde_json` |

FastMCP wraps the low-level protocol and provides decorators for tool registration. The TypeScript SDK provides `McpServer` with `server.tool()` for registration. Rust implementations use axum routing with manual JSON-RPC handling.

## HTTP clients

| Language | Library | Key features |
| --- | --- | --- |
| Python | `httpx` | Async, connection pooling, timeouts, retries |
| TypeScript | `fetch` / `axios` | Native fetch or axios for interceptors |
| Rust | `reqwest` | Async, TLS, connection pooling |

## Validation

| Language | Library | Purpose |
| --- | --- | --- |
| Python | `pydantic` | Input/output schema validation, serialization |
| TypeScript | `zod` | Runtime schema validation, type inference |
| Rust | `serde` | Serialization/deserialization with compile-time checks |

## Testing

| Language | Framework | Live tests |
| --- | --- | --- |
| Python | `pytest` + `pytest-asyncio` | `tests/test_live.sh` |
| TypeScript | `vitest` or `jest` | `tests/test_live.sh` |
| Rust | `cargo test` + `tokio::test` | `tests/test_live.sh` |

## Linting and formatting

| Language | Linter | Formatter | Type checker |
| --- | --- | --- | --- |
| Python | `ruff check` | `ruff format` | `ty` (or `mypy`) |
| TypeScript | `biome check` | `biome format` | `tsc --noEmit` |
| Rust | `clippy` | `cargo fmt` | Compiler (inherent) |

## Docker

All plugins use multi-stage Docker builds:

| Stage | Purpose |
| --- | --- |
| Builder | Install dependencies, compile code |
| Runtime | Minimal image with only runtime artifacts |

Common patterns:

- Non-root user (`UID 1000`, overridable via `PUID`/`PGID`)
- Healthcheck: `curl -sf http://localhost:8000/health`
- No credentials baked into the image
- `entrypoint.sh` for runtime environment substitution

### Base images

| Language | Builder | Runtime |
| --- | --- | --- |
| Python | `python:3.12-slim` | `python:3.12-slim` |
| TypeScript | `node:22-alpine` | `node:22-alpine` |
| Rust | `rust:1.86-slim` | `debian:bookworm-slim` |

## Dependency management

| Language | Lock file | Add dependency | Update all |
| --- | --- | --- | --- |
| Python | `uv.lock` | `uv add <pkg>` | `uv lock --upgrade` |
| TypeScript | `pnpm-lock.yaml` | `pnpm add <pkg>` | `pnpm update` |
| Rust | `Cargo.lock` | `cargo add <pkg>` | `cargo update` |

## Cross-references

- [ARCH](ARCH.md) — architecture patterns
- [PRE-REQS](PRE-REQS.md) — prerequisites for development
- [RECIPES](../repo/RECIPES.md) — language-specific Justfile recipes
