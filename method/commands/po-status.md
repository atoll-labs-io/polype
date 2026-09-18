---
description: Tells where each story stands, from the files and git alone, and which command to run next
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---
# /po-status

Reads settings: `Target branch`, `Worktree root`, `Merge mode`, `Plan validation`

Everything comes from files and git; nothing is guessed. Bash is used read-only: no commit, checkout, merge or file change. `git fetch` is allowed when a remote exists, so that stories merged through a pull request are seen.

1. **Setup.** No `AGENTS.local.md` → the next command is `/po-setup`, full stop. Otherwise one line: `Merge mode`, `Plan validation`, `Target branch`.
2. **Per story** listed in `docs/stories.md` (none → "No stories yet"), reading from its worktree `<Worktree root><id>` while it exists and from `Target branch` afterwards:
   - complexity from `docs/stories.md`;
   - research present or not;
   - plan: none · draft · approved (`validated: yes` in the frontmatter), and ticked boxes over total;
   - record: present or not, and whether `po-gate verif-current <id>` passes;
   - review: last `Ship allowed:` value — yes · no · none — and its `Fix loop:`;
   - shipped: a commit whose subject starts with `<id>:` on `Target branch` or `origin/<Target branch>` → shipped; an open pull request from `story/<id>` → waiting for merge;
   - dependencies: if one of them is not shipped, the story shows "waiting for <ids>" instead of a next command.
3. **Output.** A first line with shipped / in progress / not started counts, then a table: story (complexity) · research · plan · record · review · shipped · next. "Next" follows the cycle: research → plan → approve plan (`/po-plan` again) → execute → review (blocked → `/po-execute` fix run) → ship, or "waiting for merge". One line per shipped story.
4. **Decisions.** With `docs/decisions/`: how many ADRs, and the most recent.

Finish with the single most useful command, for example "Next: /po-plan s02-refund-order".
