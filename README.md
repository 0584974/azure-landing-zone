# Azure Landing Zone

Azure Landing Zone baseline repository for EU-region deployments using Bicep.

## Sprint 2 highlights

- compiled environment model under `environments/<env>/compiled/`
- stage-specific deployment scripts for platform, governance, and observability
- GitLab pipeline expanded beyond validation into compile, what-if, deploy, and verify stages
- parameterized governance module replacing placeholder-only policy templating for the main baseline assignment path

## Repository flow

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

## Environment model

Each environment keeps source configuration in:

- `global.json`
- `subscriptions.json`
- `policy.json`
- `logging.json`
- `networking.json`

Compiled deployment artifacts are generated automatically into `environments/<env>/compiled/`.

## CI/CD

GitLab CI now separates:

- validation,
- environment compilation,
- what-if review,
- manual deployment by component,
- post-deployment verification.

## Integrity and provenance

See [Source integrity and provenance](docs/source-integrity.md) for the current commit and tree anchors, reproducible verification commands, historical import context, and safe-use boundaries.
