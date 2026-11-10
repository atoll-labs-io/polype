# Verification — s149-planner-writes-the-oracle

[Story](../stories.md) · [Plan](../plans/s149-planner-writes-the-oracle.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 4c1ea0dbae3013f49c5a3ef40ce535d592ccfc44

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
End to end, build and type check: this project has none (`E2E`, `Build` and `Typecheck` are `—`). Whether agents follow the new oracle wording at run time is not provable by these text tests; the reviewer judges it. The two earlier failing runs came from `tests/artifact-links-backfill.test.sh` failing on `main` itself (missing link line in the s147 review), fixed on `main` by #170 before this branch was rebased; the last unit suite run, on the rebased code, exited 0.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | 12099813b6f59924e949b470da9ab87bdb38e330 | 2026-11-10T17:56:02Z |
| Unit suite | `bash tests/run.sh` | 1 | ab5819cd0e926f610c77119997fa9ccaa75f0510 | 2026-11-10T18:01:20Z |
| Unit suite | `bash tests/run.sh` | 0 | f17bc7397f79b6ad897e47b7985bb19f6251f343 | 2026-11-10T18:09:59Z |
