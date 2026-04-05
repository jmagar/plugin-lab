# Coding Rules — my-plugin

Standards and conventions enforced across the plugin ecosystem.

## Git workflow

### Conventional commits

All commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Purpose | Example |
| --- | --- | --- |
| `feat:` | New feature | `feat: add search tool` |
| `fix:` | Bug fix | `fix: handle empty API response` |
| `chore:` | Maintenance | `chore: update dependencies` |
| `refactor:` | Code restructure | `refactor: extract client module` |
| `test:` | Tests | `test: add integration tests for search` |
| `docs:` | Documentation | `docs: update CONFIG reference` |
| `ci:` | CI/CD changes | `ci: add Docker build workflow` |

### Branch strategy

- `main` is production-ready at all times
- Feature branches for development: `feat/tool-name`, `fix/issue-description`
- PR required before merge to `main`

### Version tags

Tags use `vX.Y.Z` format (e.g., `v0.1.0`). Created by the `just publish` recipe.

### Never commit

- `.env` files or any file containing credentials
- API keys, tokens, or passwords
- Large binary files
- Temporary or debug files
- `__pycache__/`, `node_modules/`, `target/`

## Version bumping

### Bump type rules

| Commit prefix | Bump | Example |
| --- | --- | --- |
| `feat!:` or `BREAKING CHANGE` | Major | `1.2.3` -> `2.0.0` |
| `feat:` or `feat(...):` | Minor | `1.2.3` -> `1.3.0` |
| Everything else | Patch | `1.2.3` -> `1.2.4` |

### Version-bearing files

All of these files must have the same version. Never bump only one:

| File | Field |
| --- | --- |
| `.claude-plugin/plugin.json` | `"version": "X.Y.Z"` |
| `.codex-plugin/plugin.json` | `"version": "X.Y.Z"` |
| `gemini-extension.json` | `"version": "X.Y.Z"` |
| `package.json` (TS) | `"version": "X.Y.Z"` |
| `pyproject.toml` (Python) | `version = "X.Y.Z"` |
| `Cargo.toml` (Rust) | `version = "X.Y.Z"` |
| `CHANGELOG.md` | New entry under `## X.Y.Z` |

### CHANGELOG format

```markdown
## 0.2.0

- feat: add search tool with pagination
- fix: handle upstream timeout gracefully

## 0.1.0

- Initial release
```

## Code standards

### Bash

```bash
#!/bin/bash
set -euo pipefail          # Strict mode
"$variable"                # Always quote variables
function_name() { ... }   # Use functions for reusable code
chmod +x script.sh         # Executable permissions
```

### Python

- Type hints on all function signatures
- Google-style docstrings
- f-strings for formatting
- `async`/`await` for I/O operations
- PEP 8 via `ruff format`

```python
async def search_media(query: str, limit: int = 10) -> list[dict]:
    """Search upstream service for media.

    Args:
        query: Search term.
        limit: Maximum results to return.

    Returns:
        List of matching media items.
    """
```

### TypeScript

- ESM modules (`import` syntax, not `require`)
- No `any` types — use explicit types or `unknown`
- Strict mode enabled in `tsconfig.json`
- `async`/`await` for I/O

```typescript
export async function searchMedia(query: string, limit = 10): Promise<MediaItem[]> {
  const response = await client.get("/api/search", { params: { query, limit } });
  return response.data.results;
}
```

### Rust

- Standard clippy lints (`#![warn(clippy::all)]`)
- Proper error handling with `thiserror` or `anyhow`
- `async`/`await` with `tokio`
- `serde` for serialization

```rust
pub async fn search_media(query: &str, limit: usize) -> Result<Vec<MediaItem>> {
    let response = client
        .get(&format!("/api/search?q={query}&limit={limit}"))
        .send()
        .await?;
    Ok(response.json().await?)
}
```

## Security rules

See [GUARDRAILS](../GUARDRAILS.md) for the full security reference. Key rules:

- Credentials in `.env` only, never in code
- `.env` has `chmod 600` permissions
- Docker images run as non-root
- No baked environment variables in Docker images
- Health endpoint (`/health`) is unauthenticated; all other endpoints require bearer auth

## Documentation requirements

Every plugin must include:

| File | Audience | Purpose |
| --- | --- | --- |
| `CLAUDE.md` | Claude Code | Project instructions for AI sessions |
| `README.md` | Humans | Overview, install, configuration, examples |
| `CHANGELOG.md` | Both | Version history |
| `SKILL.md` | Claude Code | Skill definition with commands and workflows |
| Reference docs | Both | API endpoints, troubleshooting, quick reference |
