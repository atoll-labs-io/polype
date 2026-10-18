# Verification — s143-payload-edit-not-spread

[Story](../stories.md) · [Plan](../plans/s143-payload-edit-not-spread.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 1c6e3f2a721fd46de902170eb8609bcdef0c2bcc

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
No type check, end-to-end or build command exists in this project (`—`). Argued, not tested (plan, Test strategy): the payload path recorded with the signed sum rather than `RECORDED` (both equal when installed from a repository), and the `drop_kept_copies_now_shipped` skip for an edited source. Not exercised: `install|update <project>` from the payload with an edit (same code path as `init`, no test of its own), and a real chezmoi sync between machines.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 1b016ec4dd2e1962b23a2de9041f3680390ebc9e | 2026-10-18T17:51:33Z |
