# Logging and Error Handling

Logging and error handling patterns for `my-plugin-mcp`.

## Log Configuration

| Env Var | Values | Default |
|---------|--------|---------|
| `LOG_LEVEL` | `DEBUG`, `INFO`, `WARNING`, `ERROR` | `INFO` |
| `RUST_LOG` | Rust filter directives (e.g. `my_plugin=debug`) | `info` |

## Language Patterns

<!-- scaffold:specialize -->

### Python

```python
import os
import logging
from logging.handlers import RotatingFileHandler

logger = logging.getLogger("MyPlugin")
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

# Console handler
console = logging.StreamHandler()
console.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s %(message)s"))
logger.addHandler(console)

# File handler — 5 MB, 3 backups
file_handler = RotatingFileHandler("logs/my-plugin.log", maxBytes=5_242_880, backupCount=3)
file_handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s %(message)s"))
logger.addHandler(file_handler)
```

### TypeScript

Custom structured logger in `src/utils/logger.ts`:

```typescript
import { createLogger, transports, format } from "winston";

export const logger = createLogger({
  level: process.env.LOG_LEVEL?.toLowerCase() ?? "info",
  format: format.combine(format.timestamp(), format.json()),
  transports: [
    new transports.Console(),
    new transports.File({ filename: "logs/my-plugin.log", maxsize: 5242880, maxFiles: 3 }),
  ],
});
```

### Rust

Uses `RUST_LOG` env var with `tracing` or `env_logger`:

```rust
tracing_subscriber::fmt()
    .with_env_filter(EnvFilter::from_default_env())
    .json()
    .init();
```

## Log Location

| Context | Path |
|---------|------|
| Local dev | `./logs/` |
| Docker | `/app/logs` (volume mount `./logs:/app/logs`) |

Access Docker logs:

```bash
just logs            # Tails compose logs
docker compose logs -f my-plugin-mcp
```

## Error Handling Patterns

### Consistent Error Response

```json
{
  "error": {
    "code": "UPSTREAM_TIMEOUT",
    "message": "my-service did not respond within 30s",
    "details": {}
  }
}
```

### Timeout Protection

Default 30s for upstream calls. Override with `MY_PLUGIN_TIMEOUT`.

```python
try:
    resp = httpx.get(url, timeout=int(os.getenv("MY_PLUGIN_TIMEOUT", "30")))
except httpx.TimeoutException:
    logger.warning("Upstream timeout for %s", url)
    return error_response("UPSTREAM_TIMEOUT", "my-service did not respond within timeout")
```

### Graceful Degradation

- Return partial data with a warning when non-critical fields fail.
- Never crash the server on a single upstream failure.
- Always return valid MCP response structure even on errors.

### Credential Safety

- Never log API keys, tokens, or passwords.
- Redact `Authorization` headers in debug output.
- Mask env var values in startup banners: `MY_PLUGIN_API_KEY=****`.

## Structured Logging Format

For log aggregation, use JSON lines:

```json
{"ts":"2026-04-04T12:00:00Z","level":"INFO","msg":"tool invoked","tool":"my_action","duration_ms":42}
{"ts":"2026-04-04T12:00:01Z","level":"ERROR","msg":"upstream error","status":503,"retry":true}
```

## Related Docs

- [DEPLOY.md](DEPLOY.md) — Docker volume mounts
- [ENV.md](ENV.md) — `LOG_LEVEL` and other env vars
- [TESTS.md](TESTS.md) — testing error conditions
