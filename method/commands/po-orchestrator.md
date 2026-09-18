---
description: Run one story's whole cycle — research, plan, execute, review, ship — stopping at the two human checkpoints the settings ask for
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
  - AskUserQuestion
  - Agent
---
# /po-orchestrator — One story, the whole cycle

Reads settings: `Target branch`, `Worktree root`, `Plan validation`, `Ship confirmation`, `Merge mode`, `Test budget`

Target story: $ARGUMENTS

You conduct; you never do a stage's work inline when a subagent owns it, and you never write code. Each stage follows **the exact contract of its own command file** — read `/po-research`, `/po-plan`, `/po-execute`, `/po-review` and `/po-ship` and apply them; this file only chains them. A checkpoint is a real AskUserQuestion call, never a sentence in your output.

## 0. Prerequisites (fail-closed)
- `AGENTS.local.md` missing → STOP: "No project settings. Run /po-setup."
- `docs/stories.md` missing → STOP: "No stories yet."
- Resolve the id; no unambiguous match → list the stories and stop. Never invent a story to keep going.

## 1. Research
Bootstrap or verify the worktree exactly as `/po-research` says. No `docs/research/<id>.md` → produce it under that contract; otherwise reuse it.

## 2. Plan — checkpoint
No `docs/plans/<id>.md` → produce it under the `/po-plan` contract. Then, unless its frontmatter already says `validated: yes`:
- `Plan validation: human` → AskUserQuestion "Validate this plan?" with its summary (tasks, files touched, test strategy): Validate / Change / Stop. Only Validate writes `validated: yes`; anything else stops here.
- `autonomous` → re-read it against every acceptance criterion, write `validated: yes`, and say that nobody else read it.

## 3. Execute
Delegate to the `implementer` **exactly as `/po-execute` does**, fix mode first if a blocking review exists. Never implement yourself.

## 4. Review
Delegate to the `reviewer` **exactly as `/po-review` does** and write `docs/reviews/<id>.md`. A missing or malformed verdict is a blocked review: `Max severity: critical`, `Ship allowed: no`.

`Ship allowed: no` → back to step 3 in fix mode with the complete latest report. Two loops at most; still blocked → stop and list every open finding. Never soften a verdict to move on.

## 5. Ship — checkpoint
Follow `/po-ship`: its gate, its exit checks, its confirmation per `Ship confirmation` (a real AskUserQuestion when `human`), its merge per `Merge mode`, its cleanup only on a proven merge.

End with: "Story <id> shipped." — "PR opened: <url>. Merging is yours." — or the exact blocking state: which stage, what is missing, the next command.
