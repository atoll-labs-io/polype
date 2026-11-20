# Verification — s197-own-context-commands-are-briefs

[Story](../stories.md) · [Plan](../plans/s197-own-context-commands-are-briefs.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 28df5dede6638b16687be15b7d00820f8f98ca13

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
End to end and build at ship (none declared here); lint runs inside the oracle (`test_commands_still_lint`). `routing_is_said_once`, `worktree_is_prepared_in_one_place` and `subagents_keep_their_procedure` speak to a model and are judged by the reviewer against `## Removed sentences` of the plan; no script proves them. No hand run of `/po-research`, `/po-plan` or `/po-design` against a live `po next` was made: the `## By hand` paragraphs are prose checked by reading. The stops that moved to `po next` are held by tests outside `Owns` (research `## Traps`), not by this story's. Fix run 1: the restored `/po-design` stops (`docs/design-system.md` missing, `Design source` `—`), the narrowed no-`Surface` branch, the "A subagent skips this paragraph." lines and the reworded soft-gate sentence of `/po-stories-review` are prose, checked by reading; no test pins them.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 4836591cc24154651bf6ffcce6eacf26c37bc9db | 2026-11-20T23:12:49Z (450s) |
| Unit suite | `bash tests/run.sh` | 1 | 6464d48c81c4aee349d1b984c55849c6cd890c21 | 2026-11-20T23:41:56Z (451s) |
| Unit suite | `bash tests/run.sh` | 0 | 39698219cb96e342ee1843f05aab283e29f98f0b | 2026-11-20T23:49:51Z (453s) |
