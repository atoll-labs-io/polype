# Verification — s96-defect-and-routing-paths

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 99e8754bc5dbcadc0d3b6164d214006aa946f237

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

## Not proven here
- Whether naming the `diagnostic` skill in the prose of `/po-research` and `/po-orchestrator` makes the main context actually load and follow it: the text tests show the skill is named on every path, not that a model applies it (the plan's pivot, third risk; same gap as s90).
- Whether a model writes the marker exactly as `Root cause: not found` on its own line: the tests show the skill and every reader quote the same token, not what a model produces at run time.
- No type check, end to end or build: the project has none of them.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 944d6bb2fa28a4e98f8bda007b6480ee37d4855a | 2026-10-08T17:44:29Z |
