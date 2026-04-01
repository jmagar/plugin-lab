# Approved Sources for Lab Plugin Research

This file lists authoritative primary sources for homelab plugin research. Consult these before any other source. Do not substitute blog posts, tutorials, or community forum posts for items listed here.

For each source: use the URL description to locate the resource — URLs are not hardcoded because they change. When a source moves, update this file.

---

## MCP Protocol

### Specification Repository
- **What it is:** The canonical MCP protocol specification, maintained by Anthropic. The source of truth for transport expectations, message shapes, tool/resource/prompt schemas, and lifecycle rules.
- **Where to find it:** GitHub, organization `modelcontextprotocol`, repository named `modelcontextprotocol` or `specification`. The `docs/` or `spec/` directory contains the versioned spec documents.
- **Authoritative for:** transport negotiation, message framing, capability negotiation, tool call and response schemas, resource URI conventions, prompt schemas, error codes.
- **Change frequency:** Moderate. Major transport changes (e.g., the introduction of Streamable HTTP) ship with spec PRs and are announced in the repo's releases or CHANGELOG. Check before scaffolding any transport layer.

### Transport Documentation
- **What it is:** Spec pages covering stdio, HTTP+SSE, and Streamable HTTP transports.
- **Where to find it:** Within the specification repository above, typically under a `transports/` or `docs/transports/` path. Also mirrored on the official MCP documentation site (modelcontextprotocol.io or docs.anthropic.com — check both, prefer the spec repo when they conflict).
- **Authoritative for:** which transports are current vs. deprecated, required headers, session lifecycle, message batching, backpressure handling.
- **Change frequency:** High relative to other spec areas. The move from HTTP+SSE to Streamable HTTP was a breaking transport change. Verify the current recommended transport before every new scaffold.

### Tool and Resource Schema
- **What it is:** JSON Schema definitions for tool input/output, resource contents, and prompt arguments as defined by the protocol.
- **Where to find it:** In the specification repository, typically under `schema/` as JSON Schema files, or embedded in the spec documents.
- **Authoritative for:** required and optional fields in tool definitions, resource MIME types, prompt argument types, error response shape.
- **Change frequency:** Low to moderate. Field additions are backward compatible; field removals or renames are breaking and accompany a major spec version bump.

---

## Claude Code Plugin System

### plugin.json Schema
- **What it is:** The manifest schema for `.claude-plugin/plugin.json`. Defines required and optional fields for plugin discovery, marketplace listing, skill registration, command registration, hook configuration, and userConfig.
- **Where to find it:** Anthropic's Claude Code documentation (docs.anthropic.com), under the plugins or extensions section. Also present in the `plugin-templates` repo's own `.claude-plugin/plugin.json` as an example — but treat the official schema doc as authoritative, not the local example.
- **Authoritative for:** required manifest fields, userConfig shape, sensitive vs. non-sensitive field distinction, skill/command/agent registration, hook event names.
- **Change frequency:** Moderate. New fields are added as Claude Code ships new plugin capabilities. The `minVersion` field and `channels` field were added in distinct spec updates. Check the official changelog or release notes before alignment work.

### Marketplace Format
- **What it is:** The schema and conventions for `marketplace.json` entries that list a plugin in the Claude Code plugin marketplace.
- **Where to find it:** Claude Code documentation, under marketplace or plugin distribution. The `plugin-templates` repo's `.claude-plugin/marketplace.json` is an example but may lag the official schema.
- **Authoritative for:** how external plugins are referenced (`github:owner/repo` format), version fields, category tags, icon references.
- **Change frequency:** Low. Changes here are rare but consequential for discoverability.

### Skill Format and SKILL.md Conventions
- **What it is:** The frontmatter schema and body conventions for `SKILL.md` files that register Claude Code skills.
- **Where to find it:** Claude Code documentation, skill authoring guide. Also in the `skills-ref` npm package (see TypeScript SDK section for locating npm packages).
- **Authoritative for:** required frontmatter fields (`name`, `description`), optional fields that the validator supports, body structure conventions.
- **Change frequency:** Low. Additions are backward compatible.

