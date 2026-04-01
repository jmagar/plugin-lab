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
- health endpoint
- `.env` as the runtime config source

## Research Before Scaffolding

Do not scaffold blindly from memory when the plugin depends on an SDK, protocol, or API that may have changed.

Review the supplied docs or repo context first. If the request depends on current SDK or protocol behavior, browse primary sources before finalizing the scaffold plan.

Focus research on:

- current MCP transport expectations
- latest language SDK patterns
- service authentication model
- required manifests and config files
- package manager and test tooling

## Produce a Scaffold Plan

Create a concrete plan before generating files.

The plan should cover:

- repo name
- language/runtime choice
- tool contract
- service layer shape
- manifest set
- command, skill, and agent surfaces
- test strategy
- Docker/runtime strategy

Prefer a written plan when the plugin is new or the requirements are fuzzy.

## Scaffold to Canonical Shape

Generate or update the plugin to include these baseline surfaces:

- package manifest
- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`
- `.mcp.json`
- `.app.json`
- `README.md`
- `CLAUDE.md`
- `CHANGELOG.md`
- `Dockerfile`
- `docker-compose.yaml`
- `entrypoint.sh`
- `Justfile`
- `.env.example`
- ignore files
- CI workflow
- live test scaffold

Add commands, agents, skills, hooks, resources, prompts, and services only when they are justified by the plugin's actual scope.

## Prefer Canonical Sources

Prefer the canonical shared template assets under `~/workspace/plugin-templates/` plus the selected language implementation layer under `~/workspace/plugin-templates/<lang>/` over ad hoc file generation.

When both exist:

- use `~/workspace/plugin-templates/` for shared plugin-contract files
- use the selected `~/workspace/plugin-templates/<lang>/` directory for runtime and toolchain files
- specialize with plugin-specific names and config
- avoid inventing new layout or naming patterns

## Required Output

At minimum, provide:

- the scaffolded files or the exact scaffold plan
- notable assumptions
- unresolved questions
- any research-derived constraints that affect implementation

If you do not scaffold immediately, make the next execution step obvious and specific.
