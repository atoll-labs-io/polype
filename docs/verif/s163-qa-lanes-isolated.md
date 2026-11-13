# Verification — s163-qa-lanes-isolated

[Story](../stories.md) · [Plan](../plans/s163-qa-lanes-isolated.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: cdb9261ccd9490bfd89f85275d535664fa3e8eb6

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- `each_lane_drives_its_own_browser`, `each_lane_serves_on_its_own_port`, `a_stuck_driver_ends_blocked`: case 3 of the plan, rules addressed to the `qa` model in `method/skills/qa-drivers/SKILL.md` `## Lanes side by side`; judged by the reviewer by reading, candidates for a `po-eval` control arm (#208). Only the word counts (`test_no_file_grows`) are tested.
- No live run of two QA lanes on a `screen` project: this repository has no screen (`Platform: cli`). The port expression was evaluated by hand in this worktree (it prints a port in 20000-29999); no browser was launched.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | ed7cf16fad62ecf05c119ab77cd91a5b4f2da3d4 | 2026-11-13T10:55:03Z |
| Unit suite | `bash tests/run.sh` | 0 | 2b513977ff17e9118b4a2afd2a08563c3e4d3717 | 2026-11-13T11:04:30Z |
