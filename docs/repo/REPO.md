# Repository Structure -- plugin-lab

Complete directory tree and file reference for plugin-lab v1.0.5.

## Directory Tree

```
plugin-lab/
  .claude-plugin/
    plugin.json           Claude Code plugin manifest
    marketplace.json      Marketplace template (scaffold input)
    CLAUDE.md             Manifest directory guidance
    docs/                 Mirrored Claude plugin docs
  .codex-plugin/
    plugin.json           Codex plugin manifest (template shape)
    CLAUDE.md             Manifest directory guidance
    docs/                 Mirrored Codex plugin docs
  .omc/                   Repo-local tooling state
  agents/
    CLAUDE.md             Agent directory guidance
    ster-the-scaffolder.md
    roddy-reviewer.md
    ally-the-aligner.md
    tilly-the-toolsmith.md
    dex-the-deployer.md
    petra-the-pipeliner.md
    rex-the-researcher.md
    docs/                 Mirrored agent format docs
      claude/
      codex/
  commands/
    create-lab-plugin.md
    review-lab-plugin.md
    align-lab-plugin.md
    tool-lab-plugin.md
    deploy-lab-plugin.md
    pipeline-lab-plugin.md
    research-lab-plugin.md
    setup-homelab.md
    claude/               Mirrored command format docs
  skills/
    CLAUDE.md             Skill directory guidance
    scaffold-lab-plugin/
      SKILL.md
      references/
        scaffold-plan-template.md
        surface-to-template-map.md
    review-lab-plugin/
      SKILL.md
      references/
        canonical-spec.md
        review-report-template.md
    align-lab-plugin/
      SKILL.md
      references/
        alignment-report-template.md
        alignment-targets.md
        verification-commands.md
    tool-lab-plugin/
      SKILL.md
      references/
        canonical-error-shape.md
        dispatch-table-patterns.md
        help-tool-template.md
    deploy-lab-plugin/
      SKILL.md
      references/
        compose-healthcheck.md
        dockerfile-patterns.md
    pipeline-lab-plugin/
      SKILL.md
      references/
        ci-workflow-template.md
        live-test-guard-pattern.md
    lab-research-specialist/
      SKILL.md
      references/
        approved-sources.md
    setup/
      SKILL.md
      references/
        service-credentials-guide.md
      scripts/
        setup-creds.sh
    docs/                 Mirrored skill format docs
      claude/
      codex/
      example-plugin/
  templates/
    py/                   Python/FastMCP template (self-contained)
    ts/                   TypeScript/MCP SDK template (self-contained)
    rs/                   Rust/rmcp template (self-contained)
    docs/                 Documentation templates (scaffold input)
      mcp/                MCP server doc templates
      plugin/             Plugin surface doc templates
      repo/               Repository doc templates
      stack/              Stack doc templates
      upstream/           Upstream service doc templates
    .agents/              Template agent scaffolds
    .claude-plugin/       Template manifest scaffolds
    .codex-plugin/        Template Codex manifest scaffolds
    agents/               Template agent files
    assets/               Template asset files
    bin/                  Template executable helpers
    commands/             Template command files
    hooks/                Template hook files
    output-styles/        Template output style files
    skills/               Template skill files
    tests/                Template test files
  hooks/
    CLAUDE.md             Hook directory guidance
    scripts/
      sync-env.sh
      fix-env-perms.sh
      ensure-ignore-files.sh
    docs/                 Mirrored hook format docs
      claude/
      codex/
  scripts/
    scaffold-plugin.sh    Generate new plugin from templates
    lint-plugin.sh        Comprehensive plugin linter
    check-version-sync.sh Version sync validator
    ensure-ignore-files.sh Ignore file enforcer
    check-docker-security.sh Docker security audit
    check-no-baked-env.sh Baked env var detector
    check-outdated-deps.sh Dependency freshness checker
    validate-marketplace.sh Marketplace JSON validator
    update-doc-mirrors.sh Doc mirror refresher
    sync-env.sh           Env sync (repo-level)
    fix-env-perms.sh      Permission fixer (repo-level)
  docs/
    CLAUDE.md             Docs directory guidance
    plugin-setup-guide.md Full canonical spec reference
    scaffold-template-mapping.md Root-to-template mapping
    mcp-testing-standard.md MCP testing standard
    plans/                Planning artifacts
    reports/              Review and alignment outputs
    research/             Research artifacts
    sessions/             Session notes
    superpowers/          Superpowers skill references
    plugin/               Plugin surface docs (this docs set)
    repo/                 Repository docs (this docs set)
    stack/                Stack docs (this docs set)
  output-styles/
    CLAUDE.md
    docs/                 Mirrored output-style docs
  bin/
    CLAUDE.md             Executable helper guidance
  tests/
    CLAUDE.md             Test guidance for scaffolded plugins
  actions/
    mcp-integration/      MCP integration action templates
  assets/                 Plugin assets (icons, logos)
  .env.example            Template .env for scaffolded plugins
  .gitignore              Git ignore rules
  CLAUDE.md               Repo-level working instructions
  README.md               User-facing documentation
  CHANGELOG.md            Release history
  LICENSE                 MIT license
  gemini-extension.json   Gemini extension manifest
```

## Root Files

| File | Purpose |
| --- | --- |
| `CLAUDE.md` | Working instructions and single-source-of-truth rules |
| `README.md` | User-facing documentation (skills, agents, commands, templates, usage) |
| `CHANGELOG.md` | Version history in Keep a Changelog format |
| `LICENSE` | MIT license |
| `.env.example` | Template env file for scaffolded plugins |
| `.gitignore` | Git ignore patterns |
| `gemini-extension.json` | Gemini extension manifest |

## Key Directories

| Directory | Content | Scaffold input? |
| --- | --- | --- |
| `agents/` | 7 agent definitions for plugin-lab | No |
| `commands/` | 8 slash command definitions | No |
| `skills/` | 8 skill definitions with references | No |
| `templates/` | Canonical scaffold source for generated plugins | Yes |
| `hooks/` | 3 hook scripts for lifecycle events | No |
| `scripts/` | 11 repo maintenance and validation scripts | No |
| `docs/` | Human-facing documentation about plugin-lab | No |
| `bin/` | Executable helper guidance | Template guidance |
| `tests/` | Test guidance for scaffolded plugins | Template guidance |
| `output-styles/` | Reserved scaffold surface | Template guidance |

## Docs vs Templates Boundary

- `docs/` explains plugin-lab itself
- `templates/` defines output for generated plugin repos
- `templates/docs/` contains doc templates that are scaffold input, not plugin-lab docs

Keep this separation strict.
