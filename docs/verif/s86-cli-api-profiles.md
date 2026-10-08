# Verification — s86-cli-api-profiles

Tree: 55a5e9ad6fe3c547c37c073055a22ef32f084641

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Not proven here
The `npx tsc --noEmit` command of the hono-api profile was not run (no install on an untrusted clone). The grounding test needs the network and skips with a message when a starter is unreachable; here it ran against fresh clones. `bin/po-lint` ran clean separately.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 34ab9d68c9690de0ada04332d918447b852cfce9 | 2026-10-08T16:04:51Z |
