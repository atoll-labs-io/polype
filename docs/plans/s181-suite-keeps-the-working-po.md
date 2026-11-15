---
validated: yes
---
# Plan — s181-suite-keeps-the-working-po

[Story](../stories.md) · [Research](../research/s181-suite-keeps-the-working-po.md)

Branch `story/s181-suite-keeps-the-working-po`. Read `docs/research/s181-suite-keeps-the-working-po.md` first; this plan builds on it without repeating it.

## Story
This story fixes #254 and #221 inside the quickstart test, with no change to `README.md`, `bin/polype` or `po/`.
- `working_po_survives_the_suite`: after `tests/readme-onboarding.test.sh`, `$PO` is the binary built from the working tree, even when `po/` differs from HEAD.
- `quickstart_runs_from_a_detached_head`: the quickstart test passes from a checkout whose detached HEAD no branch holds.
- `quickstart_still_runs_as_written`: the README quickstart commands still run as written, and no README line changes.

## Reuse
No new mechanism: the fix reuses `scratch_repo` (`tests/lib.sh:47`), the isolated target dir shape of `tests/po-prebuilt-and-verified.test.sh:14`, and plain git (`init --bare`, `fetch`).

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Own `CARGO_TARGET_DIR` for the quickstart | already in this repository (`tests/po-prebuilt-and-verified.test.sh:14`) | — |
| Bare source repo whose `main` holds `$ROOT`'s HEAD | the platform (git) | nothing in `tests/lib.sh` prepares a clone source |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/suite-keeps-the-working-po.oracle.test.sh` | `2590878491 3123` |

Each test copies the working tree's files (tracked and untracked, not ignored) into a scratch repository, commits them once on `main`, and runs **that copy's** `tests/run.sh` with `CARGO_TARGET_DIR` and `HOME` under the scratch dir. It goes through the interface the tasks fix: what the suite runner and the readme test do, seen from outside.

| Criterion | Test |
| --- | --- |
| `working_po_survives_the_suite` | `test_working_po_survives_the_suite`. The copy's `po/src/main.rs` (now different from the copy's HEAD) prints one fixed word. A probe test sorting after `readme-onboarding` must get that word from `"$PO"`. |
| `quickstart_runs_from_a_detached_head` | `test_quickstart_runs_from_a_detached_head`. The copy is detached on an extra empty commit no branch holds, and `quickstart_runs_as_written` must pass in it. |
| `quickstart_still_runs_as_written` | `test_quickstart_still_runs_as_written`. The copy's README gains two lines after `git -C ~/src/polype pull` (an echo, then `exit 7`). The quickstart must fail, with the echoed token in its output. That proves the test still runs the README's blocks rather than its own commands. "No README line changes" is checked by the reviewer on the diff (Run interdicts). |

Checked by the planner, outside the worktree (`/tmp/s181-repro/`): on the code as it stands, the first two tests fail and the third passes. With the two tasks below applied to a copy, all three pass, as do the 6 tests of `readme-onboarding`.

