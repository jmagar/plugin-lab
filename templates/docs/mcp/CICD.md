# CI/CD Workflows

GitHub Actions configuration for `my-plugin-mcp`.

## Workflows

### ci.yml — Continuous Integration

Runs on every push and PR.

<!-- scaffold:specialize -->

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # Python: ruff check / ruff format --check
      # TypeScript: biome check
      # Rust: cargo clippy -- -D warnings

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # Python: ty check (or mypy)
      # TypeScript: tsc --noEmit
      # Rust: cargo check

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # Python: pytest -m "not live"
      # TypeScript: vitest run
      # Rust: cargo test

  contract-drift:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash scripts/lint-plugin.sh

  docker-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash scripts/check-docker-security.sh Dockerfile
      - run: bash scripts/check-no-baked-env.sh .
      - run: bash scripts/ensure-ignore-files.sh --check .

  mcp-integration:
    needs: [lint, typecheck, test]
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: jmagar/plugin-lab/.github/actions/mcp-integration@main
        with:
          server-start-cmd: "just serve &"
          health-url: "http://localhost:8000/health"
          test-cmd: "bash tests/test_live.sh http"
        env:
          MY_SERVICE_URL: ${{ secrets.MY_SERVICE_URL }}
          MY_SERVICE_API_KEY: ${{ secrets.MY_SERVICE_API_KEY }}
```

### publish-pypi.yml / publish-npm.yml — Package Publishing

Triggered on tag push (`v*.*.*`).

```yaml
name: Publish
on:
  push:
    tags: ["v*.*.*"]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # OIDC trusted publishing
      contents: write  # GitHub Release
    steps:
      - uses: actions/checkout@v4

      - name: Verify tag matches version
        run: |
          TAG="${GITHUB_REF#refs/tags/v}"
          # Python: VERSION=$(grep '^version' pyproject.toml | cut -d'"' -f2)
          # TypeScript: VERSION=$(jq -r .version package.json)
          [[ "$TAG" == "$VERSION" ]] || { echo "Tag $TAG != version $VERSION"; exit 1; }

      - name: Build
        run: just build

      - name: Publish
        # Python: uv publish (trusted publishing via OIDC)
        # TypeScript: npm publish --provenance --access public
        # Rust: cargo publish

      - name: GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
```

### docker-publish.yml — Container Images

Triggered on tag push.

```yaml
name: Docker Publish
on:
  push:
    tags: ["v*.*.*"]

jobs:
  docker:
    runs-on: ubuntu-latest
    permissions:
      packages: write
    steps:
      - uses: actions/checkout@v4

      - uses: docker/setup-buildx-action@v3

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@v6
        with:
          push: true
          platforms: linux/amd64,linux/arm64
          tags: |
            ghcr.io/jmagar/my-plugin-mcp:${{ github.ref_name }}
            ghcr.io/jmagar/my-plugin-mcp:latest
```

### MCP Registry Publish

Part of the publish workflow. Registers `server.json` metadata under the `tv.tootie/my-plugin` namespace.

See [PUBLISH.md](PUBLISH.md) for `server.json` structure.

## Secrets Required

| Secret | Purpose | How to Generate |
|--------|---------|-----------------|
| `GITHUB_TOKEN` | Auto-provided | Built-in |
| `MY_SERVICE_URL` | Upstream URL for live tests | Set in repo settings |
| `MY_SERVICE_API_KEY` | Upstream API key for live tests | Set in repo settings |
| `PYPI_API_TOKEN` | PyPI publish (if not using OIDC) | pypi.org account |
| `NPM_TOKEN` | npm publish (if not using OIDC) | npm account |
| `DOCKER_HUB_TOKEN` | Docker Hub push (optional) | hub.docker.com |

MCP tokens are generated at CI runtime and do not need to be stored as secrets.

## Related Docs

- [TESTS.md](TESTS.md) — test commands referenced by CI
- [MCPORTER.md](MCPORTER.md) — live smoke tests in CI
- [PUBLISH.md](PUBLISH.md) — versioning and release workflow
- [PRE-COMMIT.md](PRE-COMMIT.md) — hooks that CI also enforces
