# Verification — s61-bounds-owns

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 83ae5cda5e8edecf91255fe59c829e5e927f3d40

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

## Not proven here
- No type check, end-to-end or build exists in this project.
- The hook is exercised on scratch repositories only; its behaviour on a real lane (the installed `.polype/hooks/po-bounds.sh` refreshed by an install) is not run here.
- `/po-drive` and the review's ownership check still read `Owns` without globs (outside this story's `Owns`, noted in ADR-0038).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 1c13c746ae2273091e8f3f55cd9ac059bf11c80a | 2026-10-08T10:24:16Z |
