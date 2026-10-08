# Verification — s95-profiles-hold

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: fd89d09b3cc87ea963e346b77dafbf2afb97a4ef

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
- The new iOS `Test` command was never run: no Mac or Xcode here. Neither the green nor the red case is proven; the tests only pin its exact text (plan, "The pivot"). Someone with a Mac should run it once green and once red.
- The Android and Expo commands were not run on a real generated project.
- `bin/po-lint` was run by hand on `method/` (no breach); it is not a declared check of this project.
- The grounding tests ran with network access; the offline skip path was also observed by hand with an unreachable proxy (`skip  expo_profile_is_grounded_in_its_source`).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 5d96f29edea42bbe7afba13e0b47524f0761c363 | 2026-10-08T17:46:16Z |