---

## Codex Plugin System

### plugin.json (Codex)
- **What it is:** The manifest schema for `.codex-plugin/plugin.json`. Parallel to the Claude manifest but with Codex-specific fields.
- **Where to find it:** OpenAI Codex or OpenAI developer documentation, under plugin or agent integration. The `plugin-templates` repo's `.codex-plugin/plugin.json` is an example.
- **Authoritative for:** Codex-specific manifest fields, tool registration for Codex agents.
- **Change frequency:** Moderate. Check before alignment or scaffold work targeting Codex.

### app.json
- **What it is:** The application manifest (`.app.json`) used for plugin app identity and OAuth/auth integration.
- **Where to find it:** Same Codex developer documentation as above.
- **Authoritative for:** app identity fields, auth configuration, redirect URIs.
- **Change frequency:** Low.

### Skill Format (Codex)
- **What it is:** The `SKILL.md` conventions for Codex agent skill registration, which differ from Claude Code conventions.
- **Where to find it:** Codex agent documentation. Compare with Claude Code skill conventions — they share structure but differ in supported frontmatter fields.
- **Change frequency:** Low.

---

## Python MCP SDK

### Repository
- **What it is:** The official Python MCP SDK, maintained in the `modelcontextprotocol` GitHub organization. Repository is typically named `python-sdk`.
- **Where to find it:** GitHub, organization `modelcontextprotocol`, repository `python-sdk`. The `README.md`, `CHANGELOG.md`, and `src/` tree are all primary sources.
- **Authoritative for:** server construction patterns, lifespan handler signature, tool registration decorators, transport invocation, FastMCP integration, async patterns.
- **Change frequency:** High. This SDK has shipped breaking changes between minor versions. Always check the CHANGELOG before scaffolding a new Python plugin or aligning an existing one.

### PyPI
- **What it is:** The `mcp` package on PyPI. Use to verify the current stable version, release history, and dependency constraints.
- **Where to find it:** pypi.org, package name `mcp`. Check the release history tab for recent versions and the project links for the canonical repo.
- **Authoritative for:** current stable version number, release dates, dependency pinning decisions.
- **Change frequency:** Follows the SDK repo release cadence.

### Key Patterns to Verify
- Server entrypoint (`FastMCP`, `mcp.server.stdio.stdio_server`, or `mcp.run`)
- Lifespan handler signature (`@asynccontextmanager`, `lifespan=` parameter)
- Tool registration (`@mcp.tool()` decorator vs. explicit registration)
- Transport invocation (`mcp.run(transport="stdio")` vs. context manager pattern)

---

## Rust MCP SDK (RMCP)

### Repository
- **What it is:** The official Rust MCP SDK. May be in the `modelcontextprotocol` GitHub organization or a community-maintained crate — verify current ownership.
- **Where to find it:** GitHub, search `modelcontextprotocol` organization for a Rust SDK repository. Also check crates.io for the `rmcp` crate and its listed repository link.
- **Authoritative for:** server trait definitions, tool attribute macros, transport setup, async runtime requirements (tokio), feature flags.
- **Change frequency:** Moderate to high. The Rust SDK matured later than Python/TypeScript and may have had more API churn. Check before scaffolding.

### crates.io
- **What it is:** The `rmcp` crate registry entry. Use to verify stable version, recent releases, and feature flags.
- **Where to find it:** crates.io, crate name `rmcp`. Check the versions tab and the repository link.
- **Authoritative for:** current stable version, feature flag names (e.g., `server`, `transport-sse`, `transport-io`), yanked versions.
- **Change frequency:** Follows the SDK repo release cadence.

---

## TypeScript MCP SDK

### Repository
- **What it is:** The official TypeScript/Node.js MCP SDK, maintained in the `modelcontextprotocol` GitHub organization. Repository is typically named `typescript-sdk`.
- **Where to find it:** GitHub, organization `modelcontextprotocol`, repository `typescript-sdk`.
- **Authoritative for:** `McpServer` construction, tool registration, transport classes (`StdioServerTransport`, `StreamableHTTPServerTransport`), SSE vs. Streamable HTTP patterns.
- **Change frequency:** High. Transport classes have been added and renamed across versions.

