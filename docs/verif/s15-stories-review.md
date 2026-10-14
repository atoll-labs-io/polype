# Verification — s15-stories-review

[Story](../stories.md) · [Plan](../plans/s15-stories-review.md)

Commands copied from `AGENTS.local.md`. `Tree:` was taken after `git add -A`; this file and the plan's ticks sit in `docs/`, which the comparison leaves out.

Tree: ad8321314f3c4de2060db9cdc986e2e293eccb0c

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Focused (tasks 1–8) | `bash tests/run.sh stories-review.test.sh pilot.test.sh structure.test.sh overlap.test.sh` | exit 0 · 22 passed · 0 skipped | 2026-09-19T12:15Z |
| Unit suite | `bash tests/run.sh` | exit 0 · 101 passed · 0 failed · 0 skipped | 2026-09-19T12:16:19Z |
| Type check | — | no such command in this project (`Typecheck: —`) | — |
| End to end | — | no such command in this project (`E2E: —`) | — |
| Build | — | no such command in this project (`Build: —`) | — |

The unit suite ran twice on the same code (the first run's exit status was not captured, so it was rerun to record it); both reported 101 passed, 0 failed. Baseline before the story: 96 passed; the 5 new tests are those of `tests/stories-review.test.sh`.

## Not proven here
- The behaviour of `/po-stories-review` and of the `stories-reviewer` subagent when actually run by Claude Code: the tests are structural and pin the clauses, they do not execute the command. A person should run `/po-stories-review` on a project with `docs/stories.md` once to see the report written and committed.
- That `/po-research` really emits the warning and carries on: only its wording is checked.
- `tests/overlap.test.sh` ran with the Killer SaaS sources present and passed; it proves no 8-word overlap, not that the prose is otherwise original.
- No type check, end-to-end or build exists in this project.

Verification status: complete
