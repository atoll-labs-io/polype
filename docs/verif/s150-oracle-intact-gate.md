# Verification — s150-oracle-intact-gate

[Story](../stories.md) · [Plan](../plans/s150-oracle-intact-gate.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: d7e3edfcb805eae516a8992637ed993f0d8922fd

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
No type check, end to end or build exists in this project. The new `po-gate oracle-intact` is exercised only through the oracle tests on throwaway repositories; two rows of `## Oracle changes` for one file, a row naming an intact or unlisted file, and the installed copy under `.polype/` (refreshed only after ship) are not tested here. The first Unit suite run exited 1 on two tests of `artifact-links-backfill.test.sh` about `docs/reviews/s156-qa-report-returned-as-text.md`, a `main` file outside this story; #187 fixed it on `main`, the branch was rebased onto it and the suite was run again.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | 79dcd390ecd95c2c682658ceefffb4ab3216459b | 2026-11-11T21:19:00Z |
| Unit suite | `bash tests/run.sh` | 0 | 9951e524a4151c38dbe1727480858d2f891b38b2 | 2026-11-11T21:36:31Z |
