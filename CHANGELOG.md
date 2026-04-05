# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.3] - 2026-04-04

### Added
- **MCP operations docs**: 7 scaffold templates (DEPLOY, LOGS, TESTS, MCPORTER, CICD, PRE-COMMIT, PUBLISH) in `templates/docs/mcp/`

## [1.0.2] - 2026-04-04

### Added
- **docs templates**: Root-level documentation templates (README, SETUP, CONFIG, CHECKLIST, GUARDRAILS, INVENTORY) for plugin scaffolding
- **docs CLAUDE.md**: Updated with directory index, placeholder conventions, scaffold markers, and style guide

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
