---
description: Containerize and deploy a lab plugin via Docker and Docker Compose
argument-hint: <plugin-path> [create|review|update]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, Skill
---

# Deploy Lab Plugin

Use the `deploy-lab-plugin` skill and `dex-the-deployer` agent to containerize and deploy a lab plugin.

## Inputs

Start from `$ARGUMENTS`.

Parse as: `<plugin-path> [mode]`

- `mode` defaults to `create` if not specified
- For `update`, inspect the existing Dockerfile and docker-compose.yaml first

If the plugin path is missing, ask before proceeding.

## Workflow

1. Read [skills/deploy-lab-plugin/SKILL.md](/home/jmagar/workspace/plugin-templates/skills/deploy-lab-plugin/SKILL.md).
2. Spawn `dex-the-deployer`.
3. Tell Dex to:
   - inspect the plugin's language, `.env.example`, and existing container config
   - for `create`: gather port, env vars, and volume requirements, then produce the full container config
   - for `review`: audit Dockerfile, Compose, and entrypoint for drift and produce a findings list
   - for `update`: make targeted changes; flag any new env vars missing from entrypoint validation
   - confirm the `/health` endpoint exists in server code; stub it if absent
   - dispatch a `rex-the-researcher` worker to confirm base image tags if the runtime is non-standard

## Required Output

Dex should return:

- `Dockerfile` (multi-stage)
- `entrypoint.sh` (with env var validation)
- `docker-compose.yaml` (with healthcheck and env_file)
- `.dockerignore`
- confirmation or stub of `/health` endpoint
- any assumptions about ports, volumes, or required env vars
