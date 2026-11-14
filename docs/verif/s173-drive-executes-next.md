# Verification — s173-drive-executes-next

[Story](../stories.md) · [Plan](../plans/s173-drive-executes-next.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 74f343fa4f76b04797956460f05d08cdb06c1cae

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | `Full suite: execute-end`; builds `po` first |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

`tests/drive-executes-next.oracle.test.sh` is unchanged (cksum `1028105667 2939`).

Fix run (no oracle file touched), word trades paying for the review findings:
- `po-execute.md` (854 → 850): cut "That is deliberate: the context that coordinates a story is unable to write its code. The `implementer` subagent does it." to "so the `implementer` subagent writes the code"; cut "(missing files, another path, another branch)" in precondition 3; cut "This section is the single statement of the implementer's model; `/po-drive`, `/po-orchestrator` and `/po-flow` point to it." at the head of `## Model`; cut ": the setting is at fault, not the story" in the refusal rule. All explanation, no rule.
- `po-drive.md` (2494 → 2483): cut "two lanes reading the `ADR directory` folder at the same time both find the same highest number, and both write over the other" (why ADR numbers are reserved); cut "The log is written after the ships because a local ship stops on a tracked file modified in the root (`method/commands/po-ship.md`)." (why the log comes after the ships, already stated as "after the wave's last ship"). Both explanation, no rule.

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- `drive_executes_what_it_reads`, `drive_stops_without_po` and the refusal part of `execute_refuses_a_shape_blocked_fix`: prose read by a model; judged in review, `po-eval` control-arm candidates (#208).
- That the `po next` permission string matches what the model types: only the first real `/po-execute` run on a blocked review shows it (plan, `## The pivot`).
- Routing itself: covered by s168's cases (`tests/driver-next-action.oracle.test.sh`), not touched here.
- No end-to-end, build or lint stage exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 9121b95008704fc60c8a77b76cd6fe20d93be553 | 2026-11-14T09:44:49Z |
| Unit suite | `bash tests/run.sh` | 0 | eb213582e1bd2b6c2603e1246a73e09f4061ae5a | 2026-11-14T09:57:41Z |
