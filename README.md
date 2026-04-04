# Plugin Lab

Canonical plugin-development toolkit for the homelab MCP ecosystem. Contains the agents, skills, commands, templates, hooks, and reference docs used to scaffold, review, align, tool, deploy, and pipeline homelab MCP plugins.

## Overview

`plugin-lab` is the development workspace for building and enforcing plugin quality across the homelab. It is not a runtime server. It is also the working example of the canonical plugin shape, so every surface in this repo demonstrates what a well-formed plugin looks like.

It ships:

- specialized agents for every phase of plugin development
- slash commands that orchestrate those agents
- skills that define the operating procedure each agent reads before acting
- canonical templates for Python, TypeScript, and Rust plugins
- hook scripts for Claude and Codex environments
- plugin manifests for installing this repo as a Claude Code plugin
- reference docs explaining the full scaffold contract

## Skills

Skills are the operating procedures agents read before acting. Each skill lives under `skills/<name>/SKILL.md` and has a `references/` subdirectory with supporting material.

| Skill | Slash command | Description |
| --- | --- | --- |
| `scaffold-lab-plugin` | `/create-lab-plugin` | Guides creation of a new MCP plugin from inputs to a concrete scaffold plan |
| `review-lab-plugin` | `/review-lab-plugin` | Guides spec auditing of an existing plugin against the canonical contract |
| `align-lab-plugin` | `/align-lab-plugin` | Guides turning review findings into implementation changes |
| `tool-lab-plugin` | `/tool-lab-plugin` | Guides design and implementation of MCP tools using the action+subaction pattern |
| `deploy-lab-plugin` | `/deploy-lab-plugin` | Guides containerization: Dockerfile, entrypoint, Compose, health endpoint |
| `pipeline-lab-plugin` | `/pipeline-lab-plugin` | Guides CI/CD: ci.yaml, publish-image.yaml, release-on-main.yaml, pre-commit hooks, Justfile targets |
| `lab-research-specialist` | `/research-lab-plugin` | Guides primary-source research on MCP, SDKs, runtimes, and protocol changes |
| `setup` | `/setup-homelab` | Guides interactive credential setup for `~/.claude-homelab/.env` |
| `docs` | — | Reference skill docs mirrored from Claude and Codex agent/skill docs |

### What each skill guides you through

**scaffold-lab-plugin** — Collects plugin name, language, description, and docs links. Directs research before writing any files. Produces a written scaffold plan covering the tool contract, manifest list, and transport assumptions. Hands off to implementation only after the plan is coherent.

**review-lab-plugin** — Reads the canonical spec surfaces and compares them to the target plugin. Flags every misalignment as a finding, distinguishes undocumented drift from justified documented deviations, and writes a durable report to `docs/reports/plugin-reviews/`.

**align-lab-plugin** — Starts from a review report or performs a quick structural audit if none exists. Produces a prioritized alignment plan across ten surfaces (manifests, Docker, CI, tests, docs, skills, commands, agents, hooks, and version sync). Implements changes in a predictable order and writes a summary to `docs/reports/plugin-alignments/`.

**tool-lab-plugin** — Gathers the operation set for a resource domain. Designs an action+subaction contract. Produces the dispatch table, handler stubs, and a `*_help` companion tool. Reviews existing tools for pattern drift.

**deploy-lab-plugin** — Collects port, env var, and volume requirements. Produces a canonical multi-stage Dockerfile, a conforming `entrypoint.sh` with env var validation, a `docker-compose.yaml` with healthcheck, and `.dockerignore`. Confirms or stubs the `/health` endpoint.

**pipeline-lab-plugin** — Produces all four canonical workflow files: `ci.yaml` (lint → type-check → test gate), `publish-image.yaml` (image build and GHCR push with full tag strategy), `release-on-main.yaml` (manifest version → tag check → GitHub release), and the pre-commit hook config. Syncs Justfile targets to match CI steps.

**lab-research-specialist** — Gathers current primary-source docs for MCP protocol, Claude Code plugin format, Codex plugin format, language SDK patterns, and adjacent runtime guidance. Marks inferences explicitly and writes research artifacts other agents can consume.

