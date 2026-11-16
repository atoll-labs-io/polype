# Review — s185-ship-order-and-closed-pr

[Story](../stories.md) · [Plan](../plans/s185-ship-order-and-closed-pr.md) · [Verification](../verif/s185-ship-order-and-closed-pr.md)

Method version: 0.3.1

Diff reviewed: `git diff main...story/s185-ship-order-and-closed-pr`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: dd77f78f31ce1f49ff6f2a8b5de344699c15d63f

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s185-ship-order-and-closed-pr`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. All 13 code and test paths match an `Owns` entry: `po/src/next/`, `po/src/record/`, `po/src/trust/`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `method/templates/review.md`, `method/commands/po-drive.md`, `docs/interface-agent.md`, `tests/fixtures/driver-cases/ships.cases` and three `tests/` entries. The research, plan and verification files are the story's own pipeline evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. The only other worktree is `.claude/worktrees/framing-m22` on `fix/qa-deadline-wording`, which is not a story lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s185-ship-order-and-closed-pr` → exit 0, so the record is reused. The verification file is marked complete. The `Unit suite` (`bash tests/run.sh`) has one run that exited 0. `Typecheck: —`, so the project has no type-check command; the record names `cargo build --release --locked` inside `tests/run.sh` as the compile check. Its "Not proven here" section is carried to `## Not verified`.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Each task is present: dated block, ship order, pull-request state, `--remote`, prose and contract, version. Nothing was found outside the plan.
- [x] Run interdicts, checked one by one:
  - The diff is empty for `method/hooks/po-gate.sh`, `po/src/state/`, `po/src/context/`, `po/src/inbox/`, `po/src/run/`, `method/templates/qa.md`, `method/commands/po-execute.md`, `.polype/` and `.claude/`.
  - Among the driver-case fixtures only `ships.cases` changed, and `tests/driver-next-action.oracle.test.sh` did not change.
  - Without `--remote`, no `gh` is called: `closed_pull_requests` runs only when `remote` is set, and the test checks that the double's log is empty.
  - No test reaches the network: every forge answer comes from a `PO_GH` double.
  - There is no new crate, and no new field or warning code.
  - A lane waiting on a dependency is filtered out before the forge is asked.

## References
- [x] Every import, call and key was confirmed:
  - `Forge::of`, `gh_program` and the `gh_api` refactor (behaviour identical to the old `checks` body).
  - `chrono::Local::now().to_rfc3339_opts` and `DateTime::parse_from_rfc3339`; the crate already depends on `chrono`.
  - `holding_decision` and `waiting_dependency` in `po/src/next/mod.rs`.
  - `lane_next`, still called by `po/src/state/mod.rs:76` with an empty `closed` list.
- [x] No value that only looks right:
  - The `pulls?head=<owner>:<branch>&state=all` path and the `state`/`merged_at` fields match the GitHub REST pulls list.
  - The "newest by `number` decides" rule is argued in the plan's pivot.
  - Mixing a written date with a file's modification time compares two instants since the epoch.

## Rules
- [x] `AGENTS.md` conventions are respected. The `po-drive.md` word count went from 2481 to 2453, and the ceiling in `tests/ship-files-the-other-findings.oracle.test.sh` was lowered from 2483 to 2481, which is the one case the story allows.
- [x] No accepted ADR is contradicted. The forge is still read through `gh api --hostname github.com` (ADR-0083). `/po-execute` keeps `po next` without the option (ADR-0120).

## Tests
- Oracle: `po-gate oracle-intact s185-ship-order-and-closed-pr` → exit 0
- [x] Floor: `po-gate floor-guard s185-ship-order-and-closed-pr main` → exit 0, nothing lowered. `po-gate oracle-intact` → exit 0.
- [x] The assertions pin the acceptance criteria, and none of the six empty test shapes is present:
  - Fixtures 05 and 06 set file modification times against the written date. In case 05 the offsets invert a plain text comparison.
  - The `gh` double has its call log checked.
  - The failing-forge test checks that the double was actually called.
