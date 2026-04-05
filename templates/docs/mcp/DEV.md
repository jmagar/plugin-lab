# Development Workflow

Day-to-day development guide for my-plugin MCP server.

<!-- scaffold:specialize -- update commands, paths, and language-specific tooling -->

## Quick start

```bash
git clone https://github.com/jmagar/my-plugin.git
cd my-plugin
cp .env.example .env
chmod 600 .env
# Edit .env with your my-service credentials

just dev          # Start dev server with auto-reload
```

## Project structure

<!-- scaffold:specialize -- adjust paths for language (py/ts/rs) -->

```
my-plugin/
  src/ or my_plugin_mcp/    # Server source code
  tests/                     # Unit and integration tests
  scripts/                   # Smoke tests, contract checks, maintenance
  hooks/                     # Claude Code hooks (pre-commit, etc.)
  skills/my-plugin/          # Skill definition (SKILL.md)
  .claude-plugin/            # Claude Code plugin manifest
  .codex-plugin/             # Codex CLI plugin manifest
  gemini-extension.json      # Gemini CLI manifest
  docker-compose.yml         # Container deployment
  Dockerfile                 # Container build
  .env.example               # Environment variable template
  Justfile                   # Task runner recipes
```

## Development cycle

1. **Edit source code** -- modify tool handlers, add actions, fix bugs.
2. **Run dev server** -- `just dev` starts with auto-reload on file changes.
3. **Test interactively** -- call tools via MCP client or curl:
   ```bash
   # HTTP transport
   curl -X POST http://localhost:8000/mcp \
     -H "Authorization: Bearer $MY_PLUGIN_MCP_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"method":"tools/call","params":{"name":"my_plugin","arguments":{"action":"health"}}}'
   ```
4. **Run checks**:
   ```bash
   just lint && just typecheck && just test
   ```
5. **Commit** with conventional prefix:
   ```bash
   git commit -m "feat(tools): add list_items action"
   ```

## Adding a new tool action

<!-- scaffold:specialize -- replace with language-specific file paths -->

1. **Add to dispatch table** -- register the action string in the router (e.g., `match action:` block).
2. **Implement handler** -- write the function that calls the upstream API and returns formatted results.
3. **Update schema** -- add parameters, descriptions, and types to the tool's input schema.
4. **Add test** -- write a unit test covering success, error, and edge cases.
5. **Update SKILL.md** -- add the action to the skill's action table and examples.
6. **Update help tool** -- ensure `my_plugin_help` includes the new action.

### Adding a subaction

For actions that have sub-operations (e.g., `docker` action with `list`, `start`, `stop` subactions):

1. Add subaction case to the action's handler.
2. Implement subaction logic.
3. Update schema with subaction enum and per-subaction parameters.
4. Add tests for each subaction path.

## Adding a new resource

MCP resources expose read-only data via URI-based access.

1. **Register resource URI** -- add a resource handler with a URI pattern (e.g., `my-plugin://config`).
2. **Implement handler** -- return the resource content (text, JSON, or binary).
3. **Add test** -- verify the resource returns expected content.

See [RESOURCES](RESOURCES.md) for the resource catalog.

## Debugging

### Log levels

Set `LOG_LEVEL` in `.env`:

| Level | Use case |
|-------|----------|
| `DEBUG` | Full request/response bodies, dispatch tracing |
| `INFO` | Startup, tool calls, upstream requests (default) |
| `WARNING` | Degraded conditions, retries |
| `ERROR` | Failures, unhandled exceptions |

### curl testing

```bash
# Health (unauthenticated)
curl http://localhost:8000/health

# Tool call
curl -X POST http://localhost:8000/mcp \
  -H "Authorization: Bearer $MY_PLUGIN_MCP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"method":"tools/call","params":{"name":"my_plugin","arguments":{"action":"list_items"}}}'

# List tools
curl -X POST http://localhost:8000/mcp \
  -H "Authorization: Bearer $MY_PLUGIN_MCP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"method":"tools/list"}'
```

### MCP Inspector

Use the MCP Inspector for interactive debugging:

```bash
npx @modelcontextprotocol/inspector
```

Connect to `http://localhost:8000/mcp` with your bearer token.

## Code style

<!-- scaffold:specialize -- keep only the relevant language section -->

| Language | Linter | Formatter | Type checker |
|----------|--------|-----------|-------------|
| Python | ruff | ruff format | pyright / mypy |
| TypeScript | biome | biome format | tsc --noEmit |
| Rust | clippy | rustfmt | cargo check |

Run all checks:

```bash
just lint        # Lint
just format      # Auto-format
just typecheck   # Type check
just test        # Run test suite
```

## Justfile recipes

Common recipes available in all MCP repos:

| Recipe | Description |
|--------|-------------|
| `just dev` | Start dev server with auto-reload |
| `just up` | Build and start via Docker Compose |
| `just down` | Stop containers |
| `just logs` | Tail container logs |
| `just health` | Curl the /health endpoint |
| `just lint` | Run linter |
| `just format` | Run formatter |
| `just typecheck` | Run type checker |
| `just test` | Run test suite |
| `just smoke` | Run smoke tests against running server |

See also: [CONNECT](CONNECT.md) | [PATTERNS](PATTERNS.md) | [TESTS](TESTS.md)
