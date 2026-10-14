# Research — s110-framing-second-landing

[Story](../stories.md)

## Structuring facts
- **Root cause (s106 major 2):** `method/commands/po-setup.md:66` decides whether to stack only from `gh pr list --head framing/<slug> --state open`. When that finds nothing (non-GitHub forge, `gh` unusable, PR never opened), `<base>` is `origin/<Target branch>`. The push at `po-setup.md:77` then replaces the branch, because after the fetch the lease matches the remote-tracking ref. Reproduced below: the branch lost the first run's file.
- **Root cause (s106 minor 3):** only the automatic pr path realigns the root (`po-setup.md:83`). The `human` path stops at `po-setup.md:80`, and nothing later checks whether the person merged.
- No story assumption is false. The proof the story cites exists: `po-ship.md:84` (`MERGED` in pr mode, `--is-ancestor` in local mode), and `ADR-0081:14,52` says ancestry never proves a GitHub merge.
- One edit covers every framing command. Brief, prd, stories, stories-review, architect, design-system, and the decisions log of `/po-drive` and `/po-orchestrator`, all land "as `## Landing the framing` of `/po-setup` says" (`po-brief.md:59`, `po-architect.md:72`, `po-drive.md:155`, `po-orchestrator.md:88`, …). So `po-setup.md` is the only method file to change.

## Diagnostic
**Reproduction** (throwaway repo under `/tmp/tmp.3GRc0fSBeO`, nothing in the worktree). I used a bare remote and a root on `main`, and ran the landing exactly as `po-setup.md:71-77` writes it: temporary index, `commit-tree`, `git add` in the root, then the lease push to `framing/architecture`.
- Run 1 lands `docs/adr-a.md`.
- Run 2 lands `docs/adr-b.md` with base `origin/main`, which is what `:66` gives when no open PR is found.
- Result: `git ls-tree origin/framing/architecture` lists only `docs/adr-b.md`. The root still stages both files, so the loss is contained, as the review said.

**Hypotheses**
1. *The stacking test rests only on an open PR* (`:66`). It would be refuted if the PR lookup were not the only input to the base. Reading `:65-68` shows no other input. **Kept.**
2. *The lease push at `:77` refuses the overwrite.* It would be refuted if the push succeeded. It did: `pushed 1a3b357…`. **Discarded.**
3. *The root fast-forward refuses after a merge, because of the staged copies or the files the second run has just edited.* It would be refuted if `git merge --ff-only origin/main` succeeded. In `/tmp`, the root had `docs/architecture.md` staged at v1 and edited to v2, plus an untracked new ADR. It succeeded in both cases: after a true fast-forward merge, and after a GitHub-style rewritten commit with the same tree and a new SHA. Both times v2 stayed in the working tree. **Discarded.** That run also showed `--is-ancestor` printing "not merged" for the rewritten commit, which is what ADR-0081 says.
4. *Nothing realigns the root after a human merge.* It would be refuted if any step after `:80` read the merge. None does, and local mode merges in the command itself (`:88`). **Kept.**

## Story
When a second landing reuses the same `framing/<slug>`, it must start from what that branch already holds as long as the branch is not merged, on any forge. Once the merge is proven, the root realigns.
- `framing_merge_is_proven_per_forge`: the proof is the one of step 3 of `/po-ship`. With a PR, `gh pr view` prints exactly `MERGED`. Without a PR (a true fast-forward forge, ADR-0081), the head of `origin/framing/<slug>` is an ancestor of `origin/<Target branch>`. Ancestry never proves a merge on GitHub.
- `second_landing_stacks_on_the_framing_branch`: `<base>` is `origin/framing/<slug>` as soon as that branch exists and the proof does not say it is merged, PR or not. Otherwise `<base>` is `origin/<Target branch>`. A merged branch is never taken as a base.
- `root_realigns_after_a_merge`: before it builds its commit, every framing command realigns the root with `git merge --ff-only origin/<Target branch>` when the proof says merged. A refusal is reported and nothing is forced.

