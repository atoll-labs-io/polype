# Verification — s191-drive-takes-one-story

[Story](../stories.md) · [Plan](../plans/s191-drive-takes-one-story.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 24db2cb8892f6b014074efe31482cd4ad784874c

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- `drive_takes_an_id` and `nothing_only_they_said_is_lost` are model-read rules: no test, judged in review (the table `## Rules the two commands carried` of the plan).
- `bin/po-lint method` was run by hand (no breach in 25 files) and is also run by the oracle inside the suite.
- The installed copies under `.claude/` and `.polype/` still hold both commands until the next install; not this story's.
- No type check, end-to-end or build exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | ceddbbdb97eab835ed9b533ce9ebe5912967d179 | 2026-11-18T12:03:46Z (412s) |
| Unit suite | `bash tests/run.sh` | 0 | f1d66db7de885e593dd6d02b598ab30e764ef60f | 2026-11-18T12:35:33Z (488s) |
