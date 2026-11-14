# Review — s176-state-carries-session-lines

[Story](../stories.md) · [Plan](../plans/s176-state-carries-session-lines.md) · [Verification](../verif/s176-state-carries-session-lines.md)

Method version: 0.2.0

Diff reviewed: `git diff main...story/s176-state-carries-session-lines`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: bd5977283a59af2ae85be43eaa04cb20ef819339

## When blocked
- Failure cause: n/a
- Missing: n/a
- Required adaptation: n/a
- Next action: n/a

## Ownership
Diff listed with `git diff --name-only main...story/s176-state-carries-session-lines`. Each path was checked against the story's `Owns` (`po/src/context/`, `po/src/state/`, `docs/interface-agent.md`, `tests/state-carries-session-lines.oracle.test.sh`, `tests/state-carries-session-lines.test.sh`, `tests/state-as-json.oracle.test.sh`, `tests/state-as-json.test.sh`, `tests/verbs-read-project-context.oracle.test.sh`).
- [x] Every path is inside `Owns`. These fall under `Owns` folder entries: `po/src/context/{framing,lanes,mod}.rs` and `po/src/state/mod.rs`. These match `Owns` entries exactly: `docs/interface-agent.md`, `tests/state-carries-session-lines.oracle.test.sh` and `tests/verbs-read-project-context.oracle.test.sh`. The story's own evidence files `docs/research/`, `docs/plans/` and `docs/verif/` are in scope by construction.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. The only other worktree is `story/s172-commands-read-po-state`, which is already an ancestor of `main` (`merge-base --is-ancestor` exit 0). Its `Owns` does not cover any path in this diff.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s176-state-carries-session-lines` exited 0, so the record was reused. Verification mode is `record`. The last `Unit suite` row ran `bash tests/run.sh` and exited 0 on code equal to `Tree:` outside `docs/`. The project has no type check (`Typecheck: —`), and `tests/run.sh` builds `po` with `cargo build --release --locked` first. I read the record's "Not proven here" section: the two earlier failing rows came from a shared `CARGO_TARGET_DIR` running `main`'s `po`, and the passing row ran after the commit.
- [x] `po-gate qa-current`: not required. `QA stage` is `—`, so the story does not go to QA.

## Plan
- [x] All six tasks are present: framing items (task 1), `Stop` enum and `stops()` (2), the state `Lane` gaining `path` and `stops` (3), the s174 normalisation in `del(... .framing.items?)` and `del(.next, .path, .stops)` with its comment (4), the contract doc (5), and the suite run through `po-run` (6). I found nothing outside the plan.
- [x] Each run interdict, checked one by one with an empty `git diff --stat`:
  - `method/hooks/po-session.sh` is unchanged.
  - `po/src/next/`, `po/src/run/` and `po/src/trust/` are unchanged, and the diff does not touch `inbox` or `record` either.
  - `po/Cargo.toml` and `po/Cargo.lock` are unchanged.
  - `tests/project-lead.test.sh`, `tests/state-as-json.test.sh` and `tests/state-as-json.oracle.test.sh` are unchanged.
  - In `verbs-read-project-context.oracle.test.sh`, only `normalised` and its comment moved.
  - The oracle checksum is intact (`oracle-intact` exit 0).
  - `BlockedBy` keeps its five variants.
  - No field was removed or renamed, and `contract` stays `1`.
  - `tests/state-carries-session-lines.test.sh` was not created.

## References
- [x] Every reference was opened and confirmed:
  - `shown()` at `po/src/context/lanes.rs:146` and `count() -> Option<u64>` at `:299`, so `fix_loop` and `max_attempts` are `u64`.
  - `frontmatter_status`, `no_story_has_a_screen` and `project.root`, which is canonicalized at `po/src/project.rs:41`, as is the worktree path.
  - The `Stop` re-export in `context/mod.rs` and its use in `state/mod.rs`.
  - The only `context::Lane` constructor is `lanes.rs:226`.
- [x] No value only looks right. I compared `stops()` with `po-session.sh:213-238` rule by rule: same five conditions, same order, same file paths, and the same `/po-plan <id>` and `story/<id>` strings. Before the change, `blocked_by()` returned on the first matching rule. Now `blocked_by` is `stops.first().map(Stop::code)`, which gives the same code in the same order. I also checked the framing items against `po-session.sh:78-94`: scope gives `by hand` / `missing` / `approved` / `in progress`, the review gives `none` / `yes` / `no`, and the design system gives `present`, then `not needed` only when stories are present and none has a screen, else `missing`. The stage chain is unchanged because `design_system` is still "present or not needed".

