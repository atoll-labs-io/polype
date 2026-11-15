# Review — s182-po-change-needs-a-version

[Story](../stories.md) · [Plan](../plans/s182-po-change-needs-a-version.md) · [Verification](../verif/s182-po-change-needs-a-version.md)

Method version: 0.3.1

Review status: complete
Reviewed tree: ada881c49574b56f52d3f3c67e3fbc274d48bca3
Fix loop: 0
Lenses run: none. The diff touches `bin/`, `tests/`, `docs/` and `.github/workflows/ci.yml`. None of these is an auth, route, migration, lockfile or server path. The workflow change takes away the fork-head checkout and adds no right, so the security posture does not change.

## Scope
All nine paths in `git diff --name-only main...story/s182-po-change-needs-a-version` are in scope. The story's `Owns` covers `bin/po-version-check`, `.github/workflows/ci.yml`, `docs/ci.md`, `docs/decisions/` and both `tests/po-change-needs-a-version*.test.sh`. The research, plan and verification files are pipeline evidence. ADR-0125 is newly added under `docs/decisions/` and the plan names it. The run interdicts hold: `po/`, `bin/polype`, `bin/po-ci`, `tests/run.sh`, `method/`, `README.md` and the s159 tests have an empty diff, and no version moved (it stays 0.3.1).

## What was relied on
- `po-gate verif-current` exited 0 (`Verification mode: record`). The record's `Tree:` 2bb45f7… equals HEAD outside `docs/`, and its `bash tests/run.sh` row exited 0. I did not rerun the suite in the worktree. The project has no type check (`Typecheck: —`).
- `po-gate oracle-intact` exited 0, and the record lists no oracle changes.
- `po-gate floor-guard … main` exited 0, so no check was made easier to pass.
- `QA stage: —`, so the story has no QA to require.

## What I checked myself
- **The plan's tasks, one by one.** Tasks 1 to 5 all match the diff: the interface, the three rules, the error codes and messages, the default `origin/<Target branch>`, the workflow `with:` block replaced by `fetch-depth: 0`, and the `docs/ci.md` rewrites. The script copies its version readers from `tests/record-review-loose-ends.oracle.test.sh:91-93`, as the plan's Reuse section says. It reads no forge variable, makes no network call and writes no ref.
- **Bite test 1.** I turned Rule 3 into `elif false`, so a `po/` change without a bump would pass. Two tests failed: `po_diff_without_bump_is_refused` and `missing_base_fails`. I restored the file and `git diff --exit-code` confirmed it.
- **Bite test 2.** I removed the `$toml != $lock` comparison from Rule 1. One test failed: `bump_moves_the_three_places`, on the case "1.2.4 1.2.3 1.2.4". I restored the file and `git diff --exit-code` confirmed it.
- **The repository-level test actually refuses.** In a throwaway clone (`/tmp/tmp.pjTlLotUjy/live`), I committed a change to a file under `po/src` without a bump on top of the story. `test_this_repository_versions_po` then failed with the ADR-0122 message naming 0.3.1 and the three files.
- **The plan's main risk, tried under CI-like conditions.** I built a clone (`/tmp/tmp.pjTlLotUjy/ci`) shaped like the pull request checkout: HEAD detached on a merge commit of `origin/main` and the story, no local branch, full history, `origin/main` present. The whole `bash tests/run.sh` passed there: 835 passed, 0 failed. So dropping the `head_ref` workaround breaks no test on a detached merge commit, and the `git pull` statement in `docs/ci.md` holds.
- **Other files that mention the old checkout.** Only old reviews and research mention `head_ref`. Those are history, not current documents.

## Tests
- Oracle: `po-gate oracle-intact s182-po-change-needs-a-version` → exit 0

## Findings
- minor — bin/po-version-check:53 — The script compares versions with `sort -V`, which ranks `1.0.0-rc1` above `1.0.0` (checked locally). A move from a pre-release to its final version would therefore be refused as a downgrade, although semver says the final version is higher. po has never published a pre-release, so nothing is affected today.

## Not verified
- **A real GitHub `pull_request` run** with `actions/checkout` at the pinned SHA and `fetch-depth: 0`. I did not see it leave `refs/remotes/origin/main` from the base repository, including for a fork PR. My clone imitates that checkout but is not the forge. This story's own `suite` check on its pull request settles it: a person should confirm it is green and that `test_workflow_brings_the_base` passes there.
- **A real pull request that changes `po/` without a bump**, refused on the forge. Story s183 brings it, as the plan says. I only saw the refusal locally.
- **The pre-existing failure of `po-bounds`** that a slip of mine triggered. My first shell call contained `git branch --show-current`, which the reviewer hook refuses. I got the same fact through `git rev-parse --abbrev-ref HEAD`, a reading verb the hook allows, so I did not use a bypass. Nothing about the code is left unseen because of it.

Max severity: minor
Ship allowed: yes