- [x] Within `Test budget`: 9 tests out of 25.
- [x] Bite 1, `ship()` closed-lane guard (`lane.rs:177`) disabled → 1 failing test (`closed_pr_goes_to_a_human`). Undone, and `git diff --exit-code` is clean.
- [x] Bite 2, the written date ignored in `reviewed_at` (`.and_then(|text| recorded(&text))` forced to `None`) → 2 failing tests (`ships_follow_the_written_date`, `older_reviews_fall_back`). Undone, `git diff --exit-code` is clean, and the tree hash is unchanged.
- [x] No tests were made useless. `test_next_refuses_an_option` is unchanged and still holds for any argument other than `--remote`.

## Neighbours
- [x] Callers read:
  - `po/src/state/mod.rs:76` (`lane_next`, which never asks the forge, as `docs/interface-agent.md` now says).
  - `record/mod.rs:242,246`, the only callers of `append` and `first_write`.
  - `trust/signals.rs:25`, which reads after the last `Method version:` line and ignores `Recorded:`; the oracle shows the trust values unchanged.
  - The `po-gate` readers, whose `ship-allowed` and `findings-shape` exit 0 on a dated review in the oracle.

## Lenses
Lenses run:
- Security: `po/src/trust/forge.rs` builds an outbound `gh api` path from lane ids. The host is pinned to github.com, `gh` is run without a shell and no token is read. Nothing found.
- Dependencies: `po/Cargo.toml` and `po/Cargo.lock` changed. Only the `po` package's own version moved, and no dependency entry changed. Nothing found.
- [x] Each lens finding is graded and listed under Findings (none).

## Findings
- major — po/src/next/mod.rs:111 — `closed_pull_requests` adds its own `landed` closure, re-implementing `landed()` at `po/src/next/lane.rs:17`, a private one-liner in the sibling module. The skill grades new code that duplicates a citable helper as major. Expose `landed` as `pub(super)` and call it instead. The damage is contained: the two copies are identical today, but they can drift apart.
- minor — po/src/next/mod.rs:76 — `stories_read(&context).then(|| lane::next(...))?` re-checks a condition the enclosing `.filter(|_| stories_read(&context))` already holds. The re-check is redundant and the closure can call `lane::next` directly.
- minor — method/commands/po-drive.md:29 — The command now reads `po next --remote`, but the next sentence still says "Run `po next` again once a stage's answers are recorded". A model may take that literally and run the later passes without the option. A closed pull request would then reach a person only on the first pass of a wave, although the rule this story removed applied on every pass. This is a wording point, to be fixed outside a story.
- minor — po/src/next/lane.rs:220 — `recorded()` reads the line under the last `Method version:` line. A multi-block review recorded onto itself, a case the oracle exercises, keeps the old inner blocks in the new block's body. The last stamp is then the older, copied one, and the ship is ordered by that older date. This was derived from reading `strip_own_header` and `append` and was not run. The effect is limited to ship order, in a case that is unusual in practice.

