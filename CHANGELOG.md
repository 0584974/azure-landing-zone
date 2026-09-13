# Changelog

## [0.1.0] - 2026-03-19
### Added
- Sprint 1 repository foundation for an enterprise-style Azure Landing Zone codebase.
- GitLab CI pipeline with validate and manual what-if stages.
- Environment-specific configuration folders for dev, test, and prod.
- Validation and what-if helper scripts under `scripts/`.
- Documentation skeleton for architecture, management groups, networking, deployment flow, and operations.
- Governance folder structure for future policy, initiatives, role definitions, and exemptions.
- `CODEOWNERS` file for repository ownership.

### Changed
- Moved infrastructure code under `platforms/infra-as-code/` to make the platform boundary clearer.
- Converted the former root deployment script into a compatibility wrapper and preserved the original implementation as `scripts/deploy-alz-legacy.sh`.

### Notes
- This iteration focuses on repo structure, validation, and delivery discipline. It does not yet fully refactor all Bicep parameter flows.
