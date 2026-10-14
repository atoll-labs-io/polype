# Verification — s43-mustelinet-bricks

[Story](../stories.md) · [Plan](../plans/s43-mustelinet-bricks.md)

The implementer writes this file last, just before committing the story, and commits it with the code. The reviewer compares `Tree:` with the commit: if they match, the results below count as proven and are not rerun. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks are written afterwards, inside `docs/`, which the comparison leaves out.

Tree: 8fcbaa2d6f1f4ffda77d86029afd8e7e732bfc0d

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Task tests | `bash tests/run.sh bricks.test.sh` | exit 0 · 4 passed · 0 skipped | 2026-09-22T19:5xZ |
| Unit suite | `bash tests/run.sh` | exit 0 (run.sh ends on `[ "$failed" -eq 0 ]`; printed "226 passed, 0 failed") · 226 passed · 0 skipped | 2026-09-22T19:55Z |
| Lint (plan task 5) | `bin/po-lint` | exit 0 · "no breach in 23 file(s) of method/" | 2026-09-22T19:55Z |
| Type check | — | no such command in this project | — |
| End to end | — | no such command in this project (`E2E stage: —`) | — |
| Build | — | no such command in this project (`Build stage: —`) | — |

## Not proven here
- Facts about Garage, pg-boss, OpenTelemetry and PostgreSQL written in the notes are not checked by any test; the tests check the notes' shape, host gaps, checklists and absence of code. Grounding of host claims against `docs/references/mustelinet.md` is the reviewer's pivot check.
- Nothing is deployed at mustelinet; the checklists' `Mustelinet:` items are unproven until a brick is actually deployed.
- The full-suite exit code was not echoed separately (the capture in the shell failed); it follows from run.sh's last line and the printed "0 failed".

Verification status: complete
