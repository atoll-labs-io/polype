# Verification — s160-intake-title-bounded

[Story](../stories.md) · [Plan](../plans/s160-intake-title-bounded.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

Tree: 5dbb64f87b02ddbeb4744f0e45225ab1d31a40fc

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | deferred to ship |
| Build | — | deferred to ship |

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

No oracle file changed (cksum `1150097721 5270` kept).

## Not proven here
Word bounds: `wc -w` po-intake.sh 1615 (main 1623), po-gate.sh 5758 (main 5767). The awk exit 2 to 3 move has no deterministic test (needs a read race). `docs/harnais.md:15` read by eye. Invalid UTF-8 in the failing line is not covered.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 7c621948b7d1de2537744a079819c76fc8bf8843 | 2026-11-13T09:15:23Z |
