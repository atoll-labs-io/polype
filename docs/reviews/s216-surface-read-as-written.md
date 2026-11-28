# Review — s216-surface-read-as-written

[Story](../stories.md) · [Plan](../plans/s216-surface-read-as-written.md) · [Verification](../verif/s216-surface-read-as-written.md)

Method version: 0.13.0
Recorded: 2026-11-27T10:44:44+01:00

Diff reviewed: `git diff main...story/s216-surface-read-as-written`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: b5fd6fc4106e31a964f334ee29034fa195d5aba0

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-only main...story/s216-surface-read-as-written` and checked each path against the story's `Owns` line using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. `bin/polype`, `po/Cargo.lock`, `po/Cargo.toml`, `po/src/context/framing.rs`, `po/src/context/stories.rs` and `tests/surface-read-as-written.oracle.test.sh` are all listed in `Owns`. `docs/plans/s216-…md` and `docs/verif/s216-…md` are the story's own pipeline evidence, so they are in scope without being listed.
- [x] Nothing outside `Owns`.
- [x] No path inside another running story's `Owns`. The only other worktree is s217 (`.worktrees/s217-plan-says-no-oracle`, not an ancestor of main). Its `Owns` is `method/templates/plan*.md`, `method/agents/planner.md`, `method/hooks/po-gate.sh` and its own tests, so the two do not overlap. s218, s222 and s223 also own `bin/polype`, but none of them has a worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s216-surface-read-as-written` passes (exit 0), so I reused the record. It has status complete and a passing `Unit suite` row (`bash tests/run.sh`, exit 0). The project has no type check (`Typecheck: —`). The record's "Not proven here" section defers E2E and build to ship; this project sets both to `—`.
- [x] `po-gate qa-current` is not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] All four tasks are present and nothing outside the plan was changed.
  - Task 1: `stories.rs:150` uses `trim_matches('`')`.
  - Task 2: `no_story_has_a_screen(screen_platform)` takes the new parameter, its doc comment is updated, and `framing.rs` computes the value from `Platform`. A missing `Platform` gives true.
  - Task 3: the version is 0.13.1 in all three places.
  - Task 4: the full suite ran through `po-run`.
- [x] I checked each run interdict:
  - `method/` has an empty diff.
  - The `PO_SUMS` block of `bin/polype` is unchanged; only `POLYPE_VERSION` moved.
  - `says_screen` and `has_screen` keep their bodies, and no "the text shows a screen" fallback was added.
  - `goes_to_qa`'s signature and the JSON shapes are unchanged.
  - No existing test file changed, no new crate was added and `tests/fixtures/driver-cases/` is unchanged.
  - No empty `tests/surface-read-as-written.test.sh` was created.

## References
- [x] Every reference was confirmed:
  - `Settings::optional` (`po/src/context/mod.rs:75`) returns `Option<String>`.
  - `Story::has_screen` and `says_screen` behave as described.
  - `no_story_has_a_screen` has one caller, `framing.rs:92`, and it was updated.
  - The Cargo.lock entry changes only the `po` package version.
- [x] Values that might only look right:
  - `web` and `mobile` as the screen platforms match the template's row 57 of `method/templates/agents-local.md` and the plan's citation of ADR-0055.
  - A missing `Platform` reads as the template default `web`, so the old rule stays in force for projects without that line.

## Rules
- [x] The `AGENTS.md` conventions are respected: bash oracle, English code and comments, and the version raised as ADR-0122 requires.
- [x] No accepted ADR is contradicted.

## Tests
- Oracle: `po-gate oracle-intact s216-surface-read-as-written` → exit 0
- [x] Floor: `po-gate floor-guard s216-surface-read-as-written main` exits 0, so nothing was lowered. `po-gate oracle-intact` also exits 0, and the record says no oracle changed.
- [x] The assertions pin the acceptance criteria, and none of the six empty test shapes appears.
  - The tests drive the real `po` binary on real git fixtures built by the driver oracle's helpers.
  - The QA-stage-missing case catches the former `ask`.
  - `track_is` checks that both the research-stage and the ready backticked-`—` stories plan on the `flow` track, not `design` and not full.
- [x] 3 tests, within the `Test budget` of 25.
- [x] Bite tests, each followed by `git checkout -- <file>` and a clean `git diff --exit-code`:
  - I reverted `stories.rs:150` to `value(line).trim().to_lowercase()`: 1 failing test (`backticked_dash_is_no_surface`).
  - I forced `no_story_has_a_screen(true)` in `framing.rs`: 1 failing test (`no_screen_needs_no_design_system`). The neighbouring `state-carries-session-lines` and `state-as-json` tests stayed green.
  - I dropped `!story.has_screen()` from `no_story_has_a_screen`: 1 failing test (`no_screen_needs_no_design_system`).
- [x] The story made no test useless.

## Neighbours
- [x] Callers of the changed code read; nothing is broken.
  - `goes_to_qa` (`lanes.rs:300`) compares against a bare `—`, which the stripped value now matches.
  - `has_screen` is unaffected.
  - Nothing in `method/hooks` or `bin` reads `Surface` themselves.
  - I built the new binary into a temp target. `po state` on this repository (`Platform: cli`) now reports `design-system: not needed`.

## Lenses
Lenses run: dependencies, triggered by `po/Cargo.lock` and `po/Cargo.toml`. Only the `po` package's own version changed; no dependency was added, removed or bumped.
- [x] The lens found nothing.

## Findings
none

## Not verified
- **Lagon.** I did not run `po next` or `po state` on Lagon itself, the other repository the story names, because it is outside this review's scope. A person should run `po state` and `po next` there after install and confirm that backticked-`—` stories no longer route to QA.
- **Polype's own `po next` routing.** I did not check it. Only `po state`'s design-system line was checked on this repository, against a binary built into `/tmp/tmp.VqGiZBoa3g/target`.
- **Surface values with extra text.** A `Surface` value with text after the backticked dash (for example `` `—` (note) ``) is still read as a surface. No criterion covers it and I did not judge it as a defect.
- **E2E and build.** The project has neither (`E2E: —`, `Build: —`).
- **Hook refusal.** `po-bounds` refused `git branch --list` in reviewer mode. I judged "running stories" from `git worktree list` and `merge-base --is-ancestor` alone, so a story branch without a worktree was not inspected.

Max severity: none
Ship allowed: yes
