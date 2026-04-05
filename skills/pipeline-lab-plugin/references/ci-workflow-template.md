# CI Workflow Template — Annotated GitHub Actions

This document shows an annotated canonical `ci.yaml` for a homelab lab plugin. Three language variants are provided: Python, Rust, and TypeScript. Each shares the same job topology and trigger strategy; only the toolchain steps differ.

---

## Triggers (shared across all variants)

```yaml
on:
  push:
    branches:
      - main          # Run full pipeline on every push to main
    tags:
      - "v*.*.*"      # Run full pipeline including release job on version tags
  pull_request:       # Run lint/type-check/test on all PRs; skip build+push
```

**Why these triggers:**
- `push` to `main` runs the full pipeline including Docker build and push, so the registry always has a current image for `main`.
- `tags` matching `v*.*.*` additionally trigger the release job.
- `pull_request` runs quality gates (lint, type-check, test) but the `push` job is gated to skip on PRs (see `if:` condition on the push job).

---

## Job dependency graph

```
lint ──┐
       ├──> test ──> build ──> push ──> release
typecheck ─┘                    (main/tag only)  (tag only)
```

All jobs use `needs:` to enforce this ordering. No job skips its upstream gate.

---

## Workflow-level environment variables

```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}   # e.g., owner/my-plugin-mcp
  SKIP_LIVE_TESTS: "1"                   # Applied to all jobs; live tests never run in CI
```

`SKIP_LIVE_TESTS` is set at workflow level so it applies to every job without repeating it per step. Individual jobs can override if a dedicated live-test job is added later.

---

## Python variant

```yaml
name: ci

on:
  push:
    branches: [main]
    tags: ["v*.*.*"]
  pull_request:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  SKIP_LIVE_TESTS: "1"

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # uv is the canonical Python package manager for lab plugins.
      # setup-uv installs uv and makes it available for subsequent steps.
      - uses: astral-sh/setup-uv@v5

      # uv sync installs the project and all dev dependencies from uv.lock.
      # This is reproducible because it uses the lockfile, not just pyproject.toml.
      - run: uv sync

      # ruff check: fast linter covering style, imports, and common bug patterns.
      - run: uv run ruff check .

      # Plugin contract checks: Docker security, no baked env vars, ignore files, skill schema.
      - run: bash scripts/check-docker-security.sh
      - run: bash scripts/check-no-baked-env.sh .
      - run: bash hooks/scripts/ensure-ignore-files.sh --check .
      - run: npx skills-ref validate skills/

  typecheck:
    name: Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
      - run: uv sync

      # ty (Astral's type checker) is the canonical choice for lab plugins.
      # mypy is acceptable if the plugin predates ty adoption.
      - run: uv run ty check

  test:
    name: Test
    runs-on: ubuntu-latest
    needs: [lint, typecheck]   # Only run tests if lint and typecheck pass
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
      - run: uv sync

      # -m "not live" excludes tests marked with @pytest.mark.live.
      # SKIP_LIVE_TESTS is set at workflow level as a belt-and-suspenders guard.
      # See references/live-test-guard-pattern.md for conftest.py setup.
      - run: uv run pytest -m "not live"

  build:
    name: Build Image
    runs-on: ubuntu-latest
    needs: [test]
    # Build on main pushes and tag pushes; skip on PRs.
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4

      # Log in to ghcr.io using the GitHub Actions token.
      # GITHUB_TOKEN has write:packages permission by default for the repo owner.
      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # Extract metadata for image tags and labels.
      # Produces: short SHA tag on push, semver tag on tag push.
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,format=short
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}

      - name: Build image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: false          # Build only; push job handles pushing
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          # Cache layers from the registry to speed up repeated builds
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max

  push:
    name: Push Image
    runs-on: ubuntu-latest
    needs: [build]
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,format=short
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max

  release:
    name: Release
    runs-on: ubuntu-latest
    needs: [push]
    # Only run on tag pushes matching v*.*.*
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0   # Full history needed to generate release notes

      # Extract the CHANGELOG entry for this version and create a GitHub Release.
      # Adjust the release body command to match your CHANGELOG format.
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
```

