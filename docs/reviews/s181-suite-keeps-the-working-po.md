# Review — s181-suite-keeps-the-working-po

[Story](../stories.md) · [Plan](../plans/s181-suite-keeps-the-working-po.md) · [Verification](../verif/s181-suite-keeps-the-working-po.md)

Method version: 0.3.1

Diff reviewed: `git diff main...story/s181-suite-keeps-the-working-po`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 431a83914f2ed73f47697e7abb1887fd120e386e

## When blocked
- Failure cause: none, the review is complete
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s181-suite-keeps-the-working-po`, and each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. `tests/readme-onboarding.test.sh` and `tests/suite-keeps-the-working-po.oracle.test.sh` are listed there. `docs/research/`, `docs/plans/` and `docs/verif/` of this story count as pipeline evidence, which is in scope by construction.
- [x] Nothing outside `Owns`.
- [x] Nothing inside the `Owns` of another running story. `git worktree list` shows only `main`, `.claude/worktrees/framing-m22` (`fix/qa-deadline-wording`, not a story) and this worktree. s182 also owns `tests/run.sh`, but this diff does not touch that file.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s181-suite-keeps-the-working-po` → exit 0, so the record is reused. Checked by hand as well: `git diff --quiet <Tree> HEAD -- . ':(exclude)docs'` exits 0 for the record's `Tree:` (69187147…) and for the run's tree (2ea741af…). The one declared check, the unit suite (`bash tests/run.sh`), exited 0 after 436 s. The record lists no type check, E2E or build because the project has none (`Typecheck: —`, `E2E: —`, `Build: —`). Its "Not proven here" section names the CI `suite` check on a shallow checkout.
- [x] `po-gate qa-current` → not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Task 1 is in the diff: a bare `$SCRATCH/polype.git` whose `main` is fetched from `$ROOT` HEAD, with the substituted URL and the count check changed to match.
- [x] Task 2 is in the diff: `export CARGO_TARGET_DIR="$SCRATCH/target"` next to `HOME`, with a comment giving the reason.
- [x] Task 3 is covered by the record.
- [x] Nothing outside the plan.
- [x] Run interdicts, checked one by one:
  - `README.md`, `bin/`, `po/`, `method/`, `tests/run.sh`, `tests/lib.sh` and `.github/` all have an empty diff (0 lines).
  - Only `test_quickstart_runs_as_written` changes. Its shape checks and post-install checks are untouched.
  - The oracle sum matches: `2590878491 3123`.
  - There is no `tests/suite-keeps-the-working-po.test.sh`.
  - No version bump.
  - The CI checkout workaround is left in place.

## References
- [x] Every reference was opened and confirmed:
  - `scratch_repo` (`tests/lib.sh:47`) and `$PO` (`tests/lib.sh:7`, read from `CARGO_TARGET_DIR`).
  - The export of `CARGO_TARGET_DIR` in `tests/run.sh:11`.
  - `build_po` in `bin/polype`, which builds into `${CARGO_TARGET_DIR:-$base/po/target}`.
  - `README.md` line `git -C ~/src/polype pull`, which the third oracle test matches.
  - The shape in `tests/po-prebuilt-and-verified.test.sh:14`.
- [x] No value only looks right. `git init --bare -b main` matches what `scratch_repo` already relies on. Each test runs in its own process (`tests/run.sh`, `bash -c` per test), so the new exports cannot leak into later tests.

## Rules
- [x] `AGENTS.md` conventions respected. Code and comments are in English, and the comments explain why.
- [x] No accepted ADR contradicted. ADR-0122 does not apply because `po/` is untouched.