## Rules
- [x] `AGENTS.md` conventions are respected. Code and comments are in English, the doc is in French, and nothing was added to `method/`.
- [x] No accepted ADR is contradicted. There is no new dependency (ADR-0118), and the change only adds fields under contract 1 (ADR-0107).

## Tests
- Oracle: `po-gate oracle-intact s176-state-carries-session-lines` → exit 0
- [x] Floor: `po-gate floor-guard s176-state-carries-session-lines main` exited 0, so nothing was lowered.
- [x] The assertions pin the acceptance criteria. Each test runs the real `po` binary on scratch git repositories, with no mocks. The `session_cases_read_the_same` test runs the real hook as its reference. None of the six empty-test shapes applies.
- [x] There are four new tests, within `Test budget` (25).
- [x] Bite 1: I added `stops.truncate(1)` before `stops()` returns, keeping only the first stop. 1 test failed (`every_stop_of_a_lane_is_listed`). I undid it with `git checkout -- po/src/context/lanes.rs`, and `git diff --exit-code` was clean.
- [x] Bite 2: I made the design-system item report `present` where it should say `not needed`, leaving the stage untouched. 1 test failed (`framing_items_are_listed`). I undid it with `git checkout -- po/src/context/framing.rs`, `git diff --exit-code` was clean, and I rebuilt `po` from the committed code.
- [x] Neighbour tests on the committed code: `state-carries-session-lines.oracle` (4), `verbs-read-project-context.oracle` (2) and `state-as-json` (4) all pass, 10 passed and 0 failed.
- [x] No test became useless. The s174 oracle keeps its recorded objects, and only its normalisation drops the new fields.

## Neighbours
- [x] I read the other callers of `blocked_by`: `po/src/next/lane.rs:41,73,172,179` and `po/src/next/wave.rs:20,23`. They read the same first-stop code as before. `framing.next` and `stage` are unchanged, and the s174 oracle confirms it.

## Lenses
Lenses run: none. The diff touches no auth, route or upload path, no migration, and no lockfile or manifest (`po/Cargo.*` is unchanged). The changed Rust is a CLI reading local files, not server-side code.
- [x] There were no lens findings.

## Findings
- none

## Not verified
- **Criterion `contract_says_the_new_fields`.** I judged it by reading only, since no script reads `docs/interface-agent.md`. The doc describes `framing.items` with its order and words, `lanes[].path`, `lanes[].stops` per code, and `blocked_by` as the first stop's code. It no longer says the rules are `po-session`'s, keeps `contract` at `1`, and drops no field. A person can re-read `docs/interface-agent.md:41-100` against the plan's field table if they want a second opinion.
- **Leading zeros in `Fix loop:` or `Max attempts`.** The hook prints the raw text (`02`), while `po state` gives the integer `2`. No fixture covers this; the research's Traps section and the record name it. s172, which makes the hook print from `po state`, should decide whether this matters.
- **`po state` run from a nested directory of a lane other than its root.** It is covered only from the lane root and the project root.
- **Unit suite and full build.** I did not rerun them and relied on the record (Verification mode `record`). I ran only the three focused files above.
- **Suite isolation defect, outside this diff.** `tests/readme-onboarding.test.sh` builds `main`'s `po` into the suite's shared `CARGO_TARGET_DIR`, so later tests ran a stale binary (record, "Not proven here"). This is not a finding on this diff; the lead should file it in `Issue tracker` (Law 7).
- **End to end, production build and type check.** The project has none (`E2E: —`, `Build: —`, `Typecheck: —`).

Relevant files:
- /home/lecrabe/dev/atoll/polype/.worktrees/s176-state-carries-session-lines/po/src/context/lanes.rs
- /home/lecrabe/dev/atoll/polype/.worktrees/s176-state-carries-session-lines/po/src/context/framing.rs
- /home/lecrabe/dev/atoll/polype/.worktrees/s176-state-carries-session-lines/po/src/state/mod.rs
- /home/lecrabe/dev/atoll/polype/.worktrees/s176-state-carries-session-lines/docs/interface-agent.md
- /home/lecrabe/dev/atoll/polype/.worktrees/s176-state-carries-session-lines/tests/state-carries-session-lines.oracle.test.sh

Max severity: none
Ship allowed: yes
