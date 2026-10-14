# Verification — s56-evidence-runner

[Story](../stories.md) · [Plan](../plans/s56-evidence-runner.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 132b7c2133c89d9320e4f055c08cd585cbbd25bc

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
- Type check, end to end and build: this project has none (`Typecheck: —`, `E2E: —`, `Build: —`).
- The new `po-gate verif-current` on this very record: the installed `.polype/hooks/po-gate.sh` the reviewer runs is still the old one (it reads only `Tree:` and the status), and the installed copy is refreshed after ship, not by this story. The new gate is proven on throwaway repositories by `tests/run-ledger.test.sh` and on the built eval cases by `tests/evals.test.sh`.
- A hand-forged row in `## Runs` is not detected by any check (ADR-0035, Bad): only the review can spot it.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | eab2800af70508d9bf77b878cc0e14362f75e140 | 2026-10-08T08:35:08Z |
