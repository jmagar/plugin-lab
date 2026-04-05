# Upstream Service Integration — my-plugin

How my-plugin integrates with the my-service API.

## Purpose

my-plugin is an MCP server that wraps the my-service API, exposing upstream functionality as MCP tools consumable by Claude Code, Codex, and Gemini.

## API access patterns

### REST API (most common)

```
GET/POST/PUT/DELETE https://my-service.example.com/api/v1/<endpoint>
Authorization: <api-key-or-bearer-token>
```

### Authentication methods

<!-- scaffold:specialize — keep only the relevant method -->

| Method | Header | Env var |
| --- | --- | --- |
| API key | `X-Api-Key: <key>` | `MY_PLUGIN_API_KEY` |
| Bearer token | `Authorization: Bearer <token>` | `MY_PLUGIN_API_KEY` |
| Basic auth | `Authorization: Basic <base64>` | `MY_PLUGIN_USERNAME`, `MY_PLUGIN_PASSWORD` |

## Credential configuration

All upstream credentials are configured via environment variables in `.env`:

```bash
# Required — upstream service base URL
MY_PLUGIN_URL=https://my-service.example.com

# Required — API key for upstream authentication
MY_PLUGIN_API_KEY=your_api_key_here

# Optional — disable SSL verification for self-signed certs
MY_PLUGIN_VERIFY_SSL=true
```

See [ENV](../mcp/ENV.md) for the complete environment variable reference.

## Client wrapper pattern

Every plugin implements a central HTTP client that handles auth, retries, and error mapping:

### Responsibilities

| Concern | Implementation |
| --- | --- |
| Auth headers | Injected on every request from env vars |
| Base URL | Prefixed to all relative paths |
| Timeouts | 30s default, configurable |
| Retries | 3 attempts with exponential backoff on 5xx |
| SSL verification | Controlled by `MY_PLUGIN_VERIFY_SSL` |
| Error mapping | Upstream HTTP errors mapped to MCP error responses |

### Error mapping

| Upstream status | MCP response |
| --- | --- |
| 401 / 403 | `isError: true` — "Upstream authentication failed. Check MY_PLUGIN_API_KEY." |
| 404 | `isError: true` — "Resource not found." |
| 429 | `isError: true` — "Rate limited. Retry after X seconds." |
| 500+ | `isError: true` — "Upstream service error." |
| Connection refused | `isError: true` — "Upstream unreachable. Check MY_PLUGIN_URL." |

### Example (Python)

```python
import httpx

class MyServiceClient:
    def __init__(self, base_url: str, api_key: str, verify_ssl: bool = True):
        self.client = httpx.AsyncClient(
            base_url=base_url,
            headers={"X-Api-Key": api_key},
            verify=verify_ssl,
            timeout=30.0,
        )

    async def get(self, path: str, **kwargs) -> dict:
        response = await self.client.get(path, **kwargs)
        response.raise_for_status()
        return response.json()
```

## API documentation

<!-- scaffold:specialize — replace with actual upstream docs link -->

Upstream API documentation is typically available at:

- `https://my-service.example.com/api/docs` — Swagger/OpenAPI UI
- `https://my-service.example.com/api/v1/openapi.json` — OpenAPI spec
- Official docs: `https://docs.my-service.example.com/api`

## Rate limiting

Respect upstream rate limits:

- Check `X-RateLimit-Remaining` and `Retry-After` headers
- Implement exponential backoff on 429 responses
- Do not parallelize bulk requests without rate awareness
- Log rate limit warnings at `WARN` level

## Testing

Integration tests require a running upstream service:

```bash
# Verify upstream is reachable
curl -sf "$MY_PLUGIN_URL/api/health"

# Run live integration tests
just test-live
```

Live tests are skipped in CI by default. Set `MY_PLUGIN_URL` and `MY_PLUGIN_API_KEY` in the CI environment to enable them.

## Cross-references

- [ENV](../mcp/ENV.md) — all environment variables
- [ARCH](../stack/ARCH.md) — MCP server architecture and data flow
- [TOOLS](../mcp/TOOLS.md) — MCP tool definitions that wrap upstream endpoints
- [GUARDRAILS](../GUARDRAILS.md) — security rules for credential handling
