# Verification — s80-surface-routing

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 859d0c65f611a04c3f92a6ebffbe074265f18047

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
Whether the commands and agents that route a story actually apply the two terms of `method/AGENTS.md` ("has a screen", "goes to QA") to a real `Surface` line is prose followed by a model: the tests pin the phrases and the absence of the old formulas, not the behaviour. No `/po-drive`, `/po-orchestrator`, `/po-flow` or review run was made against this tree. The installed copies (root `AGENTS.md`, `.claude/`, `.polype/`) are refreshed after ship, not here. No screen.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 32c271c5612e61b10c1f8b853a2593c8819282dd | 2026-10-08T15:51:26Z |
