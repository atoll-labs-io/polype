# Verification — s166-answer-comes-back

[Story](../stories.md) · [Plan](../plans/s166-answer-comes-back.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: b8fa79deccafb4fb88c25f8492cffc2d2d1e8e64

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`); `tests/run.sh` builds `po` with cargo before the suite, which type-checks the Rust |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- `rules_say_who_consumes` (the sentence of `method/AGENTS.md:67`): judged in review by reading; only the word ceiling (3739 ≤ 3741) is tested.
- The contract of task 7 (`docs/interface-agent.md`): judged by reading, no test reads it.
- `tests/state-as-json.oracle.test.sh:151` (s164's oracle, not this story's) loses `answer` from its `not-built` loop, as task 5 of the plan says.
- `po answer` on this repository itself: its inbox holds no decision, so it answers `unknown-decision`; the refusal of an unlisted key is proven on throwaway repositories by the oracle.
- CI on the pull request runs at ship.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | be773db21ec05c0ce5850710acf599b80daf7a2d | 2026-11-13T15:38:25Z |
