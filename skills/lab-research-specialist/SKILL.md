---
name: lab-research-specialist
description: Research current primary-source guidance for MCP, Claude Code plugins, Codex plugins, and the language/runtime stack used by homelab plugins. Use when the user asks "what changed in the MCP SDK", "is this transport pattern still current", "find the latest docs for X", "before I scaffold this plugin I need to know...", or any time up-to-date information about MCP protocol changes, plugin manifests, SDK versions, transport patterns, package choices, Docker guidance, or the latest official docs is needed to scaffold, review, or align a plugin.
---

# Lab Research Specialist

Research current canonical information for homelab plugin work. This skill exists because local templates and past notes go stale — the only reliable way to know what is current is to consult primary sources before acting.

## Research Scope

Use this skill for current-information questions involving:

- MCP protocol and transport expectations (stdio, HTTP+SSE, Streamable HTTP)
- Claude Code plugins, marketplaces, manifest schema, and skill formats
- Codex plugin manifests and app integration
- Python, Rust, and TypeScript MCP SDKs — version constraints, breaking changes, new patterns
- FastMCP variants (Python and TypeScript)
- Docker multi-stage build guidance, Compose healthcheck patterns
- GitHub Actions runner versions, action versions, CI pattern changes
- Auth, rate-limit, and testing patterns adjacent to plugin work

## Why Local Materials Are Not Sufficient

Local repo materials — `~/workspace/plugin-templates/`, language layer dirs, existing plugins — are useful as context but cannot be treated as proof of what is current. They reflect a past state of external specs. An SDK may have shipped a breaking release after the template was written. The MCP transport spec may have deprecated a pattern. A plugin manifest field may have been renamed or removed.

The consequence: scaffolding or alignment work done from local materials alone can produce a plugin that compiles and passes internal checks but fails at runtime because it relies on a superseded API. Research is the step that prevents this.

Use local repo materials to understand the current template shape, not to validate that the template shape is still correct against the upstream spec.

## Source Rules

Prefer primary sources in this order:

1. Official protocol specifications (modelcontextprotocol.io, GitHub spec repo)
2. Official SDK repositories (source code is ground truth when docs lag)
3. Official language registry entries (PyPI, crates.io, npm) for version and changelog data
4. Official release notes and changelogs
5. Local repo materials as context — never as proof of currency

Do not use secondary blog posts, tutorials, or community discussions as primary evidence. Use them only to locate primary sources faster.

**Rate-limited or login-gated sources:** If a primary source requires authentication or is rate-limited, use web search to extract a current summary. State explicitly in the research output that the source was accessed indirectly and that the finding may be incomplete. Do not omit the limitation — a clearly flagged partial answer is more useful than a confident answer with hidden gaps.

## Research Workflow

**Step 1 — Define the exact questions.**

Write down what you need to know before fetching anything. Vague research produces vague answers. Good research questions are specific: "Does the MCP Python SDK ≥1.5 require a different lifespan handler signature?" is answerable. "What is new in MCP?" is not.

**Step 2 — Gather primary-source evidence for each question.**

Consult the sources listed in `references/approved-sources.md`. For each question, identify which source is authoritative and fetch from it directly. Record the source URL, the date accessed, and the specific section or version that contains the answer.

**Step 3 — Compare findings against local canonical assets.**

After gathering primary-source evidence, compare it against the shared assets in `~/workspace/plugin-templates/` and the relevant language layer (`~/workspace/plugin-templates/py/`, `~/workspace/plugin-templates/rs/`, or `~/workspace/plugin-templates/ts/`).

A **confirmation** looks like: "The current MCP SDK README shows the same lifespan handler pattern used in `~/workspace/plugin-templates/py/my_plugin_mcp/server.py`. No update required."

A **conflict** looks like: "The MCP Python SDK changelog for v1.6.0 introduces `FastMCP.run(transport=...)` as the new entrypoint, replacing the `mcp.server.stdio.stdio_server()` context manager used in the local template. The local template is one major version behind."

