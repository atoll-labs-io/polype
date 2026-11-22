# Verification — s204-framing-and-installer-phrase-tests-retired

[Story](../stories.md) · [Plan](../plans/s204-framing-and-installer-phrase-tests-retired.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 23c4c331f581b72d8e556db3e921c35e9984ed35

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
| `tests/framing-and-installer-phrase-tests-retired.oracle.test.sh` | `S204_KEPT` adds `distribution-wiring.test.sh test_rules_point_at_the_installer`; `S204_KEPT_LINES` adds the base line restored in that function and the base line restored in `hooks-installer-docs-cleanup.test.sh test_hooks_say_what_they_do_scan_reads_the_base` (231 → 233 lines). cksum `590842029 32692` → `3879645666 32911`. | Fix run 1, decision d-0054 under d-0052: two security assertions removed by the first run come back word for word from `bb07953`, and the oracle pins them like every other **S** line. |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
`po-lint` on `method/` was run by hand (`bin/po-lint method`, no breach) and is not a recorded check. `po-gate floor-guard` reads the committed story branch, so it was run after the commit, by hand. `kept_assertions_have_a_reader` and `no_phrase_test_is_left` are model-read: the reviewer judges them, and `docs/harnais.md` is a document no test reads. That a model follows the framing prose whose tests were removed is left to s206's real run.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 25eb9d3ddc48f98418bc40c7ef2834aee44f06f5 | 2026-11-22T18:52:04Z (629s) |
| Unit suite | `bash tests/run.sh` | 0 | f901c090b7a4e658241447bceb9aa67ab3819248 | 2026-11-22T19:09:39Z (555s) |
