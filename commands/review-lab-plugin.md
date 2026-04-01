---
description: Review a plugin against the canonical lab/plugin spec and write a report
argument-hint: <plugin-path>
allowed-tools: Read, Write, Bash, Glob, Grep, Task, Skill
---

# Review Lab Plugin

Use the `review-lab-plugin` skill and `roddy-reviewer` agent to audit a plugin against the canonical spec.

## Inputs

Treat `$ARGUMENTS` as the target plugin path.

If no path is provided, ask for it.

## Baseline Inspection

Before spawning reviewers, inspect the target plugin and gather context from:

- `README.md`
- project manifest
- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`
- `.mcp.json`
- `.app.json`
- `CLAUDE.md`
- `AGENTS.md`
- `CHANGELOG.md`
- `docker-compose.yaml`
- `.env.example`
- `Dockerfile`
- `Justfile`

Also run:

```bash
tree -a -L 4 "$ARGUMENTS"
```

## Workflow

1. Read [skills/review-lab-plugin/SKILL.md](/home/jmagar/workspace/plugin-templates/skills/review-lab-plugin/SKILL.md).
2. Spawn three parallel `roddy-reviewer` agents.
3. Give each reviewer the plugin path and the same baseline file set.
4. Ask each reviewer to identify:
   - all meaningful misalignments
   - whether the deviation is documented
   - whether the deviation appears justified
5. Synthesize the three review passes into one final report.

## Required Artifact

Write the merged report to:

- `docs/reports/plugin-reviews/<timestamp>.md`

The report must list findings first and include file references wherever possible.
