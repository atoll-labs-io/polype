# Verification — s82-mobile-web-driver

[Story](../stories.md) · [Plan](../plans/s82-mobile-web-driver.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 871abb886390c05d5d17be08cd7efd6fc312cef2

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
- The tests check the method text only; no QA of a real mobile project was run with the new driver (the first one will be clout, after s83–s85 write the profiles).
- Whether the browser tools a `/po-qa` session inherits can set a viewport is not exercised here (plan, "The pivot").
- `bash bin/po-lint method` exited 0 when run by hand; it has no `po-run` row because it is not a project command.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 5f999a5bcc57a86e11eaf0cbb72e4f8b495a2180 | 2026-10-08T16:03:57Z |
