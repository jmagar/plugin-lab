# Scheduled Tasks — my-plugin

Automated recurring agent execution on a cron schedule.

## Purpose

Schedules allow plugins to run agents on a recurring basis without manual invocation. Common use cases: health checks, log monitoring, backup verification, and periodic data syncing.

## Configuration

Schedules are configured as remote triggers that execute Claude Code agents on a cron schedule.

### Schedule definition

```json
{
  "name": "my-plugin-health-check",
  "schedule": "*/5 * * * *",
  "agent": "my-specialist",
  "prompt": "Run a health check on my-service and report any issues",
  "enabled": true
}
```

| Field | Required | Description |
| --- | --- | --- |
| `name` | yes | Unique schedule identifier |
| `schedule` | yes | Cron expression (minute hour day month weekday) |
| `agent` | no | Agent to invoke (omit for default) |
| `prompt` | yes | Instruction passed to the agent |
| `enabled` | no | Toggle without deleting (default: `true`) |

### Common cron patterns

| Pattern | Frequency |
| --- | --- |
| `*/5 * * * *` | Every 5 minutes |
| `0 * * * *` | Every hour |
| `0 */6 * * *` | Every 6 hours |
| `0 0 * * *` | Daily at midnight |
| `0 0 * * 1` | Weekly on Monday |

## Setup

Create and manage schedules via the `/schedule` skill:

```
/schedule create "health-check" --cron "*/5 * * * *" --prompt "Check my-service health"
/schedule list
/schedule enable health-check
/schedule disable health-check
/schedule delete health-check
```

## Security

- Scheduled agents run with the same permissions as manual invocations
- Remote execution requires authentication (API key or token)
- Schedules cannot escalate beyond the plugin's allowed tools
- Audit logs track all scheduled executions

## Use cases for my-plugin

<!-- scaffold:specialize — add plugin-specific scheduled tasks -->

| Schedule | Cron | Purpose |
| --- | --- | --- |
| Health check | `*/5 * * * *` | Verify my-service is responsive |
| Log digest | `0 */6 * * *` | Summarize errors from last 6 hours |
| Backup verify | `0 2 * * *` | Confirm last backup completed |
| Version check | `0 0 * * 1` | Check for upstream updates |

## Example: scheduled health check

```json
{
  "name": "my-plugin-health",
  "schedule": "*/5 * * * *",
  "prompt": "Check my-service health. If DOWN, post alert to Discord channel. If DEGRADED, log a warning.",
  "enabled": true
}
```

## Cross-references

- [AGENTS.md](AGENTS.md) — Agents invoked by schedules
- [CHANNELS.md](CHANNELS.md) — Channels used for schedule alerts
- [HOOKS.md](HOOKS.md) — Hooks that may complement scheduled checks
