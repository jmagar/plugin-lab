# Component Inventory

Complete inventory of all components in plugin-lab v1.0.5.

## Skills (8)

| Skill | Directory | Command | Description |
| --- | --- | --- | --- |
| `scaffold-lab-plugin` | `skills/scaffold-lab-plugin/` | `/create-lab-plugin` | Scaffold a new MCP plugin from inputs to a concrete plan |
| `review-lab-plugin` | `skills/review-lab-plugin/` | `/review-lab-plugin` | Audit a plugin against the canonical spec |
| `align-lab-plugin` | `skills/align-lab-plugin/` | `/align-lab-plugin` | Turn review findings into implementation changes |
| `tool-lab-plugin` | `skills/tool-lab-plugin/` | `/tool-lab-plugin` | Design MCP tools using the action+subaction pattern |
| `deploy-lab-plugin` | `skills/deploy-lab-plugin/` | `/deploy-lab-plugin` | Containerize: Dockerfile, entrypoint, Compose, health endpoint |
| `pipeline-lab-plugin` | `skills/pipeline-lab-plugin/` | `/pipeline-lab-plugin` | CI/CD: workflows, pre-commit hooks, Justfile targets |
| `lab-research-specialist` | `skills/lab-research-specialist/` | `/research-lab-plugin` | Primary-source research on MCP, SDKs, runtimes |
| `setup` | `skills/setup/` | `/setup-homelab` | Interactive credential setup for `~/.claude-homelab/.env` |

## Agents (7)

| Agent | File | Color | Skill | Spawned by |
| --- | --- | --- | --- | --- |
| `ster-the-scaffolder` | `agents/ster-the-scaffolder.md` | blue | `scaffold-lab-plugin` | `/create-lab-plugin` |
| `roddy-reviewer` | `agents/roddy-reviewer.md` | red | `review-lab-plugin` | `/review-lab-plugin`, `ally-the-aligner` |
| `ally-the-aligner` | `agents/ally-the-aligner.md` | green | `align-lab-plugin` | `/align-lab-plugin` |
| `tilly-the-toolsmith` | `agents/tilly-the-toolsmith.md` | yellow | `tool-lab-plugin` | `/tool-lab-plugin` |
| `dex-the-deployer` | `agents/dex-the-deployer.md` | green | `deploy-lab-plugin` | `/deploy-lab-plugin` |
| `petra-the-pipeliner` | `agents/petra-the-pipeliner.md` | cyan | `pipeline-lab-plugin` | `/pipeline-lab-plugin` |
| `rex-the-researcher` | `agents/rex-the-researcher.md` | magenta | `lab-research-specialist` | `/research-lab-plugin`, any agent needing research |

## Commands (8)

| Command | File | Agent | Argument |
| --- | --- | --- | --- |
| `/create-lab-plugin` | `commands/create-lab-plugin.md` | ster-the-scaffolder | `<plugin-name> [short description]` |
| `/review-lab-plugin` | `commands/review-lab-plugin.md` | roddy-reviewer (x3) | `<plugin-path>` |
| `/align-lab-plugin` | `commands/align-lab-plugin.md` | ally-the-aligner | `<plugin-path>` |
| `/tool-lab-plugin` | `commands/tool-lab-plugin.md` | tilly-the-toolsmith | `<plugin-path> [create\|review\|update] [tool-name]` |
| `/deploy-lab-plugin` | `commands/deploy-lab-plugin.md` | dex-the-deployer | `<plugin-path> [create\|review\|update]` |
| `/pipeline-lab-plugin` | `commands/pipeline-lab-plugin.md` | petra-the-pipeliner | `<plugin-path> [create\|review\|update]` |
| `/research-lab-plugin` | `commands/research-lab-plugin.md` | rex-the-researcher | `<topic or target stack>` |
| `/setup-homelab` | `commands/setup-homelab.md` | (skill only) | `[--force]` |

## Scripts (11)

| Script | Purpose |
| --- | --- |
| `scripts/scaffold-plugin.sh` | Generate a new plugin from canonical templates |
| `scripts/lint-plugin.sh` | Comprehensive plugin linter (16 check categories) |
| `scripts/check-version-sync.sh` | Verify all version-bearing files match |
| `scripts/ensure-ignore-files.sh` | Ensure .gitignore/.dockerignore have required patterns |
| `scripts/check-docker-security.sh` | Audit Docker config for security issues |
| `scripts/check-no-baked-env.sh` | Verify no env vars baked into Docker images |
| `scripts/check-outdated-deps.sh` | Check for outdated dependencies |
| `scripts/validate-marketplace.sh` | Validate marketplace.json structure and references |
| `scripts/update-doc-mirrors.sh` | Refresh mirrored markdown docs from upstream URLs |
| `scripts/sync-env.sh` | Sync userConfig values into .env |
| `scripts/fix-env-perms.sh` | Fix .env file permissions |

## Hook Scripts (3)

| Script | Location | Trigger |
| --- | --- | --- |
| `sync-env.sh` | `hooks/scripts/sync-env.sh` | SessionStart |
| `fix-env-perms.sh` | `hooks/scripts/fix-env-perms.sh` | PostToolUse |
| `ensure-ignore-files.sh` | `hooks/scripts/ensure-ignore-files.sh` | SessionStart |

## Templates (3 language layers + docs)

| Template | Directory | Runtime |
| --- | --- | --- |
| Python | `templates/py/` | FastMCP |
| TypeScript | `templates/ts/` | Express + MCP SDK |
| Rust | `templates/rs/` | rmcp |
| Documentation | `templates/docs/` | Scaffold input for generated plugin docs |

## Skill References

| Skill | Reference files |
| --- | --- |
| `scaffold-lab-plugin` | `scaffold-plan-template.md`, `surface-to-template-map.md` |
| `review-lab-plugin` | `canonical-spec.md`, `review-report-template.md` |
| `align-lab-plugin` | `alignment-report-template.md`, `alignment-targets.md`, `verification-commands.md` |
| `tool-lab-plugin` | `canonical-error-shape.md`, `dispatch-table-patterns.md`, `help-tool-template.md` |
| `deploy-lab-plugin` | `compose-healthcheck.md`, `dockerfile-patterns.md` |
| `pipeline-lab-plugin` | `ci-workflow-template.md`, `live-test-guard-pattern.md` |
| `lab-research-specialist` | `approved-sources.md` |
| `setup` | `service-credentials-guide.md` |

## Plugin Manifests

| File | Platform |
| --- | --- |
| `.claude-plugin/plugin.json` | Claude Code |
| `.codex-plugin/plugin.json` | OpenAI Codex |
| `gemini-extension.json` | Google Gemini |
