# Verification — s185-ship-order-and-closed-pr

[Story](../stories.md) · [Plan](../plans/s185-ship-order-and-closed-pr.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: ed9b3597b67e2d5ca0c9c17741ad4d61d2300cd8

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`); `cargo build --release --locked` inside `tests/run.sh` is the compile check |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- `po next --remote` against the real GitHub API: every forge answer in the tests comes from a `PO_GH` double, so the shape of `GET repos/{owner}/{repo}/pulls?head=…&state=all` is taken from the research, not observed.
- `drive_no_longer_decides_it`: read by a model, judged in review; only its word ceiling is checked here.
- Formatting and lint: none configured in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 2844a11b3e7183b87c2509839176be4c841e9afb | 2026-11-16T00:03:12Z (377s) |
| Unit suite | `bash tests/run.sh` | 0 | b3479dd034c8ed2e3498dd2a25683a3ee6628b35 | 2026-11-16T00:15:00Z (374s) |