## Tests
- Oracle: `po-gate oracle-intact s181-suite-keeps-the-working-po` → exit 0
- [x] Oracle: `po-gate oracle-intact` → 0, intact.
- [x] Floor: `po-gate floor-guard s181-suite-keeps-the-working-po main` → 0, nothing lowered.
- [x] The assertions pin the three criteria. Each test runs the runner of a committed copy of the tree in its own `CARGO_TARGET_DIR`/`HOME`. None of the six empty test shapes is present. The probe calls the real `$PO`, and the third test proves the README blocks still run by injecting `exit 7`.
- [x] 3 tests, within the `Test budget` of 25. The added runtime is argued in the plan's test strategy.
- [x] Bite 1: `export CARGO_TARGET_DIR="$SCRATCH/target"` commented out → 1 failing oracle test (`working_po_survives_the_suite`, through the nested `probe_gets_the_working_po`) → undone with `git checkout --`, `git diff --exit-code` clean.
- [x] Bite 2: clone source switched back to `file://$ROOT` (substitution and count) → 1 failing oracle test (`quickstart_runs_from_a_detached_head`) → undone, `git diff --exit-code` clean. Afterwards `git status --porcelain` was empty.
- [x] The story makes no test useless.

## Neighbours
- [x] I read the other users of `CARGO_TARGET_DIR` and the other clones the research's H3 lists. `po-prebuilt-and-verified*` already isolate their target, and `local-copy-checksums` does not copy `po/`. Nothing else writes into the shared target.

## Lenses
Lenses run: none. The diff touches only bash test files and story docs, which matches no security, migration, dependency or performance trigger.
- [x] No lens findings.

## Findings
- none

