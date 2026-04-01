# Canonical Error Shape

Every MCP tool call that fails must return a structured error response. Never throw an unhandled exception from a tool handler — always return this shape.

## The Shape

```json
{
  "isError": true,
  "content": [
    {
      "type": "text",
      "text": "Error: <action>/<subaction> failed — <reason>"
    }
  ]
}
```

Field definitions:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `isError` | boolean | yes | Must be `true` for failures |
| `content` | array | yes | Must be a non-empty array |
| `content[0].type` | string | yes | Always `"text"` for error messages |
| `content[0].text` | string | yes | Human-readable error description |

## Why `isError: true` Matters

The MCP protocol distinguishes two types of tool responses:

- **`isError: false`** (or absent): the tool ran successfully and returned content. The MCP client relays the content to the model as a tool result.
- **`isError: true`**: the tool call itself failed. The MCP client surfaces this as a tool failure, which the model can reason about and retry or escalate.

If you return `isError: false` with an error message in the content, the MCP client treats it as a successful response. The model will see the error text but won't know the tool failed — it may not retry or report the failure correctly.

## Language-Specific Helper Functions

### Python

```python
def error_response(action: str, subaction: str, reason: str) -> dict:
    """Return the canonical MCP tool error shape."""
    return {
        "isError": True,
        "content": [
            {
                "type": "text",
                "text": f"Error: {action}/{subaction} failed — {reason}",
            }
        ],
    }

# Usage
async def handle_message_create(params: dict) -> dict:
    title = params.get("title")
    if not title:
        return error_response("message", "create", "missing required parameter: title")
    try:
        result = await gotify_client.create_message(title=title)
        return {"isError": False, "content": [{"type": "text", "text": str(result)}]}
    except Exception as exc:
        return error_response("message", "create", str(exc))
```

### Rust

```rust
use serde_json::{json, Value};

fn error_response(action: &str, subaction: &str, reason: &str) -> Value {
    json!({
        "isError": true,
        "content": [
            {
                "type": "text",
                "text": format!("Error: {}/{} failed — {}", action, subaction, reason)
            }
        ]
    })
}

// Usage
async fn handle_message_create(params: &Value) -> Value {
    let title = match params.get("title").and_then(|v| v.as_str()) {
        Some(t) => t.to_string(),
        None => return error_response("message", "create", "missing required parameter: title"),
    };
    match gotify_client::create_message(&title).await {
        Ok(result) => json!({
            "isError": false,
            "content": [{"type": "text", "text": result.to_string()}]
        }),
        Err(e) => error_response("message", "create", &e.to_string()),
    }
}
```

### TypeScript

```typescript
interface McpContent {
  type: "text";
  text: string;
}

interface McpToolResult {
  isError: boolean;
  content: McpContent[];
}

function errorResponse(action: string, subaction: string, reason: string): McpToolResult {
  return {
    isError: true,
    content: [
      {
        type: "text",
        text: `Error: ${action}/${subaction} failed — ${reason}`,
      },
    ],
  };
}

// Usage
async function handleMessageCreate(params: Record<string, unknown>): Promise<McpToolResult> {
  const title = params["title"];
  if (typeof title !== "string" || !title) {
    return errorResponse("message", "create", "missing required parameter: title");
  }
  try {
    const result = await gotifyClient.createMessage({ title });
    return { isError: false, content: [{ type: "text", text: JSON.stringify(result) }] };
  } catch (err) {
    return errorResponse("message", "create", String(err));
  }
}
```

## Common Mistakes

### Throwing exceptions instead of returning the error shape

```python
# WRONG — unhandled exception crashes the tool call
async def handle_message_create(params):
    if not params.get("title"):
        raise ValueError("title is required")  # Do not do this

# CORRECT
async def handle_message_create(params):
    if not params.get("title"):
        return error_response("message", "create", "missing required parameter: title")
```

### Returning `isError: false` with error text

```python
# WRONG — MCP client sees a "successful" tool call with error text in content
return {
    "isError": False,
    "content": [{"type": "text", "text": "Error: something went wrong"}]
}

# CORRECT
return error_response("message", "create", "something went wrong")
```

### Missing the `content` array wrapper

```python
# WRONG — not a valid MCP tool result
return {"isError": True, "text": "Error: something went wrong"}

# CORRECT
return {
    "isError": True,
    "content": [{"type": "text", "text": "Error: something went wrong"}]
}
```

### Returning a bare string

```python
# WRONG — not a valid MCP tool result shape at all
return "Error: something went wrong"

# CORRECT
return error_response("message", "create", "something went wrong")
```
