# plugin-templates

A Claude Code and Codex plugin that provides agents, commands, skills, and scripts for scaffolding, reviewing, aligning, and deploying homelab MCP server plugins. Also serves as the canonical specification and template source for all plugin server implementations across Python, TypeScript, and Rust.

## What This Is

This repo does two things:

1. **Claude Code / Codex plugin** — install it and get a full suite of agents and slash commands for creating and maintaining MCP plugins (`/create-lab-plugin`, `/review-lab-plugin`, `/align-lab-plugin`, etc.)
2. **Canonical template library** — the source of truth that `scaffold-plugin.sh` and the scaffolding agents read when generating new plugin repos

## Repository Structure

```
plugin-templates/
├── agents/                  # Specialist agents invoked by commands
├── commands/                # Slash commands exposed to Claude Code / Codex
├── skills/                  # Operating procedures agents follow
├── scripts/                 # Utility scripts for linting, validation, scaffolding
├── hooks/                   # SessionStart / PostToolUse hook configs + scripts
├── py/                      # Python language template layer
├── ts/                      # TypeScript language template layer
├── rs/                      # Rust language template layer
├── .claude-plugin/          # Claude plugin manifest
├── .codex-plugin/           # Codex plugin manifest
└── .mcp.json                # MCP server declaration
```

### Two-Layer Architecture

The template structure is intentionally split:

- **Repo root** — shared plugin-contract assets used by every plugin regardless of language: manifests, hooks, scripts, agents, commands, skills, `.env.example`, `docker-compose.yaml`, `my-service.subdomain.conf`
- **`py/`, `ts/`, `rs/`** — language-specific runtime and toolchain assets: package manifests, source modules, Dockerfiles, Justfiles, CI workflows, test frameworks

If a file exists identically in all three language directories, it belongs at repo root. Language directories are not a fourth template — they are the specific layer only.

---

## Agents

Eight specialist agents cover the full plugin lifecycle:

| Agent | Slash command | Role |
|-------|--------------|------|
| **Ster-The-Scaffolder** | `/create-lab-plugin` | Plans and scaffolds new plugins from canonical templates and current SDK docs |
| **Roddy-Reviewer** | `/review-lab-plugin` | Audits existing plugins against the canonical spec; produces detailed reports |
| **Ally-The-Aligner** | `/align-lab-plugin` | Implements review findings; brings plugins to spec |
| **Dex-The-Deployer** | `/deploy-lab-plugin` | Creates Dockerfile, entrypoint.sh, docker-compose.yaml |
| **Tilly-The-Toolsmith** | `/tool-lab-plugin` | Designs MCP tools using the action+subaction dispatch pattern |
| **Petra-The-Pipeliner** | `/pipeline-lab-plugin` | Implements the full 4-workflow CI/CD pipeline + pre-commit / lefthook |
| **Rex-The-Researcher** | `/research-lab-plugin` | Gathers current best practices from official SDK and runtime docs |
| **My-Plugin-Analyzer** | (template) | Read-only template agent for plugin-specific investigation |

---

## Commands

| Command | Arguments | What it does |
|---------|-----------|-------------|
| `/create-lab-plugin` | `<name> [description]` | Scaffold a new plugin from scratch |
| `/review-lab-plugin` | `<plugin-path>` | Run three parallel spec audits and produce a report |
| `/align-lab-plugin` | `<plugin-path>` | Update an existing plugin to canonical spec |
| `/deploy-lab-plugin` | `<plugin-path> [create\|review\|update]` | Generate or review container configuration |
| `/tool-lab-plugin` | `<plugin-path> [create\|review\|update] [tool-name]` | Create or update MCP tools |
| `/pipeline-lab-plugin` | `<plugin-path> [create\|review\|update]` | Set up the full CI/CD pipeline |
| `/research-lab-plugin` | `<topic or stack>` | Research current SDK and runtime best practices |
| `/setup-homelab` | `[--force]` | Initialize `~/.claude-homelab/.env` credentials |

---

## Skills

Skills are detailed operating procedures that agents follow. Each has a `SKILL.md` and a `references/` directory with checklists, templates, and approved source lists.

| Skill | Used by | Output |
|-------|---------|--------|
| `scaffold-lab-plugin` | Ster | Scaffold plan + new repo with all 15 plugin surfaces |
| `review-lab-plugin` | Roddy | `docs/reports/plugin-reviews/<timestamp>.md` |
| `align-lab-plugin` | Ally | Aligned plugin + `docs/reports/plugin-alignments/<timestamp>.md` |
| `deploy-lab-plugin` | Dex | Dockerfile, entrypoint.sh, docker-compose.yaml |
| `tool-lab-plugin` | Tilly | Tool contracts, dispatch tables, handler implementations |
| `pipeline-lab-plugin` | Petra | 4 CI workflow files, Justfile, pre-commit / lefthook config |
| `lab-research-specialist` | Rex | `docs/research/<topic>-<timestamp>.md` |
| `setup` | (direct) | `~/.claude-homelab/.env` configured |

