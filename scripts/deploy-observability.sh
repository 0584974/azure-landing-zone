#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
ENVIRONMENT="${1:-prod}"
ENV_DIR="$(env_dir "$ENVIRONMENT")"
COMPILED_DIR="$(compiled_dir "$ENVIRONMENT")"
MG_ID="$(jq -r '.managementGroupId' "$ENV_DIR/global.json")"
LOCATION="$(jq -r '.primaryLocation' "$ENV_DIR/global.json")"
TEMPLATE_FILE="$ROOT_DIR/platforms/infra-as-code/bicep/orchestration/mgDiagSettingsAll/mgDiagSettingsAll.bicep"
PARAM_FILE="$COMPILED_DIR/mgDiagSettingsAll.parameters.json"
require_cmd az; require_cmd jq
bash "$SCRIPT_DIR/compile-env.sh" "$ENVIRONMENT"
[[ "$MG_ID" != "your-management-group-id" ]] || { err "Set a real managementGroupId in $ENV_DIR/global.json"; exit 1; }
log "Deploying management-group diagnostic settings to management group $MG_ID"
az deployment mg create --management-group-id "$MG_ID" --location "$LOCATION" --template-file "$TEMPLATE_FILE" --parameters @"$PARAM_FILE"
