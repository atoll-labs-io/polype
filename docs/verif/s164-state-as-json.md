# Verification — s164-state-as-json

[Story](../stories.md) · [Plan](../plans/s164-state-as-json.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: dfe0be37eaa25554be949f87f071f0988f4a675c

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | builds `po` with cargo first, then every `tests/*.test.sh` |
| Type check | — | no such command in this project (`Typecheck: —`); `cargo build` in the suite's first step type-checks the Rust |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- The panic hook's `internal` reply: no test makes `po` panic; judged by reading `po/src/output.rs`.
- The installer's `cargo could not build po` branch: no test breaks the crate; judged by reading `build_po` in `bin/polype`.
- `po state` under one second on a repository with many lanes: timed only on this repository (oracle) and on the seven-lane fixture of `test_lane_stage_follows_the_gates`.
- The CI runner (`.github/workflows/ci.yml`, unchanged): that `ubuntu-latest` builds the crate with its own cargo is seen only when the pull request's checks run.
- The docs of task 8 (`docs/interface-agent.md`, `docs/installation.md`): judged by reading.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | 4bd2ecbca390137766445f3b9cae1135be9fa320 | 2026-11-13T13:17:43Z |
| Unit suite | `bash tests/run.sh` | 0 | 9627d288d3bfa6bd3627dc3d0893a2ed75882866 | 2026-11-13T13:34:22Z |
