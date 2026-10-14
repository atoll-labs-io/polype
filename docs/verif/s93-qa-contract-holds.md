# Verification — s93-qa-contract-holds

[Story](../stories.md) · [Plan](../plans/s93-qa-contract-holds.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 293c4fd967a74eac2a2d3a487b5835c840604b87

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Lint | `bash bin/po-lint` | declared by the plan (task 5): checks every `Reads settings` entry exists in the template |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
Whether a real `qa` subagent obeys the new prose (zero-row block, `docs/qa/<id>/` exception, Bash heredoc, 60-second bound): only a real `/po-qa` run on a CLI or API story shows it. The bite of each new assertion (deleting its rule turns it red) is the reviewer's to run (ADR-0012).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 55d969260bbba5ca6f4e4e3f1f5b9d6583c43ae4 | 2026-10-08T17:26:45Z |
| Lint | `bash bin/po-lint` | 0 | 28d3ced4e71b23b9b47dbc081633addd8c241689 | 2026-10-08T17:26:46Z |
