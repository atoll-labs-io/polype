# Verification — s168-driver-next-action

[Story](../stories.md) · [Plan](../plans/s168-driver-next-action.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 0fb60352334aadf8d6b11ff0b3f5c8842b7969e7

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`); `cargo build` inside `tests/run.sh` type-checks the crate |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |
| `tests/driver-next-action.oracle.test.sh` | `test_blocked_on_shape_asks_and_never_fixes`: two lines `W="$F/.worktrees/s01-alpha"` and `W="$F/.worktrees/s02-bravo"` added before its two `review_in` calls; no assertion changes (cksum now `2077968519 16821`) | `review_in` writes into `$W`, which after the loop still points at s02-bravo's worktree, so s01-alpha's review landed in the wrong lane and s01-alpha routed `review / no review`: the test checked a state other than the one it describes |
| `tests/state-as-json.oracle.test.sh` (s164's oracle, plan task 7) | `ready`, `held` dropped from the fields asserted `null`; `lanes[].next` asserted an object with `action` and `reason`; the `not-built` loop runs on `run continue` only | this story builds `po next`, `ready`, `held` and `lanes[].next`, which those three assertions pinned as not built |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- Row 17 of `## Resuming` (a closed pull request) has no fixture: it needs the forge, which `po` never asks.
- The review order rests on the review file's modification time; a copy or a `touch` of a review reorders ships, as the plan's pivot 1 accepts.
- L3's `no po-gate` reason and an unreadable `QA stage` value (other than missing) are reached by no fixture.
- No `cargo test` exists; every check runs through the built binary in `tests/run.sh`.
- The first Unit suite run (exit 1) failed on `state_prints_one_json_object` only: `tests/readme-onboarding.test.sh` clones `file://$ROOT` (the committed HEAD, without this story's code) and its install rebuilds `po` into the shared `CARGO_TARGET_DIR`, so the test files after it ran the old binary. Reproduced with `bash tests/run.sh readme-onboarding.test.sh state-as-json.oracle.test.sh`. The suite was therefore launched again once the code was committed, where the clone builds the same code; a defect of the suite, outside this story's `Owns` (issue 254).
- Fix run (forge check and review finding `lane.rs:133`): the fix-run suite ran before its commit. The only code change since the committed HEAD is the fix-loop count in `po/src/next/lane.rs`, which `tests/driver-next-action.test.sh` exercises before `readme-onboarding.test.sh` rebuilds `po`; no later test file covers a remote target ahead of the local one.
- `test_next_on_this_repository_is_fast_and_writes_nothing` was checked on a CI-like checkout (a fresh repository fetching the story branch, `HEAD` detached, no `main` nor `origin/main`): `po next` answers `actions`, `ready`, `held` `null` and the test passes. The forge run itself is not replayed here.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | 662dab70a15c9c41d4f4578e16c5550d2a3c3a08 | 2026-11-13T18:05:40Z |
| Unit suite | `bash tests/run.sh` | 0 | b86a9ea48c9ed0905d1ddbbcb9e757699890f3e1 | 2026-11-13T18:12:36Z |
| Unit suite | `bash tests/run.sh` | 0 | 32f4f5bce10a92db21e266e2e9738c4398d36f62 | 2026-11-13T18:37:39Z |
