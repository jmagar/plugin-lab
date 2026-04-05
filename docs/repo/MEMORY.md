# Memory System -- plugin-lab

How Claude Code maintains persistent knowledge across sessions when working with plugin-lab.

## How Memory Works

Claude Code uses memory files to persist knowledge between sessions. When a session ends, important context (decisions, patterns, bugs found, conventions learned) can be saved to memory files that are automatically loaded in future sessions.

## Memory Scope

Memory in plugin-lab is set to `user` scope on all agents. This means:

- Memory is per-user, not per-repo
- Knowledge learned in one plugin-lab session carries over to the next
- Decisions about template conventions, SDK patterns, and plugin shapes persist

## Where Memory Matters

### Research Artifacts

Rex-the-researcher writes findings to `docs/research/<topic>-<YYYYMMDD-HHMMSS>.md`. These are durable artifacts that any agent can consume in future sessions without repeating the research.

### Review Reports

Roddy-reviewer writes reports to `docs/reports/plugin-reviews/<YYYYMMDD-HHMMSS>.md`. Ally-the-aligner reads these when starting alignment work, avoiding redundant audits.

### Alignment Summaries

Ally-the-aligner writes summaries to `docs/reports/plugin-alignments/<YYYYMMDD-HHMMSS>.md`. These document what was changed, what was preserved, and what needs follow-up.

### Session Notes

The `docs/sessions/` directory stores session notes and working context from extended development sessions.

### Planning Artifacts

The `docs/plans/` directory stores planning documents for multi-session work.

## Artifact Timestamp Format

All durable artifacts use `YYYYMMDD-HHMMSS` in their filenames for chronological ordering and deduplication.

## Gitignored Artifacts

The following docs subdirectories are gitignored to keep transient session state out of version control:

```
docs/plans/
docs/sessions/
docs/reports/
docs/research/
docs/superpowers/
```

These directories contain working artifacts that are useful within and across sessions but are not part of the published repo.
