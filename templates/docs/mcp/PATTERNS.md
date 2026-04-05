# Common MCP Code Patterns

Reusable patterns across all MCP server implementations.

<!-- scaffold:specialize -- keep only the language-specific examples relevant to this repo -->

## Action + subaction dispatch

The canonical routing pattern. A single tool entry point dispatches to handlers by `action` and optional `subaction`.

### Python (FastMCP)

```python
@app.tool()
async def my_plugin(action: str, subaction: str | None = None, **kwargs) -> str:
    match action:
        case "list_items":
            return await list_items(**kwargs)
        case "docker":
            match subaction:
                case "list":
                    return await docker_list(**kwargs)
                case "start":
                    return await docker_start(**kwargs)
                case _:
                    raise ToolError(f"Unknown subaction: {subaction}")
        case _:
            raise ToolError(f"Unknown action: {action}")
```

### TypeScript

```typescript
server.tool("my_plugin", schema, async (params) => {
  switch (params.action) {
    case "list_items":
      return listItems(params);
    case "docker":
      switch (params.subaction) {
        case "list": return dockerList(params);
        case "start": return dockerStart(params);
        default: throw new ToolError(`Unknown subaction: ${params.subaction}`);
      }
    default:
      throw new ToolError(`Unknown action: ${params.action}`);
  }
});
```

### Rust

```rust
#[derive(Deserialize)]
#[serde(tag = "action", rename_all = "snake_case")]
enum Action {
    ListItems,
    Docker { subaction: DockerSubaction },
}

#[derive(Deserialize)]
#[serde(rename_all = "snake_case")]
enum DockerSubaction {
    List,
    Start,
    Stop,
}
```

## Error handling

Consistent error response format across all tools:

```json
{
  "isError": true,
  "content": [
    {
      "type": "text",
      "text": "Failed to list items: connection refused (my-service at https://my-service.example.com)"
    }
  ]
}
```

### Error middleware (Python)

```python
async def safe_call(fn, *args, **kwargs):
    try:
        return await asyncio.wait_for(fn(*args, **kwargs), timeout=30)
    except asyncio.TimeoutError:
        raise ToolError("Upstream request timed out after 30s")
    except httpx.HTTPStatusError as e:
        raise ToolError(f"Upstream returned {e.response.status_code}: {e.response.text[:200]}")
    except Exception as e:
        raise ToolError(f"Unexpected error: {e}")
```

### HTTP status codes (REST fallback)

| Code | Meaning | When |
|------|---------|------|
| 200 | Success | Normal tool response |
| 401 | Unauthorized | Missing or invalid bearer token |
| 403 | Forbidden | Token valid but insufficient permissions |
| 404 | Not found | Unknown tool or resource |
| 500 | Server error | Unhandled exception |

## Health endpoint

Every MCP server exposes `GET /health` -- unauthenticated, for liveness probes.

```python
@app.get("/health")
async def health():
    return {"status": "ok"}
```

Optionally include upstream reachability:

```python
@app.get("/health")
async def health():
    upstream_ok = await check_upstream()
    return {
        "status": "ok" if upstream_ok else "degraded",
        "upstream": "reachable" if upstream_ok else "unreachable"
    }
```

## Bearer auth middleware

Token validation for HTTP transport. Reads `MY_PLUGIN_MCP_TOKEN` from environment.

```python
class BearerAuth:
    async def authenticate(self, request):
        if os.getenv("MY_PLUGIN_MCP_NO_AUTH", "").lower() == "true":
            return  # Auth disabled

        token = os.environ["MY_PLUGIN_MCP_TOKEN"]
        header = request.headers.get("Authorization", "")
        if header != f"Bearer {token}":
            raise HTTPException(401, "Invalid or missing bearer token")
```

- 401: missing or wrong token.
- 403: token valid but operation not permitted (rare -- most MCP servers are all-or-nothing).

## Destructive operation gate

Two-call confirmation pattern for dangerous actions:

```python
async def handle_delete(item_id: int, confirm: bool = False):
    if not confirm:
        return f"WARNING: This will permanently delete item {item_id}. Re-call with confirm=True to proceed."

    await client.delete(f"/items/{item_id}")
    return f"Deleted item {item_id}"
```

Set `MY_PLUGIN_MCP_ALLOW_YOLO=true` to skip confirmation in automated pipelines.

See [ELICITATION](ELICITATION.md) for the full confirmation flow.

## Help tool

Companion tool that returns markdown reference for all actions:

```python
@app.tool()
async def my_plugin_help() -> str:
    return """# my-plugin actions

| Action | Subaction | Description |
|--------|-----------|-------------|
| list_items | -- | List all items |
| get_item | -- | Get item by ID |
| delete_item | -- | Delete item (requires confirm=True) |
| health | -- | Check upstream connectivity |
"""
```

Every MCP server ships a `*_help` tool. This is the client's first point of reference.

## Upstream API client wrapper

Reusable HTTP client with auth and timeout:

```python
class MyServiceClient:
    def __init__(self):
        self.base_url = os.environ["MY_PLUGIN_URL"].rstrip("/")
        self.api_key = os.environ["MY_PLUGIN_API_KEY"]
        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            headers={"X-Api-Key": self.api_key},
            timeout=30.0,
        )

    async def get(self, path: str, **kwargs):
        resp = await self.client.get(path, **kwargs)
        resp.raise_for_status()
        return resp.json()
```

## Environment loading

### Python

```python
from dotenv import load_dotenv
load_dotenv()  # Reads .env file

url = os.environ["MY_PLUGIN_URL"]        # Required -- raises KeyError if missing
port = int(os.getenv("MY_PLUGIN_MCP_PORT", "8000"))  # Optional with default
```

### TypeScript

```typescript
import "dotenv/config";

const url = process.env.MY_PLUGIN_URL!;
const port = parseInt(process.env.MY_PLUGIN_MCP_PORT ?? "8000");
```

### Rust

```rust
dotenvy::dotenv().ok();
let url = std::env::var("MY_PLUGIN_URL").expect("MY_PLUGIN_URL required");
let port: u16 = std::env::var("MY_PLUGIN_MCP_PORT")
    .unwrap_or_else(|_| "8000".into())
    .parse()
    .expect("MY_PLUGIN_MCP_PORT must be a number");
```

## Graceful shutdown

Handle SIGTERM and SIGINT for clean container stops:

```python
import signal, asyncio

async def shutdown(sig, loop):
    logger.info(f"Received {sig.name}, shutting down...")
    tasks = [t for t in asyncio.all_tasks() if t is not asyncio.current_task()]
    for task in tasks:
        task.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)
    loop.stop()

loop = asyncio.get_event_loop()
for sig in (signal.SIGTERM, signal.SIGINT):
    loop.add_signal_handler(sig, lambda s=sig: asyncio.create_task(shutdown(s, loop)))
```

## Structured logging

```python
import logging, json

class JSONFormatter(logging.Formatter):
    def format(self, record):
        return json.dumps({
            "ts": self.formatTime(record),
            "level": record.levelname,
            "msg": record.getMessage(),
            "module": record.module,
        })

handler = logging.StreamHandler()
handler.setFormatter(JSONFormatter())
logger = logging.getLogger("my_plugin")
logger.addHandler(handler)
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))
```

See also: [DEV](DEV.md) | [ELICITATION](ELICITATION.md) | [LOGS](LOGS.md)
