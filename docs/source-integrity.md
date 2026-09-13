# Source integrity and provenance

This document records verifiable integrity facts for this repository and separates the current source tree from an earlier, abandoned import attempt.

## Current baseline

As checked on 2026-09-13:

- default branch: `main`
- current commit: `36c6ce3d1ca8512eeed384646a837f5a9716c713`
- current tree: `40f70f41753a8d74ec29e53e42266609f901ea6f`
- root commit: `0ae74370f2acb74ce2781df45283f46e0ff9f3e3`
- root tree: `bc47790f17fbb90ee728f64add4ebeccc1a1844a`
- recursive Git tree result: 1,052 entries with `truncated: false`

The current `main` history contains three commits and starts at the root commit above. It does not descend from the obsolete import commit described below.

## Obsolete import attempt

GitHub Actions run [34757452900](https://github.com/0584974/azure-landing-zone/actions/runs/34757452900) failed on commit `fe35553e9c5df0e50552d4feb0a79d88e7040ebb` while reconstructing a split gzip manifest. That commit is not part of the current `main` history, and the corresponding `.import/` and `.github/workflows/compare-upstream.yml` paths are not present in the current tree.

Treat that run as historical evidence of a discarded import method, not as validation status for the current baseline.

## Reproduce the checks

```bash
git fetch origin main
git rev-parse origin/main
git rev-parse origin/main^{tree}
git rev-list --max-parents=0 origin/main
git merge-base --is-ancestor fe35553e9c5df0e50552d4feb0a79d88e7040ebb origin/main   && echo "obsolete import is an ancestor"   || echo "obsolete import is not an ancestor"
```

To confirm the full recursive tree through GitHub:

```bash
curl -fsSL   https://api.github.com/repos/0584974/azure-landing-zone/git/trees/main?recursive=1   | jq '{sha, truncated, entries: (.tree | length)}'
```

Expected integrity signal: `truncated` is `false`. Recalculate the commit, tree, and entry count after every intentional baseline update.

## Scope and safe use

This repository is a reference Azure landing-zone baseline, not an official Microsoft distribution. Review tenant IDs, subscription mappings, policy effects, regions, permissions, and generated deployment plans before use. Run validation and Azure what-if first. Deployment stages are intentionally manual and require operator-controlled credentials and approval.

No production availability, rollback, or service-level guarantee is implied.
