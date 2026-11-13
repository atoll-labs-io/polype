# Verification — s174-verbs-read-project-context

[Story](../stories.md) · [Plan](../plans/s174-verbs-read-project-context.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: ca707954d409b719d3358ac202d016cd0a2977b1

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`); `cargo build` inside `tests/run.sh` type-checks the crate |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- The warnings and stops no fixture reaches (`no-gate`, the `QA stage` warnings, `merge-waiting`, `max-attempts`, `qa-blocked`, `root-cause-not-found`): their code moved unchanged; the reviewer compares `stage()` and `blocked_by()` with `main`, as the plan's pivot says.
- The new readers (`Depends on` / `Dépend de`, `Owns`, a story's milestone, the landed commit) have no observable output yet; s168 and s170 test them. One throwaway run outside the repository printed the expected deps, `Owns` and milestone for the last six stories of `docs/stories.md`.
- `verbs_receive_one_context` is a code-structure rule: judged by the reviewer.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 6cbad1165ea5693f2a8d00f8c1dadcd0a88c398d | 2026-11-13T17:25:27Z |
