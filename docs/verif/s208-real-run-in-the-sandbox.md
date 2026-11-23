# Verification — s208-real-run-in-the-sandbox

[Story](../stories.md) · [Plan](../plans/s208-real-run-in-the-sandbox.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 4996cba051795655f3b54ea30d95693fd51c7810

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
| `tests/real-run-is-usable.oracle.test.sh` (s207's oracle) | `test_law4_commands_are_allowed` no longer compares `permissions.allow` with the ADR-0136 Bash list; it keeps the check that `curl` and `claude` are denied | ADR-0137 removes the Bash command list; plan task 7 |
| `tests/real-run-before-a-release.oracle.test.sh` (s206's oracle) | preamble only: presence stubs `bwrap` and `socat` in `$RTMP/sandbox-tools`, exported first on PATH; no test function changes | a launch now refuses without `bwrap`/`socat` on Linux and CI has neither; plan task 4 |
| `tests/real-run-before-a-release.test.sh` (not an oracle; listed for the reviewer) | `test_gh_is_allowed_for_a_lead_that_follows_the_method` checks that no `Bash(gh…)` rule is denied instead of `Bash(gh:*)` in allow; the intake run is kept. Its `lead_double` now also allows a command when the settings turn on the sandbox with `autoAllowBashIfSandboxed`, as Claude Code would | the allow list is gone (ADR-0137); plan task 7. The double change is beyond the plan's wording: without it the double refused every `gh` call and the intake run could not be graded |
| `tests/routing-phrase-tests-retired.oracle.test.sh` (s201's oracle) | one line added to `LOWERED_COUNTS`: `po 184 183 s208-real-run-in-the-sandbox` | `test_law4_commands_are_allowed` named the run's `po` path inside the removed allow-list equality, which the launch counter read as a launch of `po`; the test never ran `po`. `test_no_script_lost_its_tests` failed on that drop (184 on origin/main, 183 here); `LOWERED_COUNTS` is the mechanism that file gives for a rightful drop, and the line stops allowing anything once this story lands |

This story's own oracle, `tests/real-run-in-the-sandbox.oracle.test.sh`, is unchanged (cksum `987626575 7130`).

## Not proven here
- That Claude Code honours the `sandbox` keys, the `allowWrite` root and the `deny` rules under an auto-allowed sandboxed Bash, and that the listed governing sets hold against what a real session writes: only the next real run (`po-eval real`, paid, run by a person) shows it. Every check here uses the claude double.
- The refusal without `bwrap`/`socat` is exercised on Linux only; the macOS branch (no check) is not run.
- ADR-0137, the ADR-0136 frontmatter and `docs/evals/real-run.md` are judged in review; no script reads them.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | 1368eaaa8591c5fc03d411a2c41bc47412d4a5f2 | 2026-11-23T22:31:18Z (687s) |
| Unit suite | `bash tests/run.sh` | 0 | ea53dbb1e45714874986ab29afa48b58938f4807 | 2026-11-23T22:43:21Z (665s) |
