# Verification — s87-godot-scene-driver

[Story](../stories.md) · [Plan](../plans/s87-godot-scene-driver.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 54195fb45deb561da85a49aadd4b3425def54fac

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
The project has no type check, end-to-end or build command. The profile is checked against godot-xr-template only when the network (or `GODOT_TEMPLATE_SRC`) is reachable; otherwise the test skips loudly. Neither Godot nor Xvfb exists on this machine: the engine command, the virtual display and the capture script of the scene driver were never run here; the first real `scene` QA is their test.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 19e4270f72f4734ef6ff032aac9a6f1395ce1c75 | 2026-10-08T16:34:30Z |
