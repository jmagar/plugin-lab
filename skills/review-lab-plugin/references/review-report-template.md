# Plugin Review Report

<!-- Fill in all fields marked with angle brackets. Remove this comment before saving. -->

## Header

| Field | Value |
|-------|-------|
| **Plugin path** | `<absolute or repo-relative path to the plugin being reviewed>` |
| **Review date** | `<YYYYMMDD-HHMMSS>` |
| **Reviewer** | `<agent name or human name>` |
| **Spec reference** | `skills/review-lab-plugin/references/canonical-spec.md` |

---

## Files Inspected

| File | Present | Notes |
|------|---------|-------|
| `pyproject.toml` / `Cargo.toml` / `package.json` | ✅ / ❌ | `<version found or "absent">` |
| `.claude-plugin/plugin.json` | ✅ / ❌ | `<notes>` |
| `.codex-plugin/plugin.json` | ✅ / ❌ | `<notes>` |
| `.mcp.json` | ✅ / ❌ | `<notes>` |
| `.app.json` | ✅ / ❌ | `<notes>` |
| `README.md` | ✅ / ❌ | `<notes>` |
| `CLAUDE.md` | ✅ / ❌ | `<notes>` |
| `CHANGELOG.md` | ✅ / ❌ | `<notes>` |
| `Dockerfile` | ✅ / ❌ | `<notes>` |
| `docker-compose.yaml` | ✅ / ❌ | `<notes>` |
| `entrypoint.sh` | ✅ / ❌ | `<notes>` |
| `Justfile` | ✅ / ❌ | `<notes>` |
| `.env.example` | ✅ / ❌ | `<notes>` |
| `.gitignore` | ✅ / ❌ | `<notes>` |
| `.dockerignore` | ✅ / ❌ | `<notes>` |
| `.github/workflows/ci.yaml` | ✅ / ❌ | `<notes>` |
| Live test scaffold | ✅ / ❌ | `<notes>` |
| `<any additional files inspected>` | ✅ / ❌ | `<notes>` |

---

## Findings

Order by severity: CRITICAL first, then HIGH, MEDIUM, LOW.

| Severity | File | Description | Fix |
|----------|------|-------------|-----|
| `CRITICAL/HIGH/MEDIUM/LOW` | `<file path>` | `<concise description of what is wrong>` | `<concrete fix action>` |

### Detailed Findings

<!-- Expand each finding from the table above using this block format. -->

```
**[SEVERITY] Finding title**
File: <path>
Expected: <what canonical spec requires>
Found: <what actually exists>
Fix: <specific action to resolve>
```

<!-- Example:
**[HIGH] Missing /health endpoint**
File: src/server.py
Expected: GET /health returns HTTP 200 with {"status": "ok"}
Found: No /health route registered
Fix: Add health route before starting server
-->

---

## Documented Deviations

Deviations that exist and are explicitly documented somewhere in the plugin (README, CLAUDE.md, inline comment, etc.).

| Deviation | Documentation Location | Justification Summary |
|-----------|----------------------|----------------------|
| `<what differs from spec>` | `<file and section where it is documented>` | `<summary of stated reason>` |

_If none: "No documented deviations found."_

---

## Justified Deviations

Deviations that are not yet documented but appear technically sound based on the plugin's design. These should be documented by the plugin author but do not require remediation.

| Deviation | Technical Rationale |
|-----------|-------------------|
| `<what differs from spec>` | `<why it makes sense for this plugin>` |

_If none: "No additional justified deviations identified."_

---

## Open Questions

Questions that cannot be resolved by reading files alone. User input or live service access is required before remediation can proceed.

1. **`<question>`**
   - What is needed: `<specific information required>`
   - Who can answer: `<plugin author / service owner / user>`

2. **`<question>`**
   - What is needed: `<specific information required>`
   - Who can answer: `<plugin author / service owner / user>`

_If none: "No open questions."_

---

## Remediation Checklist

Ordered by priority. CRITICAL and HIGH items first. Check off items as align-lab-plugin completes them.

- [ ] **[CRITICAL]** `<specific action>` — `<file to change>`
- [ ] **[HIGH]** `<specific action>` — `<file to change>`
- [ ] **[HIGH]** `<specific action>` — `<file to change>`
- [ ] **[MEDIUM]** `<specific action>` — `<file to change>`
- [ ] **[LOW]** `<specific action>` — `<file to change>`
- [ ] Answer open questions before proceeding with items that depend on them (see Open Questions section)

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | `<n>` |
| HIGH | `<n>` |
| MEDIUM | `<n>` |
| LOW | `<n>` |
| **Total findings** | `<n>` |
| Documented deviations | `<n>` |
| Justified deviations | `<n>` |
| Open questions | `<n>` |
