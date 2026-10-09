# Verification — s99-throwaway-zone-holds

Tree: 3feb98759500dc845b60918410414f5e3d621a68

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Not proven here
- `.claude/` and `.polype/` still hold the old hook until the post-ship refresh; the tests run `method/hooks/po-bounds.sh` directly.
- Only gawk ran as the lexer's awk; other awks are not exercised.
- Bash 3.2 compatibility was not run (no macOS bash here); the code avoids `${x,,}` and associative arrays.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | ba9d25f8c3b922b78d6cf9e28ca4015859a7108d | 2026-10-09T12:54:15Z |
