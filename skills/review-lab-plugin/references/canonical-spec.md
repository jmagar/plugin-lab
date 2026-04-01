# Canonical Spec Reference

This file defines the correct canonical values for every check category used by review-lab-plugin. When a finding says "canonical expectation is X", the source of that expectation is here.

---

## Missing Required Files

A compliant plugin must contain all 15 of the following files at the specified paths. Absence of any file is at minimum a HIGH finding.

| # | Required File | Correct Path |
|---|---------------|--------------|
| 1 | Package manifest | `pyproject.toml` (Python) · `Cargo.toml` (Rust) · `package.json` (TypeScript) |
| 2 | Claude plugin manifest | `.claude-plugin/plugin.json` |
| 3 | Codex plugin manifest | `.codex-plugin/plugin.json` |
| 4 | MCP server declaration | `.mcp.json` |
| 5 | App metadata | `.app.json` |
| 6 | User-facing docs | `README.md` |
| 7 | Claude-facing dev guide | `CLAUDE.md` |
| 8 | Version history | `CHANGELOG.md` |
| 9 | Container image | `Dockerfile` |
| 10 | Compose definition | `docker-compose.yaml` |
| 11 | Container startup script | `entrypoint.sh` |
| 12 | Task runner | `Justfile` |
| 13 | Credential template | `.env.example` |
| 14 | Ignore files | `.gitignore` and `.dockerignore` |
| 15 | CI workflow | `.github/workflows/ci.yaml` |

Plus: live test scaffold (at least one test file that hits the real service with a skip guard).

---

## Wrong File Locations

Files placed outside these paths are mislocated. Mark as MEDIUM if the file exists but is in the wrong place, HIGH if the misplacement prevents loading.

| File | Correct Location | Common Wrong Locations |
|------|-----------------|----------------------|
| Claude manifest | `.claude-plugin/plugin.json` | `plugin.json` at root, `.claude/plugin.json` |
| Codex manifest | `.codex-plugin/plugin.json` | `codex-plugin.json` at root |
| MCP declaration | `.mcp.json` | `mcp.json`, `.mcp/config.json` |
| CI workflow | `.github/workflows/ci.yaml` | `.github/ci.yaml`, `ci.yml` at root |
| Entrypoint | `entrypoint.sh` at repo root | `scripts/entrypoint.sh`, `docker-entrypoint.sh` |
| Live tests | `tests/test_live.*` (Python) · `tests/live_test.rs` (Rust) · `tests/live.test.*` (TypeScript) | `test/live.*`, `e2e/*` |

---

## Version Drift

Version fields must be synchronized across all version-bearing files. A mismatch between any two is a HIGH finding.

**Version-bearing files:**

- Package manifest (`version = "..."` or `"version": "..."`)
- `.claude-plugin/plugin.json` (`"version"` field)
- `.codex-plugin/plugin.json` (`"version"` field)
- `.app.json` (`"version"` field)
- `CHANGELOG.md` (latest `## [x.y.z]` heading)

**Correct behavior:** All five sources must show the same semver string (e.g., `1.2.0`). The CHANGELOG heading is the source of truth when there is ambiguity — the manifest versions should match the most recent CHANGELOG release.

---

## Incorrect userConfig Shape

The `userConfig` object in `.claude-plugin/plugin.json` must follow this shape:

```json
"userConfig": {
  "<ENV_VAR_NAME>": {
    "type": "string",
    "description": "Human-readable description of what this value is.",
    "required": true,
    "sensitive": true
  }
}
```

**Rules:**

- Every credential or secret the user must supply goes in `userConfig`, not hardcoded in the manifest.
- `"type"` must be `"string"` for all current homelab plugins.
- `"sensitive": true` is required for tokens, passwords, and API keys. Omitting it is a HIGH finding.
- `"required": true` for values without which the plugin cannot function. Optional values must have a sensible default documented in `"description"`.
- Keys must match the env var names used in `.env.example` exactly (case-sensitive).
- Do not put non-credential config (ports, feature flags, timeouts) in `userConfig` — those belong in `.env.example` with defaults.

---

## Transport Mismatch

Valid transport options are `stdio`, `http`, or both (dual transport).

**Dual transport (canonical default):**

`.mcp.json` must declare `stdio` so Claude Code can launch the server locally:

```json
{
  "mcpServers": {
    "<plugin-name>": {
      "command": "docker",
      "args": ["compose", "-f", "/path/to/docker-compose.yaml", "run", "--rm", "mcp", "stdio"],
      "env": {}
    }
  }
}
```

`.claude-plugin/plugin.json` must declare the HTTP transport URL:

```json
"transport": {
  "type": "http",
  "url": "http://localhost:${PORT}/mcp"
}
```

