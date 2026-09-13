# Azure Landing Zone - RIT Deployment Template

This repository contains an Azure Landing Zone foundation for RIT, implemented primarily in Bicep and organized around management groups, platform subscriptions, networking, logging, and policy-driven governance.

## Sprint 1 status

This iteration introduces the first enterprise-oriented repository refactor:
- environment-specific configuration under `environments/`
- CI validation and manual what-if pipeline stages
- documentation skeleton under `docs/`
- governance folder structure for later iterations
- compatibility wrapper for the original deployment script

The underlying Bicep modules are still the original implementation. Sprint 1 improves structure, validation, and delivery discipline without fully redesigning every deployment path.

## Repository layout

```text
.
├─ .gitlab-ci.yml
├─ CHANGELOG.md
├─ CODEOWNERS
├─ docs/
├─ environments/
├─ governance/
├─ platforms/
│  └─ infra-as-code/
├─ scripts/
├─ deploy-alz.sh
├─ VARIABLES_README.md
└─ variables.json
```

## Quick start

### 1. Validate locally

```bash
bash scripts/validate.sh prod
```

### 2. Run a manual what-if preview

Set a real management group ID in `environments/prod/global.json`, authenticate with Azure CLI, then run:

```bash
bash scripts/whatif.sh prod
```

### 3. Legacy/manual deployment

The original deployment script is preserved and can still be invoked through the compatibility wrapper:

```bash
./deploy-alz.sh
```

## Environment configuration

Each environment has its own folder:

```text
environments/
├─ dev/
├─ test/
└─ prod/
```

Each folder contains:
- `global.json`
- `subscriptions.json`
- `policy.json`
- `logging.json`
- `networking.json`

These files are the first step away from a single monolithic `variables.json`. The legacy file remains in place to avoid breaking the current deployment flow.

## CI/CD

GitLab CI now includes:
- `validate` stage for Bicep build and JSON validation
- manual `whatif` stage for management-group scoped preview

See `.gitlab-ci.yml` and `docs/deployment-flow.md`.

## Documentation

- `docs/architecture.md`
- `docs/management-groups.md`
- `docs/networking.md`
- `docs/deployment-flow.md`
- `docs/operations.md`

## Notes

- All infrastructure code now sits under `platforms/infra-as-code/`.
- `variables.json` is retained for backward compatibility.
- Sprint 2 should focus on refactoring parameter flow, deploy stages, and policy/governance hardening.
