---
name: lab-research-specialist
description: Research current primary-source guidance for MCP, Claude Code plugins, Codex plugins, and the language/runtime stack used by homelab plugins. Use when the user needs up-to-date information about MCP protocol changes, plugin manifests, SDK versions, transport patterns, package choices, Docker guidance, or the latest official docs needed to scaffold, review, or align a plugin.
---

# Lab Research Specialist

Research current canonical information for homelab plugin work.

## Research Scope

Use this skill for current-information questions involving:

- MCP protocol and transport expectations
- Claude Code plugins and marketplaces
- Codex plugin manifests and app integration
- Python, Rust, and TypeScript MCP SDKs
- Docker, CI, auth, and testing patterns adjacent to plugin work

## Source Rules

Prefer primary sources:

- official docs
- protocol specs
- official SDK repos
- authoritative release notes

Use local repo materials as context, not as proof of what is current.

## Research Workflow

1. Define the exact questions to answer.
2. Gather primary-source evidence for each question.
3. Compare findings against the shared canonical assets in `~/workspace/plugin-templates/`, the relevant `~/workspace/plugin-templates/<lang>/` language layer, or current plugin behavior.
4. Separate facts from recommendations.
5. Summarize the implications for scaffold, review, or alignment work.

## Required Output Shape

Present findings in these buckets:

- confirmed current facts
- changes from prior assumptions
- implications for the language template
- implications for existing plugins
- open uncertainties

## Write Research Artifacts

When the work is substantial, write the result to:

- `docs/research/<topic>-<timestamp>.md`

Include:

- research questions
- sources consulted
- concise fact summary
- recommended template or plugin updates

## Guardrails

Do not guess when the information is likely to have changed.

Do not rely on secondary blog posts when official docs or source repos are available.

Call out when a recommendation is an inference rather than something explicitly stated in the source material.
