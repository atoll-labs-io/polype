# Verification — s190-next-names-the-track

[Story](../stories.md) · [Plan](../plans/s190-next-names-the-track.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 0e8e6d725f61fee1c70718c86bd57add258c8222

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
| `tests/driver-next-action.oracle.test.sh` (s168's oracle) | `test_next_gives_one_action_per_lane` compares each lane's whole `next` object with `po next`'s entry (`{story} + .next`) instead of `{story, action, reason}`; its fixture gains `Story track: auto` and `Flow threshold: 2` (task 5) | a `plan` action now carries `track`: the old comparison dropped it, so `po state` could lose the track unseen; the new one is stricter, not weaker |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- This story's own oracle (`tests/next-names-the-track.oracle.test.sh`) is unchanged; the change to s168's oracle is in `## Oracle changes`.
- Fix run: a ready story whose entry is `ask` stays in `ready` (`tests/next-names-the-track.test.sh`); the wave-end rule of `po-drive.md` is model-read prose, not tested.
- `bin/po-version-check` reads HEAD, so it is run after the commit, not through `po-run`.
- The planner and driver prose (`planner_follows_the_track_it_is_given`) is a model-read rule: no test, judged in review.
- No type check, end-to-end or build exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 70344d52c74688e161fc4dbcda4b177273233b96 | 2026-11-18T10:40:27Z (404s) |
| Unit suite | `bash tests/run.sh` | 1 | 6e41ab05214c456cd039e8a3e22edb665ccc3e38 | 2026-11-18T10:58:43Z (691s) |
| Unit suite | `bash tests/run.sh` | 0 | 3dd51db9d11750daea348e8dfe6f057b53d548d8 | 2026-11-18T11:22:55Z (586s) |
