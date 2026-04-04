# Plugin Lab

Canonical plugin-development toolkit for the homelab ecosystem. This repo contains the live plugin/workspace example, plus the agents, commands, templates, hooks, and reference material used to scaffold, review, align, and ship marketplace-ready MCP plugins.

## What this repository is

`plugin-lab` is not one runtime server. It is the development workspace for plugin creation and enforcement, and it doubles as the working example of how we scaffold and structure plugin repos.

It contains:

- specialized agents for scaffolding, review, alignment, deployment, pipelines, research, and tool design
- slash commands that orchestrate those workflows
- live plugin/workspace files that demonstrate the canonical plugin shape
- template material for generated repos under `templates/`
- reference docs that explain the scaffold contract and implementation patterns
- hook bundles for Claude and Codex

## What ships in this repo

- `agents/`: lab agents such as `ster-the-scaffolder`, `roddy-reviewer`, `ally-the-aligner`, `tilly-the-toolsmith`, `dex-the-deployer`, `petra-the-pipeliner`, and `rex-the-researcher`
- `commands/`: commands such as `/create-lab-plugin`, `/review-lab-plugin`, `/align-lab-plugin`, `/tool-lab-plugin`, `/deploy-lab-plugin`, `/pipeline-lab-plugin`, `/research-lab-plugin`, `/setup-homelab`
- `skills/`: skill-specific implementation guides and references
- `templates/`: canonical scaffold source for generated plugin repos
- `templates/py/`, `templates/ts/`, `templates/rs/`: canonical language templates
- `hooks/claude/`, `hooks/codex/`: hook packs
- `.claude-plugin/`, `.codex-plugin/`, `gemini-extension.json`: plugin manifests for consuming the lab from clients

## Installation

### Marketplace

```bash
/plugin marketplace add jmagar/claude-homelab
/plugin install plugin-lab @jmagar-claude-homelab
```

### Template consumption

Use the commands and agents in this repo to scaffold a new plugin, then copy or adapt the relevant template:

- `bin/` for plugin executables that should be added to `PATH`
- `templates/py/` for Python/FastMCP-style plugins
- `templates/ts/` for TypeScript MCP servers
- `templates/rs/` for Rust-based MCP services

## Canonical workflow surface

### Agents

| Agent | Purpose |
| --- | --- |
| `ster-the-scaffolder` | Scaffold new plugins |
| `roddy-reviewer` | Review plugin repos against the canonical contract |
| `ally-the-aligner` | Apply review findings |
| `tilly-the-toolsmith` | Design and implement MCP tool surfaces |
| `dex-the-deployer` | Deployment packaging and rollout |
| `petra-the-pipeliner` | CI/CD pipeline setup |
| `rex-the-researcher` | SDK and ecosystem research |

### Commands

| Command | Purpose |
| --- | --- |
| `/create-lab-plugin` | Scaffold a new plugin |
| `/review-lab-plugin` | Audit a plugin |
| `/align-lab-plugin` | Apply canonical alignment work |
| `/tool-lab-plugin` | Design/refactor MCP tools |
| `/deploy-lab-plugin` | Add deployment surfaces |
| `/pipeline-lab-plugin` | Add CI/CD workflows |
| `/research-lab-plugin` | Research best practices and standards |
| `/setup-homelab` | Bootstrap shared credentials for the homelab environment |

## Repository layout

```text
agents/      Workflow agents
commands/    Slash commands
skills/      Skill-specific design guidance
bin/         Plugin execution helpers
templates/   Scaffold source root
templates/py/  Python template
templates/ts/  TypeScript template
templates/rs/  Rust template
hooks/       Claude/Codex hooks
docs/        Setup and plugin authoring docs
```

## Development notes

This repo is mostly documentation, templates, and workflow assets. When updating it:

- keep live plugin/workspace examples aligned with the scaffold contract
- keep template manifests aligned with the current ecosystem contract
- keep agent and command docs synchronized
- treat the top-level README as the entrypoint and the language-template READMEs as implementation details

## Verification

Manual verification should include:

```bash
rtk rg -n "^#|^##" README.md docs/plugin-setup-guide.md
rtk rg --files agents commands skills py ts rs hooks
```

When modifying templates, also review the nested READMEs under `templates/py/`, `templates/ts/`, and `templates/rs/`.

## Related files

- `docs/plugin-setup-guide.md`: setup and usage guide
- `templates/py/README.md`: Python template
- `templates/ts/README.md`: TypeScript template
- `templates/rs/README.md`: Rust template
- `CHANGELOG.md`: release history

## License

MIT
