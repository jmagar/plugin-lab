# Repository Structure — my-plugin

Standard layout used across all plugin repositories.

## Directory tree

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json              # Claude Code plugin manifest
├── .codex-plugin/
│   └── plugin.json              # Codex plugin manifest
├── .github/
│   └── workflows/
│       ├── ci.yml               # Lint, typecheck, test on push/PR
│       ├── release.yml          # Build + publish on version tag
│       └── docker.yml           # Build + push Docker image
├── agents/                      # Agent definitions (.md)
├── commands/                    # Slash command definitions (.md)
├── hooks/
│   ├── install.md               # Post-install hook
│   ├── PreToolCall.md           # Pre-tool-call hook
│   └── scripts/                 # Hook scripts (sync-env, fix-perms)
├── output-styles/               # Output style definitions
├── skills/
│   └── my-plugin/
│       ├── SKILL.md             # Skill definition
│       └── scripts/             # Skill scripts
├── scripts/                     # Maintenance and CI scripts
├── tests/                       # Test suite
│   └── test_live.sh             # Live integration smoke test
├── src/                         # Source code (see "Source code" below)
│
├── .app.json                    # App metadata (optional)
├── .env.example                 # Environment variable template (tracked)
├── .gitignore                   # Git ignore rules
├── .dockerignore                # Docker ignore rules
├── .mcp.json                    # MCP server descriptor
├── .pre-commit-config.yaml      # Pre-commit hooks (Python) or lefthook.yml (TS)
├── CHANGELOG.md                 # Version history
├── CLAUDE.md                    # Claude Code project instructions
├── docker-compose.yaml          # Docker Compose stack
├── Dockerfile                   # Container build definition
├── entrypoint.sh                # Container entrypoint script
├── gemini-extension.json        # Gemini extension manifest
├── Justfile                     # Task runner recipes
├── README.md                    # User-facing documentation
├── server.json                  # MCP server registry entry
└── settings.json                # Plugin settings schema
```

## Root files

| File | Required | Purpose |
| --- | --- | --- |
| `CLAUDE.md` | Yes | Project instructions for Claude Code sessions |
| `README.md` | Yes | User-facing overview, install, configuration |
| `CHANGELOG.md` | Yes | Version history with entries for every bump |
| `.env.example` | Yes | Template for credentials — placeholder values only |
| `Justfile` | Yes | Task runner — dev, lint, test, docker, publish |
| `Dockerfile` | Yes | Multi-stage container build |
| `docker-compose.yaml` | Yes | Orchestration with healthcheck and env |
| `entrypoint.sh` | Yes | Runtime env substitution and startup |
| `settings.json` | Yes | Plugin settings schema for userConfig |

## Plugin manifests

All plugins ship with manifests for multiple platforms:

| File | Platform | Key fields |
| --- | --- | --- |
| `.claude-plugin/plugin.json` | Claude Code | name, version, description, tools, surfaces |
| `.codex-plugin/plugin.json` | Codex | name, version, description |
| `gemini-extension.json` | Gemini | name, version, description |
| `server.json` | MCP Registry | transport, auth, health endpoint |
| `.app.json` | App metadata | display name, icon |
| `.mcp.json` | MCP descriptor | server command, args, env |

All manifests must have the same `version` value. See [RULES](RULES.md) for version bumping.

## Source code

<!-- scaffold:specialize — adjust for language -->

| Language | Source directory | Entry point |
| --- | --- | --- |
| Python | `my_plugin_mcp/` | `my_plugin_mcp/server.py` |
| TypeScript | `src/` | `src/index.ts` |
| Rust | `crates/` or `src/` | `src/main.rs` |

## Plugin surfaces

| Directory | Surface | Description |
| --- | --- | --- |
| `agents/` | Agents | Specialized AI agent definitions |
| `skills/` | Skills | SKILL.md + scripts for domain workflows |
| `commands/` | Commands | Slash commands (`.md` files) |
| `hooks/` | Hooks | Lifecycle hooks (install, PreToolCall) |
| `output-styles/` | Output styles | Custom output formatting |

## Infrastructure

| Directory | Purpose |
| --- | --- |
| `.github/workflows/` | CI/CD pipelines |
| `scripts/` | Maintenance scripts (security checks, linting) |
| `tests/` | Unit and integration tests |

## Config files

| File | Purpose |
| --- | --- |
| `.gitignore` | Excludes `.env`, build artifacts, caches |
| `.dockerignore` | Excludes `.env`, `.git`, `node_modules`, `__pycache__` |
| `.pre-commit-config.yaml` | Pre-commit hooks (Python repos) |
| `lefthook.yml` | Git hooks (TypeScript repos) |
