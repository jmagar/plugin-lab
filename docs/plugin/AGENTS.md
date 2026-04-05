# Agent Definitions -- plugin-lab

plugin-lab has 7 specialized agents, one for each phase of the plugin development lifecycle. Each agent reads its corresponding skill before acting.

## Agent Summary

| Agent | Color | Skill | Spawned by | Produces |
| --- | --- | --- | --- | --- |
| ster-the-scaffolder | blue | scaffold-lab-plugin | `/create-lab-plugin` | Scaffold plan + implementation steps |
| roddy-reviewer | red | review-lab-plugin | `/review-lab-plugin`, ally-the-aligner | `docs/reports/plugin-reviews/<ts>.md` |
| ally-the-aligner | green | align-lab-plugin | `/align-lab-plugin` | `docs/reports/plugin-alignments/<ts>.md` |
| tilly-the-toolsmith | yellow | tool-lab-plugin | `/tool-lab-plugin` | Tool contract + handler stubs |
| dex-the-deployer | green | deploy-lab-plugin | `/deploy-lab-plugin` | Dockerfile, entrypoint.sh, docker-compose.yaml |
| petra-the-pipeliner | cyan | pipeline-lab-plugin | `/pipeline-lab-plugin` | Four workflow files + Justfile targets |
| rex-the-researcher | magenta | lab-research-specialist | `/research-lab-plugin`, any agent | `docs/research/<topic>-<ts>.md` |

## Agent Details

### ster-the-scaffolder

**File:** `agents/ster-the-scaffolder.md`
**Tools:** Bash, Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, SendMessage, Skill

Scaffolding orchestrator. Gathers inputs (plugin name, language, description, docs links), inspects supplied context, delegates parallel research to rex-the-researcher when the stack may have changed, and synthesizes results into a concrete scaffold plan.

**Initialization:** Reads `skills/scaffold-lab-plugin/SKILL.md` before any work.

**Delegation pattern:** Dispatches parallel rex-the-researcher workers when the request depends on current MCP, Claude Code, Codex, or SDK behavior. Works locally without delegation when the request is straightforward.

**Edge cases:**
- Service URL or OpenAPI spec but no docs: fetch and inspect the spec before scaffolding
- Ambiguous language: ask once, then proceed
- Conflicting research sources: use the more recent primary source, note the conflict
- User asks for immediate generation: produce a condensed plan at the top first

### roddy-reviewer

**File:** `agents/roddy-reviewer.md`
**Tools:** Bash, Read, Write, Edit, Glob, Grep, Task, SendMessage, Skill

Spec review agent. Inspects all canonical surfaces of a target plugin, flags every meaningful misalignment with precise file references, separates undocumented drift from justified documented deviations.

**Initialization:** Reads `skills/review-lab-plugin/SKILL.md` before any review work.

**Review standard:** Operates in code-review mode -- findings first, precise file references, no vague style commentary. Focus on behavioral, structural, and contract drift.

**Output:** Writes review artifact to `docs/reports/plugin-reviews/<YYYYMMDD-HHMMSS>.md`. Findings classified as CRITICAL, HIGH, MEDIUM, or LOW severity.

**Edge cases:**
- Plugin path does not exist: stop and ask for correct path
- Required canonical file missing: flag as CRITICAL
- Two review passes disagree: include both perspectives, flag for human review

### ally-the-aligner

**File:** `agents/ally-the-aligner.md`
**Tools:** Bash, Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, SendMessage, Skill

Alignment and remediation agent. Consumes a review report or dispatches roddy-reviewer if none exists. Plans changes across ten surfaces in priority order (manifests first, docs last). Preserves justified deviations.

**Initialization:** Reads `skills/align-lab-plugin/SKILL.md` before making changes.

**Editing order:**
1. Manifests and runtime contract
2. Docker/runtime files
3. Tests and CI
4. Docs, skills, commands, agents

**Edge cases:**
- No review report: dispatch roddy-reviewer first
- Fix would break a documented deviation: flag for human review
- Large scope: break into phases, complete each before starting the next

**Output:** Writes alignment summary to `docs/reports/plugin-alignments/<YYYYMMDD-HHMMSS>.md`.

### tilly-the-toolsmith

**File:** `agents/tilly-the-toolsmith.md`
**Tools:** Bash, Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, SendMessage, Skill

MCP tool design agent. Designs action+subaction contracts (one tool per resource domain, subactions are verbs). Produces handler stubs, the dispatch table, and the required `*_help` companion tool. Can refactor flat tool lists into the canonical dispatch shape.

