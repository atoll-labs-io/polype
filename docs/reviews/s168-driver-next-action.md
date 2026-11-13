# Review — s168-driver-next-action

[Story](../stories.md) · [Plan](../plans/s168-driver-next-action.md) · [Verification](../verif/s168-driver-next-action.md)

Method version: 0.2.0

Diff reviewed: `git diff main...story/s168-driver-next-action`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 04ca415b982284668f57802ebaea6c165c435b23

## When blocked
Not blocked.

## Ownership
Diff listed with `git diff --name-only main...story/s168-driver-next-action`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`: these are `po/src/next/` (4 files), `po/src/context/mod.rs`, `tests/fixtures/driver-cases/` (7 files), `tests/driver-next-action.oracle.test.sh`, `tests/driver-next-action.test.sh` and `tests/state-as-json.oracle.test.sh`, plus the story's own `docs/research/`, `docs/plans/` and `docs/verif/` files.
- [x] Outside `Owns` → major: none
- [x] Inside another running story's `Owns` → critical: none. `git worktree list` shows only the root and this lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s168-driver-next-action` → exit 0, record reused. The last `Unit suite` row (`bash tests/run.sh`) exited 0 on code equal to `Tree:` outside `docs/`. The project has no type check (`Typecheck: —`): `cargo build --locked` inside `tests/run.sh` compiles the crate. I read the record's "Not proven here" section.
- [x] `po-gate qa-current` → not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1-9 are all present. Nothing is outside the plan: `context/mod.rs` changes only the `pub use stories::{Stories, Story};` line, and `next/mod.rs` drops `#![allow(dead_code)]`.
- [x] Each run interdict, checked one by one:
  - No diff in `po/src/state/`, `inbox/`, `record/`, `run/`, `trust/`, `main.rs`, `project.rs`, `output.rs`, `Cargo.toml` or `Cargo.lock`. Nothing in `method/` or `docs/interface-agent.md`.
  - `tests/state-as-json.oracle.test.sh` changes only the three assertions of task 7.
  - `next/` runs no `gh`, `curl` or `claude`. Its only git use is `log` with `GIT_OPTIONAL_LOCKS=0`, plus `po-gate qa-current` under stage `qa`.
  - `next/` pushes no warning.
  - The actions stay within the contract's ten and the held reasons within its four.

## References
- [x] Opened and confirmed against their definitions:
  - `Context`, `Lane`, `Stage`, `BlockedBy`, `Landed::contains`, `LaneSettings.max_attempts` and `Warning::OrphanWorktree{branch}` (`po/src/context/mod.rs`, `po/src/context/lanes.rs`)
  - `Stories.present`/`list`/`find`, `Story.depends_on`/`owns`/`has_screen` (`po/src/context/stories.rs`)
  - `Decision.blocks: Option<Vec<String>>`, `consumed: Option<Value>` and `status` (`po/src/inbox/decision.rs:48-70`)
  - `project::git` (`po/src/project.rs:20`), `output::reply`/`error`/`UNREADABLE` (`po/src/output.rs`)
  - The callers in `po/src/state/mod.rs:68,83,84`
- [x] Values checked against `method/commands/po-drive.md` `## Resuming` rows 51-69 and lines 142-147:
  - The design row comes after plan-validated.
  - Review at `Fix loop: n` means n fix runs; `Max attempts` is reached at `>=`.
  - The QA-evidence and findings-shape rows ask.
  - Ships run in review order, and a merge-waiting lane keeps its `Owns` but takes no slot.
  - The fix-loop count has one exception: finding 1.

## Rules
- [x] `AGENTS.md` conventions respected. Code and comments are in English, and the tests are bash using `tests/lib.sh` helpers.
- [x] No accepted ADR contradicted. ADR-0118: no new dependency, and the overlap matcher is hand-written instead of a glob crate.

## Tests
- Oracle: `po-gate oracle-intact s168-driver-next-action` → exit 0
  tests/driver-next-action.oracle.test.sh: changed, logged in ## Oracle changes — `test_blocked_on_shape_asks_and_never_fixes`: two lines `W="$F/.worktrees/s01-alpha"` and `W="$F/.worktrees/s02-bravo"` added before its two `review_in` calls; no assertion changes (cksum now `2077968519 16821`) — `review_in` writes into `$W`, which after the loop still points at s02-bravo's worktree, so s01-alpha's review landed in the wrong lane and s01-alpha routed `review / no review`: the test checked a state other than the one it describes
  po-gate: 1 logged oracle change(s) of s168-driver-next-action to judge
