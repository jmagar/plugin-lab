---
description: Create or update Docker container config for a lab plugin
argument-hint: <plugin-path> [create|review|update]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion, Task, Skill
---

# Deploy Lab Plugin

Invoke the `deploy-lab-plugin` skill, then spawn `dex-the-deployer` to containerize the plugin at `$ARGUMENTS`.

## Inputs

Parse `$ARGUMENTS` as: `<plugin-path> [mode]`

- `mode` defaults to `create` if not specified
- For `update`, read the existing `Dockerfile` and `docker-compose.yaml` before spawning

Ask for the plugin path if absent.

## Workflow

1. Invoke the `deploy-lab-plugin` skill.
2. Spawn `dex-the-deployer` with the plugin path and mode.
3. Direct Dex to:
   - inspect the plugin's language, `.env.example`, and existing container config
   - for `create`: gather port, env vars, and volume requirements, then produce the full container config
   - for `review`: audit `Dockerfile`, `docker-compose.yaml`, and `entrypoint.sh` for drift; produce a findings list
   - for `update`: make targeted changes; flag any env vars missing from entrypoint validation
   - confirm the `/health` endpoint exists in server code; stub it if absent
   - dispatch a `rex-the-researcher` worker to confirm base image tags if the runtime is non-standard

## Required Output

- `Dockerfile` (multi-stage)
- `entrypoint.sh` (with env var validation)
- `docker-compose.yaml` (with healthcheck and env_file)
- `.dockerignore`
- confirmation or stub of `/health` endpoint
- any assumptions about ports, volumes, or required env vars
