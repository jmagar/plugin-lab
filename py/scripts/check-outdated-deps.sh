#!/usr/bin/env bash
set -euo pipefail
uv tree --outdated || true
