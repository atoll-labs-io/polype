# Verification — s182-po-change-needs-a-version

[Story](../stories.md) · [Plan](../plans/s182-po-change-needs-a-version.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 2bb45f74a37561773926b023a8056780340fe9ad

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

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
The forge's behaviour: that `actions/checkout` with `fetch-depth: 0` on a `pull_request` event leaves `origin/main` of the base repository, and that no test breaks on the detached merge commit. This story's own `suite` check on its pull request settles both (`test_workflow_brings_the_base`, `test_this_repository_versions_po`). A real pull request that changes `po/` without a bump comes with s183. Locally, `test_this_repository_versions_po` ran against `origin/main` with no `po/` change, so it only shows the pass path on this repository; the refusal path is shown by the oracle's scratch repositories.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | d1569be322970a867c00488f7b7f37fea71737d3 | 2026-11-15T14:45:43Z (368s) |
