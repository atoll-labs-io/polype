---
description: Show where every story stands — derived from the files and git, never guessed — and the next useful command
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---
# /po-status — Where the project stands

Reads settings: `Target branch`, `Worktree root`, `Merge mode`, `Plan validation`

Derive everything from the files and git. Bash is for read-only queries only: never modify, commit, check out or fetch.

1. **Settings.** `AGENTS.local.md` missing → the only next step is `/po-setup`. Otherwise show `Merge mode`, `Plan validation` and `Target branch` on one line.
2. **Stories.** `docs/stories.md` missing → "No stories yet." Otherwise, for each id, read its files in its worktree `<Worktree root><id>` when it exists, and on `Target branch` once shipped:
   - complexity, from `docs/stories.md`;
   - research: `docs/research/<id>.md` present;
   - plan: missing · draft · validated (frontmatter `validated: yes`), with ticked over total checkboxes;
   - verification: `docs/verif/<id>.md` present, and whether `po-gate verif-current <id>` passes;
   - review: the `Ship allowed:` line → yes · no · none;
   - shipped: a commit `<id>: …` on `Target branch` → shipped; an open pull request for `story/<id>` → merge pending;
   - blocked: a story whose dependencies are not all shipped shows "blocked by <ids>" instead of a next command.
3. **Summary first**: X shipped · Y in progress · Z not started. Then one table: story (complexity) · research · plan · verification · review · shipped · next. The next command follows the cycle: research → plan → validate (rerun `/po-plan`) → execute → review (a `no` → `/po-execute` in fix mode) → ship, or "merge pending". Shipped stories take one line each.
4. **Decisions.** If `docs/decisions/` exists: the number of ADRs and the latest one.

End with the single most useful next command, e.g. "Next: /po-plan s02-export-invoice".
