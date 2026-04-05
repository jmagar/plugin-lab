# Configuration Reference

All configuration for plugin-lab and plugins it scaffolds.

## Environment Variables

plugin-lab itself does not run a server, so it has minimal env var requirements. The `.env.example` at the repo root is a **template** for scaffolded plugins, not for plugin-lab itself.

### Template `.env.example` Variables

These variables are placeholders that get renamed during scaffolding:

| Variable | Default | Purpose |
| --- | --- | --- |
| `MY_SERVICE_URL` | `https://your-service.example.com` | Upstream service base URL |
| `MY_SERVICE_API_KEY` | `your_api_key_here` | Upstream service API key |
| `MY_SERVICE_MCP_HOST` | `0.0.0.0` | MCP server bind address |
| `MY_SERVICE_MCP_PORT` | `9000` | MCP server port |
| `MY_SERVICE_MCP_TRANSPORT` | `http` | Transport mode: `http` or `stdio` |
| `MY_SERVICE_MCP_TOKEN` | (empty) | Bearer token for HTTP transport auth |
| `MY_SERVICE_MCP_NO_AUTH` | `false` | Disable authentication (dev only) |
| `MY_SERVICE_MCP_LOG_LEVEL` | `INFO` | Logging level |
| `MY_SERVICE_MCP_ALLOW_YOLO` | `false` | Skip destructive operation confirmation |
| `MY_SERVICE_MCP_ALLOW_DESTRUCTIVE` | `false` | Enable destructive operations |
| `PUID` | `1000` | Container user ID |
| `PGID` | `1000` | Container group ID |
| `DOCKER_NETWORK` | `my-service_mcp` | Docker network name |

During scaffolding, `MY_SERVICE` is replaced with the actual service prefix (e.g., `GOTIFY`, `UNRAID`).

### Homelab Credential Store

All homelab service credentials live in `~/.claude-homelab/.env` (not in the plugin-lab repo). This file is created and managed by the `/setup-homelab` command.

Requirements:
- `chmod 600` permissions
- Never committed to git
- Created from `.env.example` template

## Plugin Manifest Configuration

### `.claude-plugin/plugin.json`

The Claude Code plugin manifest for plugin-lab itself:

| Field | Value |
| --- | --- |
| `name` | `plugin-lab` |
| `version` | `1.0.5` |
| `description` | Agents, commands, skills, and scripts for scaffolding, reviewing, aligning, and deploying homelab MCP server plugins |

### `.codex-plugin/plugin.json`

The Codex plugin manifest. Contains the same version as the Claude manifest. Includes an `interface` section with display metadata.

### `gemini-extension.json`

Gemini extension manifest. Contains `name`, `version`, `description`, and `contextFileName` pointing to `GEMINI.md`.

## Version Sync

All version-bearing files must carry the same version string. The `scripts/check-version-sync.sh` script validates this. Files checked:

- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`
- `gemini-extension.json`
- `Cargo.toml` (if present)
- `package.json` (if present)
- `pyproject.toml` (if present)
- `CHANGELOG.md` (must have an entry for the current version)
