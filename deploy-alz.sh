#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION="${1:-help}"
ENVIRONMENT="${2:-prod}"
case "$ACTION" in
  validate) exec "$SCRIPT_DIR/scripts/validate.sh" "$ENVIRONMENT" ;;
  compile) exec "$SCRIPT_DIR/scripts/compile-env.sh" "$ENVIRONMENT" ;;
  whatif) COMPONENT="${3:-platform}"; exec "$SCRIPT_DIR/scripts/whatif.sh" "$ENVIRONMENT" "$COMPONENT" ;;
  deploy-platform) exec "$SCRIPT_DIR/scripts/deploy-platform.sh" "$ENVIRONMENT" ;;
  deploy-governance) exec "$SCRIPT_DIR/scripts/deploy-governance.sh" "$ENVIRONMENT" ;;
  deploy-observability) exec "$SCRIPT_DIR/scripts/deploy-observability.sh" "$ENVIRONMENT" ;;
  verify) exec "$SCRIPT_DIR/scripts/verify.sh" "$ENVIRONMENT" ;;
  legacy) shift; exec "$SCRIPT_DIR/scripts/deploy-alz-legacy.sh" "$@" ;;
  *)
    cat <<EOF
Usage:
  ./deploy-alz.sh validate <env>
  ./deploy-alz.sh compile <env>
  ./deploy-alz.sh whatif <env> [platform|governance|observability]
  ./deploy-alz.sh deploy-platform <env>
  ./deploy-alz.sh deploy-governance <env>
  ./deploy-alz.sh deploy-observability <env>
  ./deploy-alz.sh verify <env>
  ./deploy-alz.sh legacy [legacy-args]
EOF
    ;;
esac
