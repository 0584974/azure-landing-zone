# Operations

## Day-2 operating model

- Change configuration in `environments/<env>/*.json`.
- Run `scripts/validate.sh <env>` before opening a merge request.
- Review `what-if` output for each component separately.
- Promote through environments by merging the same code and only changing protected CI variables and environment configuration.

## Rollback approach

Sprint 2 still relies on controlled redeployment rather than an automated rollback engine. Recommended approach:

1. revert the merge request,
2. rerun validate and what-if,
3. redeploy the affected component stage.

## Security notes

- Secrets must come from GitLab protected variables or workload identity federation.
- Do not store service principal secrets in the environment JSON files.
- `variables.generated.json` is a compiled compatibility artifact and should not be manually edited.
