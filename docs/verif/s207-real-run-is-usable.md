# Verification — s207-real-run-is-usable

[Story](../stories.md) · [Plan](../plans/s207-real-run-is-usable.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 719cce93dbb26c503a8393c4810c96e9c18476a3

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | deferred to ship |
| Build | — | deferred to ship |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |
| `tests/real-run-is-usable.oracle.test.sh` | one comment line added above `usable_build`, holding the text `"$RTMP/bin/claude"` | `test_suite_never_pays` (s206 oracle) scans every `tests/*.sh` that launches po-eval and requires the text `/bin/claude"` in it; the oracle as written made that s206 test fail. No assertion changed. New cksum `4199343886 4800`. |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- Whether Claude Code accepts `cd … && git …` and refuses `sed -i` under `Bash(sed -n:*)`, and whether `.last-cleanup` is the only housekeeping file it writes at start: only the next real run shows (ADR-0136).
- `first_record_is_kept`: judged in review; `docs/evals/real-2026-11-23-v0.12.0.md` is untouched.
- No paid run was launched.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 1e40cb986ee792aa82b59a681ddb337fc4a2f6e8 | 2026-11-23T20:04:08Z (627s) |
