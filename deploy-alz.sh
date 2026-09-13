#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[INFO] deploy-alz.sh has moved to scripts/deploy-alz-legacy.sh"
exec "$SCRIPT_DIR/scripts/deploy-alz-legacy.sh" "$@"