### npm
- **What it is:** The `@modelcontextprotocol/sdk` package on npm. Use to verify the current stable version and release history.
- **Where to find it:** npmjs.com, package `@modelcontextprotocol/sdk`.
- **Authoritative for:** current stable version, peer dependency requirements, ESM vs. CJS module format.
- **Change frequency:** Follows the SDK repo release cadence.

### Key Patterns to Verify
- Server class (`Server` vs. `McpServer`)
- Transport class names for stdio and HTTP
- Whether Streamable HTTP transport is available and stable
- ESM import paths and whether `.js` extensions are required

---

## FastMCP

### FastMCP (Python)
- **What it is:** A higher-level Python framework for building MCP servers, wrapping the official Python SDK with ergonomic decorators and automatic schema generation.
- **Where to find it:** GitHub, search for `fastmcp` — check both the `jlowin` org and the `modelcontextprotocol` org, as the project's canonical home has changed. Also check PyPI for the `fastmcp` package and its repository link.
- **Authoritative for:** `FastMCP` class API, `@mcp.tool` decorator behavior, context injection, image/resource handling, mounting sub-servers.
- **Change frequency:** High. FastMCP evolves rapidly and its integration with the official SDK has changed with SDK major versions. Always verify compatibility between `fastmcp` and `mcp` package versions.

### FastMCP (TypeScript)
- **What it is:** A TypeScript equivalent providing similar ergonomic wrappers. A separate project from the Python FastMCP.
- **Where to find it:** GitHub, search `fastmcp typescript`. Check npm for the `fastmcp` package and its repository link.
- **Authoritative for:** TypeScript server construction shorthand, tool registration, resource handlers.
- **Change frequency:** Moderate. Check before use — the TypeScript variant tracks the TypeScript SDK but with its own release cadence.

---

## Docker

### Multi-Stage Build Documentation
- **What it is:** Official Docker documentation for multi-stage builds.
- **Where to find it:** docs.docker.com, under the "Build" section, "Multi-stage builds" page.
- **Authoritative for:** `FROM ... AS ...` syntax, `COPY --from=<stage>`, stage naming conventions, minimizing final image size.
- **Change frequency:** Low. Syntax is stable; check only when Dockerfile linting raises unfamiliar errors.

### Compose Healthcheck
- **What it is:** Official Docker Compose documentation for the `healthcheck:` key in `docker-compose.yaml`.
- **Where to find it:** docs.docker.com, under "Compose file reference", `healthcheck` key.
- **Authoritative for:** `test`, `interval`, `timeout`, `retries`, `start_period` fields, `HEALTHCHECK` instruction in Dockerfile vs. Compose override.
- **Change frequency:** Low. Check when adding a new healthcheck or when a Compose version bump changes key behavior.

---

## GitHub Actions

### Actions Marketplace
- **What it is:** The official registry of reusable GitHub Actions.
- **Where to find it:** github.com/marketplace?type=actions. Each action's repository is the primary source for its current major version and input/output schema.
- **Authoritative for:** current major version tags for `actions/checkout`, `actions/setup-node`, `astral-sh/setup-uv`, `dtolnay/rust-toolchain`, and other actions used in canonical CI files.
- **Change frequency:** Individual actions update independently. Pin to major version tags (e.g., `@v4`) and check changelogs when a new major version is released.

### Current Runner Versions
- **What it is:** Documentation on what software is pre-installed on GitHub-hosted runners.
- **Where to find it:** GitHub Actions documentation, "About GitHub-hosted runners", and the `actions/runner-images` repository on GitHub (contains per-image software manifests).
- **Authoritative for:** default Python version on `ubuntu-latest`, Node.js availability, OS version of `ubuntu-latest`, pre-installed tools.
- **Change frequency:** High relative to CI stability. `ubuntu-latest` periodically bumps to a new Ubuntu LTS, which can change default tool versions. Always pin language versions explicitly rather than relying on runner defaults.
