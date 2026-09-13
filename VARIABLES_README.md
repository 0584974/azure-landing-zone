# Variables and Environment Configuration

The repository is transitioning from a single `variables.json` file to environment-specific configuration under `environments/`.

## Current model

### Legacy
- `variables.json` remains in place for backward compatibility with the original deployment script.

### Sprint 1
- `environments/dev/`
- `environments/test/`
- `environments/prod/`

Each environment contains:
- `global.json`
- `subscriptions.json`
- `policy.json`
- `logging.json`
- `networking.json`

## Recommended usage

Use the new environment folders for validation and what-if flows:

```bash
bash scripts/validate.sh prod
bash scripts/whatif.sh prod
```

Use `variables.json` only while the legacy deployment path is still needed.

## Next iteration goals

- remove hard dependency on `variables.json`
- map environment files directly into orchestration templates
- move secrets and authentication out of configuration files and into protected CI variables
