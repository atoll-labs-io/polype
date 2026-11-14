# Verification — s172-commands-read-po-state

[Story](../stories.md) · [Plan](../plans/s172-commands-read-po-state.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: a8fbe0776939978dd8e16a8700c3a00bdf9b38d8

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- `status_and_retro_read_po_state` has no behavioural test by the owner's rule: the review judges `method/commands/po-status.md` and `method/commands/po-retro.md` by reading; `test_status_and_retro_shrink` only counts their words (candidate for a `po-eval` control arm, #208).
- The hook is checked against a stub `po` (oracle) and the real `po` built by `tests/run.sh` (session tests); a real session start in Claude Code was not run.
- No type-check, end-to-end or build command exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 8377de1c97466802d58ac0979ba0ed804e9087c1 | 2026-11-14T12:32:19Z |
