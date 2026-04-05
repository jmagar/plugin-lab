# Skill Definitions — my-plugin

Patterns for defining skills (domain knowledge modules) within a Claude Code plugin.

## Directory structure

```
skills/
  my-service/
    SKILL.md                  # Skill definition (required)
    references/
      api-endpoints.md        # REST API documentation
      quick-reference.md      # Common operations cheat sheet
      troubleshooting.md      # Known issues and fixes
```

## SKILL.md frontmatter

```yaml
---
name: my-service
description: |
  Manages my-service instances. Activate when the user mentions
  my-service, MyPlugin, or asks about [relevant domain].
homepage: https://my-service.example.com
---
```

| Field | Required | Description |
| --- | --- | --- |
| `name` | yes | Skill identifier (matches directory name) |
| `description` | yes | Trigger phrases for auto-invocation by Claude Code |
| `homepage` | no | Upstream project URL |

Do not add fields the schema does not support (e.g., `version`). Check the active skill schema before adding optional fields.

## Body sections

The SKILL.md body follows a fixed structure:

```markdown
# my-service

## Purpose
One paragraph: what this skill does and when to use it.

## Setup
Prerequisites, credentials, and verification steps.

## Commands
Available operations with syntax and examples.

## Workflows
Multi-step procedures and decision trees.

## Notes
Caveats, limitations, and edge cases.

## References
Links to files in references/ for detailed documentation.
```

## Progressive disclosure

Skills use three levels of detail, loaded on demand:

| Level | Content | Size | When loaded |
| --- | --- | --- | --- |
| 1 — Metadata | Frontmatter | ~100 words | Always (skill discovery) |
| 2 — Body | SKILL.md body | ~2,000 words | On skill activation |
| 3 — References | `references/*.md` | Unlimited | On explicit request |

Keep SKILL.md concise. Move detailed API docs, troubleshooting guides, and reference tables into `references/`.

## References directory

| File | Purpose | When to include |
| --- | --- | --- |
| `api-endpoints.md` | REST/GraphQL API reference | Services with HTTP APIs |
| `command-reference.md` | CLI tool reference | CLI-based tools |
| `library-reference.md` | SDK/library docs | Library integrations |
| `config-reference.md` | Configuration schema | Complex configuration |
| `quick-reference.md` | Common operations cheat sheet | Always |
| `troubleshooting.md` | Known issues and fixes | Always |

## Mode detection

Skills that wrap an MCP server should detect the available transport:

```markdown
## Setup

### MCP mode (preferred)
When installed as a Claude Code plugin, my-service tools are available
directly via MCP. No additional configuration needed.

### HTTP fallback
If MCP is unavailable, use curl against the my-service API:

curl -H "Authorization: Bearer $MY_PLUGIN_API_KEY" \
  "$MY_PLUGIN_URL/api/v1/status"
```

## Mandatory invocation block

Every SKILL.md must include a block listing when the skill should activate:

```markdown
## When to invoke this skill

Activate this skill when the user:
- Asks about my-service status, health, or configuration
- Wants to search, create, or manage my-service resources
- Mentions "my-service", "MyPlugin", or related terms
- Needs to troubleshoot my-service connectivity or errors
```

## Example SKILL.md template

<!-- scaffold:specialize — replace with actual service details -->

````markdown
---
name: my-service
description: |
  Manages my-service. Activate when the user mentions my-service,
  MyPlugin, or asks about [domain].
homepage: https://my-service.example.com
---

# my-service

## When to invoke this skill

Activate when the user:
- Asks about my-service status or health
- Wants to query or manage my-service resources
- Mentions "my-service" or "MyPlugin"

## Purpose

Provides tools for interacting with a my-service instance: health checks,
resource queries, and management operations.

## Setup

### Prerequisites
- my-service instance accessible at `MY_PLUGIN_URL`
- API key configured in `.env` as `MY_PLUGIN_API_KEY`

### Verify
```bash
curl -s -H "Authorization: Bearer $MY_PLUGIN_API_KEY" \
  "$MY_PLUGIN_URL/api/v1/health" | jq .
```

## Commands

### Check health
```bash
curl -s "$MY_PLUGIN_URL/api/v1/health" | jq .status
```

### List resources
```bash
curl -s -H "Authorization: Bearer $MY_PLUGIN_API_KEY" \
  "$MY_PLUGIN_URL/api/v1/resources" | jq '.items[:5]'
```

## Workflows

### Diagnose connectivity
1. Check if service is reachable: `curl -s -o /dev/null -w '%{http_code}' $MY_PLUGIN_URL/health`
2. If 401: verify `MY_PLUGIN_API_KEY` in `.env`
3. If timeout: check container status with `docker ps | grep my-service`

## Notes

- API rate limits: 100 requests/minute
- Responses truncated at 500 items by default

## References

- [API Endpoints](references/api-endpoints.md) — Full REST API reference
- [Quick Reference](references/quick-reference.md) — Common operations
- [Troubleshooting](references/troubleshooting.md) — Known issues
````

## Cross-references

- [AGENTS.md](AGENTS.md) — Agents that delegate to skills
- [COMMANDS.md](COMMANDS.md) — Slash commands that may reference skills
- See [INVENTORY](../INVENTORY.md) for the complete component list
