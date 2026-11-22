# Verification — s201-routing-phrase-tests-retired

[Story](../stories.md) · [Plan](../plans/s201-routing-phrase-tests-retired.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 56327b08bf5facdbbfd03da8abf27f40178dfd3e

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
| `tests/routing-phrase-tests-retired.oracle.test.sh` | The reader's two markers start with a NUL (`\0@@FILE `, `\0@@FUNCS`), in `script_launches` and `LAUNCH_READER`. `test_no_script_lost_its_tests` gains a bite on a throwaway copy: a file that sources the helpers, as `docs/harnais.md` says, has its launch counted and its removal named, and this oracle's own `test_contract_tests_stay` is counted as launching `po-lint`. New cksum `511014532 17744` (with the row below). | Review fix loop 1, major at `:96`: the literal `@@FILE ` sat inside `LAUNCH_READER` and the body of `script_launches`, so every file that defines or sources the helpers was cut and none of its tests read. No variable or function body can hold a NUL. |
| `tests/routing-phrase-tests-retired.oracle.test.sh` | New `LOWERED_COUNTS` (empty), one line `<script> <count on the base> <count after> <story id>` per allowed drop; `scripts_kept_their_tests` lets a drop through only for a line matching the base count exactly, and names the story. The bite: a matching line passes and is named, a line for another base count fails. Same cksum `511014532 17744`. | Review fix loop 1, minor on `docs/harnais.md`: the count had no per-script allowance, so a story rightly removing a script's test had to edit the shared helpers by hand. A line keyed to the base count is explicit in the diff and goes inert once the story ships. |
| `tests/routing-phrase-tests-retired.oracle.test.sh` | A `LOWERED_COUNTS` line is read only while no commit of the base ref (the one `scripts_kept_their_tests` is given) has a subject starting with `<story id>: `, the landing commit `/po-ship` writes; the new helper `story_landed` compares that prefix as a fixed string (awk `index`, no regex built from the id, subjects only). A landed line allows nothing, silently. The "after" field is exact (`$3 == n`), and a line whose second or third field is not a non-negative integer allows nothing. `test_no_script_lost_its_tests` gains two assertions: a line with `-` as its count after does not let the drop through; after `s999-lowered: …` lands and `s998-back` brings the count back, a new drop under the same line is refused. New cksum `1727973062 19069`. | Review fix loop 1, major at `:175`: a line keyed only on the base count came back to life whenever the base passed through that count again, so a later story could drop a launch silently. Minor at the same line: the "after" field acted as a floor and accepted a malformed `-`. A landed line does not fail the test, because its own story cannot delete it. |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- The two model-read criteria, `kept_assertions_have_a_reader` and `journey_covers_what_left`: the reviewer judges them by sampling `## Classification` of the plan.
- The landed-line rule was proven by the oracle's own throwaway repository inside `test_no_script_lost_its_tests`, not by a separate probe: `po-bounds` refuses the implementer a `git commit` outside a `story/<id>` worktree, temp dir included. The floor case (a line `3 0` against a real count of 2) is not exercised by a test.
- The launch count is static: it compares how many test functions name each script, not that those lines run or assert anything. Its remaining blind spots (a helper sourced inside a test function, a launch in a single-quoted `bash -c`, a `python3 - <script>` that only reads counted as a launch, heredoc bodies and expanded variable values counted as launches) are listed in `docs/harnais.md`, not fixed.
- The five human checkpoints and stops of the review's second major stay model-read only. Decision d-0051 is answered, option a: the five rules stay with the model and s206 names them (framing commit `5dc9fc4` on main).
- No type check, end-to-end or build exists in this project. `bin/po-lint method` was run by hand and is clean; `test_contract_tests_stay` runs it again inside the suite.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 336aff059ba8c662b33dd71e1f69932167b833d4 | 2026-11-21T12:54:23Z (477s) |
| Unit suite | `bash tests/run.sh` | 0 | af876ee22aa2870693f88c0b1da20753597b18a3 | 2026-11-21T13:14:59Z (538s) |
| Unit suite | `bash tests/run.sh` | 0 | 19bce7fcb9d9d141219712c6708cbfb3a8251f35 | 2026-11-22T10:29:42Z (585s) |
| Unit suite | `bash tests/run.sh` | 0 | 643441b26f6197b16778610cdae3f5ce3ccd2df2 | 2026-11-22T10:41:12Z (639s) |
