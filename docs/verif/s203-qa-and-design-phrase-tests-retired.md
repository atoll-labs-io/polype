# Verification — s203-qa-and-design-phrase-tests-retired

[Story](../stories.md) · [Plan](../plans/s203-qa-and-design-phrase-tests-retired.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: fe36ed7facaf12f2bc3e3df7081a6b2863821892

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |
| `tests/qa-and-design-phrase-tests-retired.oracle.test.sh` | `S203_KEPT` adds `test_qa_returns_its_report`; `S203_KEPT_LINES` adds the restored lines of `qa-report-returned-as-text` and `scenario-driver` and the S5, S6, S7 lines the review found unpinned. New cksum `1497978296 7488` (was `3547054909 6749`). | Fix run 1: the review's minor on the keep list, and the assertions restored under d-0053 and d-0052 option c (S8, S9 of the plan). |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
Model-read criteria (`kept_assertions_have_a_reader`, `what_only_a_product_proves_is_listed`) are judged in review. The rules listed under `## What only a product proves` of the plan have no test left. `bin/po-lint method` and `po-gate floor-guard` are run separately, not recorded here.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 38bc6be05006a6375c37d74c08a8af4fcb601351 | 2026-11-22T17:29:47Z (614s) |
| Unit suite | `bash tests/run.sh` | 0 | eb00b44b9a69b6e250946769d0dc19ecb4a534f3 | 2026-11-22T17:50:13Z (541s) |
