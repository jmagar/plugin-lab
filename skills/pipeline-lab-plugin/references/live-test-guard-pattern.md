# Live Test Guard Pattern

Live tests require a running external service (a real API, a running container, live credentials). They must never block CI when that service is unavailable. This document shows the complete guard pattern for each language, including local invocation via `just`.

The canonical guard variable is `SKIP_LIVE_TESTS`. When set to any non-empty value, live tests are skipped. When unset or empty, live tests run.

---

## Python — pytest marker

### Setup

**`conftest.py`** (at project root or `tests/conftest.py`):

```python
import os
import pytest


def pytest_configure(config: pytest.Config) -> None:
    """Register the 'live' marker so pytest doesn't warn about unknown markers."""
    config.addinivalue_line(
        "markers",
        "live: mark test as requiring a live external service (skipped in CI)",
    )


def pytest_collection_modifyitems(
    config: pytest.Config,
    items: list[pytest.Item],
) -> None:
    """Skip all 'live' tests when SKIP_LIVE_TESTS is set."""
    if not os.environ.get("SKIP_LIVE_TESTS"):
        return  # Live tests enabled — do not skip

    skip_marker = pytest.mark.skip(reason="SKIP_LIVE_TESTS is set")
    for item in items:
        if "live" in item.keywords:
            item.add_marker(skip_marker)
```

**`pyproject.toml`** — register the marker to suppress `PytestUnknownMarkWarning`:

```toml
[tool.pytest.ini_options]
markers = [
    "live: requires a live external service (skipped in CI when SKIP_LIVE_TESTS is set)",
]
```

### Writing live tests

```python
# tests/test_api_live.py
import pytest

from my_plugin_mcp.client import MyServiceClient


@pytest.mark.live
def test_health_endpoint_responds() -> None:
    """Verify the real service health endpoint is reachable."""
    client = MyServiceClient()
    response = client.health()
    assert response["status"] == "ok"


@pytest.mark.live
def test_list_items_returns_results() -> None:
    """Verify the real service returns a non-empty item list."""
    client = MyServiceClient()
    items = client.list_items()
    assert len(items) > 0
```

Tests without `@pytest.mark.live` always run regardless of `SKIP_LIVE_TESTS`.

### Running locally

```bash
# Run all tests including live (requires running service and credentials in .env)
just test-live
# equivalent: uv run pytest

# Run only non-live tests (same as CI)
uv run pytest -m "not live"

# Run only live tests
uv run pytest -m "live"
```

**`Justfile` targets:**

```
test:
    uv run pytest -m "not live"

test-live:
    uv run pytest
```

### How CI invokes it

```yaml
# In .github/workflows/ci.yaml
env:
  SKIP_LIVE_TESTS: "1"   # Set at workflow level

jobs:
  test:
    steps:
      - run: uv run pytest -m "not live"
      # The -m flag is the primary guard; SKIP_LIVE_TESTS is belt-and-suspenders
      # for any test code that checks the env var directly.
```

---

## Rust — feature flag

### Setup

**`Cargo.toml`** — declare the feature flag:

```toml
[features]
# Enable with: cargo test --features live-tests
# CI never passes this flag, so live tests are always ignored in CI.
live-tests = []
```

### Writing live tests

```rust
// tests/live_tests.rs  (or inline in src/ with #[cfg(test)])

#[cfg(test)]
mod live {
    use super::*;

    /// Verify the real service health endpoint is reachable.
    /// Ignored unless compiled with --features live-tests.
    #[cfg_attr(not(feature = "live-tests"), ignore)]
    #[test]
    fn test_health_endpoint_responds() {
        let client = MyServiceClient::from_env().expect("credentials required");
        let response = client.health().expect("health check failed");
        assert_eq!(response.status, "ok");
    }

    /// Verify the real service returns a non-empty item list.
    #[cfg_attr(not(feature = "live-tests"), ignore)]
    #[tokio::test]
    async fn test_list_items_returns_results() {
        let client = MyServiceClient::from_env().expect("credentials required");
        let items = client.list_items().await.expect("list failed");
        assert!(!items.is_empty());
    }
}
```

The `#[cfg_attr(not(feature = "live-tests"), ignore)]` attribute means:
- Without `--features live-tests`: the test is compiled but marked `#[ignore]`, so `cargo test` lists it but does not run it.
- With `--features live-tests`: the ignore attribute is absent, and the test runs normally.

This is preferable to `#[cfg(feature = "live-tests")]` because it keeps the test visible in `cargo test -- --ignored` output, making it easier to discover which live tests exist.

### Running locally

