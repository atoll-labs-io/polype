# Verification — s178-security-findings-stay-private

[Story](../stories.md) · [Plan](../plans/s178-security-findings-stay-private.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 8ac1eeccb481e765a4e022904d5020f64d1026ed

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | run on the committed story, before the record was amended in (issue #254, plan task 10) |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- `fix_run_still_reads_them` and the reviewer's marking rule are rules read by a model (`implementer.md` `## Fix runs`, `reviewer.md` `## Your answer`): no test covers them, the review judges them by reading (`po-eval` control-arm candidates, #208).
- `docs/interface-agent.md`: no script reads it, judged in review.
- `po-bounds` letting the implementer and the reviewer run `po inbox <id>` was checked once by hand (both roles exit 0 on that command), not by a test.
- A live review on a real project: the behaviour is proven only through the bash fixtures, with `HOME` and `Private folder` inside a scratch dir.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 51f4ddaa4351e3356ddf429a9cf094a02a4edfe1 | 2026-11-14T16:05:45Z (339s) |
| Unit suite | `bash tests/run.sh` | 0 | 565829468e930655daeafac8b40a04ba3ed0024b | 2026-11-14T16:18:39Z (314s) |
