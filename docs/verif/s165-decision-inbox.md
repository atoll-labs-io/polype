# Verification — s165-decision-inbox

[Story](../stories.md) · [Plan](../plans/s165-decision-inbox.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 7b04c66af11fca7a969cb0ae4abf4bdc1d045d16

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`); `tests/run.sh` builds `po` with cargo before the suite, which type-checks the Rust |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- `rules_send_every_stop_to_the_inbox` and `provisional_inbox_is_gone`: judged in review by reading (only the word ceilings are tested).
- The docs of task 8 (`docs/interface-agent.md`, `docs/installation.md`): judged by reading.
- `po inbox add` on this repository itself: its main checkout's `.gitignore` gains `.polype/inbox/` only once the story ships, so until then `po inbox add` here answers `inbox-not-ignored`, as it should.
- CI on the pull request runs at ship.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 84f4ed7db78f04f6d0573ab18d985e0d8f3eb739 | 2026-11-13T14:23:09Z |
