#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "[ERROR] Required command not found: $1" >&2; exit 1; }
}

log() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
err() { echo "[ERROR] $*" >&2; }

env_dir() {
  local environment="${1:-prod}"
  echo "$ROOT_DIR/environments/$environment"
}

compiled_dir() {
  local environment="${1:-prod}"
  echo "$ROOT_DIR/environments/$environment/compiled"
}

validate_env_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || { err "Environment directory not found: $dir"; exit 1; }
}