**stdio-only:** Acceptable for CLI-wrapping plugins with no persistent service. Must be explicitly justified.

**http-only:** Acceptable only when stdio is technically impossible. Must be explicitly justified.

A plugin that declares dual transport in its manifest but only implements one transport in code is a HIGH finding.

---

## Missing Auth

HTTP transport must be protected by bearer token auth. Absence of auth is a CRITICAL finding.

**Correct configuration in `.claude-plugin/plugin.json`:**

```json
"auth": {
  "type": "bearer",
  "tokenEnvVar": "MCP_AUTH_TOKEN"
}
```

**Correct server-side behavior:** The server must reject requests missing a valid `Authorization: Bearer <token>` header with HTTP 401. Logging the token value anywhere is a separate CRITICAL finding.

`MCP_AUTH_TOKEN` must appear in `.env.example` with a placeholder value and in `userConfig` with `"sensitive": true`.

---

## Missing Health Endpoint

Every HTTP-transport plugin must expose a health endpoint.

**Correct path:** `GET /health`

**Correct response:**

```json
{"status": "ok"}
```

**Correct HTTP status:** `200 OK`

The endpoint must not require authentication so that Docker health checks and uptime monitors can reach it without credentials. Returning any non-200 status or a body that does not include `"status": "ok"` is a HIGH finding.

**Correct Docker health check in `docker-compose.yaml`:**

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:${PORT}/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

---

## Missing Help Tool

Every plugin must expose a `<plugin_name>_help` tool alongside its primary tool.

**What the help tool must contain:**

- A complete action/subaction table: one row per valid `(action, subaction)` combination with a short description.
- Parameter descriptions for every parameter across all actions.
- At least one usage example per action.

**Correct tool name pattern:** If the primary tool is `unraid`, the help tool is `unraid_help`. If there are multiple primary tools, each gets its own `_help` companion.

A plugin that exposes actions without a help tool is a MEDIUM finding. A plugin with a help tool that omits actions from the table is a LOW finding.

---

## Missing Live Test

Every plugin must have at least one live test that contacts the real service.

**Minimum requirements:**

- One test function or test case that makes a real network call to the configured service.
- A skip guard that skips the test when credentials or service URL are absent from the environment (so CI passes without live credentials).
- The test must assert on the response, not just that no exception was raised.

**Correct skip guard patterns:**

Python:
```python
import pytest
pytestmark = pytest.mark.skipif(
    not os.getenv("SERVICE_URL"), reason="SERVICE_URL not set"
)
```

TypeScript:
```typescript
const skip = !process.env.SERVICE_URL;
(skip ? test.skip : test)("live: fetches data", async () => { ... });
```

Rust:
```rust
#[test]
fn live_fetch() {
    let url = std::env::var("SERVICE_URL").expect("SERVICE_URL not set — skipping live test");
    // ...
}
```

A plugin with no live test file is a HIGH finding. A plugin with a live test that always runs (no skip guard) is a MEDIUM finding.

---

## Stale README / CLAUDE

**README.md must contain these sections:**

- Installation / setup (including plugin marketplace install command)
- Environment variables (table matching `.env.example`)
- Tool reference (all actions and subactions with parameter descriptions)
- Examples (at least one per action)
- Troubleshooting

A README missing any of these sections is a MEDIUM finding. A README that describes tools or env vars that no longer exist is a HIGH finding.

**CLAUDE.md must contain:**

- Repo layout overview
- How to run the server locally
- How to run tests
- Key conventions (naming, error handling, logging rules)
- What not to change without discussion (e.g., transport contract, auth scheme)

A CLAUDE.md that refers to files or commands that no longer exist is a MEDIUM finding.

---

## Ignore File Hygiene

**`.gitignore` must exclude:**

- `.env` and any file matching `*.env` or `.env.*` (except `.env.example`)
- `__pycache__/`, `*.pyc`, `*.pyo` (Python)
- `target/` (Rust)
- `node_modules/`, `dist/`, `.next/` (TypeScript)
- `.DS_Store`, `Thumbs.db`
- IDE directories: `.vscode/`, `.idea/`
- Log files: `*.log`, `logs/`

**`.dockerignore` must exclude:**

- `.env` and any file matching `*.env` or `.env.*` (except `.env.example`)
- `.git/`
- `node_modules/` (TypeScript)
- `target/` (Rust)
- `__pycache__/` (Python)
- `*.md` (documentation, not needed in image)
- `.github/`
- `tests/` (test code should not be in the production image)

A `.gitignore` that does not exclude `.env` is a CRITICAL finding. A `.dockerignore` that does not exclude `.env` is a HIGH finding.
