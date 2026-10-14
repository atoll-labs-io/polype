# Verification — s55-reviewer-evals

[Story](../stories.md) · [Plan](../plans/s55-reviewer-evals.md)

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: 01c6f59749ceb4d75e45c6dbed6b8d9b4c3f0950

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | exit 0 · 287 passed · 0 skipped | 2026-10-08T08:12:00Z |
| Focused (task 5) | `bash tests/run.sh evals.test.sh` | exit 0 · 5 passed · 0 failed | 2026-10-08T08:09:00Z |
| Lint | `bin/po-lint` | exit 0 · no breach in 25 file(s) of method/ | 2026-10-08T08:11:00Z |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project | — |
| Build | — | no such command in this project | — |

The focused run preceded a one-line change to `bin/po-eval` (a newline after the confirmation when stdin is not a terminal); the full suite, which includes `evals.test.sh`, ran after it on the tree above.

## Not proven here
- No real `claude` run was made: each costs a paid call and the runner asks a person to confirm by design. Every runner behaviour was checked against a fake `claude` on `PATH`. A first real `bin/po-eval` run is left to the user.
- Whether `claude -p --agent reviewer` preloads the agent's `skills:` in a main session is unverified (plan pivot 1); the raw reports kept by `po-eval` will show it.
- `bin/ks-overlap` and `tests/overlap.test.sh` scan `method/` only, so `evals/` was not machine-checked against agent-skills; its recipes and pressure texts were written without opening agent-skills' `evals/`.
- Times are to the minute, read from the session, not stamped by a tool.

Verification status: complete
