# Verification — s156-qa-report-returned-as-text

[Story](../stories.md) · [Plan](../plans/s156-qa-report-returned-as-text.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 49f91e2189e3eac465d27b1f3c3418bad168fef1

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
| End to end | — | no such command in this project |
| Build | — | no such command in this project |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
- The harness guard itself (Claude Code's Write refusing a subagent's `report*.md`) lives outside this repository: no test runs it, and no real `qa` walk was dispatched here. The tests check the text contract of `qa.md`, `po-qa.md`, `po-drive.md` and the ADRs.
- The heredoc transcription is a written instruction for the coordinating context; no test executes it on a real report.
- `tests/leftovers.test.sh:12` froze ADR-0029's `superseded-by: [ADR-0037]`; it now expects `[ADR-0037, ADR-0102]`, because this story really changes that clause (the file was added to the story's `Owns` by the lead, PR #177). The first unit-suite row below (exit 1) is that test failing before the change.
- No type check, end-to-end or build exists in this repository (`Typecheck`, `E2E`, `Build` are `—`).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | 5a72f76a69e00eb9bd6280ba30802ed3c047b501 | 2026-11-10T18:18:39Z |
| Unit suite | `bash tests/run.sh` | 0 | 1957b2b6c2bf861666eff29aca21dd789105f222 | 2026-11-10T18:26:17Z |
