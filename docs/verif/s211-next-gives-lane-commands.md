# Verification — s211-next-gives-lane-commands

[Story](../stories.md) · [Plan](../plans/s211-next-gives-lane-commands.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 9b779dcfc0138fabe87ebbcd4d8aed3bc8252cfd

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
- No real run: whether a lead under Claude Code's sandbox runs the `commands` one per call as given, and whether `(cd <lane> && <Install>)` passes without a prompt, only the next real run shows (plan, `## The pivot`; `drive_runs_them_as_given` is model-read).
- `docs/interface-agent.md` and the record `docs/evals/real-2026-11-24-v0.12.0-2.md` (sum `589271514 851`, checked after copying) are judged in review.
- No type check, end-to-end or build: the project has none. The version check (`bin/po-version-check`) runs in CI.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | 54f37afb8bb3382b7a6907a6d19b1f560677c38d | 2026-11-24T15:31:33Z (716s) |
| Unit suite | `bash tests/run.sh` | 0 | a8a0104a5f4ff3fa94b78a13349d3b18a66bf112 | 2026-11-24T16:06:27Z (1136s) |
