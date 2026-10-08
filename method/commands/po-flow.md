---
description: Short track for a simple story — research and plan in one pass, then the same execute, review and ship cycle with every gate intact
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
  - Agent
  - AskUserQuestion
---
# /po-flow

Reads settings: `Target branch`, `Worktree root`, `Install`, `Story track`, `Flow threshold`, `Plan validation`, `Test budget`, `Verification mode`, `Full suite`, `Merge mode`, `Ship confirmation`, `Model strong`, `Model light`, `Light up to`

Story: $ARGUMENTS

A small story should not pay for six contexts. Here this context does the research and the plan together, then coordinates the rest; the `implementer` writes the code and the `reviewer` judges it, each in its own context. Three contexts in all. This command writes the worktree and the plan, never a source file.

The research and plan this command writes in its own context run on the session's model, which no command can choose (ADR-0036); start the session on `Model strong` for them. Only the implementer and the reviewer get a model passed to them.

## Checks
1. No `AGENTS.local.md` → stop and point to `/po-setup`.
2. Match $ARGUMENTS to one id of `docs/stories.md`; none or several → list the ids and stop.
3. No Agent tool available → say so and stop: the implementer and the reviewer cannot be delegated, and this context does not stand in for them.

## Which track
Read `Story track` before anything else.
- `Story track` is `full` → refuse: every story walks every stage in this project. Point to `/po-research <id>`.
- `flow` → the short track is accepted for any story.
- `auto` → accepted only when the story's complexity, as written in `docs/stories.md`, is at most `Flow threshold`. Above it, refuse and point to `/po-research <id>`. A story that states no complexity cannot be compared with the threshold: refuse it too, and say the story needs a complexity or the full track.

A missing setting is a stop, never a guess: a model setting missing → stop and name it.

## Escalation signals
Five signals send a story to the full track:
- a migration;
- a new screen;
- authorization or tenant scope;
- an API contract;
- a new dependency.

They are checked twice. First on the story text, before reading the code and before any worktree exists: a signal there → stop and point to `/po-research <id>`. Then after reading the code, since the code often shows what the story left out.

A single signal is enough, at either check. Found after reading the code, the worktree already exists: keep it as it is, write no plan, and point to `/po-research <id>`, which reuses that worktree.

A story that needs more than about six tasks escalates the same way.

## The worktree
Create it, or confirm it, exactly as `/po-research` does: path `<repository root>/<Worktree root><id>`, branch `story/<id>`, started from the freshest `Target branch` (after a fetch when a remote exists), ignored `.env*` files copied in and any tracked `.env*` refused, `Install` run (or reported absent with `Install: —`), the tests not run. An existing worktree on any branch other than `story/<id>`, or on a detached HEAD, ends the command; no `switch`, `checkout` or `stash`.

From here on, work only inside that path.

## Reading the code
Read the story, `AGENTS.md`, `docs/architecture.md` when it exists and the accepted ADRs, then use the `codebase-analysis` skill on the code the story touches. Open every assumption the story makes and check it: name, signature, location, behaviour on this story's inputs. A wrong assumption is written first in the plan's facts; the story is corrected, not worked around.

Then run the second signal check described above.

## The plan
Fill `templates/plan-flow.md` into `docs/plans/<id>.md`: frontmatter `track: flow` and `validated: no`, verified facts with their `path:line`, the five signals each marked absent with where it was checked, six tasks at most, each naming the test that would fail if it were wrong. Tests follow the `testing-doctrine` skill and stay within `Test budget`. About 150 lines at most.

Leave the plan uncommitted; the implementer commits it with the code.

## Approval
The rule of `/po-plan`, per `Plan validation`:
- `human`: AskUserQuestion "Approve the plan for <id>?" with the facts, tasks and test strategy summarised; answers Approve / Change / Stop. Write `validated: yes` into the frontmatter on Approve only.
- `autonomous`: check the plan against each acceptance criterion yourself, write `validated: yes`, and say that no human reviewed it.

Without `validated: yes`, nothing below starts.

## Execute, review, ship
Each stage follows its own command file, word for word; this section only names the differences.

1. **Execute** — delegate as `/po-execute` does: its preconditions, then the Agent tool with `subagent_type: implementer`, its model chosen by `/po-execute`'s `## Model` (`Model light` up to `Light up to`, `Model strong` above), and the prompt of `/po-execute`, with this sentence appended:
   > This story is on the short track: there is no docs/research/<id>.md. The `## Verified facts` section of the plan takes its place.
2. **Review** — delegate as `/po-review` does: Agent tool with `subagent_type: reviewer`, `model:` set to `Model strong`, and the prompt of `/po-review`, `Fix loop:` counted the same way, with the same short-track sentence appended. Record the answer in `docs/reviews/<id>.md` as `/po-review` says; an answer without both verdict lines is recorded as blocked.
3. **Fix loops** — before any fix run, a review with `Review status: blocked` and a `Next action:` naming `/po-qa` → stop with "Review blocked on QA for <id>. Run /po-qa <id>, then /po-review <id> again; no fix run is spent."; with `Review status: blocked` and a `Next action:` naming the `<id>: QA evidence` commit → stop with "Review blocked on uncommitted QA evidence for <id>. Commit it alone: git commit -m "<id>: QA evidence" -- docs/qa/<id>/, then /po-review <id> again; no fix run is spent."; neither spends a fix run, since `/po-flow` runs no QA itself (ADR-0041). Any other `Ship allowed: no` → a fix run of the implementer, on the same model rule as its first run, then a new review on `Model strong`. After two fix runs still blocked, stop and hand the open findings to a human.
4. **Ship** — `Ship allowed: yes` → apply `/po-ship` from its Step 0: the verdict gate, the expensive checks once, the squash merge per `Merge mode` and `Ship confirmation`, cleanup only after proof.

## Nothing is relaxed
Only the number of contexts goes down. The story still has:
- its own worktree on `story/<id>`;
- a plan that must hold `validated: yes` before any code;
- code written by a delegated implementer and judged by a delegated reviewer, never by this context;
- a ship that requires `Ship allowed: yes`;
- at most `Test budget` tests unless the plan argues for more.

Finish with one of: "<id> shipped: <hash or url>. Next: /po-status" · "Pull request ready: <url>." · "<id> leaves the short track: <signal or reason>. Next: /po-research <id>" · the exact step that stopped, what is missing, and the command to run next.
