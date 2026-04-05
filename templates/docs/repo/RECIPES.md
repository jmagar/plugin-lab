# Justfile Recipes — my-plugin

Standard task runner recipes. Run `just --list` to see all available recipes.

## Development

| Recipe | Command | Purpose |
| --- | --- | --- |
| `dev` | `just dev` | Run dev server with auto-reload |
| `lint` | `just lint` | Run linter (ruff / biome / clippy) |
| `fmt` | `just fmt` | Format code |
| `typecheck` | `just typecheck` | Type checking (ty / tsc / cargo check) |
| `test` | `just test` | Run unit tests |
| `test-live` | `just test-live` | Run integration tests against live service |
| `verify` | `just verify` | Full CI equivalent: fmt + lint + typecheck + test |

## Docker

| Recipe | Command | Purpose |
| --- | --- | --- |
| `build` | `just build` | Build Docker image |
| `up` | `just up` | `docker compose up -d` |
| `down` | `just down` | `docker compose down` |
| `logs` | `just logs` | `docker compose logs -f` |
| `restart` | `just restart` | `docker compose restart` |

## Health and status

| Recipe | Command | Purpose |
| --- | --- | --- |
| `health` | `just health` | `curl http://localhost:8000/health \| jq .` |
| `gen-token` | `just gen-token` | `openssl rand -hex 32` |

## Setup

| Recipe | Command | Purpose |
| --- | --- | --- |
| `setup` | `just setup` | Copy `.env.example` to `.env`, set permissions |
| `install` | `just install` | Install project dependencies |

## Quality

| Recipe | Command | Purpose |
| --- | --- | --- |
| `check-contract` | `just check-contract` | Validate plugin.json against schema |
| `validate-skills` | `just validate-skills` | Validate SKILL.md files |
| `clean` | `just clean` | Remove build artifacts and caches |

## Publishing

| Recipe | Command | Purpose |
| --- | --- | --- |
| `publish [bump]` | `just publish patch` | Version bump, tag, push |

The `publish` recipe:

1. Bumps the version in all version-bearing files
2. Updates `CHANGELOG.md` with a new entry
3. Creates a git tag `vX.Y.Z`
4. Pushes the tag to trigger the release workflow

Bump types: `major`, `minor`, `patch` (default: `patch`).

## Language-specific variations

### Python (uv)

```just
dev:
    uv run my-plugin-server --reload

lint:
    uv run ruff check .

fmt:
    uv run ruff format .

typecheck:
    uv run ty check

test:
    uv run pytest

install:
    uv sync --dev
```

### TypeScript (pnpm)

```just
dev:
    pnpm dev

lint:
    pnpm biome check .

fmt:
    pnpm biome format --write .

typecheck:
    pnpm tsc --noEmit

test:
    pnpm vitest run

install:
    pnpm install
```

### Rust (cargo)

```just
dev:
    cargo run

lint:
    cargo clippy --all-targets

fmt:
    cargo fmt

typecheck:
    cargo check

test:
    cargo test

install:
    cargo build
```

## Chaining recipes

Recipes can be chained:

```bash
just fmt lint typecheck test   # Run all quality checks in sequence
just verify                     # Same as above, single command
```
