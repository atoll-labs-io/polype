# Verification — s98-bounds-messages

[Story](../stories.md) · [Plan](../plans/s98-bounds-messages.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 37e9b657c745f90e721b529a1b13df3031d1671d

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
- Live sessions: `.claude/` and `.polype/` still hold the old hook until the post-ship refresh; the tests run `method/hooks/po-bounds.sh`.
- Whether a real implementer session reaches for a `file://` clone after the refusal of `cd /tmp && git clone /local/path x` (ADR-0072, accepted cost): not exercised.
- The `{name}` drop was run under gawk only (also checked with `gawk --posix`); BWK awk and mawk are not installed here.
- No type check, end to end or build: the project has none of them.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 5a61138158d9d500aeeb0d9fac65f7d358b331cc | 2026-10-08T18:03:06Z |
