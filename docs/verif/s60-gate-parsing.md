# Verification — s60-gate-parsing

[Story](../stories.md) · [Plan](../plans/s60-gate-parsing.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: f2a387e543076259e8ec95f1fa489436bebb8c8f

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E stage: —`) |
| Build | — | no such command in this project (`Build stage: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
- The secret scan's awk has the same end-of-input gap the floor guard had (a hunk left short at the last line is not flagged): not in this story's criteria, left as is.
- `po-drive.md` rows 53 and 62 still describe `qa-current` passing an uncommitted report; after this story that resume path never matches. Correction belongs to s64 or a follow-up.
- Run interdicts checked by hand: `.claude/`, `.polype/`, `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/skills/review-antihallu/SKILL.md`, `tests/qa-fleet.test.sh` have an empty diff; `SECRET_PATTERNS`, `FLOOR_PATTERNS`, `FLOOR_TEST_PATHS` unchanged.
- No screen, no visual check; no type check, end to end or build exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | bdb7736e6c2662cb59b0b1b864df99cdc424092a | 2026-10-08T10:22:24Z |