**setup** — Checks whether `~/.claude-homelab/.env` exists. Creates it from the template if absent. Walks through service credential groups interactively and validates each entry before moving on.

## Agents

Each agent has a YAML front matter block that controls when it fires and what tools it may use. Agents read their corresponding skill before acting.

| Agent | Color | Skill | Spawned by |
| --- | --- | --- | --- |
| `ster-the-scaffolder` | blue | `scaffold-lab-plugin` | `/create-lab-plugin` |
| `roddy-reviewer` | red | `review-lab-plugin` | `/review-lab-plugin`, `ally-the-aligner` |
| `ally-the-aligner` | green | `align-lab-plugin` | `/align-lab-plugin` |
| `tilly-the-toolsmith` | yellow | `tool-lab-plugin` | `/tool-lab-plugin` |
| `dex-the-deployer` | green | `deploy-lab-plugin` | `/deploy-lab-plugin` |
| `petra-the-pipeliner` | cyan | `pipeline-lab-plugin` | `/pipeline-lab-plugin` |
| `rex-the-researcher` | magenta | `lab-research-specialist` | `/research-lab-plugin`, any agent that needs current-state research |

### Agent details

**ster-the-scaffolder** — Scaffolding orchestrator. Gathers inputs, inspects supplied docs and repos, delegates parallel research to rex-the-researcher when the stack may have changed, synthesizes results into a concrete scaffold plan, and produces the first implementation steps. Uses `~/workspace/plugin-templates/` for shared assets and `~/workspace/plugin-templates/<lang>/` for language-specific assets.

**roddy-reviewer** — Spec review agent. Inspects all canonical surfaces, flags every meaningful misalignment with precise file references, separates undocumented drift from justified deviations, and writes a report to `docs/reports/plugin-reviews/<timestamp>.md`.

**ally-the-aligner** — Alignment and remediation agent. Consumes a review report or dispatches roddy-reviewer if none exists. Plans changes across ten surfaces in priority order (manifests first, docs last). Preserves justified deviations. Writes an alignment summary to `docs/reports/plugin-alignments/<timestamp>.md`.

**tilly-the-toolsmith** — MCP tool design agent. Designs action+subaction contracts (one tool per resource domain, subactions are verbs). Produces handler stubs, the dispatch table, and the required `*_help` companion tool. Can refactor flat tool lists into the canonical dispatch shape.

**dex-the-deployer** — Containerization and deployment agent. Produces multi-stage Dockerfiles, entrypoints with env var validation, Compose files with healthchecks, and `.dockerignore`. Enforces the rule that no secret enters the image and no config is hardcoded. Handles rollback via image tag pinning.

**petra-the-pipeliner** — CI/CD pipeline agent. Owns all four workflow files plus the pre-commit hook config and Justfile targets. Enforces that `just test` and CI test are mirrors of each other. The release workflow enforces version discipline: every push to main must bump the manifest version or already have a release tag.

**rex-the-researcher** — Current-state research specialist. Answers questions from primary sources (official docs, protocol specs, SDK repositories, release notes). Distinguishes confirmed facts from inferences. Flags conflicts between sources. Writes research artifacts to `docs/research/<topic>-<timestamp>.md` for other agents to consume.

## Commands

Commands are slash commands that invoke the matching skill and spawn the matching agent.

| Command | Agent | Argument |
| --- | --- | --- |
| `/create-lab-plugin` | `ster-the-scaffolder` | `<plugin-name> [short description]` |
| `/review-lab-plugin` | `roddy-reviewer` (×3 parallel) | `<plugin-path>` |
| `/align-lab-plugin` | `ally-the-aligner` | `<plugin-path>` |
| `/tool-lab-plugin` | `tilly-the-toolsmith` | `<plugin-path> [create\|review\|update] [tool-name]` |
| `/deploy-lab-plugin` | `dex-the-deployer` | `<plugin-path> [create\|review\|update]` |
| `/pipeline-lab-plugin` | `petra-the-pipeliner` | `<plugin-path> [create\|review\|update]` |
| `/research-lab-plugin` | `rex-the-researcher` | `<topic or target stack>` |
| `/setup-homelab` | (skill only) | `[--force]` |

