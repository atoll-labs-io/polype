# Verification — s114-reuse-ladder-eval

Tree: 34122d9c924b4156cba211e177f1b892f9b177a6

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Not proven here
- The rates themselves: no real `claude -p` ran. Whether `claude -p` starts from an empty `CLAUDE_CONFIG_DIR` with only an environment token, and how the two arms score, come from the person's paid run after ship (`bin/po-eval --control --repeat 3`).
- Bite targets (mutations) are the reviewer's job.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 63f37414382d35946a28083bf937a1f415d5dc27 | 2026-10-13T15:37:37Z |
