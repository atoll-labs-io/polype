---
description: Cut the approved PRD or brief into stories an agent can build without asking, and commit docs/stories.md on the target branch
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
  - AskUserQuestion
---
# /po-stories

Reads settings: `Entry mode`, `Target branch`, `Platform`

Every later stage reads `docs/stories.md`: research checks its hypotheses, the plan cuts its criteria into tasks, the review holds the code to them. This command writes that file from the framing document the project already approved. The source comes from the settings, never from an argument.

## Checks
1. No `AGENTS.local.md` → stop: "Run /po-setup first."
2. Read `Entry mode`.
   - `replace` or `adapt` → the source is `docs/prd.md`. Missing, or its frontmatter does not say `status: approved` → stop: "No approved PRD yet: run /po-prd <target SaaS> first."
   - `new` → the source is `docs/brief.md`. Missing, or its frontmatter does not say `status: approved` → stop: "No approved brief yet: run /po-brief first."
   - `—` → stop: "`Entry mode` is not set: run /po-setup or set it in AGENTS.local.md." Do not guess the source from whichever file exists.
   - Whatever the mode, a source whose frontmatter carries anything other than `status: approved` — `status: interviewing`, a draft, no frontmatter at all — is refused like a missing one: stop, name that file and say it is still being written. Never read its body to decide it is approved enough.
3. `Platform` missing → stop and name it: `/po-setup` writes it, and `polype update` lists it to a project set up before it.
4. Read the `agentic-stories` skill before drafting. It holds how a story is cut and written; this command does not repeat it.

## Sequence
1. Read the source in full. From a PRD, keep the core loop, the angle and the graveyard at hand; from a brief, the wedge, the non-goals and the premises.
2. Draft the list of stories: id, title, complexity, dependencies, surface and Owns for each, in dependency order.
3. Run the checks of "Before writing" on the draft and fix what fails.
4. Show the list to the user and get explicit agreement. A change of scope, order or split goes back to step 3.
5. Write each story in full from `templates/stories.md`: the user story, complexity, dependencies, surface, Owns, acceptance criteria, notes for the agent.
6. `docs/stories.md` already exists → append the new stories after the existing ones, numbered from the next free `s<n>`. Existing ids and stories are never renumbered or rewritten: branches and files already carry them.

## Before writing
Go through the draft story by story; a failed line is fixed before anything is written.
- [ ] Every story is a vertical slice a user can try; the only exception is a contract story, as the skill defines it.
- [ ] Every complexity 5 is split into smaller stories; none is left for the planner.
- [ ] Every complexity 4 names its main risk in its notes.
- [ ] Dependency order holds: no story depends on a story placed after it.
- [ ] Every story traces to the core loop or the angle (PRD), or to the wedge or a premise (brief).
- [ ] In `replace` or `adapt`, no story brings back a graveyard feature, under its own name or another.
- [ ] Every story declares Owns, and two stories whose `Owns` entries overlap, by the overlap rule of check 8 of the `stories-review` skill, depend on one another.
- [ ] Every story carries a `Surface` the project's `Platform` admits, by the table of the `agentic-stories` skill, or `—`.
- [ ] Every interface shared by two stories is an earlier contract story they both depend on.

## Finish
1. Show the whole `docs/stories.md` and ask the user to read it end to end; wait for explicit agreement.
2. Commit from the repository root, on `Target branch` only; another branch → stop and say so. Check `git status --porcelain` first: an environment file listed there → stop. Commit `docs/stories.md` alone as `docs: stories for <product>`.

Finish with: "Stories written. Next: /po-research <first story id>"
