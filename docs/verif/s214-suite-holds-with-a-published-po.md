# Verification — s214-suite-holds-with-a-published-po

[Story](../stories.md) · [Plan](../plans/s214-suite-holds-with-a-published-po.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 313c8eb82cd7f1f48e12cacc13a15d17f5198c5b

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | deferred to ship |
| Build | — | deferred to ship |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
End to end and build: none in this project. Criterion `whole_suite_on_a_summed_tree`, in a throwaway clone of PR #520's tree (`04a003b`) with the story's two test files, network present: (a) as is, 710 passed, 0 failed; (b) with the `po-0.13.0-linux-x86_64` sum replaced by the sha256 of the `po` built in that tree (CI's condition), 710 passed, 0 failed. Only CI on PR #520, rebased after this story, proves the runner's own case.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 5beb76c2d89c040cc96a5288f5c2c4cc99b136bd | 2026-11-26T00:48:39Z (715s) |