## Tasks
1. [x] **Own source for the quickstart (#221).** In `test_quickstart_runs_as_written` of `tests/readme-onboarding.test.sh`, right after `scratch_repo` (`:101`), add `git init -q --bare -b main "$SCRATCH/polype.git"` and `git -C "$SCRATCH/polype.git" fetch -q "$ROOT" HEAD:refs/heads/main || fail "…"`. At `:114`, substitute `$CLONE_URL` with `file://$SCRATCH/polype.git` instead of `file://$ROOT`, and make the count check at `:115` look for that URL. The clone then checks out `main` whatever `$ROOT`'s HEAD is, and the update block's `git pull` has a branch. Test: `test_quickstart_runs_from_a_detached_head`.
2. [x] **Own target dir for the quickstart (#254).** In the same test, export `CARGO_TARGET_DIR="$SCRATCH/target"` next to `export HOME="$SCRATCH/home"` (`:102`), with a short comment saying why: the shared target holds `$PO`, the working tree's binary. `install --global` from the clone then builds HEAD's po there (`bin/polype:868`), never into the target `tests/run.sh:11` exported. Test: `test_working_po_survives_the_suite`.
3. [x] **Focused run, then commit, then full suite.** Run `bash tests/run.sh readme-onboarding.test.sh suite-keeps-the-working-po.oracle.test.sh` (about 70 s here). Commit the story, since the readme test clones committed HEAD. Then run the full suite through `po-run`, and complete the record. Test: the whole suite green, `quickstart_runs_as_written` included.

## Scene viewpoints
—

## Run interdicts
- `README.md`, `bin/polype`, `.github/workflows/ci.yml`, `po/`, `method/`, `tests/run.sh` and `tests/lib.sh` end with an empty diff (`git diff main...story/s181-suite-keeps-the-working-po -- <path>`). `run.sh` and `lib.sh` are in `Owns` but the fix does not need them.
- In `tests/readme-onboarding.test.sh`, only `test_quickstart_runs_as_written` changes, and its shape checks (`:73-99`) and post-install checks (`:118-124`) stay byte for byte.
- The oracle file keeps its sum. A change goes through `## Oracle changes` of the record.
- No `tests/suite-keeps-the-working-po.test.sh`: no task test is planned, and `tests/run.sh` fails a file with no `test_` function.
- No version bump: `po/` is untouched (story note, ADR-0122).
- Do not remove the CI checkout workaround (`ci.yml:17-20`): it is out of `Owns`.

## The pivot
The fix lives in the one test that installs Polype's own sources from a clone. It does not live in `tests/run.sh` (protecting `$PO` with a copy) or in `bin/polype` (out of `Owns`). It could be wrong in three ways:
- **Another writer exists.** A test other than the quickstart could build non-working-tree po sources into the shared target. Compare with H3 of the research (grep of clones and of `CARGO_TARGET_DIR`); the first oracle test only covers `readme-onboarding`. If one turns up, the guard belongs in `tests/run.sh` (its `$PO` taken from a copy outside the target dir, `lib.sh:7` reading `${PO:-…}`), and that is a new task, not a patch.
- **Shallow CI.** `git fetch` from CI's depth-1 checkout into the bare repo could fail where the clone used to pass. Compare with the `suite` check on this story's pull request. If it fails, `git clone --bare -q "file://$ROOT"` followed by `git -C … update-ref refs/heads/main <HEAD sha>` stays inside the same test.
- **Stale targets already on disk** (research H2): a `po/target` poisoned by a pre-fix run stays stale. This fix stops new poisoning but does not heal old targets, and the oracle does not see it because it builds in fresh dirs. A developer who sees `$PO` answer HEAD's text once after this lands needs one `touch po/src/main.rs`.

## Files touched
- `tests/readme-onboarding.test.sh` (task 1, task 2)
- `tests/suite-keeps-the-working-po.oracle.test.sh` (written by the planner)
- `docs/research/s181-suite-keeps-the-working-po.md`, `docs/plans/s181-suite-keeps-the-working-po.md`, `docs/verif/s181-suite-keeps-the-working-po.md`

## Test strategy
- Automated: 3 oracle tests, one per criterion, within `Test budget` (25). There are no task tests: the oracle's first two tests are the tests that would have caught each defect. Each one runs a nested suite on a copy of the tree, the layer where both defects live (the runner's environment shared across test files, and the git state of the checkout).
- Cost, argued: each oracle test pays two cold release builds of po (the copy's `run.sh`, then the quickstart's own target), and the readme test now pays one more. That was ≈ 70 s wall here for oracle + readme, more on a 2-core runner. Seeding the scratch targets from `po/target` was turned down: copied outputs are newer than the sources, which is the very stale-freshness trap of H2.
- Model-read rules: none. Every criterion is read by a script.
- Visual checks: none.

## Done when
- Both tasks ticked. `bash tests/run.sh readme-onboarding.test.sh suite-keeps-the-working-po.oracle.test.sh` is green, then the full suite is green through `po-run` on the committed tree, and the record is complete.
- The diff touches only the files listed above, and the interdicted paths have an empty diff.
- A review with no open critical finding. One commit `s181-suite-keeps-the-working-po: La suite ne remplace plus le po de l'arbre de travail` lands through a pull request whose `suite` check passes. That check is the proof for open question 1 of the research.
