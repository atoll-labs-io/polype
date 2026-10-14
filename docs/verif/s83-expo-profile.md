# Verification — s83-expo-profile

[Story](../stories.md) · [Plan](../plans/s83-expo-profile.md)

Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 6e81fcb2ca685278e914b382d7883a77dac85d39

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Not proven here
The `npx jest`, `npx tsc --noEmit` and `npm run web` commands of the expo profile were not run (no install on an untrusted clone). The grounding test ran against a fresh sparse clone of expo/expo. `bin/po-lint` ran clean.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 06c4f5f3b1e82de475f2bd854a47e143e16100c8 | 2026-10-08T16:16:34Z |
