# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.4] - 2026-04-04

### Added
- **MCP core server docs**: 7 scaffold templates (CLAUDE, TOOLS, RESOURCES, SCHEMA, ENV, AUTH, TRANSPORT) in `templates/docs/mcp/` covering tool dispatch, resource URIs, schema generation, environment variables, authentication, and transport methods

## [1.0.3] - 2026-04-04

### Added
- **MCP operations docs**: 7 scaffold templates (DEPLOY, LOGS, TESTS, MCPORTER, CICD, PRE-COMMIT, PUBLISH) in `templates/docs/mcp/`

## [1.0.2] - 2026-04-04

### Added
- **docs templates**: Root-level documentation templates (README, SETUP, CONFIG, CHECKLIST, GUARDRAILS, INVENTORY) for plugin scaffolding
- **docs CLAUDE.md**: Updated with directory index, placeholder conventions, scaffold markers, and style guide
## [1.0.3] - 2026-04-04

### Added
- **Repo doc templates**: CLAUDE.md (index), REPO.md (directory structure), RECIPES.md (Justfile recipes), SCRIPTS.md (maintenance/hook/test scripts), RULES.md (git workflow, versioning, code standards), MEMORY.md (Claude Code memory system).
- **Stack doc templates**: CLAUDE.md (index), ARCH.md (MCP server architecture and data flow), TECH.md (language/framework/tooling choices), PRE-REQS.md (prerequisites per language).
- **Upstream doc template**: CLAUDE.md (upstream service integration patterns, client wrapper, error mapping).

## [1.0.2] - 2026-04-04

### Added
- **MCP advanced doc templates**: CONNECT.md (connection guide for all clients/transports/scopes), DEV.md (development workflow), ELICITATION.md (interactive credential entry and destructive operation confirmation), PATTERNS.md (reusable code patterns across languages), WEBMCP.md (browser-accessible MCP endpoints), MCPUI.md (protocol-level UI hints).

## [1.0.1] - 2026-04-03

### Fixed
- **OAuth discovery 401 cascade**: BearerAuthMiddleware was blocking GET /.well-known/oauth-protected-resource, causing MCP clients to surface generic "unknown error". Added WellKnownMiddleware (RFC 9728) to return resource metadata.

### Added
- **docs/AUTHENTICATION.md**: New setup guide covering token generation and client config.
- **README Authentication section**: Added quick-start examples and link to full guide.


## [1.0.0] - YYYY-MM-DD

### Added

- Initial release
- Action+subaction tool pattern with help tool
- Bearer token authentication
- Dual transport support (HTTP + stdio)
- Docker Compose deployment
- SWAG reverse proxy config
- Live integration tests
