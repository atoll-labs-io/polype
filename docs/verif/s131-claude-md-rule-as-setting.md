# Verification — s131-claude-md-rule-as-setting

[Story](../stories.md) · [Plan](../plans/s131-claude-md-rule-as-setting.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: e695ef4e3238918d5026aacdf73351733337fa13

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
No type check, end-to-end or build exists in this project (`—` in AGENTS.local.md). The installed copies (root `AGENTS.md`, `.claude/`, `.polype/`) are not refreshed by this story, so the pipeline running on Polype itself still uses the previous hooks; `docs/installation.md` still describes unconditional absorption until s132. No real Claude Code session was started to confirm it reads `AGENTS.md` through a kept `CLAUDE.md`. Fix run: the symlinked root `CLAUDE.md` under `kept` and a `CLAUDE.md` starting with a BOM are still not exercised; a CRLF `CLAUDE.md` under `kept` now is.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 7948e60e4ae629f77021cda7fa193000a6e97ed9 | 2026-10-14T11:24:06Z |
| Unit suite | `bash tests/run.sh` | 0 | 8ab506620e6c509513dda52b0685d35fca82cc78 | 2026-10-14T11:33:35Z |
