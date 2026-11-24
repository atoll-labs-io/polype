# Review — s211-next-gives-lane-commands

[Story](../stories.md) · [Plan](../plans/s211-next-gives-lane-commands.md) · [Verification](../verif/s211-next-gives-lane-commands.md)

Method version: 0.11.0
Recorded: 2026-11-24T17:11:20+01:00

Diff reviewed: `git diff main...story/s211-next-gives-lane-commands`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 726b2d6280711b6fad715290a15ffd7ebb3fe5dc

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-only main...story/s211-next-gives-lane-commands` and checked each path against the story's `Owns` (the line on the branch's `docs/stories.md`, which was fast-forwarded onto c5c654f).
- [x] Every path is inside `Owns`:
  - `po/**`, `bin/polype`, `method/commands/po-drive.md`, `method/commands/po-research.md`, `docs/interface-agent.md`, `docs/evals/real-2026-11-24-v0.12.0-2.md`, the two story test files and `tests/journey/stops.sh` are all covered.
  - `docs/plans/`, `docs/research/` and `docs/verif/` for this id are the story's own evidence.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`: `git worktree list` shows only the main checkout and this lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s211-next-gives-lane-commands` exited 0, so I reused the record:
  - Unit suite `bash tests/run.sh` exited 0 on tree a8a0104…, which matches `Tree:` outside `docs/`.
  - The project has no type check, end-to-end test or build (`Typecheck: —`, `E2E: —`, `Build: —`).
  - I read the record's "Not proven here" section; its items are carried below.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–8 are all present.
  - Version 0.13.0 appears in all three places.
  - `po/src/next/open.rs`, `po/src/help.rs` and the contract row are added; the `## La commande` rule is in `docs/interface-agent.md`.
  - The method edits are in place; the record is copied; `stop_env_file_not_ignored` is added; the suite ran through `po-run`.
- [x] Run interdicts, one by one:
  - Empty diff on `.claude/`, `.polype/`, `evals/`, `AGENTS.md`, `method/agents/`, `tests/journey/journey.sh|project/|answers/` and the s206 oracle: holds.
  - `tests/journey/stops.sh` only gains lines: holds.
  - `docs/stories.md` has no diff against main: holds.
  - The oracle sum is still `1147489417 6395`: holds.
  - `method/word-budget` is untouched. Word counts went down: po-drive 2266→2262, po-research 509→436.
  - `po` runs no fetch, worktree add, copy or install itself: in `open.rs` these appear only as strings, and its only git calls are reads through `project.git`.
  - The record sums to `589271514 851`, matching the plan.
  - `contract` stays 1, and no existing field changed name or meaning.
  - One deviation in task 7 is listed under Findings.

## References
- [x] Every reference I opened matches its target:
  - `Project::git` returns `Option<String>` and gives `None` on a non-zero exit, so the `rev-parse --verify -q` branch test is correct.
  - `Project::setting` and `Settings::usable` read settings the same way, and `—` is treated as unusable for `Worktree root`.
  - `StartPoint.reference`, the new `lane_prefix` (extracted from `lanes.rs`, and still used by `lanes()`), and `lane::act` made `pub(super)` all check out.
  - `record::USAGE` and `ship::USAGE` are now `pub(crate)`. `output::reply` adds `contract: 1`.
  - `NewDecision` / `Motive::Stop`, kebab-case and `deny_unknown_fields`, accept the `input` sample. The oracle checks this round trip.
- [x] Values: the safe-byte set `[A-Za-z0-9_@%+=:,./-]` and the `'\''` escape are standard POSIX quoting, and the test with a space and an apostrophe in the path exercises them. One timing gap in the start point is listed under Findings.

## Rules
- [x] `AGENTS.md` conventions are respected: comments are in English and sparse, and the method files are in English.
- [x] No accepted ADR is contradicted:
  - ADR-0122: the version is raised.
  - ADR-0138: the git commands start with `git -C <root>`.
  - The owner's choice, recorded in the story, that `po` gives the commands is followed.

## Tests
- Oracle: `po-gate oracle-intact s211-next-gives-lane-commands` → exit 0
- [x] Floor: `po-gate floor-guard s211-next-gives-lane-commands main` → 0, nothing lowered. `po-gate oracle-intact` → 0.
- [x] The assertions pin the criteria, and I found none of the six empty test shapes:
  - Both the oracle and the task tests actually run the returned commands from `/` against real repositories, including a real bare origin.
  - They check the lane's HEAD, the branch, the `.env*` copies and where Install ran.
  - The help test takes a filesystem snapshot to prove nothing is written, and uses a fake `claude` to prove no session is launched.
- [x] Within `Test budget`: 7 tests out of 25.
- [x] Bite: three mutations of `po/src/next/open.rs`, each undone and confirmed with `git diff --exit-code po/src/next/open.rs`:
  - Env-not-ignored guard disabled (`if false && …`) → 1 failing test (`unignored_env_asks`).
  - Existing-branch check disabled → 1 failing test (`existing_branch_is_checked_out`).
  - Shell quoting disabled (always bare) → 1 failing test (`paths_with_a_space_run`).
- [x] No test made useless by the story. Two tests need no change and still hold: `test_every_ask_reason_is_reached` (which now also reaches the new ask) and `test_reason_reader_reads_every_ask`. Both were green in the recorded suite run.

## Neighbours
- [x] I read the callers of the changed code and found nothing broken:
  - `Entry::of` and the new `Entry::ready` are the only builders.
  - `po state` does not use `Entry`.
  - `lanes()` uses the same extracted prefix, so a lane the commands open is read back. The oracle and the space test both check that it comes back as `no research`.
  - `help::main` returns `None` for `po --help` and for unknown verbs, so their existing errors are kept.
  - In the method docs, no reference to the removed `/po-research` steps remains outside `docs/stories.md`'s historical criteria.

## Lenses
Lenses run: dependencies — triggered by `po/Cargo.lock` and `po/Cargo.toml`; the only change is po's own version, 0.12.0 → 0.13.0, with no dependency entry added, removed or bumped.
- [x] The lens found nothing to grade.

## Findings
- minor — tests/journey/stops.sh:156 — The journey departs from plan task 7, and the plan does not record it: the plan said the throwaway project has no `.gitignore` and `.env` is merely left untracked; the function instead appends `!.env` to `$R/.gitignore`, with a comment saying the installer ignores `.env*`. The result is right (the journey reaches the ask, only lines were added), but the plan's premise was wrong and nothing records the correction.
- minor — po/src/next/open.rs:29 — The start point is read before the fetch command the lead runs: `StartPoint::read` picks `origin/<target>` only when that ref already exists locally, so when `origin` exists but `origin/<target>` was never fetched, `po next` gives `git fetch origin` followed by `worktree add … <target>`, and the lane opens from the local target, where the old `/po-research` rule started from `origin/<target>` after the fetch. A rare edge: a remote added but never fetched.
- minor — method/commands/po-drive.md:50 — The method contradicts itself about `cd`: line 50 tells the lead "no `cd`, at any stage of a wave", while the new `### Opening the lanes` tells it to run each given command exactly as given, which includes `(cd <lane> && <Install>)`. The subshell never moves the lead's shell, so the behaviour is right, but a literal reader meets two rules that disagree. Also, `po-drive.md` says nothing about a `commands: null` entry other than the missing-`Install` stop in `## Checks`; `po-research.md` names it, `po-drive.md` does not.

## Not verified
- I did not see a real run under Claude Code's sandbox. Two things remain unproven:
  - Whether a lead runs `commands` one per call as given, instead of joining or looping them as the fourth run did. `drive_runs_them_as_given` is model-read; I judged its prose sound by reading.
  - Whether `(cd <lane> && <Install>)` passes without a permission prompt.
  - A person should check both on the next `po-eval` real run (control-arm candidate, #208).
- An `Install` value that itself calls git would produce a git command that does not start with `git -C <root>`, and it would stay inside the sandbox. No test or real project shows this. A person should check the `Install` value of each project before relying on the commands under the sandbox.
- I checked `docs/evals/real-2026-11-24-v0.12.0-2.md` only by its checksum (`589271514 851`, which matches the plan). I could not compare it with the run's original output: I did not open `/tmp/po-eval-results.S0Td4j/` or the lead's copy.
- I did not rerun the full unit suite, the journey oracle or `bin/po-lint`. I relied on the record's passing `po-run` row on this code. The version check (`bin/po-version-check`) runs only in CI, and I did not run it.
- There is no type check, end-to-end test or build: the project has none.

Max severity: minor
Ship allowed: yes
