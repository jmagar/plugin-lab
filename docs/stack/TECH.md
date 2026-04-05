# Technology Choices -- plugin-lab

Languages, frameworks, SDKs, and tooling used by plugin-lab and the plugins it scaffolds.

## plugin-lab Tooling

plugin-lab itself is a collection of Bash scripts, Markdown files, and YAML definitions. It has no compiled code or runtime dependencies beyond Bash 4+ and standard Unix tools.

| Tool | Purpose |
| --- | --- |
| Bash 4+ | All scripts, hooks, scaffold logic |
| jq | JSON validation in lint and marketplace scripts |
| Python 3.10+ | Version extraction in `check-version-sync.sh` |
| sed, awk, grep | Template placeholder replacement, env file manipulation |
| curl, wget | Doc mirror fetching, marketplace validation |
| flock | File locking in `sync-env.sh` |

## Scaffolded Plugin Stacks

### Python Template (templates/py/)

| Component | Choice | Notes |
| --- | --- | --- |
| Language | Python 3.11+ | Minimum version for template |
| MCP Framework | FastMCP | Python MCP server framework |
| Package Manager | uv | Fast Python package manager |
| Package Format | `pyproject.toml` | PEP 621 project metadata |
| Type Checker | mypy / ty | Static type analysis |
| Linter | ruff | Fast Python linter |
| Test Framework | pytest | With `live` marker for integration tests |
| Pre-commit | pre-commit | `.pre-commit-config.yaml` |
| Docker Base | python:3.11-slim | Multi-stage build |

### TypeScript Template (templates/ts/)

| Component | Choice | Notes |
| --- | --- | --- |
| Language | TypeScript 5+ | Strict mode enabled |
| MCP SDK | @modelcontextprotocol/sdk | Official MCP TypeScript SDK |
| HTTP Server | Express | HTTP transport layer |
| Package Manager | npm/pnpm | `package.json` |
| Type Checker | tsc --noEmit | TypeScript compiler |
| Linter | biome / eslint | Code style and static analysis |
| Test Framework | vitest / jest | With env var skip guard |
| Pre-commit | lefthook | `lefthook.yml`, parallel mode |
| Docker Base | node:20-slim | Multi-stage build |

### Rust Template (templates/rs/)

| Component | Choice | Notes |
| --- | --- | --- |
| Language | Rust (stable) | Latest stable toolchain |
| MCP Crate | rmcp | Rust MCP server crate |
| Async Runtime | tokio | Async I/O |
| Package Manager | cargo | `Cargo.toml` |
| Linter | clippy | Cargo clippy |
| Test Framework | cargo test | With `live-tests` feature flag |
| Pre-commit | lefthook | `lefthook.yml`, parallel mode |
| Docker Base | rust:1-slim / debian:bookworm-slim | Multi-stage build |

## CI/CD Stack

All scaffolded plugins use GitHub Actions:

| Workflow | Actions used |
| --- | --- |
| ci.yaml | `actions/checkout`, language-specific setup actions |
| publish-image.yaml | `docker/login-action`, `docker/build-push-action`, `docker/metadata-action` |
| release-on-main.yaml | `softprops/action-gh-release` |

Registry: GHCR (ghcr.io). Tag strategy: branch ref, git SHA, semver on tag push, `latest` on default branch.

## Container Stack

| Component | Choice |
| --- | --- |
| Container Runtime | Docker |
| Orchestration | Docker Compose (v2 plugin syntax) |
| Registry | GHCR (ghcr.io) |
| Build | Multi-stage (builder + runtime) |
| Health | HTTP GET `/health` returning 200 |
| Auth | Bearer token via env var |
| Secrets | `.env` file at runtime, never in image |

## Testing Strategy

| Layer | Tool | Scope |
| --- | --- | --- |
| Unit tests | pytest / vitest / cargo test | Handler logic, dispatch, param validation |
| Live tests | Shell scripts + mcporter | End-to-end against running service |
| Contract tests | mcporter | MCP tool schema, transport, auth |
| Lint | lint-plugin.sh | Plugin structure, manifests, hygiene |
| Security | check-docker-security.sh, check-no-baked-env.sh | Docker and credential safety |

Live tests are gated behind `SKIP_LIVE_TESTS` in CI and only run locally or in environments with service access.