When a primary source conflicts with the local template, the primary source wins. The local template must be updated, not defended. Document the conflict explicitly — do not silently discard one side.

When primary sources conflict with each other (for example, the protocol spec and an SDK implementation disagree), apply this precedence: prefer the more recent document; when recency is equal, prefer the official protocol spec over SDK implementation; prefer SDK implementation over any generated or derived documentation. Document the conflict explicitly in the output regardless of which side wins.

**Step 4 — Separate facts from recommendations.**

Facts are things the source states directly. Recommendations are inferences about what the template or plugin should do as a result. Keep them in separate output sections. Do not present a recommendation as if it were a stated fact.

**Step 5 — Summarize the implications.**

For each conflict or change found, produce at least one concrete implication statement. An implication statement names both the upstream change and the downstream action required.

Examples of well-formed implication statements:

- "The MCP SDK now requires the `lifespan` parameter to be an async context manager (changed in v1.6.0), which means the scaffold template's `server.py` startup section needs to be rewritten to use `@asynccontextmanager`."
- "The Claude Code plugin.json schema added a required `minVersion` field as of the March 2025 spec release, which means existing plugins scaffolded before that date will fail manifest validation unless the field is added."
- "The GitHub-hosted `ubuntu-latest` runner now defaults to Ubuntu 24.04, which means any CI step relying on Python 3.9 system packages will fail — the workflow must pin the Python version explicitly."

Vague implication statements ("this might affect the template") are not acceptable. Name the specific file, section, or field that needs to change.

## Required Output Shape

Present findings in these buckets:

**Confirmed current facts** — things that are true now per primary sources, with citations.

**Changes from prior assumptions** — things the local template or prior notes assumed that are no longer accurate.

**Implications for the language template** — concrete, specific changes needed in `~/workspace/plugin-templates/<lang>/`.

**Implications for existing plugins** — changes that affect already-deployed plugins, not just new scaffolds.

**Open uncertainties** — questions that could not be resolved from available sources.

For the open uncertainties bucket: surface an uncertainty rather than attempting to resolve it when resolution would require running code against a live service, accessing credentials you do not have, or testing behavior that only manifests at runtime. Resolve an uncertainty before writing the output when a quick doc check or source read would settle it — do not surface something as uncertain when one more lookup would answer it. When you surface an uncertainty, state clearly what evidence would resolve it.

## Write Research Artifacts

When the work is substantial or when the findings will be consumed by another skill (scaffold, align, review), write the result to:

- `docs/research/<topic>-<YYYYMMDD-HHMMSS>.md`

The timestamp format is `YYYYMMDD-HHMMSS` (e.g., `20260401-143022`).

Include:

- the specific research questions that drove the work
- sources consulted, with access dates
- concise fact summary per question
- recommended template or plugin updates, each linked to a specific finding
- open uncertainties with notes on what evidence would resolve them

## Guardrails

Do not guess when information is likely to have changed. If a spec, SDK, or runtime has had a release since the template was last updated, assume it may contain breaking changes and verify.

Do not rely on secondary blog posts when official docs or source repos are available.

Call out explicitly when a recommendation is an inference rather than something directly stated in the source material. Use language like "this implies" or "based on the pattern shown in X, the likely update is..." rather than asserting it as fact.

Do not present a single source as definitive when multiple authoritative sources exist and they disagree. Surface the disagreement.

When a source is unexpectedly unavailable (404, timeout, auth wall), note the failure, fall back to the next best source, and flag in the output that the primary source was not accessible.

## Related Skills

- **scaffold-lab-plugin** — consumes research output; uses findings to choose SDK patterns, manifest fields, and CI shapes before generating files
- **align-lab-plugin** — uses research for gap analysis; identifies which local template divergences are caused by upstream spec changes vs. local drift
- **review-lab-plugin** — uses research for canonical spec verification; validates whether a plugin's deviations from the template are caused by a legitimate upstream change or are simply stale
