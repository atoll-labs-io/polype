---
description: Have a story reviewed by a fresh-context subagent and write the verdict that gates the ship. Never reviews in the context that produced the code.
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
  - Write
---
# /po-review — Delegated review and ship gate

Reads settings: `Target branch`, `Worktree root`, `Verification mode`, `Test budget`

Target story: $ARGUMENTS

## Contract
You complete this command by delegating to the `reviewer` subagent, in a fresh context. You never:
- judge the code yourself — you may be the context that produced it, and would be blind to its hallucinations;
- modify code: your only write is `docs/reviews/<id>.md`;
- let a critical finding through.

If the Agent tool is unavailable, stop and say so.

## 1. Prerequisites (fail-closed)
- `AGENTS.local.md` missing → STOP: "No project settings. Run /po-setup."
- Resolve the id; locate `<Worktree root><id>`; `<repository root>/.git/worktrees/<id>/HEAD` must read `ref: refs/heads/story/<id>`. Otherwise STOP; never switch branches.

## 2. Delegate
Agent tool:
- subagent_type: `reviewer`
- description: Review story <id>
- working directory: the absolute worktree path
- prompt: "Review story <id> in <absolute worktree path>. Your definition and the preloaded review-antihallu skill are your contract; this prompt only carries what is specific to this run. Judge `git diff <Target branch>...story/<id>` and nothing else. Structure your report with templates/review.md. Report every finding now; never keep one for a later pass. Project commands and settings are in AGENTS.local.md — quote them verbatim; one set to `—` is reported as not run, never replaced. End with the exact lines `Max severity:` and `Ship allowed:`."

Wait for the verdict.

## 3. Write the report
Write the reviewer's full report to `docs/reviews/<id>.md` in the worktree. It carries a `Review status:` line and ends with the exact lines `Max severity: …` and `Ship allowed: yes|no` — `/po-ship` greps the last one.

**If the Agent call fails, times out, returns nothing, or returns a report without both verdict lines**, write the report yourself: `Review status: blocked`, the concrete failure cause, what is missing, the adaptation required, and end it with `Max severity: critical` and `Ship allowed: no`. Never replace a failure with a vague "review failed", and never infer a severity.

## 4. Gate
- `Ship allowed: no` → End with: "Ship blocked. Fix with /po-execute <id> (fix mode), then rerun /po-review <id>." Two fix loops at most; still blocked after two → stop and list every open finding.
- `Ship allowed: yes` → End with: "Review passed. Next: /po-ship <id>"
