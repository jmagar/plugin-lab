---
description: Align an existing plugin to the canonical lab/plugin spec
argument-hint: <plugin-path>
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, Skill, WebSearch, WebFetch
---

# Align Lab Plugin

Invoke the `align-lab-plugin` skill, then spawn `ally-the-aligner` to bring the plugin at `$ARGUMENTS` to the canonical spec.

## Inputs

`$ARGUMENTS` is the target plugin path. Ask for it if absent.

## Workflow

1. Invoke the `align-lab-plugin` skill.
2. Spawn `ally-the-aligner` with the plugin path.
3. Direct Ally to:
   - start from an existing review report if one exists in `docs/reports/plugin-reviews/`
   - otherwise dispatch in parallel:
     - one `roddy-reviewer` for structural/spec drift
     - one `rex-the-researcher` for current runtime/schema drift
     - one `ster-the-scaffolder` for template parity comparison
   - synthesize the evidence into an alignment plan
   - implement the alignment while preserving justified deviations

## Required Artifact

Write the alignment summary to:

- `docs/reports/plugin-alignments/<YYYYMMDD-HHMMSS>.md`

Include: changed files, preserved deviations, verification commands, and follow-up work.
