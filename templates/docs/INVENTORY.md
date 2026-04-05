# Component Inventory — my-plugin

Complete listing of all plugin components.

## MCP tools

<!-- scaffold:specialize — replace with actual tools -->

| Tool | Action | Subaction | Description | Destructive |
| --- | --- | --- | --- | --- |
| `my_plugin` | `list_items` | — | List all items | no |
| `my_plugin` | `get_item` | — | Get item by ID | no |
| `my_plugin` | `create_item` | — | Create a new item | no |
| `my_plugin` | `delete_item` | — | Delete an item | yes |
| `my_plugin` | `health` | — | Check upstream service health | no |
| `my_plugin_help` | — | — | Return action reference as Markdown | no |

## MCP resources

<!-- scaffold:specialize — add if the server exposes MCP resources -->

| URI | Description | MIME type |
| --- | --- | --- |
| — | No resources exposed | — |

## Environment variables

| Variable | Required | Default | Sensitive |
| --- | --- | --- | --- |
| `MY_PLUGIN_URL` | yes | — | no |
| `MY_PLUGIN_API_KEY` | yes | — | yes |
| `MY_PLUGIN_MCP_HOST` | no | `0.0.0.0` | no |
| `MY_PLUGIN_MCP_PORT` | no | `8000` | no |
| `MY_PLUGIN_MCP_TOKEN` | yes* | — | yes |
| `MY_PLUGIN_MCP_TRANSPORT` | no | `http` | no |
| `MY_PLUGIN_MCP_NO_AUTH` | no | `false` | no |
| `LOG_LEVEL` | no | `INFO` | no |
| `MY_PLUGIN_LOG_FILE` | no | `logs/my_plugin.log` | no |
| `ALLOW_DESTRUCTIVE` | no | `false` | no |
| `ALLOW_YOLO` | no | `false` | no |
| `PUID` | no | `1000` | no |
| `PGID` | no | `1000` | no |
| `DOCKER_NETWORK` | no | — | no |

## Plugin surfaces

<!-- scaffold:specialize — check/uncheck as applicable -->

| Surface | Present | Path |
| --- | --- | --- |
| Skills | yes | `skills/my-plugin/SKILL.md` |
| Agents | no | — |
| Commands | no | — |
| Hooks | yes | `hooks/` |
| Channels | no | — |
| Output styles | no | — |
| Schedules | no | — |

## Docker

| Component | Value |
| --- | --- |
| Image | `ghcr.io/jmagar/my-plugin:latest` |
| Port | `8000` |
| Health endpoint | `GET /health` (unauthenticated) |
| Compose file | `docker-compose.yml` |
| Entrypoint | `entrypoint.sh` |
| User | `1000:1000` |

## CI/CD workflows

<!-- scaffold:specialize — list actual workflow files -->

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| `ci.yml` | push, PR | Lint, typecheck, test |
| `docker.yml` | tag push | Build and publish Docker image |
| `mcp-integration.yml` | PR | Live MCP integration test |

## Scripts

<!-- scaffold:specialize — list actual scripts -->

| Script | Purpose |
| --- | --- |
| `scripts/smoke-test.sh` | Smoke test against running server |
| `scripts/contract-check.sh` | Verify tool schema against spec |

## Dependencies

### Runtime

<!-- scaffold:specialize — list actual runtime deps -->

| Package | Purpose |
| --- | --- |
| `fastmcp` | MCP server framework |
| `httpx` | Async HTTP client |
| `pydantic` | Data validation |

### Development

<!-- scaffold:specialize — list actual dev deps -->

| Package | Purpose |
| --- | --- |
| `pytest` | Test framework |
| `ruff` | Linter and formatter |
| `pre-commit` | Git hook management |
