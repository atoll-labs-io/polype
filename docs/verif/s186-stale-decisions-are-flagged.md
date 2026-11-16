# Verification — s186-stale-decisions-are-flagged

[Story](../stories.md) · [Plan](../plans/s186-stale-decisions-are-flagged.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 7c25b288b0b2bb509c9991e81bf039988edec01c

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
- `contract_says_held_until_consumed` and the rest of the `docs/interface-agent.md` changes: a text no script reads, judged in review.
- The stale mark on a project whose `Target branch` has an `origin/<target>` copy: `Landed::read` is reused unchanged, and the tests land stories on the local `main` only.
- `method/hooks/po-session.sh` does not show the mark (out of `Owns`, out of the criteria).
- Formatting and lint: none configured in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 5a15bba3b6adca6b7cfb897107cb8218c6ba5b16 | 2026-11-16T09:50:16Z (416s) |
