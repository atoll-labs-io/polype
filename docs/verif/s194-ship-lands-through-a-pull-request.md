# Verification — s194-ship-lands-through-a-pull-request

[Story](../stories.md) · [Plan](../plans/s194-ship-lands-through-a-pull-request.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: e5a0ce4e0ea7dd3b5eaec7a5fcec3dd3e861398b

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | `Full suite: execute-end`; builds `po` with `cargo build --release --locked` first |
| Type check | — | no such command in this project (`Typecheck: —`); the Rust compiler checks types in the suite's build |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |
| `tests/ship-lands-through-a-pull-request.oracle.test.sh` | The gh double only: a pull request it answers carries `isCrossRepository` and `headRepositoryOwner` (origin's own unless its file says otherwise) and keeps a `headRefOid` its file names; `pr list` returns every pull request of the head, no longer the first. No assertion and no test function changes. | The security finding of d-0046: the task tests `test_only_pull_requests_from_origin_are_used` and `test_pull_request_on_another_commit_is_not_reported_ready` need the double to answer these fields. |

## Not proven here
- The lease of `git push --force-with-lease=refs/heads/story/<id>:<observed>` (and the same form on `framing/ship-confirmation`): nothing in a test can move origin between `git ls-remote` and the push, so no test fails when the lease is removed. The reviewer checks its form by reading `po/src/ship/push.rs`, as the plan says.
- `GIT_TERMINAL_PROMPT=0` in `po/src/ship/git.rs`: no test reaches a credential prompt (the test origin is a local bare repository), so removing it fails no test.
- `--repo github.com/<owner>/<repo>` on every `gh` call: the gh double ignores `--repo`, so dropping it fails no test; checked by reading.
- The 30-second default of `PO_SHIP_POLL_SECONDS`: the tests run at 0; covered by reading (`POLL_SECONDS`). Likewise the bound of 10 readings of a pull request's head before it is reported ready (`HEAD_READINGS`): no test counts them.
- The fields `isCrossRepository` and `headRepositoryOwner` of `gh pr list`: the double answers them as gh documents them, never a live call.
- A real GitHub: `gh pr list/create/view/checks/merge` are doubled; their JSON fields and the `--body-file -` of the draft follow gh's documented interface, never a live call.
- `description_stays_with_the_model`: a model rule, judged in review. Its word ceiling, at least 300 words fewer than the 2 298 before (≤ 1 998, as the criterion reads since e2a5334), is checked by `test_ship_words_go_down`: `po-ship.md` holds 1 975 words. That threshold lives in the task test file, not in the oracle. After the fix run, `po-ship.md` holds 1 993 words.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | db8aa9f028a39410df095829cd002a34f2cb957d | 2026-11-19T14:24:11Z (474s) |
| Unit suite | `bash tests/run.sh` | 0 | 47d369d4daa043cd8b8bc3ff809b1d5dc0b66179 | 2026-11-19T14:44:21Z (475s) |
| Unit suite | `bash tests/run.sh` | 0 | 10a90c99e168c247200add96c4b9b1a701d7c6e8 | 2026-11-20T09:57:24Z (439s) |
