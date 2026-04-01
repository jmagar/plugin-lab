# Plugin Alignment Report

**Date**: YYYYMMDD-HHMMSS
**Plugin**: `<plugin-name>`
**Performed by**: align-lab-plugin skill

---

## Source Plugin Path

```
/path/to/plugin-repo
```

## Canonical Sources Used

| Source | Purpose |
|--------|---------|
| `~/workspace/plugin-templates/` | Shared plugin-contract files (hooks, CI structure, check scripts) |
| `~/workspace/plugin-templates/<lang>/` | Language-specific runtime files (Dockerfile, entrypoint, Justfile) |
| `<other-reference>` | `<reason>` |

---

## Files Changed

| File | Change | Reason |
|------|--------|--------|
| `.claude-plugin/plugin.json` | Updated `version` from `0.1.0` to `1.2.0` | Version was frozen; bumped to match `package.json` and latest git tag |
| `docker-compose.yaml` | Added `healthcheck` stanza | Was absent; required by canonical spec |
| `entrypoint.sh` | Added validation for `MISSING_VAR` | Variable was read in application code but not validated at startup |
| `.github/workflows/ci.yaml` | Pinned action versions to SHA | `@main` refs are non-reproducible |
| `.env.example` | Added `NEW_REQUIRED_VAR` entry | Variable present in entrypoint but undocumented |
| `<file>` | `<change>` | `<reason>` |

---

## Preserved Deviations

Deviations from the canonical template that were intentionally kept:

| File | Deviation | Reason Preserved |
|------|-----------|-----------------|
| `Dockerfile` | Uses `python:3.12-slim` instead of `python:3.11-slim` | Plugin requires a library that dropped 3.11 support in its latest release |
| `Justfile` | `test` target uses `pytest -x` instead of bare `pytest` | Plugin author prefers fail-fast mode; no correctness impact |
| `<file>` | `<deviation>` | `<reason>` |

---

## Open Questions / Follow-up Work

Items that could not be resolved during this alignment pass:

- [ ] `<item>` — needs user input: `<what is needed>`
- [ ] `<item>` — deferred: `<why>`
- [ ] Live test coverage: tests exist but exercise only the `/health` endpoint; full tool-call coverage is follow-up work

---

## Verification Commands Run

List each command run and its outcome. Mark any check that was deferred.

```bash
# Manifest validation
jq . .claude-plugin/plugin.json
# Result: valid JSON, no errors

# Version sync check
grep -rn '"version"' .claude-plugin/plugin.json package.json
# Result: both show "1.2.0"

# Shell syntax check
bash -n entrypoint.sh
# Result: no errors

# YAML lint
yamllint .github/workflows/ci.yaml
# Result: no warnings

# Compose config validation
docker compose config --quiet
# Result: config is valid

# Env var coverage check
# Result: all vars in entrypoint.sh are documented in .env.example
```

**Deferred checks** (require running container or network):

- [ ] Live test run (`just test`) — deferred, requires service dependencies
- [ ] `/health` endpoint probe — deferred, requires container build

---

## Summary

Brief narrative of what was done, what the plugin's state was before, and what it is now:

> Before alignment: `<one sentence describing the main issues>`.
> After alignment: `<one sentence describing current state>`.
> Remaining gaps: `<one sentence or "none">`.
