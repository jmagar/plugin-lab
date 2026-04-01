---
name: scaffold-lab-plugin
description: Create a new MCP plugin scaffold aligned to the homelab canonical plugin spec. Use when the user wants to create a new plugin repo, scaffold a plugin in Python, Rust, or TypeScript, choose manifests and runtime files, define commands/agents/skills, or turn docs and API references into an implementation plan for a new plugin.
---

# Scaffold Lab Plugin

Create a new plugin scaffold that matches the current homelab canonical structure.

## Gather Inputs First

Collect these inputs before proposing structure or generating files:

- plugin name
- short description
- target language: `python`, `rust`, or `typescript`
- primary product or service being wrapped
- links or local paths for docs, SDKs, OpenAPI specs, repos, or examples
- whether the plugin needs HTTP only or dual transport

If any input is missing, ask for it before scaffolding.

## Default Assumptions

Unless the user says otherwise, assume:

- dual transport: HTTP and stdio
- one primary tool using the action + subaction pattern
- one `*_help` companion tool
- Docker + Docker Compose
- Claude and Codex manifests
- bearer auth on HTTP transport
- health endpoint at `/health`
- `.env` as the runtime config source

For the exact template file that implements each assumption, see `references/surface-to-template-map.md`.

## Research Before Scaffolding

Do not scaffold blindly from memory when the plugin depends on an SDK, protocol, or API that may have changed.

Review the supplied docs or repo context first. If the request depends on current SDK or protocol behavior, browse primary sources before finalizing the scaffold plan.

Focus research on:

- current MCP transport expectations
- latest language SDK patterns
- service authentication model
- required manifests and config files
- package manager and test tooling

## When to Write a Plan

Always write a plan for net-new plugins. Skip it only for single-file additions to existing plugins where the scope is unambiguous.

The plan should cover:

- repo name
- language/runtime choice
- tool contract (action enum, subaction enum per action, parameter shapes)
- service layer shape (REST, GraphQL, CLI, etc.)
- manifest set
- command, skill, and agent surfaces
- test strategy
- Docker/runtime strategy
- open questions that must be resolved before implementation starts

Use the fill-in-the-blanks template in `references/scaffold-plan-template.md` to structure the plan output.

## Scaffold to Canonical Shape

Generate or update the plugin to include these 15 baseline surfaces. Each surface has a brief description and a canonical template location — see `references/surface-to-template-map.md` for the full mapping.

1. **package manifest** (`pyproject.toml` / `Cargo.toml` / `package.json`) — declares the package name, version, dependencies, and entry point for the chosen runtime
2. **`.claude-plugin/plugin.json`** — Claude plugin manifest; defines name, description, userConfig, transport, and the tool list Claude exposes to users
3. **`.codex-plugin/plugin.json`** — Codex plugin manifest; parallel to the Claude manifest for OpenAI Codex agent compatibility
4. **`.mcp.json`** — MCP server declaration consumed by Claude Code; specifies command, args, and env for launching the server locally
5. **`.app.json`** — application-level metadata used by the plugin marketplace and install tooling
6. **`README.md`** — user-facing setup and usage guide; must cover install, env vars, tool reference, and examples
7. **`CLAUDE.md`** — Claude-facing development guide; covers repo layout, key conventions, and how to work on this plugin safely
8. **`CHANGELOG.md`** — version history in Keep a Changelog format; version must stay in sync with all manifests
9. **`Dockerfile`** — container image definition; must not bake in env vars or secrets
10. **`docker-compose.yaml`** — local development and production Compose definition; wires env, ports, and volumes
11. **`entrypoint.sh`** — container startup script; handles signal trapping, env validation, and process launch
12. **`Justfile`** — task runner with canonical targets: `dev`, `test`, `lint`, `build`, `docker-build`, `docker-up`
13. **`.env.example`** — credential and config template with placeholder values; tracked in git, never contains real secrets
14. **ignore files** (`.gitignore`, `.dockerignore`) — exclude secrets, build artifacts, caches, and runtime state
15. **CI workflow** (`.github/workflows/ci.yaml`) — runs lint, type-check, tests, and Docker build on every PR

Plus: **live test scaffold** — at least one test that hits the real service; includes a skip guard for environments without credentials.

The three language layers are `~/workspace/plugin-templates/py/` (Python), `~/workspace/plugin-templates/rs/` (Rust), and `~/workspace/plugin-templates/ts/` (TypeScript). Use the layer that matches the target language for runtime and toolchain files.

Add commands, agents, skills, hooks, resources (MCP protocol: data exposed to the model, such as file contents or API responses), and prompts (MCP protocol: reusable prompt templates registered with the server) only when they are justified by the plugin's actual scope.

## Prefer Canonical Sources

Prefer the canonical shared template assets under `~/workspace/plugin-templates/` plus the selected language implementation layer over ad hoc file generation.

When both exist:

- use `~/workspace/plugin-templates/` for shared plugin-contract files
- use the selected `~/workspace/plugin-templates/<lang>/` directory for runtime and toolchain files
- specialize with plugin-specific names, ports, and env var names
- avoid inventing new layout or naming patterns

## Artifact Paths

When writing plan documents or report files, use the timestamp format `YYYYMMDD-HHMMSS` in the path. Example:

```
docs/scaffold-plans/<YYYYMMDD-HHMMSS>-<plugin-name>.md
```

## Required Output

At minimum, provide:

- the scaffolded files or the exact scaffold plan
- notable assumptions made
- unresolved questions
- any research-derived constraints that affect implementation

If you do not scaffold immediately, make the next execution step obvious and specific.

## Related Skills

- **tool-lab-plugin** — use for designing the MCP tool contract (action/subaction shape, parameter types, error handling) before scaffolding
- **deploy-lab-plugin** — use for Docker and Compose configuration after the scaffold is in place
- **pipeline-lab-plugin** — use for CI/CD workflow setup after the scaffold is in place
- **review-lab-plugin** — use post-scaffold to audit the result against the canonical spec
