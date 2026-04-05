# Architecture -- plugin-lab

How plugin-lab is structured, how the template system works, and how agents coordinate.

## System Overview

plugin-lab is a development toolkit, not a runtime server. It consists of:

1. **Template system** -- Canonical scaffold source for Python, TypeScript, and Rust MCP plugins
2. **Agent system** -- 7 specialized agents that coordinate through skill definitions
3. **Command system** -- 8 slash commands that invoke skills and spawn agents
4. **Validation system** -- 11 scripts for linting, security auditing, and version sync

```
User
  |
  v
Slash Command (/create-lab-plugin, /review-lab-plugin, ...)
  |
  v
Skill (operating procedure)
  |
  v
Agent (specialized worker)
  |
  +-- reads templates/ for scaffold source
  +-- reads skills/*/references/ for patterns and specs
  +-- delegates to rex-the-researcher for current-state research
  +-- writes artifacts to docs/reports/, docs/research/
  +-- generates plugin files in target repo
```

## Template System

### Three Language Layers

```
templates/
  py/    Python/FastMCP -- async, FastMCP framework, uv package manager
  ts/    TypeScript/MCP SDK -- Express server, @modelcontextprotocol/sdk
  rs/    Rust/rmcp -- tokio async runtime, rmcp crate
```

Each template is self-contained. No cross-template dependencies at scaffold time. If a file is consumed during scaffolding, it lives inside the template directory.

### Shared vs Language-Specific

- **Shared assets** (repo root / `templates/`): Plugin manifests, ignore files, docs templates, hook scripts -- identical across languages
- **Language-specific assets** (`templates/<lang>/`): Package manifest, server module, Dockerfile, Justfile, test scaffold, CI workflow, pre-commit config

### Template Placeholder System

The scaffold script performs a global find-and-replace across all template files:

| Placeholder | Replacement example |
| --- | --- |
| `my-plugin-mcp` | `gotify-mcp` |
| `my_plugin_mcp` | `gotify_mcp` |
| `MY_SERVICE_MCP` | `GOTIFY_MCP` |
| `MY_SERVICE` | `GOTIFY` |
| `my-service` | `gotify` |
| `My Plugin` | `Gotify` |
| `9000` | `9158` |

### Scaffold Pipeline

```
scaffold-plugin.sh
  |
  +-- reads service name, language, port from CLI args
  +-- resolves PLUGIN_TEMPLATES_ROOT (default: ~/workspace/plugin-templates)
  +-- copies shared assets from templates/
  +-- copies language-specific assets from templates/<lang>/
  +-- performs placeholder replacement via sed
  +-- writes output to target directory
```

### Documentation Templates

`templates/docs/` contains documentation templates that are scaffold input for generated plugins. These are organized into subdirectories (mcp/, plugin/, repo/, stack/, upstream/) and contain `<!-- scaffold:specialize -->` markers at locations requiring per-plugin customization.

## Agent Delegation Architecture

### Delegation Graph

```
/create-lab-plugin --> ster-the-scaffolder
                         +---> rex-the-researcher (x3, parallel)

/review-lab-plugin --> roddy-reviewer (x3, parallel)

/align-lab-plugin  --> ally-the-aligner
                         +---> roddy-reviewer (if no review exists)
                         +---> rex-the-researcher (runtime drift)
                         +---> ster-the-scaffolder (template parity)

/tool-lab-plugin   --> tilly-the-toolsmith
                         +---> rex-the-researcher (API changes)

/deploy-lab-plugin --> dex-the-deployer
                         +---> rex-the-researcher (base images)

/pipeline-lab-plugin -> petra-the-pipeliner
                         +---> rex-the-researcher (GHA versions)

/research-lab-plugin -> rex-the-researcher (parallel tracks)
```

### Agent Initialization Contract

Every agent follows the same initialization sequence:
1. Read its corresponding `skills/<name>/SKILL.md`
2. Follow that skill as the operating procedure
3. Consult `skills/<name>/references/` for detailed patterns

### Artifact Output Paths

| Agent | Artifact path |
| --- | --- |
| roddy-reviewer | `docs/reports/plugin-reviews/<YYYYMMDD-HHMMSS>.md` |
| ally-the-aligner | `docs/reports/plugin-alignments/<YYYYMMDD-HHMMSS>.md` |
| rex-the-researcher | `docs/research/<topic>-<YYYYMMDD-HHMMSS>.md` |
| ster-the-scaffolder | `docs/scaffold-plans/<YYYYMMDD-HHMMSS>-<plugin-name>.md` |

## Canonical Plugin Shape

The 15 baseline surfaces every scaffolded plugin includes:

1. Package manifest
2. `.claude-plugin/plugin.json`
3. `.codex-plugin/plugin.json`
4. `.mcp.json`
5. `.app.json`
6. `README.md`
7. `CLAUDE.md`
8. `CHANGELOG.md`
9. `Dockerfile`
10. `docker-compose.yaml`
11. `entrypoint.sh`
12. `Justfile`
13. `.env.example`
14. Ignore files (`.gitignore`, `.dockerignore`)
15. CI workflow (`.github/workflows/ci.yaml`)

Plus: live test scaffold with skip guard.

## Tool Contract: Action+Subaction Pattern

All scaffolded plugins use the action+subaction dispatch pattern:

```
Tool call: { action: "message", subaction: "create", ... }
    |
    v
Dispatch table: (action, subaction) -> handler function
    |
    v
Handler: validates params, calls service, returns result
```

One primary tool per resource domain. One `*_help` companion tool for capability discovery. Error responses use `isError: true` with structured content.

## Transport Architecture

All templates default to dual transport:

- **HTTP** -- Production path. Bearer token authentication. `/health` endpoint for Docker healthcheck.
- **stdio** -- Local dev and Codex CLI path. No authentication needed.

Transport is controlled by the `<SERVICE>_MCP_TRANSPORT` env var.
