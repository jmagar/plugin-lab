# Slash Commands -- plugin-lab

plugin-lab provides 8 slash commands that invoke skills and spawn agents.

## Command Summary

| Command | Agent | Argument | Description |
| --- | --- | --- | --- |
| `/create-lab-plugin` | ster-the-scaffolder | `<plugin-name> [short description]` | Scaffold a new plugin |
| `/review-lab-plugin` | roddy-reviewer (x3) | `<plugin-path>` | Audit plugin against spec |
| `/align-lab-plugin` | ally-the-aligner | `<plugin-path>` | Implement review findings |
| `/tool-lab-plugin` | tilly-the-toolsmith | `<plugin-path> [create\|review\|update] [tool-name]` | Create/review/update MCP tools |
| `/deploy-lab-plugin` | dex-the-deployer | `<plugin-path> [create\|review\|update]` | Containerize a plugin |
| `/pipeline-lab-plugin` | petra-the-pipeliner | `<plugin-path> [create\|review\|update]` | Implement CI/CD pipeline |
| `/research-lab-plugin` | rex-the-researcher | `<topic or target stack>` | Research current guidance |
| `/setup-homelab` | (skill only) | `[--force]` | Configure credentials |

## Command Details

### /create-lab-plugin

**File:** `commands/create-lab-plugin.md`
**Allowed tools:** Read, Write, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, Skill

Parses `<plugin-name> [short description]` from arguments. Asks for missing inputs (name, description, language, docs links). Invokes `scaffold-lab-plugin` skill, spawns ster-the-scaffolder.

Ster dispatches up to three parallel rex-the-researcher workers for current-state research, synthesizes results into a written scaffold plan, and returns the exact first implementation action.

```bash
/create-lab-plugin my-service-mcp "Wraps the My Service API"
```

### /review-lab-plugin

**File:** `commands/review-lab-plugin.md`
**Allowed tools:** Read, Write, Bash, Glob, Grep, Task, Skill

Takes `<plugin-path>` as argument. Reads the plugin tree and baseline files before spawning. Invokes `review-lab-plugin` skill, spawns **three parallel roddy-reviewer agents**. Merges the three passes into one report.

Baseline files read: README.md, CLAUDE.md, manifests, Dockerfile, docker-compose.yaml, .env.example, Justfile.

Report written to: `docs/reports/plugin-reviews/<YYYYMMDD-HHMMSS>.md`

```bash
/review-lab-plugin ~/workspace/my-service-mcp
```

### /align-lab-plugin

**File:** `commands/align-lab-plugin.md`
**Allowed tools:** Read, Write, Edit, Bash, Glob, Grep, Task, Skill, WebSearch, WebFetch

Takes `<plugin-path>` as argument. Invokes `align-lab-plugin` skill, spawns ally-the-aligner.

If a review report exists in `docs/reports/plugin-reviews/`, Ally reads it directly. Otherwise, dispatches in parallel: roddy-reviewer (structural drift), rex-the-researcher (runtime/schema drift), ster-the-scaffolder (template parity).

Summary written to: `docs/reports/plugin-alignments/<YYYYMMDD-HHMMSS>.md`

```bash
/align-lab-plugin ~/workspace/my-service-mcp
```

### /tool-lab-plugin

**File:** `commands/tool-lab-plugin.md`
**Allowed tools:** Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, Skill

Takes `<plugin-path> [mode] [tool-name]`. Mode defaults to `create`. Tool name required for `create` and `update`, optional for `review`.

Modes:
- `create` -- gather operations, produce full action+subaction contract + handler stubs
- `review` -- audit all tools for conformance, produce findings list
- `update` -- patch schema, dispatch, handlers; keep `*_help` in sync

```bash
/tool-lab-plugin ~/workspace/my-service-mcp create applications
```

### /deploy-lab-plugin

**File:** `commands/deploy-lab-plugin.md`
**Allowed tools:** Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, Skill

Takes `<plugin-path> [mode]`. Mode defaults to `create`.

Modes:
- `create` -- gather requirements, produce full container config
- `review` -- audit for drift, produce findings list
- `update` -- targeted changes, flag missing env vars

Produces: Dockerfile, entrypoint.sh, docker-compose.yaml, .dockerignore, `/health` confirmation/stub.

```bash
/deploy-lab-plugin ~/workspace/my-service-mcp create
```

### /pipeline-lab-plugin

**File:** `commands/pipeline-lab-plugin.md`
**Allowed tools:** Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, Skill

Takes `<plugin-path> [mode]`. Mode defaults to `create`.

Produces all four workflow files, pre-commit/lefthook config, Justfile targets, and required secrets list.

```bash
/pipeline-lab-plugin ~/workspace/my-service-mcp create
```

### /research-lab-plugin

**File:** `commands/research-lab-plugin.md`
**Allowed tools:** Read, Write, Bash, Glob, Grep, WebSearch, WebFetch, Task, Skill

Takes `<topic or target stack>`. For broad topics, Rex splits into parallel tracks (MCP protocol, Claude plugin docs, Codex plugin docs, SDK updates, Docker/auth guidance).

Result written to: `docs/research/<topic>-<YYYYMMDD-HHMMSS>.md`

```bash
/research-lab-plugin "TypeScript MCP server current patterns"
```

### /setup-homelab

**File:** `commands/setup-homelab.md`
**Allowed tools:** Bash, Skill

Takes optional `[--force]`. Invokes `setup` skill. Copies `.env.example` to `~/.claude-homelab/.env` if absent (or overwrites with `--force`), sets `chmod 600`, installs `load-env.sh`, prompts user to fill in service credentials.

```bash
/setup-homelab
/setup-homelab --force
```

## Command Frontmatter Schema

```yaml
---
description: Short description for autocomplete
argument-hint: <required> [optional]
allowed-tools: Read, Write, Bash, ...
---
```

| Field | Required | Description |
| --- | --- | --- |
| `description` | yes | Shown in Claude Code autocomplete |
| `argument-hint` | yes | Expected argument pattern |
| `allowed-tools` | yes | Pre-approved tools (no permission prompts) |
