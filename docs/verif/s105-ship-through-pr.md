# Verification — s105-ship-through-pr

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 4f8feb7029dac04fb73f7d9dc363b5edbe7e4708

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
The tests are text checks on method files: they prove the wording of `/po-ship`, not that a real ship lands one commit through a pull request. That is proven only by the first real `/po-ship` in pr mode on this repository (the plan's "single end-to-end run of the whole cycle"). The equivalence of `git merge-tree --write-tree` with the former `git merge --squash` on a clean merge was not re-checked in this run: `po-bounds` refused the throwaway-repository commands (it blocks `git commit` outside a `story/<id>` branch); the research checked it once. No type check, end-to-end or build command exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 6d93c82069a5f887c2852df1f60c923f1621a2d4 | 2026-10-13T11:34:28Z |
