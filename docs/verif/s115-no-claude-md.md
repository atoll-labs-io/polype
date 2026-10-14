# Verification — s115-no-claude-md

[Story](../stories.md) · [Plan](../plans/s115-no-claude-md.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 85d2c7883f87cb5dc46e0d5df97b1ec4c7d2d5ba

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Not proven here
- The installed copies `.claude/` and `.polype/` of this repository are not refreshed: the pre-commit and po-session running here keep the old behaviour until the next `polype update`.
- Whether Claude Code really ignores `AGENTS.md` while a `CLAUDE.md` exists is taken from ADR-0073/ADR-0086, not tested here.
- Bite targets (mutations) are the reviewer's job.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | b72e504c11bc94b5de9c31839bf9b43d673cc919 | 2026-10-13T16:40:10Z |
