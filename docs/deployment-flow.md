# Deployment Flow

## Merge request flow
1. Developer updates Bicep, docs, or environment files.
2. GitLab runs `validate` automatically.
3. Reviewers approve the change.
4. A manual `what-if` job can be run from the default branch.

## Future iterations
- Add deploy stages
- Add post-deploy verification
- Add rollback and drift detection
