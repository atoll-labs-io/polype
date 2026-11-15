---
validated: yes
---
# Plan — s182-po-change-needs-a-version

[Story](../stories.md) · [Research](../research/s182-po-change-needs-a-version.md)

Branch `story/s182-po-change-needs-a-version`. Read `docs/research/s182-po-change-needs-a-version.md` first; this plan builds on it without repeating it.

The technical choice is settled: the owner chose option **A** of ADR-0125 (`docs/decisions/ADR-0125-la-version-de-po-se-verifie-contre-origin-de-la-branche-cible.md`, `accepted`) on 2026-11-15, decision d-0029 of the inbox. `bin/po-version-check`, run by one test of the suite, with `origin/<Target branch>` as its default base and a full-history checkout; `bin/po-ci` and ADR-0105 do not change. The script keeps the story's default name, `bin/po-version-check`.

## Story
A pull request that changes `po/` without raising the version fails the `suite` check, so a version number always names one state of the sources (ADR-0122, fixes #296). Criteria: `po_diff_without_bump_is_refused`, `bump_moves_the_three_places`, `other_diffs_pass`, `missing_base_fails`, `workflow_brings_the_base`, `ci_still_has_one_entry` (see the research for their text).

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Reading the three versions | In this repository: `tests/record-review-loose-ends.oracle.test.sh:91-93` | — (copied into the script; a test file cannot be sourced by a `bin/` script) |
| Reading `Target branch` | In this repository: the `sed` of `bin/po-ci:9` | — |
| Root from the script's path | In this repository: `bin/po-ci:6` | — |
| Base of a story | Platform: `git merge-base HEAD <base>`, as `method/hooks/po-bounds.sh:151` | The hook's `story_base` reads the main worktree's branch, which CI does not have; only its `merge-base` call applies |
| Version order | Platform: `sort -V` (`tests/record-review-loose-ends.oracle.test.sh:97`) | — |
| `bin/po-version-check` itself | New code, ~40 lines of bash | `bin/po-release:10-15` checks two places against each other and never a base. It runs on tags only and builds `po`, so neither its reading nor its moment fits. |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/po-change-needs-a-version.oracle.test.sh` | `473480134 6838` |

| Criterion | Test |
| --- | --- |
| `po_diff_without_bump_is_refused` | `test_po_diff_without_bump_is_refused`: a scratch repository, `po/src` changed at 1.2.3 → non-zero exit naming `1.2.3`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`; then the three raised to 1.2.10 → exit 0 (catches a string comparison) |
| `bump_moves_the_three_places` | `test_bump_moves_the_three_places`: the six one-or-two-place bumps and two lower versions are refused; 2.0.0 everywhere passes |
| `other_diffs_pass` | `test_other_diffs_pass`: README only passes; a pure bump passes; a docs branch passes when `po/` changed on its base after the fork (diff is base...HEAD) |
| `missing_base_fails` | `test_missing_base_fails`: an absent ref fails and is named; with no argument and `Target branch: trunk`, it fails naming `origin/trunk`; once that ref exists, the default compares against it |
| `workflow_brings_the_base` | `test_workflow_brings_the_base`: one checkout, `fetch-depth: 0`, no `ref:`, `repository:` absent or `${{ github.repository }}`, no `head_ref`/`head.repo`/`pull_request_target`; and `origin/<Target branch>` resolves where the suite runs |
| `ci_still_has_one_entry` | `test_ci_still_has_one_entry`: sources s159's oracle and runs `test_workflow_only_calls_the_entry`, so the ADR-0105 rule stays tested in one place |

The oracle was run against a throwaway prototype outside the worktree: all six pass. Three broken variants each turn one test red: string ordering, a two-dot diff, and a hard-coded `origin/main`.

## Tasks
1. [x] **Write `bin/po-version-check`** (executable, `#!/usr/bin/env bash`, `set -u`). Interface fixed by the oracle:
   - `bin/po-version-check [<base-ref>]`, from any directory. It works on the repository that holds it (root from `$0`, as `bin/po-ci:6`) and reads no environment variable of any forge.
   - With no argument, base = `origin/<Target branch>`, read from `<root>/AGENTS.local.md`. A missing setting → exit 2, naming `Target branch`.
   - `git rev-parse --verify -q "<base>^{commit}"` fails → exit 2, message `po-version-check: <base> is not in this repository…`, never a pass. No merge base → exit 2, naming the base.
   - `mb = merge-base HEAD <base>`. Read the three versions with `git show <rev>:<path>` at `HEAD` and at `mb`, using the readers of the Reuse table.
   - Rule 1: at `HEAD`, the three are non-empty and equal. Otherwise exit 1 with each file and its value.
   - Rule 2: if the `HEAD` version differs from the `mb` version, it must be higher by `sort -V`. Otherwise exit 1.
   - Rule 3: if `git diff --name-only <mb> HEAD -- po/` is non-empty and the version did not change → exit 1 with `po/ changed since <base> but po is still at <v>: raise po/Cargo.toml, po/Cargo.lock and POLYPE_VERSION in bin/polype together (ADR-0122)`.
   - Otherwise exit 0 with one line on stdout.
   - Comment the header only: what it checks, and that it reads no forge variable.
   Test: the five scratch-repository tests of the oracle (`bash tests/run.sh po-change-needs-a-version.oracle.test.sh`).
2. [x] **Make the suite refuse.** Create `tests/po-change-needs-a-version.test.sh` with `test_this_repository_versions_po`. It runs `"$ROOT/bin/po-version-check"` with no argument and fails with its output unless it exits 0. Test: this function itself. It must pass in this worktree, since `origin/main` is present and the story leaves `po/` alone. Checking that it bites, with a `po/` change and no bump, is the reviewer's job (ADR-0012).
3. [x] **Bring the base in CI.** In `.github/workflows/ci.yml`, replace the checkout's `with:` block (`:16-21`, the comment, `repository:` and `ref:`) with `fetch-depth: 0` and a one-line comment saying why: the version check compares against `origin/<Target branch>`. Leave the `on:`, `permissions:` and `run:` lines and the pinned `uses:` byte for byte. Tests: `test_workflow_brings_the_base`, `test_ci_still_has_one_entry` and `tests/ci-on-every-pr.oracle.test.sh` unchanged and green.
4. [x] **Document it.** In `docs/ci.md`, rewrite `:11`: a pull request is checked out as GitHub's merge commit, with the whole history, so `origin/main` is the base and the check judges the merge (#221 fixed by s181). Under "Ce qui tourne", add one paragraph: any change to `po/` raises the version in the same story, in `po/Cargo.toml`, `po/Cargo.lock` and `bin/polype`, and `bin/po-version-check`, run by the suite, refuses otherwise (ADR-0122, ADR-0125). In "Publier une version", step 1 says the version was already raised by the story that changed `po/`, and adds `po/Cargo.lock`. French, as the rest of `docs/`.
5. [x] **Commit, then run the full suite** through `po-run --story s182-po-change-needs-a-version --label suite -- 'bash tests/run.sh'`. Commit first: `tests/readme-onboarding.test.sh` clones the committed HEAD. Then complete the record. ADR-0125 is `accepted`; the implementer never edits it.

## Scene viewpoints
—

## Run interdicts
- `po/`, `bin/polype`, `bin/po-release`, `bin/po-ci`, `tests/run.sh`, `tests/ci-on-every-pr.oracle.test.sh`, `tests/ci-on-every-pr.test.sh`, `method/`, `.github/workflows/release.yml` and `README.md` end with an empty diff (`git diff main...story/s182-po-change-needs-a-version -- <path>`). Under option A, `bin/po-ci` and `tests/run.sh` stay as they are even though `Owns` lists them.
- `po/Cargo.toml`, `po/Cargo.lock` and `POLYPE_VERSION` keep `0.3.1`: no version moves in this story.
- `bin/po-version-check` reads no `GITHUB_*`, `GITLAB_*`, `CI*`, `GITEA_*` or `FORGEJO_*` variable, makes no network call (no `git fetch`, `curl`) and writes no ref.
- `.github/workflows/ci.yml` keeps exactly two `run:` steps, `jq` and `bin/po-ci`, and one `uses:`, the pinned checkout. It never uses `pull_request_target`.
- The oracle's sum stays `473480134 6838` unless `## Oracle changes` of the record says why.
- No ADR is written or edited during execution: ADR-0125 is accepted as the planner left it, and no other ADR changes.

## The pivot
The decision this rests on is that **`origin/<Target branch>`, after a full-history checkout of the pull request's merge commit, is the base on every forge, and the diff to judge is `merge-base(HEAD, base)..HEAD`.** Three ways it could be wrong:
- `actions/checkout` might not leave `refs/remotes/origin/main` on a `pull_request` event, or might leave the fork's. Compare with this story's own `suite` run: `test_workflow_brings_the_base` and `test_this_repository_versions_po` fail on it, naming `origin/main`.
- The suite might break on a detached merge commit. `head_ref` hid that until now. Compare with the same run: any test that needs `$ROOT` on a branch turns red there, not locally.
- The merge base might be wrong when `main` moved after the fork, and charge the story with a bump made on `main`. Compare with `test_other_diffs_pass`, third case.

## Files touched
`bin/po-version-check` (new), `tests/po-change-needs-a-version.test.sh` (new), `tests/po-change-needs-a-version.oracle.test.sh` (oracle, already written), `.github/workflows/ci.yml`, `docs/ci.md`, `docs/decisions/ADR-0125-la-version-de-po-se-verifie-contre-origin-de-la-branche-cible.md` (written by the planner), `docs/research/…`, `docs/plans/…`, `docs/verif/…`.

## Test strategy
Seven tests, within `Test budget` 25.
- Script, through its command-line interface, on throwaway repositories: the four scratch tests of the oracle. These check the rule itself; no mock, real git.
- Workflow file, read as text: `test_workflow_brings_the_base`, plus `test_ci_still_has_one_entry`, which reuses s159's check instead of copying it (cut 3 of the doctrine).
- The live rule on this repository: `test_this_repository_versions_po`. This is what makes the `suite` check refuse. It is not a duplicate of the scratch tests, since it checks this repository's diff, not the script's logic.
- Not provable here: a real pull request that touches `po/`. s183 brings it, and its review notes it (story notes).
- Criteria regime (owner, 2026-11-13): every criterion is read by a script, so each has its oracle test. No criterion speaks to a model, so no `po-eval` candidate.

## Done when
One commit on `story/s182-po-change-needs-a-version` holding the files above. `bash tests/run.sh` is green through `po-run`, and the `suite` check on the pull request is green, with `origin/main` present. The review has no open critical finding. #296 closes at ship.
