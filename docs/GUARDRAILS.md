# Security Guardrails

Security constraints enforced across all plugins built with plugin-lab.

## Credential Management

**Rule: Credentials never enter version control or Docker images.**

- All secrets live in `~/.claude-homelab/.env` (homelab services) or plugin-local `.env` (per-plugin)
- `.env` is always in `.gitignore` and `.dockerignore`
- `.env` files have `chmod 600` permissions
- `.env.example` contains placeholder values only -- tracked in git
- Hook scripts (`sync-env.sh`, `fix-env-perms.sh`) enforce these rules at session start

### What the hooks enforce

| Hook script | Trigger | What it does |
| --- | --- | --- |
| `sync-env.sh` | SessionStart | Syncs `userConfig` values into `.env`, validates MCP token is set |
| `fix-env-perms.sh` | PostToolUse | Ensures `.env` and backups have `chmod 600` |
| `ensure-ignore-files.sh` | SessionStart | Ensures `.gitignore` and `.dockerignore` have required patterns |

### Credential patterns

```bash
# Correct: read from .env at runtime
source .env
curl -H "Authorization: Bearer ${MY_SERVICE_API_KEY}" ...

# Wrong: hardcoded in script
curl -H "Authorization: Bearer abc123" ...

# Wrong: baked into Docker image
ENV MY_SERVICE_API_KEY=abc123
```

## Docker Security

- Multi-stage builds only -- no compilers or dev deps in runtime image
- Runtime stage runs as non-root user
- No `USER root` in runtime stage
- No inline `environment:` blocks in `docker-compose.yaml` -- use `env_file:`
- Base images pinned to version tags, not `latest`
- `entrypoint.sh` exits non-zero if required env vars are missing

### Validation

```bash
bash scripts/check-docker-security.sh
bash scripts/check-no-baked-env.sh
```

## Authentication

- HTTP transport requires bearer token authentication
- `MY_SERVICE_MCP_TOKEN` must be set for production HTTP transport
- `MY_SERVICE_MCP_NO_AUTH=true` is for local development only
- `/health` endpoint is unauthenticated (required for Docker healthcheck)
- All other endpoints require a valid bearer token

## Input Handling

- Action and subaction parameters are validated against enum values before dispatch
- Unknown action/subaction combinations return a structured error, not an exception
- Parameter validation happens after dispatch, not before
- The `*_help` tool is always unauthenticated for capability discovery

## Destructive Operations

- Destructive operations (delete, modify, restart) are gated behind `ALLOW_DESTRUCTIVE`
- Interactive confirmation via MCP elicitation when available
- `ALLOW_YOLO=true` skips confirmation (CI/automation only)

## Ignore File Requirements

Required `.gitignore` patterns:

```
.env
.env.*
!.env.example
logs/*
!logs/.gitkeep
*.log
.claude/settings.local.json
.claude/worktrees/
.omc/
```

Required `.dockerignore` patterns:

```
.git
.github
.env
.env.*
!.env.example
.claude
.claude-plugin
.codex-plugin
docs
tests
scripts
*.md
!README.md
```

The `ensure-ignore-files.sh` script appends missing patterns automatically at session start, or can run in `--check` mode for CI.