---

## Scripts

All scripts accept `--help`. Generic plugin tooling — safe to copy into any plugin repo.

| Script | Purpose |
|--------|---------|
| `scaffold-plugin.sh` | Generate a new plugin repo from `py/`, `ts/`, or `rs/` templates |
| `lint-plugin.sh` | Validate plugin structure: manifests, version sync, env vars, ignore files, tool patterns |
| `validate-marketplace.sh` | Validate `.claude-plugin/marketplace.json` — accepts `[repo-root]` (default: `$PWD`) |
| `ensure-ignore-files.sh` | Append missing patterns to `.gitignore` / `.dockerignore`; `--check` for CI |
| `check-docker-security.sh` | Verify multi-stage Dockerfile, non-root USER, no baked secrets |
| `check-no-baked-env.sh` | Ensure `.env` is not in Dockerfile or Compose inline environment blocks |
| `check-outdated-deps.sh` | Report outdated packages for Python / TypeScript / Rust projects |
| `fix-env-perms.sh` | Re-enforce `chmod 600` on `.env` (PostToolUse hook) |
| `sync-env.sh` | Map `CLAUDE_PLUGIN_OPTION_*` userConfig vars to `.env` at SessionStart |
| `update-doc-mirrors.sh` | Refresh markdown docs whose first line is a source URL |

---

## Language Templates

Each language directory is a complete, deployable MCP server template:

### Python (`py/`)
- `pyproject.toml` + `uv` / `pip` dependency management
- FastMCP server with action+subaction dispatch
- Multi-stage Dockerfile (Python 3.11+)
- `.pre-commit-config.yaml` hooks
- pytest with `SKIP_LIVE_TESTS` guard

### TypeScript (`ts/`)
- `package.json` + `tsconfig.json`
- FastMCP / MCP SDK server
- Multi-stage Dockerfile (Node 20+)
- `lefthook.yml` hooks (parallel mode)
- Vitest / Jest test framework

### Rust (`rs/`)
- `Cargo.toml` with workspace layout
- `rmcp` / custom MCP server
- Multi-stage Dockerfile (Rust 1.75+ → minimal runtime)
- `lefthook.yml` hooks
- Standard Rust tests + feature flags for live integration tests

All three include: `Dockerfile`, `docker-compose.yaml`, `entrypoint.sh`, `Justfile`, `.env.example`, `.gitignore`, `.dockerignore`, `CLAUDE.md`, `CHANGELOG.md`, `README.md`, four GitHub Actions workflows, and `tests/test_live.sh`.

---

## The 15 Plugin Surfaces

Every plugin must implement all 15 surfaces:

1. Package manifest (`pyproject.toml` / `package.json` / `Cargo.toml`)
2. Claude plugin manifest (`.claude-plugin/plugin.json`)
3. Codex plugin manifest (`.codex-plugin/plugin.json`)
4. MCP declaration (`.mcp.json`)
5. App metadata (`.app.json`)
6. `README.md`
7. `CLAUDE.md`
8. `CHANGELOG.md`
9. `Dockerfile`
10. `docker-compose.yaml`
11. `entrypoint.sh`
12. `Justfile`
13. `.env.example`
14. `.gitignore` + `.dockerignore`
15. CI workflows (ci, publish-image, release-on-main, pre-commit)

---

## MCP Tool Pattern

All tools use **action + subaction dispatch** — not flat tool lists:

```
<service>("<action>", "<subaction>", {...params})
<service>_help("<action>")   # companion help tool for every action
```

Canonical error shape:
```json
{"isError": true, "content": [{"type": "text", "text": "error message"}]}
```

---

## CI/CD — Four Workflows

1. **`ci.yaml`** — lint → type-check → test (sequential via `needs:`)
2. **`publish-image.yaml`** — build + push Docker image with full tag strategy + GHA layer cache
3. **`release-on-main.yaml`** — read version from manifest, skip if tag exists, create git tag + GitHub release
4. **Pre-commit / Lefthook** — runs `scripts/lint-plugin.sh` before every commit

---

## Hook System

```
hooks/
├── claude/hooks.json          # Claude Code plugin hooks
├── codex/hooks.json           # Codex plugin hooks
└── scripts/
    ├── sync-env.sh            # SessionStart: userConfig → .env
    ├── fix-env-perms.sh       # PostToolUse: enforce chmod 600
    └── ensure-ignore-files.sh # SessionStart: sync ignore patterns
```

---

## Rules

- Update templates here first, then update consumers
- Do not duplicate shared files in language directories
- Repo root is the shared layer — not a dumping ground for one-language files
- Language-specific assets live under exactly one of `py/`, `ts/`, `rs/`
- All manifests must carry the same version number, synced with `CHANGELOG.md` and git tags
- `.env` is never committed — `.env.example` with placeholder values only
