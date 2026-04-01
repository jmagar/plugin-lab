---
name: align-lab-plugin
description: Bring an existing MCP plugin into full alignment with the homelab canonical plugin spec. Use when the user wants to update a plugin to current standards, replace stale scaffolding with the `plugin-templates` repo, reconcile manifest drift, standardize Docker and CI files, or turn a review report into a concrete alignment plan and implementation.
---

# Align Lab Plugin

Align an existing plugin to the current homelab canonical spec.

## Default Assumptions

When the user does not provide full context, assume:

- If no review report exists, perform a quick structural audit of all canonical surfaces before writing a plan
- The canonical source of truth for shared plugin-contract files is `~/workspace/plugin-templates/`
- Language-specific files come from `~/workspace/plugin-templates/py/`, `~/workspace/plugin-templates/rs/`, or `~/workspace/plugin-templates/ts/` depending on the plugin's runtime
- Preserve any deviation that is clearly intentional, documented, and still valid — do not erase differences simply because they differ from the template
- If the user says "align my plugin," treat all 10 surfaces as in scope unless they narrow the request

## Start From Evidence

Do not begin editing from vague assumptions.

Start with one of:

- a fresh plugin review (run review-lab-plugin if no report exists)
- an existing review report from `docs/reports/plugin-reviews/`
- a concrete list of files the user wants aligned

If no review exists, perform a quick audit of the canonical surfaces before planning edits. Check that the key files are present and structurally sound before committing to a full alignment plan.

## Alignment Targets

Prioritize these ten surfaces in order:

### 1. Manifests and Version Sync

Correct alignment means `plugin.json` (or `Cargo.toml` / `pyproject.toml` / `package.json`) carries the same version string as the Git tag and as any version field in `CHANGELOG.md`. The `name`, `description`, and `mcp_version` fields match the canonical schema. Drift looks like a `plugin.json` version frozen at `0.1.0` while the package manifest is at `1.3.0`, or a `mcp_version` field referencing a superseded protocol revision.

### 2. `.env.example` and Runtime Contract

Correct alignment means every environment variable the plugin reads at runtime appears in `.env.example` with a descriptive placeholder value and an inline comment explaining what it does. Drift looks like variables present in `entrypoint.sh` or application code that are absent from `.env.example`, or stale variables in `.env.example` that the application no longer reads.

### 3. Dockerfile

Correct alignment means a two-stage build: a builder stage that compiles or installs dependencies, and a minimal runtime stage that copies only the production artifact and runs as a non-root user. Drift looks like a single-stage build that ships compilers and dev dependencies into the final image, a `USER root` in the runtime stage, or base images pinned to `latest` instead of a digest or minor-version tag.

### 4. `docker-compose.yaml`

Correct alignment means the service stanza references `env_file: .env`, defines a `healthcheck` with the canonical interval/timeout/retries defaults, exposes only the required port, and uses named volumes for any persistent data. Drift looks like inline `environment:` blocks that duplicate `.env.example` values, a missing `healthcheck`, or bind-mounts to absolute host paths that break portability.

### 5. `entrypoint.sh`

Correct alignment means the script validates every variable listed in `.env.example` before starting the server, exits with a non-zero code and a clear error message for any missing variable, and ends with `exec "$@"` or an equivalent direct handoff to the server process. Drift looks like missing variable checks, silent failures when a required var is unset, or a `sleep`-loop health-wait that masks startup errors.

### 6. `Justfile`

Correct alignment means the canonical targets exist: `build`, `up`, `down`, `logs`, `test`, `lint`, and `clean`. Each target delegates to the correct underlying tool (Docker Compose, the language test runner, etc.) with no hardcoded project-specific paths that would break in another repo. Drift looks like missing targets, targets that call `docker-compose` (v1 binary) instead of `docker compose` (v2 plugin), or targets with inline logic that belongs in a script.

### 7. Hook Scripts and Hook Config

Correct alignment means `hooks.json` (or `lefthook.yml`) references only scripts that exist under `hooks/scripts/`, every referenced script is executable, and the hooks cover at minimum: env-file permission check, no-baked-env check, and ignore-file sync. Drift looks like hook entries pointing to deleted scripts, hooks that are defined but never triggered because the glob is wrong, or missing hooks that allow `.env` to be committed.

