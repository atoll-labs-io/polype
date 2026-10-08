---
description: Sends a finished story to the reviewer subagent in a fresh context and records the verdict that decides whether it may ship
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
  - Write
---
# /po-review

Reads settings: `Target branch`, `Worktree root`, `Verification mode`, `Test budget`

Story: $ARGUMENTS

The verdict comes from the `reviewer` subagent, never from this context: whoever coordinated or wrote the story is the worst placed to see its mistakes. This command writes exactly one file, `docs/reviews/<id>.md`, and never touches code. A critical finding always blocks the ship.

No Agent tool available → say so and stop.

## Preconditions
- `AGENTS.local.md` exists; otherwise point to `/po-setup`.
- $ARGUMENTS matches one id; otherwise list the ids and stop.
- The worktree is registered for this story, checked the way `/po-execute` does it (shared git directory found through `<repository root>/.git`, folder or file; then `<shared>/worktrees/<id>/gitdir` and `<shared>/worktrees/<id>/HEAD`). Otherwise stop; do not switch branches.
- Read the previous `docs/reviews/<id>.md` if there is one: its `Fix loop:` value plus one is this review's loop number (0 when there is none). When that previous review was blocked on QA — its `Next action:` names `/po-qa` — this review keeps the same `Fix loop:` value instead, because a QA return is not a fix run (ADR-0034). A third blocked review in a row is not requested: stop and hand the open findings to a human. Reviews blocked on QA do not count toward those three.

## Delegation
Agent tool, `subagent_type: reviewer`, description "Review <id>", prompt filled in:

> Story <id>. Worktree: <absolute path>. How to review is settled by your agent file and the review-antihallu skill; below are the details of this story. The scope is `git diff <Target branch>...story/<id>`, no wider. Shape your answer like templates/review.md with `Fix loop: <n>`. Report every finding now — none kept for later. Settings and project commands come from AGENTS.local.md, used verbatim; when a command is `—`, your report says the project has none and you do not substitute your own. Start every shell command with `cd <absolute path> &&` or use `git -C <absolute path>`. End with the lines `Max severity:` and `Ship allowed:`.

## Recording
Write the subagent's answer, whole, to `docs/reviews/<id>.md` in the worktree. It must contain `Review status:`, `Fix loop:` and the `Reviewed tree:` hash the reviewer took before reading — `/po-ship` refuses a verdict whose tree no longer matches the code outside `docs/` — and end with `Max severity: …` then `Ship allowed: yes|no` — `/po-ship` reads the last of these.

If the subagent fails, times out, returns nothing, or returns a report without both verdict lines, write the file yourself: `Review status: blocked`, the concrete cause, what is missing, what must change, the loop number, then `Max severity: critical` and `Ship allowed: no`. Do not turn a failure into "review failed" and do not guess a severity.

## Outcome
- `Ship allowed: no` with a `Next action:` naming `/po-qa` → "Review blocked on QA for <id>. Run /po-qa <id>, then /po-review <id> again; no fix run is spent."
- Any other `Ship allowed: no` → "Ship blocked for <id>. Run /po-execute <id> (fix run), then /po-review <id> again." At loop 2, instead: "Ship still blocked after two fix runs. Open findings: <list>. A human decides what happens next."
- `Ship allowed: yes` → "Review passed. Next: /po-ship <id>"
