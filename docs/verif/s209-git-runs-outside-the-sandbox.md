# Verification — s209-git-runs-outside-the-sandbox

[Story](../stories.md) · [Plan](../plans/s209-git-runs-outside-the-sandbox.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: ab08739b1be3cdc5286fca7853da95df8b62b1d1

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
| `tests/real-run-in-the-sandbox.oracle.test.sh` (s208's oracle) | `test_sandbox_governs_bash`: the Bash rules of `allow` must equal `["Bash(git *)"]` instead of `[]` | ADR-0138 allows git, alone, by `Bash(git *)` (plan task 5) |
| `tests/real-run-in-the-sandbox.oracle.test.sh` (s208's oracle) | `test_governing_is_listed_not_ignored`: the form appending `/src/` to `home/.config/git/ignore` is replaced by one appending `* filter=x` to `home/.config/git/attributes`, which must still read as a change | git's global ignore leaves the governing list (ADR-0138); the rest of `.config/git/` stays compared (plan task 5) |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- No real run: every check uses the claude double. Whether Claude Code honours `sandbox.excludedCommands: ["git"]` and `Bash(git *)` inside a run only the next real run shows (plan, `## The pivot`). The case-sensitive matching of the four git deny rules rests on the lead's probe of 2026-11-24, cited in ADR-0138, not on a check of this record; the refusal of `git -C <path> --config-env=…` and `git --no-pager --config-env=…` rests on the lead's second probe of the same day, also cited there; whether a leading `VAR=… git …` passes them is not proven anywhere.
- ADR-0138, `docs/evals/real-run.md` and the two landed records (sums `776923962 984` and `2639938192 1077`, checked after copying) are judged in review.
- No type check, end-to-end or build: the project has none.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 8a4ff7c7ca6a7250c9f3e6df6a0e3260eaa4b752 | 2026-11-24T09:40:56Z (1090s) |
| Unit suite | `bash tests/run.sh` | 0 | 55a5ce1bbf5fa37e7750742599f451eabaf2f451 | 2026-11-24T11:00:41Z (753s) |
| Unit suite | `bash tests/run.sh` | 1 | 41ae5ab7c586c42acfcffacac995de9568c29669 | 2026-11-24T11:34:11Z (1021s) |
| Unit suite | `bash tests/run.sh` | 1 | 05fcc81d844c91fc431bf638d3268998a43c2c0c | 2026-11-24T12:03:47Z (1477s) |
| Unit suite | `bash tests/run.sh` | 1 | e9e3be485d9bc6ef2ce287b6288ea8c3dd591031 | 2026-11-24T12:32:57Z (1701s) |
| Unit suite | `bash tests/run.sh` | 0 | f62728b0fac00901572232d0fdb40edf11d0b6fd | 2026-11-24T12:57:43Z (1480s) |
