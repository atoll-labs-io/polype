# Verification — s188-orphan-copy-survives

[Story](../stories.md) · [Plan](../plans/s188-orphan-copy-survives.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 2a997467f96d41ebe8863b020b4144350bb85b06

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
A git clone that carries `.polype/agents-md-aside` without the copy (the copy is not committed) is only reasoned about: the record is deleted on the next run without a message, no test drives it. No type check, end to end or build exists in this project. Two existing assertions moved with the clause they check (ADR-0088's `superseded-by` line, which task 6 extends; lead's option (a), `Owns` widened on main d8f3b26): `test_adr_records_the_choice` (`tests/drop-keeps-modified.test.sh:184`) and `test_adr_records_the_payload_rule` (`tests/payload-refuses-foreign-files.test.sh:201`) now expect `superseded-by: [ADR-0092, ADR-0095, ADR-0128]`; nothing else in those files changed. The reviewer's bite checks (marker condition restored, record compared by existence only) are left to the review.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | 04362f219329acecbd20568f084ed291ddc3f4a0 | 2026-11-16T11:38:14Z (460s) |
| Unit suite | `bash tests/run.sh` | 0 | e7565bbf8975a7065372074c02f54bbf40a59835 | 2026-11-16T12:04:58Z (426s) |
