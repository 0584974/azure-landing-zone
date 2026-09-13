# Changelog

## Sprint 2

- Added compiled environment generation under `environments/<env>/compiled/`
- Added stage-specific deployment scripts: platform, governance, observability
- Expanded GitLab CI pipeline to include compile, what-if, deploy, and verify stages
- Added parameterized management-group governance policy assignment module
- Added verification script and stronger operational documentation
- Preserved legacy deployment path via `./deploy-alz.sh legacy`

## Sprint 1

- Introduced environment folders (`dev`, `test`, `prod`)
- Added validation and what-if pipeline skeleton
- Added docs and governance skeleton