### Command details

**/create-lab-plugin** — Parses plugin name, description, and optional language. Asks for any missing inputs. Invokes `scaffold-lab-plugin` skill, spawns ster-the-scaffolder. Ster dispatches up to three parallel rex-the-researcher workers for current-state research, synthesizes results into a written scaffold plan, and returns the exact first implementation action.

**/review-lab-plugin** — Reads the plugin tree and baseline files (README.md, CLAUDE.md, manifests, Dockerfile, etc.) before spawning. Invokes `review-lab-plugin` skill, spawns three parallel roddy-reviewer agents. Merges the three passes into one report at `docs/reports/plugin-reviews/<timestamp>.md`.

**/align-lab-plugin** — Invokes `align-lab-plugin` skill, spawns ally-the-aligner. If a review report exists in `docs/reports/plugin-reviews/`, Ally reads it. Otherwise, Ally dispatches roddy-reviewer, rex-the-researcher, and ster-the-scaffolder in parallel for evidence, then implements alignment. Writes summary to `docs/reports/plugin-alignments/<timestamp>.md`.

**/tool-lab-plugin** — Invokes `tool-lab-plugin` skill, spawns tilly-the-toolsmith. Modes: `create` gathers operations and produces a full contract; `review` audits all tools for conformance; `update` patches schema, dispatch, and handlers. Tilly dispatches rex-the-researcher if the wrapped service API may have changed.

**/deploy-lab-plugin** — Invokes `deploy-lab-plugin` skill, spawns dex-the-deployer. Modes: `create` produces the full container config from scratch; `review` audits for drift; `update` makes targeted changes. Dex confirms the `/health` endpoint exists or stubs it.

**/pipeline-lab-plugin** — Invokes `pipeline-lab-plugin` skill, spawns petra-the-pipeliner. Modes: `create` produces all four workflow files plus Justfile; `review` audits each file against canonical shape; `update` makes targeted changes and keeps Justfile in sync. Output includes a required secrets list.

**/research-lab-plugin** — Invokes `lab-research-specialist` skill, spawns rex-the-researcher. Rex splits broad topics into parallel research tracks (MCP protocol, Claude plugin docs, Codex plugin docs, language SDK updates, Docker/auth guidance). Writes result to `docs/research/<topic>-<timestamp>.md`.

**/setup-homelab** — Invokes `setup` skill. Copies `.env.example` to `~/.claude-homelab/.env` if absent (or overwrites with `--force`), sets `chmod 600`, installs `load-env.sh`, and prompts the user to fill in service credentials.

## Skill → Agent → Command mapping

| Skill | Agent | Command | Produces |
| --- | --- | --- | --- |
| `scaffold-lab-plugin` | `ster-the-scaffolder` | `/create-lab-plugin` | Scaffold plan + implementation steps |
| `review-lab-plugin` | `roddy-reviewer` | `/review-lab-plugin` | `docs/reports/plugin-reviews/<ts>.md` |
| `align-lab-plugin` | `ally-the-aligner` | `/align-lab-plugin` | `docs/reports/plugin-alignments/<ts>.md` |
| `tool-lab-plugin` | `tilly-the-toolsmith` | `/tool-lab-plugin` | Tool contract + handler stubs |
| `deploy-lab-plugin` | `dex-the-deployer` | `/deploy-lab-plugin` | Dockerfile, entrypoint.sh, docker-compose.yaml |
| `pipeline-lab-plugin` | `petra-the-pipeliner` | `/pipeline-lab-plugin` | Four workflow files + Justfile targets |
| `lab-research-specialist` | `rex-the-researcher` | `/research-lab-plugin` | `docs/research/<topic>-<ts>.md` |
| `setup` | — | `/setup-homelab` | `~/.claude-homelab/.env` |

## Plugin lifecycle

A plugin moves through six phases. Each phase has a dedicated skill, agent, and command.

```
scaffold → review → align → tool → deploy → pipeline
```

