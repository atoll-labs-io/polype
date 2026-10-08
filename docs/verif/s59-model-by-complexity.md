# Verification — s59-model-by-complexity

The implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status line. `po-run` writes the `## Runs` section, one row per launch; no one else touches it. The gate compares the tree of each run with `Tree:` outside `docs/`: a declared check counts only through its runs on that code, and the last of them must have exited 0. Commands are copied exactly from `AGENTS.local.md`.

Order that produces `Tree:` — `git add -A`, then `git write-tree`. The hash therefore names the exact code the checks ran on. This file and the plan's ticks live inside `docs/`, which the comparison leaves out.

Tree: e02116b17be337c7fae24792863316019892ca3e

## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project (`Typecheck: —`) |
| End to end | — | no such command in this project (`E2E stage: —`) |
| Build | — | no such command in this project (`Build stage: —`) |

A row with a command is a check you launch through `po-run`. A check not run at this stage, or one the project does not have, gets `—` as its command and says why in Note ("no such command in this project", "deferred to ship").

## Not proven here
- That the Agent tool accepts `opus` and `sonnet` as a per-call `model`, and that this value overrides a subagent's `model: inherit`: no command was dispatched in a real Claude Code session. A refusal is a stop by design, so the failure would be loud.
- The routing is prose the commands follow; no hook checks which model a subagent actually ran on.
- Polype's own `AGENTS.local.md` has no model settings yet: every dispatching command stops on it until a human adds `Model strong`, `Model light`, `Light up to` after ship.
- `bin/po-lint method` run by hand: no breach in 25 files (also covered by `tests/adr-directory.test.sh` inside the suite).
- Run interdicts checked by hand: `git diff --cached --stat` on `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `docs/parite-killer-saas.md`, `tests/distribution-wiring.test.sh` is empty; in `method/agents/` only line 5 of `implementer.md` changes.
- No screen, no visual check; no type check, end to end or build exists in this project.

Verification status: complete

## Runs
Written by `po-run`, one row per launch. Never edit, reorder or delete a row.

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | 55b2a1b01a0b1006d949699e97131c89431dc8de | 2026-10-08T09:10:12Z |
