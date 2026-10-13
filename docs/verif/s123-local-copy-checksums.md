# Verification — s123-local-copy-checksums

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: bc1e739bf727fc9eb9b57dd91dc4c3fe6282c4d3

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

## Not proven here
No type check, end-to-end or build exists in this project. The tests run the installer only in scratch repositories; no real `install`, `update` or `remove` was run on Polype's root or on pecten and nautile, whose first `update` after this version performs the migration.
The fix run adds the read-order test with an old-format `.polype/checksums` and the `install`→`init` case without `remove`; it does not change how `check` behaves in a project that commits `.claude/` (refreshed copies stay listed until `update` runs), it only documents it. No cross-version scenario with two real installer versions committing alternately was run beyond that test's simulated old-format lines.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | b44a0c088117478f914cfd56a886679d6f3b74c8 | 2026-10-13T23:42:12Z |
| Unit suite | `bash tests/run.sh` | 0 | 84a2d92c2f33298c167ceccdee43c35682d2febf | 2026-10-13T23:51:55Z |