1. **scaffold** — Create the repo, manifests, transport config, and initial tool stubs from a concrete plan.
2. **review** — Audit every canonical surface against the spec. Produce a findings report.
3. **align** — Implement every finding from the review report. Preserve justified deviations.
4. **tool** — Design and implement MCP tool contracts using the action+subaction pattern.
5. **deploy** — Containerize with a multi-stage Dockerfile, conforming entrypoint, and Compose stack.
6. **pipeline** — Add CI/CD: test gate, image publishing, automated releases, and pre-commit hooks.

Phases are not strictly sequential. Run `/review-lab-plugin` on any existing plugin at any time. Run `/align-lab-plugin` after any review. Run `/research-lab-plugin` before scaffolding when the target SDK is unfamiliar or may have changed.

## Templates

Templates are the canonical scaffold source for generated plugin repos. The scaffold script at `/home/jmagar/claude-homelab/scripts/scaffold-plugin.sh` reads from these directories.

```
templates/
  py/    Python/FastMCP template
  ts/    TypeScript/MCP SDK template
  rs/    Rust/rmcp template
```

### Template selection guide

| Language | Runtime | When to choose |
| --- | --- | --- |
| Python (`py/`) | FastMCP | Service has a Python SDK; team is comfortable with Python; existing homelab plugins are Python |
| TypeScript (`ts/`) | Express + MCP SDK | Service has a JS/TS SDK; plugin is primarily async HTTP calls; JSON-heavy APIs |
| Rust (`rs/`) | rmcp | Plugin is performance-critical; binary size matters; Rust SDK is the best maintained option |

All three templates ship the same canonical shape:

- package manifest (`pyproject.toml` / `package.json` / `Cargo.toml`)
- `my_plugin_mcp/` runtime module directory
- Claude and Codex plugin manifests
- hooks and hook scripts
- multi-stage Dockerfile, `docker-compose.yaml`, `entrypoint.sh`
- `Justfile`
- CI workflow
- pre-commit or lefthook config
- `.gitignore`, `.dockerignore`, `.env.example`
- AI-facing files: `skills/`, `agents/`, `commands/`, `CLAUDE.md`
- test scaffold: `tests/test_live.sh`

Each template is self-contained. Never add cross-template dependencies at scaffold time. If a file is consumed during scaffolding, it must live inside the template directory. Update the scaffold script whenever template paths change.

### Transport defaults

All templates default to dual transport (HTTP + stdio). HTTP is the production path; stdio is the local dev and Codex CLI path. Transport is controlled by the `<SERVICE>_MCP_TRANSPORT` env var.

### Tool shape

All templates default to the action+subaction pattern: one primary tool per resource domain plus a `*_help` companion tool. Do not flatten multiple operations into separate top-level tools without a compelling reason.

## Repository layout

```
agents/                 Lab workflow agents (one .md file per agent)
commands/               Slash commands (one .md file per command)
skills/                 Skill operating procedures
  align-lab-plugin/     SKILL.md + references/
  deploy-lab-plugin/    SKILL.md + references/
  lab-research-specialist/  SKILL.md + references/
  pipeline-lab-plugin/  SKILL.md + references/
  review-lab-plugin/    SKILL.md + references/
  scaffold-lab-plugin/  SKILL.md + references/
  setup/                SKILL.md + references/ + scripts/
  tool-lab-plugin/      SKILL.md + references/
  docs/                 Mirrored Claude and Codex skill/agent documentation
templates/              Canonical scaffold source root
  py/                   Python plugin template (self-contained)
  ts/                   TypeScript plugin template (self-contained)
  rs/                   Rust plugin template (self-contained)
hooks/                  Hook scripts shared across environments
  docs/                 Hook documentation
  scripts/              sync-env.sh, fix-env-perms.sh, ensure-ignore-files.sh
docs/                   Human-facing docs about plugin-lab
  plugin-setup-guide.md Full canonical spec reference
  scaffold-template-mapping.md  Root-to-template mapping decisions
  plans/                Planning artifacts
  reports/              Review and alignment outputs
  research/             Research artifacts from rex-the-researcher
  sessions/             Session notes
  superpowers/          Superpowers skill references
bin/                    Plugin execution helpers added to PATH
output-styles/          Output formatting references
scripts/                Repo maintenance scripts
.claude-plugin/         Claude plugin manifest (plugin.json)
.codex-plugin/          Codex plugin manifest (plugin.json)
gemini-extension.json   Gemini extension manifest
CLAUDE.md               Repo working instructions and single-source-of-truth rules
CHANGELOG.md            Release history
```

