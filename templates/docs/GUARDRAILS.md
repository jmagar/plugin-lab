# Security Guardrails — my-plugin

Safety and security patterns enforced across all plugins.

## Credential management

### Storage

- All credentials in `.env` with `chmod 600` permissions
- Never commit `.env` or any file containing secrets
- Use `.env.example` as a tracked template with placeholder values only
- Generate tokens with `openssl rand -hex 32`

### Ignore files

`.gitignore` and `.dockerignore` must include:

```
.env
*.secret
credentials.*
*.pem
*.key
```

### Hook enforcement

Pre-commit hooks verify security invariants:

| Hook | Purpose |
| --- | --- |
| `sync-env.sh` | Ensures `.env.example` documents all variables read by the server |
| `fix-env-perms.sh` | Sets `.env` to `chmod 600` if present |
| `ensure-ignore-files.sh` | Verifies `.gitignore` and `.dockerignore` contain required patterns |

### Credential rotation

1. Generate new token: `openssl rand -hex 32`
2. Update `.env` with new value
3. Restart the server: `just restart`
4. Update MCP client configuration with new token
5. Verify: `just health`

## Destructive operations

Actions that delete or modify data irreversibly are gated:

- Tool calls require `confirm=True` parameter
- Without confirmation, the server returns an error
- Server-wide bypass via `ALLOW_DESTRUCTIVE=true` (automated environments only)
- `ALLOW_YOLO=true` is an alias for the same behavior

Never enable destructive bypass in production without understanding the implications.

## Docker security

### Non-root execution

All containers run as non-root (UID/GID 1000 by default):

```dockerfile
RUN addgroup -g 1000 appgroup && adduser -u 1000 -G appgroup -D appuser
USER appuser
```

Override with `PUID` and `PGID` environment variables.

### No baked environment

Docker images must not contain credentials at build time:

- No `ENV MY_PLUGIN_API_KEY=...` in Dockerfile
- No `COPY .env` in Dockerfile
- Credentials injected at runtime via `--env-file` or `environment:` in compose

Verify with:

```bash
docker inspect my-plugin:latest | jq '.[0].Config.Env'
```

No sensitive values should appear in the output.

### Image scanning

Run vulnerability scans before publishing:

```bash
docker scout cves my-plugin:latest
```

## Network security

### HTTPS in production

- All `MY_PLUGIN_URL` values should use `https://` in production
- Use valid TLS certificates (Let's Encrypt via SWAG or similar)
- HTTP is acceptable only for local development

### Bearer token authentication

- HTTP transport requires `MY_PLUGIN_MCP_TOKEN` by default
- Token sent as `Authorization: Bearer <token>` header
- Disable only behind a trusted reverse proxy (`MY_PLUGIN_MCP_NO_AUTH=true`)

### Health endpoint

- `/health` is unauthenticated — required for container liveness probes
- Returns only status information, never credentials or internal state
- All other endpoints require bearer authentication

## Input handling

### API parameter sanitization

- Validate and sanitize all user-supplied parameters before forwarding to upstream APIs
- Use parameterized queries — never string-interpolate user input into URLs or commands
- Reject unexpected parameter types early

### Response truncation

- Truncate large responses at a reasonable limit (e.g., 512 KB)
- Append `... [truncated]` marker to indicate truncation
- Never stream unbounded upstream responses to the client

## Logging

- Never log credentials, tokens, or API keys — not even at DEBUG level
- Mask sensitive headers in request logs
- Log file permissions should be restrictive (`chmod 640`)
- Rotate logs to prevent disk exhaustion (5 MB max, 3 backups)
