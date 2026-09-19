---
description: Tells where each story stands, from the files and git alone, and which command to run next
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---
# /po-status

Reads settings: `Target branch`, `Worktree root`, `Merge mode`, `Plan validation`, `Entry mode`, `Story track`, `Flow threshold`

Everything comes from files and git; nothing is guessed. Bash is used read-only: no commit, checkout, merge or file change. `git fetch` is allowed when a remote exists, so that stories merged through a pull request are seen.

1. **Setup.** No `AGENTS.local.md` → the next command is `/po-setup`, full stop. Otherwise one line: `Merge mode`, `Plan validation`, `Target branch`.
2. **Framing**, read on `Target branch`:
   - scope: `docs/prd.md` for `Entry mode` `replace` or `adapt`, `docs/brief.md` for `new` — none · in progress (`status: draft` for the PRD, `status: interviewing` for the brief) · approved (`status: approved` in the frontmatter); `Entry mode: —` → "stories by hand";
   - `docs/stories.md` present or not;
   - stories review: the `Stories ready:` value of `docs/reviews/stories.md` — yes · no · none;
   - `docs/architecture.md` present or not;
   - `docs/design-system.md` present or not.
3. **Per story** listed in `docs/stories.md` (none → "No stories yet"), reading from its worktree `<Worktree root><id>` while it exists and from `Target branch` afterwards:
   - complexity from `docs/stories.md`;
   - track: `flow` when the plan frontmatter holds `track: flow`, `full` when a plan exists without it; no plan yet → the track the settings predict (`Story track`, and for `auto` the complexity against `Flow threshold`), suffixed `(expected)` — `auto` with no complexity gives `full (expected)`;
   - research present or not;
   - design: `docs/designs/<id>/design.md` present or not;
   - plan: none · draft · approved (`validated: yes` in the frontmatter), and ticked boxes over total;
   - record: present or not, and whether `po-gate verif-current <id>` passes;
   - review: last `Ship allowed:` value — yes · no · none — and its `Fix loop:`;
   - shipped: a commit whose subject starts with `<id>:` on `Target branch` or `origin/<Target branch>` → shipped; an open pull request from `story/<id>` → waiting for merge;
   - dependencies: if one of them is not shipped, the story shows "waiting for <ids>" instead of a next command.
4. **Output.** The framing line first, then a line with shipped / in progress / not started counts, then a table: story (complexity) · track · research · design · plan · record · review · shipped · next. "Next" follows the cycle: research → design (`/po-design <id>`, a story with a screen) → plan → approve plan (`/po-plan` again) → execute → review (blocked → `/po-execute` fix run) → ship, or "waiting for merge". A story expected on the flow track with no plan yet gets `/po-flow <id>` while it has no worktree; once a worktree exists without a plan, `/po-flow` has escalated, and it gets `/po-research <id>`. One line per shipped story.
5. **Decisions.** With `docs/decisions/`: how many ADRs, and the most recent.

Finish with the single most useful command, for example "Next: /po-plan s02-refund-order".
