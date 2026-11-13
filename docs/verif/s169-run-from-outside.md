# Verification — s169-run-from-outside

[Story](../stories.md) · [Plan](../plans/s169-run-from-outside.md)

The link line under the title is part of this template: it is copied with it, never edited after the copy, and is not one of the implementer's lines.

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, `## Oracle changes`, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: cc934cbe5bcf397f54499c9966cba03c0ec98aa5

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`); `tests/run.sh` builds `po` with `cargo build --release --locked` first, which type-checks the Rust |
| End to end | — | no such command in this project (`E2E: —`) |
| Build | — | no such command in this project (`Build: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Oracle changes
| Oracle file | What changes | Why |
| --- | --- | --- |
| `tests/run-from-outside.oracle.test.sh` | Fixture only, no assertion: `agents_in` copies Polype's own `method/agents/{implementer,qa,reviewer}.md` instead of writing name-only files, and `project` also lays an executable `.polype/hooks/po-bounds.sh` beside `po-gate.sh`. | Fix run, review finding major `po/src/run/bounds.rs:26` (owner decision d-0011): `held` now requires each global file to be Polype's subagent wiring the `po-bounds` hook and the project to hold the executable script. The old fixture laid exactly the name-only files the finding says prove nothing, so its "held" cases would read `unproven`; every assertion, including the three `bounds` cases of `test_run_refuses_unproven_bounds`, is unchanged. |

Each change the implementer makes to a file that `## Acceptance tests` of the plan names gets one row here, and the reviewer judges it. No row means no oracle file changed.

## Not proven here
- Whether the real `claude --bg` honours `--session-id` and lists that `sessionId` in `claude agents --json` with a `pid` while it runs: every test goes through the `PO_CLAUDE` stand-in. The owner checks it on the first real `po run` (the plan's pivot).
- `docs_show_the_agent_loop` (the edits to `docs/interface-agent.md`, `docs/installation.md`, `README.md`): judged in review.
- `tests/state-as-json.oracle.test.sh` (s164's oracle, not this plan's) changed as task 5 of the plan says: line 136 checks only `shipped` as null, the `run`/`continue` `not-built` loop is removed.
- Formatting and lint: none configured in this project.
- Fix run (review loop 0): `bounds` matches the hooks block of Polype's agent frontmatter as text, line by line. It does not read Claude Code's settings, so a configuration that turns every hook off (`disableAllHooks`) would still read `held`; and it does not check that `.polype/hooks/po-bounds.sh` is Polype's own script, only that it is there and executable.
- Fix run: a stale launch lock is detected with `kill -0 <pid>` and a ten-minute age limit; the probe is the system `kill` program, and when it cannot run only the age limit applies. A `po` of another user holding the lock would read as gone (`kill -0` refuses), which a project shared between users would meet; not tested.
- Fix run: the third Unit suite row (exit 1) failed only `installer_and_docs_agree_installation_doc`, a table row of `docs/installation.md` over 100 characters; the row was shortened and the suite run again on the amended commit (fourth row).
- Fix run: the minor finding on `not-built` in `docs/interface-agent.md:29` is left as the lead asked, `po/src/output.rs` being outside `Owns`.
- The first Unit suite row (exit 1) ran on uncommitted `po` code: `tests/readme-onboarding.test.sh` builds a clone of HEAD into the shared `CARGO_TARGET_DIR`, replacing the binary for every later test (issue 254). The suite was therefore run again after committing, with a forced rebuild, on the same code; that is the second row, and the commit was then amended with this record.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 1 | 4ceca9bd39ac9a24a1135959746d387f7bdd3467 | 2026-11-13T19:07:13Z |
| Unit suite | `bash tests/run.sh` | 0 | df01d7f0890dfba354b394e155089813727cca04 | 2026-11-13T19:24:11Z |
| Unit suite | `bash tests/run.sh` | 1 | fc758dc1d303b31fba6de143cb5890d2f06ab1a6 | 2026-11-13T23:28:55Z |
| Unit suite | `bash tests/run.sh` | 0 | cc934cbe5bcf397f54499c9966cba03c0ec98aa5 | 2026-11-13T23:36:17Z |
