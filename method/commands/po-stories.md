---
description: Cut the approved PRD or brief into stories an agent can build without asking, and land docs/stories.md on the target branch through a pull request
argument-hint: [story ids sent back by /po-stories-review]
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
  - AskUserQuestion
---
# /po-stories

Reads settings: `Entry mode`, `Target branch`, `Platform`, `Merge mode`, `Ship confirmation`

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
4. Draft each story in full from `templates/stories.md`: the user story, complexity, dependencies, surface, Owns, acceptance criteria, notes for the agent.
5. Put the stories to the user in order, one story per question, with AskUserQuestion: each summarised as what the story delivers, why, and its acceptance criteria, which the user answers Approve / Change / Set aside.
   - The summary aims short and grows when the subject needs it: no fact needed to decide is cut to keep it short.
   - Each item is written only once approved, and the commit asks for no rereading.
   - Change → back to "Before writing" for that story, then ask about it again. Set aside → the story leaves the draft, and "Before writing" runs again on what remains, since a dependency may now be broken.
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

## A story sent back by the review
`$ARGUMENTS` holding story ids sent back by `/po-stories-review` → this section replaces the sequence: the command rewrites (Fix) or removes (Set the story aside) those stories, plus the ones a removal breaks (the next bullets), and no other; the review's outcome names only the first group.
- Each story keeps its id. A story with a `story/<id>` branch or a `docs/research/<id>.md` has already started → stop and say that it has already started; it is not reopened here.
- A rewritten story goes through "Before writing", then through the one-story question of step 5, and is written in place once approved.
- A story set aside leaves the file, and "Before writing" runs again on the stories that remain, since a dependency or an `Owns` overlap may now be broken. A remaining story that now fails is put to the user through the one-story question of step 5 with its fix, and written in place once approved; one with a branch or a research file → stop and say so, as above.
- This section is the one exception to step 6: only a story sent back by `/po-stories-review`, or broken by a removal, that has not started is rewritten or removed.
- The commit follows "Finish" (steps 1 and 2), with the message `docs: stories fixed after review`, on the same branch `framing/stories`. The command ends with "Stories fixed. Next: /po-stories-review", never with the finish line of "Finish".

## Finish
1. Every story was approved on its own question; nothing is shown again for reading.
2. Work from the repository root, which must be on `Target branch`; another branch → stop and say so. Check `git status --porcelain` first: an environment file listed there → stop. Commit `docs/stories.md` alone as `docs: stories for <product>`, on the branch `framing/stories`, landed as `## Landing the framing` of `/po-setup` says (`method/commands/po-setup.md`).

Finish with: "Stories written. Next: /po-research <first story id>"
