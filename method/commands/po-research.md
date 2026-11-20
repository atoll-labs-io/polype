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

## By hand
A subagent skips this paragraph. This research runs on the session's model, which no command can choose (ADR-0036); start the session on `Model strong`. After step 1 of `## The worktree`, run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" next` and read the story's entry as `/po-drive <id>` does; `po` missing or exiting 2 → stop, naming `polype install`; no `AGENTS.local.md` → stop, naming `/po-setup`. Go on only on `plan` with reason `ready` or `no research`. Any other entry, or a warning naming the story, is reported, an `ask` as a question for the person, and ends the command. At the end, report a new `po next` entry likewise.

## The worktree
Path: `<repository root>/<Worktree root><id>`. Branch: `story/<id>`.

`/po-drive` prepares each lane by these steps; reason `no research` means the worktree is already there.

If it does not exist yet:
1. When the repository has a remote, `git fetch` it, and start from `origin/<Target branch>` if that ref exists; otherwise start from the local `Target branch`.
2. `git worktree add -b story/<id> <path> <start point>`.
3. Copy into it the environment files git ignores: `git ls-files --others --ignored --exclude-standard -- '.env*'`. If an `.env*` file exists that git does **not** ignore, stop: it would be committed. Ask for it to be added to `.gitignore` first.
4. Run `Install` inside the worktree; with `Install: —`, say so and skip it. Do not run the tests.

Report the absolute path, the branch, the start point and the names (never the contents) of the environment files copied. From here on, work only inside that path.

## The investigation
Read the story, `AGENTS.md`, `docs/architecture.md` when it exists, and the accepted ADRs. Use the `codebase-analysis` skill on the part of the code the story touches. A story carrying a `Fixes` line (`Corrige` in a French stories file) fixes a defect: run this investigation under the `diagnostic` skill, which writes the root cause first and stops after three discarded hypotheses.

**Test the story's assumptions against the code.** Each thing the story takes for granted — a field exists, a function handles a case, a screen shows a state — gets opened and checked: name, signature, location, and what it does with this story's inputs. An assumption that turns out false goes at the very top of the report; the story gets corrected, the plan does not work around it.

## The report
Fill `templates/research.md` into `docs/research/<id>.md`, **200 lines at most**: the planner, the implementer and the reviewer will all read it. Every fact carries its `path:line`. Keep decisions and doubts, drop narration.

Leave it uncommitted; the implementer commits it with the code.

Finish with "Research written to docs/research/<id>.md in <path>."
