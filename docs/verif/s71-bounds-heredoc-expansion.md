# Verification — s71-bounds-heredoc-expansion

[Story](../stories.md) · [Plan](../plans/s71-bounds-heredoc-expansion.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 3e553c50c3afc7d038343e9698c19ac3120806a8

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
The lexer ran under gawk only: BWK awk (macOS) and mawk are not available on this machine and stay unproven, as for s62. The unescape was compared with bash's own `cat <<EOF` rendering on throwaway data (`\\$X`, `\\\``, `\$X`, `\``, `\<newline>`, `\n`, `\\\\`, `\"`): identical apart from variable expansion, which the reader does not do. No type check, end-to-end or build in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 40c3ef57650938fe54c9714717fdb0b0b52cebcd | 2026-10-08T12:06:52Z |
