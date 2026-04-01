---
name: pipeline-lab-plugin
description: Implement or update the full CI/CD pipeline for a lab plugin. Use when the user wants to add or update GitHub Actions workflows (ci.yaml, publish-image.yaml, release-on-main.yaml), configure pre-commit or lefthook, set up automated releases, audit an existing pipeline for drift, or sync Justfile targets with CI steps.
---

# Pipeline Lab Plugin

Implement the complete CI/CD pipeline for a lab plugin. A conforming plugin has four workflow files, not one.

## The Four Workflow Files

Every canonical lab plugin has all four of these:

### 1. `ci.yaml` — Test Gate
Runs on every PR and push to main. Stages in order:
1. **lint** — code style and static analysis (ruff, clippy, biome/eslint)
2. **type-check** — type safety (mypy/ty, tsc --noEmit)
3. **test** — unit tests; live integration tests skipped via `SKIP_LIVE_TESTS=1`

Stages are wired with `needs:` so they run sequentially. Never triggers image push.

### 2. `publish-image.yaml` — Image Publishing
Runs on every `push` and `workflow_dispatch`. Builds and pushes the Docker image to GHCR using GHA layer cache. Tag strategy via `docker/metadata-action`:
- `type=ref,event=branch` — branch name tag
- `type=ref,event=tag` — semver tag on git tag push
- `type=sha` — short commit SHA tag
- `type=raw,value=latest,enable={{is_default_branch}}` — latest on default branch only

### 3. `release-on-main.yaml` — Automated Releases
Runs on push to `main` and `workflow_dispatch`. Workflow:
1. Reads version from the package manifest (pyproject.toml → `project.version`, Cargo.toml → `package.version`, package.json → `version`)
2. Checks whether the git tag `v<version>` already exists — **fails the workflow if it does** (this enforces a version bump on every main push)
3. Creates and pushes the git tag
4. Cuts a GitHub release with auto-generated release notes (`softprops/action-gh-release@v2`, `generate_release_notes: true`)

### 4. Pre-commit / Lefthook — Local Dev Gate
Runs `scripts/lint-plugin.sh` before every commit:
- **Python**: `.pre-commit-config.yaml` (uses `pre-commit` framework, `language: system`)
- **Rust / TypeScript**: `lefthook.yml` (runs in parallel mode)

## Default Assumptions

Unless the user states otherwise, assume:

- registry is `ghcr.io`, image name is `github.repository`
- no matrix builds unless the plugin explicitly targets ARM or a second platform
- live tests are skipped in CI via `SKIP_LIVE_TESTS=1` set at workflow `env:` level
- release workflow fails if tag already exists (this is correct behavior — do not remove the check)
- pre-commit uses the language's canonical hook manager (pre-commit for Python, lefthook for Rust/TypeScript)

## Gather Inputs First

Before writing or updating pipeline files, collect:

- plugin name and language (`python`, `rust`, `typescript`)
- Docker registry and image name (default: ghcr.io + github.repository)
- required secrets (registry credentials, service tokens for live tests)
- whether live integration tests require a running external service
- which of the four workflow files are missing or need updating

If any of these inputs are absent and cannot be inferred from the repo, ask before generating files.

## Prefer Canonical Templates

Use the workflow files in `~/workspace/plugin-templates/py/`, `~/workspace/plugin-templates/rs/`, or `~/workspace/plugin-templates/ts/` as the base for all four files. Specialize with:

- the plugin's image name and registry path
- the correct package manager invocations for the language
- the live test toggle (`SKIP_LIVE_TESTS=1`)
- the registry secret names specific to this plugin

Avoid inventing new job names or step ordering. Diverge from the canonical template only when the plugin has a documented reason.

## Implementing the Pipeline

Produce all four files plus Justfile targets:

1. **`.github/workflows/ci.yaml`** — lint → type-check → test gate with live test skip guard
2. **`.github/workflows/publish-image.yaml`** — image build + push with full tag strategy and GHA cache
3. **`.github/workflows/release-on-main.yaml`** — manifest version read → tag existence check → tag creation → GitHub release
4. **Pre-commit config** — `.pre-commit-config.yaml` (Python) or `lefthook.yml` (Rust/TypeScript) running `scripts/lint-plugin.sh`
5. **Justfile targets** — `lint`, `type-check`, `test`, `test-live`, `build`, `push`, `release` that mirror each CI step locally
6. **Required secrets list** — write to both `README.md` (human-facing) and `docs/secrets.md` (machine-readable)

## Live Test Guard Pattern

Live tests require a running external service. They must never block CI when that service is unavailable. Guard them with `SKIP_LIVE_TESTS=1`.

**Python — pytest marker:**

