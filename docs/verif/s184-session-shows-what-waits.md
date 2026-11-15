# Verification — s184-session-shows-what-waits

[Story](../stories.md) · [Plan](../plans/s184-session-shows-what-waits.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 9b347a04c44eb65485ca090b5a1a8f566b5d58d1

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |
| `tests/verbs-read-project-context.oracle.test.sh` (oracle of an earlier story) | `normalised` also drops `.answered`, its comment names the field s184 adds | plan task 4: the test pins the whole `po state` object, and `answered` is a field this story adds |
| `tests/state-carries-session-lines.oracle.test.sh` (oracle of an earlier story) | `SESSION_LINES` puts one `<id>: decision pending → po inbox <id>` line per `.waiting` id first in the waiting list | plan task 4: the test mirrors the hook's lines, and the hook now lists pending decisions first |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
The forge `suite` check on the pull request, where `bin/po-version-check` compares with `origin/main`; locally the unit suite runs before the commit, so its version-check and onboarding tests see the committed HEAD of `main`, not this story. `po state` at this repository's root reading `stories-review: yes` is proven only after the ship (`on_target` reads `main`); before it, `this_repository_reads_reviewed` reads the working tree's files in a scratch repository. The interface bullet of `docs/interface-agent.md`: judged by the reviewer reading. The installed `.polype/hooks/po-session.sh` is unchanged by design until the copies are refreshed.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | fa0db476447d9443409e09f2f6b467d8d974b6f9 | 2026-11-15T23:27:37Z (470s) |
