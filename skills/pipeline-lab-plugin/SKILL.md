---
name: pipeline-lab-plugin
description: Implement or update the full CI/CD pipeline for a lab plugin. Use when the user wants to add GitHub Actions workflows, set up lint/type-check/test/build/push stages, configure environment secrets, or audit an existing pipeline for drift against the canonical plugin CI pattern.
---

# Pipeline Lab Plugin

Implement a complete CI/CD pipeline for a lab plugin following the canonical homelab plugin pattern.

## Canonical Pipeline Shape

A conforming plugin pipeline has these stages in order:

1. **lint** — code style and static analysis (ruff, clippy, biome/eslint)
2. **type-check** — type safety (mypy, tsc --noEmit)
3. **test** — unit and live integration tests (pytest, cargo test, vitest)
4. **build** — Docker image build (multi-stage, platform matrix if needed)
5. **push** — push image to registry on main or tag trigger
6. **release** — create GitHub release and update CHANGELOG on tag

Stages run sequentially; build is skipped on PR unless explicitly enabled.

## Gather Inputs First

Before writing or updating pipeline files, collect:

- plugin name and language (`python`, `rust`, `typescript`)
- Docker registry and image name
- trigger strategy (push to main, PR, tag)
- required secrets (registry credentials, service tokens for live tests)
- whether live integration tests require a running service
- current CI file location if updating

If inputs are missing, ask before generating files.

## Prefer Canonical Templates

Use `~/workspace/plugin-templates/<lang>/` CI files as the base. Specialize with:

- the plugin's image name
- the correct package manager commands
- the live test toggle (skip if service unavailable)
- the registry secret names

Avoid inventing new job names or step ordering.

## Implementing the Pipeline

Produce in order:

1. **Workflow file** — `.github/workflows/ci.yaml` with all stages
2. **Justfile targets** — `lint`, `type-check`, `test`, `build`, `push` targets that mirror CI locally
3. **Required secrets list** — document which secrets must be added in the repo settings
4. **Live test guard** — show how to skip live tests when the target service is unavailable

## Reviewing an Existing Pipeline

Check for:

- missing stages (commonly: type-check skipped, push not gated on test)
- hardcoded credentials or tokens
- no live test toggle
- image tag strategy not pinned (`:latest` only)
- no matrix for multi-platform builds when the plugin targets ARM
- Justfile targets missing or inconsistent with CI steps

Produce a findings list before making changes.

## Updating a Pipeline

When modifying:

1. Identify the specific gap (missing stage, wrong trigger, secret name drift)
2. Make a targeted change — avoid rewriting the whole file unless necessary
3. Verify Justfile targets stay in sync with updated CI steps
4. Document new secrets in `README.md` if they were added

## Required Output

At minimum:

- the `.github/workflows/ci.yaml` file
- the relevant Justfile targets
- the required secrets list
- any assumptions about the registry or live test environment
