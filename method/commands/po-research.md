---
description: Explore a story's real context in its own worktree before it is planned — current code, verified APIs, false premises, traps
argument-hint: <story id or name>
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash
---
# /po-research — What the code really says about this story

Reads settings: `Target branch`, `Worktree root`, `Install`

Target story: $ARGUMENTS

You produce verified context, not a plan and not code. Your only write is `docs/research/<id>.md` inside the story's worktree.

## 0. Settings and story (fail-closed)
- `AGENTS.local.md` missing → STOP: "No project settings. Run /po-setup."
- Resolve $ARGUMENTS to an id `s<number>-<slug>` in `docs/stories.md`. No unambiguous match → list the stories and stop.

## 1. Workspace
The story's workspace is `<repository root>/<Worktree root><id>` on branch `story/<id>`.
- **Absent** → `git worktree add -b story/<id> <path> <Target branch>`, copy every untracked `.env*` file of the repository root into it, then run the project's `Install` command there (`—` → skip and say so). Never run the test suite: the state of `Target branch` is not this story's problem.
- **Present** → verify it is a worktree of this repository, on exactly `story/<id>`, not detached.
- Any mismatch — wrong branch, detached HEAD, the path is the repository root, the branch is checked out elsewhere → STOP and report it. Never `git switch`, `checkout`, `stash`, or pick another path.

Report the absolute path, the branch, and the names of the environment files copied (never their values). Every read and write below happens in that worktree.

## 2. Research
Read the target story in `docs/stories.md`, `docs/architecture.md` if it exists, and `AGENTS.md`. Apply the `codebase-analysis` skill to the story's scope: the code as it is today, not as the documents describe it.

1. Isolate the story and its acceptance criteria.
2. Find the files the story really touches and what they do now.
3. **Check the story's premise.** A story asserts things about the code: this guard reads that field, this function handles that case, this screen shows that state. Open each one and check the name, the signature, the location **and the behaviour on the story's own case**. Never assert from memory. A function that exists but fails on the story's input breaks the premise: that goes first in the report, and the fix belongs in the story, not in a workaround at planning.
4. Find the traps: existing tests that will run, coupling between modules, code a previous story changed.
5. Write what you could not settle under "Open questions". An honest unknown is worth more than a plausible guess.
6. Score the complexity again now that the code is read, on the scale in `templates/stories.md`, and compare with the story's score. A 5 comes with a split proposal.

## 3. Write
`docs/research/<id>.md`, shaped by `templates/research.md`. **At most ~200 lines**: three agents read it after you. Keep whatever carries a decision — broken premises, migration or not, name collisions, open questions, complexity — and cut the narrative. A verified fact is a `path:line`, not a paragraph.

Do not commit: the implementer's single story commit carries this file.

End with: "Research ready in docs/research/<id>.md (worktree <path>). Next: /po-plan <id>"
