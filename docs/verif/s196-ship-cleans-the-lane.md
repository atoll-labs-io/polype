# Verification — s196-ship-cleans-the-lane

[Story](../stories.md) · [Plan](../plans/s196-ship-cleans-the-lane.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 9e44a5f3c02c34e9a4ebc1c3d891a076e17f665e

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | deferred to ship |
| Build | — | deferred to ship |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
End to end and build at ship (none declared here). A `po ship clean` against a real forge and a real GitHub remote was never run, by order: every run used a throwaway repository with a local bare origin. Guard not bitten: the lease on the remote deletion (`--force-with-lease=<ref>:<head>`) races a push between `ls-remote` and the delete, which no test here can interleave; the tests prove the observed-head check, not the lease. The `branch-refused` refusal of `update-ref -d` (the head moved between the read and the delete) is unbitten for the same reason. The tree and patch-id conditions that recognise the remote head are each told apart (the tree one by a base that gained the story's own file, the patch one by an unrelated commit on the base). The security findings of d-0049 are closed in `po/src/ship/clean.rs` and `method/commands/po-ship.md`; the tests that hold them are `clean_keeps_a_branch_that_the_landing_does_not_hold`, `clean_keeps_a_remote_head_whose_parent_is_not_on_the_base` and `clean_compares_the_change_of_a_remote_head_byte_for_byte`, each bitten once by disabling its guard (the byte-for-byte test once for each of its two conditions). The method cannot yet list a story branch left without a worktree: `po next` and `po state` read lanes from worktrees, outside `Owns`. The two dirty-worktree guards (`po`'s `git status` and git's own refusal) are told apart by the oracle's `dirty-worktree` name and by the locked-worktree test (`worktree-refused`).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | b0c47195b491dc618b7100401bec2365ec1ec452 | 2026-11-20T11:33:05Z (445s) |
| Unit suite | `bash tests/run.sh` | 1 | 5dbfffe958b988c6586a0151b4de7bad0e5d120a | 2026-11-20T22:19:19Z (475s) |
| Unit suite | `bash tests/run.sh` | 0 | cb0c271398ad3e188946a2cc4edfafef46f181df | 2026-11-20T22:27:33Z (473s) |
