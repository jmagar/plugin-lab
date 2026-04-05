# Testing Guide

Testing patterns for `my-plugin-mcp`. All non-live testing is covered here; see [MCPORTER.md](MCPORTER.md) for end-to-end smoke tests.

## Unit Tests

<!-- scaffold:specialize -->

| Language | Command | Offline flag |
|----------|---------|-------------|
| Python | `pytest tests/` | `-m "not live"` |
| TypeScript | `vitest` or `jest` | `--testPathIgnorePatterns live` |
| Rust | `cargo test` | `--skip live` |

Shortcut: `just test`

### Python

```bash
uv run pytest tests/ -m "not live" -v
```

Tests live in `tests/test_*.py`. Use `@pytest.mark.live` for tests requiring upstream credentials.

### TypeScript

```bash
pnpm test
```

Tests live in `tests/*.test.ts`.

### Rust

```bash
cargo test
```

Tests live alongside source in `#[cfg(test)]` modules or in `tests/`.

## Integration Tests

Integration tests hit real upstream services and require credentials.

| Concern | Pattern |
|---------|---------|
| Marker | Python: `@pytest.mark.live` |
| Credentials | `.env` locally, GitHub secrets in CI |
| CI behavior | Skipped unless secrets are available |
| Trigger | `main` push only (not on PRs from forks) |

```bash
# Run integration tests locally
uv run pytest tests/ -m "live" -v
```

## Test Structure

```
tests/
  test_tools.py          # Tool dispatch (all action/subaction combos)
  test_auth.py           # Auth flows (valid, invalid, missing, no-auth mode)
  test_health.py         # /health endpoint
  test_errors.py         # Error conditions and timeouts
  test_live.py           # @pytest.mark.live — upstream integration
  test_live.sh           # Shell-based smoke tests (see MCPORTER.md)
  TEST_COVERAGE.md       # Documents what is and isn't tested
```

## Testing Checklist

- [ ] **Tool dispatch** — every action/subaction combo returns expected shape
- [ ] **Auth: valid token** — 200 with correct Bearer token
- [ ] **Auth: invalid token** — 401/403
- [ ] **Auth: no token** — 401 (or 200 if `--no-auth`)
- [ ] **Auth: no-auth mode** — all endpoints accessible without token
- [ ] **Health endpoint** — `GET /health` returns 200 with no auth
- [ ] **Error conditions** — upstream timeout, 404, 500 propagate correctly
- [ ] **Destructive operation gates** — delete/modify actions require confirmation or are flagged

## CI Configuration

Tests run automatically in CI. See [CICD.md](CICD.md) for workflow details.

```yaml
# Excerpt from ci.yml
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - run: just test
```

## Related Docs

- [MCPORTER.md](MCPORTER.md) — live smoke tests
- [CICD.md](CICD.md) — CI workflow configuration
- [LOGS.md](LOGS.md) — error handling patterns tested here
