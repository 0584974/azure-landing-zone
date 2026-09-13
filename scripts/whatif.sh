#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
ENVIRONMENT="${1:-prod}"
COMPONENT="${2:-platform}"
ENV_DIR="$(env_dir "$ENVIRONMENT")"
COMPILED_DIR="$(compiled_dir "$ENVIRONMENT")"
require_cmd az
require_cmd jq
bash "$SCRIPT_DIR/compile-env.sh" "$ENVIRONMENT"
MG_ID="$(jq -r '.managementGroupId' "$ENV_DIR/global.json")"
LOCATION="$(jq -r '.primaryLocation' "$ENV_DIR/global.json")"
[[ "$MG_ID" != "your-management-group-id" ]] || { err "Set a real managementGroupId in $ENV_DIR/global.json before running what-if."; exit 1; }
case "$COMPONENT" in
  platform)
    TEMPLATE_FILE="$ROOT_DIR/platforms/infra-as-code/bicep/orchestration/subPlacementAll/subPlacementAll.bicep"
    PARAM_FILE="$COMPILED_DIR/subPlacementAll.parameters.json"
    ;;
  governance)
    TEMPLATE_FILE="$ROOT_DIR/governance/policy-assignments/customPolicyAssignment.bicep"
    PARAM_FILE="$COMPILED_DIR/policyAssignment.parameters.json"
    ;;
  observability)
    TEMPLATE_FILE="$ROOT_DIR/platforms/infra-as-code/bicep/orchestration/mgDiagSettingsAll/mgDiagSettingsAll.bicep"
    PARAM_FILE="$COMPILED_DIR/mgDiagSettingsAll.parameters.json"
    ;;
  *)
    err "Unknown component: $COMPONENT (supported: platform, governance, observability)"
    exit 1
    ;;
esac
log "Running what-if for component '$COMPONENT' against management group: $MG_ID"
az deployment mg what-if --management-group-id "$MG_ID" --location "$LOCATION" --template-file "$TEMPLATE_FILE" --parameters @"$PARAM_FILE"
