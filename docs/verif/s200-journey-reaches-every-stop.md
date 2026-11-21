# Verification — s200-journey-reaches-every-stop

[Story](../stories.md) · [Plan](../plans/s200-journey-reaches-every-stop.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: d7963707d1a7d5253e2ba624797c6d6ff28dc73a

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such stage in this project |
| Build | — | no such stage in this project |

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

## Not proven here
- **Duration (Task 10).** `bash tests/run.sh journey-reaches-every-stop.oracle.test.sh journey-reaches-every-stop.test.sh journey-runs-to-a-landed-commit.oracle.test.sh journey-runs-to-a-landed-commit.test.sh` took 27.9 s wall clock (s199's two files alone: 9.0 s), so s200 adds about 19 s, under the plan's 25 s estimate and far under its 90 s stop. No build beyond the no-op `cargo build` of `tests/run.sh`. The coverage test's folder holds about 4.3 MB just before its removal. No `polype-journey.*` folder was left under `/tmp` after the runs.
- **Guards bitten** (each removed by hand, the named test run alone, then restored): `--remote` and the double's `pulls` answer (`every_ask_reason_is_reached`, and `human_confirmation_waits_for_the_merge` for `pulls`); entries logged before the warning stop (`every_ask…`); the research-only planner of a screen story (`screen_story_goes_through_design_and_qa`); the Fix loop computation (`blocked_review_loops_then_asks`); the findings-shape retry and blocked report (`every_ask…`); the unrunnable-check blocked report (`unrunnable_shape_check_records_a_blocked_review`); the posting of the ask decision (`pending_decision_holds_the_lane`); numbered answers (`every_ask…`); the `waiting-for-human` end of the ship answer (`human_confirmation…`); the reader's token count (`reason_reader_reads_every_ask`); a stop function removed (`every_ask…`); #432, both `$vars` and `JOURNEY_SETUP` (`journey_clears_the_callers_git`); #434, `--repo` and the merge base (`forge_double_holds_its_repository`).
- **Guards not bitten, and why.** The `-- docs/qa/<id>/` pathspec of the QA evidence commit: nothing else is ever dirty in the lane when the evidence is committed, so committing without it gives the same commit. Emptying `$J/count` on restore: the one stop that applies `qa` twice runs after every other screen stop, and no other stop meets a numbered answer, so a count carried over changes nothing. Skipping `po ship push` when `po ship land` answers `already_landed` (po-ship Step 1): `push` after a merge also answers `merged`, so both routes clean up. The `$J/prs` snapshot guards nothing, as the plan says.
- **Not walked.** No QA walk is real (no browser); the second site of `setting unreadable: QA stage` (`lane.rs:69`) is not walked on its own; the human merge is cleaned up only by the person's `/po-ship <id>` run by hand, not by `/po-drive`'s `ship (landed)` route, since `po next --remote` keeps `wait (merge waiting)` until something fetches (the defect the research names, left for the lead).
- **Reader escapes (fix run 1, review major at `journey.sh:202`).** Closed: `journey_ask_reasons` now reads every `.rs` file under the folder, subfolders included, for the reasons and for the `"ask"` token count alike; and it fails on an `act(` call whose action is not a string literal (a constant, a variable). `reason_reader_reads_every_ask` bites both: a reason in `sub/deep/nested.rs` of a copy is named by `journey_unreached`, and `act(ASK, …)` in `sub/held.rs` is named with its line. Already closed before this run: a reason held in a constant or built by `format!`, a helper other than `act` that spells `"ask"`, a hand-built `NextAction` with `"ask"`, a macro whose body spells `"ask"` — each leaves an `"ask"` token that is not a literal `act` call, which the token count names. Still open, named in `docs/harnais.md`: an action never spelled `"ask"` inside `po/src/next/` (`concat!`, a macro or constant defined outside the module and used other than through `act`), an `act(` whose action sits on the next line, code pulled in by `include!` or `#[path]`, and an `ask` built outside `po/src/next/`. Focused check: `bash tests/run.sh journey-reaches-every-stop.test.sh`, 4 passed.
- No type check, end-to-end or build stage exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | b6d10a6337d46a8ecc620228e37d6ef12b1313a5 | 2026-11-21T02:54:49Z (510s) |
| Unit suite | `bash tests/run.sh` | 0 | ba3a282d454ccae99908ed0cd5d59ec793deddfd | 2026-11-21T11:51:22Z (807s) |
