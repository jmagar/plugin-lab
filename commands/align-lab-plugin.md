---
description: Align an existing plugin to the canonical lab/plugin spec
argument-hint: <plugin-path>
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, Skill, WebSearch, WebFetch
---

# Align Lab Plugin

Use the `align-lab-plugin` skill and `ally-the-aligner` agent to bring a plugin to the canonical spec.

## Inputs

Treat `$ARGUMENTS` as the target plugin path.

If no path is provided, ask for it.

## Workflow

1. Read [skills/align-lab-plugin/SKILL.md](/home/jmagar/workspace/plugin-templates/skills/align-lab-plugin/SKILL.md).
2. Spawn `ally-the-aligner`.
3. Tell Ally to:
   - start from an existing review report if one exists
   - otherwise perform a quick spec audit first
   - dispatch:
     - one `roddy-reviewer` for structural/spec drift
     - one `rex-the-researcher` for current runtime/schema drift
     - one `ster-the-scaffolder` for template parity comparison
   - synthesize the evidence into an alignment plan
   - implement the alignment while preserving justified deviations

## Required Artifact

Write the alignment summary to:

- `docs/reports/plugin-alignments/<timestamp>.md`

It must include:

- changed files
- preserved deviations
- verification commands
- follow-up work