- [x] Oracle: `po-gate oracle-intact` → exit 0, with one logged change to judge. In `tests/driver-next-action.oracle.test.sh`, `test_blocked_on_shape_asks_and_never_fixes` gets two `W=` lines so each `review_in` writes into its own lane. Without them the s01-alpha case built a state other than the one it describes. No assertion changes and no criterion is weakened, so the change is accepted. The s164 oracle edit is the one task 7 announces, and it moves the `null` pins only for the fields this story builds.
- [x] Floor: `po-gate floor-guard s168-driver-next-action main` → exit 0, nothing lowered.
- [x] Assertions pin down the criteria. The 54 `case_*` fixtures each build a real git repository with the real `po-gate.sh`, with no mocks, and the expectations compare exact `[action, reason]` pairs. None of the six empty test shapes found.
- [x] Within `Test budget`: 7 oracle + 6 implementer tests = 13 ≤ 25.
- [x] Bite, each mutation run only against `bash tests/run.sh driver-next-action.oracle.test.sh`, with a temporary `CARGO_TARGET_DIR`:
  - L17 disabled (`if false && blocked && …findings-shape`) → 2 failing tests (`blocked_on_shape_asks_and_never_fixes`; `every_routing_case_is_a_fixture` via resuming 16 and verdict 05). Undone; `git diff --exit-code po/src/next/lane.rs` clean.
  - `consumed.is_none()` removed from `holding_decision` → 2 failing tests (`answered_decision_releases_its_lanes`; fixtures via decisions 03). Undone; `git diff --exit-code po/src/next/mod.rs` clean.
  - L20 order reversed (`min_by_key` → `max_by_key`) → 2 failing tests (`ships_stay_serial_in_review_order`; fixtures via ships 01). Undone; `git diff --exit-code po/src/next/lane.rs` clean.
- [x] No test is made useless by the story. The `not-built` assertion for `next` was removed from the s164 oracle, as task 7 says.

## Neighbours
- [x] Other callers read. `po/src/state/mod.rs` calls `lane_next`, `ready` and `held`, and `po/src/main.rs:23` calls `next::main`. Running `po next` on this repository returns `review / no review` for this lane and holds the remaining stories on `dependency`, with no warnings.

## Lenses
Lenses run: none. No auth, migration, lockfile or manifest change. `po` is a local CLI, not server-side code.
- [x] No lens finding.

## Findings
- major — po/src/next/lane.rs:133 — The fix-loop count is wrong when local `main` is behind `origin/main`. The count runs `git log <Target branch>..HEAD` against local `main` only, while `Landed::read` already reads `origin/<Target branch>` (`po/src/context/lanes.rs:57-61`).
  - Under `Merge mode: pr`, landings happen on the forge, and `/po-research` starts a lane from `origin/main` after a fetch. Local `main` can therefore lag behind it.
  - When it lags, every commit landed on origin since local `main` is counted as an implementer commit. L15 then fires with `review / review judged earlier code` instead of `fix`. Each re-review spends a `Max attempts` unit, until the lane ends at `ask / Max attempts reached` without ever having a fix run.
  - Reproduced with a probe repository: `origin/main` two landed commits ahead of local `main`, lane started from `origin/main`, one implementer commit, a current review at `Fix loop: 0` with `Ship allowed: no`. `po next` returned `[{"story":"s01-alpha","action":"review","reason":"review judged earlier code"}]`; `fix / Ship allowed: no` was expected.
  - No fixture covers a remote. Suggested fix: count with `git log HEAD --not <target> origin/<target>` when that ref exists, the way `Landed::read` does, and add a case.
- minor — po/src/next/lane.rs:34 — L3 gives the reason `setting unreadable: QA stage` even when the setting is missing. For the same state the context warns `missing-setting` (`po/src/context/lanes.rs:254`), so the reason and the warning disagree. Wording only; `checks.cases` 01 pins it as written.
- minor — po/src/next/lane.rs:168-173 — The competing ships for L20 include every `stage == Ship` lane, even one that L9 routes to `design` or `ask` (a story with a screen and no `docs/designs/<id>/design.md`). Such a lane can make another lane `wait` while it cannot ship itself. This is unreachable in the normal flow, where design comes before code.

## Not verified
- Row 17 of `## Resuming` (a closed pull request) has no fixture or code path, because it needs `gh` and `po` never runs it. Whoever wires `/po-drive` to `po next` (s173) should keep that row in the prose path or check it by hand.
- The review order rests on the review file's mtime (plan pivot 1). A copy, `touch`, `git checkout` or restore of a review reorders ships. I did not test it beyond the fixtures; to cover it, record two reviews with `po record` in real lanes and compare.
- No fixture reaches L3's `no po-gate` reason or an unreadable (not missing) `QA stage`, and I did not exercise them.
- I did not rerun the full suite. I relied on the record's last `Unit suite` run (exit 0). The record says the first run failed because `tests/readme-onboarding.test.sh` rebuilds `po` from committed HEAD into the shared `CARGO_TARGET_DIR`, so later test files ran an old binary. That suite defect is outside this diff and should be filed in `Issue tracker`.
- The project has no `E2E`, `Build` or `Typecheck` command (all `—`), so none was run.
- `/po-drive` does not read this output yet (s173), so I could not observe the fleet behaving on it. Parity was judged by reading the code against `po-drive.md` and through the fixtures.

