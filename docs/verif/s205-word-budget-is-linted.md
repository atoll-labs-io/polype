# Verification — s205-word-budget-is-linted

[Story](../stories.md) · [Plan](../plans/s205-word-budget-is-linted.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: b5ccf026b441d57c4288161bc72aaacb5691a3b5

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
| `tests/routing-phrase-tests-retired.oracle.test.sh` | `KEPT_CONTRACTS` loses `drive-executes-next.test.sh test_execute_does_not_grow`; `LOWERED_COUNTS` gains `po-gate.sh 136 135 s205-word-budget-is-linted`. | Plan task 5: the file and its word ceiling go (task 4), the ceiling now held by `method/word-budget`; `security-findings-stay-private.oracle.test.sh:test_words_hold` was the 136th launch of `po-gate.sh` (research fact 5). `test_no_script_lost_its_tests` prints `po-gate.sh: launched by 136 test functions on origin/main, 135 here, lowered by s205-word-budget-is-linted`. |
| `tests/ship-phrase-tests-retired.oracle.test.sh` | `S202_KEPT`: `intake-follow-ups.oracle.test.sh` keeps `test_redact_follows_the_scan_rule` only. | Plan task 5: `test_intake_holds_in_its_words` was pinned until s205; its ceiling moves to the budget. |
| `tests/qa-and-design-phrase-tests-retired.oracle.test.sh` | `S203_KEPT` loses the line `qa-lanes-isolated.oracle.test.sh test_no_file_grows`. | Plan task 5: the file is deleted with its only test, a word ceiling now held by the budget. |
| `tests/framing-and-installer-phrase-tests-retired.oracle.test.sh` | `S204_KEPT`: `installer-leftovers.oracle.test.sh` drops `test_docs_describe_the_kept_copy_stops`; the line `defects-seen-on-products.oracle.test.sh test_no_file_grows` goes; `commands-read-po-state.test.sh` keeps `test_session_hook_reports_a_failing_po`; `record-writes-reports.test.sh` keeps `test_composed_report_is_not_checked test_missing_link_is_dropped`; `decision-inbox.test.sh` drops `test_rules_stay_under_their_word_ceilings`; `answer-comes-back.test.sh` drops `test_rules_stay_under_the_story_ceiling`. | Plan task 5: each removed function was a word ceiling pinned until s205, now held by `method/word-budget` (section ceilings have no successor, as the plan says). |
| `tests/word-budget-is-linted.oracle.test.sh` | Fix run 1: a helper `words()` (`LC_ALL=C awk '{n += NF} END {print n + 0}'`) replaces `LC_ALL=C wc -w` in `write_budget` and in `test_budget_starts_at_todays_counts`; no assertion changes. New sum `1729079487 11205`. | The forge's `suite` failed `test_budget_starts_at_todays_counts` (3816 for 3815 words in `docs/parite-killer-saas.md`): `wc -w` of coreutils 9.12 reads the byte 0xA0 of « à » as a blank in the C locale, the runner's older one does not. awk gives the same count on gawk 5.4.1, mawk 1.3.4 and busybox. Only the way of counting changes, the lead's decision for this fix run. |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
`bin/po-lint method` and `bin/po-lint --base origin/main method` were run by hand (no breach) and are not recorded checks; the suite runs both through `tests/lint.test.sh`. `po-gate floor-guard` reads the committed story branch, so it was run after the commit, by hand. That the `d-NNNN` a raised line cites exists and says what the line claims is the reviewer's to check: the lint never opens the decision inbox. The documentation of `docs/harnais.md` and `docs/installation.md` is read by no test. bash 3 (macOS) was not run here: `bin/po-lint`'s new code uses no bash 4 feature. Fix run 1: the awk count was compared on gawk 5.4.1 (here), mawk 1.3.4 (debian:13-slim) and busybox awk (node:22-alpine), with no network: same counts for the four documents and the 50158 total; macOS's BSD awk was not run.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 1ad61f548bc54a0a280e2f94635c9758ed02022b | 2026-11-22T22:28:59Z (726s) |
| Unit suite | `bash tests/run.sh` | 0 | f026090314cb8b95d544553a894fe7691d5f1d5e | 2026-11-22T23:05:15Z (716s) |
