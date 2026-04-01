---
description: Scaffold a new lab plugin with a spec-conforming plan
argument-hint: <plugin-name> [short description]
allowed-tools: Read, Write, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, Skill
---

# Create Lab Plugin

Invoke the `scaffold-lab-plugin` skill, then spawn `ster-the-scaffolder` to plan and build the plugin described in `$ARGUMENTS`.

## Inputs

Parse `$ARGUMENTS` as: `<plugin-name> [short description]`

If any of these are missing, ask before proceeding:

- plugin name
- short description
- target language (if known)
- links or local paths for docs, repos, SDKs, or OpenAPI specs

## Workflow

1. Invoke the `scaffold-lab-plugin` skill.
2. Spawn `ster-the-scaffolder` with all gathered inputs.
3. Direct Ster to:
   - inspect any provided docs or repo context
   - dispatch up to three parallel `rex-the-researcher` workers when current-state research is needed
   - synthesize research into a concrete, ordered scaffold plan
   - produce the plan as a written document when the plugin is net new or requirements are incomplete

## Required Output

Ster must return:

- the normalized plugin name
- the assumed language/runtime
- the research summary
- the scaffold plan with ordered implementation steps
- the exact first implementation action
