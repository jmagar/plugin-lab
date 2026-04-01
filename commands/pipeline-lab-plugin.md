---
description: Implement or update the full CI/CD pipeline for a lab plugin
argument-hint: <plugin-path> [create|review|update]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, Skill
---

# Pipeline Lab Plugin

Invoke the `pipeline-lab-plugin` skill, then spawn `petra-the-pipeliner` to implement or update the pipeline at `$ARGUMENTS`.

## Inputs

Parse `$ARGUMENTS` as: `<plugin-path> [mode]`

- `mode` defaults to `create` if not specified
- For `update`, read the existing `.github/workflows/` files before spawning

Ask for the plugin path if absent.

## Workflow

1. Invoke the `pipeline-lab-plugin` skill.
2. Spawn `petra-the-pipeliner` with the plugin path and mode.
3. Direct Petra to:
   - inspect the plugin's language, package manifest, and existing CI config
   - for `create`: gather registry, trigger strategy, and secret requirements, then produce all four workflow files
   - for `review`: audit each of the four workflow files against canonical shape; produce a findings list organized by file
   - for `update`: make targeted changes and keep Justfile targets in sync
   - dispatch a `rex-the-researcher` worker to confirm current GitHub Action versions if needed

## Required Output

- `.github/workflows/ci.yaml` — lint → type-check → test gate with live test skip guard
- `.github/workflows/publish-image.yaml` — image build + push, full tag strategy, GHA cache
- `.github/workflows/release-on-main.yaml` — manifest version → tag check → tag + GitHub release
- Pre-commit config — `.pre-commit-config.yaml` (Python) or `lefthook.yml` (Rust/TypeScript)
- Justfile targets — `lint`, `type-check`, `test`, `test-live`, `build`, `push`
- Required secrets list with descriptions
- Any assumptions about the registry or live test environment
