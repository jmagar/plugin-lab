---
description: Implement or update the full CI/CD pipeline for a lab plugin
argument-hint: <plugin-path> [create|review|update]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, Skill
---

# Pipeline Lab Plugin

Use the `pipeline-lab-plugin` skill and `petra-the-pipeliner` agent to implement or update a plugin's CI/CD pipeline.

## Inputs

Start from `$ARGUMENTS`.

Parse as: `<plugin-path> [mode]`

- `mode` defaults to `create` if not specified
- For `update`, inspect the existing `.github/workflows/ci.yaml` first

If the plugin path is missing, ask before proceeding.

## Workflow

1. Read [skills/pipeline-lab-plugin/SKILL.md](/home/jmagar/workspace/plugin-templates/skills/pipeline-lab-plugin/SKILL.md).
2. Spawn `petra-the-pipeliner`.
3. Tell Petra to:
   - inspect the plugin's language, package manifest, and existing CI config
   - for `create`: gather registry, trigger strategy, and secret requirements, then produce the full pipeline
   - for `review`: audit existing pipeline against canonical stage order and produce a findings list
   - for `update`: make targeted changes and keep Justfile targets in sync
   - dispatch a `rex-the-researcher` worker to confirm current GitHub Action versions if needed

## Required Output

Petra should return:

- `.github/workflows/ci.yaml`
- relevant Justfile targets (`lint`, `type-check`, `test`, `build`, `push`)
- required secrets list with descriptions
- any assumptions about the registry or live test environment
