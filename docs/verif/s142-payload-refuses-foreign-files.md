# Verification — s142-payload-refuses-foreign-files

[Story](../stories.md) · [Plan](../plans/s142-payload-refuses-foreign-files.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 2efcd690e6754292698f7653bda54803f4f3dcef

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
No type check, end-to-end or build command exists in this project (`—`). Existing tests changed with the rule: `tests/install-collisions.test.sh` (`set_aside_is_explicit_and_undone_global` no longer sets aside `polype/bin/polype`; that collision is now covered by `foreign_payload_file_stops_install`), `tests/payload-kept-outside.test.sh` (the "aside" home of `remove_leaves_kept_copies` writes its `.before-polype` by hand after the install, as an older install left it), `tests/drop-keeps-modified.test.sh` (ADR-0088 now `superseded-by: [ADR-0092, ADR-0095]`). Not exercised: a real chezmoi sync between two machines (simulated by `cp -r` between two throwaway homes), and a `~/.claude` that is itself a symlink (the physical-path compare is only reached through the PATH-link test of `tests/global-install.test.sh`).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | b8eabac4ad22c208b76d416e29e17391b96124cf | 2026-10-18T17:22:19Z |
