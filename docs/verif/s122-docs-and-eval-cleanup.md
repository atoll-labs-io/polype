# Verification — s122-docs-and-eval-cleanup

[Story](../stories.md) · [Plan](../plans/s122-docs-and-eval-cleanup.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 7d2437c9c2519e955457042421765fbdd7364c0d

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
No type check, end-to-end or build exists in this project. The resume-row change in `method/commands/po-drive.md` and `method/commands/po-status.md` is method text read by an agent: the tests check its wording, not a driver acting on it; the gate behaviour it mirrors is covered by `tests/session-and-gate-checks.test.sh`. The installed copies (root `AGENTS.md`, `.polype/hooks/po-gate.sh`) are not refreshed here; the lead does it after ship. No real `bin/po-eval` run against a model (fake `claude` only).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | f3c6449a76c52121986c51e72c962ffc1e89c409 | 2026-10-13T22:46:07Z |
| Unit suite | `bash tests/run.sh` | 0 | 66286124d85c14938d6084fabd35c23b8dbd1ce1 | 2026-10-13T22:51:41Z |
| Unit suite | `bash tests/run.sh` | 0 | 03a7e01182300995e6a0dff5b4e0a8a5b845fe77 | 2026-10-13T22:57:05Z |
