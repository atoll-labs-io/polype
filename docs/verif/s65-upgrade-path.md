# Verification — s65-upgrade-path

[Story](../stories.md) · [Plan](../plans/s65-upgrade-path.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: bd658ccb8959dec7c5b7ca86b8e8e2e3ca109aae

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Not proven here
`polype init` printing the list on a project (same `wire_the_project` call as `update`, checked by reading only). Real Agent-tool refusals of a model name (no dispatch happens in tests): the command texts are pinned, not the behaviour of an agent following them. The French wording of `docs/installation.md` is judged by the review.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | dfc47eb8232e1e9844c8703ff36a9ee65aa0d115 | 2026-10-08T11:13:23Z |
