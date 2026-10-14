# Verification — s81-scenario-driver

[Story](../stories.md) · [Plan](../plans/s81-scenario-driver.md)

Tree: f7edea3fbb96538f43684b567e8aba382778fb7d

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

## Not proven here
Whether a `qa` subagent actually copies the tracked files into `mktemp -d`, starts a service on a free loopback port under `setsid`, runs an invalid input per criterion, redacts secrets and blocks on a new path in `status --porcelain --ignored` is prose followed by a model: the tests pin the phrases, not the behaviour. No real `/po-qa` run was made against a `command` or `endpoint` story. `qa.md` does not list `Install` and `Build` in its `Reads settings:` line (outside `Owns`, follow-up noted in the research). No screen.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | ba8e713aec8cb48ea64225fa9c896ae7be277393 | 2026-10-08T15:50:09Z |
