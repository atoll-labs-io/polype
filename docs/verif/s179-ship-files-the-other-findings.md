# Verification — s179-ship-files-the-other-findings

[Story](../stories.md) · [Plan](../plans/s179-ship-files-the-other-findings.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 1106054c581efde66cb4a4f74eb4a2f9ef2b4c8c

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
| `tests/intake-issue-becomes-a-story.oracle.test.sh` | line 121-122 expects `superseded-by: [ADR-0099, ADR-0123, ADR-0124]` | ADR-0124 supersedes ADR-0090 on the lens hold; plan task 5 and `Owns` allow this line only. |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
End to end and build are not run by this stage (E2E and Build stage are `—`). The three model-read criteria (other_findings_are_filed_again, nothing_private_in_what_ship_writes, retro_counts_what_it_cannot_read) have no script and are judged in review.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | dadfba5a7734fc5dac5a169faaaa71a348d2bad8 | 2026-11-14T17:29:48Z (385s) |
| Unit suite | `bash tests/run.sh` | 0 | ac645eb4279e491f048b8e616b0c5b9f22ce9966 | 2026-11-14T17:47:46Z (395s) |
