# Skill Definitions -- plugin-lab

plugin-lab has 8 skills, each defining the operating procedure for a phase of plugin development. Agents read their corresponding skill before acting.

## Skill Summary

| Skill | Directory | Agent | Command | Reference files |
| --- | --- | --- | --- | --- |
| scaffold-lab-plugin | `skills/scaffold-lab-plugin/` | ster-the-scaffolder | `/create-lab-plugin` | scaffold-plan-template.md, surface-to-template-map.md |
| review-lab-plugin | `skills/review-lab-plugin/` | roddy-reviewer | `/review-lab-plugin` | canonical-spec.md, review-report-template.md |
| align-lab-plugin | `skills/align-lab-plugin/` | ally-the-aligner | `/align-lab-plugin` | alignment-report-template.md, alignment-targets.md, verification-commands.md |
| tool-lab-plugin | `skills/tool-lab-plugin/` | tilly-the-toolsmith | `/tool-lab-plugin` | canonical-error-shape.md, dispatch-table-patterns.md, help-tool-template.md |
| deploy-lab-plugin | `skills/deploy-lab-plugin/` | dex-the-deployer | `/deploy-lab-plugin` | compose-healthcheck.md, dockerfile-patterns.md |
| pipeline-lab-plugin | `skills/pipeline-lab-plugin/` | petra-the-pipeliner | `/pipeline-lab-plugin` | ci-workflow-template.md, live-test-guard-pattern.md |
| lab-research-specialist | `skills/lab-research-specialist/` | rex-the-researcher | `/research-lab-plugin` | approved-sources.md |
| setup | `skills/setup/` | (none) | `/setup-homelab` | service-credentials-guide.md |

## Skill Details

### scaffold-lab-plugin

**Purpose:** Create a new MCP plugin scaffold aligned to the homelab canonical plugin spec.

**Trigger phrases:** "create a new plugin", "scaffold a plugin in Python/Rust/TypeScript", "turn these docs into a plugin plan"

**Inputs gathered:**
- Plugin name, short description
- Target language (python, rust, typescript)
- Primary service being wrapped
- Links to docs, SDKs, OpenAPI specs
- Transport preference (dual by default)

**Default assumptions:** Dual transport (HTTP + stdio), one primary tool with action+subaction, `*_help` companion, Docker + Compose, Claude and Codex manifests, bearer auth, `/health` endpoint, `.env` config.

**Process:**
1. Gather missing inputs
2. Research current SDK/protocol state if needed
3. Write a scaffold plan covering 15 baseline surfaces
4. Implement from canonical templates

**Canonical surfaces (15):** Package manifest, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.mcp.json`, `.app.json`, `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `Dockerfile`, `docker-compose.yaml`, `entrypoint.sh`, `Justfile`, `.env.example`, ignore files, CI workflow. Plus live test scaffold.

**Reference files:**
- `references/scaffold-plan-template.md` -- Fill-in-the-blanks plan structure
- `references/surface-to-template-map.md` -- Maps each surface to its template file

### review-lab-plugin

**Purpose:** Review a plugin for alignment with the homelab canonical plugin spec.

**Trigger phrases:** "review this plugin", "audit for spec drift", "compare to canonical manifests"

**Process:**
1. Inspect the target plugin tree
2. Read each canonical file
3. Compare against the spec (see `references/canonical-spec.md`)
4. Classify every misalignment with severity, file reference, and fix
5. Write report to `docs/reports/plugin-reviews/<YYYYMMDD-HHMMSS>.md`

**Check categories:** Missing files, wrong locations, version drift, incorrect userConfig, transport mismatch, missing auth, missing `/health`, missing `*_help` tool, missing live tests, stale docs, ignore file drift.

