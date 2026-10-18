---
description: Sends a finished story to the reviewer subagent in a fresh context and records the verdict that decides whether it may ship
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
  - Write
  - Bash(.polype/hooks/po-gate.sh findings-shape:*)
---
# /po-review

Reads settings: `Target branch`, `Worktree root`, `Verification mode`, `Test budget`, `Model strong`

Story: $ARGUMENTS

The verdict comes from the `reviewer` subagent, never from this context: whoever coordinated or wrote the story is the worst placed to see its mistakes. This command writes exactly one file, `docs/reviews/<id>.md`, and never touches code. A critical finding always blocks the ship.

No Agent tool available → say so and stop.

## Preconditions
- `AGENTS.local.md` exists; otherwise point to `/po-setup`.
- $ARGUMENTS matches one id; otherwise list the ids and stop.
- `Model strong` missing → stop and name it.
- The worktree is registered for this story, checked the way `/po-execute` does it (shared git directory found through `<repository root>/.git`, folder or file; then `<shared>/worktrees/<id>/gitdir` and `<shared>/worktrees/<id>/HEAD`). Otherwise stop; do not switch branches.
- Read the previous `docs/reviews/<id>.md` if there is one: its `Fix loop:` value plus one is this review's loop number (0 when there is none). A review is blocked on QA when it carries `Review status: blocked` and a `Next action:` naming `/po-qa`, and blocked on QA evidence when it carries `Review status: blocked` and a `Next action:` naming the `<id>: QA evidence` commit; nothing less makes either. When that previous review was blocked on QA or on QA evidence, this review keeps the same `Fix loop:` value instead, because a QA return is not a fix run (ADR-0034, ADR-0041). A third blocked review in a row is not requested: stop and hand the open findings to a human. Reviews blocked on QA or on QA evidence do not count toward those three.

## Delegation
Agent tool, `subagent_type: reviewer`, `model:` set to `Model strong` whatever the story's complexity, description "Review <id>", prompt filled in:

> Story <id>. Worktree: <absolute path>. How to review is settled by your agent file and the review-antihallu skill; below are the details of this story. The scope is `git diff <Target branch>...story/<id>`, no wider. Shape your answer like templates/review.md with `Fix loop: <n>`. Report every finding now — none kept for later. Settings and project commands come from AGENTS.local.md, used verbatim; when a command is `—`, your report says the project has none and you do not substitute your own. Start every shell command with `cd <absolute path> &&` or use `git -C <absolute path>`. End with the lines `Max severity:` and `Ship allowed:`.

`Model strong` at `—` passes no `model` at all: the reviewer runs on the session's model. If the Agent tool rejects the model name, stop and report the setting and its value: write no `docs/reviews/<id>.md` and never retry with another model or with none, because the setting is at fault, not the story.

## Recording
Write the subagent's answer, whole, to `docs/reviews/<id>.md` in the worktree. It must contain `Review status:`, `Fix loop:` and the `Reviewed tree:` hash the reviewer took before reading — `/po-ship` refuses a verdict whose tree no longer matches the code outside `docs/` — and end with `Max severity: …` then `Ship allowed: yes|no` — `/po-ship` reads the last of these.

Once a reviewer's answer is written verbatim, check the shape of its findings: `cd <worktree> && .polype/hooks/po-gate.sh findings-shape <id>`. That shell call is the only one this command makes. A blocked report this context composed itself is never checked. Exit 1 → dispatch the reviewer once more, same model, with the `## Delegation` prompt at the same `Fix loop: <n>`, followed by: "Your previous answer, recorded in docs/reviews/<id>.md, fails po-gate findings-shape <id> at: <the lines it quoted>. Answer again with the same Fix loop, each finding one list item `- <critical|major|minor> — <path>:<line> — <the problem>` as templates/review.md shows, never a heading." The new answer is appended after the malformed block, which stays byte for byte: Write replaces the whole file, so everything already in it is written back unchanged before the new answer. This re-ask spends no fix loop. A second exit 1 → append a blocked report: `Review status: blocked`, the same `Fix loop:`, `Failure cause:` quoting the refused lines, `Missing:` findings in the shape of `templates/review.md`, `Required adaptation:` a person rewrites or files them, `Next action: a person settles the findings shape — po-gate findings-shape <id> refused the reviewer twice`, then `Max severity: critical` and `Ship allowed: no`. That stop goes to the person at once. Any other exit — 2 when the check cannot run, such as a missing id or a `.polype/hooks/po-gate.sh` older than `findings-shape` answering `unknown subcommand` — is not a malformed review: the reviewer is not dispatched again, and the same blocked report is appended, with `Failure cause:` the gate's exit and its message, `Missing:` a shape check that ran, `Required adaptation:` a person runs the check or repairs the installed gate, `Next action: a person runs po-gate findings-shape <id> — the check could not run (exit <n>)`, then `Max severity: critical` and `Ship allowed: no`. Any command that records a review "as `/po-review` says" applies this check and its stop before its own fix-loop rules.

If the subagent fails, times out, returns nothing, or returns a report without both verdict lines, write the file yourself: `Review status: blocked`, the concrete cause, what is missing, what must change, the loop number, then `Max severity: critical` and `Ship allowed: no`. Do not turn a failure into "review failed" and do not guess a severity.

## Outcome
- `Ship allowed: no` with `Review status: blocked` and a `Next action:` naming `/po-qa` → "Review blocked on QA for <id>. Run /po-qa <id>, then /po-review <id> again; no fix run is spent."
- `Ship allowed: no` with `Review status: blocked` and a `Next action:` naming the `<id>: QA evidence` commit → "Review blocked on uncommitted QA evidence for <id>. Commit it alone: git commit -m "<id>: QA evidence" -- docs/qa/<id>/, then /po-review <id> again; no fix run is spent."
- `Ship allowed: no` with `Review status: blocked` and a `Next action:` naming `po-gate findings-shape` → "Review of <id> stopped: <the cause its Next action: gives — the reviewer's findings failed their shape twice, or the check could not run (exit <n>)>. A person settles it; no fix run is spent."
- Any other `Ship allowed: no` → "Ship blocked for <id>. Run /po-execute <id> (fix run), then /po-review <id> again." At loop 2, instead: "Ship still blocked after two fix runs. Open findings: <list>. A human decides what happens next."
- `Ship allowed: yes` → "Review passed. Next: /po-ship <id>"
