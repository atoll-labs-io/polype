# Verification — s64-qa-routing

[Story](../stories.md) · [Plan](../plans/s64-qa-routing.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: b14c7996e0e7bc47593138ce84e2ee41ed3ac22f

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Lint | `bin/po-lint` | asked by the plan's task 8; not a command of `AGENTS.local.md` |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Not proven here
Behaviour of `po-gate` (unchanged; its `is current but` refusal is pinned by `tests/qa-fleet.test.sh` and `tests/qa-gate.test.sh`). Whether an agent following the six command texts actually routes a QA-blocked review as described is judged by the review, not by these string checks.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | c64231b5518778c8dc11d8137bfd62f944f8f614 | 2026-10-08T10:58:15Z |
| Lint | `bin/po-lint` | 0 | 38ed482d3e809b304d567b804180573fa6daba40 | 2026-10-08T10:58:15Z |
