# Verification — s130-install-refuses-collisions

[Story](../stories.md) · [Plan](../plans/s130-install-refuses-collisions.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 49f36de5e3f5b283fd06c151fa7f59b0bb215047

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
No type check, end-to-end or build exists in this project. The installer was exercised only in throwaway directories with a throwaway HOME and CLAUDE_CONFIG_DIR, never against a real `~/.claude/`. A symlinked file is covered (fix run), but a `~/.claude/` or `.claude/agents` that is itself a symlinked directory was never exercised, nor an interrupted global `remove` or a set-aside install that fails after its moves. `docs/installation.md` still describes the old AGENTS.md backup and synopsis (owned by s132).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | b1db52c5336f561fb3767ec7ab32020bc0870054 | 2026-10-14T10:52:49Z |
| Unit suite | `bash tests/run.sh` | 0 | 35630b2b826284beeae15bc99b6c49fe83836c49 | 2026-10-14T11:04:50Z |