## Current code
`po-setup.md:60-90` `## Landing the framing`:
- Remote check (`:63`).
- **Base** (`:65-68`): pr fetches and stacks only on an open PR, a missing ref stops, local stacks while `framing/<slug>` is not an ancestor.
- Commit built beside the checkout (`:70-74`).
- pr landing (`:76-83`):
  - lease push (`:77`);
  - PR reuse or creation, with "GitHub only" for opening (`:78`);
  - effective value (`:79`);
  - `human` stop sentence (`:80`);
  - automatic merge (`:81`);
  - `MERGED` proof (`:82`);
  - root `--ff-only` and branch delete (`:83`).
- Local landing (`:85-88`) and Report (`:90`).

## Attachment points
- The **Base** block, `po-setup.md:65-68`. The realignment has to sit there: it is the step after the fetch and before `**The commit, built beside the checkout**` (`:70`).
- Forge identity is already settled in `po-ship.md:27`: host `github.com` means GitHub. Refer to it, do not restate it.
- New test file `tests/framing-second-landing.test.sh`. `tests/run.sh` runs every `tests/*.test.sh` (`AGENTS.local.md`, Commands), so nothing needs registering.

## Verified interfaces
- `po-ship.md:84`, the proof in step 3: `gh pr view story/<id> --json state --jq .state` prints exactly `MERGED`. In local mode, `git merge-base --is-ancestor <sha> <Target branch>`.
- `po-setup.md:82` uses the same `MERGED` form on `<url>`. `:83` holds `git merge --ff-only origin/<Target branch>` and `git push origin --delete framing/<slug>`.
- `ADR-0081:25,27`: GitLab `ff` and Forgejo `fast-forward-only` are true fast-forwards. GitHub rebase rewrites the SHA. Only GitHub is wired.
- `--force-with-lease=framing/<slug>` with no remote-tracking ref created the branch in the `/tmp` run (first push succeeded). So deleting the merged branch before the next push is safe.
- Test helpers: `tests/lib.sh` (`fail`, `require_file`, `contains`). The section-slicing idiom `section_of` and `holds` is copied per file (`tests/framing-through-pr.test.sh:18-20`, `tests/drive-guards.test.sh:7-12`).

## Traps
- `tests/framing-through-pr.test.sh:39-40`: every line of `po-setup.md` holding `git push` must also hold `framing/<slug>`.
- `tests/framing-through-pr.test.sh:41-42`: no line may match `commit[^.]* on (\`Target branch\`|the target branch)` (case-insensitive). The new text must avoid phrasing like "the commit … on `Target branch`".
- `tests/framing-through-pr.test.sh:51-54` keep these strings intact: `'gh pr merge <url> --rebase --match-head-commit <sha>'`, `` '`MERGED`' ``, `'git merge --ff-only origin/<Target branch>'`, `'git merge --ff-only framing/<slug>'`, the `human` stop sentence, `AskUserQuestion`.
- `git merge --ff-only origin/<Target branch>` already appears at `:83`. A test for the new realignment must look inside the **Base** block, not at the whole section, or it bites nothing.
- `tests/overlap.test.sh`: write in our own words.
- `.claude/` and `.polype/` are installed copies and are not edited (`AGENTS.local.md` Conventions).
- s109 owns `po-drive.md` and `po-orchestrator.md`, and they have already shipped (`82a0341`). Both only reference the section, so they need no edit.

## Open questions
- Is `gh pr view framing/<slug>` reliable when several PRs share that head? A merged one plus a later open one is possible if the branch was reused without being deleted. Deleting the branch once its merge is proven, as `:83` already does, avoids that case from now on. I did not verify which PR `gh` picks for a branch name.
- GitHub can delete merged head branches automatically. The branch is then gone, `<base>` becomes `origin/<Target branch>` (correct), but the root is not realigned, since the AC ties realignment to a proven merge of an existing branch. The root then catches up at the next automatic landing or by hand. The plan keeps the AC's scope.
- On GitHub with `gh` unusable, neither proof is valid. The plan has to choose between stopping and stacking. Stacking on a merged branch loses nothing but reships landed content. Stopping is the conservative choice.
- When a PR from that branch exists but is `CLOSED` without a merge, it counts as not merged, so the next landing stacks on it and opens a new PR. Is that the intent? I assume yes, since nothing is lost.

## Complexity
The story says 2. After reading the code, 2: one section of one method file and one new test file, and no other method file needs to change. It goes on the full track only because of its `Corrige` line.

## Split
—
