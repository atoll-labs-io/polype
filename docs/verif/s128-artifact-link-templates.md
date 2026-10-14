# Verification — s128-artifact-link-templates

[Story](../stories.md) · [Plan](../plans/s128-artifact-link-templates.md)

The link line under the title is part of this template: it is copied with it, never edited, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Tree: 5a2a3f4d8b7a31c6b0856e17355048e977f9cf67

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Not proven here
Nothing runs the templates through a real story cycle; the first new artefacts after this commit will show it.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 13f8d0a314ec9a6c75b643f3b42b7e6a82bf6952 | 2026-10-14T09:04:40Z |
| Unit suite | `bash tests/run.sh` | 0 | adb49a93a9392bed77aa644a489d3dc51724fe51 | 2026-10-14T09:10:32Z |
