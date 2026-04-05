# Setup Guide

Step-by-step instructions for setting up plugin-lab.

## Prerequisites

- Claude Code CLI installed and authenticated
- Git
- Bash 4+
- `jq` (used by validation scripts)
- Python 3.10+ (used by `check-version-sync.sh` and scaffold scripts)

Optional (for template development):
- Docker and Docker Compose (for container template testing)
- `yamllint` (for CI workflow validation)

## Installation

### Option 1: Claude Code Plugin Marketplace

```bash
/plugin marketplace add jmagar/claude-homelab
/plugin install plugin-lab @jmagar-claude-homelab
```

After installation, all skills, agents, and commands are available immediately.

### Option 2: Local Development

```bash
cd ~/workspace
git clone https://github.com/jmagar/plugin-lab.git
cd plugin-lab
```

Claude Code auto-discovers the `.claude-plugin/plugin.json` when you open the repo. Skills, agents, and commands become available after Claude Code loads the plugin.

## Credential Setup

Run the setup wizard to configure homelab service credentials:

```bash
/setup-homelab
```

This will:
1. Create `~/.claude-homelab/.env` from the template if absent
2. Set `chmod 600` on the env file
3. Walk through service credential groups interactively

To force overwrite an existing `.env`:

```bash
/setup-homelab --force
```

## Verify Installation

After setup, verify that commands are available:

```bash
# These should appear in Claude Code autocomplete:
/create-lab-plugin
/review-lab-plugin
/align-lab-plugin
/tool-lab-plugin
/deploy-lab-plugin
/pipeline-lab-plugin
/research-lab-plugin
/setup-homelab
```

## Template System

The scaffold templates live at `templates/` within this repo:

```
templates/
  py/    Python/FastMCP template
  ts/    TypeScript/MCP SDK template
  rs/    Rust/rmcp template
  docs/  Documentation templates (scaffold input, not plugin-lab docs)
```

The scaffold script at `scripts/scaffold-plugin.sh` reads from these directories. The `PLUGIN_TEMPLATES_ROOT` environment variable can override the template location (defaults to `~/workspace/plugin-templates`).

## Doc Mirror Refresh

Mirrored docs (agent/skill/hook reference docs from Claude and Codex) can be refreshed:

```bash
bash scripts/update-doc-mirrors.sh
```

This fetches the latest upstream markdown docs and overwrites local mirrors. See [SCRIPTS.md](repo/SCRIPTS.md) for details.
