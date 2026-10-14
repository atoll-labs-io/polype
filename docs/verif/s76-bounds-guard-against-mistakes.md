# Verification — s76-bounds-guard-against-mistakes

[Story](../stories.md) · [Plan](../plans/s76-bounds-guard-against-mistakes.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: c6aa77ed22ba3afb31f7b7da46d6ef1cbde5a194

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
The hook is fed JSON by the bash tests, never wired into a live Claude Code session here; the installed copies (`.claude/`, `.polype/`, root `AGENTS.md`) are refreshed after ship. Lexer behaviour under BWK awk and mawk is not run here (only the local awk).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 0f9dc9879390cb4b7c4de981eb0b5844fd8a8bb0 | 2026-10-08T13:03:39Z |