**Initialization:** Reads `skills/tool-lab-plugin/SKILL.md` before any work.

**Design principle:** One tool per resource domain. Subactions are verbs. Parameters validated after dispatch, not before.

**Edge cases:**
- More operations than fit in one tool: propose splitting by resource domain (max 4-5 actions per tool)
- Existing action/subaction must be renamed: flag as breaking change, propose versioned transition
- User asks to skip `*_help` tool: decline -- MCP clients depend on it for capability discovery

### dex-the-deployer

**File:** `agents/dex-the-deployer.md`
**Tools:** Bash, Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, SendMessage, Skill

Containerization and deployment agent. Produces multi-stage Dockerfiles, entrypoints with env var validation, Compose files with healthchecks, and `.dockerignore`. Handles rollback via image tag pinning.

**Initialization:** Reads `skills/deploy-lab-plugin/SKILL.md` before any work.

**Principle:** No secret enters the image. No config is hardcoded. Entrypoint fails fast on missing env vars. Health endpoint answers before server accepts other traffic.

**Edge cases:**
- `/health` endpoint missing: stub it before delivering container config
- Env vars in entrypoint don't match `.env.example`: synchronize before closing
- Rollback request: pin prior image tag in `docker-compose.yaml`, never use `--scale 0`

### petra-the-pipeliner

**File:** `agents/petra-the-pipeliner.md`
**Tools:** Bash, Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, SendMessage, Skill

CI/CD pipeline agent. Owns all four workflow files (`ci.yaml`, `publish-image.yaml`, `release-on-main.yaml`, pre-commit config) plus Justfile targets.

**Initialization:** Reads `skills/pipeline-lab-plugin/SKILL.md` before any work.

**Principle:** CI is a mirror of local `just` commands. If `just test` passes locally, CI test should pass. Live integration tests have skip guards and never fail a PR because the target service is unreachable.

**Edge cases:**
- Structurally broken workflow: rewrite from canonical template
- Custom stages: preserve but document as deviations
- Release workflow fails because tag exists: explain the fix is to bump the version, not delete the tag

### rex-the-researcher

**File:** `agents/rex-the-researcher.md`
**Tools:** Bash, Read, Write, Glob, Grep, WebSearch, WebFetch, SendMessage, Skill

Current-state research specialist. Answers questions from primary sources (official docs, protocol specs, SDK repositories, release notes). Distinguishes confirmed facts from inferences. Flags conflicts between sources.

**Initialization:** Reads `skills/lab-research-specialist/SKILL.md` before researching.

**Source standard:** Official docs > protocol specs > SDK repos > release notes. Avoids weak secondary summaries. Consults `references/approved-sources.md` for the curated source list.

**Edge cases:**
- Primary source behind login/rate-limited: use web search for reliable summary, flag the limitation
- Two primary sources conflict: use more recent one, document the conflict
- Question unanswerable from public sources: say so clearly, do not fabricate
- Dispatched with narrow question: answer specifically, do not broaden scope

**Output:** Writes research artifacts to `docs/research/<topic>-<YYYYMMDD-HHMMSS>.md`.

## Frontmatter Schema

All agents use this YAML frontmatter:

```yaml
---
name: agent-name
description: |
  Trigger description with examples.
model: inherit
color: blue
tools: ["Bash", "Read", "Write", ...]
memory: user
---
```

| Field | Required | Description |
| --- | --- | --- |
| `name` | yes | Agent identifier |
| `description` | yes | When to invoke, with `<example>` blocks |
| `model` | yes | Model to use (`inherit` uses the session model) |
| `color` | yes | Terminal color for agent output |
| `tools` | yes | List of tools the agent may use |
| `memory` | no | Memory scope (`user` for persistent memory) |

## Delegation Patterns

Agents delegate to each other in predictable patterns:

- **ally-the-aligner** dispatches roddy-reviewer, rex-the-researcher, and ster-the-scaffolder in parallel when no review report exists
- **ster-the-scaffolder** dispatches up to three rex-the-researcher workers for current-state research
- **tilly-the-toolsmith** dispatches rex-the-researcher when the wrapped service API may have changed
- **dex-the-deployer** dispatches rex-the-researcher to confirm base image tags for non-standard runtimes
- **petra-the-pipeliner** dispatches rex-the-researcher to confirm current GitHub Action versions

rex-the-researcher is the common research delegate -- it never delegates to other agents.
