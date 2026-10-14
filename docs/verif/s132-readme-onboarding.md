# Verification — s132-readme-onboarding

[Story](../stories.md) · [Plan](../plans/s132-readme-onboarding.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 2a3f12ad118c87ab5e21f8d65f1568a06fb01336

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
No type check, end-to-end or build exists in this project (`—` in AGENTS.local.md). No bash older than 4.2 exists on this machine: the guards are proven by running their extracted block with a substituted array name, not under a real old bash, and nothing is run on macOS. The quickstart test clones the committed tree, so before this commit it ran the pre-story `bin/polype`: it proves the README procedure, not the guard. `jq` and `gh` prerequisites are only listed, not exercised. The installed copies (root `AGENTS.md`, `.claude/`, `.polype/`) are not refreshed by this story. Fix run 1: the pose-aware hint is proven on the working-tree `bin/polype` for `init` and `install <projet>` only; `update .` on an `init` project still lays the commands (out of scope). The throwaway-clone try in the README is checked for its place, not run. Fix run 2: both pose-aware hints (`CLAUDE.md`, hand-written `AGENTS.md`) are proven for `init` and `install <projet>` only; the `po-session` hint for `absorbed` still names `polype update .` (loop-1 finding 2, left to the lead).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | ed356874ac00588d81ae2c40bbb0e21e0c2c8fce | 2026-10-14T11:48:08Z |
| Unit suite | `bash tests/run.sh` | 0 | 695d460e6494e5343a3e32aed7385d34742a786c | 2026-10-14T11:56:52Z |
| Unit suite | `bash tests/run.sh` | 0 | 50fa3f6e3240d1cfccc02cd3e5e42030fd6c175f | 2026-10-14T12:14:54Z |
