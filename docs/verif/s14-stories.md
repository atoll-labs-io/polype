# Verification — s14-stories

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: 4d127d7b4fb5b3fe72cce948aa7b8b0f1a545aec

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Focused (tasks 1–4) | `bash tests/run.sh stories.test.sh` | exit 0 · 5 passed · 0 skipped | 2026-09-19T12:07Z |
| Unit suite | `bash tests/run.sh` | exit 0 · 96 passed · 0 skipped (overlap check ran with Killer SaaS sources present) | 2026-09-19T12:08:18Z |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project | — |
| Build | — | no such command in this project | — |

## Not proven here
- The command's behaviour when run for real (drafting stories from an actual PRD or brief, user agreement, commit on `Target branch`) is not exercised: the tests are structural and check that the clauses exist, not that an agent follows them.
- Whether each test fails when its clause is removed is left to the review (guard neutralization).
- The full suite ran twice on the same tree: the first run's exit code was lost in a pipe (96 passed, 0 failed shown), the recorded run is the second.

Verification status: complete
