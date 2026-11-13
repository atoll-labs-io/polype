# Verification — s167-record-writes-reports

[Story](../stories.md) · [Plan](../plans/s167-record-writes-reports.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 118ba33f078a00f6df5a1f5730affff79d69f4d8

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | builds `po` first, then every `tests/*.test.sh` |
| Type check | — | no such command in this project (`Typecheck: —`); `cargo build --release --locked` inside the suite is the only compile check |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- **Why the first unit-suite row exited 1 (a harness defect, not this code).** That run was made before the code was committed and gave 741 passed and 7 failed: the five oracle tests and the two implementer tests of s167. The second row ran on the same code after commit `15888d3` and passed 748 of 748. `tests/readme-onboarding.test.sh` clones `file://$ROOT`, which is the committed HEAD, and runs `install --global` from that clone. That install builds `po` from the clone's sources into the `CARGO_TARGET_DIR` that `tests/run.sh` exports and shares. The `po` every later test launches is therefore HEAD's, where `po record` answers `not-built`. Reproduced with `bash tests/run.sh readme-onboarding.test.sh record-writes-reports.oracle.test.sh`, which gives 5 failures. The same two files without the readme test pass 5/5 and 3/3. Once the code was committed, HEAD held it and the clone built it. Fixing the shared target dir touches `tests/run.sh` or `tests/readme-onboarding.test.sh`, which are both outside `Owns`; the lead files the defect.
- `commands_call_po_record` and `resume_paths_reuse_the_report` are model-read rules: only their word counts are tested; the review judges the prose.
- Whether the narrowed `Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" record review:*)` rule of `/po-review` matches without a permission prompt was not checked against Claude Code.
- No live `/po-review`, `/po-qa` or `/po-drive` run was made through `po record`; the binary is tested on a scratch project only.
- This repository's `.polype/` is an installed copy: until the next `bin/polype-dev-install`, `po record` here reads the old review template note (harmless: the header is the first two non-empty lines).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | e9d7060281938bf491f4994cc0839c587121f5d6 | 2026-11-13T14:46:13Z |
| Unit suite | `bash tests/run.sh` | 0 | 012a27735b5c559876186475757448239b2002c2 | 2026-11-13T15:01:42Z |
