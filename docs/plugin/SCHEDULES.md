# Schedules -- plugin-lab

plugin-lab does not use Claude Code schedules.

## What schedules are

Schedules define cron-based recurring agent execution. They allow plugins to run automated tasks at specified intervals without user intervention.

## Why plugin-lab does not use schedules

plugin-lab agents are invoked on demand via slash commands. There is no recurring automation need -- scaffolding, reviewing, and aligning are interactive workflows initiated by the developer.

Plugins scaffolded by plugin-lab may add schedules if they need periodic health checks, data syncs, or other recurring operations. See the template documentation at `templates/docs/plugin/SCHEDULES.md` for the schedule definition pattern.
