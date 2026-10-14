# Verification — s106-framing-through-pr

[Story](../stories.md) · [Plan](../plans/s106-framing-through-pr.md)

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 3b54a461230d9007bceb92d4f2c9d16d28e4e1ff

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
The tests are text checks on method files: they prove the wording of the framing commands and of `/po-research`, not that a real framing landing builds its commit beside the checkout, opens a pull request and fast-forwards the root. That is proven only by the first real framing command run in pr mode (and one in local mode on a repository without a remote). The root fast-forward after staging the framing paths was checked by the research in a throwaway repository, not re-run here. No type check, end-to-end or build command exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | ae6c91de78653ab69587da6a08383e224c991c6f | 2026-10-13T12:44:00Z |
