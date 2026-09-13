#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
ENVIRONMENT="${1:-prod}"
ENV_DIR="$(env_dir "$ENVIRONMENT")"
COMPILED_DIR="$(compiled_dir "$ENVIRONMENT")"
require_cmd jq
bash "$SCRIPT_DIR/compile-env.sh" "$ENVIRONMENT"
for file in context.json variables.generated.json mgDiagSettingsAll.parameters.json subPlacementAll.parameters.json policyAssignment.parameters.json; do
  [[ -f "$COMPILED_DIR/$file" ]] || { err "Missing compiled artifact $file"; exit 1; }
  jq empty "$COMPILED_DIR/$file" >/dev/null
  log "Verified $file"
done
[[ -f "$ROOT_DIR/governance/policy-assignments/customPolicyAssignment.bicep" ]] || { err "Missing governance policy assignment module"; exit 1; }
log "Sprint 2 verification completed"
