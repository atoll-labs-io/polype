---
description: Has the reviewer subagent judge a story in a fresh context and records its verdict
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
  - Write
  - Bash(.polype/hooks/po-gate.sh findings-shape:*)
  - Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" record review:*)
  - Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next)
---
# /po-review

Reads settings: `Target branch`, `Worktree root`, `Model strong`

Story: $ARGUMENTS

## By hand
`/po-drive` skips this section. Run `po next` and route as `## By hand` of `/po-execute` says, going on only on `review`, or on the `ask` `findings-shape refused`, `review without verdict` or `QA evidence committed twice` once the person has settled it. At the end, on the `ask` `Max attempts reached`: "Ship still blocked after two fix runs. Open findings: <list>. A human decides what happens next." On the `ask` `findings-shape refused`: "Review of <id> stopped: <the cause its Next action: gives — the reviewer's findings failed their shape twice, or the check could not run (exit <n>)>. A person settles it; no fix run is spent."

## Fix loop
Read the previous `docs/reviews/<id>.md` if there is one: its `Fix loop:` value plus one is this review's loop number (0 when there is none). When that previous review carries `Review status: blocked` and a `Next action:` naming `/po-qa` or the `<id>: QA evidence` commit, this review keeps the same `Fix loop:` value instead, because a QA return is not a fix run (ADR-0034, ADR-0041).

## Delegation
Agent tool, `subagent_type: reviewer`, `model:` set to `Model strong` whatever the story's complexity, description "Review <id>", prompt filled in:

> Story <id>. Worktree: <absolute path>. How to review is settled by your agent file and the review-antihallu skill; below are the details of this story. The scope is `git diff <Target branch>...story/<id>`, no wider. Shape your answer like templates/review.md with `Fix loop: <n>`, starting below its header: no `# Review` title and no link line, which this context writes itself. Report every finding now — none kept for later. Settings and project commands come from AGENTS.local.md, used verbatim; when a command is `—`, your report says the project has none and you do not substitute your own. Run git as `git -C <absolute path>`, every other command after `cd <absolute path> &&`. End with the lines `Max severity:` and `Ship allowed:`.

`Model strong` at `—` passes no `model` at all. If the Agent tool rejects the model name, stop and report the setting and its value: write no `docs/reviews/<id>.md` and never retry with another model or with none.

## Recording
`po record` writes the file, never this context: pipe the body, whole, into `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" record review <id>`, run with `cd <worktree> &&`, through a quoted heredoc whose delimiter no line of the body equals. It writes the header, the `Method version:` stamp and the `Oracle:` line of `po-gate oracle-intact <id>`, appends to a file that exists, then runs `.polype/hooks/po-gate.sh findings-shape <id>` on what it wrote and exits with its code. A blocked report this context composes goes through `po record review <id> --composed` and is never checked. `[security]` findings go to a sensitive inbox decision once the shape passes; the review keeps their count and its id. `security-shape` takes the exit 1 path. `no-private-folder-setting` and `private-folder-unusable` stop for the person. `po` missing → stop, name `polype install`; any other `"written": false` → stop on its `error`. Write nothing by hand.

The answer must contain `Review status:`, `Fix loop:` and the `Reviewed tree:` hash the reviewer took before reading, and end with `Max severity: …` then `Ship allowed: yes|no`.

Exit 1 → dispatch the reviewer once more, same model, with the `## Delegation` prompt at the same `Fix loop: <n>`, followed by: "Your previous answer, recorded in docs/reviews/<id>.md, fails po-gate findings-shape <id> at: <the `refused` lines>. Answer again with the same Fix loop, each finding one list item `- <critical|major|minor> — <path>:<line> — <the problem>` as templates/review.md shows, never a heading." After `security-shape`, the prompt names the `refused` answer lines and says nothing was recorded. The new answer is recorded the same way: appended after the malformed block, which stays byte for byte. This re-ask spends no fix loop. A second exit 1 → record a blocked report: `Review status: blocked`, the same `Fix loop:`, `Failure cause:` quoting the refused lines, `Missing:` findings in the shape of `templates/review.md`, `Required adaptation:` a person rewrites or files them, `Next action: a person settles the findings shape — po-gate findings-shape <id> refused the reviewer twice`, then `Max severity: critical` and `Ship allowed: no`. Any other exit — 2 when the check cannot run — is not a malformed review: the reviewer is not dispatched again, and the same blocked report is recorded, with `Failure cause:` the gate's exit and its message, `Missing:` a shape check that ran, `Required adaptation:` a person runs the check or repairs the installed gate, `Next action: a person runs po-gate findings-shape <id> — the check could not run (exit <n>)`. Any command that records a review "as `/po-review` says" applies this check and its stop before its own fix-loop rules.

If the subagent fails, times out, returns nothing, or answers without both verdict lines, record a blocked report: `Review status: blocked`, its cause, what is missing and must change, the loop number, then `Max severity: critical` and `Ship allowed: no`. Never turn a failure into "review failed" nor guess a severity.