```bash
# Run all tests including live (requires running service and credentials in .env)
just test-live
# equivalent: cargo test --features live-tests

# Run only non-live tests (same as CI)
cargo test
# or: just test

# List live tests without running them
cargo test -- --ignored --list
```

**`Justfile` targets:**

```
test:
    cargo test

test-live:
    cargo test --features live-tests
```

### How CI invokes it

```yaml
# In .github/workflows/ci.yaml
jobs:
  test:
    steps:
      # No --features live-tests flag → live tests are ignored
      - run: cargo test
```

No environment variable is needed for Rust because the feature flag provides a compile-time guard. `SKIP_LIVE_TESTS` is set at the workflow level for consistency with other language variants but does not affect Rust test behavior unless the test code explicitly reads it.

---

## TypeScript — environment variable check

### Setup

No additional configuration file is required beyond what vitest or jest provides. The guard is applied inline in test files using the test runner's native skip API.

If you use a shared helper, add it to `tests/helpers/live.ts`:

```typescript
// tests/helpers/live.ts
export const isLiveTestEnabled = !process.env.SKIP_LIVE_TESTS;
```

### Writing live tests — vitest variant

```typescript
// tests/live/api.test.ts
import { describe, expect, test } from "vitest";
import { MyServiceClient } from "../../src/client.js";

// test.skipIf(condition) skips the test when the condition is truthy.
// When SKIP_LIVE_TESTS is set, all tests in this block are skipped.
const skipLive = !!process.env.SKIP_LIVE_TESTS;

describe("live: MyService API", () => {
  test.skipIf(skipLive)("health endpoint responds", async () => {
    const client = new MyServiceClient();
    const response = await client.health();
    expect(response.status).toBe("ok");
  });

  test.skipIf(skipLive)("list items returns results", async () => {
    const client = new MyServiceClient();
    const items = await client.listItems();
    expect(items.length).toBeGreaterThan(0);
  });
});
```

### Writing live tests — jest variant

```typescript
// tests/live/api.test.ts
import { MyServiceClient } from "../../src/client.js";

const skipLive = !!process.env.SKIP_LIVE_TESTS;

// describe.skip skips the entire block when skipLive is true.
// Use this pattern for jest, which lacks test.skipIf.
(skipLive ? describe.skip : describe)("live: MyService API", () => {
  test("health endpoint responds", async () => {
    const client = new MyServiceClient();
    const response = await client.health();
    expect(response.status).toBe("ok");
  });

  test("list items returns results", async () => {
    const client = new MyServiceClient();
    const items = await client.listItems();
    expect(items.length).toBeGreaterThan(0);
  });
});
```

### Configuring vitest to separate live tests (optional)

If the project uses vitest, you can add a separate workspace entry or config override to make live test invocation cleaner:

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Standard test run excludes the live/ directory entirely.
    // Use vitest --config vitest.live.config.ts for live tests.
    exclude: ["tests/live/**", "node_modules/**"],
  },
});
```

```typescript
// vitest.live.config.ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["tests/live/**/*.test.ts"],
  },
});
```

### Running locally

```bash
# Run all tests including live (requires running service and credentials in .env)
just test-live
# equivalent (vitest): npx vitest run
# equivalent (jest):   npm test

# Run only non-live tests (same as CI)
SKIP_LIVE_TESTS=1 npm test
# or: just test

# Run only live tests explicitly (vitest with separate config)
npx vitest run --config vitest.live.config.ts
```

**`Justfile` targets:**

```
test:
    SKIP_LIVE_TESTS=1 npm test

test-live:
    npm test
```

### How CI invokes it

```yaml
# In .github/workflows/ci.yaml
env:
  SKIP_LIVE_TESTS: "1"   # Set at workflow level; inherited by all steps

jobs:
  test:
    steps:
      # npm test inherits SKIP_LIVE_TESTS from workflow env.
      # No additional flags needed.
      - run: npm test
```

---

## Summary table

| Language | Guard mechanism | CI invocation | Local live invocation |
|---|---|---|---|
| Python | `@pytest.mark.live` + `conftest.py` | `uv run pytest -m "not live"` | `just test-live` (= `uv run pytest`) |
| Rust | `--features live-tests` feature flag | `cargo test` | `just test-live` (= `cargo test --features live-tests`) |
| TypeScript | `process.env.SKIP_LIVE_TESTS` + `test.skipIf` | `npm test` (with `SKIP_LIVE_TESTS=1` from workflow env) | `just test-live` (= `npm test` without env var) |

All three approaches share the same invariant: the default invocation (`just test`, CI pipeline) never requires a running external service. Live tests run only when explicitly requested locally via `just test-live`.
