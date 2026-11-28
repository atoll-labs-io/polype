# Verification — s219-suite-bounds-and-cleans

[Story](../stories.md) · [Plan](../plans/s219-suite-bounds-and-cleans.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 6bdef53968fad24c1f64ff18f4a464918fd78756

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | deferred to ship |
| Build | — | deferred to ship |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
End to end and build: none in this project. Real load on a CI runner is simulated by doubles of `po`; only CI proves a runner under real load. Scratch cleanup of files outside `Owns` that re-arm their own `trap ... EXIT` is not changed.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 9287e43caca0306160e1e55a349a14d3019d5ba7 | 2026-11-28T11:25:54Z (814s) |
| Unit suite | `bash tests/run.sh` | 0 | 283fefa756e98eb47ac0def0ef3e00b7d5a2d97b | 2026-11-28T11:45:48Z (737s) |