Max severity: major
Ship allowed: yes

Method version: 0.2.0

Diff reviewed: `git diff main...story/s168-driver-next-action`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 0ba9e800639b5822c8ce2c0f7c26921d5a54296a

## When blocked
Not blocked.

## Ownership
I listed the diff with `git diff --name-status main...story/s168-driver-next-action` and held each path against the story's `Owns` line.
- [x] Every path is inside `Owns`:
  - `po/src/next/` (`mod.rs`, `lane.rs`, `wave.rs`, `overlap.rs`)
  - `po/src/context/mod.rs`
  - `tests/fixtures/driver-cases/` (7 files)
  - `tests/driver-next-action.oracle.test.sh`, `tests/driver-next-action.test.sh` and `tests/state-as-json.oracle.test.sh`
  - the story's own `docs/research/`, `docs/plans/`, `docs/verif/` and `docs/reviews/` files
- [x] Outside `Owns` → major: none.
- [x] Inside another running story's `Owns` → critical: none. s169 also owns `po/src/context/mod.rs` and `tests/state-as-json.oracle.test.sh`, but `git worktree list` shows only the root and this lane, so s169 is not running.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s168-driver-next-action` → exit 0.
  - The last `Unit suite` run (`bash tests/run.sh`, tree `32f4f5bc…`) exited 0. The project has no type check (`Typecheck: —`); `cargo build --release --locked` in `tests/run.sh` compiles the crate.
  - The record's "Not proven here" says the fix-run suite ran before its commit. Because of issue 254, test files that run after `readme-onboarding.test.sh` may have used a stale binary.
  - So I reran the files the code reaches on a fresh build (`CARGO_TARGET_DIR=/tmp/tmp.M3NLO6GPA3/target`): `driver-next-action.test.sh`, `driver-next-action.oracle.test.sh` and `state-as-json.oracle.test.sh`. Result: 20 passed, 0 failed.
- [x] QA not required: `QA stage: —`.

## Plan
- [x] Tasks 1-9 are present, as the loop-0 review found.
- [x] The fix run (`fdbcb21`) addresses the loop-0 major. In `po/src/next/lane.rs:134-142`, implementer commits are now counted with `git log HEAD --not <target> [refs/remotes/origin/<target>]`. That matches how `Landed::read` reads both refs (`po/src/context/lanes.rs:54-62`).
  - When the target is missing, the count is empty, as it was before the fix. There is no regression.
  - It also leaves L16's `at_tip` count correct.
