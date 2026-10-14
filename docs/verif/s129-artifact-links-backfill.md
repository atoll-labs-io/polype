# Verification — s129-artifact-links-backfill

[Story](../stories.md) · [Plan](../plans/s129-artifact-links-backfill.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: a2cc58b15974ef778574db8d7800f5ec81e01493

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
End to end and build do not exist in this project. The 434 backfilled artefacts are held by link resolution and by the per-file `+2 -0` diff, not by a reading of each.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 6087af0ed33df1bb6d2536779d161c45a2d8942a | 2026-10-14T09:20:59Z |
| Unit suite | `bash tests/run.sh` | 0 | a2cc58b15974ef778574db8d7800f5ec81e01493 | 2026-10-14T09:29:29Z |
