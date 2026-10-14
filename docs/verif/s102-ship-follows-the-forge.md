# Verification — s102-ship-follows-the-forge

[Story](../stories.md) · [Plan](../plans/s102-ship-follows-the-forge.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 269f5100a005a2400775cec1edd75d24f706fad1

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
The method is prose; the tests grep its clauses. No forge API was called during implementation (plan, Run interdicts): the GitHub, GitLab and Forgejo/Gitea calls, the plan-limit 403 reading and the draft pull request on `framing/ship-confirmation` are proven only when a real ship runs them; GitLab and Forgejo/Gitea are unverified on any instance (ADR-0079). No type check, end to end or build exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 947215f7d22e2d3bbc5d8631bb5d34062d6913d4 | 2026-10-13T12:25:17Z |
