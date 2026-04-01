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

See `references/canonical-spec.md` for the authoritative correct values for every check category below.

## Read the Canonical Surfaces

Inspect the target plugin's tree first to know what exists and what is absent. Then read each canonical file when present:

- `README.md`
- project manifest (`pyproject.toml`, `Cargo.toml`, or `package.json`)
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
- CI workflow (`.github/workflows/ci.yaml`)
- live test script

Also inspect the repo tree so you can reason about missing or misplaced surfaces.

## Compare Against the Spec

Check for every category below. For the exact correct values in each category, consult `references/canonical-spec.md`.

- missing required files
- wrong file locations
- version drift across manifests
- incorrect userConfig shape
- transport mismatch
- missing auth on HTTP transport
- missing `/health` endpoint
- missing `*_help` tool or action/subaction pattern
- missing live test coverage
- stale README or CLAUDE guidance
- ignore file and Docker hygiene drift

## Classify Every Misalignment

For each finding, state:

- what is misaligned
- where it appears (file path and line if known)
- what the canonical expectation is
- whether the deviation is documented
- whether the deviation appears technically justified

Do not treat every difference as a bug. A deviation is acceptable if it is deliberate, documented, and technically justified.

## Open Questions

Some findings cannot be resolved by reading files alone. Flag these explicitly as **open questions** — issues that require user input or live service access to resolve before remediation can proceed.

Examples of open questions:

- "Is the second Unraid server still in use, or can its env vars be removed?"
- "What auth scheme does this service use — bearer token or API key header?"
- "The CHANGELOG shows v1.0.0 but plugin.json shows v1.1.0 — which is correct?"

Group open questions at the end of the report so the user can answer them before align-lab-plugin begins work.

## Produce a Written Report

Write the final review to:

```
docs/reports/plugin-reviews/<YYYYMMDD-HHMMSS>.md
```

Use the fill-in-the-blanks template in `references/review-report-template.md` for the report structure.

The report must include:

- target plugin path
- review date (YYYYMMDD-HHMMSS)
- files inspected
- findings ordered by severity (CRITICAL → HIGH → MEDIUM → LOW)
- documented deviations
- justified deviations
- open questions
- concrete remediation checklist ordered by priority

## Output Style

Findings first. Each finding uses this format:

```
**[HIGH] Missing /health endpoint**
File: src/server.py
Expected: GET /health returns HTTP 200 with {"status": "ok"}
Found: No /health route registered
Fix: Add health route before starting server
```

Severity levels:

- **CRITICAL** — plugin will not load or will break other plugins
- **HIGH** — runtime contract violated, integration will fail silently
- **MEDIUM** — spec drift that degrades usability or discoverability
- **LOW** — hygiene issue, documentation gap, or cosmetic drift

Keep the report detailed and complete enough that align-lab-plugin can implement all fixes without repeating the audit.

## Related Skills

- **align-lab-plugin** — consumes the review report and implements the remediation checklist
- **lab-research-specialist** — use to verify current canonical values when the spec may have changed
- **scaffold-lab-plugin** — reference for the canonical 15-surface list and correct plugin structure