**Severity levels:** CRITICAL (plugin won't load), HIGH (runtime contract violated), MEDIUM (spec drift degrading usability), LOW (hygiene/cosmetic).

**Reference files:**
- `references/canonical-spec.md` -- Authoritative correct values for every check
- `references/review-report-template.md` -- Report structure template

### align-lab-plugin

**Purpose:** Bring an existing plugin into alignment with the canonical spec.

**Trigger phrases:** "align this plugin", "update to current standard", "implement review findings"

**Ten alignment targets (priority order):**
1. Manifests and version sync
2. `.env.example` and runtime contract
3. Dockerfile (multi-stage, non-root)
4. `docker-compose.yaml` (env_file, healthcheck)
5. `entrypoint.sh` (env var validation)
6. Justfile (canonical targets)
7. Hook scripts and hook config
8. CI workflows
9. Live tests
10. README, CLAUDE, commands, agents, skills

**Process:**
1. Start from review report or perform quick audit
2. Write alignment plan separating required fixes, optional improvements, justified deviations, open questions
3. Implement in order: manifests, runtime, tests/CI, docs
4. Write summary to `docs/reports/plugin-alignments/<YYYYMMDD-HHMMSS>.md`

**Reference files:**
- `references/alignment-report-template.md` -- Report structure
- `references/alignment-targets.md` -- Detailed correct/drift examples for each target
- `references/verification-commands.md` -- Concrete validation commands

### tool-lab-plugin

**Purpose:** Design and implement MCP tools using the action+subaction dispatch pattern.

**Trigger phrases:** "add a tool for managing X", "review existing tools", "refactor flat tools into action+subaction"

**The action+subaction pattern:**
- `action` -- high-level resource (e.g., `message`, `application`)
- `subaction` -- specific verb (e.g., `create`, `list`, `delete`)
- Additional parameters validated after dispatch
- Companion `*_help` tool lists all valid combinations

**Modes:** `create` (new tool from scratch), `review` (audit for conformance), `update` (targeted changes).

**Canonical error shape:**
```json
{
  "isError": true,
  "content": [{"type": "text", "text": "Error: action/subaction failed -- reason"}]
}
```

**Reference files:**
- `references/canonical-error-shape.md` -- Error shape with language-specific helpers
- `references/dispatch-table-patterns.md` -- Dispatch patterns for Python, Rust, TypeScript
- `references/help-tool-template.md` -- Full `*_help` tool structure and example

### deploy-lab-plugin

**Purpose:** Containerize a plugin with Docker and Docker Compose.

**Trigger phrases:** "Dockerize my plugin", "containerize my MCP server", "set up Compose"

**Canonical container shape:**
- Multi-stage Dockerfile (builder + minimal runtime)
- Non-root user in runtime stage
- `/health` endpoint on HTTP port returning HTTP 200
- Config from environment variables only -- no baked secrets
- `entrypoint.sh` with env var validation
- `docker-compose.yaml` with `env_file`, healthcheck, named volumes
- `.dockerignore`

**Default assumptions:** Port 8080, `env_file: .env`, healthcheck interval 30s/timeout 10s/retries 3.

**Reference files:**
- `references/compose-healthcheck.md` -- Healthcheck patterns and defaults
- `references/dockerfile-patterns.md` -- Multi-stage patterns for all three languages

### pipeline-lab-plugin

**Purpose:** Implement the full CI/CD pipeline for a plugin.

**Trigger phrases:** "set up CI pipeline", "add automated releases", "sync Justfile with CI"

**Four workflow files:**
1. `ci.yaml` -- lint, type-check, test gate (sequential via `needs:`)
2. `publish-image.yaml` -- Docker image build + push to GHCR with full tag strategy
3. `release-on-main.yaml` -- Manifest version read, tag check, tag + GitHub release
4. Pre-commit config -- `.pre-commit-config.yaml` (Python) or `lefthook.yml` (Rust/TS)

**Plus:** Justfile targets (`lint`, `type-check`, `test`, `test-live`, `build`, `push`) that mirror CI steps.

**Live test guard:** Tests requiring external services are skipped in CI via `SKIP_LIVE_TESTS=1`. Language-specific patterns: pytest markers (Python), feature flags (Rust), env var checks (TypeScript).

**Reference files:**
- `references/ci-workflow-template.md` -- Full workflow templates for all languages
- `references/live-test-guard-pattern.md` -- Guard patterns for Python, Rust, TypeScript

### lab-research-specialist

**Purpose:** Research current primary-source guidance for MCP, SDKs, and plugin specs.

**Trigger phrases:** "what changed in the MCP SDK", "is this transport pattern current", "find latest docs for X"

**Research scope:** MCP protocol, Claude Code plugins, Codex plugins, Python/Rust/TypeScript SDKs, FastMCP, Docker guidance, GitHub Actions, auth patterns.

**Source priority:** Official specs > SDK repos > registry entries > release notes > local repo materials (context only, never proof of currency).

**Five-step workflow:**
1. Define exact questions
2. Gather primary-source evidence
3. Compare against local canonical assets
4. Separate facts from recommendations
5. Summarize implications with specific file/field changes

**Output buckets:** Confirmed facts, changes from prior assumptions, implications for templates, implications for existing plugins, open uncertainties.

**Reference files:**
- `references/approved-sources.md` -- Curated list of authoritative primary sources

### setup

**Purpose:** Interactive credential setup wizard for `~/.claude-homelab/.env`.

**Trigger phrases:** "setup credentials", "configure plex", "add my API key", "I just installed homelab-core"

**Wizard flow:**
1. Ask which services the user runs (18 services across infrastructure, media, downloads, utilities)
2. For each selected service, collect credentials one at a time using safe upsert pattern
3. Verify and offer health check

**Security rules:** Never print/echo credentials, never show `.env` contents, always `chmod 600` after writes.

**Reference files:**
- `references/service-credentials-guide.md` -- Per-service credential locations and instructions

## Skill Directory Structure

Every skill follows this layout:

```
skills/<name>/
  SKILL.md          # Operating procedure (required)
  references/       # Supporting reference docs
    *.md            # Detailed patterns, templates, specs
  scripts/          # Executable scripts (setup skill only)
```

## SKILL.md Frontmatter

```yaml
---
name: skill-name
description: |
  What this skill does and when to activate it.
  Trigger phrases listed here.
---
```

Only `name` and `description` are supported fields. Do not add `version` or other unsupported fields.
