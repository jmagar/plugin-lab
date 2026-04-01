#!/bin/bash
# =============================================================================
# Setup Credentials for Claude Homelab
# =============================================================================
# Creates ~/.claude-homelab/.env from .env.example (if not already present).
# Safe to run multiple times — never overwrites an existing .env.
#
# Usage:
#   ./scripts/setup-creds.sh          # from repo checkout
#   curl -sSL .../setup-creds.sh | bash  # standalone (plugin path)
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }

HOMELAB_DIR="$HOME/.claude-homelab"
ENV_FILE="$HOMELAB_DIR/.env"

# Locate .env.example — works from repo checkout or curl | bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-./setup-creds.sh}")" 2>/dev/null && pwd || echo "")"
REPO_ROOT="${SCRIPT_DIR:+$(cd "$SCRIPT_DIR/.." && pwd)}"
EXAMPLE_FILE="${REPO_ROOT:+$REPO_ROOT/.env.example}"

echo ""
echo -e "${BLUE}=== Claude Homelab — Credential Setup ===${NC}"
echo ""

# Create ~/.claude-homelab/ if needed
mkdir -p "$HOMELAB_DIR"
log_info "Credentials directory: $HOMELAB_DIR"

# Install load-env.sh if repo is available
if [[ -n "$REPO_ROOT" && -f "$REPO_ROOT/scripts/load-env.sh" ]]; then
    cp "$REPO_ROOT/scripts/load-env.sh" "$HOMELAB_DIR/load-env.sh"
    log_success "Installed load-env.sh"
fi

# Create .env from template
if [[ -f "$ENV_FILE" ]]; then
    log_warn ".env already exists — not overwriting"
    log_info "To reconfigure a service, run: /homelab-core:setup inside Claude Code"
else
    if [[ -n "$EXAMPLE_FILE" && -f "$EXAMPLE_FILE" ]]; then
        cp "$EXAMPLE_FILE" "$ENV_FILE"
        log_success "Created $ENV_FILE from .env.example"
    else
        # Fallback: fetch from GitHub if running via curl | bash
        local_example="$(mktemp)"
        if curl -sSL "https://raw.githubusercontent.com/jmagar/claude-homelab/main/.env.example" \
            -o "$local_example" 2>/dev/null; then
            cp "$local_example" "$ENV_FILE"
            rm -f "$local_example"
            log_success "Created $ENV_FILE (fetched from GitHub)"
        else
            touch "$ENV_FILE"
            log_warn "Created empty $ENV_FILE (.env.example not available)"
        fi
    fi
    chmod 600 "$ENV_FILE"
    log_success "Permissions set (chmod 600)"
fi

echo ""
echo -e "${GREEN}Services requiring credentials:${NC}"
echo "  Media:          Plex, Radarr, Sonarr, Overseerr, Prowlarr, Tautulli"
echo "  Downloads:      qBittorrent, SABnzbd"
echo "  Infrastructure: Unraid (×2), UniFi, Tailscale, ZFS"
echo "  Utilities:      Gotify, Linkding, Memos, ByteStash, Paperless-ngx, Radicale"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Open Claude Code and run: /homelab-core:setup"
echo "     (interactive wizard — asks which services you use, prompts for each credential)"
echo ""
echo "  Or edit manually:  \$EDITOR $ENV_FILE"
echo ""
