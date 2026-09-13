#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
ENVIRONMENT="${1:-prod}"
ENV_DIR="$(env_dir "$ENVIRONMENT")"
BICEP_ROOT="$ROOT_DIR/platforms/infra-as-code/bicep"
validate_env_dir "$ENV_DIR"
require_cmd az
require_cmd jq
required_files=(global.json subscriptions.json policy.json logging.json networking.json)
for file in "${required_files[@]}"; do
  [[ -f "$ENV_DIR/$file" ]] || { err "Missing $ENV_DIR/$file"; exit 1; }
done
log "Validating JSON configuration for environment: $ENVIRONMENT"
for file in "$ENV_DIR"/*.json; do jq empty "$file"; done
bash "$SCRIPT_DIR/compile-env.sh" "$ENVIRONMENT"
log "Building Bicep files"
while IFS= read -r -d '' file; do
  echo "  - $file"
  az bicep build --file "$file" >/dev/null
done < <(find "$BICEP_ROOT" -name '*.bicep' -print0)
az bicep build --file "$ROOT_DIR/governance/policy-assignments/customPolicyAssignment.bicep" >/dev/null
log "Validation completed successfully"
