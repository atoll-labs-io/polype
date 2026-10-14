# Verification — s127-hooks-installer-docs-cleanup

[Story](../stories.md) · [Plan](../plans/s127-hooks-installer-docs-cleanup.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: b7032a182ff4a921310e032bb9ba80e43ee9e702

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
- No type check, end-to-end or build exists in this project (`Typecheck`, `E2E`, `Build` are `—`).
- The `/po-setup` framing landing that now passes `<base>` to `po-gate pre-commit` is checked here on the hook alone (scratch repository with a temporary index), not through a real framing landing.
- `remove` without `jq` is checked with a jq-less PATH on Linux only; the macOS bash 3.2 path is not exercised.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 1be28290c1bf5edd88f86617d05ddac7a2d1b6a9 | 2026-10-14T08:32:41Z |
| Unit suite | `bash tests/run.sh` | 0 | 17822cd68512d418aa149038dc5d09d60bd41e09 | 2026-10-14T08:42:57Z |
