# Verification — s161-installer-leftovers

[Story](../stories.md) · [Plan](../plans/s161-installer-leftovers.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 53fb92e7073e4e80553940fa26e72436ad87f8c9

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- The new prose of `method/AGENTS.md` `## Installed files` (the `~/.claude/polype/` exception to `--set-aside`) and of `docs/installation.md` (the two kept-copy stops, the root-only state files, the trace of a failed `--set-aside` run, the orphan `AGENTS.md.before-polype`, a failed `remove --global`): case 3 of the plan, judged by the reviewer by reading; only the word count of the section is tested.
- The trap's "still held" branch and its refusal to overwrite an existing target: checked by hand in a scratch `HOME` (a `mv` shim refusing the put-back), not by a test.
- An exit by signal (`kill -9`) bypasses the trap, as ADR-0112 accepts.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | 8a9acc17e180bd3e649fbc9734a7501314f23d69 | 2026-11-13T09:53:41Z |
| Unit suite | `bash tests/run.sh` | 0 | 98f2ff9e09de5cc07b1cfa6c3b8b1653c85eea3c | 2026-11-13T10:23:38Z |
