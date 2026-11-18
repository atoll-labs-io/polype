# Verification — s192-ship-reads-the-forge

[Story](../stories.md) · [Plan](../plans/s192-ship-reads-the-forge.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 6ff804063bf796e66bdc50b6860b04f495ccca17

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project; `tests/run.sh` builds `po` with `cargo build --release --locked` first, without warning |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- `ship_command_reads_the_value` is a model-read rule: no test, judged in review; only its word ceilings are checked (`po-ship.md` 2 700, `po-setup.md` 2 272).
- GitLab and Forgejo/Gitea are read through doubles only, never on a real instance (#75): `glab api -i`, `glab auth status --hostname`, `tea api --login <name> -i`, `tea logins list --output json` and its `name`/`url` fields are unverified flags; any failure there reads `unreadable`.
- No real forge was called: `gh`, `curl`, `glab`, `tea` are doubles in every test.
- The `X-Total-Count` header of the Forgejo/Gitea collaborator list is read through doubles only; a non-empty list without it reads `list-truncated`.
- Fix run 1 closes the two security findings of d-0043: held by `test_full_collaborator_page_is_unreadable` and `test_target_branch_is_one_path_segment`.
- The `(forge)` line rewrite stays prose in `po-ship.md` until s194.
- No type check, end-to-end or build exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 5a8e2a2c6a77850cce620575f23ca6de85382a09 | 2026-11-18T15:26:09Z (533s) |
| Unit suite | `bash tests/run.sh` | 0 | f46ed2955721d247e092fa6d949b69cb9b84c6b4 | 2026-11-18T16:16:33Z (457s) |