### 8. CI Workflows

Correct alignment means `.github/workflows/ci.yaml` runs lint, test, and build on every pull request, uses the canonical job structure from `~/workspace/plugin-templates/ts/` (or `py/` or `rs/`), and pins action versions to a SHA or tagged release. Drift looks like workflows that only run on push to main, unpinned `@main` action references, or a workflow that skips the build step and ships untested code.

### 9. Live Tests

Correct alignment means `tests/test_live.sh` (or the language-equivalent) exercises at least one real tool call against a running container, asserts a non-error HTTP response from `/health`, and exits non-zero on failure. Drift looks like a test file that is present but contains only `echo "TODO"`, tests that require manual env setup with no documented steps, or tests that always pass because they never assert anything.

### 10. README, CLAUDE, Commands, Agents, and Skills

Correct alignment means `README.md` covers installation, configuration (referencing `.env.example`), and usage; `CLAUDE.md` describes the plugin's tools and any gotchas for AI assistants; any slash commands in `commands/` have correct frontmatter; agents in `agents/` reference real tool names. Drift looks like a README that describes a different plugin's setup flow, a `CLAUDE.md` that lists tool names that no longer exist, or command files with stale `allowed-tools` entries.

## Use Canonical Sources

When aligning files:

- prefer `~/workspace/plugin-templates/` for shared plugin-contract files (hooks, CI structure, check scripts)
- prefer `~/workspace/plugin-templates/py/`, `~/workspace/plugin-templates/rs/`, or `~/workspace/plugin-templates/ts/` for runtime and language-toolchain files
- keep justified plugin-specific differences
- remove stale or duplicated custom scaffolding that duplicates template content without adding value

Do not erase a deviation just because it differs. Preserve it when it is clearly intentional and still valid. Document preserved deviations in the alignment report.

## Plan Before Editing

Write a concrete alignment plan before making broad edits.

The plan must separate:

- **required fixes** — gaps that would cause the plugin to fail validation or behave incorrectly
- **optional improvements** — style or consistency issues that are low-risk
- **justified deviations to preserve** — intentional differences with a documented reason
- **open questions requiring user input** — ambiguities that cannot be resolved from the files alone

## Implement Safely

Make changes in an order that reduces churn:

1. manifests and config contract
2. runtime and Docker files
3. tests and CI
4. docs and AI-facing files

Do not claim full alignment unless the final files and verification steps support it.

## Produce an Alignment Report

Write the alignment summary to:

- `docs/reports/plugin-alignments/YYYYMMDD-HHMMSS.md`

Use the template at `skills/align-lab-plugin/references/alignment-report-template.md`. Include:

- source plugin path
- canonical sources used
- files changed (table with file, change, reason)
- preserved deviations
- follow-up work
- verification commands run and their output

## Verification

Run the strongest available local checks after alignment. Use the concrete commands in `skills/align-lab-plugin/references/verification-commands.md`.

Required checks:

```bash
# Validate plugin manifest JSON is well-formed
jq . .claude-plugin/plugin.json

# Check version appears consistently
grep -r "\"version\"" plugin.json package.json pyproject.toml Cargo.toml 2>/dev/null

# Shell syntax check on all shell scripts
bash -n entrypoint.sh hooks/scripts/*.sh

# YAML lint on CI workflow
yamllint .github/workflows/ci.yaml

# Docker Compose config validation
docker compose config --quiet

# Env var coverage check (vars in entrypoint but not in .env.example)
grep -oE 'required_var "[A-Z_]+"' entrypoint.sh | sort
grep -oE '^[A-Z_]+=' .env.example | sort
```

State clearly what was and was not verified. If a check requires a running container or network access, note it as deferred.

## Related Skills

- **review-lab-plugin** — run before aligning; produces the review report this skill consumes
- **scaffold-lab-plugin** — canonical surface reference; use to understand what a greenfield plugin looks like
- **deploy-lab-plugin** — for Docker and Compose alignment specifically
- **pipeline-lab-plugin** — for CI workflow alignment specifically