- [x] Run interdicts hold. The fix run touches only `po/src/next/lane.rs`, `tests/driver-next-action.test.sh` and the record, with no new git verb beyond `log` and `rev-parse --verify`.
- [x] The fix run's second change, in `test_next_on_this_repository_is_fast_and_writes_nothing`, does not weaken the test.
  - When `Target branch` resolves (any developer checkout), the test keeps the full `next_shape` assertion.
  - When it does not resolve (a forge's detached `pull_request` checkout), the test now asserts the `null` shape. That shape is what `## The output of po next` in the plan specifies for an unreadable target.
  - The test still asserts exit 0, the time limit and that nothing is written.

## References
- [x] Opened and confirmed against their definitions:
  - `project::git` (`po/src/project.rs:20`) and `Landed::read` (`po/src/context/lanes.rs:54`)
  - `Context.target` (`po/src/context/mod.rs:99,130`)
  - `Decision.consumed` / `blocks` (`po/src/inbox/decision.rs`) and `inbox consume` (`po/src/inbox/mod.rs:88-91`)
  - `pub use stories::{Stories, Story}` (`po/src/context/mod.rs:17`)
- [x] L2 holds a decision until it is consumed, as plan pivot 2 says. That matches `docs/interface-agent.md:179-181`: an answered decision is consumed by the lead before it resumes the lanes.

## Rules
- [x] `AGENTS.md` conventions are respected: English code and comments, bash tests on `tests/lib.sh`, no new dependency (ADR-0118).
- [x] No accepted ADR is contradicted.

## Tests
- Oracle: `po-gate oracle-intact s168-driver-next-action` → exit 0
  tests/driver-next-action.oracle.test.sh: changed, logged in ## Oracle changes — `test_blocked_on_shape_asks_and_never_fixes`: two lines `W="$F/.worktrees/s01-alpha"` and `W="$F/.worktrees/s02-bravo"` added before its two `review_in` calls; no assertion changes (cksum now `2077968519 16821`) — `review_in` writes into `$W`, which after the loop still points at s02-bravo's worktree, so s01-alpha's review landed in the wrong lane and s01-alpha routed `review / no review`: the test checked a state other than the one it describes
  po-gate: 1 logged oracle change(s) of s168-driver-next-action to judge
- [x] Oracle: `po-gate oracle-intact s168-driver-next-action` → exit 0, with 1 logged change to judge. It is the same `W=` change in `test_blocked_on_shape_asks_and_never_fixes` that the loop-0 review accepted. It fixes which lane the review is written into, changes no assertion and weakens no criterion. Accepted.
- [x] Floor: `po-gate floor-guard s168-driver-next-action main` → exit 0.
- [x] None of the six empty test shapes:
  - The new `test_fix_loop_counts_against_the_origin_target_branch` builds a real repository: `origin/main` is two landed commits ahead of local `main`, the lane is started from `origin/main`, and the test runs the real `po next`.
- [x] Budget: 7 oracle + 7 implementer tests = 14 ≤ 25. The plan's task 8 said "At most 6 tests"; the 7th is a regression test for a review finding (minor, below).
- [x] Bite: each mutation was run only against the files that exercise it, then undone and checked with `git diff --exit-code po/src/next/lane.rs` (clean).
  - Mutation: the origin ref was no longer added to the `--not` list (`args.push(&origin)` neutralised). Result: 1 failing test (`fix_loop_counts_against_the_origin_target_branch`). Undone, clean.
  - Mutation: L15 disabled (`if false && implementer > fix_loop + 1`). Result: 1 failing test (`every_routing_case_is_a_fixture`, via `resuming` case 14). Undone, clean.
  - The loop-0 review's mutations (L17, the `consumed` check in L2, L20 order) touched code the fix run did not change, so I did not repeat them.

## Neighbours
- [x] The other callers are unchanged: `po/src/state/mod.rs` (`lane_next`, `ready`, `held`) and `po/src/main.rs` (`next::main`).
- [x] `state-as-json.oracle.test.sh` passes on the fresh build.

## Lenses
Lenses run: none. There is no auth, migration, lockfile or manifest change, and `po` is a local read-only CLI, not server-side code.
- [x] No lens finding.

## Findings
- minor — po/src/next/lane.rs:34 — L3 gives the reason `setting unreadable: QA stage` even when `QA stage` is missing, while the context warns `missing-setting` for the same state (`po/src/context/lanes.rs:254`). This is wording only; `checks.cases` 01 pins it as written. Carried over from loop 0 and still open.
- minor — po/src/next/lane.rs:176-181 — The lanes that compete for L20 include every `stage == Ship` lane, even one that L9 routes to `design` or `ask` (a story with a screen and no `docs/designs/<id>/design.md`). Such a lane can make another lane `wait` while it cannot ship itself. This cannot happen in the normal flow, where design comes before code. Carried over from loop 0 and still open.
- minor — tests/driver-next-action.test.sh:102 — `test_fix_loop_counts_against_the_origin_target_branch` is a 7th implementer test, while plan task 8 says "At most 6 tests". The total stays within `Test budget`, and it covers the loop-0 major, but the plan was not updated to say so.

## Not verified
- Row 17 of `## Resuming` (a closed pull request) has no fixture or code path, because it needs `gh`, which `po` never runs. Whoever wires `/po-drive` to `po next` (s173) should keep that row in the prose path or check it by hand.
- The ship order rests on the review file's mtime (plan pivot 1). A copy, a `touch` or a checkout reorders ships. I did not exercise this beyond the fixtures. To cover it, record two reviews with `po record` in real lanes and compare.
- No fixture reaches L3's `no po-gate` reason, or a `QA stage` value that is present but unreadable. I did not exercise them.
- I did not replay the forge's `pull_request` checkout, where `test_next_on_this_repository_is_fast_and_writes_nothing` takes its `null` branch. The record says it was checked on a CI-like checkout. To cover it, look at the forge check run on the pull request.
- I did not rerun the full suite myself. I relied on the record's last `Unit suite` run, plus my fresh-build rerun of the three files this code reaches. The stale-binary suite defect is outside this diff (issue 254).
- The project has no `E2E`, `Build` or `Typecheck` command (all `—`), so none was run.
- `/po-drive` does not read this output yet (s173), so I could not watch the fleet behave on it. I judged parity by reading the code against `po-drive.md` and through the fixtures.

Max severity: minor
Ship allowed: yes
