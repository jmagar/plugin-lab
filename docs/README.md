# Plugin Lab Documentation

Reference documentation for `plugin-lab` v1.0.5, the canonical plugin-development toolkit for the homelab MCP ecosystem.

## What plugin-lab does

plugin-lab provides the agents, skills, commands, templates, hooks, and scripts needed to scaffold, review, align, tool, deploy, and pipeline homelab MCP plugins. It is not a runtime server. It is the working example of the canonical plugin shape.

## Plugin lifecycle

A plugin moves through six phases, each with a dedicated skill, agent, and command:

```
scaffold --> review --> align --> tool --> deploy --> pipeline
```

1. **scaffold** (`/create-lab-plugin`) -- Create the repo, manifests, and initial tool stubs from a concrete plan.
2. **review** (`/review-lab-plugin`) -- Audit every canonical surface against the spec. Produce a findings report.
3. **align** (`/align-lab-plugin`) -- Implement every finding from the review. Preserve justified deviations.
4. **tool** (`/tool-lab-plugin`) -- Design and implement MCP tool contracts using the action+subaction pattern.
5. **deploy** (`/deploy-lab-plugin`) -- Containerize with a multi-stage Dockerfile, entrypoint, and Compose stack.
6. **pipeline** (`/pipeline-lab-plugin`) -- Add CI/CD: test gate, image publishing, automated releases, pre-commit hooks.

Phases are not strictly sequential. Run `/review-lab-plugin` on any existing plugin at any time. Run `/research-lab-plugin` before scaffolding when the target SDK is unfamiliar.

## Documentation index

### Root-level docs

| File | Purpose |
| --- | --- |
| [README.md](README.md) | This file -- documentation overview and lifecycle summary |
| [SETUP.md](SETUP.md) | Step-by-step setup: clone, install plugin, configure credentials |
| [CONFIG.md](CONFIG.md) | Environment variables, userConfig, and `.env` conventions |
| [CHECKLIST.md](CHECKLIST.md) | Pre-release quality checklist for plugins built with plugin-lab |
| [GUARDRAILS.md](GUARDRAILS.md) | Security guardrails enforced across all plugin surfaces |
| [INVENTORY.md](INVENTORY.md) | Complete component inventory: skills, agents, commands, scripts, hooks |

### Subdirectories

| Directory | Scope |
| --- | --- |
| [plugin/](plugin/CLAUDE.md) | Plugin system: manifests, agents, skills, commands, hooks, channels |
| [repo/](repo/CLAUDE.md) | Repository: structure, scripts, rules, memory |
| [stack/](stack/CLAUDE.md) | Technology stack: architecture, template system, prerequisites |

### Existing docs (unchanged)

| File | Purpose |
| --- | --- |
| [plugin-setup-guide.md](plugin-setup-guide.md) | Full canonical plugin spec reference (137KB) |
| [scaffold-template-mapping.md](scaffold-template-mapping.md) | Root-to-template mapping decisions |
| [mcp-testing-standard.md](mcp-testing-standard.md) | MCP testing standard with mcporter |

## Quick start

```bash
# Install as a Claude Code plugin
/plugin marketplace add jmagar/claude-homelab
/plugin install plugin-lab @jmagar-claude-homelab

# Or use locally
cd ~/workspace/plugin-lab

# Scaffold a new plugin
/create-lab-plugin my-service-mcp "Wraps the My Service API"

# Review an existing plugin
/review-lab-plugin ~/workspace/my-service-mcp

# Research current SDK state before scaffolding
/research-lab-plugin "TypeScript MCP server current patterns"
```

## Related plugins

See the [main README](../README.md#related-plugins) for the full homelab plugin ecosystem.
