# Verification — s170-trust-signals

[Story](../stories.md) · [Plan](../plans/s170-trust-signals.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: abadca055adcdc627b37fef007a04b0c9e6583e3

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | builds `po` with `cargo build --release --locked`, the crate's type check |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |
| `tests/state-as-json.oracle.test.sh` (s164's oracle) | `test_state_prints_one_json_object`, lines 136-137: the assertion that `shipped` is present and `null` becomes `.shipped == []` | this story computes `shipped`; that fixture lands no story, so the list is empty rather than unread (plan task 7, research false assumption 2) |

`tests/trust-signals.oracle.test.sh`, this story's own oracle, is unchanged (`cksum` 4269644301 10934). Outside any oracle, `tests/run-ledger.test.sh:48` changes the clause this story changes: the Time cell of a `po-run` row is now `<UTC time> (<n>s)` (plan task 1).

## Not proven here
- `checks` against the real GitHub API: every test uses a `PO_GH` double; the response shape follows the `gh api …/check-runs` answer quoted in the research. Pagination beyond 100 runs gives `null` by design, not exercised against a real forge.
- `po state --remote` makes one forge call per shipped story and claims no time bound; not measured.
- The contract text of `docs/interface-agent.md` (task 8): judged in review.
- The installed `.polype/hooks/po-run.sh` used for the runs below is still the pre-story copy, so its rows carry no duration; the new `method/hooks/po-run.sh` is exercised by `test_duration_comes_from_the_record` and `tests/run-ledger.test.sh`.
- The first Unit suite row (exit 1) ran on uncommitted code: `test_quickstart_runs_as_written` of `tests/readme-onboarding.test.sh` clones `file://$ROOT`, which holds only committed code, and its install rebuilds `po` into the shared `CARGO_TARGET_DIR`, so every `po` test after it in the alphabet (the 8 failures: the oracle's 4, the 3 task tests, `test_state_prints_one_json_object`) ran the pre-story binary. Those 8 pass on this code when run alone. The next row runs on the same tree once committed, where the clone builds this story's `po`.
- Formatting and lint: none configured in this project.

Verification status: complete
## Runs

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | a9594c6ead0301c79460bace580e4fb5353bafd5 | 2026-11-14T09:48:47Z |
| Unit suite | `bash tests/run.sh` | 0 | 71fb127fa465a7a0728fd94e4e2fe0cbf8bfe493 | 2026-11-14T10:02:21Z |