---

## Rust variant

```yaml
name: ci

on:
  push:
    branches: [main]
    tags: ["v*.*.*"]
  pull_request:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  SKIP_LIVE_TESTS: "1"

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # dtolnay/rust-toolchain installs the stable Rust toolchain including
      # rustfmt and clippy. Pin to stable for reproducible builds.
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt, clippy

      # Check formatting first — fast and catches a broad class of issues.
      - run: cargo fmt --check

      # clippy with -D warnings: treat all warnings as errors.
      # This matches the canonical lab plugin standard.
      - run: cargo clippy -- -D warnings

      # Plugin contract checks (same as Python variant).
      - run: bash scripts/check-docker-security.sh
      - run: bash scripts/check-no-baked-env.sh .
      - run: bash hooks/scripts/ensure-ignore-files.sh --check .
      - run: npx skills-ref validate skills/

  # Rust has no separate type-check job because clippy subsumes type checking.
  # Add a typecheck job only if you use additional type analysis tools.

  test:
    name: Test
    runs-on: ubuntu-latest
    needs: [lint]
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable

      # cargo test without --features live-tests runs only non-live tests.
      # Live tests are gated behind the "live-tests" feature flag.
      # See references/live-test-guard-pattern.md for Cargo.toml setup.
      - run: cargo test

  build:
    name: Build Image
    runs-on: ubuntu-latest
    needs: [test]
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,format=short
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
      - name: Build image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: false
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max

  push:
    name: Push Image
    runs-on: ubuntu-latest
    needs: [build]
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,format=short
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max

  release:
    name: Release
    runs-on: ubuntu-latest
    needs: [push]
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
```

---

## TypeScript variant

```yaml
name: ci

on:
  push:
    branches: [main]
    tags: ["v*.*.*"]
  pull_request:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  SKIP_LIVE_TESTS: "1"

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Pin Node.js to 22 (LTS). Do not rely on the runner default —
      # ubuntu-latest may ship a different Node version after a runner image update.
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm

      - run: npm ci   # Reproducible install from package-lock.json

      # Biome handles both lint and format checking in a single pass.
      - run: npx biome check .

      # Plugin contract checks (same as other variants).
      - run: bash scripts/check-docker-security.sh
      - run: bash scripts/check-no-baked-env.sh .
      - run: bash hooks/scripts/ensure-ignore-files.sh --check .
      - run: npx skills-ref validate skills/

  typecheck:
    name: Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci

      # tsc --noEmit: type-check only, no output files.
      # Biome does not type-check; this step is required separately.
      - run: npx tsc --noEmit

  test:
    name: Test
    runs-on: ubuntu-latest
    needs: [lint, typecheck]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci

      # SKIP_LIVE_TESTS is inherited from workflow env.
      # The test runner (vitest or jest) reads it to skip live-marked tests.
      # See references/live-test-guard-pattern.md for test setup.
      - run: npm test

  build:
    name: Build Image
    runs-on: ubuntu-latest
    needs: [test]
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,format=short
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
      - name: Build image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: false
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max

  push:
    name: Push Image
    runs-on: ubuntu-latest
    needs: [build]
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,format=short
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max

  release:
    name: Release
    runs-on: ubuntu-latest
    needs: [push]
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
```

---

## Secrets reference

The following secrets must be configured in GitHub repo settings under **Settings > Secrets and variables > Actions**:

| Secret name | Required for | Notes |
|---|---|---|
| `GITHUB_TOKEN` | build, push, release | Automatically provided by GitHub Actions; no manual setup needed for `ghcr.io` when the repo owner matches the image owner |
| `MY_SERVICE_TOKEN` | test (live tests only) | Only needed if a dedicated live-test job is added; not required when `SKIP_LIVE_TESTS=1` |

If you use a registry other than `ghcr.io`, add the appropriate `REGISTRY_USERNAME` and `REGISTRY_PASSWORD` secrets and update the `docker/login-action` step accordingly.

Document all secrets in both `README.md` (human-facing setup instructions) and `docs/secrets.md` (machine-readable list for tooling).
