---
description: Tells where each story stands, from po state and the story files, and which command to run next
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---
# /po-status

Reads settings: `Target branch`, `Worktree root`, `Merge mode`, `Plan validation`, `Story track`, `Flow threshold`, `ADR directory`

Nothing is guessed. Bash is used read-only: no commit, checkout, merge or file change. `git fetch` is allowed when a remote exists, so that stories merged through a pull request are seen.

1. **Setup.** No `AGENTS.local.md` → the next command is `/po-setup`, full stop. Otherwise one line: `Merge mode`, `Plan validation`, `Target branch`.
2. **Project state, from `po state`.** Run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" state --all` from the repository root. When `po` is missing or exits 2, say so, name `polype install`, and stop. Report from that JSON, citing `po state` as the source of each figure:
   - the framing items and the framing next;
   - the milestone;
   - each lane: its path, stage, `next` and stops;
   - `ready`, and `held` with its reason and ref, plus for `owns` the two entries and the path;
   - `shipped`;
   - the warnings, as they are.
3. **What `po state` does not carry, read from files.** Per story of `docs/stories.md` (none → "No stories yet"), reading in its worktree `<Worktree root><id>` while it exists and on `Target branch` otherwise:
   - its complexity, from `docs/stories.md`;
   - its track: `flow` when the plan holds `track: flow`, `full` for a plan without it; no plan yet → the track `Story track` and `Flow threshold` predict, suffixed `(expected)`;
   - whether the research, design (`docs/designs/<id>/design.md`), plan, record, QA report and review files are present;
   - the plan's ticked boxes over total;
   - its next step: a story with a lane takes `lanes[].next`; a story in `ready` gets `/po-flow <id>` when its expected track is flow, otherwise `/po-research <id>`; a story in `held` shows its reason; a shipped story gets nothing.
4. **Output.** The framing line first, then a line with shipped / in progress / not started counts, then a table: story (complexity) · track · research · design · plan · record · qa · review · shipped · next. The stops and warnings of step 2 follow the table.
5. **Decisions.** With the `ADR directory` folder present: how many ADRs, and the most recent.

Finish with the single most useful command, for example "Next: /po-plan s02-refund-order".
