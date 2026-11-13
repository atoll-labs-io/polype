# Verification — s159-ci-on-every-pr

[Story](../stories.md) · [Plan](../plans/s159-ci-on-every-pr.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: db1b7530a6bac1bf1414c9efb4c831ba59f66d29

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- That `.github/workflows/ci.yml` runs green on a GitHub hosted runner. The first run (pull request, 714 passed, 1 failed) failed `quickstart_runs_as_written` on the detached merge commit; the fix run checks out the pull request head as a local branch. Proven locally only: from a temp clone detached on a commit no branch holds, `readme-onboarding.test.sh` fails 1; after `git checkout --force -B <branch> refs/remotes/origin/<branch>` (what `actions/checkout` runs for a branch `ref`, read in its source at the pinned commit) it passes 6. The next `suite` run on the pull request is the proof.
- The jq step on a Forgejo runner image (root, no `sudo`): not run, no Forgejo runner here.
- `ship_waits_for_green_checks` and `missing_setting_changes_nothing` (the `/po-ship` wait and the missing-line exception) speak to a model: no test, the reviewer judges `method/commands/po-ship.md` by reading; `po-eval` candidates (#208).
- `docs_say_how_to_require_the_check`: read by the reviewer, `docs/ci.md`.
- The ruleset that makes `suite` required on `main` is a person's gesture, not done here.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 338d07e6f5bc44611a20b4cdc5997a44a70cdf1c | 2026-11-13T09:18:44Z |
| Unit suite | `bash tests/run.sh` | 0 | 7d6cae701a8d624a068cd01f9489f1d9a6d472f7 | 2026-11-13T09:41:20Z |
