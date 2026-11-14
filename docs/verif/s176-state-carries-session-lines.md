# Verification — s176-state-carries-session-lines

[Story](../stories.md) · [Plan](../plans/s176-state-carries-session-lines.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 707e7b846e209a5b0e1c84d27c63e962aeb2b048

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`); `tests/run.sh` builds `po` with `cargo build --release --locked` before the suite |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

## Not proven here
- `contract_says_the_new_fields` (`docs/interface-agent.md`) has no test: the review reads it against the plan's field table.
- No end-to-end, build or type-check command exists in this project; the Rust compiler runs as part of `tests/run.sh`, and its only warning (`not_built` never used, `po/src/output.rs`) predates this story.
- The two failing `Unit suite` rows ran on uncommitted code: `tests/readme-onboarding.test.sh` clones `file://$ROOT` (the branch's HEAD, then `main`'s sources) and its `install --global` builds `po` into the suite's shared `CARGO_TARGET_DIR`, which cargo then takes as fresh, so every later test ran `main`'s `po`. The passing row ran after the story commit, on the same code outside `docs/`.
- Leading zeros in `Fix loop:` print raw in po-session and as integers in `po state`; no fixture covers them (research, Traps).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | 76c91f60255bac8a9fc03ac1b37237b5305421e2 | 2026-11-14T11:37:07Z |
| Unit suite | `bash tests/run.sh` | 1 | 76d4c006915d87c1a5ae15fa53f2d4358072047c | 2026-11-14T11:52:43Z |
| Unit suite | `bash tests/run.sh` | 0 | 37c610aec5300cb8e5e1fc31b6853374493d97e8 | 2026-11-14T12:04:10Z |
