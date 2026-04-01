---
name: review-lab-plugin
description: Review an MCP plugin against the homelab canonical plugin spec and identify any and all misalignments. Use when the user wants a plugin audited for spec drift, wants to compare a plugin to canonical manifests and runtime patterns, wants to know whether deviations are documented and justified, or wants a detailed plugin review report.
---

# Review Lab Plugin

Review a plugin for alignment with the homelab canonical plugin spec.

## Review Goal

Find mismatches between the target plugin and the current canonical standard.

Treat the review as a spec audit, not a style pass.

Focus on:

- correctness
- structural drift
- runtime contract drift
- missing required files
- stale manifests
- undocumented or unjustified deviations

## Read the Canonical Surfaces

Review the target plugin's canonical files first when present:

- `README.md`
- project manifest
- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`
- `.mcp.json`
- `.app.json`
- `CLAUDE.md`
- `AGENTS.md`
- `CHANGELOG.md`
- `Dockerfile`
- `docker-compose.yaml`
- `Justfile`
- `.env.example`
- hook config
- CI workflow
- live test script

Also inspect the repo tree so you can reason about missing or misplaced surfaces.

## Compare Against the Spec

Check for:

- missing required files
- wrong file locations
- version drift across manifests
- incorrect userConfig shape
- transport mismatch
- missing auth, health, or rate-limit expectations
- missing help tool or action pattern
- missing live test coverage
- stale README or CLAUDE guidance
- ignore file and Docker hygiene drift

## Classify Every Misalignment

For each finding, state:

- what is misaligned
- where it appears
- what the canonical expectation is
- whether the deviation is documented
- whether the deviation appears justified

Do not treat every difference as a bug. A deviation may be acceptable if it is deliberate, documented, and technically justified.

## Produce a Written Report

Write the final review to:

- `docs/reports/plugin-reviews/<timestamp>.md`

Include:

- target plugin path
- review date
- files inspected
- findings ordered by severity
- documented deviations
- justified deviations
- open questions
- concrete remediation list

## Output Style

Findings first.

Each finding should include:

- severity
- file path
- concise explanation
- recommended fix

Keep the report detailed and complete enough that another agent can implement the fixes without repeating the audit.
