# Verification — s195-ship-files-open-findings

[Story](../stories.md) · [Plan](../plans/s195-ship-files-open-findings.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: c7f48f364c906e273982cef3919321331d1e90c9

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | `Full suite: execute-end`; builds `po` with `cargo build --release --locked` first |
| Type check | — | no such command in this project (`Typecheck: —`); the Rust compiler checks types in the suite's build |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

## Not proven here
- A real tracker: `gh issue list`, `gh api --hostname github.com --method POST repos/<o>/<r>/issues --input <file>`, `task … export` and `task … import <file>` are doubled; their forms follow `gh api --help` and the research's check of `task import` on 3.5.0, never a live call (lane rule).
- The modes of the temporary folder (`0700`, `DirBuilder::create`, never reused) and of its files (`0600`, `create_new`): the folder is gone when `po` returns, so no test can read them; checked by reading `po/src/ship/file.rs`. Its removal on every return is bitten by the oracle's empty-`TMPDIR` assertion, on success and on `file-failed`.
- `task import`'s stderr dropped (`Stdio::null`): the double prints nothing there, so removing it fails no test; checked by reading.
- Guards with no test of their own: `--file` given twice (`usage`), an unknown option (`unknown-option`), a `## Findings` that ends at `Max severity:` before the next `## `, and `Fix loop:` read only up to the last verdict (the oracle bites "the last one", not "up to the verdict"). A line of a `[security]` item that does not itself hold the mark gets `text: null` in `unrecognised`; only the stray-mark case is tested.
- `unmarked_security_stays_with_the_model`: a model rule, judged in review. Its word ceiling is checked by `test_ship_words_go_down`: `po-ship.md` holds 1 250 words (≤ 1 593).

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 959419f7a6211a8425b8f36a857c08ee4f4bbd29 | 2026-11-20T10:47:23Z (542s) |
