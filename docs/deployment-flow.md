# Deployment flow

Sprint 2 introduces a compiled environment model and separates deployment into three management-group stages:

1. **Platform** – subscription placement into the ALZ hierarchy.
2. **Governance** – baseline policy assignment(s).
3. **Observability** – management-group diagnostic settings.

## Local flow

```bash
bash scripts/validate.sh prod
bash scripts/whatif.sh prod platform
bash scripts/whatif.sh prod governance
bash scripts/whatif.sh prod observability
bash scripts/deploy-platform.sh prod
bash scripts/deploy-governance.sh prod
bash scripts/deploy-observability.sh prod
bash scripts/verify.sh prod
```

## Compiled artifacts

`bash scripts/compile-env.sh <env>` generates environment-specific deployment files under `environments/<env>/compiled/`:

- `variables.generated.json`
- `subPlacementAll.parameters.json`
- `policyAssignment.parameters.json`
- `mgDiagSettingsAll.parameters.json`
- `context.json`

These files bridge the environment model to the existing Bicep modules without forcing an all-at-once refactor of every module input.
