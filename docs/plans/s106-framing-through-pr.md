---
validated: yes
---
# Plan — s106-framing-through-pr

[Story](../stories.md) · [Research](../research/s106-framing-through-pr.md)

Branch `story/s106-framing-through-pr`. Read `docs/research/s106-framing-through-pr.md` first; this plan builds on it without repeating it.

## Story
The seven framing commands (`/po-setup`, `/po-brief`, `/po-prd`, `/po-stories`, `/po-stories-review`, `/po-architect`, `/po-design-system`) commit on `framing/<slug>`, built from `Target branch`. They push the branch, open a PR and land it as a fast-forward. The agent lands it under effective `automatic`, the person under `human`. Without a remote, the fast-forward happens on the machine. No framing command commits on `Target branch` or pushes it. `/po-research` creates a worktree only when the story's section is on its start point. Otherwise it stops and says that the framing PR is waiting for its merge.
Criteria: `framing_commits_on_a_branch`, `framing_pr_fast_forwards`, `research_waits_for_framing_merge`.

## Tasks
1. [x] **`po-setup.md`: new section `## Landing the framing`**, placed after `## Step 3`. Fixed wording and order:
   - **Scope.** Every framing command lands its commit this way: this one, `/po-brief`, `/po-prd`, `/po-stories`, `/po-stories-review`, `/po-architect` and `/po-design-system` (ADR-0080, ADR-0081). The command works from the repository root, which stays on `Target branch` with no switch, checkout or stash. It never commits on `Target branch` and never pushes it. Each command names its `<slug>`, its paths and its message.
   - **Remote check**, as in `/po-ship`. `Merge mode: pr` without `origin` → stop. `local` with a remote → stop with the ADR-0080 sentence.
   - **Base.**
     - `pr`: run `git fetch origin`. A PR already open from `framing/<slug>` (`gh pr list --head framing/<slug> --state open`) → `<base>` is `origin/framing/<slug>`, so the new commit stacks on it and the same PR carries it. Otherwise `<base>` is `origin/<Target branch>`.
     - That ref missing → stop: a person pushes `Target branch` once, since no agent does.
     - `local`: `<base>` is `framing/<slug>` when that local branch exists and is not an ancestor of `Target branch`. Otherwise `<base>` is `<Target branch>`.
   - **The commit, beside the checkout** (as `po-ship.md:44`):
     - Build a temporary index: `GIT_INDEX_FILE=<tmp> git read-tree <base>`, then `GIT_INDEX_FILE=<tmp> git add -- <paths>`.
     - When `core.hooksPath` is `.polype/hooks`, run `GIT_INDEX_FILE=<tmp> .polype/hooks/po-gate.sh pre-commit`. A refusal stops the landing: `commit-tree` runs no hook.
     - Then `git write-tree` → `<tree>`, and `git commit-tree <tree> -p <base> -m "<message>"` → `<sha>`. Remove the temporary index.
     - Then `git add -- <paths>` in the root's own index. Say why: a later fast-forward of the root refuses unstaged copies of these files (research, fact 3).
   - **`pr` mode.**
     - Push with `git push --force-with-lease=framing/<slug> origin <sha>:refs/heads/framing/<slug>`. A refused push is never forced.
     - Reuse the open PR, or open one with `gh pr create --base <Target branch> --head framing/<slug>`, titled with the message.
     - On a forge where no PR is opened yet (ADR-0081), the branch is sent and the report asks a person to open the PR.
     - The effective `Ship confirmation` is the one `## The forge's review rule` of `method/commands/po-ship.md` settles, and the line is never rewritten here.
     - `human` → stop with "Framing pull request ready: <url>. Land it with Rebase and merge; /po-research starts a story only once its section is on `origin/<Target branch>`."
     - `automatic` → when the PR has checks, wait for them to pass (a failing check → stop and leave the PR open). Then `gh pr merge <url> --rebase --match-head-commit <sha>`.
     - Proof: `gh pr view <url> --json state --jq .state` prints exactly `MERGED`.
     - Then `git fetch origin`, then `git merge --ff-only origin/<Target branch>` in the root (a refusal is reported, and the landing stands), then `git push origin --delete framing/<slug>`.
   - **`local` mode.**
     - Run `git update-ref refs/heads/framing/<slug> <sha>`.
     - `human` → AskUserQuestion "Land <message> on <Target branch>?", with Merge / Not now. Not now leaves the branch, and the report says so.
     - Then `git merge --ff-only framing/<slug>` in the root, and `git branch -d framing/<slug>`. Nothing is pushed.
   - **Report.** The finish names the branch, the PR URL or local landing, and the effective `Ship confirmation` and why.
   - Fails if wrong: `test_framing_commits_on_a_branch` and `test_framing_pr_fast_forwards`.
