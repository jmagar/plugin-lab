# Dispatch Table Patterns

Implementation patterns for the action+subaction dispatch table in each supported language. Each example includes the unknown-action fallback that returns the canonical error shape.

---

## Python

Use a `dict` keyed on `(action, subaction)` tuples. Handlers are `async` functions that take a `params: dict` and return `dict`.

```python
from __future__ import annotations
from typing import Callable, Awaitable

# Type alias for handler functions
Handler = Callable[[dict], Awaitable[dict]]

# --- Handler implementations ---

async def handle_message_create(params: dict) -> dict:
    title = params.get("title")
    message = params.get("message", "")
    if not title:
        return error_response("message", "create", "missing required parameter: title")
    result = await gotify_client.create_message(title=title, message=message)
    return success_response(result)

async def handle_message_list(params: dict) -> dict:
    app_id = params.get("app_id")
    messages = await gotify_client.list_messages(app_id=app_id)
    return success_response(messages)

async def handle_message_delete(params: dict) -> dict:
    message_id = params.get("id")
    if not message_id:
        return error_response("message", "delete", "missing required parameter: id")
    await gotify_client.delete_message(message_id)
    return success_response({"deleted": message_id})

async def handle_application_create(params: dict) -> dict:
    name = params.get("name")
    if not name:
        return error_response("application", "create", "missing required parameter: name")
    result = await gotify_client.create_application(name=name)
    return success_response(result)

async def handle_application_list(params: dict) -> dict:
    apps = await gotify_client.list_applications()
    return success_response(apps)

# --- Dispatch table ---

DISPATCH: dict[tuple[str, str], Handler] = {
    ("message", "create"):      handle_message_create,
    ("message", "list"):        handle_message_list,
    ("message", "delete"):      handle_message_delete,
    ("application", "create"):  handle_application_create,
    ("application", "list"):    handle_application_list,
}

# --- Entry point ---

async def handle_tool(action: str, subaction: str, params: dict) -> dict:
    handler = DISPATCH.get((action, subaction))
    if handler is None:
        known = ", ".join(f"{a}/{s}" for a, s in DISPATCH)
        return error_response(
            action, subaction,
            f"unknown action/subaction. Known pairs: {known}"
        )
    return await handler(params)
```

**Key points:**
- Tuple keys `(action, subaction)` give O(1) lookup and make the table easy to scan.
- Add a new row to `DISPATCH` whenever you add a new handler — the entry point never needs to change.
- The unknown-action fallback lists known pairs to help MCP clients debug bad calls.

---

## Rust

Use a `match` statement on an `(action.as_str(), subaction.as_str())` tuple. Handlers return `Result<Value, String>` and the entry point converts errors to the canonical error shape.

```rust
use serde_json::{json, Value};

// --- Handler implementations ---

async fn handle_message_create(params: &Value) -> Result<Value, String> {
    let title = params["title"]
        .as_str()
        .ok_or("missing required parameter: title")?;
    let message = params["message"].as_str().unwrap_or("");
    let result = gotify_client::create_message(title, message)
        .await
        .map_err(|e| e.to_string())?;
    Ok(json!(result))
}

async fn handle_message_list(params: &Value) -> Result<Value, String> {
    let app_id = params["app_id"].as_u64();
    let messages = gotify_client::list_messages(app_id)
        .await
        .map_err(|e| e.to_string())?;
    Ok(json!(messages))
}

async fn handle_application_create(params: &Value) -> Result<Value, String> {
    let name = params["name"]
        .as_str()
        .ok_or("missing required parameter: name")?;
    let result = gotify_client::create_application(name)
        .await
        .map_err(|e| e.to_string())?;
    Ok(json!(result))
}

// --- Entry point ---

pub async fn handle_tool(action: &str, subaction: &str, params: &Value) -> Value {
    let result = match (action, subaction) {
        ("message", "create")     => handle_message_create(params).await,
        ("message", "list")       => handle_message_list(params).await,
        ("application", "create") => handle_application_create(params).await,
        _ => Err(format!(
            "unknown action/subaction: {}/{}. \
             Known pairs: message/create, message/list, application/create",
            action, subaction
        )),
    };

    match result {
        Ok(data) => json!({
            "isError": false,
            "content": [{"type": "text", "text": data.to_string()}]
        }),
        Err(reason) => json!({
            "isError": true,
            "content": [{"type": "text", "text": format!("Error: {}/{} failed — {}", action, subaction, reason)}]
        }),
    }
}
```

