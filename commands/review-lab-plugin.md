---
description: Audit a plugin against the canonical spec and write a report
argument-hint: <plugin-path>
allowed-tools: Read, Write, Bash, Glob, Grep, Task, Skill
---

# Review Lab Plugin

Invoke the `review-lab-plugin` skill, then spawn `roddy-reviewer` agents to audit the plugin at `$ARGUMENTS`.

## Inputs

`$ARGUMENTS` is the target plugin path. Ask for it if absent.

## Baseline Inspection

Before spawning reviewers, gather context from the plugin directory:

!`tree -a -L 4 "$ARGUMENTS"`

Read these files if present:

- `README.md`, `CLAUDE.md`, `AGENTS.md`, `CHANGELOG.md`
- `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.mcp.json`, `.app.json`
- `docker-compose.yaml`, `Dockerfile`, `.env.example`, `Justfile`

## Workflow

1. Invoke the `review-lab-plugin` skill.
2. Spawn three parallel `roddy-reviewer` agents.
3. Give each reviewer the plugin path and the same baseline file set.
4. Direct each reviewer to identify:
   - all meaningful misalignments
   - whether the deviation is documented
   - whether the deviation appears justified
5. Synthesize the three passes into one final report.

## Required Artifact

Write the merged report to:

- `docs/reports/plugin-reviews/<YYYYMMDD-HHMMSS>.md`

List findings first. Include file references wherever possible.
