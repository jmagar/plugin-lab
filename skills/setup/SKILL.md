---
name: setup
description: Interactive credential setup wizard for claude-homelab. Use when the user wants to configure credentials, set up a new service, update API keys, or run initial setup after installing the homelab-core plugin. Triggers on: 'setup credentials', 'configure plex', 'add my API key', 'I just installed homelab-core', 'setup homelab', or any mention of needing to configure a homelab service credential.
---

# Homelab Credential Setup Wizard

You are guiding the user through configuring their `~/.claude-homelab/.env` file. This is the single credential store for all homelab service plugins.

## Before You Start

Check the current state:
```bash
[ -f ~/.claude-homelab/.env ] && echo "EXISTS" || echo "MISSING"
[ -s ~/.claude-homelab/.env ] && echo "NON-EMPTY" || echo "EMPTY"
```

If the file is missing entirely, run `setup-creds.sh` first to create it from the template. Because `CLAUDE_PLUGIN_ROOT` is unreliable, locate the script relative to the skill's own directory:

```bash
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SKILL_DIR}/scripts/setup-creds.sh"
```

If running from a context where `BASH_SOURCE` is not set (e.g., directly from Claude Code), run the script by its known installed path:

```bash
bash ~/.claude-homelab/scripts/setup-creds.sh
```

## The Wizard Flow

### Step 1: Ask which services the user runs

Group the choices to make it manageable:

> "Which of these do you use? (say all that apply, or 'all', or list numbers)"
>
> **Infrastructure** *(no credentials required — can skip in Step 2)*
> 1. ZFS — local storage CLI (no credentials needed)
>
> **Infrastructure (credentials required)**
> 2. Unraid — NAS/hypervisor (can have 2 servers)
> 3. UniFi — network
> 4. Tailscale — VPN mesh
>
> **Media**
> 5. Plex — media server
> 6. Radarr — movies
> 7. Sonarr — TV shows
> 8. Overseerr — media requests
> 9. Prowlarr — indexers
> 10. Tautulli — Plex analytics
>
> **Downloads**
> 11. qBittorrent — torrents
> 12. SABnzbd — Usenet
>
> **Utilities**
> 13. Gotify — push notifications
> 14. Linkding — bookmarks
> 15. Memos — notes
> 16. ByteStash — code snippets
> 17. Paperless-ngx — documents
> 18. Radicale — calendar/contacts

Wait for the user's response before continuing.

### Step 2: For each selected service, collect credentials

Work through services **one at a time**. Skip ZFS — it requires no credentials.

For each credential-bearing service:

1. Tell the user what you need and where to find it (see `references/service-credentials-guide.md` for per-service detail)
2. Ask them to paste/type the value
3. Write it to `~/.claude-homelab/.env` immediately using a safe upsert pattern
4. Confirm it was saved before moving to the next service

**Never echo or log credential values.** Use this upsert pattern to write without revealing, which handles both existing and new keys:

```bash
if grep -q "^SERVICE_URL=" ~/.claude-homelab/.env; then
    sed -i "s|^SERVICE_URL=.*|SERVICE_URL=$value|" ~/.claude-homelab/.env
else
    echo "SERVICE_URL=$value" >> ~/.claude-homelab/.env
fi
chmod 600 ~/.claude-homelab/.env
```

This prevents two failure modes:
- **Silent no-op**: `sed -i` on a missing key matches nothing and silently does nothing
- **Duplicate keys**: plain `>>` appending when the key already exists creates duplicates that confuse parsers

Always use the upsert pattern for every key written.

For where to find credentials for each service, see `references/service-credentials-guide.md`.

### Step 3: Verify and offer health check

After collecting credentials, confirm:

> "All set! I've saved credentials for: [list services]. Want me to run a health check to verify everything is reachable?"

If yes, run the health check script directly:

```bash
bash ~/.claude-homelab/scripts/check-health.sh
```

Note: `/homelab-core:health` is a slash command and cannot be invoked from within a skill. Instruct the user to run it from a new Claude Code session, or use the script path above directly.

## Reconfiguration

If the user already has an `.env` and just wants to update one service:
- Ask which service
- Ask for the new values
- Update only those specific keys using the upsert pattern above
- Don't touch anything else

## Security Rules

- Never print, echo, or log any credential value
- Never show the contents of `.env`
- Always set `chmod 600 ~/.claude-homelab/.env` after any write
- If the user accidentally pastes a credential in chat, acknowledge it, don't repeat it, and remind them credentials should only go into the `.env` file

## Related Skills

- **homelab-core:health** — run after setup to verify all configured services are reachable. Use `bash ~/.claude-homelab/scripts/check-health.sh` or invoke `/homelab-core:health` from a new Claude Code session.