2. [x] **`po-setup.md`, Step 3 item 4 and description.**
   - Item 4 becomes: commit `AGENTS.local.md`, `.gitignore`, `AGENTS.md`, `.claude/` and `.polype/` together (those that exist) as `chore: set up polype`, on `framing/setup`, as `## Landing the framing` says. Keep the `CLAUDE.md` sentence. "Worktrees are created from this branch: without this commit…" becomes "…from `Target branch`: until this landing is merged, they would have neither…".
   - Setup lands with the `Merge mode`, `Target branch` and effective `Ship confirmation` it has just settled.
   - `description` (`:2`): "commits the installed method" → "lands the installed method through a pull request".
   - Fails if wrong: `test_framing_commits_on_a_branch` (slug and reference per command) and `structure.test.sh` (`.claude/` and `.polype/` together).
3. [x] **The six other commands** replace their commit-on-`Target branch` sentence. Each keeps its paths, message, `git status --porcelain` check and branch check:
   - `po-brief.md:59` keeps "commit `docs/brief.md` and the ADR together in one commit, `docs: brief for <product>`", plus "on the branch `framing/brief`, landed as `## Landing the framing` of `/po-setup` says (`method/commands/po-setup.md`)". Keep the sentence "The approval and its ADR go in the same commit, or neither…". Finish step 1 keeps its branch check: the root must still be on `Target branch`.
   - `po-prd.md:57`: `framing/prd`. `po-stories.md:60`: `framing/stories`, and the fix mode (`:56`) still "follows "Finish"", so it uses the same branch. `po-stories-review.md:54`: `framing/stories-review`, keeping `:16` as it is. `po-architect.md:72`: `framing/architecture`. `po-design-system.md:74`: `framing/design-system`.
   - The `description` of brief, prd, stories, stories-review, architect and design-system: "commit(s) … on the target branch" → "land(s) … on the target branch through a pull request".
   - Add `Merge mode` and `Ship confirmation` to the `Reads settings:` line of these six, keeping `Target branch`.
   - Fails if wrong: `test_framing_commits_on_a_branch`, plus `brief.test.sh`, `stories-review.test.sh` and `conversational-framing.test.sh` kept green.
4. [x] **`po-research.md`, `## The worktree`**: a new step 2 between the fetch (`:30`) and `git worktree add`, which becomes step 3.
   - The story must have a heading line naming `<id>` (`## <id>` or `### <id>`) in `git show <start point>:docs/stories.md`.
   - Missing → stop before any worktree exists: "<id> is not on <start point> yet: its framing pull request waits for its merge. Merge it, then run /po-research <id> again."
   - Renumber the steps that follow. Keep every phrase that `research.test.sh` freezes.
   - Fails if wrong: `test_research_waits_for_framing_merge`.
