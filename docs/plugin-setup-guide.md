# Claude Code Plugin Setup Guide

This guide documents the exact structure, conventions, and standards for all MCP-server-backed
Claude Code plugins in this ecosystem (`../workspace/gotify-mcp`, `../workspace/overseerr-mcp`, `../workspace/unifi-mcp`, `../workspace/swag-mcp`,
`../workspace/unraid-mcp`, `../workspace/synapse-mcp`, `../workspace/syslog-mcp`, `../workspace/axon`, `../workspace/arcane-mcp`, and any future additions).

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Deployment Modes — Local & Docker](#deployment-modes--local--docker)
3. [Directory Layout](#directory-layout)
4. [`.cache/` Convention](#cache-convention)
5. [Language Toolchain Standards](#language-toolchain-standards)
6. [HTTP Security — Bearer Tokens](#http-security--bearer-tokens)
7. [Tool Design — Action + Subaction Pattern](#tool-design--action--subaction-pattern)
8. [Code Architecture](#code-architecture)
9. [Destructive Operations — Confirmation Gate](#destructive-operations--confirmation-gate)
10. [Middleware & Server Hardening](#middleware--server-hardening)
11. [CI/CD Pipeline](#cicd-pipeline)
12. [MCP Resources](#mcp-resources)
13. [File-by-File Reference](#file-by-file-reference)
    - [plugin.json](#claudepluginpluginjson)
    - [.app.json](#appjson)
    - [.mcp.json](#mcpjson)
    - [hooks/hooks.json](#hookshooksjson)
    - [hooks/scripts/sync-env.sh](#hooksscriptssync-envsh)
    - [hooks/scripts/fix-env-perms.sh](#hooksscriptsfix-env-permssh)
    - [hooks/scripts/ensure-ignore-files.sh](#hooksscriptsensure-ignore-filessh)
    - [skills/SKILL.md](#skillsserviceskillmd)
    - [agents/](#agentsagent-namemd)
    - [commands/](#commandscommandmd)
    - [CLAUDE.md / AGENTS.md / GEMINI.md](#claudemd--agentsmd--geminimd)
    - [.gitignore](#gitignore)
    - [.env.example](#envexample)
    - [Plugin Settings](#plugin-settings-claudeplugin-namelocalmd--optional)
    - [Justfile](#justfile)
    - [entrypoint.sh](#entrypointsh)
    - [Dockerfile](#dockerfile)
    - [docker-compose.yaml](#docker-composeyaml)
    - [SWAG Reverse Proxy Config](#swag-reverse-proxy-config)
14. [Codex CLI Compatibility](#codex-cli-compatibility)
15. [Marketplace Registration](#marketplace-registration)
16. [Testing with mcporter](#testing-with-mcporter)
17. [Validation Checklist](#validation-checklist)
18. [Credential Flow Diagram](#credential-flow-diagram)
19. [Development Tools Reference](#development-tools-reference)
20. [Adding a New Plugin](#adding-a-new-plugin)

---

## Architecture Overview

Each plugin lives **inside its MCP server repo**, not in this repo. The marketplace here points
to those repos as sources. Plugin, MCP server, and Docker Compose stack all ship together.

The plugin provides:
1. **userConfig** — prompts the user for credentials/URLs at install time
2. **MCP config** — wires the MCP server connection using those credentials
3. **Hooks** — syncs credentials to `.env` so Docker Compose can read them
4. **Skills** — dual-mode skill (MCP preferred, HTTP fallback) documenting all tool actions
5. **Agents** — specialized AI agents for complex multi-step workflows (optional)
6. **Commands** — slash commands for common operations (optional)

```
Claude Code plugin install
    → userConfig prompts
    → credentials stored encrypted
    → SessionStart hook → .env written
    → Docker Compose reads .env
    → MCP server starts, reads env vars
    → .mcp.json connects Claude Code → MCP server
    → Claude Code calls tools
```

### Transport Modes

All MCP servers **must** support both transport modes:

| Mode | Env value | When used |
|------|-----------|-----------|
| **HTTP** (Streamable-HTTP) | `http` | **Default.** Production deployments, Docker, reverse proxy |
| **stdio** | `stdio` | Local development, direct pipe, Codex CLI without network |

The transport is controlled by `<SERVICE>_MCP_TRANSPORT` env var, defaulting to `http`:

```bash
# .env
MY_SERVICE_MCP_TRANSPORT=http    # default — Streamable-HTTP server
MY_SERVICE_MCP_TRANSPORT=stdio   # alternative — stdin/stdout pipe
```

**HTTP mode** starts a persistent HTTP server (the normal production path). The server
binds to `<SERVICE>_MCP_HOST` and `<SERVICE>_MCP_PORT`, enforces bearer auth, and exposes
`/health` and `/mcp` endpoints.

**stdio mode** reads JSON-RPC from stdin and writes to stdout. No HTTP server, no auth,
no health endpoint. Useful for local development and CLI tools that manage the process
directly (e.g., `codex` with stdio transport).

Servers should check the transport env var at startup and branch accordingly — both modes
use the same tool handlers and business logic.

---

## Deployment Modes — Local & Docker

All MCP servers **must** be deployable both locally and via Docker Compose. **Docker Compose is
the recommended deployment method** — it isolates the MCP server from the user's system, avoids
dependency conflicts, and provides consistent behavior across machines.

### Docker Compose (recommended)

Docker Compose is the primary deployment path. Users run `docker compose up -d` and the server
starts with all dependencies self-contained. The `docker-compose.yaml`, `Dockerfile`, and
`entrypoint.sh` ship with every plugin.

**All configuration comes from `.env` via `env_file: .env` only.** The `docker-compose.yaml`
must **not** have an `environment:` block — this duplicates configuration and creates a second
place to manage env vars. Every variable the container needs must be in `.env` and `.env.example`.

### Local deployment

For development or environments where Docker is unavailable, the server runs directly on the host.
Install language dependencies, set env vars, and start the server (e.g., `uv run python -m my_service_mcp.server`).

### Environment detection

Servers **must** detect whether they're running inside Docker or locally and adjust behavior
accordingly. This prevents users from having to change URLs when switching deployment modes.

```python
# Python — detect Docker environment
import os

def is_docker() -> bool:
    """Detect if running inside a Docker container."""
    return (
        os.path.exists("/.dockerenv")
        or os.environ.get("RUNNING_IN_DOCKER", "").lower() in ("true", "1")
    )
```

```typescript
// TypeScript — detect Docker environment
function isDocker(): boolean {
  return (
    require("fs").existsSync("/.dockerenv") ||
    process.env.RUNNING_IN_DOCKER?.toLowerCase() === "true"
  );
}
```

```rust
// Rust — detect Docker environment
fn is_docker() -> bool {
    std::path::Path::new("/.dockerenv").exists()
        || std::env::var("RUNNING_IN_DOCKER").map_or(false, |v| v == "true" || v == "1")
}
```

### URL normalization

When the MCP server proxies to an upstream service (e.g., Gotify, Plex, Radarr), the upstream
URL may differ between local and Docker deployments:

- **Local**: `http://localhost:8080` or `http://127.0.0.1:8080`
- **Docker**: `http://host.docker.internal:8080` or the Tailscale IP

Servers **must** normalize URLs so the user sets one URL and it works in both contexts:

#### Python

```python
import re

def normalize_service_url(url: str) -> str:
    """Normalize upstream service URL based on deployment context."""
    if not is_docker():
        return url
    # Inside Docker, localhost/127.0.0.1 refers to the container, not the host.
    return re.sub(
        r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
        lambda m: f"http://host.docker.internal{m.group(2) or ''}",
        url,
    )
```

#### TypeScript

```typescript
function normalizeServiceUrl(url: string): string {
  if (!isDocker()) return url;
  // Inside Docker, localhost/127.0.0.1 refers to the container, not the host.
  return url.replace(
    /https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?/,
    (_match, _host, port) => `http://host.docker.internal${port ?? ""}`,
  );
}
```

#### Rust

```rust
fn normalize_service_url(url: &str) -> String {
    if !is_docker() {
        return url.to_string();
    }
    // Inside Docker, localhost/127.0.0.1 refers to the container, not the host.
    let re = regex::Regex::new(r"https?://(localhost|127\.0\.0\.1)(:\d+)?").unwrap();
    re.replace(url, |caps: &regex::Captures| {
        format!("http://host.docker.internal{}", caps.get(2).map_or("", |m| m.as_str()))
    }).to_string()
}
```

**Rules:**
- The user configures `MY_SERVICE_URL` once (typically `http://localhost:PORT` or a Tailscale IP)
- The server normalizes at startup, not the user
- Log the normalized URL at startup so users can verify the connection target
- If `MY_SERVICE_URL` is already a non-local address (Tailscale IP, hostname), leave it unchanged

### Docker security requirements

Every Dockerfile **must** follow these rules:

1. **Multi-stage build** — separate builder and runtime stages to minimize image size
2. **Non-root user** — the runtime stage must use `USER 1000:1000` (or `${PUID}:${PGID}` via compose)
3. **No baked-in secrets** — no `ENV` directives with sensitive values (API keys, tokens, passwords)
4. **HEALTHCHECK** — hitting `/health` for container health monitoring
5. **Dependency layer caching** — copy manifest files before source code

Run `scripts/check-docker-security.sh` and `scripts/check-no-baked-env.sh` to verify compliance.
Both scripts are available in the claude-homelab repo and should be adapted into each plugin's
pre-commit hooks.

---

## Directory Layout

```
my-service-mcp/
├── .cache/                      # ALL tool artifacts — see .cache Convention below
├── .claude-plugin/
│   └── plugin.json              # Claude Code plugin manifest
├── .codex-plugin/
│   └── plugin.json              # Codex CLI plugin manifest
├── .app.json                    # Codex app/connector manifest (optional)
├── .mcp.json                    # MCP server connection config (shared by both CLIs)
├── agents/                      # Specialized AI agents for complex workflows
│   └── <agent-name>.md          # Agent definition (system prompt, tools, triggers)
├── assets/                      # Plugin visual assets for install surfaces (Codex)
│   ├── icon.png                 # Plugin icon (512x512 recommended)
│   ├── logo.svg                 # Plugin logo
│   └── screenshots/             # Install-surface screenshots
├── scripts/
│   └──                          # Useful scripts for the plugin
├── bin/
│   └──                          # Executables that should be added to PATH
├── commands/                    # Slash commands (optional)
│   └── <command>.md             # Command definition with frontmatter
├── docs/                        # Reference docs, API endpoints, troubleshooting
├── hooks/
│   ├── hooks.json               # Hook event wiring (SessionStart, PostToolUse)
│   └── scripts/
│       ├── ensure-ignore-files.sh # Ensures .gitignore + .dockerignore have required patterns
│       ├── fix-env-perms.sh     # Re-enforces chmod 600 when .env is touched
│       └── sync-env.sh          # Syncs userConfig → .env on session start
├── logs/
│   └── .gitkeep                 # Gitignored — holds server log files
├── skills/
│   └── <service>/
│       └── SKILL.md             # Claude-facing skill definition
├── <service>_mcp/               # Server source code (language-specific)
│   ├── client.*                 # Service API client
│   └── server.*                 # MCP server entry point — action+subaction pattern
├── tests/
│   └── test_live.sh             # Full end-to-end live test (mcporter-based)
├── .dockerignore                # Excludes .git, build artifacts, docs, tests, .env
├── .env                         # Runtime credentials — gitignored, chmod 600
├── .env.example                 # Template — tracked in git, no real values
├── .github/
│   └── workflows/
│       └── ci.yml               # CI pipeline: lint, typecheck, test, audit
├── .gitignore                   # Must include patterns listed below
├── .mcp.json                    # MCP server connection config
├── .pre-commit-config.yaml      # Pre-commit hook config
├── <service>.subdomain.conf     # SWAG reverse proxy config (no -mcp suffix)
├── AGENTS.md -> CLAUDE.md       # Symlink — Codex CLI support
├── CHANGELOG.md                 # Version history
├── CLAUDE.md                    # AI memory file — canonical source of truth
├── docker-compose.yaml          # env_file only, PUID/PGID, named volumes, external network
├── Dockerfile                   # Multi-stage, non-root user
├── entrypoint.sh               # Container entrypoint — env validation before server start
├── GEMINI.md -> CLAUDE.md       # Symlink — Gemini CLI support
├── Justfile                     # Task runner — build, test, lint, deploy recipes
├── LICENSE                      # MIT license
├── pyproject.toml / package.json / Cargo.toml  # Language-specific manifest
└── README.md                    # User-facing documentation (setup, usage, API)
```

---

## `.cache/` Convention

**The repo root must stay clutter-free.** Every tool artifact, cache, and generated output
that does not *have* to live at the root **must** be configured to write into `.cache/`.

`.cache/` is gitignored. Nothing inside it is committed.

### What goes in `.cache/`

| Tool | Default location | Required config |
|------|-----------------|-----------------|
| **Python** | | |
| pytest | `.pytest_cache/` | `cache_dir = ".cache/pytest"` in `pyproject.toml` |
| ruff | `.ruff_cache/` | `cache-dir = ".cache/ruff"` in `pyproject.toml` |
| ty | `.ty_cache/` | `cache-dir = ".cache/ty"` in `pyproject.toml` |
| mypy | `.mypy_cache/` | `cache_dir = ".cache/mypy"` in `pyproject.toml` |
| pyright | `.pyright/` | `"cacheDir": ".cache/pyright"` in `pyrightconfig.json` |
| coverage | `.coverage`, `htmlcov/` | `[tool.coverage.run] data_file = ".cache/coverage/.coverage"` |
| hypothesis | `.hypothesis/` | `database = ".cache/hypothesis"` in conftest or settings |
| tox | `.tox/` | `toxworkdir = .cache/tox` in `tox.ini` |
| nox | `.nox/` | `--envdir .cache/nox` flag |
| **JS/TS** | | |
| tsbuildinfo | `*.tsbuildinfo` | `"tsBuildInfoFile": ".cache/tsconfig.tsbuildinfo"` in `tsconfig.json` |
| vitest | `node_modules/.vitest/` | `cacheDir: '.cache/vitest'` in `vitest.config` |
| eslint | `.eslintcache` | `--cache-location .cache/eslint/` |
| stylelint | `.stylelintcache` | `--cache-location .cache/stylelint/` |
| next.js | `.next/` | `distDir: '.cache/next'` in `next.config` (dev only) |
| turbo | `.turbo/` | `"cacheDir": ".cache/turbo"` in `turbo.json` |
| parcel | `.parcel-cache/` | `--cache-dir .cache/parcel` |
| **Rust** | | |
| cargo | `target/` | `CARGO_TARGET_DIR=.cache/target` in `.cargo/config.toml` |
| **Go** | | |
| go test | per-package | `GOCACHE=.cache/go-build` env var |
| go cover | `cover.out` | `-coverprofile=.cache/cover.out` flag |

### `pyproject.toml` example

```toml
[tool.pytest.ini_options]
cache_dir = ".cache/pytest"

[tool.ruff]
cache-dir = ".cache/ruff"

[tool.ty]
cache-dir = ".cache/ty"

[tool.mypy]
cache_dir = ".cache/mypy"

[tool.coverage.run]
data_file = ".cache/coverage/.coverage"

[tool.coverage.html]
directory = ".cache/coverage/html"

[tool.coverage.xml]
output = ".cache/coverage/coverage.xml"
```

### Enforcement

The `.gitignore` includes a single `.cache/` entry that covers everything.
Individual tool cache directories (`.pytest_cache/`, `.ruff_cache/`, etc.) should
**not** appear at the repo root. If they do, the tool is misconfigured.

---

## Language Toolchain Standards

Each language has a **required** toolchain. Do not deviate.

### Python

| Concern | Tool | Notes |
|---------|------|-------|
| Package/project manager | **uv** | `uv init`, `uv add`, `uv run` — no pip, no poetry, no setuptools |
| Project config | **pyproject.toml** | Single source of truth — no `setup.py`, `setup.cfg`, `requirements.txt` |
| Testing | **pytest** | Via `uv run pytest` — configure in `[tool.pytest.ini_options]` |
| Linting + formatting | **ruff** | `ruff check` + `ruff format` — configure in `[tool.ruff]` |
| Type checking | **ty** | Strict mode — configure in `[tool.ty]` |
| Pre-commit hooks | **ruff + ty** | Both must pass before commit |
| MCP SDK | **FastMCP** (latest) | `uv add fastmcp` — the only supported Python MCP framework |

**No other linters, formatters, or type checkers.** No flake8, black, isort, pylint, mypy, pyright, pytype.

Minimal `pyproject.toml` tooling section:

```toml
[tool.ruff]
cache-dir = ".cache/ruff"
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "UP", "B", "A", "SIM", "TCH", "RUF"]

[tool.ty]
cache-dir = ".cache/ty"

[tool.pytest.ini_options]
cache_dir = ".cache/pytest"
testpaths = ["tests"]
```

### TypeScript / JavaScript

| Concern | Tool | Notes |
|---------|------|-------|
| Linting + formatting | **Biome** | Single tool — no ESLint, no Prettier, no separate formatter |
| Config | `biome.json` | At repo root |
| MCP SDK | **@modelcontextprotocol/sdk** (latest) | Official MCP TypeScript SDK — the only supported TS MCP framework |

**No ESLint, Prettier, or other JS/TS linters.** Biome handles everything.

Minimal `biome.json`:

```json
{
  "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json",
  "formatter": {
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true
    }
  }
}
```

### Rust

| Concern | Tool | Notes |
|---------|------|-------|
| Build system | **cargo** | Standard Rust toolchain |
| Project config | **Cargo.toml** | Single source of truth |
| Testing | **cargo test** | Built-in test framework |
| Linting | **clippy** | `cargo clippy -- -D warnings` |
| Formatting | **rustfmt** | `cargo fmt` |
| MCP SDK | **rmcp** (latest) | `cargo add rmcp` — the only supported Rust MCP framework |

### Pre-commit Hooks (all languages)

Every plugin **must** validate its skills in pre-commit. Use `skills-ref` from the
`@anthropic-ai/skills-ref` package:

```bash
# Validate a single skill
npx skills-ref validate skills/my-service/SKILL.md

# Validate all skills in the directory
npx skills-ref validate skills/

# Read parsed skill properties (debugging)
npx skills-ref read-properties skills/my-service/SKILL.md

# Convert skills to prompt format (testing)
npx skills-ref to-prompt skills/my-service/
```

Add to your pre-commit config (`.pre-commit-config.yaml` or equivalent):

```yaml
# Python repos (ruff + ty + skills)
repos:
  - repo: local
    hooks:
      - id: ruff
        name: ruff
        entry: uv run ruff check --fix
        language: system
        types: [python]
      - id: ruff-format
        name: ruff-format
        entry: uv run ruff format
        language: system
        types: [python]
      - id: ty
        name: ty
        entry: uv run ty check
        language: system
        types: [python]
      - id: skills-validate
        name: skills-validate
        entry: npx skills-ref validate skills/
        language: system
        pass_filenames: false
        files: 'skills/.*\.md$'
```

```yaml
# TypeScript repos (biome + skills)
repos:
  - repo: local
    hooks:
      - id: biome
        name: biome
        entry: npx biome check --write
        language: system
        types_or: [javascript, typescript, json]
      - id: skills-validate
        name: skills-validate
        entry: npx skills-ref validate skills/
        language: system
        pass_filenames: false
        files: 'skills/.*\.md$'
```

```yaml
# Rust repos (clippy + fmt + skills)
repos:
  - repo: local
    hooks:
      - id: cargo-fmt
        name: cargo-fmt
        entry: cargo fmt --check
        language: system
        types: [rust]
        pass_filenames: false
      - id: cargo-clippy
        name: cargo-clippy
        entry: cargo clippy -- -D warnings
        language: system
        types: [rust]
        pass_filenames: false
      - id: skills-validate
        name: skills-validate
        entry: npx skills-ref validate skills/
        language: system
        pass_filenames: false
        files: 'skills/.*\.md$'
```

The `skills-validate` hook runs whenever a `SKILL.md` file changes and ensures
frontmatter, structure, and content pass validation before commit.

### Docker & env safety hooks (all languages)

Every plugin **must** also run Docker security and env-baking checks in pre-commit.
Add these hooks to your `.pre-commit-config.yaml`:

```yaml
      # Docker security checks (all languages — add alongside your language hooks above)
      - id: docker-security
        name: docker-security
        entry: bash scripts/check-docker-security.sh
        language: system
        files: 'Dockerfile$'
        pass_filenames: true
      - id: no-baked-env
        name: no-baked-env
        entry: bash scripts/check-no-baked-env.sh .
        language: system
        files: '(Dockerfile|docker-compose\.yaml|\.dockerignore|entrypoint\.sh)$'
        pass_filenames: false
      - id: ensure-ignore-files
        name: ensure-ignore-files
        entry: bash scripts/ensure-ignore-files.sh --check .
        language: system
        files: '(\.gitignore|\.dockerignore)$'
        pass_filenames: false
```

Copy `check-docker-security.sh`, `check-no-baked-env.sh`, and `ensure-ignore-files.sh` from
the claude-homelab repo's `scripts/` directory into each plugin's `scripts/` directory.

**`check-docker-security.sh`** verifies:
- Multi-stage build (builder + runtime stages)
- Non-root user (USER 1000:1000)
- No sensitive `ENV` directives baked into the image
- HEALTHCHECK present
- Dependency layer caching (manifest before source)

**`check-no-baked-env.sh`** verifies:
- No `environment:` block in `docker-compose.yaml` (all config via `env_file:` only)
- No sensitive `ENV` in Dockerfile
- No `.env` copied into the image
- `.dockerignore` excludes `.env`

**`ensure-ignore-files.sh`** (dual-mode):
- **Default**: appends missing patterns to `.gitignore` and `.dockerignore` (SessionStart hook)
- **`--check`**: reports missing patterns and exits non-zero (pre-commit/CI)
- Full pattern lists from the guide: secrets, runtime artifacts, AI tooling, IDE, caches, docs
- Language-aware: checks Python/TS/Rust patterns are uncommented
- Verifies `.env.example` is not accidentally gitignored

### Outdated dependency checks

Run `scripts/check-outdated-deps.sh` periodically (not in pre-commit — it requires network
access and is slow). It auto-detects Python/TypeScript/Rust from manifest files and reports
outdated packages, lock file staleness, and known vulnerabilities.

```bash
# Run manually or in CI
bash scripts/check-outdated-deps.sh
```

---

## HTTP Security — Bearer Tokens

HTTP-transport MCP servers **must**:
1. Use HTTP bearer token authentication by default (exception: `MY_SERVICE_MCP_NO_AUTH=true` for proxy-managed auth)
2. Expose `GET /health` returning `{"status":"ok"}` — unauthenticated, exempt from bearer token enforcement. Used by Docker healthchecks, compose healthchecks, and `test_live.sh`.

**Stdio transport does not use bearer auth.** `stdio` mode runs over stdin/stdout and has no HTTP
headers, so bearer token enforcement applies only when `MY_SERVICE_MCP_TRANSPORT=http`.

### Environment variable naming convention

Use a **flat prefix structure** — no generic/unprefixed vars:

| Prefix | Scope | Examples |
|--------|-------|---------|
| `MY_SERVICE_` | Service-related (API URL, API key, credentials) | `MY_SERVICE_URL`, `MY_SERVICE_API_KEY` |
| `MY_SERVICE_MCP_` | MCP server config (host, port, auth, transport) | `MY_SERVICE_MCP_HOST`, `MY_SERVICE_MCP_PORT`, `MY_SERVICE_MCP_TOKEN` |

**No generic env vars.** Every variable is prefixed with the service name. This prevents
collisions when running multiple MCP servers on the same host and makes it clear which
service a variable belongs to.

### Required environment variables

| Variable | Purpose |
|---|---|
| `MY_SERVICE_MCP_TOKEN` | Bearer token the server validates. Required unless `MY_SERVICE_MCP_NO_AUTH=true`. |
| `MY_SERVICE_MCP_NO_AUTH` | Set to `true` to disable bearer auth. Default: unset (auth enforced). |
| `MY_SERVICE_MCP_HOST` | HTTP bind address. Default: `0.0.0.0`. |
| `MY_SERVICE_MCP_PORT` | HTTP port. Default: service-specific. |
| `MY_SERVICE_MCP_TRANSPORT` | `http` (default) or `stdio`. |
| `MY_SERVICE_MCP_ALLOW_YOLO` | Skip elicitation for destructive ops. Default: `false`. |
| `MY_SERVICE_MCP_ALLOW_DESTRUCTIVE` | Auto-confirm all destructive ops. Default: `false`. |
| `MY_SERVICE_URL` | Upstream service URL (e.g., `https://gotify.example.com`). |
| `MY_SERVICE_API_KEY` | Upstream service API key/token. |

### Token generation

If `MY_SERVICE_MCP_TOKEN` is not set and `MY_SERVICE_MCP_NO_AUTH` is not `true`, the server **must fail to
start** with a clear error message:

```
CRITICAL: MY_SERVICE_MCP_TOKEN is not set.
Set MY_SERVICE_MCP_TOKEN to a secure random token, or set MY_SERVICE_MCP_NO_AUTH=true to disable auth
(only appropriate when secured at the network/proxy level).

Generate a token with: openssl rand -hex 32
```

The `sync-env.sh` hook **fails with a clear error** if `MY_SERVICE_MCP_TOKEN` is not set — it does
not auto-generate tokens. Auto-generation causes a token mismatch: the server reads the generated
token but Claude Code sends the (empty) userConfig value, resulting in silent 401 errors on every
MCP call. Users must generate a token and paste it into the plugin's userConfig field:

```bash
# Generate a token:
openssl rand -hex 32
# Then paste it into the plugin's MCP token userConfig field.
```

### Bearer token enforcement by language

#### Python (FastMCP + Starlette)

```python
import os
import sys
from fastmcp import FastMCP
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

BEARER_TOKEN = os.getenv("MY_SERVICE_MCP_TOKEN")
MY_SERVICE_MCP_NO_AUTH = os.getenv("MY_SERVICE_MCP_NO_AUTH", "").lower() in ("true", "1", "yes")

if not MY_SERVICE_MCP_NO_AUTH and not BEARER_TOKEN:
    print(
        "CRITICAL: MY_SERVICE_MCP_TOKEN is not set.\n"
        "Set MY_SERVICE_MCP_TOKEN to a secure random token, or set MY_SERVICE_MCP_NO_AUTH=true\n"
        "to disable auth (only appropriate when secured at the network/proxy level).\n\n"
        "Generate a token with: openssl rand -hex 32",
        file=sys.stderr,
    )
    sys.exit(1)

class BearerAuthMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if MY_SERVICE_MCP_NO_AUTH:
            return await call_next(request)
        if request.url.path in ("/health",):
            return await call_next(request)
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer ") or auth[7:] != BEARER_TOKEN:
            return JSONResponse({"error": "Unauthorized"}, status_code=401)
        return await call_next(request)

mcp = FastMCP(name="MyServiceMCP", ...)
mcp.app.add_middleware(BearerAuthMiddleware)
```

#### TypeScript (Express middleware)

```typescript
import { timingSafeEqual } from "node:crypto";
import type { NextFunction, Request, Response } from "express";

export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  // Health + well-known are always unauthenticated
  if (req.path === "/health" || req.path.startsWith("/.well-known")) {
    next();
    return;
  }

  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    res.status(401).json({ error: "Missing or invalid Authorization header" });
    return;
  }

  const token = authHeader.slice(7);
  const tokenBuf = Buffer.from(token);
  const expectedBuf = Buffer.from(env.AUTH_TOKEN);
  if (tokenBuf.length !== expectedBuf.length || !timingSafeEqual(tokenBuf, expectedBuf)) {
    res.status(401).json({ error: "Invalid bearer token" });
    return;
  }

  next();
}
```

#### Rust (rmcp + axum)

Rust servers use **rmcp** with the `#[tool_router]` macro for tool registration and
`StreamableHttpService` for HTTP transport. Auth is handled as axum middleware wrapping
the MCP service.

```rust
use rmcp::{
    tool, tool_handler, tool_router,
    handler::server::wrapper::Parameters,
    model::{ServerCapabilities, ServerInfo, InitializeResult},
    service::RequestContext,
    transport::{stdio, streamable_http_server::StreamableHttpService},
    ErrorData, RoleServer, ServerHandler, ServiceExt,
};

#[derive(Clone)]
pub struct MyServiceMcpServer { /* config, clients, etc. */ }

// Register the single action+subaction tool
#[tool_router]
impl MyServiceMcpServer {
    #[tool(
        name = "my_service",
        description = "Unified tool. Use action/subaction routing. Call action:help for reference."
    )]
    async fn my_service(
        &self,
        Parameters(raw): Parameters<serde_json::Map<String, serde_json::Value>>,
    ) -> Result<String, ErrorData> {
        let action = raw.get("action").and_then(|v| v.as_str()).unwrap_or("unknown");
        let subaction = raw.get("subaction").and_then(|v| v.as_str()).unwrap_or("");
        // Parse and dispatch...
        todo!()
    }
}

#[tool_handler(router = Self::tool_router())]
impl ServerHandler for MyServiceMcpServer {
    fn get_info(&self) -> ServerInfo { /* capabilities, name, version, instructions */ }
    async fn initialize(&self, request: InitializeRequestParams, _ctx: RequestContext<RoleServer>)
        -> Result<InitializeResult, ErrorData> { /* ... */ }
}

// Dual transport: stdio or HTTP
pub async fn run_stdio(cfg: Config) -> Result<(), Box<dyn std::error::Error>> {
    let service = MyServiceMcpServer::new(cfg).serve(stdio()).await?;
    service.waiting().await?;
    Ok(())
}

pub async fn run_http(cfg: Config, host: &str, port: u16) -> Result<(), Box<dyn std::error::Error>> {
    let mcp_service = StreamableHttpService::new(
        move || Ok(MyServiceMcpServer::new(cfg.clone())),
        Default::default(),
        Default::default(),
    );
    // Wrap with auth middleware
    let app = Router::new()
        .nest_service("/mcp", mcp_service)
        .route("/health", get(health));
    let listener = tokio::net::TcpListener::bind((host, port)).await?;
    axum::serve(listener, app).await?;
    Ok(())
}
```

**Bearer auth** is applied as axum middleware on the `/mcp` route using
`subtle::ConstantTimeEq` for timing-safe token comparison. The `/health`
route is always unauthenticated.

**Key patterns across all languages:**
- Timing-safe comparison (`hmac.compare_digest`, `timingSafeEqual`, `subtle::ConstantTimeEq`)
- `/health` always unauthenticated
- Fail startup if no token and auth not explicitly disabled

### `.mcp.json` — passing the token

The bearer token must be passed from `userConfig` to the MCP connection headers. Since
`MY_SERVICE_MCP_TOKEN` is synced to `.env` (sensitive), it is also exposed as
`CLAUDE_PLUGIN_OPTION_MY_SERVICE_MCP_TOKEN`. However, `.mcp.json` only supports
`${user_config.*}` substitution — so the token must be a `userConfig` field:

```json
{
  "mcpServers": {
    "my-service-mcp": {
      "type": "http",
      "url": "${user_config.my_service_mcp_url}",
      "headers": {
        "Authorization": "Bearer ${user_config.my_service_mcp_token}"
      }
    }
  }
}
```

Add `my_service_mcp_token` to `userConfig` in `plugin.json`:

```json
"my_service_mcp_token": {
  "type": "string",
  "title": "MCP Server Bearer Token",
  "description": "Bearer token for authenticating with the MCP server. Must match MY_SERVICE_MCP_TOKEN in the server's .env. Generate with: openssl rand -hex 32",
  "sensitive": true
}
```

The `sync-env.sh` hook maps this to `MY_SERVICE_MCP_TOKEN` in `.env`.

---

## Tool Design — Action + Subaction Pattern

**Mandatory.** All MCP servers **must** expose exactly **two tools**:

1. **Domain tool** — a single tool using `action` + optional `subaction` parameters for all operations
2. **Help tool** — auto-generated from the domain tool's schema, returns available actions, subactions, and parameter docs

No other tool structure is allowed. Do not create individual tools per operation.

### Engineering principles

Plugin work should follow a simple engineering loop:

- **Research → Plan → Validate → Implement**
- **Prove it works**

Do not jump straight from an idea to implementation. Inspect the service API, define the tool
contract, validate the schema and safety model, then implement. Completion requires evidence:
tests, live calls, schema validation, or runtime output — not assumptions.

### Why

- Claude Code loads all tool definitions into context on every request
- 20 individual tools × 500 tokens each = 10,000 tokens of tool overhead per call
- 1 tool with 20 actions = ~800 tokens total — ~12× improvement
- Subactions further group related operations without new top-level tokens
- The help tool lets Claude discover capabilities at runtime without extra context overhead

### Context and token efficiency

This guide optimizes for low-overhead tool use:

- Keep tool count minimal — exactly one domain tool plus one help tool
- Keep list responses small by default — pagination is mandatory and conservative defaults are preferred
- Keep examples and docs concise — include the contract, not every possible variation

Token waste is design debt. Reduce schema surface area, response size, and documentation noise
unless they clearly improve usability.

### Pattern

#### Python (FastMCP)

```python
from typing import Literal, Optional
from fastmcp import FastMCP, Context

mcp = FastMCP(name="MyServiceMCP")

@mcp.tool()
async def my_service(
    ctx: Context,
    action: Literal[
        "list", "get", "create", "update", "delete",
        "search", "status", "logs"
    ],
    subaction: Optional[Literal["enable", "disable", "reload"]] = None,
    id: Optional[str] = None,
    name: Optional[str] = None,
    query: Optional[str] = None,
    config: Optional[dict] = None,
    confirm: bool = False,
) -> dict | list | str:
    """Interact with My Service.

    Actions:
      list     — list all resources
      get      — get resource by id
      create   — create new resource (requires name, config)
      update   — update resource (requires id, config)
      delete   — delete resource by id (destructive — requires confirm=true)
      search   — search resources by query
      status   — check service health
      logs     — tail recent log lines

    Subactions (for action=update):
      enable   — enable the resource
      disable  — disable the resource
      reload   — reload resource config
    """
    match action:
        case "list":
            return await _list_resources(ctx)
        case "get":
            return await _get_resource(ctx, id)
        case "create":
            return await _create_resource(ctx, name, config)
        case "update":
            return await _update_resource(ctx, id, subaction, config)
        case "delete":
            return await _delete_resource(ctx, id, confirm=confirm)
        case "search":
            return await _search_resources(ctx, query)
        case "status":
            return await _get_status(ctx)
        case "logs":
            return await _get_logs(ctx)
        case _:
            return f"Unknown action: {action}"
```

#### TypeScript (@modelcontextprotocol/sdk)

```typescript
import { McpServer } from "@modelcontextprotocol/server";
import * as z from "zod/v4";
import type { CallToolResult } from "@modelcontextprotocol/server";

const server = new McpServer({ name: "MyServiceMCP", version: "1.0.0" });

server.registerTool(
  "my_service",
  {
    description: "Interact with My Service. Call my_service_help for reference.",
    inputSchema: z.object({
      action: z.enum(["list", "get", "create", "update", "delete", "search", "status", "logs"]),
      subaction: z.enum(["enable", "disable", "reload"]).optional()
        .describe("Subaction for action=update"),
      id: z.string().optional().describe("Resource ID"),
      name: z.string().optional().describe("Resource name"),
      query: z.string().optional().describe("Search query"),
      config: z.record(z.unknown()).optional().describe("Configuration object"),
      confirm: z.boolean().default(false).describe("Confirm destructive actions"),
    }),
  },
  async ({ action, subaction, id, name, query, config, confirm }): Promise<CallToolResult> => {
    let result: unknown;
    switch (action) {
      case "list":    result = await listResources(); break;
      case "get":     result = await getResource(id!); break;
      case "create":  result = await createResource(name!, config); break;
      case "update":  result = await updateResource(id!, subaction, config); break;
      case "delete":  result = await deleteResource(id!, confirm); break;
      case "search":  result = await searchResources(query!); break;
      case "status":  result = await getStatus(); break;
      case "logs":    result = await getLogs(); break;
      default:        result = { error: `Unknown action: ${action}` };
    }
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  },
);
```

#### Rust (rmcp)

```rust
use rmcp::{tool, tool_router, tool_handler, ServerHandler, ErrorData};
use rmcp::handler::server::wrapper::Parameters;
use serde::Deserialize;

#[derive(Debug, Deserialize, schemars::JsonSchema)]
pub struct MyServiceParams {
    pub action: String,
    pub subaction: Option<String>,
    pub id: Option<String>,
    pub name: Option<String>,
    pub query: Option<String>,
    pub config: Option<serde_json::Value>,
    #[serde(default)]
    pub confirm: bool,
}

#[derive(Clone)]
pub struct MyServiceMcpServer { /* services, config */ }

#[tool_router]
impl MyServiceMcpServer {
    #[tool(
        name = "my_service",
        description = "Interact with My Service. Call my_service_help for reference."
    )]
    async fn my_service(
        &self,
        #[tool(param)] params: MyServiceParams,
    ) -> Result<String, ErrorData> {
        match params.action.as_str() {
            "list"   => Ok(serde_json::to_string(&self.svc.list_resources().await?).unwrap()),
            "get"    => Ok(serde_json::to_string(&self.svc.get_resource(params.id.as_deref()).await?).unwrap()),
            "create" => Ok(serde_json::to_string(&self.svc.create_resource(params.name.as_deref(), params.config).await?).unwrap()),
            "update" => Ok(serde_json::to_string(&self.svc.update_resource(params.id.as_deref(), params.subaction.as_deref(), params.config).await?).unwrap()),
            "delete" => Ok(serde_json::to_string(&self.svc.delete_resource(params.id.as_deref(), params.confirm).await?).unwrap()),
            "search" => Ok(serde_json::to_string(&self.svc.search_resources(params.query.as_deref()).await?).unwrap()),
            "status" => Ok(serde_json::to_string(&self.svc.get_status().await?).unwrap()),
            "logs"   => Ok(serde_json::to_string(&self.svc.get_logs().await?).unwrap()),
            other    => Err(ErrorData::invalid_params(format!("Unknown action: {other}"), None)),
        }
    }
}
```

### Filtering, pagination, and sorting (required)

All `list`-type actions **must** support filtering, pagination, and sorting. Never return
unbounded result sets — they blow up the client's context window and waste tokens.

**Standard parameters** for any action that returns a list:

#### Python (FastMCP)

```python
@mcp.tool()
async def my_service(
    ctx: Context,
    action: Literal["list", ...],
    # Pagination
    offset: int = 0,                # Skip N results
    limit: int = 10,                # Max results (recommended default 10, max 500)
    # Sorting
    sort_by: str | None = None,     # Field to sort by (e.g., "created", "name")
    sort_order: str | None = None,  # "asc" or "desc" (default "desc")
    # Filtering
    query: str | None = None,       # Free-text search/filter
    status: str | None = None,      # Filter by status (domain-specific)
) -> dict:
    ...
```

#### TypeScript (@modelcontextprotocol/sdk + zod)

```typescript
server.tool("my_service", {
  action: z.enum(["list", ...]),
  offset: z.number().int().min(0).default(0).describe("Skip N results"),
  limit: z.number().int().min(1).max(500).default(10).describe("Max results"),
  sort_by: z.string().optional().describe("Field to sort by"),
  sort_order: z.enum(["asc", "desc"]).default("desc").optional(),
  query: z.string().optional().describe("Free-text filter"),
}, async ({ action, offset, limit, sort_by, sort_order, query }) => {
  // ...
});
```

#### Rust (rmcp + schemars)

```rust
#[derive(Debug, Clone, Deserialize, schemars::JsonSchema)]
pub struct ListRequest {
    pub subaction: Option<ListSubaction>,
    /// Skip N results (default 0)
    pub offset: Option<usize>,
    /// Max results (recommended default 10, max 500)
    pub limit: Option<i64>,
    /// Field to sort by
    pub sort_by: Option<String>,
    /// "asc" or "desc" (default "desc")
    pub sort_order: Option<String>,
    /// Free-text filter
    pub query: Option<String>,
}
```

**Response format** for paginated results (all languages):

```json
{
  "items": [...],
  "total": 142,
  "limit": 10,
  "offset": 0,
  "has_more": true
}
```

**Rules:**
- Default `limit` to a sensible value. Recommended default: `10` unless the domain clearly
  justifies a different number. Never return all records by default.
- Include `total` count so Claude knows how much data exists
- Include `has_more` flag so Claude can request the next page
- Apply the response size limit (~512KB) as a safety net even with pagination

### Help tool (required)

Every server **must** expose a help tool that returns the full action/subaction reference,
auto-generated from the domain tool's schema. This lets Claude discover capabilities
at runtime without the SKILL.md needing to be loaded.

The help tool response is part of the contract. It **must** expose, for every action:
- action name
- description
- required vs optional parameters
- subactions, if any
- destructive marker where applicable

Tests should fail if the help tool is missing, cannot be called, or omits any required fields.

#### Python

```python
@mcp.tool()
async def my_service_help(
    action: str | None = None,
) -> str:
    """Return available actions, subactions, and parameters for the my_service tool.

    Call with no arguments for a full overview.
    Call with action="<name>" for detailed help on a specific action.
    """
    schema = {
        "list": {"description": "List all resources", "params": {}},
        "get": {"description": "Get resource by id", "params": {"id": "Resource ID (required)"}},
        "create": {"description": "Create new resource", "params": {"name": "Resource name (required)", "config": "Configuration dict (optional)"}},
        "update": {
            "description": "Update resource",
            "params": {"id": "Resource ID (required)", "config": "Configuration dict (optional)"},
            "subactions": {
                "enable": "Enable the resource",
                "disable": "Disable the resource",
                "reload": "Reload resource config",
            },
        },
        "delete": {"description": "Delete resource by id (DESTRUCTIVE)", "params": {"id": "Resource ID (required)", "confirm": "Set true after confirmation or elicitation"}},
        "search": {"description": "Search resources", "params": {"query": "Search query (required)"}},
        "status": {"description": "Check service health", "params": {}},
        "logs": {"description": "Tail recent log lines", "params": {}},
    }

    if action:
        if action not in schema:
            return f"Unknown action: {action}. Available: {', '.join(schema.keys())}"
        entry = schema[action]
        lines = [f"## {action}\n{entry['description']}\n"]
        if entry.get("params"):
            lines.append("**Parameters:**")
            for k, v in entry["params"].items():
                lines.append(f"  - `{k}`: {v}")
        if entry.get("subactions"):
            lines.append("**Subactions:**")
            for k, v in entry["subactions"].items():
                lines.append(f"  - `{k}`: {v}")
        return "\n".join(lines)

    lines = ["# my_service — Available Actions\n"]
    for name, entry in schema.items():
        destructive = " ⚠️" if "DESTRUCTIVE" in entry["description"] else ""
        lines.append(f"- **{name}**{destructive} — {entry['description']}")
    lines.append("\nCall `my_service_help(action=\"<name>\")` for detailed parameter info.")
    return "\n".join(lines)
```

#### TypeScript (@modelcontextprotocol/sdk)

```typescript
import * as z from "zod/v4";

server.registerTool(
  "my_service_help",
  {
    description: "Return available actions, subactions, and parameters for the my_service tool",
    inputSchema: z.object({
      action: z.string().optional().describe("Get detailed help for a specific action"),
    }),
  },
  async ({ action }) => {
    const schema: Record<string, { description: string; params: Record<string, string>; subactions?: Record<string, string> }> = {
      /* same structure as Python */
    };

    if (action) {
      const entry = schema[action];
      if (!entry) return { content: [{ type: "text", text: `Unknown action: ${action}` }] };
      // Format detailed help for the action
    }

    // Format overview of all actions
    const overview = Object.entries(schema)
      .map(([name, entry]) => `- **${name}** — ${entry.description}`)
      .join("\n");
    return { content: [{ type: "text", text: overview }] };
  },
);
```

#### Rust (rmcp)

```rust
use rmcp::{tool, model::CallToolResult};
use serde::Deserialize;

#[derive(Debug, Deserialize, schemars::JsonSchema)]
pub struct HelpParams {
    /// Get detailed help for a specific action
    pub action: Option<String>,
}

// Inside your #[tool_router] impl:
#[tool(
    name = "my_service_help",
    description = "Return available actions, subactions, and parameters for the my_service tool"
)]
async fn my_service_help(
    &self,
    #[tool(param)] params: HelpParams,
) -> Result<CallToolResult, rmcp::ErrorData> {
    let schema = self.build_help_schema(); // derive from tool registration

    if let Some(action) = &params.action {
        let entry = schema.get(action.as_str());
        let text = match entry {
            Some(e) => format!("## {action}\n{}\n{}", e.description, e.format_params()),
            None => format!("Unknown action: {action}. Available: {}", schema.keys().collect::<Vec<_>>().join(", ")),
        };
        return Ok(CallToolResult::text(text));
    }

    let overview = schema.iter()
        .map(|(name, e)| format!("- **{name}** — {}", e.description))
        .collect::<Vec<_>>()
        .join("\n");
    Ok(CallToolResult::text(overview))
}
```

The help tool schema object should be **derived from or kept in sync with** the domain
tool's actual type definitions — not maintained as a separate copy. If your language
supports runtime reflection on the tool schema, use that.

### Response shape contract

Tool responses should be structurally consistent across plugins:

- `list` actions **must** return a JSON object with pagination metadata
- `get` / `create` / `update` actions should return a JSON object, not ad-hoc plain text
- `delete` and other destructive actions may return a concise JSON object or concise text, but must remain testable
- Error responses should follow a consistent format and include actionable guidance

Prefer JSON objects over free-form text for normal success responses. Free-form prose is harder
to validate, harder to diff, and more likely to drift across implementations.

### SKILL.md tool reference format for action+subaction tools

```
mcp__my-service-mcp__my_service
  action:     (required) "list" | "get" | "create" | "update" | "delete" | "search" | "status" | "logs"
  subaction:  (optional, for action=update) "enable" | "disable" | "reload"
  id:         (required for get, update, delete) Resource ID
  name:       (required for create) Resource name
  query:      (required for search) Search query
  config:     (optional) Configuration dict
  confirm:    (required for destructive actions unless env bypass / elicitation succeeds) true
```

---

## Code Architecture

### Services layer (required)

All business logic **must** live in a services layer. Tool handlers are thin shims that
validate input, call the appropriate service, and format the response. This separation
allows adding new handlers (CLI, REST, tests) without duplicating logic.

```
src/ or <service>_mcp/
├── server.*                 # MCP server setup + tool registration (shims only)
├── client.*                 # Upstream API client (HTTP calls, auth)
├── services/                # Business logic — the real work happens here
│   ├── resource_service.*   # CRUD operations for resources
│   ├── monitoring_service.* # Health checks, metrics
│   └── config_service.*     # Configuration management
├── models/                  # Data models, types, enums
├── middleware/              # Auth, timing, rate limiting, error handling
└── utils/                   # Shared helpers (formatters, validators, logging)
```

**Tool handler pattern** — tools are thin shims that delegate to services:

#### Python (FastMCP)

```python
# ❌ Wrong — business logic in the tool handler
@mcp.tool()
async def my_service(action: str, id: str | None = None, ...) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{URL}/api/resources/{id}")
        data = response.json()
        # 50 lines of transformation logic...
        return transformed_data

# ✅ Right — tool handler delegates to service
@mcp.tool()
async def my_service(action: str, id: str | None = None, ...) -> dict:
    match action:
        case "get":
            return await resource_service.get(id)
        case "list":
            return await resource_service.list(limit=limit, offset=offset)
```

#### TypeScript (@modelcontextprotocol/sdk)

```typescript
import * as z from "zod/v4";
import { resourceService } from "./services/resource_service.js";

// ✅ Right — tool handler delegates to service
server.registerTool(
  "my_service",
  {
    description: "Interact with My Service. Call my_service_help for reference.",
    inputSchema: z.object({
      action: z.enum(["list", "get", "create", "update", "delete"]),
      id: z.string().optional(),
      // ...
    }),
  },
  async ({ action, id, ...rest }) => {
    switch (action) {
      case "get":
        return { content: [{ type: "text", text: JSON.stringify(await resourceService.get(id!)) }] };
      case "list":
        return { content: [{ type: "text", text: JSON.stringify(await resourceService.list(rest)) }] };
      // ...
    }
  },
);
```

#### Rust (rmcp)

```rust
// ✅ Right — tool handler delegates to service
#[tool(name = "my_service", description = "Interact with My Service.")]
async fn my_service(
    &self,
    #[tool(param)] params: MyServiceParams,
) -> Result<CallToolResult, ErrorData> {
    let result = match params.action.as_str() {
        "get" => self.resource_service.get(params.id.as_deref()).await?,
        "list" => self.resource_service.list(params.limit, params.offset).await?,
        _ => return Err(ErrorData::invalid_params(format!("Unknown action: {}", params.action), None)),
    };
    Ok(CallToolResult::text(serde_json::to_string(&result).unwrap()))
}
```

### Module size limit

**No file should exceed 500 lines.** If a module grows beyond this, split it:

- Extract service methods into domain-specific modules
- Split tool dispatch by action group (e.g., `_containers.py`, `_networks.py`)
- Move shared types/models to a `models/` or `types/` module
- Extract middleware into separate files

This keeps code reviewable, testable, and navigable.

### Naming consistency

Use one canonical service identifier and derive everything else from it consistently:

| Artifact | Pattern | Example |
|---|---|---|
| Plugin name | `<service>-mcp` | `my-service-mcp` |
| MCP server name | `<service>-mcp` | `my-service-mcp` |
| Domain tool name | `<service_with_underscores>` | `my_service` |
| Help tool name | `<service_with_underscores>_help` | `my_service_help` |
| Env prefix | `<SERVICE>_` / `<SERVICE>_MCP_` | `MY_SERVICE_`, `MY_SERVICE_MCP_` |
| Docker service name | `<service>-mcp` | `my-service-mcp` |
| Docker network default | `<service>_mcp` | `my-service_mcp` |
| Reverse proxy hostname | `<service>` | `my-service` |

Do not mix naming schemes inside one plugin. Naming drift is one of the fastest ways to create
confusing manifests, broken hooks, and tests that check the wrong thing.

---

## Destructive Operations — Confirmation Gate

Any action that can cause **data loss** (delete, destroy, prune, purge, reset) **must** require
confirmation before executing. This is enabled by default — users opt into skipping it.

### Three-path confirmation

Every destructive operation runs through this logic in order:

1. **Env bypass** — if `<SERVICE>_MCP_ALLOW_DESTRUCTIVE=true`, auto-confirm (for CI/automation)
2. **Elicitation** — if the MCP client supports `elicitation.form`, prompt the user with a
   confirmation dialog. Skipped when `<SERVICE>_MCP_ALLOW_YOLO=true` (YOLO mode)
3. **Hard block** — if neither bypass is enabled and elicitation isn't available, deny the
   operation and return guidance on how to proceed

### Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `<SERVICE>_MCP_ALLOW_DESTRUCTIVE` | `false` | Auto-confirm all destructive ops (CI/automation) |
| `<SERVICE>_MCP_ALLOW_YOLO` | `false` | Skip elicitation prompts but still allow `{ confirm: true }` in params |

### `.env` and `.env.example`

Both `ALLOW_YOLO` and `ALLOW_DESTRUCTIVE` must be defined in `.env` and `.env.example` — **not**
in the `docker-compose.yaml` `environment:` block. The compose file uses `env_file: .env` only:

```bash
# .env.example
MY_SERVICE_MCP_ALLOW_YOLO=false        # true = skip elicitation prompts
MY_SERVICE_MCP_ALLOW_DESTRUCTIVE=false # true = auto-confirm all destructive ops
```

The container reads these from `.env` via `env_file:`. No `environment:` block is needed or allowed.

### TypeScript implementation (reference: arcane-mcp)

```typescript
interface ConfirmResult {
  confirmed: boolean;
  method: "env_bypass" | "elicitation" | "blocked";
}

async function confirmDestructive(
  server: Server,
  action: string,
  subaction: string,
  id: string | undefined,
): Promise<ConfirmResult> {
  // Path 1: env bypass
  if (env.ALLOW_DESTRUCTIVE) {
    return { confirmed: true, method: "env_bypass" };
  }

  // Path 2: elicitation (skipped in YOLO mode)
  if (!env.YOLO_MODE && server.getClientCapabilities()?.elicitation?.form) {
    try {
      const result = await server.elicitInput({
        mode: "form",
        message: `WARNING: Destructive operation **${action}:${subaction}**${
          id ? ` on \`${id}\`` : ""
        }.\n\nThis action cannot be undone.\nTo suppress this prompt, set ${SERVICE}_MCP_ALLOW_YOLO=true.`,
        requestedSchema: {
          type: "object",
          properties: {
            confirm: {
              type: "boolean",
              title: `${subaction.charAt(0).toUpperCase() + subaction.slice(1)} this ${action}?`,
              description: "I understand this cannot be undone.",
              default: false,
            },
          },
          required: ["confirm"],
        },
      });
      if (result.action === "accept" && result.content?.confirm === true) {
        return { confirmed: true, method: "elicitation" };
      }
      return { confirmed: false, method: "elicitation" };
    } catch {
      // Elicitation failed — fall through to blocked
    }
  }

  // Path 3: hard block
  return { confirmed: false, method: "blocked" };
}
```

### Tool handler integration

Call `confirmDestructive` before executing any destructive subaction. When blocked,
return actionable guidance — not just an error:

```typescript
// Inside the action+subaction dispatcher:
if (DESTRUCTIVE_SUBACTIONS.has(subaction) && params?.confirm !== true) {
  const gate = await confirmDestructive(server, action, subaction, id);
  if (!gate.confirmed) {
    return {
      content: [{
        type: "text",
        text: gate.method === "elicitation"
          ? "Operation cancelled by user."
          : `⚠️ Confirmation required. Re-call with params: { confirm: true } to proceed.`,
      }],
      isError: gate.method === "elicitation",  // user-declined = error, blocked = guidance
    };
  }
}
```

### Python equivalent

```python
async def confirm_destructive(
    server: FastMCP, action: str, subaction: str, target_id: str | None = None
) -> tuple[bool, str]:
    """Returns (confirmed, method)."""
    if os.getenv(f"{SERVICE}_MCP_ALLOW_DESTRUCTIVE", "").lower() in ("true", "1"):
        return True, "env_bypass"

    if not os.getenv(f"{SERVICE}_MCP_ALLOW_YOLO", "").lower() in ("true", "1"):
        # Attempt elicitation if client supports it
        try:
            result = await server.elicit(
                message=f"Destructive: {action}:{subaction}" + (f" on `{target_id}`" if target_id else ""),
                schema={"confirm": {"type": "boolean", "required": True}},
            )
            if result.action == "accept" and result.data.get("confirm"):
                return True, "elicitation"
            return False, "elicitation"
        except Exception:
            pass

    return False, "blocked"
```

### Rust equivalent (rmcp)

```rust
use rmcp::model::{CreateElicitationRequestParams, ElicitationSchema};

pub struct ConfirmResult {
    pub confirmed: bool,
    pub method: &'static str, // "env_bypass", "elicitation", "blocked"
}

pub async fn confirm_destructive(
    ctx: &rmcp::service::RequestContext<rmcp::RoleServer>,
    action: &str,
    subaction: &str,
    target_id: Option<&str>,
) -> ConfirmResult {
    // Path 1: env bypass
    if std::env::var(format!("{SERVICE}_MCP_ALLOW_DESTRUCTIVE"))
        .map_or(false, |v| v == "true" || v == "1")
    {
        return ConfirmResult { confirmed: true, method: "env_bypass" };
    }

    // Path 2: elicitation (skipped in YOLO mode)
    let yolo = std::env::var(format!("{SERVICE}_MCP_ALLOW_YOLO"))
        .map_or(false, |v| v == "true" || v == "1");

    if !yolo {
        let message = format!(
            "Destructive: {action}:{subaction}{}",
            target_id.map_or(String::new(), |id| format!(" on `{id}`"))
        );
        let schema = ElicitationSchema::builder()
            .required_boolean("confirm")
            .build()
            .unwrap();
        let params = CreateElicitationRequestParams::FormElicitationParams {
            meta: None,
            message,
            requested_schema: schema,
        };
        if let Ok(result) = ctx.peer().create_elicitation(params).await {
            if result.action == "accept" {
                return ConfirmResult { confirmed: true, method: "elicitation" };
            }
            return ConfirmResult { confirmed: false, method: "elicitation" };
        }
    }

    // Path 3: hard block
    ConfirmResult { confirmed: false, method: "blocked" }
}
```

### SKILL.md documentation

Destructive subactions in the skill's tool reference **must** be clearly marked:

```markdown
### Delete resource — DESTRUCTIVE

Requires confirmation. Set `<SERVICE>_MCP_ALLOW_YOLO=true` to skip prompts.

Always confirm with user before executing.
```

---

## Middleware & Server Hardening

MCP servers **should** implement a middleware stack to protect against abuse and ensure
observability. The order matters — outermost middleware runs first.

### Recommended middleware stack

| Layer | Purpose | Required? |
|-------|---------|-----------|
| **Timing** | Track request/response duration per tool call | Yes |
| **Logging** | Log all tool calls and resource reads | Yes |
| **Error handling** | Convert exceptions to MCP errors, track stats | Yes |
| **Rate limiting** | Per-IP request throttling (e.g., 100 req/min) | Recommended |
| **Response limiting** | Cap responses at ~512KB to protect client context | Recommended |
| **Bearer auth** | Token validation (ASGI-level or framework middleware) | Yes |
| **Health** | Pass-through for `/health` endpoint (unauthenticated) | Yes |

### Error handling

Errors returned to Claude should be **LLM-friendly** — include:
- What action failed and on what target
- A unique error ID for traceability (e.g., 8-char UUID)
- Whether the error is retryable
- Actionable guidance (not raw stack traces)

```
container:stop on 'nginx-proxy' — Arcane API error (503): Service Unavailable.
Service may be temporarily unavailable. Retry after a moment. [err:a1b2c3d4]
```

### Graceful shutdown

All servers **must** handle `SIGTERM` and `SIGINT` for clean container stops:
- Drain in-flight requests
- Close database connections
- Flush log buffers

Python (FastMCP handles this), TypeScript (Express `server.close()`), Rust (tokio signal handlers).

### Response size limits

Tool responses can be arbitrarily large (e.g., listing 10,000 containers). Cap responses
to prevent blowing up the client's context window:

#### Python (FastMCP)

FastMCP 3.x includes built-in `ResponseLimitingMiddleware`:

```python
from fastmcp import FastMCP
from fastmcp.server.middleware.response_limiting import ResponseLimitingMiddleware

mcp = FastMCP("MyServiceMCP")

# Limit all tool responses to 512KB
mcp.add_middleware(ResponseLimitingMiddleware(max_size=512_000))
```

Or manually for custom truncation:

```python
MAX_RESPONSE_SIZE = 512 * 1024  # 512KB
if len(response) > MAX_RESPONSE_SIZE:
    response = response[:MAX_RESPONSE_SIZE] + "\n\n[Response truncated at 512KB]"
```

#### TypeScript (@modelcontextprotocol/sdk)

```typescript
const MAX_RESPONSE_SIZE = 512 * 1024; // 512KB

function truncateResponse(text: string): string {
  if (Buffer.byteLength(text, "utf-8") <= MAX_RESPONSE_SIZE) return text;
  // Truncate at byte boundary, then trim to last complete UTF-8 char
  const truncated = Buffer.from(text).subarray(0, MAX_RESPONSE_SIZE).toString("utf-8");
  return truncated + "\n\n[Response truncated at 512KB]";
}
```

#### Rust (rmcp)

```rust
const MAX_RESPONSE_SIZE: usize = 512 * 1024; // 512KB

fn truncate_response(text: &str) -> String {
    if text.len() <= MAX_RESPONSE_SIZE {
        return text.to_string();
    }
    // Find the last valid UTF-8 char boundary before the limit
    let truncated = &text[..text.floor_char_boundary(MAX_RESPONSE_SIZE)];
    format!("{truncated}\n\n[Response truncated at 512KB]")
}
```

---

## CI/CD Pipeline

Every plugin repo **should** have a GitHub Actions CI pipeline.

### Verification expectations

Use a test-first mindset for plugin work:

1. Write the failing test or live-check first
2. Implement the smallest change that makes it pass
3. Verify with live or integration evidence

For MCP plugins, "verification" means more than unit tests. It includes schema validation,
authenticated live tool calls, auth rejection, destructive-op gating, and pagination/help-tool
contract checks where applicable.

### Minimum CI jobs

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  lint:
    # Python: uv run ruff check . && uv run ruff format --check .
    # TypeScript: npx biome ci .
    # Rust: cargo fmt --check && cargo clippy -- -D warnings

  typecheck:
    # Python: uv run ty check
    # TypeScript: npx tsc --noEmit
    # Rust: (covered by clippy)

  test:
    # Python: uv run pytest
    # TypeScript: npx vitest run
    # Rust: cargo test

  version-sync:
    # Verify pyproject.toml/package.json version matches .claude-plugin/plugin.json version

  audit:
    # Python: uv audit
    # TypeScript: npm audit
    # Rust: cargo audit

  contract-drift:
    # Verify schema, help output, and SKILL.md stay in sync
```

### Version sync check

The version in your language manifest **must** match `.claude-plugin/plugin.json`:

```bash
# Example check (Python)
PYPROJECT_VERSION=$(grep '^version' pyproject.toml | head -1 | cut -d'"' -f2)
PLUGIN_VERSION=$(jq -r '.version' .claude-plugin/plugin.json)
if [ "$PYPROJECT_VERSION" != "$PLUGIN_VERSION" ]; then
  echo "Version mismatch: pyproject.toml=$PYPROJECT_VERSION plugin.json=$PLUGIN_VERSION"
  exit 1
fi
```

### Contract drift checks

CI should fail when the plugin's public contract disagrees with itself. At minimum, compare:

- exposed MCP schema
- help tool output
- `skills/<service>/SKILL.md` action/subaction reference

If one says an action exists and another omits it, that is a contract bug. The goal is to catch
drift before release, not after Claude discovers inconsistent behavior at runtime.

---

## MCP Resources

Servers **may** expose read-only data as MCP resources for direct access without tool calls.
Resources are useful for data Claude can reference without executing an action.

#### Python (FastMCP)

```python
@mcp.resource("myservice://status")
async def service_status() -> str:
    """Current service status and configuration."""
    return json.dumps(await get_status())

@mcp.resource("myservice://items/{item_id}")
async def get_item(item_id: str) -> str:
    """Details for a specific item."""
    return json.dumps(await fetch_item(item_id))
```

#### TypeScript (@modelcontextprotocol/sdk)

```typescript
server.resource("myservice://status", "Service status", async () => ({
  contents: [{ uri: "myservice://status", text: JSON.stringify(await getStatus()) }],
}));

server.resource("myservice://items/{item_id}", "Item details", async (uri) => {
  const itemId = uri.pathname.split("/").pop()!;
  return { contents: [{ uri: uri.href, text: JSON.stringify(await fetchItem(itemId)) }] };
});
```

#### Rust (rmcp)

```rust
// In your ServerHandler impl, override list_resources and read_resource:
fn list_resources(
    &self,
    _request: Option<PaginatedRequestParams>,
    _context: RequestContext<RoleServer>,
) -> impl Future<Output = Result<ListResourcesResult, McpError>> + '_ {
    async {
        Ok(ListResourcesResult {
            resources: vec![
                Resource { uri: "myservice://status".into(), name: "Service Status".into(), ..Default::default() },
            ],
            ..Default::default()
        })
    }
}

fn read_resource(
    &self,
    request: ReadResourceRequestParams,
    _context: RequestContext<RoleServer>,
) -> impl Future<Output = Result<ReadResourceResult, McpError>> + '_ {
    async move {
        match request.uri.as_str() {
            "myservice://status" => {
                let status = self.get_status().await?;
                Ok(ReadResourceResult {
                    contents: vec![ResourceContents::text(request.uri, serde_json::to_string(&status).unwrap())],
                })
            }
            _ => Err(McpError::resource_not_found(request.uri, None)),
        }
    }
}
```

### When not to expose a resource

Do **not** expose a resource just because the data exists. Prefer tools instead when:

- the data is large, frequently changing, or expensive to serialize
- access should be filtered, paginated, or parameterized
- the data includes secrets or sensitive operational detail
- the data is only meaningful as the result of an action with explicit user intent

Resources should stay small, read-only, and obviously useful as passive context.
Resources are optional — not every server needs them. Use for data that is
frequently referenced but doesn't change often.

---

## File-by-File Reference

### `.claude-plugin/plugin.json`

**The `userConfig` block is the canonical source of truth for all plugin configuration.**
Every environment variable the Docker Compose service and MCP server need must be declared as a
`userConfig` field. There is no other mechanism for getting values into `.env` — `sync-env.sh`
reads exclusively from `CLAUDE_PLUGIN_OPTION_*` vars, which are populated exclusively from
`userConfig`. If a required env var is not in `userConfig`, it will never reach the container.

`userConfig` must cover at minimum:
- **MCP server URL** — so `.mcp.json` can connect (`sensitive: false`)
- **MCP bearer token** — so `.mcp.json` can authenticate (`sensitive: false`)
- **Service URL / host** — base URL of the proxied service (`sensitive: true`)
- **Service credentials** — API key, password, token, or whatever the service requires (`sensitive: true`)
- **Any other required env vars** — ports, log levels, feature flags (`sensitive` as appropriate)

All four fields (`name`, `type`, `title`, `description`) are required by the validator on every
`userConfig` entry. `type` and `title` are not in official docs but the validator enforces them.
Use all available metadata fields.

```json
{
  "name": "my-service-mcp",
  "version": "1.0.0",
  "description": "One-line description of what this plugin does.",
  "author": {
    "name": "Jacob Magar",
    "email": "jmagar@users.noreply.github.com"
  },
  "repository": "https://github.com/jmagar/my-service-mcp",
  "homepage": "https://github.com/jmagar/my-service-mcp",
  "license": "MIT",
  "keywords": ["my-service", "homelab", "mcp"],
  "userConfig": {
    "my_service_mcp_url": {
      "type": "string",
      "title": "My Service MCP Server URL",
      "description": "Full MCP endpoint URL including /mcp path (e.g. https://my-service-mcp.example.com/mcp).",
      "default": "http://localhost:9000/mcp",
      "sensitive": false
    },
    "my_service_mcp_token": {
      "type": "string",
      "title": "MCP Server Bearer Token",
      "description": "Bearer token for authenticating with the MCP server. Must match MY_SERVICE_MCP_TOKEN in .env. Generate with: openssl rand -hex 32",
      "sensitive": false
    },
    "my_service_url": {
      "type": "string",
      "title": "My Service URL",
      "description": "Base URL of your service, e.g. https://service.example.com. No trailing slash.",
      "sensitive": true
    },
    "my_service_api_key": {
      "type": "string",
      "title": "My Service API Key",
      "description": "API key. Found in Settings → API.",
      "sensitive": true
    }
  }
}
```

**`userConfig` field rules:**

| Field | Required | Notes |
|---|---|---|
| `type` | Yes | Always `"string"` — validator requires it, docs omit it |
| `title` | Yes | Shown in install UI — validator requires it, docs omit it |
| `description` | Yes | Help text at install prompt |
| `sensitive` | Yes | `true` = encrypted, accessible only as `$CLAUDE_PLUGIN_OPTION_*` in Bash, NOT as `${user_config.*}` in `.mcp.json` or skill content. `false` = available as both `$CLAUDE_PLUGIN_OPTION_*` and `${user_config.*}` (required for `.mcp.json` substitution) |
| `default` | Recommended | Pre-fills install prompt; only meaningful for non-sensitive fields |

**Env var mapping:** `my_service_api_key` → `$CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY`

---

### `.app.json`

Codex app/connector manifest at the plugin root. Points Codex at the MCP server and any
additional apps or connectors the plugin provides.

```json
{
  "apps": [
    {
      "name": "my-service-mcp",
      "type": "mcp",
      "config": "./.mcp.json"
    }
  ]
}
```

This file is optional for Claude Code (which reads `.mcp.json` directly) but required for
full Codex compatibility. Keep it at the plugin root alongside `.mcp.json`.

---

### `.mcp.json`

MCP server connection config. Supports four transport types:

| Type | Use when |
|------|----------|
| `http` | **Default.** Streamable-HTTP for production deployments |
| `sse` | Server-Sent Events (legacy, prefer `http`) |
| `stdio` | Local process via stdin/stdout (dev only) |
| `ws` | WebSocket for real-time streaming |

Our servers use `http` with bearer auth. Only non-sensitive `userConfig` values support
`${user_config.*}` substitution.

```json
{
  "mcpServers": {
    "my-service-mcp": {
      "type": "http",
      "url": "${user_config.my_service_mcp_url}",
      "headers": {
        "Authorization": "Bearer ${user_config.my_service_mcp_token}"
      }
    }
  }
}
```

> **Why `sensitive: false` for the MCP token?** `.mcp.json` only supports `${user_config.*}`
> substitution for non-sensitive fields. Since the `Authorization` header needs the token,
> it must be non-sensitive. This is safe because the token only grants access to the local
> MCP server — the real service credentials stay in `.env` at `chmod 600`.

### Threat model and trust boundaries

Treat the MCP bearer token and the upstream service credential as **different trust domains**:

- `MY_SERVICE_MCP_TOKEN`
  - Grants access only to the plugin's MCP HTTP endpoint
  - Does **not** directly authenticate to the upstream service
  - Is acceptable as `sensitive: false` because `.mcp.json` must interpolate it into the
    `Authorization` header for local tool calls
- `MY_SERVICE_API_KEY` / service credentials
  - Grant direct access to the upstream service or API
  - Must remain `sensitive: true`
  - Must never appear in `.mcp.json`, skill text, logs, or generated examples

The trust boundary is the MCP server itself. Claude Code authenticates to the MCP server with
`MY_SERVICE_MCP_TOKEN`; the MCP server then uses the upstream credential from `.env` to call the
real service. This separation limits blast radius: exposing the MCP token is materially less severe
than exposing the upstream service credential.

---

### `hooks/hooks.json`

The wrapper object with `"description"` and `"hooks"` is required. Bare arrays are rejected.

```json
{
  "description": "Sync userConfig credentials to .env, enforce 600 permissions, ensure gitignore",
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/sync-env.sh",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/ensure-ignore-files.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/fix-env-perms.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

`${CLAUDE_PLUGIN_ROOT}` — set by Claude Code to the repo root. Reliable in hook scripts only.

---

### `hooks/scripts/sync-env.sh`

Runs at `SessionStart`. Maps `CLAUDE_PLUGIN_OPTION_*` → `.env` keys. Fails if bearer token
is not set (no auto-generation — avoids token mismatch with userConfig). Uses `flock` to
prevent concurrent session races. Uses `awk` for value replacement (not `sed` — avoids
pipe-delimiter injection on values containing `|`). Keeps max 3 backups, all chmod 600.

```bash
#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${CLAUDE_PLUGIN_ROOT}/.env"
BACKUP_DIR="${CLAUDE_PLUGIN_ROOT}/backups"
LOCK_FILE="${CLAUDE_PLUGIN_ROOT}/.env.lock"
mkdir -p "$BACKUP_DIR"

# Serialize concurrent sessions (two tabs starting at the same time)
exec 9>"$LOCK_FILE"
flock -w 10 9 || { echo "sync-env: failed to acquire lock after 10s" >&2; exit 1; }

declare -A MANAGED=(
  [MY_SERVICE_URL]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL:-}"
  [MY_SERVICE_API_KEY]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY:-}"
  [MY_SERVICE_MCP_URL]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_MCP_URL:-}"
  [MY_SERVICE_MCP_TOKEN]="${CLAUDE_PLUGIN_OPTION_MY_SERVICE_MCP_TOKEN:-}"
)

touch "$ENV_FILE"

# Backup before writing (max 3 retained)
if [ -s "$ENV_FILE" ]; then
  cp "$ENV_FILE" "${BACKUP_DIR}/.env.bak.$(date +%s)"
fi

# Write managed keys — awk handles arbitrary values safely (no delimiter injection)
for key in "${!MANAGED[@]}"; do
  value="${MANAGED[$key]}"
  [ -z "$value" ] && continue
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    awk -v k="$key" -v v="$value" '$0 ~ "^"k"=" { print k"="v; next } { print }' \
      "$ENV_FILE" > "${ENV_FILE}.tmp" && mv "${ENV_FILE}.tmp" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
done

# Fail if bearer token is not set — do NOT auto-generate.
# Auto-generated tokens cause a mismatch: the server reads the generated token
# but Claude Code sends the (empty) userConfig value. Every MCP call returns 401.
if ! grep -q "^MY_SERVICE_MCP_TOKEN=.\+" "$ENV_FILE" 2>/dev/null; then
  echo "sync-env: ERROR — MY_SERVICE_MCP_TOKEN is not set." >&2
  echo "  Generate one:  openssl rand -hex 32" >&2
  echo "  Then paste it into the plugin's userConfig MCP token field." >&2
  exit 1
fi

chmod 600 "$ENV_FILE"

# Prune old backups
mapfile -t baks < <(ls -t "${BACKUP_DIR}"/.env.bak.* 2>/dev/null)
for bak in "${baks[@]}"; do chmod 600 "$bak"; done
for bak in "${baks[@]:3}"; do rm -f "$bak"; done
```

**Key rules:**
- Map each userConfig key → the `.env` key Docker Compose and the server read
- Skip empty values — avoids clobbering existing `.env` when a field isn't filled in
- **Fail if `MY_SERVICE_MCP_TOKEN` is empty** — auto-generation causes a token mismatch (server has one token, client sends another → silent 401). Require the user to generate and paste the token into userConfig.
- Use `awk` for replacement, not `sed` — values containing `|`, `&`, `/`, or `\` are handled safely
- Use `flock` to serialize concurrent sessions — prevents `.env` corruption when two tabs start simultaneously
- Backup before every write, prune to 3 most recent, chmod 600 on all

---

### `hooks/scripts/fix-env-perms.sh`

Identical across all plugins. Re-enforces chmod 600 on `.env` and backups unconditionally
whenever any file-touching tool runs. The PostToolUse matcher (`Write|Edit|MultiEdit|Bash`)
already scopes this to relevant tools — no need to parse stdin or match `.env` in the command
string (which can be bypassed via variable indirection).

```bash
#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${CLAUDE_PLUGIN_ROOT}/.env"
[ -f "$ENV_FILE" ] || exit 0

# Read and discard stdin (PostToolUse hooks receive JSON on stdin)
cat > /dev/null

# Unconditionally enforce permissions — the PostToolUse matcher already limits
# this to Write|Edit|MultiEdit|Bash. Checking whether the command string
# contains ".env" is a heuristic that misses variable-based paths like:
#   f=".env"; echo "KEY=val" >> "$f"
chmod 600 "$ENV_FILE"
for bak in "${CLAUDE_PLUGIN_ROOT}/backups"/.env.bak.*; do
  [ -f "$bak" ] && chmod 600 "$bak"
done
```

---

### `hooks/scripts/ensure-ignore-files.sh`

Identical across all plugins. Handles both `.gitignore` and `.dockerignore` in one script.
Runs at `SessionStart` to ensure required patterns exist.

**Two modes:**
- **Default** (no flags): appends missing patterns silently — used as a SessionStart hook
- **`--check`**: reports pass/fail for every pattern, exits non-zero on failures — used in pre-commit and CI

```bash
# As a SessionStart hook (auto-fix mode):
ensure-ignore-files.sh

# As a pre-commit check (report-only mode):
ensure-ignore-files.sh --check .
```

**`.gitignore` patterns enforced** (27 patterns):
- Secrets: `.env`, `.env.*`, `!.env.example`
- Runtime: `backups/*`, `!backups/.gitkeep`, `logs/*`, `!logs/.gitkeep`, `*.log`
- AI tooling: `.claude/settings.local.json`, `.claude/worktrees/`, `.omc/`, `.lavra/`, `.beads/`, `.serena/`, `.worktrees`, `.full-review/`, `.full-review-archive-*`
- IDE: `.vscode/`, `.cursor/`, `.windsurf/`, `.1code/`
- Caches: `.cache/`
- Docs: `docs/plans/`, `docs/sessions/`, `docs/reports/`, `docs/research/`, `docs/superpowers/`

**`.dockerignore` patterns enforced** (28 patterns):
- VCS: `.git`, `.github`
- Secrets: `.env`, `.env.*`, `!.env.example`
- AI tooling: `.claude`, `.claude-plugin`, `.codex-plugin`, `.omc`, `.lavra`, `.beads`, `.serena`, `.worktrees`, `.full-review`, `.full-review-archive-*`
- IDE: `.vscode`, `.cursor`, `.windsurf`, `.1code`
- Not needed at runtime: `docs`, `tests`, `scripts`, `*.md`, `!README.md`
- Runtime artifacts: `logs`, `backups`, `*.log`, `.cache`

In `--check` mode, the script also detects the project language (Python/TS/Rust) and warns
if language-specific patterns are not uncommented.

Why `!.env.example`: the `.env.*` glob silently gitignores `.env.example` on fresh clones without it.

---

### `skills/<service>/SKILL.md`

**Every plugin must include a skill.** The skill is the bridge between Claude and the MCP
server — it documents all available actions, their parameters, and expected outputs. Without
it, Claude has no context on how to use the tools effectively.

Skills are **dual-mode**: MCP preferred, HTTP/script fallback. If the MCP server is running,
Claude uses the MCP tools. If not, the skill provides curl/script examples as a fallback so
the plugin remains functional without the server.

**Writing style requirements:**
- `description` must use **third person**: "This skill should be used when..." (not "Use when..." or "Activate when...")
- SKILL.md body must use **imperative/infinitive form** (verb-first instructions, not second person)
- Include specific trigger phrases users would say
- Target **1,500–2,000 words** for the body — move detailed content to `references/`

```markdown
---
name: my-service
description: This skill should be used when the user asks to "list resources", "get resource",
  "create X", "delete X", "check status", or mentions My Service or its domain keywords.
---

# My Service Skill

## Mode Detection

**MCP mode** (preferred): Use when `mcp__my-service-mcp__my_service` tool is available.

**HTTP fallback**: Use when MCP tools are unavailable. Credentials are in Bash subprocesses
as `$CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL` and `$CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY`.
Do NOT attempt `${user_config.my_service_api_key}` in curl — sensitive values only work
as `$CLAUDE_PLUGIN_OPTION_*` in Bash subprocesses.

**MCP URL**: `${user_config.my_service_mcp_url}`

---

## MCP Mode — Tool Reference

Single tool: `mcp__my-service-mcp__my_service` with `action` parameter.

### List resources
\`\`\`
mcp__my-service-mcp__my_service
  action: "list"
\`\`\`

### Get resource
\`\`\`
mcp__my-service-mcp__my_service
  action: "get"
  id:     (required) Resource ID
\`\`\`

### Create resource
\`\`\`
mcp__my-service-mcp__my_service
  action: "create"
  name:   (required) Resource name
  config: (optional) Configuration dict
\`\`\`

### Update resource
\`\`\`
mcp__my-service-mcp__my_service
  action:    "update"
  id:        (required) Resource ID
  subaction: (optional) "enable" | "disable" | "reload"
  config:    (optional) New configuration
\`\`\`

### Delete resource — DESTRUCTIVE
\`\`\`
mcp__my-service-mcp__my_service
  action: "delete"
  id:     (required) Resource ID
\`\`\`
Always confirm with user before executing.

---

## HTTP Fallback Mode

\`\`\`bash
# List
curl -s "$CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL/api/v1/resources" \
  -H "X-Api-Key: $CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY"

# Create
curl -s -X POST "$CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL/api/v1/resources" \
  -H "X-Api-Key: $CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$NAME\"}"
\`\`\`
```

---

### `agents/<agent-name>.md`

Agents are autonomous subprocesses for complex multi-step tasks. Optional — only create
if the plugin needs specialized autonomous workflows.

```markdown
---
name: my-service-analyzer
description: Use this agent when the user asks to "analyze my-service performance",
  "diagnose my-service issues", or needs deep investigation of service metrics.

<example>
Context: User wants to investigate service issues
user: "Why is my-service responding slowly?"
assistant: "I'll use the my-service-analyzer agent to investigate."
<commentary>
Performance investigation requires multi-step analysis across logs, metrics, and config.
</commentary>
</example>

model: inherit
color: blue
tools: ["Read", "Grep", "Bash"]
---

You are a specialized analyst for My Service.

**Core Responsibilities:**
1. Gather metrics and logs from the service
2. Identify performance bottlenecks or errors
3. Provide actionable recommendations

**Process:**
1. Check service health via MCP tools
2. Review recent logs for errors
3. Analyze response times and resource usage
4. Report findings with specific remediation steps
```

**Required frontmatter fields:**
- `name` — lowercase, hyphens, 3–50 chars
- `description` — triggering conditions with `<example>` blocks (2–4 examples)
- `model` — `inherit` (recommended), `sonnet`, `opus`, or `haiku`
- `color` — `blue`, `cyan`, `green`, `yellow`, `magenta`, or `red`
- `tools` — (optional) restrict to specific tools; omit for full access

---

### `commands/<command>.md`

Slash commands are reusable prompts invoked as `/plugin-name:command-name`. Optional —
only create for frequently-used operations.

```markdown
---
description: Check service health and show status summary
allowed-tools: Bash(curl:*), mcp__my-service-mcp__my_service
argument-hint: [--verbose]
---

Check the health of My Service and provide a summary.

## Instructions

1. Call the my_service tool with action "health"
2. If $ARGUMENTS contains "--verbose", also call action "logs" with limit 20
3. Format results as a concise status report
```

**Frontmatter fields:**
- `description` — shown in `/help` autocomplete (under 60 chars)
- `allowed-tools` — pre-approved tools (no permission prompts)
- `argument-hint` — documents expected arguments
- `model` — (optional) `sonnet`, `opus`, or `haiku`

**Key rules:**
- Commands are instructions **for Claude**, not messages to the user
- `$ARGUMENTS` is replaced with user input after the command
- `` !`command` `` runs a shell command and injects its output as context

---

### `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`

`CLAUDE.md` is the **canonical AI memory file** — project context, conventions, and instructions
that AI coding assistants read at session start. Every plugin repo must have one.

To support all three major AI CLI tools (Claude Code, OpenAI Codex CLI, Google Gemini CLI)
without maintaining three separate files, create symlinks:

```bash
ln -sf CLAUDE.md AGENTS.md    # Codex CLI reads AGENTS.md
ln -sf CLAUDE.md GEMINI.md    # Gemini CLI reads GEMINI.md
```

**Both symlinks are committed to git.** Only edit `CLAUDE.md` — the symlinks follow automatically.

---

### `.gitignore`

Required patterns in every plugin repo. Copy this baseline and uncomment your language section.

```
# ── Secrets ──────────────────────────────────────────────────────────────────
.env
.env.*
!.env.example

# ── Runtime / hook artifacts ─────────────────────────────────────────────────
backups/*
!backups/.gitkeep
logs/*
!logs/.gitkeep
*.log

# ── Claude Code / AI tooling ────────────────────────────────────────────────
.claude/settings.local.json
.claude/worktrees/
.omc/
.lavra/memory/session-state.md
.beads/
.serena/
.worktrees
.full-review/
.full-review-archive-*

# ── IDE / editor ─────────────────────────────────────────────────────────────
.vscode/
.cursor/
.windsurf/
.1code/

# ── Caches (ALL tool artifacts go here — see .cache Convention) ──────────────
.cache/

# ── Documentation artifacts (gitignore session/plan docs, keep reference) ───
docs/plans/
docs/sessions/
docs/reports/
docs/research/
docs/superpowers/

# ── Python (uncomment if applicable) ────────────────────────────────────────
# .venv/
# __pycache__/
# *.py[oc]
# *.egg-info/
# *.egg
# dist/
# build/
# sdist/
# wheels/
# .hypothesis/
# .pytest_cache/
# .ruff_cache/
# .ty_cache/
# .mypy_cache/
# .pytype/
# .pyre/
# .pyright/
# htmlcov/
# .coverage
# .coverage.*
# coverage.xml
# .tox/
# .nox/
# pip-log.txt
# pip-wheel-metadata/
# *.whl

# ── Node/TypeScript (uncomment if applicable) ────────────────────────────────
# node_modules/
# dist/
# build/
# out/
# .next/
# .nuxt/
# coverage/
# .nyc_output/
# *.tsbuildinfo
# .eslintcache
# .stylelintcache
# .parcel-cache/
# .turbo/
# .vercel/
# *.js.map
# *.d.ts.map

# ── Rust (uncomment if applicable) ───────────────────────────────────────────
# target/
# *.db
# **/*.rs.bk
# Cargo.lock  # uncomment for libraries only, keep for binaries

# ── Go (uncomment if applicable) ─────────────────────────────────────────────
# bin/
# vendor/
# *.exe
# *.test
# *.out
# cover.out
# cover.html
# *.prof
# go.work
```

The `ensure-ignore-files.sh` hook enforces all required `.gitignore` and `.dockerignore` patterns
automatically at runtime, but these must be present from the initial commit.

---

### `.env.example`

Tracked in git. All keys with placeholder values — no real credentials.

```bash
# ── Service credentials (synced from Claude Code userConfig at SessionStart) ──
MY_SERVICE_URL=https://your-service.example.com
MY_SERVICE_API_KEY=your_api_key_here

# ── MCP server ───────────────────────────────────────────────────────────────
MY_SERVICE_MCP_HOST=0.0.0.0
MY_SERVICE_MCP_PORT=9000
MY_SERVICE_MCP_TRANSPORT=http          # "http" (default) or "stdio"
MY_SERVICE_MCP_TOKEN=                  # required — generate with: openssl rand -hex 32
MY_SERVICE_MCP_NO_AUTH=false           # true = disable bearer auth (proxy-managed only)
MY_SERVICE_MCP_LOG_LEVEL=INFO

# ── Destructive operation safety ─────────────────────────────────────────────
MY_SERVICE_MCP_ALLOW_YOLO=false        # true = skip elicitation prompts
MY_SERVICE_MCP_ALLOW_DESTRUCTIVE=false # true = auto-confirm all destructive ops

# ── Docker ───────────────────────────────────────────────────────────────────
PUID=1000
PGID=1000
DOCKER_NETWORK=my-service_mcp
```

---

### Plugin Settings (`.claude/<plugin-name>.local.md`) — optional

**Advanced pattern.** Most plugins don't need this — `userConfig` in `plugin.json` handles
standard configuration. Use this only when the plugin needs per-project settings that vary
independently of the install-time `userConfig` (e.g., agent state, feature flags, project-specific
overrides).

Plugins can store **per-project user configuration** in `.claude/<plugin-name>.local.md`.
This file uses YAML frontmatter for structured settings and a markdown body for additional
context. It is gitignored — each user has their own.

```markdown
---
enabled: true
strict_mode: false
allow_destructive: false
log_level: info
---

# My Service Plugin Configuration

Plugin is configured for standard mode.
```

**Reading settings from hooks:**

```bash
#!/bin/bash
set -euo pipefail

STATE_FILE=".claude/my-service-mcp.local.md"

# Quick exit if not configured
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Parse YAML frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")
ENABLED=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//')

if [[ "$ENABLED" != "true" ]]; then
  exit 0
fi
```

**Rules:**
- File location: `.claude/<plugin-name>.local.md` (must match plugin name)
- Must be in `.gitignore` (add `.claude/*.local.md`)
- Settings changes require Claude Code restart
- Provide sensible defaults when file doesn't exist

---

### `.dockerignore`

Keeps the build context small and prevents secrets from leaking into the image.
Copy this baseline and uncomment the section for your language.

```
# ── Version control ──────────────────────────────────────────────────────────
.git
.github

# ── Secrets ──────────────────────────────────────────────────────────────────
.env
.env.*
!.env.example

# ── Claude Code / AI tooling ────────────────────────────────────────────────
.claude
.claude-plugin
.omc
.lavra
.beads
.serena
.worktrees
.full-review
.full-review-archive-*

# ── IDE / editor ─────────────────────────────────────────────────────────────
.vscode
.cursor
.windsurf
.1code

# ── Docs, tests, scripts (not needed at runtime) ────────────────────────────
docs
tests
scripts
*.md
!README.md

# ── Runtime artifacts ────────────────────────────────────────────────────────
logs
backups
*.log
.cache

# ── Python (uncomment if applicable) ────────────────────────────────────────
# .venv
# __pycache__/
# *.py[oc]
# *.egg-info
# dist/
# .hypothesis/
# .pytest_cache/
# .ruff_cache/
# .ty_cache/
# htmlcov/
# .coverage
# coverage.xml

# ── Node/TypeScript (uncomment if applicable) ────────────────────────────────
# node_modules/
# dist/
# coverage/
# .husky/
# .nvmrc
# .prettierrc
# .prettierignore
# biome.json
# tsconfig*.json
# vitest.config.*
# pnpm-lock.yaml
# package-lock.json

# ── Rust (uncomment if applicable) ───────────────────────────────────────────
# target/
# Cargo.lock
```

---

### `Justfile`

Every plugin **must** include a `Justfile` with standard recipes. This provides a consistent
interface across all plugins regardless of language.

```just
# Default recipe — show available commands
default:
    @just --list

# ── Development ──────────────────────────────────────────────────────────────

# Start the MCP server in dev mode
dev:
    # Python: uv run python -m my_service_mcp.server
    # TypeScript: npm run dev
    # Rust: cargo run

# Run tests
test:
    # Python: uv run pytest
    # TypeScript: npx vitest run
    # Rust: cargo test

# Run linter
lint:
    # Python: uv run ruff check . && uv run ty check
    # TypeScript: npx biome check .
    # Rust: cargo clippy -- -D warnings

# Format code
fmt:
    # Python: uv run ruff format .
    # TypeScript: npx biome format --write .
    # Rust: cargo fmt

# Type check (Python/TypeScript only)
typecheck:
    # Python: uv run ty check
    # TypeScript: npx tsc --noEmit

# Validate skills
validate-skills:
    npx skills-ref validate skills/

# ── Docker ───────────────────────────────────────────────────────────────────

# Build the Docker image
build:
    docker compose build

# Start the service
up:
    docker compose up -d

# Stop the service
down:
    docker compose down

# Restart the service
restart:
    docker compose restart

# View logs
logs *args='':
    docker compose logs -f {{ args }}

# ── Health & Testing ─────────────────────────────────────────────────────────

# Check service health
health:
    @curl -sf http://localhost:${MY_SERVICE_MCP_PORT:-9000}/health | jq . || echo "UNHEALTHY"

# Run live integration tests (requires running server)
test-live:
    bash tests/test_live.sh

# ── Setup ────────────────────────────────────────────────────────────────────

# Create .env from .env.example if missing
setup:
    @[ -f .env ] || cp .env.example .env && chmod 600 .env && echo "Created .env from .env.example"

# Generate a bearer token
gen-token:
    @openssl rand -hex 32

# ── Cleanup ──────────────────────────────────────────────────────────────────

# Remove build artifacts and caches
clean:
    rm -rf .cache/ dist/ build/ target/ node_modules/.cache/
    # Python: rm -rf __pycache__/ *.egg-info/
    # TypeScript: rm -rf dist/
    # Rust: cargo clean
```

Uncomment the lines for your language and remove the others. The recipe names are
standardized — `just dev`, `just test`, `just lint`, `just build`, `just up` work
the same across all plugins.

---

### `entrypoint.sh`

Container entrypoint script that validates environment before starting the server.
The Dockerfile's `CMD` should point here, not directly at the server binary.

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "my-service-mcp: initializing..."

# Validate required env vars
if [ -z "${MY_SERVICE_URL:-}" ]; then
    echo "Error: MY_SERVICE_URL is required" >&2
    exit 1
fi

if [ -z "${MY_SERVICE_API_KEY:-}" ]; then
    echo "Warning: MY_SERVICE_API_KEY not set — some functionality may be limited" >&2
fi

# Set defaults
export MY_SERVICE_MCP_HOST="${MY_SERVICE_MCP_HOST:-0.0.0.0}"
export MY_SERVICE_MCP_PORT="${MY_SERVICE_MCP_PORT:-9000}"
export MY_SERVICE_MCP_TRANSPORT="${MY_SERVICE_MCP_TRANSPORT:-http}"

echo "my-service-mcp: starting server (${MY_SERVICE_MCP_TRANSPORT} on ${MY_SERVICE_MCP_HOST}:${MY_SERVICE_MCP_PORT})"

# Python
exec python3 -m my_service_mcp.server
# TypeScript
# exec node dist/index.js
# Rust
# exec my-service-mcp
```

**Rules:**
- Use `exec` to replace the shell process (proper signal handling)
- Validate required vars, warn on optional missing vars
- Never log credentials — only log config shape
- `set -euo pipefail` for strict mode
- Must be `chmod +x` in the Dockerfile

---

### `Dockerfile`

Multi-stage build with a non-root user. Adapt the base images and build commands for your
language (Python/uv, Node/pnpm, Rust/cargo, Go, etc.).

**Required patterns** (language-agnostic):

```dockerfile
# syntax=docker/dockerfile:1

# ── Build stage ─────────────────────────────────────────────────────────────────
FROM <language-base> AS builder
WORKDIR /app
# 1. Copy dependency manifest first (cache layer)
# 2. Install dependencies
# 3. Copy source and build

# ── Runtime stage ───────────────────────────────────────────────────────────────
FROM <slim-runtime-base> AS runtime
WORKDIR /app
COPY --from=builder /app/<build-output> /app/

# Non-root user
RUN mkdir -p /app/logs /app/backups

EXPOSE 9000

# Healthcheck — use wget (available in most slim images)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q --spider http://localhost:9000/health || exit 1

ENTRYPOINT ["my-service-mcp-server"]
```

**Mandatory Dockerfile rules:**
- Multi-stage build — separate build and runtime stages to minimize image size
- Non-root user — never run the server as root
- `EXPOSE` the default port from `.env.example`
- `HEALTHCHECK` hitting `/health` — same endpoint the compose healthcheck uses
- Dependency manifest copied before source — leverages Docker layer caching

#### Python (uv)

```dockerfile
FROM python:3.13-slim AS builder
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev
COPY . .

FROM python:3.13-slim AS runtime
WORKDIR /app
COPY --from=builder /app /app
ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 9000
CMD ["python", "-m", "my_service_mcp.server"]
```

#### TypeScript (Node)

```dockerfile
FROM node:24-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

FROM node:24-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=builder /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

#### Rust (cargo)

```dockerfile
FROM rust:1.86-slim-bookworm AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs && cargo build --release && rm -rf src
COPY src/ src/
RUN touch src/main.rs && cargo build --release

FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y ca-certificates wget && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/my-service-mcp /usr/local/bin/my-service-mcp
RUN groupadd --gid 1000 app && useradd --uid 1000 --gid app --no-create-home --shell /sbin/nologin app \
    && mkdir -p /data && chown app:app /data
USER 1000:1000
EXPOSE 3100
ENTRYPOINT ["my-service-mcp"]
```

---

### `docker-compose.yaml`

**All configuration comes from `.env` via `env_file:` only — no `environment:` block.**
Do not duplicate env vars in `docker-compose.yaml`. Every variable the container needs must
be in `.env` and `.env.example`. This gives one place to manage all configuration and prevents
drift between the compose file and the env file.

```yaml
services:
  my-service-mcp:
    build: .
    container_name: my-service-mcp
    restart: unless-stopped
    user: "${PUID:-1000}:${PGID:-1000}"
    env_file: .env
    # NOTE: No environment: block — all vars come from .env via env_file above.
    # Do NOT add environment: here. Put all variables in .env and .env.example.
    ports:
      - "${MY_SERVICE_MCP_PORT:-9000}:9000/tcp"
    volumes:
      - ${MY_SERVICE_MCP_VOLUME:-my-service-mcp-data}:/data
    networks:
      - proxy
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:9000/health || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '1.0'

volumes:
  my-service-mcp-data:

networks:
  proxy:
    name: ${DOCKER_NETWORK:-my-service_mcp}
    external: true
```

**Key patterns:**
- `user: "${PUID}:${PGID}"` — file ownership matches host user (defaults to 1000:1000), never root
- `env_file: .env` — **sole source of config**. No `environment:` block allowed — all variables in `.env` only
- Single named volume — `${MY_SERVICE_MCP_VOLUME:-default}` mounted at `/data`; server writes logs, cache, etc. as subdirectories
- No `backups/` mount — backups are host-side only (written by `sync-env.sh` hooks, not the container)
- External network — integrates with reverse proxy (SWAG, Traefik, Caddy)
- Resource limits — prevents runaway memory/CPU
- `wget` healthcheck — lighter than language-specific alternatives, available in most slim images

---

### SWAG Reverse Proxy Config

Every MCP server **must** ship a SWAG-compatible nginx reverse proxy config.
Place it at `<service>.subdomain.conf` in the repo root. The filename uses
the **service name without `-mcp`** — e.g., `gotify.subdomain.conf`, not `gotify-mcp.subdomain.conf`.

This is a **real, functional nginx config** — not a Jinja template. Replace the placeholder
values with the actual Tailscale IPs, ports, and domain for your service.

This config handles MCP Streamable-HTTP proxying with OAuth 2.1, origin validation,
health checks, and session management.

```nginx
## Version 2026/03/30 - MCP 2025-11-25 SWAG Compatible
# MCP Streamable-HTTP Reverse Proxy
# Service: gotify
# Domain: gotify.example.com
# Upstream: http://100.64.0.5:8080

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name gotify.example.com;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    # Service UI upstream (Tailscale IP of the host running the service)
    set $upstream_app "100.64.0.5";
    set $upstream_port "8080";
    set $upstream_proto "http";

    # MCP server upstream (may be same host, different port)
    set $mcp_upstream_app "100.64.0.5";
    set $mcp_upstream_port "9000";
    set $mcp_upstream_proto "http";

    # DNS rebinding protection
    set $origin_valid 0;
    if ($http_origin = "") { set $origin_valid 1; }
    if ($http_origin = "https://$server_name") { set $origin_valid 1; }
    if ($http_origin ~ "^https://(localhost|127\.0\.0\.1)(:[0-9]+)?$") { set $origin_valid 1; }
    if ($http_origin ~ "^https://(.*\.)?anthropic\.com$") { set $origin_valid 1; }
    if ($http_origin ~ "^https://(.*\.)?claude\.ai$") { set $origin_valid 1; }

    add_header X-MCP-Version "2025-11-25" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Uncomment for auth provider (authelia, authentik, etc.)
    # include /config/nginx/authelia-server.conf;

    # OAuth 2.1: /_oauth_verify, /.well-known/*, /jwks, /register,
    #            /authorize, /token, /revoke, /callback, /success, error pages
    include /config/nginx/oauth.conf;

    location /mcp {
        if ($origin_valid = 0) {
            add_header Content-Type "application/json" always;
            return 403 '{"error":"origin_not_allowed","message":"Origin header validation failed"}';
        }

        auth_request /_oauth_verify;
        auth_request_set $auth_status $upstream_status;

        include /config/nginx/resolver.conf;
        include /config/nginx/proxy.conf;
        include /config/nginx/mcp.conf;

        proxy_pass $mcp_upstream_proto://$mcp_upstream_app:$mcp_upstream_port;
    }

    location /health {
        include /config/nginx/resolver.conf;

        proxy_set_header Accept "application/json";
        proxy_set_header X-Health-Check "nginx-mcp-proxy";

        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;

        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;

        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }

    location ~* ^/(session|sessions) {
        auth_request /_oauth_verify;
        auth_request_set $auth_status $upstream_status;

        include /config/nginx/resolver.conf;
        include /config/nginx/proxy.conf;

        proxy_set_header MCP-Protocol-Version $http_mcp_protocol_version;
        proxy_set_header Mcp-Session-Id $http_mcp_session_id;

        add_header Cache-Control "no-store" always;
        add_header Pragma "no-cache" always;

        proxy_pass $mcp_upstream_proto://$mcp_upstream_app:$mcp_upstream_port;
    }

    location / {
        # Uncomment for auth provider
        # include /config/nginx/authelia-location.conf;

        include /config/nginx/resolver.conf;
        include /config/nginx/proxy.conf;

        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}
```

#### What to customize

| Value to replace | Example | Description |
|------------------|---------|-------------|
| `server_name` | `gotify.example.com` | Your FQDN (no `-mcp` suffix) |
| `$upstream_app` | `100.64.0.5` | Tailscale IP of the host running the service |
| `$upstream_port` | `8080` | Service UI port |
| `$mcp_upstream_app` | `100.64.0.5` | Tailscale IP of the host running the MCP server |
| `$mcp_upstream_port` | `9000` | MCP server port |
| Auth includes | `authelia-server.conf` | Uncomment and set to your auth provider |

#### Key design decisions

- **Tailscale IPs for upstreams** — use the device's Tailscale IP (e.g., `100.64.0.5`) instead of Docker container names, since SWAG proxies to services across the tailnet
- **Separate upstream vars** for the service UI vs MCP server — they may run on different ports or hosts
- **Origin validation** — only allows requests from the service domain, localhost, and Anthropic/Claude origins
- **`/mcp` endpoint** — OAuth-protected, includes `mcp.conf` for SSE/streaming headers
- **`/health` endpoint** — unauthenticated, short timeouts, no caching
- **`/session*` endpoints** — OAuth-protected, forwards MCP protocol headers
- **`/` catch-all** — proxies to the service UI with optional auth

---

## Codex CLI Compatibility

Every plugin **must** create both Claude Code and Codex plugins. Both CLIs must be supported
from a single repo. This is not optional — dual-CLI support is a hard requirement.

### Plugin structure mapping

Codex plugins use `.codex-plugin/` instead of `.claude-plugin/`. The repo ships both manifests
plus Codex-specific files (`.app.json`, `assets/`):

```
my-service-mcp/
├── .claude-plugin/
│   └── plugin.json           # Claude Code manifest
├── .codex-plugin/
│   └── plugin.json           # Codex manifest (see schema below)
├── .app.json                 # Codex app/connector manifest (points to apps or connectors)
├── .mcp.json                 # MCP server connection config (shared by both CLIs)
├── assets/                   # Plugin visual assets for Codex install surfaces
│   ├── icon.png              # Plugin icon (512x512 recommended)
│   ├── logo.svg              # Plugin logo
│   └── screenshots/          # Install-surface screenshots
├── CLAUDE.md                 # Canonical AI instructions
├── AGENTS.md -> CLAUDE.md    # Codex reads this
├── GEMINI.md -> CLAUDE.md    # Gemini CLI reads this
└── skills/                   # Shared — both CLIs discover skills here
    └── <service>/
        └── SKILL.md
```

> **Note:** The `assets/` directory at the plugin root is for Codex install-surface visuals
> (icons, logos, screenshots). Do **not** confuse this with skill-level assets. Skills have
> their own `assets/` if needed (e.g., `skills/<service>/assets/`).

### Codex plugin.json

The Codex manifest lives at `.codex-plugin/plugin.json`. It supports richer metadata than
Claude Code's manifest, including install-surface presentation fields:

```json
{
  "name": "my-service-mcp",
  "version": "1.0.0",
  "description": "Manage My Service via MCP tools",
  "skills": "./skills/",
  "mcpServers": "./.mcp.json",
  "apps": "./.app.json",
  "author": {
    "name": "Jacob Magar",
    "email": "jmagar@users.noreply.github.com"
  },
  "homepage": "https://github.com/jmagar/my-service-mcp",
  "repository": "https://github.com/jmagar/my-service-mcp",
  "license": "MIT",
  "keywords": ["my-service", "homelab", "mcp"],
  "interface": {
    "displayName": "My Service MCP",
    "shortDescription": "Manage My Service resources via MCP tools",
    "longDescription": "Full MCP integration for My Service with action+subaction pattern, destructive operation gating, and dual-mode skill support.",
    "developerName": "Jacob Magar",
    "category": "Infrastructure",
    "capabilities": ["mcp", "tools", "skills"],
    "brandColor": "#4A90D9",
    "composerIcon": "./assets/icon.png",
    "logo": "./assets/logo.svg",
    "screenshots": ["./assets/screenshots/overview.png"]
  }
}
```

**Manifest field reference:**

| Field | Purpose |
|---|---|
| `name`, `version`, `description` | Package identity |
| `author`, `homepage`, `repository`, `license`, `keywords` | Publisher and discovery metadata |
| `skills` | Points to bundled skill folders (relative to plugin root) |
| `mcpServers` | Points to `.mcp.json` for MCP server config |
| `apps` | Points to `.app.json` for app/connector definitions |
| `interface.displayName` | Title shown on install surfaces |
| `interface.shortDescription` / `longDescription` | Descriptive copy for install UI |
| `interface.developerName` | Publisher name |
| `interface.category` | Plugin category (e.g., Infrastructure, Media, Utilities) |
| `interface.capabilities` | Capability tags |
| `interface.brandColor` | Brand color for visual presentation |
| `interface.composerIcon` / `logo` | Icon and logo paths (relative, under `./assets/`) |
| `interface.screenshots` | Screenshot paths for install surface |
| `interface.websiteURL` / `privacyPolicyURL` / `termsOfServiceURL` | External links (optional) |
| `interface.defaultPrompt` | Starter prompt shown after install (optional) |

**Path rules:**
- Keep all manifest paths relative to the plugin root, starting with `./`
- Store visual assets under `./assets/`
- Only `plugin.json` belongs in `.codex-plugin/` — keep `skills/`, `assets/`, `.mcp.json`,
  and `.app.json` at the plugin root

Key differences from Claude Code's `plugin.json`:
- `skills` field explicitly points to the skills directory (Claude Code auto-discovers)
- `interface` object controls install-surface presentation (not in Claude Code)
- `apps` field for `.app.json` connector definitions
- No `userConfig` — Codex uses `AGENTS.md` and env vars for configuration

### `.app.json`

The `.app.json` file at the plugin root points Codex at apps or connectors. For MCP-server
plugins this is typically minimal:

```json
{
  "apps": [
    {
      "name": "my-service-mcp",
      "type": "mcp",
      "config": "./.mcp.json"
    }
  ]
}
```

If your plugin doesn't expose apps or connectors beyond the MCP server, this file can be
omitted — but including it makes the plugin discoverable in Codex's app catalog.

### Codex marketplace

A marketplace file controls plugin ordering and install policies in Codex-facing catalogs.
It can represent one plugin while testing or a curated list of plugins that Codex shows
together under one marketplace name.

Codex supports two marketplace locations:

| Scope | Path |
|-------|------|
| Per-repo | `$REPO_ROOT/.agents/plugins/marketplace.json` |
| Personal | `~/.agents/plugins/marketplace.json` |

```json
{
  "name": "homelab-plugins",
  "interface": {
    "displayName": "Homelab Plugins"
  },
  "plugins": [
    {
      "name": "my-service-mcp",
      "source": {
        "source": "local",
        "path": "./plugins/my-service-mcp"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Infrastructure"
    },
    {
      "name": "another-service-mcp",
      "source": {
        "source": "local",
        "path": "./plugins/another-service-mcp"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Media"
    }
  ]
}
```

**Marketplace rules:**
- Use top-level `name` to identify the marketplace
- Use `interface.displayName` for the marketplace title shown in Codex
- Add one object per plugin under `plugins` to build a curated list
- Point each plugin entry's `source.path` at the plugin directory. For repo installs, use
  `./plugins/`. For personal installs, use `./.codex/plugins/<plugin-name>`
- Keep `source.path` relative to the marketplace root, start with `./`, and keep inside that root
- Always include `policy.installation`, `policy.authentication`, and `category` on each entry
- `policy.installation` values: `AVAILABLE`, `INSTALLED_BY_DEFAULT`, `NOT_AVAILABLE`
- `policy.authentication` decides whether auth happens on install or first use

Before adding a plugin to a marketplace, make sure its version, publisher metadata, and
install-surface copy are ready for other developers to see.

Codex installs plugins into `~/.codex/plugins/cache/$MARKETPLACE_NAME/$PLUGIN_NAME/$VERSION/`.

### AGENTS.md discovery

Codex builds an instruction chain by walking from the git root to the current directory:

1. **Global**: `~/.codex/AGENTS.override.md` → `~/.codex/AGENTS.md`
2. **Project**: each directory from repo root → cwd, checking `AGENTS.override.md` → `AGENTS.md`
3. Files are concatenated root-downward; closer files override earlier guidance

Default size limit is 32 KiB (`project_doc_max_bytes`). Customize in `~/.codex/config.toml`:

```toml
project_doc_fallback_filenames = ["TEAM_GUIDE.md", ".agents.md"]
project_doc_max_bytes = 65536
```

### Invocation

Users invoke plugins in Codex via:
- **Natural language** — "Summarize my service status" (Codex picks the right tools)
- **Explicit** — `@my-service-mcp` to target a specific plugin

### Checklist for dual-CLI support

- [ ] `.claude-plugin/plugin.json` exists (Claude Code)
- [ ] `.codex-plugin/plugin.json` exists (Codex CLI) with `interface` object
- [ ] `.app.json` at plugin root (Codex app/connector manifest)
- [ ] `assets/` directory with icon, logo, screenshots (Codex install surface)
- [ ] `AGENTS.md` symlinks to `CLAUDE.md`
- [ ] `GEMINI.md` symlinks to `CLAUDE.md`
- [ ] `.mcp.json` at repo root (shared by both CLIs)
- [ ] `skills/` directory with `SKILL.md` files (shared by both CLIs)
- [ ] Marketplace entry includes `policy.installation`, `policy.authentication`, and `category`

---

## Marketplace Registration

Plugins in external repos use the GitHub source format. Use all available metadata fields.

```json
{
  "name": "my-service-mcp",
  "source": {
    "source": "github",
    "repo": "jmagar/my-service-mcp"
  },
  "description": "Manage My Service via MCP tools with HTTP fallback. Requires my-service-mcp MCP server running.",
  "version": "1.0.0",
  "category": "infrastructure",
  "tags": ["my-service", "homelab", "mcp"],
  "homepage": "https://github.com/jmagar/my-service-mcp"
}
```

Plugins shipped inside this repo use local path source:

```json
{
  "name": "my-local-plugin",
  "source": "./service-plugins/my-local-plugin",
  ...
}
```

**Current MCP server plugins:**

| Plugin | Repo | Language | Category | Default Port | Bearer Token userConfig key |
|--------|------|----------|----------|--------------|-----------------------------|
| `arcane-mcp` | `jmagar/arcane-mcp` | TypeScript | infrastructure | 44332 | `arcane_mcp_token` |
| `gotify-mcp` | `jmagar/gotify-mcp` | Python | utilities | 9158 | `gotify_mcp_token` |
| `overseerr-mcp` | `jmagar/overseerr-mcp` | Python | media | 9151 | `overseerr_mcp_token` |
| `swag-mcp` | `jmagar/swag-mcp` | Python | infrastructure | 8000 | `swag_mcp_token` |
| `synapse-mcp` | `jmagar/synapse-mcp` | TypeScript | infrastructure | 3000 | `synapse_mcp_token` |
| `syslog-mcp` | `jmagar/syslog-mcp` | Rust | observability | 3100 | `syslog_mcp_token` |
| `unifi-mcp` | `jmagar/unifi-mcp` | Python | infrastructure | 8001 | `unifi_mcp_token` |
| `unraid-mcp` | `jmagar/unraid-mcp` | Python | infrastructure | 6970 | `unraid_mcp_token` |
| `axon` | `jmagar/axon` | Rust | knowledge | 3000 | `axon_mcp_token` |

---

## Testing with mcporter

[mcporter](https://github.com/steipete/mcporter) is the primary testing tool for all MCP servers.
It lets you call tools, compare schemas, and generate CLIs — all without spending tokens.

### Install

```bash
npm install -g mcporter
# or via npx (no install)
npx mcporter list
```

### Each server must have a `tests/test_live.sh`

This script performs a full end-to-end live test of every required tool, action, subaction, and
resource contract. It must run against a live server instance (not mocked).

**Pass/fail contract:**
- Fail if the required domain tool is missing
- Fail if the required help tool is missing or malformed
- Fail if unauthenticated `GET /health` does not work
- Fail if unauthenticated `/mcp` is not rejected
- Fail if a destructive action succeeds without confirmation
- Fail if list responses omit or malform pagination metadata (`items`, `total`, `limit`, `offset`, `has_more`)
- Fail if required actions or subactions declared by the schema are missing from help output

```bash
#!/usr/bin/env bash
# tests/test_live.sh — Full live integration test for my-service-mcp
# Requires: mcporter, jq, running server at $MCP_URL with $MY_SERVICE_MCP_TOKEN
set -euo pipefail

MCP_URL="${MY_SERVICE_MCP_URL:-http://localhost:9000}"
TOKEN="${MY_SERVICE_MCP_TOKEN:?MY_SERVICE_MCP_TOKEN must be set}"
SERVER_NAME="my-service-mcp"
AUTH_HEADER="Authorization: Bearer $TOKEN"
PASS=0
FAIL=0
SKIP=0

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1 — $2"; ((FAIL++)); }
skip() { echo "  SKIP: $1 — $2"; ((SKIP++)); }

header() { echo; echo "=== $1 ==="; }

# ── Schema comparison ──────────────────────────────────────────────────────────
header "Schema: external vs internal"

EXTERNAL_SCHEMA=$(npx mcporter list "$SERVER_NAME" --http-url "$MCP_URL" \
  --header "$AUTH_HEADER" --json 2>/dev/null) || fail "schema/list" "mcporter list failed"

TOOL_COUNT=$(echo "$EXTERNAL_SCHEMA" | jq '.tools | length' 2>/dev/null || echo 0)
echo "  Tools exposed: $TOOL_COUNT"

# Verify the required tool pair exists
if echo "$EXTERNAL_SCHEMA" | jq -e '.tools[] | select(.name == "my_service")' > /dev/null 2>&1; then
  pass "schema/tool-exists: my_service"
else
  fail "schema/tool-exists" "my_service tool not found in external schema"
fi

if echo "$EXTERNAL_SCHEMA" | jq -e '.tools[] | select(.name == "my_service_help")' > /dev/null 2>&1; then
  pass "schema/tool-exists: my_service_help"
else
  fail "schema/tool-exists" "my_service_help tool not found in external schema"
fi

# ── Health check ───────────────────────────────────────────────────────────────
header "Health"

health=$(curl -sf "${MCP_URL}/health") && pass "health/endpoint" || fail "health/endpoint" "HTTP error"
echo "$health" | jq -e '.status == "ok"' > /dev/null 2>&1 \
  && pass "health/status-ok" || fail "health/status-ok" "$(echo "$health" | jq -r '.status')"

# ── Tools: all actions ─────────────────────────────────────────────────────────
header "Tool: my_service — action=list"

result=$(npx mcporter call "${SERVER_NAME}.my_service" \
  --http-url "$MCP_URL" --header "$AUTH_HEADER" action=list 2>/dev/null) \
  && pass "action/list" || fail "action/list" "call failed"

echo "$result" | jq -e '
  has("items") and
  has("total") and
  has("limit") and
  has("offset") and
  has("has_more") and
  (.items | type == "array") and
  (.total | type == "number") and
  (.limit | type == "number") and
  (.offset | type == "number") and
  (.has_more | type == "boolean")
' > /dev/null 2>&1 \
  && pass "action/list-pagination-shape" \
  || fail "action/list-pagination-shape" "missing or malformed pagination metadata"

header "Tool: my_service — action=status"

result=$(npx mcporter call "${SERVER_NAME}.my_service" \
  --http-url "$MCP_URL" --header "$AUTH_HEADER" action=status 2>/dev/null) \
  && pass "action/status" || fail "action/status" "call failed"

header "Tool: my_service_help"

HELP=$(npx mcporter call "${SERVER_NAME}.my_service_help" \
  --http-url "$MCP_URL" --header "$AUTH_HEADER" 2>/dev/null) \
  && pass "help/overview" || fail "help/overview" "call failed"

printf '%s' "$HELP" | grep -q "list" \
  && pass "help/includes-action-list" || fail "help/includes-action-list" "list action missing"

printf '%s' "$HELP" | grep -q "delete" \
  && pass "help/includes-action-delete" || fail "help/includes-action-delete" "delete action missing"

printf '%s' "$HELP" | grep -Eq "DESTRUCTIVE|destructive" \
  && pass "help/marks-destructive" || fail "help/marks-destructive" "destructive marker missing"

HELP_UPDATE=$(npx mcporter call "${SERVER_NAME}.my_service_help" \
  --http-url "$MCP_URL" --header "$AUTH_HEADER" action=update 2>/dev/null) \
  && pass "help/update-detail" || fail "help/update-detail" "detail call failed"

printf '%s' "$HELP_UPDATE" | grep -q "enable" \
  && pass "help/includes-subaction-enable" || fail "help/includes-subaction-enable" "enable subaction missing"

header "Tool: my_service — action=create + get + update + delete (lifecycle)"

CREATE=$(npx mcporter call "${SERVER_NAME}.my_service" \
  --http-url "$MCP_URL" --header "$AUTH_HEADER" action=create name=test-resource 2>/dev/null)
CREATED_ID=$(echo "$CREATE" | jq -r '.id // empty')

if [ -n "$CREATED_ID" ]; then
  pass "action/create"

  npx mcporter call "${SERVER_NAME}.my_service" \
    --http-url "$MCP_URL" --header "$AUTH_HEADER" action=get "id=$CREATED_ID" > /dev/null 2>&1 \
    && pass "action/get" || fail "action/get" "failed for id=$CREATED_ID"

  npx mcporter call "${SERVER_NAME}.my_service" \
    --http-url "$MCP_URL" --header "$AUTH_HEADER" action=update "id=$CREATED_ID" subaction=enable > /dev/null 2>&1 \
    && pass "action/update/enable" || fail "action/update/enable" "failed"

  if npx mcporter call "${SERVER_NAME}.my_service" \
    --http-url "$MCP_URL" --header "$AUTH_HEADER" action=delete "id=$CREATED_ID" > /dev/null 2>&1; then
    fail "action/delete-blocked-without-confirm" "destructive action succeeded without confirmation"
  else
    pass "action/delete-blocked-without-confirm"
  fi

  npx mcporter call "${SERVER_NAME}.my_service" \
    --http-url "$MCP_URL" --header "$AUTH_HEADER" action=delete "id=$CREATED_ID" confirm=true > /dev/null 2>&1 \
    && pass "action/delete-confirmed" || fail "action/delete-confirmed" "failed with confirm=true"
else
  fail "action/create" "no id in response: $CREATE"
  skip "action/get" "create failed"
  skip "action/update/enable" "create failed"
  skip "action/delete-blocked-without-confirm" "create failed"
  skip "action/delete-confirmed" "create failed"
fi

header "Tool: my_service — action=search"

npx mcporter call "${SERVER_NAME}.my_service" \
  --http-url "$MCP_URL" --header "$AUTH_HEADER" action=search query=test > /dev/null 2>&1 \
  && pass "action/search" || fail "action/search" "call failed"

# ── Resources (server-level, no tool name needed) ────────────────────────────
header "Resources"

npx mcporter call "${SERVER_NAME}" --http-url "$MCP_URL" --header "$AUTH_HEADER" \
  --list-resources > /dev/null 2>&1 \
  && pass "resources/list" || skip "resources/list" "no resources defined"

# ── CLI generation ─────────────────────────────────────────────────────────────
header "CLI generation"

npx mcporter generate-cli \
  --server "$SERVER_NAME" \
  --command "$MCP_URL" \
  --header "$AUTH_HEADER" \
  --name "my-service-cli" \
  --bundle \
  > /dev/null 2>&1 \
  && pass "cli/generate" || fail "cli/generate" "mcporter generate-cli failed"

# ── Auth ───────────────────────────────────────────────────────────────────────
header "Bearer token enforcement"

UNAUTH=$(curl -s -o /dev/null -w "%{http_code}" "${MCP_URL}/mcp" \
  -X POST -H "Content-Type: application/json" -d '{}')
[ "$UNAUTH" = "401" ] \
  && pass "auth/unauthenticated-rejected" \
  || fail "auth/unauthenticated-rejected" "expected 401, got $UNAUTH"

# ── Summary ────────────────────────────────────────────────────────────────────
echo
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" && exit 0
echo "FAILURES DETECTED" && exit 1
```

### Schema comparison workflow

```bash
# Export external schema (what the live server reports)
npx mcporter list my-service-mcp --http-url http://localhost:9000 \
  --json > /tmp/external-schema.json

# Diff against your internal schema definition
# (your pyproject.toml, FastMCP tool decorators define the internal schema)
python3 - << 'EOF'
import json

with open("/tmp/external-schema.json") as f:
    external = json.load(f)

# Expected tools and their required actions
EXPECTED = {
    "my_service": {
        "actions": ["list", "get", "create", "update", "delete", "search", "status", "logs"],
        "subactions": {"update": ["enable", "disable", "reload"]},
    },
    "my_service_help": {},
}

for tool_name, spec in EXPECTED.items():
    tool = next((t for t in external.get("tools", []) if t["name"] == tool_name), None)
    if not tool:
        print(f"MISSING TOOL: {tool_name}")
        continue
    print(f"OK: {tool_name} found")
    # Further schema validation...
EOF
```

At minimum, the schema comparison step should assert:
- exactly two tools are exposed: the domain tool and the help tool
- the domain tool advertises every required action and destructive `confirm` support
- the help tool exists and can describe each action with parameters and subactions
- list actions expose pagination parameters

### Generate CLI for a running server

```bash
# Generate and bundle a standalone CLI
npx mcporter generate-cli \
  --server my-service-mcp \
  --command http://localhost:9000 \
  --name my-service-cli \
  --bundle

# Use it
./my-service-cli my_service action=list
./my-service-cli my_service action=get id=abc123
```

### mcporter in CI / `Makefile`

```makefile
.PHONY: test test-live cli

test:
	uv run pytest tests/

test-live:
	@bash tests/test_live.sh

cli:
	npx mcporter generate-cli \
	  --server $(SERVER_NAME) \
	  --command $(MCP_URL) \
	  --name $(SERVER_NAME)-cli \
	  --bundle
```

---

## Validation Checklist

Run before every commit to a plugin repo:

```bash
claude plugin validate .
```

### No unverified claims

Plugin work is **not complete** until all required verification passes:

- `claude plugin validate .`
- `npx skills-ref validate skills/`
- CI checks
- `tests/test_live.sh`

Do not claim a plugin is finished, working, or ready to publish until those checks succeed.

Common errors and fixes:

| Error | Fix |
|---|---|
| `userConfig.*.type: Invalid option` | Add `"type": "string"` — required, undocumented |
| `userConfig.*.title: Invalid input` | Add `"title": "..."` — required, undocumented |
| Hook format rejected | Wrap in `{"description": "...", "hooks": {...}}` — bare arrays not accepted |
| `${user_config.*}` not substituting | Field must be `sensitive: false` for `.mcp.json` substitution |

### Turn guidance into enforcement

Add a repo-local scaffold, template, and lint layer so plugin quality does not depend on authors
remembering the guide:

- `scripts/scaffold-plugin.sh`
  - Creates `.claude-plugin/`, `.codex-plugin/`, `.mcp.json`, hooks, `skills/`, `tests/`, and
    `.env.example` from a canonical template
  - Uses only `MY_SERVICE_*` and `MY_SERVICE_MCP_*` env variable patterns
- `templates/plugin/`
  - Contains the canonical starting point for new plugins
  - Defines the required tool pair, manifest shape, hooks, env naming, and live-test skeleton
  - Verifies response-shape rules for list and non-list actions
  - Verifies schema/help/skill-doc contract drift

The goal is to move as many of these rules as possible from prose into repeatable checks and
generate new plugins from a single canonical template rather than from stale copies of old repos.

---

## Credential Flow Diagram

```
Claude Code plugin install
         │
         ▼
  userConfig prompts (URL, API key, MCP token)
         │
         ▼
  Credentials stored encrypted in Claude Code
         │
         ▼ SessionStart
  sync-env.sh
  ├── Writes MY_SERVICE_URL, MY_SERVICE_API_KEY → .env
  ├── Writes MY_SERVICE_MCP_TOKEN → .env (fails if token not set in userConfig)
  └── chmod 600 .env
         │
         ├─────────────────────────────────────────────────────┐
         ▼                                                     ▼
  Docker Compose reads .env                         .mcp.json wires
  → passes vars to container                        Claude Code → MCP server
  → MCP server reads env vars                       (via ${user_config.url} + Bearer token)
  → connects to service                                        │
                                                               ▼
                                                    Claude Code calls tools
                                                    → MCP server proxies to service

Fallback (MCP server not running):
  CLAUDE_PLUGIN_OPTION_* in Bash subprocess → curl commands in SKILL.md
```

---

## Development Tools Reference

Use these Claude Code skills, agents, and commands when building plugins. Don't build from
scratch — these tools enforce all the conventions in this guide.

### Plugin Creation

| Task | Tool | Type |
|------|------|------|
| Create a Claude Code plugin | `plugin-dev:create-plugin` | Command |
| Create a Codex CLI plugin | `plugin-creator` | Skill |
| Validate a Claude plugin | `plugin-dev:plugin-validator` | Agent |

### Components

| Task | Tool | Type |
|------|------|------|
| Create skills | `plugin-dev:skill-development` | Skill |
| Review skills | `plugin-dev:skill-reviewer` | Agent |
| Create hooks | `plugin-dev:hook-development` | Skill |
| Create agents | `plugin-dev:agent-development` + `plugin-dev:agent-creator` | Skill + Agent |
| Create commands | `plugin-dev:command-development` | Skill |

### MCP Servers

| Task | Tool | Type |
|------|------|------|
| Create MCP server | `mcp-server-dev:build-mcp-server` | Skill |
| Create interactive MCP app | `mcp-server-dev:build-mcp-app` | Skill |
| Create MCPB bundle | `mcp-server-dev:build-mcpb` | Skill |

### Quality & Optimization

| Task | Tool | Type |
|------|------|------|
| Generate optimal CLAUDE.md | `claude-md-management:claude-md-improver` | Skill |
| Recommend automations | `claude-code-setup:claude-automation-recommender` | Skill |
| Simplify codebase | `code-simplifier:code-simplifier` | Agent (run multiple) |

---

## Adding a New Plugin (Checklist)

### Repository setup
- [ ] **`CLAUDE.md`** — AI memory file with project conventions
- [ ] **`AGENTS.md`** → symlink to `CLAUDE.md` (Codex CLI)
- [ ] **`GEMINI.md`** → symlink to `CLAUDE.md` (Gemini CLI)
- [ ] **`README.md`** — user-facing documentation (setup, usage, API)
- [ ] **`CHANGELOG.md`** — version history
- [ ] **`LICENSE`** — MIT license
- [ ] **`.gitignore`** — secrets, caches, tool artifacts, language-specific patterns
- [ ] **`backups/.gitkeep`** and **`logs/.gitkeep`**

### Plugin manifests
- [ ] **`.claude-plugin/plugin.json`** — all userConfig fields have `type`, `title`, `description`, `sensitive`; `my_service_mcp_url` includes `/mcp` in default
- [ ] **`.codex-plugin/plugin.json`** — Codex manifest with `skills`, `mcpServers`, `apps`, and `interface` object
- [ ] **`.app.json`** — Codex app/connector manifest at plugin root
- [ ] **`assets/`** — Plugin visual assets (icon.png, logo.svg, screenshots/) for Codex install surfaces
- [ ] **`.mcp.json`** — `url: "${user_config.my_service_mcp_url}"`, `Authorization: "Bearer ${user_config.my_service_mcp_token}"`

### Hooks
- [ ] **`hooks/hooks.json`** — SessionStart + PostToolUse structure
- [ ] **`hooks/scripts/sync-env.sh`** — maps `CLAUDE_PLUGIN_OPTION_*` → `.env` via `awk`; fails if bearer token missing (no auto-gen)
- [ ] **`hooks/scripts/fix-env-perms.sh`** — enforces chmod 600 on `.env` (identical across plugins)
- [ ] **`hooks/scripts/ensure-ignore-files.sh`** — ensures .gitignore + .dockerignore have all required patterns (identical across plugins)

### MCP server
- [ ] **Server entry point** — action+subaction tool pattern + help tool; bearer auth middleware; bind `0.0.0.0`; `GET /health` unauthenticated
- [ ] **Dual transport** — supports both `http` (default) and `stdio` modes via `MY_SERVICE_MCP_TRANSPORT`
- [ ] **Middleware stack** — timing, logging, error handling, rate limiting, response limiting, bearer auth
- [ ] **Destructive ops** — confirmation gate with elicitation + YOLO mode for any data-loss actions
- [ ] **Filtering/pagination/sorting** — all list actions support `limit`, `offset`, `sort_by`, `sort_order`
- [ ] **Graceful shutdown** — handles SIGTERM/SIGINT

### Skill & agents
- [ ] **`skills/<service>/SKILL.md`** — dual-mode (MCP preferred, HTTP fallback), exhaustive trigger phrases, action+subaction reference
- [ ] **`agents/`** — specialized agents for complex workflows (optional)
- [ ] **`commands/`** — slash commands (optional)

### Configuration
- [ ] **`.env.example`** — flat prefix naming (`MY_SERVICE_*`, `MY_SERVICE_MCP_*`), includes `MY_SERVICE_MCP_TOKEN=`, `MY_SERVICE_MCP_NO_AUTH=false`, `MY_SERVICE_MCP_ALLOW_YOLO=false`, `MY_SERVICE_MCP_ALLOW_DESTRUCTIVE=false`, `PUID=1000`, `PGID=1000`, `DOCKER_NETWORK=`
- [ ] **`pyproject.toml` / `package.json` / `Cargo.toml`** — tool caches pointed at `.cache/`

### Docker & deployment
- [ ] **`entrypoint.sh`** — env validation, env detection (local vs Docker), URL normalization, `exec` for signal handling, strict mode
- [ ] **`Dockerfile`** — multi-stage build, non-root user (`USER 1000:1000`), healthcheck on `/health`, no baked-in secrets
- [ ] **`.dockerignore`** — exclude `.git`, build artifacts, `docs`, `tests`, `logs`, `.env`
- [ ] **`docker-compose.yaml`** — `env_file: .env` only (**no `environment:` block**), `user: "${PUID}:${PGID}"`, named volume, external network, resource limits
- [ ] **`<service>.subdomain.conf`** — SWAG reverse proxy config with Tailscale IPs (no `-mcp` suffix)
- [ ] **`scripts/check-docker-security.sh`** — passes (multi-stage, non-root, no baked secrets)
- [ ] **`scripts/check-no-baked-env.sh`** — passes (no `environment:` block, no baked env)

### Quality
- [ ] **`Justfile`** — standard recipes: dev, test, lint, fmt, build, up, down, health, test-live
- [ ] **`.pre-commit-config.yaml`** — language linter + `skills-ref validate` + `docker-security` + `no-baked-env`
- [ ] **`.github/workflows/ci.yml`** — lint, typecheck, test, version-sync, audit, contract-drift
- [ ] **`scripts/check-outdated-deps.sh`** — run periodically to check for outdated packages
- [ ] **`tests/test_live.sh`** — mcporter-based, tests required tool pair, help output contract, auth rejection, destructive confirmation gate, and pagination metadata
- [ ] **TDD + verification discipline** — start from a failing test/check, implement, then prove behavior with live or integration evidence
- [ ] **`templates/plugin/`** — canonical scaffold source for new plugins

### Publish
- [ ] **`claude plugin validate .`** — must pass with zero errors
- [ ] **`npx skills-ref validate skills/`** — must pass
- [ ] **Version sync** — `plugin.json` version matches language manifest version
- [ ] **Add to `marketplace.json`** — full metadata (name, source, description, version, category, tags, homepage)
