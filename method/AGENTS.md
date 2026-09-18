# Polype — Rules

**The method owns this file. The installer rebuilds it every time, so anything you write here disappears.** Everything specific to this project — settings, project commands, conventions — lives in `AGENTS.local.md`, which the installer never touches and appends below these rules. `/po-setup` creates it. After editing it by hand, rerun the installer: settings are read from it directly, but conventions only reach an agent through this assembled file.

**Rules are the same for every project. Values differ per project and are read from `AGENTS.local.md`** — never chosen by an agent, never filled in when missing. Format: one setting per line, `Name: value`, the value being everything after the first colon, trimmed. A value of `—` means the project does not have that thing: say so, never substitute something else.

## The one rule

No code is written outside the pipeline. Every change that is not an announced quick fix is a story, and a story goes through every stage, in order:

    Setup (once) → Research → Plan → Execute → Review → Ship

No code before the story has a validated plan. Nothing ships without a passed review. The context that writes code never judges it: implementation and review each run in their own subagent.

Until the framing commands exist, stories are written by hand in `docs/stories.md`, shaped by `templates/stories.md`.

### Quick fix — the only exception

Only when the user explicitly asks for it, and only for a change that is small, local, well understood and trivially reversible: a color, a spacing, a radius, a font size, a button style, short UI copy, a translation, a responsive nudge, restoring an existing affordance. The main agent edits directly; it may delegate investigation or review, never implementation.

It never covers: a feature, a redesign of a shared component, a data model or migration, an API or contract change, authorization, security, business rules, persistence, a cross-cutting refactor, a dependency change, or anything whose impact is unclear. If the change turns out to be one of these, stop, say so, recommend the pipeline, and write nothing more until the story has gone through the right stages.

Announce the mode and the exact scope before the first edit, keep the diff minimal, keep existing abstractions, and verify in proportion: a focused lint, typecheck or test, or a look at the screen. A quick fix happens in the repository base directory on `Target branch`, never in a story worktree, and never on files a running story owns.

## Commands

Per story: `/po-research` → `/po-plan` → `/po-execute` → `/po-review` → `/po-ship`. `/po-orchestrator` chains them with the human checkpoints; `/po-status` shows where every story stands; `/po-help` prints the map. Each command's own file is its contract.

**Always run the command; never write the agent call yourself.** A command carries what the pipeline has learned — fix mode, the subagent definitions, the gates. A hand-written briefing replaces all of that with an opinion.

## Where work happens

| Mode | Directory | Branch |
| --- | --- | --- |
| Announced quick fix | Repository base directory | `Target branch`; anything else checked out → stop and ask |
| Story | `<Worktree root><id>/` | exactly `story/<id>` |

A story lives in its own worktree from its first stage to its last, whatever its size. Never create or check out a story branch in the repository base directory.

`/po-research` creates the worktree or verifies it: `git worktree add` from `Target branch`, the untracked `.env*` files copied in, dependencies installed with the project's `Install` command. It never runs a baseline test suite — the state of `Target branch` is not this story's problem. Every later stage resolves the absolute path and checks the branch. A missing worktree, a wrong branch, a detached HEAD or two candidate branches is a hard stop: never `git switch`, `checkout`, `stash`, or an improvised variant of the path.

One directory, one agent. While an agent works in a worktree, nobody else edits, checks out or stashes there.

## Stories and defects

`docs/stories.md` is the product's perimeter: a story is a capability the product gains. **A defect is not a story** — a bug, a stale assertion, a screen that renders wrong goes to the issue tracker (`Issue tracker`), or it inflates the perimeter with work nobody scoped. **A review finding stays in its review report** unless a human decides otherwise: it is already traced there, with its `file:line`.

## Ids and branches

- Every story has an id `s<number>-<short-slug>` (e.g. `s03-export-invoice`), given in `docs/stories.md` and reused verbatim: `docs/research/<id>.md`, `docs/plans/<id>.md`, `docs/verif/<id>.md`, `docs/reviews/<id>.md`, branch `story/<id>`.
- A story's diff is `git diff <Target branch>...story/<id>`. That diff is what the review judges.
- A command given a fuzzy story name resolves it against `docs/stories.md`; without an unambiguous match it lists the stories and stops.

## Gates

All three are file checks — a grep or a tree comparison — so they hold whatever tool runs them. `hooks/po-gate.sh` implements them.

| Gate | Passes when | Blocks |
| --- | --- | --- |
| Plan validated | `docs/plans/<id>.md` frontmatter has `validated: yes` | `/po-execute`, and any code commit on `story/<id>` (pre-commit hook) |
| Verification current | `docs/verif/<id>.md` is complete and its `Tree:` equals the committed code outside `docs/` | nothing by itself — it decides whether the review trusts the recorded run or replays it |
| Ship allowed | `docs/reviews/<id>.md` has the exact line `Ship allowed: yes` | `/po-ship`, entirely |

- A plan file that merely exists is not validated. A missing verification record is never a pass. A missing or malformed verdict is a blocked review.
- **Only a critical finding blocks.** A major is a real defect, traced in the report and fixed in a later cycle; a minor is style. Neither reopens a fix loop. After a blocked review, `/po-execute` runs in fix mode, findings first. Two loops at most.

## Ship

`Merge mode: pr` opens a pull request against `Target branch`; `local` merges locally with no review platform. `Ship confirmation: human` asks before any merge; `automatic` merges after the gate. Whatever the mode, **the merge is a squash**: one story, one commit on `Target branch`. Cleanup happens only after the merge is proven.

## Documents

Everything the pipeline produces is markdown under `docs/`, versioned by git.

- **Framing documents** (`docs/stories.md`, `docs/architecture.md` when present) are committed on `Target branch`. **Story documents** (research, plan, verification record, review) travel on `story/<id>`: every pull request carries its own evidence.
- **Size caps**: research ~200 lines, plan ~250, review ~150. Several agents read each file and pay for its length. Cut prose, never decision tables.
- **Progress** is the checkboxes of `docs/plans/<id>.md`, ticked as tasks land. The plan tracks progress; it never triggers a commit.
- **One commit per story**, not per task. A second commit only for something you would revert on its own, typically a migration.
- **Decisions** are ADRs in `docs/decisions/NNNN-<slug>.md` (`templates/adr.md`): context, options rejected and why, consequences. Never edited once accepted — superseded by a new one. Framing decisions land on `Target branch`; a story's decisions travel with its branch.

## Testing

`Test budget` tests per story; more only when the plan says why. **A test that stays green when the rule it names is deleted is worse than no test.** Each deterministic check runs once in the cycle: the focused suite after each task, the full suite and the type check once after the last task, the end-to-end suite and the production build once at ship. Where tests go, the cuts, the shapes of a test that proves nothing, and when to run what: the `testing-doctrine` skill, preloaded in the implementer and the reviewer.

## Conventions

Technical conventions live in `AGENTS.local.md` under "Project conventions".

## Installed files

Commands, agents and skills live under `.claude/`. The method's templates live in `.polype/templates/`: `templates/<name>.md` anywhere in these rules or in a command means `.polype/templates/<name>.md`. `po-gate` means `.polype/hooks/po-gate.sh`, run from the repository root or a story worktree.

## Never edit an installed file

Commands, agents and skills under `.claude/`, and everything under `.polype/`, are replaced on the next install, silently. What is specific to this project becomes a setting in `AGENTS.local.md`; what is a real improvement goes back into Polype's own sources.

## Definition of done (per story)

- One pull request or one squash commit, with a structured description and a readable diff
- Business-logic tests green, no regression
- Review passed: no open critical finding
- Deployed, when the project has a deployment