## Installation

### Marketplace

```bash
/plugin marketplace add jmagar/claude-homelab
/plugin install plugin-lab @jmagar-claude-homelab
```

### Local install

```bash
# From the repo root, Claude Code will auto-discover the .claude-plugin/plugin.json
cd ~/workspace/plugin-lab
```

The `.claude-plugin/plugin.json` points Claude Code at the local repo. Skills, agents, and commands become available immediately after Claude Code loads the plugin.

## Usage

### Scaffold a new plugin

```bash
/create-lab-plugin my-service-mcp "Wraps the My Service API"
```

Provide links to the service API docs when prompted. Ster will delegate research to Rex before writing any files.

### Review an existing plugin

```bash
/review-lab-plugin ~/workspace/my-service-mcp
```

Three reviewer instances run in parallel and merge into one report.

### Align a plugin after review

```bash
/align-lab-plugin ~/workspace/my-service-mcp
```

If a review report already exists in `docs/reports/plugin-reviews/`, Ally reads it directly. Otherwise, Ally dispatches a fresh review pass first.

### Add or update MCP tools

```bash
/tool-lab-plugin ~/workspace/my-service-mcp create applications
```

Tilly gathers the operation set for the `applications` resource domain and produces the action+subaction contract.

### Containerize a plugin

```bash
/deploy-lab-plugin ~/workspace/my-service-mcp create
```

Dex produces Dockerfile, entrypoint.sh, docker-compose.yaml, and .dockerignore. Stubs `/health` if absent.

### Add CI/CD

```bash
/pipeline-lab-plugin ~/workspace/my-service-mcp create
```

Petra produces all four workflow files, the pre-commit or lefthook config, and the Justfile targets.

### Research before scaffolding

```bash
/research-lab-plugin "TypeScript MCP server current patterns"
```

Rex queries primary sources and writes a research artifact that ster-the-scaffolder consumes on the next scaffold run.

### Configure homelab credentials

```bash
/setup-homelab
```

Walks through the credential wizard for `~/.claude-homelab/.env`.

## CLAUDE.md rules (summary)

The repo CLAUDE.md enforces two rules that apply to everyone working in this repo:

**Single source of truth.** Every file exists in exactly one place. Shared plugin-contract files live at the repo root. Language-specific files live under one language directory. Never duplicate shared files into `py/`, `ts/`, or `rs/`.

**No duplication.** No shared trees duplicated under language directories. No placeholder-only paths unless the scaffold consumes them. Root docs describe this repo, not a language template. Per-language `README.md` and `CLAUDE.md` describe that language layer only.

If you move or rename a template file, update the scaffold script and any combo instructions in `claude-homelab` in the same change.

**Version bumping.** Every feature branch push must bump the version in all version-bearing files (`Cargo.toml`, `package.json`, `pyproject.toml`, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `gemini-extension.json`, `README.md`, `CHANGELOG.md`). All files must share the same version string.

## Verification

After modifying templates or docs:

```bash
rtk rg -n "^#|^##" README.md docs/plugin-setup-guide.md
rtk rg --files agents commands skills templates/py templates/ts templates/rs hooks
```

After scaffolding a new plugin, run `/review-lab-plugin` on the output to catch drift before committing.

## Related files

- `docs/plugin-setup-guide.md` — Full canonical spec: transport modes, tool design, Docker, CI/CD, file-by-file reference, validation checklist
- `docs/scaffold-template-mapping.md` — Decisions on what lives at the repo root vs under `templates/`
- `templates/py/README.md` — Python template details and runtime shape
- `templates/ts/README.md` — TypeScript template details and runtime shape
- `templates/rs/README.md` — Rust template details and runtime shape
- `CHANGELOG.md` — Release history
- `/home/jmagar/claude-homelab/scripts/scaffold-plugin.sh` — Consumer of the templates in this repo

## License

MIT
