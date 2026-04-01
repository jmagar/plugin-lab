# Scaffold Plan

<!-- Fill in all fields marked with angle brackets. Remove this comment before saving. -->
<!-- Save this file to: docs/scaffold-plans/<YYYYMMDD-HHMMSS>-<plugin-name>.md -->

## Plugin Summary

| Field | Value |
|-------|-------|
| **Plugin name** | `<kebab-case name, e.g., gotify-mcp>` |
| **Description** | `<one sentence: what this plugin does and for whom>` |
| **Target language** | `python` / `rust` / `typescript` |
| **Primary service** | `<name of the external service or API being wrapped>` |
| **Service base URL pattern** | `<e.g., https://<host>/api/v1 or http://localhost:8080>` |
| **Transport** | `stdio + http (dual)` / `stdio only` / `http only` |
| **Starting version** | `0.1.0` |
| **Plan date** | `<YYYYMMDD-HHMMSS>` |

---

## Tool Contract

### Primary Tool: `<tool_name>`

**Action enum** — the valid values for the `action` parameter:

| Action | Description |
|--------|-------------|
| `<action_1>` | `<what this action does>` |
| `<action_2>` | `<what this action does>` |

**Subaction enums** — valid `subaction` values per action:

| Action | Subaction | Description |
|--------|-----------|-------------|
| `<action_1>` | `<subaction_a>` | `<what this subaction does>` |
| `<action_1>` | `<subaction_b>` | `<what this subaction does>` |
| `<action_2>` | `<subaction_c>` | `<what this subaction does>` |

**Parameter shapes:**

```
action: string (required) — one of the action enum values above
subaction: string (required) — one of the subaction enum values for the chosen action
<param_3>: string (optional) — <description and default if any>
<param_4>: number (optional) — <description and default if any>
```

**Error shape:**

```json
{
  "error": "<human-readable message>",
  "code": "<snake_case error code>"
}
```

### Companion Tool: `<tool_name>_help`

Returns a static help object containing:

- Full action/subaction table
- Parameter descriptions for all parameters
- One usage example per action

---

## Service Layer Shape

| Field | Value |
|-------|-------|
| **Protocol** | `REST` / `GraphQL` / `CLI subprocess` / `WebSocket` / `gRPC` |
| **Auth mechanism** | `Bearer token` / `API key header` / `Basic auth` / `None` |
| **Auth header / env var** | `<e.g., Authorization: Bearer ${SERVICE_TOKEN}>` |
| **Base URL env var** | `<e.g., SERVICE_URL>` |
| **Pagination** | `<cursor / offset / none — and page size default>` |
| **Rate limiting** | `<known limits or "unknown">` |
| **TLS** | `Required` / `Optional` / `Not supported` |
| **SDK available** | `<package name and version, or "none — raw HTTP">` |

**Notable API behaviors or constraints:**

- `<e.g., DELETE endpoints require a confirmation header>`
- `<e.g., search results are capped at 100 items>`
- `<e.g., auth token expires every 24 hours>`

---

## Manifest Set

Check all manifests that this plugin will include:

- [ ] `pyproject.toml` / `Cargo.toml` / `package.json`
- [ ] `.claude-plugin/plugin.json`
- [ ] `.codex-plugin/plugin.json`
- [ ] `.mcp.json`
- [ ] `.app.json`
- [ ] `CHANGELOG.md`

**Reason any manifest is omitted:** `<explain or "none omitted">`

---

## Command, Skill, and Agent Surfaces

List only surfaces that are justified by this plugin's actual scope. Leave sections empty if not applicable.

### Claude Commands

| Command file | Slash command | Description |
|-------------|--------------|-------------|
| `commands/<plugin>/<action>.md` | `/<plugin>:<action>` | `<what it does>` |

_If none planned: "No Claude commands in initial scaffold."_

### Skills

| Skill directory | SKILL.md purpose |
|----------------|-----------------|
| `skills/<plugin>/` | `<what the skill covers>` |

_If none planned: "No standalone skill in initial scaffold — tool surfaces the MCP tool directly."_

### Agents

| Agent file | Purpose |
|-----------|---------|
| `agents/<name>.md` | `<what the agent orchestrates>` |

_If none planned: "No agents in initial scaffold."_

### Hooks

| Hook event | Script | Purpose |
|-----------|--------|---------|
| `<e.g., PostToolUse>` | `hooks/scripts/<name>.sh` | `<what it does>` |

_If none planned: "No hooks in initial scaffold."_

---

## Test Strategy

### Live Tests

| Test name | What it tests | Skip guard env var |
|-----------|--------------|-------------------|
| `test_live_<action>` | `<what real call it makes and what it asserts>` | `<SERVICE_URL or equivalent>` |

**Skip guard behavior:** Tests skip (not fail) when the skip guard env var is absent, so CI passes without live credentials.

### Unit / Integration Tests

| Test name | What it covers |
|-----------|---------------|
| `test_<unit>` | `<what is mocked and what is asserted>` |

---

## Docker / Runtime Strategy

| Field | Value |
|-------|-------|
| **Port** | `<chosen port number>` |
| **PORT env var** | `PORT=<chosen port>` |
| **Base image** | `<e.g., python:3.12-slim, rust:1.78-slim, node:22-alpine>` |
| **Volume mounts** | `<paths that must persist, or "none">` |
| **Required env vars at startup** | `<list of env vars entrypoint.sh must validate>` |
| **Health check URL** | `http://localhost:${PORT}/health` |
| **Restart policy** | `unless-stopped` |

---

## Open Questions

Questions that must be resolved before implementation starts. Do not begin scaffolding surfaces that depend on these answers.

1. **`<question>`**
   - Blocked surface: `<which file or decision depends on this>`
   - Who can answer: `<plugin author / service owner / user>`

2. **`<question>`**
   - Blocked surface: `<which file or decision depends on this>`
   - Who can answer: `<plugin author / service owner / user>`

_If none: "No open questions — ready to scaffold."_

---

## Next Implementation Step

`<The single most important first action. Be specific: name the file to create or the command to run.>`

Example: "Create `pyproject.toml` from `~/workspace/plugin-templates/py/pyproject.toml`, substituting `my-plugin` → `gotify-mcp` and `my_plugin` → `gotify_mcp`, then run `uv sync` to verify the manifest is valid."
