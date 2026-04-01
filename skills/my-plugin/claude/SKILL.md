---
name: my-plugin
description: This skill should be used when the user asks to query, inspect, create, update, or delete My Plugin resources, or mentions My Plugin by name.
argument-hint: [resource-id] [action] [--json]
disable-model-invocation: false
user-invocable: true
allowed-tools: Bash(curl:*), mcp__my-plugin-mcp__my_plugin
model: sonnet
effort: high
# context: fork
# agent: my-plugin-analyzer
# hooks: {}
# paths:
#   - "my_service_mcp/**"
#   - "tests/**"
# shell: bash
---

# My Plugin Skill

Target path relative to plugin root: `skills/my-plugin/SKILL.md`

This template intentionally shows the full skill shape we expect plugin authors to fill in.

## Frontmatter Reference

Plugin-safe fields shown in the live example:
- `name`
- `description`
- `argument-hint`
- `disable-model-invocation`
- `user-invocable`
- `allowed-tools`
- `model`
- `effort`
- `context`
- `agent`
- `hooks`
- `paths`
- `shell`

Broader notes:
- `description` is the most important field for model-driven invocation.
- `context: fork` and `agent` are paired fields when you want isolated execution.
- Keep optional fields commented out unless the plugin actually needs them.
- No additional Claude skill frontmatter exclusions are currently called out for plugin scope in the bundled docs used here.

## Mode Detection

**MCP mode**: Use when the plugin tool is installed and available.

**HTTP fallback mode**: Use only when MCP tooling is unavailable.

**Credential source**:
- MCP URL from `${user_config.my_service_mcp_url}`
- HTTP URL from `$CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL`
- HTTP auth from `$CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY`

## MCP Mode

Single tool:
- `mcp__my-plugin-mcp__my_plugin`

### Available fields for the tool call

Common fields used by the action/subaction pattern:
- `action`
- `subaction`
- `id`
- `name`
- `query`
- `page`
- `page_size`
- `sort`
- `order`
- `filters`
- `confirm`

### Full action reference

- `list`
- `get`
- `create`
- `update`
- `delete`

### Example invocations

```text
mcp__my-plugin-mcp__my_plugin
  action: "list"
  query: "active"
  page: 1
  page_size: 25
  sort: "created_at"
  order: "desc"
```

```text
mcp__my-plugin-mcp__my_plugin
  action: "get"
  id: "resource-123"
```

```text
mcp__my-plugin-mcp__my_plugin
  action: "create"
  name: "example"
  subaction: "validate"
```

```text
mcp__my-plugin-mcp__my_plugin
  action: "update"
  id: "resource-123"
  subaction: "enable"
```

```text
mcp__my-plugin-mcp__my_plugin
  action: "delete"
  id: "resource-123"
  confirm: true
```

## HTTP Fallback

Use `curl` with `MY_SERVICE_URL` and `MY_SERVICE_API_KEY`.

```bash
# List resources
curl -s "$CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL/api/v1/resources" \
  -H "X-Api-Key: $CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY"

# Get resource
curl -s "$CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL/api/v1/resources/$RESOURCE_ID" \
  -H "X-Api-Key: $CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY"

# Create resource
curl -s -X POST "$CLAUDE_PLUGIN_OPTION_MY_SERVICE_URL/api/v1/resources" \
  -H "X-Api-Key: $CLAUDE_PLUGIN_OPTION_MY_SERVICE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"example"}'
```

## Response Shape

Preferred response contract:
- `success`
- `action`
- `subaction`
- `data`
- `message`
- `errors`
- `timestamp`

## Destructive Operations

Always confirm before delete or irreversible update operations.
