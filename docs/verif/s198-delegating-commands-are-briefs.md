# Verification — s198-delegating-commands-are-briefs

[Story](../stories.md) · [Plan](../plans/s198-delegating-commands-are-briefs.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 247b2966be837106a7856e8a0aece22756d7b2f6

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |
| `tests/delegating-commands-are-briefs.oracle.test.sh` | `test_words_go_down`: the three commands' cap goes from `THREE_BEFORE - 700` (2 004) to `THREE_BEFORE - 650` (2 054), its failure message saying 650; nothing else changes | Fix run, 2026-11-21: the lead lowered the word criterion to 2 054 at most through a framing pull request on main, to make room for the two majors of the review only, the `ask` `QA evidence committed twice` in `/po-review` `## By hand` and the `—` model rule put back in the three commands |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
The three model-read criteria (`routing_is_said_once`, `drive_and_commands_share_one_text`, `nothing_is_lost`) are judged by the reviewer, not by a test. No `po-eval` control arm was run. Lint (`bin/po-lint`) runs inside the oracle test; there is no type check, end-to-end or build in this project. Fix run: the `—` model rule is held again by one phrase assertion (`model-routing.test.sh`) on `/po-execute` only; in `/po-qa` and `/po-review` it is read by a model, with no test. That `/po-review` by hand goes on after `QA evidence committed twice` is read by a model, not tested.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 2274993681c2284fe85a280da2b4c16d72fe3b6e | 2026-11-21T00:38:48Z (450s) |
| Unit suite | `bash tests/run.sh` | 0 | 54551afa279815eb4742da4538469d8988d3f6f1 | 2026-11-21T00:57:45Z (454s) |
