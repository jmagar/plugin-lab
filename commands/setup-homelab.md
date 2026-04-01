---
description: Initialize homelab environment and configure .env file
argument-hint: [--force]
allowed-tools: Bash, Skill
---

# Setup Homelab

Invoke the `setup` skill to initialize the homelab environment.

## Workflow

1. Invoke the `setup` skill.
2. The skill will:
   - Copy `.env.example` to `~/.claude-homelab/.env` (skip if exists, unless `--force` passed)
   - Set `chmod 600` on the env file
   - Install `load-env.sh` into `~/.claude-homelab/`
3. After setup completes, tell the user:
   - Edit `~/.claude-homelab/.env` to fill in service credentials
   - Run `/review-lab-plugin` on any service plugin to verify configuration
