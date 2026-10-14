# Verification — s136-session-hint-infers-init

[Story](../stories.md) · [Plan](../plans/s136-session-hint-infers-init.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 156962dbbd800b7cc4fd4407ed7de0e91bf7fa57

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
- Mutation (d), `&& false` appended to the condition at `method/hooks/po-session.sh:245`, was applied to a copy of the tree outside the worktree (the bounds forbid editing the hook): `update-keeps-mode.test.sh` then gave 6 passed, 1 failed, the new test being the failure. The worktree's hook is unchanged.
- No type check, end-to-end or build exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | e63eb80d3bbaf6b46bcc3732340cc0ea8ad0bc63 | 2026-10-14T18:57:08Z |
| Unit suite | `bash tests/run.sh` | 0 | c05327b76aecaa24fedc204489262b2875e9bb47 | 2026-10-14T19:08:36Z |
