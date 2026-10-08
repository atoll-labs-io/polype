# Verification — s62-bounds-scan

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 0042e5863b15e84aac91287a5dadd7728a38edc1

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

## Not proven here
- Not verified: BWK awk (the macOS `/usr/bin/awk`) and mawk. The lexer was run only under gawk 5.4.1, including `gawk --posix --lint`, which flagged no extension. Neither awk is installed on this machine; a person must run `bash tests/run.sh bounds.test.sh` on macOS and on a mawk system.
- Not verified: macOS `/bin/bash` 3.2 (`IFS=$'\037' read -ra`, `for ((…))`, `[[ =~ ]]` through a variable). Only bash 5 ran here.
- The hook is exercised on scratch repositories only. Its behaviour as the installed `.polype/hooks/po-bounds.sh` on a real lane is not run here: the copy installed in this repository is still the old one until a refresh.
- No type check, end-to-end test or build exists in this project.
- Fix run (C1, M1): the forms of the review's C1/M1 lists were probed in mode implementer only; mode qa shares the lexer and was exercised by its own tests, not by those forms. Still allowed without being read: a script file (`bash x.sh`, `bash < x.sh`), a process substitution handed to a shell (`bash <(…)`), a quoted `git` behind a wrapper this hook does not know or behind a wrapper's option argument (`sudo -u x "git" push`).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 4a9ed16425c5d3a4072e43f3e991815a194bb689 | 2026-10-08T10:44:19Z |
| Unit suite | `bash tests/run.sh` | 0 | dbe3ea8f2c10ddfb25d8fc9cad52ef297777c98d | 2026-10-08T10:54:51Z |
