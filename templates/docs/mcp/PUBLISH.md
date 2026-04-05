# Publishing Strategy

Versioning and release workflow for `my-plugin-mcp`.

## Versioning

Semantic versioning (MAJOR.MINOR.PATCH). Bump type from commit prefix:

| Prefix | Bump | Example |
|--------|------|---------|
| `feat!:` / `BREAKING CHANGE` | Major | `1.2.3` -> `2.0.0` |
| `feat:` / `feat(scope):` | Minor | `1.2.3` -> `1.3.0` |
| `fix:`, `docs:`, `chore:`, etc. | Patch | `1.2.3` -> `1.2.4` |

## Version Sync

All version-bearing files MUST match. Update together:

<!-- scaffold:specialize -->

| File | Field |
|------|-------|
| `pyproject.toml` | `version = "X.Y.Z"` in `[project]` |
| `package.json` | `"version": "X.Y.Z"` |
| `Cargo.toml` | `version = "X.Y.Z"` in `[package]` |
| `.claude-plugin/plugin.json` | `"version": "X.Y.Z"` |
| `.codex-plugin/plugin.json` | `"version": "X.Y.Z"` |
| `gemini-extension.json` | `"version": "X.Y.Z"` |
| `CHANGELOG.md` | New entry under `## X.Y.Z` |

## Publish Workflow

```bash
just publish [major|minor|patch]
```

Steps executed:

1. Bump version in all files listed above
2. Update `CHANGELOG.md` with new entry
3. Commit: `release: vX.Y.Z`
4. Tag: `vX.Y.Z`
5. Push to origin (triggers CI/CD publish workflows)

## Package Registries

| Registry | Language | Method |
|----------|----------|--------|
| PyPI | Python | Trusted publishing via OIDC (no token stored) |
| npm | TypeScript | `npm publish --provenance --access public` |
| crates.io | Rust | `cargo publish` |
| GHCR | All | Multi-arch Docker images (`linux/amd64`, `linux/arm64`) |
| MCP Registry | All | `server.json` under `tv.tootie/my-plugin` namespace |

## server.json

MCP Registry metadata file at repo root:

```json
{
  "name": "my-plugin-mcp",
  "description": "MCP server for my-service integration",
  "vendor": "tv.tootie",
  "identifier": "tv.tootie/my-plugin",
  "version": "0.1.0",
  "transport": ["stdio", "http"],
  "install": {
    "python": "uvx my-plugin-mcp",
    "typescript": "npx my-plugin-mcp",
    "docker": "ghcr.io/jmagar/my-plugin-mcp:latest"
  },
  "repository": "https://github.com/jmagar/my-plugin-mcp",
  "license": "MIT"
}
```

## Verification

After publishing, verify:

```bash
# PyPI
pip install my-plugin-mcp==X.Y.Z

# npm
npx my-plugin-mcp@X.Y.Z --version

# Docker
docker pull ghcr.io/jmagar/my-plugin-mcp:vX.Y.Z

# GitHub Release
gh release view vX.Y.Z
```

## Related Docs

- [CICD.md](CICD.md) — publish workflows triggered by tags
- [DEPLOY.md](DEPLOY.md) — package manager install commands
