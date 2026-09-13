#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENT="${1:-prod}"
ENV_DIR="$ROOT_DIR/environments/$ENVIRONMENT"
TEMPLATE_FILE="$ROOT_DIR/platforms/infra-as-code/bicep/orchestration/mgDiagSettingsAll/mgDiagSettingsAll.bicep"

command -v az >/dev/null 2>&1 || { echo "[ERROR] Azure CLI is required." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "[ERROR] jq is required." >&2; exit 1; }

MG_ID="$(jq -r '.managementGroupId' "$ENV_DIR/global.json")"
LOCATION="$(jq -r '.primaryLocation' "$ENV_DIR/global.json")"

if [[ "$MG_ID" == "" || "$MG_ID" == "null" || "$MG_ID" == "your-management-group-id" ]]; then
  echo "[ERROR] Set a real managementGroupId in $ENV_DIR/global.json before running what-if." >&2
  exit 1
fi

echo "[INFO] Running tenant-scoped what-if against management group: $MG_ID"
az deployment mg what-if   --management-group-id "$MG_ID"   --location "$LOCATION"   --template-file "$TEMPLATE_FILE"
