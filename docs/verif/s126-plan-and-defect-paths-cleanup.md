# Verification — s126-plan-and-defect-paths-cleanup

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: c149fb59e7e8386ad7aa8b398275485151cf7a25

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | deferred to ship |
| Build | — | deferred to ship |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
End to end and build: the project has none. Lint and formatting: none declared.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | baecb9155a5ed8e6eb91bf96a99d48cd4fd2ada1 | 2026-10-14T08:16:33Z |
