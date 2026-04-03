# Plugin Lab (plugin-templates)

> **Canonical specification and automated scaffolding for homelab MCP server plugins.**

[![Version](https://img.shields.io/badge/version-1.3.0-blue.svg)](CHANGELOG.md)
[![Agents](https://img.shields.io/badge/agents-8_specialists-orange.svg)](#agents)
[![FastMCP](https://img.shields.io/badge/FastMCP-Supported-brightgreen.svg)](https://github.com/jlowin/fastmcp)
[![License](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)

---

## ✨ Overview
Plugin Lab is the factory floor for the Claude Homelab ecosystem. It provides a suite of specialized agents and slash commands to scaffold, review, align, and deploy MCP servers across Python, TypeScript, and Rust, ensuring all plugins follow the canonical 15-surface specification.

### 🎯 Key Features
| Feature | Description |
|---------|-------------|
| **Auto-Scaffolding** | Generate complete plugin repos from canonical SDK templates |
| **Spec Auditing** | Automated review agents that verify compliance with ecosystem standards |
| **Multi-Language** | Native support for Python (uv), TypeScript (Node), and Rust (Cargo) |
| **CI/CD Ready** | Integrated GitHub Actions for linting, building, and releasing |

---

## 🎯 Claude Code Integration
Install the plugin development suite directly from the marketplace:

```bash
# Add the marketplace
/plugin marketplace add jmagar/claude-homelab

# Install the lab suite
/plugin install plugin-lab @jmagar-claude-homelab
```

---

## ⚙️ Configuration & Credentials
Plugin Lab helps manage the central homelab credential store.

**Location:** `~/.claude-homelab/.env`

### Quick Commands
```bash
# Initialize local credentials
/setup-homelab

# Run structural linting on a plugin
./scripts/lint-plugin.sh /path/to/plugin
```

---

## 🛠️ Available Tools & Resources

### 🔧 Specialist Agents & Commands
| Agent | Command | Purpose |
|-------|---------|---------|
| **Ster-The-Scaffolder** | `/create-lab-plugin` | Scaffold new plugins from templates |
| **Roddy-Reviewer** | `/review-lab-plugin` | Audit plugins against canonical spec |
| **Ally-The-Aligner** | `/align-lab-plugin` | Implement review findings automatically |
| **Tilly-The-Toolsmith**| `/tool-lab-plugin` | Design and implement MCP tool handlers |

### 🔧 Infrastructure Commands
- `/deploy-lab-plugin`: Generate Docker and Compose configurations.
- `/pipeline-lab-plugin`: Implement 4-workflow CI/CD pipelines.
- `/research-lab-plugin`: Research current SDK best practices.

---

## 🏗️ Architecture & Design
Built on a **Two-Layer Template Architecture**:
- **Shared Layer:** Manifests, hooks, and scripts common to all homelab plugins.
- **Language Layer:** Language-specific runtime and toolchain assets (Py, TS, RS).
- **Surface Pattern:** Every plugin must implement 15 specific "surfaces" (Manifests, Docker, CI, etc.) to be considered compliant.

---

## 🔧 Development
### Prerequisites
- Python 3.11+, Node 20+, or Rust 1.75+
- [uv](https://github.com/astral-sh/uv) package manager

### Scaffolding a New Plugin
```bash
# Example: Create a new Python-based MCP server
./scripts/scaffold-plugin.sh --name "my-new-mcp" --lang "py"
```

### Quality Assurance
- `lint-plugin.sh`: Validates manifest sync, env vars, and tool patterns.
- `check-docker-security.sh`: Verifies multi-stage builds and non-root users.

---

## 🐛 Troubleshooting
| Issue | Cause | Solution |
|-------|-------|----------|
| **Lint Failure** | Version Mismatch | Sync versions in all manifest files |
| **Docker Build Fail** | Baked Secrets | Remove `.env` from Docker build context |
| **Agent Stuck** | Context Limit | Use specific `--notebook` or target path |

---

## 📄 License
MIT © jmagar