## Not verified
- **CI shallow checkout (open question 1 of the research).** I did not check that `git fetch` from CI's depth-1 checkout into the bare repository passes on `ubuntu-latest`; it only shows up on CI. Someone should check that the pull request's `suite` check is green before merging. If it fails, the plan's fallback is a bare `git clone` plus `update-ref`.
- **Poisoned targets already on disk (H2).** A `po/target` overwritten by a run before this fix stays stale. Nothing in the diff heals it. A developer whose `$PO` still answers with HEAD's text runs `touch po/src/main.rs` once.
- **Full suite not rerun here.** Under `Verification mode: record`, the passing record proves it for this exact code outside `docs/`. I ran only the oracle file, twice, each time under a mutation.
- **Redundant CI workaround.** The workaround in `.github/workflows/ci.yml:17-20` (checking out `head_ref` because of #221) becomes unnecessary with this fix. It is outside this story's `Owns` (s182 owns `ci.yml`), so I did not judge it.

Max severity: none
Ship allowed: yes

Method version: 0.3.1

Diff reviewed: `git diff main...story/s181-suite-keeps-the-working-po`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 9e8090c6d4c6ca35a39db1aee51116243147e1d7

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-only main...story/s181-suite-keeps-the-working-po` and held each path against the story's `Owns`, using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. The two code paths are `tests/readme-onboarding.test.sh` and `tests/suite-keeps-the-working-po.oracle.test.sh`, and both are listed in `Owns`. The other paths are the story's own research, plan, verif and review files.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s181-suite-keeps-the-working-po` returned 0, so I reused the record. It holds two `bash tests/run.sh` runs, both exit 0, the last at 13:59:32Z on the fix tree. Its "Not proven here" section says the forge run remains the final proof.
- [x] `po-gate qa-current` was not required. `QA stage` is `—`, so the story does not go to QA.

## Plan
- [x] Task 2 is present: the test exports `CARGO_TARGET_DIR="$SCRATCH/target"`.
- [x] Task 1 is present in a changed form. The fix replaced `init --bare` + `fetch` with `git clone --bare "file://$ROOT"` + `update-ref refs/heads/main <HEAD>` + `symbolic-ref`. The plan's `## Risks` section, under "Shallow CI", names this exact fallback, so the change was foreseen.
- [x] Nothing outside the plan. The fix commit fbe17bb touches only the test file and the verif record.
- [x] Run interdicts: the project has no E2E or build command (`—`), so there was nothing to check there.

## References
- [x] Confirmed: `scratch_repo` and the `PO` path in `tests/lib.sh:7` (it reads `CARGO_TARGET_DIR`); `tests/run.sh:11` (it exports the shared target); and the README's `git -C ~/src/polype pull` line, which the oracle awk relies on and the test asserts with `grep -qx`.
- [x] No value only looks right. The substitution count check now targets `file://$SCRATCH/polype.git`, the URL that is actually substituted.

## Rules
- [x] `AGENTS.md` conventions are respected: bash tests, oracle in `*.oracle.test.sh`, English comments.
- [x] No accepted ADR is contradicted.

## Tests
- Oracle: `po-gate oracle-intact s181-suite-keeps-the-working-po` → exit 0
- [x] Oracle: `po-gate oracle-intact` returned 0.
- [x] Floor: `po-gate floor-guard s181-suite-keeps-the-working-po main` returned 0, so nothing was lowered.
- [x] The assertions pin the three criteria. None of the six empty test shapes is present: the probe test checks the real `$PO` output, and the "still runs as written" test checks both the FAIL and the echoed line.
- [x] 3 oracle tests, within the `Test budget` of 25.
- [x] The question for this loop: does the fix hold for a shallow checkout whose detached HEAD no branch holds? It does, and I proved it outside the worktree in `/tmp/tmp.If1g3hZZ4M/`:
  - **Detached case.** `ci/` is a depth-1 fetch of the story tip into `refs/remotes/pull/338/merge`, detached, plus one extra commit (40cba7b) that no ref holds. It has no `refs/heads` and `.git/shallow` holds fbe17bb.
    - `git clone --bare file://…/ci` exits 0. The result has no refs, a HEAD detached on 40cba7b, and is shallow.
    - `update-ref refs/heads/main 40cba7b…` and `symbolic-ref` both exit 0, and `fsck --connectivity-only` is clean.
    - Cloning that bare repo and running `git pull` in the clone works, and the clone is on `main`.
    - `bash tests/run.sh readme-onboarding.test.sh` from `ci/`: 6 passed, `quickstart_runs_as_written` ok.
    - The oracle file from `ci/`: 3 passed.
  - **Branch case (what CI actually does).** `.github/workflows/ci.yml` checks out `ref: ${{ github.head_ref }}`, so on CI the checkout is shallow and on a local branch, not detached. I rebuilt that shape in `ci2/` (depth 1, local branch `story/s181-…`). `quickstart_runs_as_written` is ok there too.
  - **Before the fix.** In the same `ci/` checkout, the pre-fix version (8774ed8) fails `quickstart_runs_as_written` with "Vous semblez avoir cloné un dépôt vide", the empty clone seen on the forge. Main's version fails there as well.
- [x] Bite (each mutation made in the scratch copy, then undone; `git diff --exit-code` clean on the scratch copy and on the worktree):
  - Removing `update-ref` and `symbolic-ref` makes 1 test fail (`quickstart_runs_as_written`).
  - Removing `export CARGO_TARGET_DIR="$SCRATCH/target"` makes 1 oracle test fail (`working_po_survives_the_suite`, through the probe `probe_gets_the_working_po`).
  - Swapping clone back to fetch (the pre-fix version) makes 1 test fail on a shallow checkout.
- [x] No test was made useless by the story.

## Neighbours
- [x] The fix changes nothing outside one test function. The oracle's `tree_copy` builds a fresh full-history repo and calls the same test, which I ran from a shallow checkout as shown above.

## Lenses
Lenses run: none. No security, migration, dependency or server-side trigger in the diff, which is test-only bash.
- [x] Nothing to grade.

## Findings
- minor — tests/suite-keeps-the-working-po.oracle.test.sh:6 — Only the forge exercises the shallow case. `tree_copy` always builds a full-history repo, so `quickstart_runs_from_a_detached_head` covers detachment but not shallowness. That is why loop 0 and the local suite missed the CI failure. A shallow regression would still be caught by the forge's own `suite` check, which runs this test at depth 1 on every pull request. A local test would need a depth-1 fetch of `tree_copy`'s repo.
- minor — docs/plans/s181-suite-keeps-the-working-po.md:40 — Task 1 still says `git init -q --bare` + `git fetch`, while the code now uses `git clone --bare` + `update-ref` + `symbolic-ref`. The verif record explains the change, but the plan's task text no longer matches the code.

## Not verified
- I did not see the forge's own `suite` run of pull request #338 on fbe17bb. My scratch runs reproduce the CI checkout shape (depth 1, both detached and on a branch), but not the CI runner's git version or its `actions/checkout` internals. Someone should confirm that the `suite` check of #338 goes green before the merge.
- I did not rerun the full suite. I relied on the current verif record, whose last run exited 0 on the fix tree.

Max severity: minor
Ship allowed: yes
