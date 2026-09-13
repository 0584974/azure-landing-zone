# Source integrity and provenance

This document records verifiable integrity facts for the deployable source baseline and separates the current history from an earlier, abandoned import attempt.

## Anchored source baseline

The deployable source tree was anchored on 2026-09-13, immediately before this documentation was added:

- source commit: `36c6ce3d1ca8512eeed384646a837f5a9716c713`
- source tree: `40f70f41753a8d74ec29e53e42266609f901ea6f`
- root commit: `0ae74370f2acb74ce2781df45283f46e0ff9f3e3`
- root tree: `bc47790f17fbb90ee728f64add4ebeccc1a1844a`
- recursive source-tree result: 1,052 entries with `truncated: false`

The anchored source history contains three commits and starts at the root commit above. Later documentation-only commits do not change this source anchor. When deployable files change, record a new source anchor.

## Obsolete import attempt

GitHub Actions run [34757452900](https://github.com/0584974/azure-landing-zone/actions/runs/34757452900) failed on commit `fe35553e9c5df0e50552d4feb0a79d88e7040ebb` while reconstructing a split gzip manifest. That commit is not part of the current `main` history, and the corresponding `.import/` and `.github/workflows/compare-upstream.yml` paths are not present in the anchored source tree.

Treat that run as historical evidence of a discarded import method, not as validation status for the current baseline.

## Reproduce the checks

```bash
git fetch origin main
SOURCE_COMMIT=36c6ce3d1ca8512eeed384646a837f5a9716c713
git cat-file -e "${SOURCE_COMMIT}^{commit}"
git rev-parse "${SOURCE_COMMIT}^{tree}"
git rev-list --max-parents=0 "${SOURCE_COMMIT}"
git merge-base --is-ancestor "${SOURCE_COMMIT}" origin/main
git merge-base --is-ancestor fe35553e9c5df0e50552d4feb0a79d88e7040ebb origin/main   && echo "obsolete import is an ancestor"   || echo "obsolete import is not an ancestor"
```

To confirm the anchored recursive tree through GitHub:

```bash
curl -fsSL   https://api.github.com/repos/0584974/azure-landing-zone/git/trees/36c6ce3d1ca8512eeed384646a837f5a9716c713?recursive=1   | jq '{sha, truncated, entries: (.tree | length)}'
```

Expected result: tree `40f70f41753a8d74ec29e53e42266609f901ea6f`, `truncated: false`, and 1,052 entries.

## Scope and safe use

This repository is a reference Azure landing-zone baseline, not an official Microsoft distribution. Review tenant IDs, subscription mappings, policy effects, regions, permissions, and generated deployment plans before use. Run validation and Azure what-if first. Deployment stages are intentionally manual and require operator-controlled credentials and approval.

No production availability, rollback, or service-level guarantee is implied.