5. [x] **`tests/framing-through-pr.test.sh`**, one function per criterion, using `section_of` / `holds` as `ship-follows-forge.test.sh` does:
   - `test_framing_commits_on_a_branch`:
     - `## Landing the framing` of po-setup holds `GIT_INDEX_FILE`, `git commit-tree <tree> -p <base>`, `refs/heads/framing/<slug>` and `git add -- <paths>`.
     - Each of the seven commands names its own `framing/<slug>`, and the six others name `## Landing the framing`.
     - Every `git push` line of the 7 files names `framing/<slug>`.
     - No line of the 7 files matches, case-insensitively, `commit[^.]* on (\`Target branch\`|the target branch)` or `Commit from the repository root, on \`Target branch\``.
   - `test_framing_pr_fast_forwards`: the section holds:
     - `gh pr merge <url> --rebase --match-head-commit <sha>`
     - `` `MERGED` ``
     - `git merge --ff-only origin/<Target branch>`
     - `git merge --ff-only framing/<slug>`
     - `## The forge's review rule`
     - the `human` stop sentence
     - `AskUserQuestion`
   - `test_research_waits_for_framing_merge`:
     - po-research holds `git show <start point>:docs/stories.md` and "waits for its merge".
     - That line number is below the fetch line and above `git worktree add -b story/<id>`.
   - Fails if wrong: each test fails when its clause is removed (the reviewer's bite check).
6. [x] **Checks**:
   - Run `bash tests/run.sh framing-through-pr.test.sh brief.test.sh prd.test.sh stories.test.sh stories-review.test.sh architect.test.sh design-system.test.sh conversational-framing.test.sh research.test.sh structure.test.sh ship-follows-forge.test.sh overlap.test.sh` after task 5.
   - Then the full suite once, through `po-run --story s106-framing-through-pr --label full-suite -- 'bash tests/run.sh'`. `Typecheck` is `—`.

## Scene viewpoints
—

## Run interdicts
- Only these files change: the eight owned commands, `tests/framing-through-pr.test.sh`, and the two files of this story under `docs/`. `git diff main...story/s106-framing-through-pr --stat` lists nothing else. In particular, `method/AGENTS.md`, `po-ship.md`, `po-drive.md`, `po-help.md`, `po-gate.sh` and `.claude/`/`.polype/` end with an empty diff.
- No existing test file changes.
- No `git push` written in a framing command names `Target branch` or `story/`.
- The existing guards stay word for word: `status: approved`, the brief and its ADR in one commit, s101's one-item-per-question approval, the branch checks and the `git status --porcelain` env-file checks.
- No new ADR. ADR-0083 stays unused: ADR-0080 and ADR-0081 settle the mechanism.

## The pivot
The decision: the framing commit is **built beside the checkout and landed by reference**, not by switching the root to a branch. The `## Landing the framing` procedure lives once, in `po-setup.md`. It reuses s102's temporary index and s105's `commit-tree` and `gh pr merge --rebase --match-head-commit`, and the root's index is staged so that its later fast-forward goes through. Ways it could be wrong:
1. **The root's fast-forward refuses after all.** For example, `origin/<Target branch>` changed the same paths in between, or a file was edited again after staging. Compare against the procedure: the refusal is reported, and the merge on the forge stands. Check that the text never turns that refusal into a stash or a checkout.
2. **Stacking on an open PR** (pr mode, human not yet merged) lands two commits for one framing file. Check that it never force-replaces the earlier commit and never drops its paths. The lease and the `<base>` choice in task 1 are what guarantee that.
3. **A command does not read po-setup's section** (cross-command reference). Check that each of the six commands still states its slug, paths and message itself, so that only the mechanics are referenced.

## Files touched
`method/commands/po-setup.md`, `po-brief.md`, `po-prd.md`, `po-stories.md`, `po-stories-review.md`, `po-architect.md`, `po-design-system.md`, `po-research.md`, `tests/framing-through-pr.test.sh`; `docs/research/s106-framing-through-pr.md`, `docs/plans/s106-framing-through-pr.md`.

## Test strategy
Automated tests: 3 new tests, within the `Test budget` of 25, at the one layer this repository has, the method text, in bash with `tests/lib.sh`. Each names one criterion and fails if its clause is deleted. The ordering check in test 3 fails if the story check is moved after the worktree creation.
- A scratch-repository test of git's fast-forward behaviour would test git, not the method. The research records that experiment instead.
- The existing frozen-phrase tests (research, Traps) are the regression net.

Visual checks: none (`Surface: —`).

## Done when
- The three criteria hold.
- `bash tests/run.sh` is green, with its `po-run` row in `docs/verif/s106-framing-through-pr.md`.
- The review has no open critical finding.
- The story lands as one commit `s106-framing-through-pr: Le cadrage et les réglages arrivent aussi par une PR`.