## Not verified
- `po next --remote` against the real GitHub API. Every forge answer here comes from a `PO_GH` double, so the response shape of `GET repos/{owner}/{repo}/pulls?head=<owner>:story/<id>&state=all` is taken from the research, not observed. GitHub's acceptance of an unencoded `/` in `head` is not observed either. To cover it, a person should run `po next --remote` on a real repository that has a pull request closed without merging, and look for `ask pull request closed`.
- `drive_no_longer_decides_it` is a model-read rule and was judged here by reading only. The closed-pull-request sentence is gone and the word count is lower. Whether a live `/po-drive` actually passes `--remote` on every pass was never seen (see the minor finding on `po-drive.md:29`). It is a candidate for a `po-eval` control arm (#208).
- The full unit suite was not rerun. It was taken from the record (`Verification mode: record`). Only the two s185 test files were run, for the bite proof.
- Formatting and lint: the project configures none.
- Clock skew between machines when written dates are mixed with modification times (plan pivot) was not exercised.

Max severity: major
Ship allowed: yes

Method version: 0.3.1

Diff reviewed: `git diff main...story/s185-ship-order-and-closed-pr`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 05f4aa3aeca1bca88beef7f82b9a19d76392e698

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-status main...story/s185-ship-order-and-closed-pr` and checked each path against the story's `Owns` line in `docs/stories.md:2993`.
- [x] Every path is inside `Owns`. The fix commit 4f099c1 touches only these: `docs/interface-agent.md`, `method/commands/po-drive.md`, `po/src/next/lane.rs`, `po/src/next/mod.rs`, `tests/ship-order-and-closed-pr.test.sh`, plus the story's own review and verification files. Every one of them is an `Owns` entry or the story's own pipeline evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows only `main`, this lane and `.claude/worktrees/framing-m22` on `fix/qa-deadline-wording`, which is not a story lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s185-ship-order-and-closed-pr` gave exit 0, so I reused the record and did not rerun the suite.
  - The record is marked complete.
  - Its last `Unit suite` run (`bash tests/run.sh`) exited 0 on tree b3479dd. `git diff --quiet b3479dd HEAD -- . ':(exclude)docs'` is clean.
  - `Typecheck: —`: the project has no type-check command. `cargo build --release --locked` inside `tests/run.sh` is the compile check, and the record says so.
  - Its "Not proven here" section is carried to `## Not verified`.
- [x] `po-gate qa-current` is not required: with `QA stage: —`, the story does not go to QA.

## Plan
- [x] The fix run answers each finding of loop 0, and I found nothing else changed:
  - `landed` is now `pub(super)` at `po/src/next/lane.rs:17`, and `closed_pull_requests` calls it at `po/src/next/mod.rs:116`.
  - The redundant `stories_read` check is gone. `filter_map` became `map`, and the behaviour is the same because the outer `.filter(|_| stories_read(&context))` still guards it.
  - The sentence at `po-drive.md:29` now says "Run it again", which refers to the `--remote` command. The file went from 2453 to 2452 words, under the 2481 ceiling.
  - `recorded()` changed as described below.
- [x] Departure from the plan: plan line 11 and task 2 say "the last such line", but the code now takes the newest valid stamp. The loop-0 finding asked for this change, the commit message names it, and `docs/interface-agent.md:266` now says "la ligne `Recorded:` la plus récente". The plan text was not updated. That is acceptable because the review records the change; it is not a finding.
- [x] I checked the reason for the newest-stamp rule against the code, and it holds:
  - `compose::strip_own_header` (`po/src/record/compose.rs:57-73`) strips only the leading header of the answer.
  - When a multi-block review is recorded onto itself, `append` writes the new stamp first, then a body that still holds the older blocks with their stamps.
  - So a file recorded at 07:00 and 08:00, then recorded onto itself at 11:00, reads 07, 08, 11, 08. The last stamp is an old copied one, and the newest stamp is the latest write. The test fixture has exactly this shape.
- [x] I judged the side effect the implementer names: a review whose last block has no stamp but an earlier block has one is now ordered by that earlier stamp, not by the file's modification time. See the minor finding. It can only happen in two ways: an older `po` (before 0.5.0) appends a block, or the file is written by hand, which `/po-review` forbids ("Write nothing by hand"). Its only effect is the order of ships among lanes that already passed review. No gate opens because of it.

## References
- [x] `chrono::DateTime::parse_from_rfc3339` and `Iterator::max` on `(i64, u32)` are standard, and `windows(2)` is standard slice behaviour.
- [x] `lane::landed` exists and is reachable from `next/mod.rs` (`pub(super)`, same parent module).
- [x] No value only looks right: the stamp's precision stays seconds with nanoseconds 0, as in loop 0.

## Rules
- [x] The `AGENTS.md` conventions hold: commit message in English with no trailer, and the `po-drive.md` word ceiling holds.
- [x] No accepted ADR is contradicted. The fix does not touch the forge reading (ADR-0083) or `/po-execute` (ADR-0120).

## Tests
- Oracle: `po-gate oracle-intact s185-ship-order-and-closed-pr` → exit 0
- Oracle: `po-gate oracle-intact s185-ship-order-and-closed-pr` → exit 0
- [x] Floor: `po-gate floor-guard s185-ship-order-and-closed-pr main` → exit 0, nothing lowered.
- [x] `test_rerecorded_review_ships_by_its_newest_date` holds none of the six shapes of a test that proves nothing:
  - It drives the real `po next` binary.
  - Its fixture reproduces the layout `append` actually writes (stamps 07, 08, 11, 08).
  - It sets s02 at 10:00, between the last stamp and the newest one, so the two rules give opposite orders.
- [x] Within `Test budget`: 10 tests out of 25 (9 plus the new one).
- [x] Bite: at `po/src/next/lane.rs:231`, I changed `.max()` to `.last()` (the old "last stamp" rule) and ran only the two s185 test files.
  - Before the change: 8 passed.
  - With the mutation: 1 failing test, `rerecorded_review_ships_by_its_newest_date`, and the 7 others passed.
  - I undid it with `git checkout -- po/src/next/lane.rs`. `git diff --exit-code po/src/next/lane.rs` is clean, and the tree hash is unchanged (05f4aa3a…).
- [x] Loop 0's bites on the closed-lane guard and on the written date still apply: the fix leaves that code unchanged.

## Neighbours
- [x] `recorded()` has one caller, `reviewed_at` at `lane.rs:211`.
- [x] `landed` has two callers, `lane.rs` itself and `next/mod.rs:116`.
- [x] `po/src/state/mod.rs:76` (`lane_next`) is not touched by the fix.

## Lenses
Lenses run: none. The fix commit touches no security path or content (the forge code is unchanged since loop 0), no lockfile or manifest, and no migration.
- [x] Each lens finding is graded and listed under Findings (none).

## Findings
- minor — po/src/next/lane.rs:222 — `recorded()` now takes the newest `Method version:`/`Recorded:` pair anywhere in the file, where loop 0 took only the pair under the last anchor. So any stamp later than the real one decides the order. That covers a quoted pair at the start of a line in a reviewer's body (a fenced block), and a block from a machine whose clock runs ahead. A review whose last block has no stamp (written by a `po` older than 0.5.0) is ordered by an earlier stamp rather than by its modification time, so it ships ahead of its turn. The only effect is ship order among lanes already allowed to ship, and no gate opens. One fix: keep the newest stamp only when the last block carries one, and otherwise fall back to the modification time.

## Not verified
- `po next --remote` against the real GitHub API (carried from the record's "Not proven here"). Every forge answer comes from a `PO_GH` double, so the response shape of `GET repos/{owner}/{repo}/pulls?head=<owner>:story/<id>&state=all` was not observed. To cover it, a person should run `po next --remote` on a real repository that has a pull request closed without a merge, and look for `ask pull request closed`.
- `drive_no_longer_decides_it` is a model-read rule, and I judged it by reading only. The wording now says "Run it again", which refers to the `--remote` command. Whether a live `/po-drive` passes `--remote` on every pass has never been seen. It is a candidate for a `po-eval` control arm (#208).
- Re-recording onto itself with the real `po record review`: I derived the file layout from `compose.rs` and did not regenerate it with the binary for this loop. The oracle's `record_dates_each_verdict` covers the one-stamp-per-block clause.
- I did not rerun the full unit suite: I took it from the record (`Verification mode: record`). I ran only the two s185 test files, for the bite.
- Formatting and lint: the project configures none.
- Clock skew between machines when written dates are mixed with modification times was not exercised.

Max severity: minor
Ship allowed: yes
