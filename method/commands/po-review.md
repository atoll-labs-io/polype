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
  - Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" record review:*)
---
# /po-review

Reads settings: `Target branch`, `Worktree root`, `Verification mode`, `Test budget`, `Model strong`

Story: $ARGUMENTS

The verdict comes from the `reviewer` subagent, never from this context: whoever coordinated or wrote the story is the worst placed to see its mistakes. This command records exactly one file, `docs/reviews/<id>.md`, through `po record`, and never touches code. A critical finding always blocks the ship.

No Agent tool available → say so and stop.

## Preconditions
- `AGENTS.local.md` exists; otherwise point to `/po-setup`.
- $ARGUMENTS matches one id; otherwise list the ids and stop.
- `Model strong` missing → stop and name it.
- The worktree is registered for this story, checked the way `/po-execute` does it. Otherwise stop; do not switch branches.
- Read the previous `docs/reviews/<id>.md` if there is one: its `Fix loop:` value plus one is this review's loop number (0 when there is none). A review is blocked on QA when it carries `Review status: blocked` and a `Next action:` naming `/po-qa`, and blocked on QA evidence when it carries `Review status: blocked` and a `Next action:` naming the `<id>: QA evidence` commit; nothing less makes either. When that previous review was blocked on QA or on QA evidence, this review keeps the same `Fix loop:` value instead, because a QA return is not a fix run (ADR-0034, ADR-0041). A third blocked review in a row is not requested: stop and hand the open findings to a human. Reviews blocked on QA or on QA evidence do not count toward those three.

## Delegation
Agent tool, `subagent_type: reviewer`, `model:` set to `Model strong` whatever the story's complexity, description "Review <id>", prompt filled in:

> Story <id>. Worktree: <absolute path>. How to review is settled by your agent file and the review-antihallu skill; below are the details of this story. The scope is `git diff <Target branch>...story/<id>`, no wider. Shape your answer like templates/review.md with `Fix loop: <n>`, starting below its header: no `# Review` title and no link line, which this context writes itself. Report every finding now — none kept for later. Settings and project commands come from AGENTS.local.md, used verbatim; when a command is `—`, your report says the project has none and you do not substitute your own. Start every shell command with `cd <absolute path> &&` or use `git -C <absolute path>`. End with the lines `Max severity:` and `Ship allowed:`.

`Model strong` at `—` passes no `model` at all: the reviewer runs on the session's model. If the Agent tool rejects the model name, stop and report the setting and its value: write no `docs/reviews/<id>.md` and never retry with another model or with none.

## Recording
`po record` writes the file, never this context: pipe the body, whole, into `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" record review <id>`, run with `cd <worktree> &&`, through a quoted heredoc whose delimiter no line of the body equals. It writes the header, the `Method version:` stamp and the `Oracle:` line of `po-gate oracle-intact <id>`, appends to a file that exists, then runs `.polype/hooks/po-gate.sh findings-shape <id>` on what it wrote and exits with its code. A blocked report this context composes goes through `po record review <id> --composed` and is never checked. `[security]` findings go to a sensitive inbox decision once the shape passes; the review keeps their count and its id. `security-shape` takes the exit 1 path. `no-private-folder-setting` and `private-folder-unusable` stop for the person. `po` missing → stop, name `polype install`; any other `"written": false` → stop on its `error`. Write nothing by hand.

The answer must contain `Review status:`, `Fix loop:` and the `Reviewed tree:` hash the reviewer took before reading, and end with `Max severity: …` then `Ship allowed: yes|no`.

Exit 1 → dispatch the reviewer once more, same model, with the `## Delegation` prompt at the same `Fix loop: <n>`, followed by: "Your previous answer, recorded in docs/reviews/<id>.md, fails po-gate findings-shape <id> at: <the `refused` lines>. Answer again with the same Fix loop, each finding one list item `- <critical|major|minor> — <path>:<line> — <the problem>` as templates/review.md shows, never a heading." After `security-shape`, the prompt names the `refused` answer lines and says nothing was recorded. The new answer is recorded the same way: appended after the malformed block, which stays byte for byte. This re-ask spends no fix loop. A second exit 1 → record a blocked report: `Review status: blocked`, the same `Fix loop:`, `Failure cause:` quoting the refused lines, `Missing:` findings in the shape of `templates/review.md`, `Required adaptation:` a person rewrites or files them, `Next action: a person settles the findings shape — po-gate findings-shape <id> refused the reviewer twice`, then `Max severity: critical` and `Ship allowed: no`. Any other exit — 2 when the check cannot run — is not a malformed review: the reviewer is not dispatched again, and the same blocked report is recorded, with `Failure cause:` the gate's exit and its message, `Missing:` a shape check that ran, `Required adaptation:` a person runs the check or repairs the installed gate, `Next action: a person runs po-gate findings-shape <id> — the check could not run (exit <n>)`. Any command that records a review "as `/po-review` says" applies this check and its stop before its own fix-loop rules.

If the subagent fails, times out, returns nothing, or answers without both verdict lines, record a blocked report: `Review status: blocked`, its cause, what is missing and must change, the loop number, then `Max severity: critical` and `Ship allowed: no`. Never turn a failure into "review failed" nor guess a severity.

## Outcome
- `Ship allowed: no` with `Review status: blocked` and a `Next action:` naming `/po-qa` → "Review blocked on QA for <id>. Run /po-qa <id>, then /po-review <id> again; no fix run is spent."
- `Ship allowed: no` with `Review status: blocked` and a `Next action:` naming the `<id>: QA evidence` commit → "Review blocked on uncommitted QA evidence for <id>. Commit it alone: git commit -m "<id>: QA evidence" -- docs/qa/<id>/, then /po-review <id> again; no fix run is spent."
- `Ship allowed: no` with `Review status: blocked` and a `Next action:` naming `po-gate findings-shape` → "Review of <id> stopped: <the cause its Next action: gives — the reviewer's findings failed their shape twice, or the check could not run (exit <n>)>. A person settles it; no fix run is spent."
- Any other `Ship allowed: no` → "Ship blocked for <id>. Run /po-execute <id> (fix run), then /po-review <id> again." At loop 2, instead: "Ship still blocked after two fix runs. Open findings: <list>. A human decides what happens next."
- `Ship allowed: yes` → "Review passed. Next: /po-ship <id>"
