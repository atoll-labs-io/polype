---
description: Opens a story's worktree and finds out what the code actually does around it — before anyone plans
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
---
# /po-research

Reads settings: `Target branch`, `Worktree root`, `Install`

Story: $ARGUMENTS

Output of this command: a worktree and one file, `docs/research/<id>.md`. Nothing is planned here and no source file is touched.

## Checks first
- No `AGENTS.local.md` → stop and point to `/po-setup`.
- Match $ARGUMENTS to one id of `docs/stories.md`. None or several → list the ids and stop.
- `docs/reviews/stories.md` missing on `Target branch`, or its last `Stories ready:` line not `yes` → warn that the stories have not passed their review, suggest /po-stories-review, and carry on: this check never blocks.

## The worktree
Path: `<repository root>/<Worktree root><id>`. Branch: `story/<id>`.

If it does not exist yet:
1. When the repository has a remote, `git fetch` it, and start from `origin/<Target branch>` if that ref exists; otherwise start from the local `Target branch`. A story must see every story merged before it.
2. `git worktree add -b story/<id> <path> <start point>`.
3. Copy into it the environment files git ignores: `git ls-files --others --ignored --exclude-standard -- '.env*'`. If an `.env*` file exists that git does **not** ignore, stop: it would be committed. Ask for it to be added to `.gitignore` first.
4. Run `Install` inside the worktree; with `Install: —`, say so and skip it. Do not run the tests.

If it exists: confirm with `git -C <path> rev-parse --abbrev-ref HEAD` that it is on `story/<id>`, and with `git worktree list` that this path belongs to this repository. Anything else — detached HEAD, other branch, branch used by another worktree, path equal to the repository root — ends the command with a description of what you found. Do not repair it with `switch`, `checkout` or `stash`.

Report the absolute path, the branch, the start point and the names (never the contents) of the environment files copied. From here on, work only inside that path.

## The investigation
Read the story, `AGENTS.md`, `docs/architecture.md` when it exists, and the accepted ADRs. Use the `codebase-analysis` skill on the part of the code the story touches.

1. Restate the story and its acceptance criteria.
2. Find the files it will touch and describe what they do today.
3. **Test the story's assumptions against the code.** Each thing the story takes for granted — a field exists, a function handles a case, a screen shows a state — gets opened and checked: name, signature, location, and what it does with this story's inputs. An assumption that turns out false goes at the very top of the report; the story gets corrected, the plan does not work around it.
4. Note the traps: tests that will run, modules that depend on each other, code a previous story changed, whether a migration is needed.
5. Anything still uncertain goes into the "Open questions" section as a question, never into the report as a fact.
6. Give your own complexity score now that you have read the code, on the scale of `templates/stories.md`, and compare it with the story's. At 5, propose how to split.

## The report
Fill `templates/research.md` into `docs/research/<id>.md`, **200 lines at most**: the planner, the implementer and the reviewer will all read it. Every fact carries its `path:line`. Keep decisions and doubts, drop narration.

Leave it uncommitted; the implementer commits it with the code.

Finish with: "Research written to docs/research/<id>.md in <path>. Next: /po-plan <id>"
