# Verification — s187-inbox-guards-bite

[Story](../stories.md) · [Plan](../plans/s187-inbox-guards-bite.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 85585160adbcf04ef34be72a122b44cab57492b7

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | deferred to ship |
| Build | — | deferred to ship |

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

## Not proven here
The mutation proofs of the guards (lock, outside worktree, comparison, `decision.rs:87`, `add.rs:192`) are the reviewer's. The contract prose (`docs/interface-agent.md`) is judged in review.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 343855408c5c64d0c3b5dbc317f18487fe2026bc | 2026-11-16T10:28:08Z (417s) |
| Unit suite | `bash tests/run.sh` | 0 | b4e00397cfe7a85be9eef521d15c19a8ce91591d | 2026-11-16T10:35:15Z (420s) |
