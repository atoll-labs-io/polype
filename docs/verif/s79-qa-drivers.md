# Verification — s79-qa-drivers

Tree: 16dbd6689a2ae4c27bca9a6db0dd684febdde042

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Lint | `bash bin/po-lint` | asked by the plan; also run inside the suite by `tests/lint.test.sh` |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Not proven here
Whether a `qa` subagent actually receives the base directory of a preloaded skill, picks the driver files of the table, writes its by-products under `mktemp -d` and blocks on a dirty tree is prose followed by a model: the tests pin the phrases, not the behaviour. No real `/po-qa` run was made against this tree. Only `browser.md` exists; the other driver files of the table are left to s81, s82, s87 and s88, so a non-`screen` QA ends blocked until they land. No screen.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 2d0ed02376a74db080901c2c976d16ddf1b49d77 | 2026-10-08T15:37:14Z |
| Lint | `bash bin/po-lint` | 0 | 3b72452297f6143955767b77342e429d1f74154b | 2026-10-08T15:37:14Z |
