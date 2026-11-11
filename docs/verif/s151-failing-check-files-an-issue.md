# Verification — s151-failing-check-files-an-issue

[Story](../stories.md) · [Plan](../plans/s151-failing-check-files-an-issue.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 5be6464c9a8e7b444b275ea73fb5d4526863ac4a

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
No real tracker is reached: `gh` and `task` are stubs in every test, so the exact behaviour of a live `gh issue create`, `gh label create` and `task add`/`annotate` (including taskwarrior's handling of a multi-line annotation) is unproven. The GitHub Actions and systemd examples of `docs/harnais.md` were not run on a scheduler. Interleaving of stdout and stderr in the combined capture is best effort (two `tee -a` on one file). The pre-commit secret scan's behaviour after the matcher refactor is covered by `tests/gate.test.sh` only. Formatting has no check here.

Verification status: complete
## Runs

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | bd7544fbd0b183bab2aeebb22bd3c838816dc2bb | 2026-11-11T22:26:08Z |
