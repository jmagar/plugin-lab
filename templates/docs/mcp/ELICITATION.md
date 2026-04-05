# MCP Elicitation

Interactive credential and configuration entry via the MCP elicitation protocol.

<!-- scaffold:specialize -- update env var names and elicitation fields -->

## What is elicitation

Elicitation is an MCP protocol capability that allows servers to request information from users interactively through the client. Instead of requiring pre-configured environment variables, the server can prompt the user for missing values at runtime.

## When to use

- **First-run setup** -- server detects missing `MY_PLUGIN_URL` or `MY_PLUGIN_API_KEY` and prompts the user.
- **Credential rotation** -- user triggers a reconfiguration flow.
- **Destructive operation confirmation** -- gate dangerous actions behind explicit user acknowledgment.
- **Optional configuration** -- collect non-required settings that enhance functionality.

## Implementation pattern

### Detecting missing configuration

On startup or first tool call, check for required environment variables. If missing, return an elicitation request instead of an error.

```
# Pseudocode -- language-agnostic

function handle_tool_call(params):
    if not env.MY_PLUGIN_URL:
        return elicitation_request(
            message="Enter your my-service URL",
            schema={
                "type": "object",
                "properties": {
                    "url": {"type": "string", "format": "uri", "description": "my-service base URL"},
                    "api_key": {"type": "string", "description": "API key for my-service"}
                },
                "required": ["url", "api_key"]
            }
        )

    # Normal tool execution
    return execute_action(params)
```

### Flow

1. Client calls a tool on the server.
2. Server detects missing configuration.
3. Server returns an elicitation response with a JSON Schema describing needed fields.
4. Client renders an interactive form to the user.
5. User fills in values and submits.
6. Client re-invokes the server with the provided values.
7. Server stores configuration and proceeds with the original request.

## Destructive operation confirmation

For operations that modify or delete data, use a two-call confirmation pattern.

### Pattern

1. Client calls destructive action **without** `confirm: true`.
2. Server returns a warning message and instructs the client to re-call with `confirm: true`.
3. Client presents the warning to the user.
4. User approves -- client re-invokes with `confirm: true`.
5. Server executes the destructive operation.

```
# Pseudocode

function handle_delete(params):
    if not params.get("confirm"):
        return {
            "isError": false,
            "content": [{
                "type": "text",
                "text": "WARNING: This will permanently delete item {id}. "
                        "Re-call with confirm=true to proceed."
            }]
        }

    # User confirmed -- execute
    return do_delete(params.id)
```

### YOLO mode

Skip confirmation prompts for automated pipelines:

```bash
MY_PLUGIN_MCP_ALLOW_YOLO=true
```

When set, destructive actions execute immediately without the two-call confirmation. Use only in CI or trusted automation contexts.

## Client support

| Client | Elicitation support | Notes |
|--------|-------------------|-------|
| Claude Code | Yes | Full interactive form rendering |
| Codex CLI | Partial | Text-based prompts |
| Gemini CLI | Partial | Text-based prompts |
| MCP Inspector | Yes | Form rendering in web UI |
| Custom clients | Varies | Depends on implementation |

## Fallback for unsupported clients

When the client does not support elicitation, the server should fall back to clear error messages:

```
# Pseudocode

function handle_missing_config():
    if client_supports_elicitation():
        return elicitation_request(...)
    else:
        return {
            "isError": true,
            "content": [{
                "type": "text",
                "text": "Missing required configuration. Set these environment variables:\n"
                        "  MY_PLUGIN_URL=https://my-service.example.com\n"
                        "  MY_PLUGIN_API_KEY=your-api-key\n"
                        "Then restart the server."
            }]
        }
```

This ensures the user always gets actionable guidance regardless of client capabilities.

See also: [ENV](ENV.md) | [AUTH](AUTH.md) | [PATTERNS](PATTERNS.md)