```python
# conftest.py
import os
import pytest

def pytest_configure(config):
    config.addinivalue_line(
        "markers", "live: mark test as requiring a live external service"
    )

def pytest_collection_modifyitems(config, items):
    if os.environ.get("SKIP_LIVE_TESTS"):
        skip_live = pytest.mark.skip(reason="SKIP_LIVE_TESTS is set")
        for item in items:
            if "live" in item.keywords:
                item.add_marker(skip_live)
```

```toml
# pyproject.toml — register the marker to silence PytestUnknownMarkWarning
[tool.pytest.ini_options]
markers = ["live: requires a live external service"]
```

```python
# usage in tests
@pytest.mark.live
def test_actual_api_call():
    ...
```

Run without live tests (CI default): `uv run pytest -m "not live"`
Run with live tests (local): `uv run pytest` or `just test-live`

**Rust — feature flag:**

```toml
# Cargo.toml
[features]
live-tests = []
```

```rust
// usage in tests
#[cfg_attr(not(feature = "live-tests"), ignore)]
#[test]
fn test_actual_api_call() {
    // requires running service
}
```

Run without live tests (CI default): `cargo test`
Run with live tests (local): `cargo test --features live-tests` or `just test-live`

**TypeScript — environment variable check:**

```typescript
// vitest variant
import { describe, test, expect } from "vitest";

const skipLive = !!process.env.SKIP_LIVE_TESTS;

describe("live integration", () => {
  test.skipIf(skipLive)("calls actual API", async () => {
    // requires running service
  });
});

// jest variant
const skipLive = !!process.env.SKIP_LIVE_TESTS;

(skipLive ? describe.skip : describe)("live integration", () => {
  test("calls actual API", async () => {
    // requires running service
  });
});
```

Run without live tests (CI default): `SKIP_LIVE_TESTS=1 npm test`
Run with live tests (local): `npm test` or `just test-live`

In CI, set `SKIP_LIVE_TESTS: "1"` as a workflow-level `env:` variable so it applies to all test steps without repeating it per step.

## Reviewing an Existing Pipeline

Check for all four workflow files. Common drift patterns:

**ci.yaml:**
- type-check stage missing or skipped
- live tests not guarded — will fail in CI when service is unreachable
- stages not wired with `needs:` (running in parallel instead of sequentially)
- hardcoded credentials or tokens

**publish-image.yaml:**
- `:latest` only tag strategy — must also include sha and branch/tag refs
- no GHA layer cache (`cache-from`/`cache-to` missing)
- push triggered on PRs (should be push events only)

**release-on-main.yaml:**
- missing entirely — common in older plugins
- tag existence check removed — allows duplicate releases
- manifest version read fails because file detection order is wrong
- `fetch-depth: 0` missing — git tag push will fail without full history

**Pre-commit / Lefthook:**
- missing entirely — no local dev quality gate
- `lint-plugin.sh` path wrong or script not executable
- lefthook not set to `parallel: true` (slower than it needs to be)

**Justfile:**
- targets missing or inconsistent with CI step commands
- no `test-live` target for running live tests locally

Produce a findings list organized by file before making changes.

## Updating a Pipeline

When modifying:

1. Identify the specific gap by file (missing workflow, wrong trigger, secret name drift)
2. Make a targeted change — avoid rewriting the whole file unless the structure is fundamentally wrong
3. Verify Justfile targets stay in sync with updated CI steps
4. Document new secrets in both `README.md` and `docs/secrets.md` if secrets were added or renamed
5. After adding `release-on-main.yaml`: confirm the manifest has a version field before the workflow runs — the workflow will fail immediately if it cannot find one

If an artifact path appears in pipeline output, use the timestamp format `YYYYMMDD-HHMMSS`.

## Required Output

At minimum, all four workflow files plus supporting config:

- [ ] `.github/workflows/ci.yaml` — lint → type-check → test with live test guard
- [ ] `.github/workflows/publish-image.yaml` — image build + push, full tag strategy, GHA cache
- [ ] `.github/workflows/release-on-main.yaml` — manifest version → tag check → tag + release
- [ ] Pre-commit config — `.pre-commit-config.yaml` (Python) or `lefthook.yml` (Rust/TypeScript)
- [ ] Justfile targets — `lint`, `type-check`, `test`, `test-live`, `build`, `push`
- [ ] Required secrets list in both `README.md` and `docs/secrets.md`
- [ ] Live test guard implementation for the target language
- [ ] Any assumptions about registry, image name, or live test environment

## Related Skills

- **scaffold-lab-plugin** — creates the initial repo structure that the pipeline runs against; the pipeline skill fills in the CI layer the scaffold leaves as a placeholder
- **deploy-lab-plugin** — CI builds the Docker image that Compose deploys; the build and push stages of the pipeline feed directly into the deploy workflow
- **tool-lab-plugin** — if the plugin exposes MCP tools with live test coverage, those tests are the ones guarded by `SKIP_LIVE_TESTS`; coordinate live test marker usage with tool design
