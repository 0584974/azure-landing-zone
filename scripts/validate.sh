#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENT="${1:-prod}"
ENV_DIR="$ROOT_DIR/environments/$ENVIRONMENT"
BICEP_ROOT="$ROOT_DIR/platforms/infra-as-code/bicep"

if [[ ! -d "$ENV_DIR" ]]; then
  echo "[ERROR] Environment directory not found: $ENV_DIR" >&2
  exit 1
fi

command -v az >/dev/null 2>&1 || { echo "[ERROR] Azure CLI is required." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "[ERROR] jq is required." >&2; exit 1; }

required_files=(global.json subscriptions.json policy.json logging.json networking.json)
for file in "${required_files[@]}"; do
  [[ -f "$ENV_DIR/$file" ]] || { echo "[ERROR] Missing $ENV_DIR/$file" >&2; exit 1; }
done

echo "[INFO] Validating JSON configuration for environment: $ENVIRONMENT"
for file in "$ENV_DIR"/*.json; do
  jq empty "$file"
done

echo "[INFO] Building Bicep files"
while IFS= read -r -d '' file; do
  echo "  - $file"
  az bicep build --file "$file" >/dev/null
done < <(find "$BICEP_ROOT" -name '*.bicep' -print0)

echo "[INFO] Validation completed successfully"
