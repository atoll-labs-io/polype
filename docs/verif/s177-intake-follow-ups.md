# Verification — s177-intake-follow-ups

[Story](../stories.md) · [Plan](../plans/s177-intake-follow-ups.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 67d07632964024e901c749a1a58eac15b7974eb0

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
- Criteria `only_the_hook_account_is_taken_in`, `pending_intake_does_not_block` and `numbering_sees_pending_branches` are rules read by a model: no test covers them, the review judges them by reading (`po-eval` control-arm candidates, #208).
- The new `/po-intake` behaviour was not run against a live forge (no pending intake pull request, no second `gh` account available here). Fix run 1: the pending-branch exception now proves "not merged" by the pull request state on GitHub (ancestry elsewhere) plus a copy that deletes no line of the target's `docs/stories.md`; this too is judged by reading, not run against a forge.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | eff1c75f9f34bac769c855e595ddf43c08adfd79 | 2026-11-14T14:28:35Z (356s) |
| Unit suite | `bash tests/run.sh` | 0 | a62492201c138725892418eb01113304d6eacce6 | 2026-11-14T14:39:28Z (340s) |