**Key points:**
- The `match` arm `_ =>` is the unknown-action fallback — it must always be present.
- Handlers return `Result<Value, String>` so the entry point can apply a uniform error shape.
- Add new arms to the `match` as you add handlers. The compiler will warn if you introduce a new arm that shadows the wildcard unexpectedly.

---

## TypeScript

Use a `Map` keyed on `"action/subaction"` strings. Handlers are `async` functions typed with a union of known action/subaction values.

```typescript
import { errorResponse, successResponse } from "./responses.js";

// --- Type definitions ---

type Action = "message" | "application";
type Subaction = "create" | "list" | "delete";
type HandlerKey = `${Action}/${Subaction}`;
type Handler = (params: Record<string, unknown>) => Promise<McpToolResult>;

// --- Handler implementations ---

async function handleMessageCreate(params: Record<string, unknown>): Promise<McpToolResult> {
  const title = params["title"];
  if (typeof title !== "string" || !title) {
    return errorResponse("message", "create", "missing required parameter: title");
  }
  const message = typeof params["message"] === "string" ? params["message"] : "";
  const result = await gotifyClient.createMessage({ title, message });
  return successResponse(result);
}

async function handleMessageList(params: Record<string, unknown>): Promise<McpToolResult> {
  const appId = typeof params["app_id"] === "number" ? params["app_id"] : undefined;
  const messages = await gotifyClient.listMessages({ appId });
  return successResponse(messages);
}

async function handleApplicationCreate(params: Record<string, unknown>): Promise<McpToolResult> {
  const name = params["name"];
  if (typeof name !== "string" || !name) {
    return errorResponse("application", "create", "missing required parameter: name");
  }
  const result = await gotifyClient.createApplication({ name });
  return successResponse(result);
}

// --- Dispatch table ---

const DISPATCH = new Map<HandlerKey, Handler>([
  ["message/create",     handleMessageCreate],
  ["message/list",       handleMessageList],
  ["application/create", handleApplicationCreate],
]);

// --- Entry point ---

export async function handleTool(
  action: string,
  subaction: string,
  params: Record<string, unknown>
): Promise<McpToolResult> {
  const key = `${action}/${subaction}` as HandlerKey;
  const handler = DISPATCH.get(key);
  if (handler === undefined) {
    const known = Array.from(DISPATCH.keys()).join(", ");
    return errorResponse(action, subaction, `unknown action/subaction. Known pairs: ${known}`);
  }
  return handler(params);
}
```

**Key points:**
- `Map` with string keys (`"action/subaction"`) is simpler than a nested object and has O(1) lookup.
- The `HandlerKey` template literal type catches typos in table entries at compile time.
- The unknown-action fallback enumerates known pairs from the map itself, so it stays accurate as you add handlers.
- Add new entries to `DISPATCH` as you add handler functions — the entry point never needs to change.

---

## Choosing a Pattern

| Language | Pattern | Key type | Unknown-action fallback |
|----------|---------|----------|------------------------|
| Python | `dict` | `tuple[str, str]` | `.get()` returns `None` |
| Rust | `match` | `(action, subaction)` string pair | `_` wildcard arm |
| TypeScript | `Map` | `"action/subaction"` string | `.get()` returns `undefined` |

In all three languages, the entry point function signature is the same conceptually:

```
handle_tool(action, subaction, params) -> tool_result
```

The dispatch table is an implementation detail hidden behind that entry point.
