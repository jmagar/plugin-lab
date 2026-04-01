---
description: Create a new lab plugin scaffold plan using Ster the Scaffolder
argument-hint: <plugin-name> [short description]
allowed-tools: Read, Write, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, Skill
---

# Create Lab Plugin

Use the `scaffold-lab-plugin` skill and `ster-the-scaffolder` agent to drive new plugin creation.

## Inputs

Start from `$ARGUMENTS`.

If any of these are missing, ask for them before proceeding:

- plugin name
- short description
- target language if already known
- links or local paths for docs, repos, SDKs, OpenAPI specs, or examples

## Workflow

1. Read [skills/scaffold-lab-plugin/SKILL.md](/home/jmagar/workspace/plugin-templates/skills/scaffold-lab-plugin/SKILL.md).
2. Spawn `ster-the-scaffolder`.
3. Tell Ster to:
   - gather any missing inputs
   - inspect the provided docs and repo context
   - dispatch three parallel `rex-the-researcher` workers when current-state research is needed
   - synthesize the research into a concrete scaffold plan
   - use the writing-plans workflow to produce the implementation plan

## Required Output

Ster should return:

- the normalized plugin name
- the assumed language/runtime
- the research summary
- the scaffold plan
- the exact next implementation step

Prefer a written plan when the plugin is net new or the requirements are incomplete.
