# Verification — s213-release-tests-survive-landed-sums

[Story](../stories.md) · [Plan](../plans/s213-release-tests-survive-landed-sums.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 983ccabc50cdc8155584458e50bbf06ea47f9ad2

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
| `tests/first-release-holds.oracle.test.sh` (s189) | `copy_of_polype` empties the copy's `PO_SUMS` block after copying `bin/` | the fixture stands for a version not yet summed; landed sums (PR #520) make `--tag` refuse, as it should |
| `tests/po-prebuilt-and-verified.oracle.test.sh` (s171) | same two lines in `copy_of_polype` | a landed real sum made `installer_falls_back_to_sources` accept the double |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
End to end and build: none in this project. Checked outside the worktree on `git archive af2c324` (PR #520) with the story's diff applied: the five files of task 5 give 22 passed, 0 failed.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 9ba0acef6f35b93e47156ebc9e3da211b9c138b9 | 2026-11-25T19:20:06Z (701s) |
