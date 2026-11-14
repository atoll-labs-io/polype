# Verification — s171-po-prebuilt-and-verified

[Story](../stories.md) · [Plan](../plans/s171-po-prebuilt-and-verified.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: 7518083621bfc441c1060adb8e3f75d8bc8afebd

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | launched with `curl` and `wget` stubs first on the `PATH`, logging every call and exiting 1 (task 8's check) |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- A real download and a real release: no tag exists and `PO_SUMS` stays empty, so every test uses the `POLYPE_PO_FETCH` and `cargo` doubles. Whether `ubuntu-24.04-arm` and `macos-latest` runners carry `cargo` and `gh`, and whether `gh release upload` accepts `dist/po-*`, shows on the first pushed tag.
- macOS: `po_platform` (`bin/polype`) and the mapping in `bin/po-release` were compared line by line, but only Linux x86_64 ran them; `shasum -a 256` paths are not exercised here.
- A Linux binary built on `ubuntu-latest` running on an older glibc: not probed, documented with `POLYPE_PO_FROM_SOURCES=1`.
- `docs_say_what_is_verified` (`docs/installation.md`, `docs/ci.md`): judged in review.
- The list of machine files `po` reads (`is_po_machine_file`) was compared with `po/src/run/session.rs` and `po/src/run/mod.rs`; no test links it to `po/src/`.
- Task 8's check: the Unit suite row above ran with `curl` and `wget` stubs first on the `PATH`, logging every call and exiting 1; the log stayed empty after the run.
- Formatting and lint: none configured in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 633b4957833063bd0e9039235aa6d4973769f92c | 2026-11-14T09:06:38Z |
