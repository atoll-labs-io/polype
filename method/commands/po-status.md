---
description: Tells where each story stands, from the files and git alone, and which command to run next
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
---
# /po-status

Reads settings: `Target branch`, `Worktree root`, `Merge mode`, `Plan validation`, `Entry mode`, `Story track`, `Flow threshold`, `Parallel`, `Max attempts`, `ADR directory`, `QA stage`

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
   - QA: for a story with a screen when `QA stage` is `screens`, `docs/qa/<id>/report.md` present or not, its last `QA status:`, and whether `po-gate qa-current <id>` passes; `—` for any other story; `QA stage` unset → shown as unset for a screen story, never guessed;
   - review: last `Ship allowed:` value — yes · no · none — and its `Fix loop:`, plus whether `po-gate ship-allowed <id>` passes; a `yes` whose `Reviewed tree:` no longer matches the code is shown as stale, next `/po-review <id>`;
   - shipped: a commit whose subject starts with `<id>:` on `Target branch` or `origin/<Target branch>` → shipped; an open pull request from `story/<id>` → waiting for merge;
   - dependencies: if one of them is not shipped, the story shows "waiting for <ids>" instead of a next command.
4. **Fleet.** The lanes `/po-drive` would see, derived from the same worktrees and the same git, never from a memory of a wave:
   - **lanes in flight**: a worktree `<Worktree root><id>` whose `git -C <Worktree root><id> rev-parse --abbrev-ref HEAD` prints `story/<id>`; their count against `Parallel`, and for each one the story, the path and the stage of step 3;
   - **attempts spent**: the `Fix loop:` line of `docs/reviews/<id>.md`, read the way `/po-drive` reads it (`method/commands/po-drive.md`), shown against `Max attempts`; no review file means no attempt spent yet;
   - **blocked stories**, with the reason and what unblocks it: a dependency not shipped and which one; an `Owns` collision, judged by the overlap rule of check 8 of the `stories-review` skill, with the path that collided, the lane holding it, the two entries that overlapped and one path matching both; `Max attempts` reached, which no fix run may pass and which waits for a human; a QA report `blocked`, with its cause, which a human decides on, as in `/po-drive`; an orphan worktree — another branch, a detached HEAD, or `story/<id>` checked out at another path — reported as it was found, never repaired here.

   `Parallel` or `Max attempts` unreadable → say which one and print no fleet section; neither is replaced by a guess, and the rest of the report stands.
5. **Output.** The framing line first, then a line with shipped / in progress / not started counts, then a table: story (complexity) · track · research · design · plan · record · qa · review · shipped · next. "Next" follows the cycle: research → design (`/po-design <id>`, a story with a screen) → plan → approve plan (`/po-plan` again) → execute → for a screen story under `QA stage: screens`: its last `QA status:` is `blocked` → "a human decides", with the report's cause, as `/po-drive` resumes it; `po-gate qa-current <id>` refusing with `is current but` → the evidence commit `git commit -m "<id>: QA evidence" -- docs/qa/<id>/`, not a new walk; any other `qa-current` failure → QA (`/po-qa <id>`, a new walk) → review (`/po-qa <id>` for `Review status: blocked` and a `Next action:` naming `/po-qa`, the evidence commit for `Review status: blocked` and a `Next action:` naming the `<id>: QA evidence` commit, any other blocked review → `/po-execute` fix run) → ship, or "waiting for merge". A story expected on the flow track with no plan yet gets `/po-flow <id>` while it has no worktree; once a worktree exists without a plan, `/po-flow` has escalated, and it gets `/po-research <id>`. One line per shipped story.
6. **Decisions.** With the `ADR directory` folder present: how many ADRs, and the most recent.

Finish with the single most useful command, for example "Next: /po-plan s02-refund-order".
