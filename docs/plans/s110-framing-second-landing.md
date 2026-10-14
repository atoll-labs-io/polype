---
validated: yes
---
# Plan — s110-framing-second-landing

[Story](../stories.md) · [Research](../research/s110-framing-second-landing.md)

Branch `story/s110-framing-second-landing`. Read `docs/research/s110-framing-second-landing.md` first; this plan builds on it without repeating it.

## Story
A second landing on the same `framing/<slug>` starts from what that branch already holds, as long as it is not merged, on any forge. Once a merge is proven, the root realigns. This fixes s106 major 2 and minor 3.
- `framing_merge_is_proven_per_forge`: the proof is step 3 of `/po-ship`. With a pull request, `gh pr view` prints exactly `MERGED`. Without one (a true fast-forward forge), the head of `origin/framing/<slug>` is an ancestor of `origin/<Target branch>`. Ancestry is never the proof on GitHub.
- `second_landing_stacks_on_the_framing_branch`: `<base>` is `origin/framing/<slug>` when that branch exists and is not proven merged, open PR or not. Otherwise it is `origin/<Target branch>`. A merged branch is never a base.
- `root_realigns_after_a_merge`: before building its commit, the command realigns the root with `git merge --ff-only origin/<Target branch>` when the proof says merged. A refusal is reported, nothing is forced.

## Tasks
1. [x] **Rewrite the pr bullet of `**Base.**`** in `method/commands/po-setup.md:66`. Keep `:67` (missing ref → stop) and `:68` (local) as they are. The new bullets, in this order, in our own words:
   - `pr`: `git fetch origin`. No `origin/framing/<slug>` (`git rev-parse --verify --quiet refs/remotes/origin/framing/<slug>` fails) → `<base>` is `origin/<Target branch>`.
   - **A framing branch already on the remote is proven merged or not, as step 3 of `/po-ship` proves a ship:**
     - On GitHub, the forge `## The forge's review rule` of `method/commands/po-ship.md` recognises from `origin`, the proof is the pull request. `gh pr view framing/<slug> --json state --jq .state` prints exactly `MERGED`.
     - Any other state, or no pull request from that branch, means not merged.
     - `gh` missing or not logged in → stop. Ancestry is never the proof of a merge on GitHub, which rebuilds every commit it lands (ADR-0081).
     - On any other forge, where no pull request is opened yet and the merge is a true fast-forward (ADR-0081), the proof is `git merge-base --is-ancestor origin/framing/<slug> origin/<Target branch>`.
   - **Not merged** → `<base>` is `origin/framing/<slug>`, whether a pull request is open or not. The new commit stacks on what the branch already carries, and an open pull request carries both.
   - **Merged** → the root realigns before anything is built. Run `git merge --ff-only origin/<Target branch>` in the root. A refusal is reported and the landing carries on: no stash, checkout or reset forces it. Then run `git push origin --delete framing/<slug>`, and `<base>` is `origin/<Target branch>`. A merged branch is never taken as a base.

   Wording constraints:
   - Every line holding `git push` must also hold `framing/<slug>`.
   - No line may read "commit … on `Target branch`".
   - The sentence "A pull request already open from `framing/<slug>` (`gh pr list --head framing/<slug> --state open`) → `<base>` is `origin/framing/<slug>`" is removed. The open-PR lookup stays at `:78` for reuse only.

   Test: `test_second_landing_stacks_on_the_framing_branch` and `test_framing_merge_is_proven_per_forge` (task 3). Existing ones: `tests/framing-through-pr.test.sh` (`framing_commits_on_a_branch`, `framing_pr_fast_forwards`).
2. [x] **Say who realigns after a human merge.** In the `human` bullet of `po-setup.md:80`, add one sentence after the quoted stop message, outside the quotes. Once a person merges, the next landing of any framing command realigns the root as **Base** says. The quoted message itself stays word for word (`tests/framing-through-pr.test.sh:54`). Test: `test_root_realigns_after_a_merge` (task 3) checks that the sentence names **Base**.
3. [x] **Write `tests/framing-second-landing.test.sh`.** Header comment `# s110 — …`. Copy the `section_of` and `holds` helpers from `tests/framing-through-pr.test.sh:18-20`. Add a `base_block` helper: the lines of `## Landing the framing` from the one starting `**Base.**` to the one before `**The commit, built beside the checkout**`. Three tests, named after the criteria:
   - `test_framing_merge_is_proven_per_forge`. In `base_block`, check:
     - `gh pr view framing/<slug> --json state --jq .state`, `` `MERGED` `` and `git merge-base --is-ancestor origin/framing/<slug> origin/<Target branch>`;
     - the clause that ancestry is never the proof on GitHub (`Ancestry is never the proof of a merge on GitHub`);
     - the reference to step 3 of `/po-ship`.
   - `test_second_landing_stacks_on_the_framing_branch`. In `base_block`, check:
     - `` `<base>` is `origin/framing/<slug>`, whether a pull request is open or not `` and `A merged branch is never taken as a base`;
     - **negative**: `base_block` holds no `gh pr list --head framing/<slug> --state open`. That is the old condition, and on its own it reproduces the defect;
     - the not-merged branch precedes the merged one, so they are not confused. Offsets use `grep -bo` as in `tests/drive-guards.test.sh:20-24`.
   - `test_root_realigns_after_a_merge`. In `base_block`, check:
     - `git merge --ff-only origin/<Target branch>` (it must be in the block, since `:83` already holds it elsewhere), the refusal clause (`A refusal is reported`) and `git push origin --delete framing/<slug>`;
     - that `base_block` ends before `GIT_INDEX_FILE=<tmp> git read-tree <base>`, i.e. the realignment happens before the commit is built;
     - that the `human` bullet holds the sentence of task 2.

   Run `bash tests/run.sh framing-second-landing.test.sh framing-through-pr.test.sh overlap.test.sh`.
4. [ ] **Full suite once**, after the last edit: `po-run --story s110-framing-second-landing --label test -- 'bash tests/run.sh'`. Then fill `docs/verif/s110-framing-second-landing.md`. Not proven here: no real push, no forge merge, and no `gh pr view` on several PRs sharing one head.

## Scene viewpoints
—

## Run interdicts
- Only `method/commands/po-setup.md`, `tests/framing-second-landing.test.sh` and this story's `docs/` files change. `git diff main...story/s110-framing-second-landing --stat` lists nothing else.
- `po-setup.md` outside `## Landing the framing` stays byte for byte, and so do these lines inside it:
  - `:67`, the missing-ref stop, and `:68`, the local base;
  - `:70-74`, the commit beside the checkout;
  - `:77`, the lease push, and `:81-83`, the automatic path and its proof;
  - `:85-88`, local mode.
- `tests/framing-through-pr.test.sh` is not modified. The story changes no clause it checks.
- `.claude/`, `.polype/`, `method/AGENTS.md`, `method/commands/po-ship.md`, `po-drive.md`, `po-orchestrator.md` and `docs/parite-killer-saas.md` are not touched.
- No new ADR: the person settled the proof and `--ff-only` on 2026-10-13 (story notes, `docs/reviews/stories-m9bis.md:95`). No `git reset --keep` anywhere.
- No `git push` other than to `framing/<slug>`, and no "commit … on `Target branch`" phrasing (`tests/framing-through-pr.test.sh:39-42`).

## The pivot
The plan hinges on proving the merge per forge from the remote branch alone. If a branch is on the remote, it was left waiting by an earlier landing, and the forge's own proof decides between stacking and realigning. Ways this can be wrong:
- **`gh pr view <branch>` picks the wrong PR** when one branch has headed several PRs. An old merged PR could hide unmerged new commits, and `<base> = origin/<Target branch>` would drop them. Deleting the branch once its merge is proven (task 1) stops new cases. Compare with a real repo that has a merged and an open PR on one head.
- **A forge merges by squash or merge commit, not fast-forward.** A squash never passes ancestry, so the next landing stacks on a merged branch and reships landed content: duplicate content, not loss. A merge commit passes ancestry correctly. Compare with ADR-0081:25, which promises `ff` / `fast-forward-only`.
- **The branch is auto-deleted by the forge after merge.** `<base>` is then correct, but the root does not realign until the next automatic landing (research, Open questions). That is outside the criteria, and it is the residual of minor 3.

## Files touched
- `method/commands/po-setup.md` (the `**Base.**` block and one sentence on the `human` bullet)
- `tests/framing-second-landing.test.sh` (new)
- `docs/research/s110-framing-second-landing.md`, `docs/plans/s110-framing-second-landing.md`, `docs/verif/s110-framing-second-landing.md`

## Test strategy
The layer is text checks on a method file, the only layer this repository has. There are 3 tests, within the `Test budget` of 25, one per criterion, all scoped to the `**Base.**` block so that deleting a clause there turns one red. These are the bites the reviewer should try:
- delete the GitHub-proof sentence → `framing_merge_is_proven_per_forge`;
- restore the open-PR-only condition → the negative check of `second_landing_stacks_on_the_framing_branch`;
- move the `--ff-only` realignment out of **Base** → `root_realigns_after_a_merge`.

The existing `tests/framing-through-pr.test.sh` guards the strings that must stay. There is no visual check. The behaviour (push, forge merge, root fast-forward) was probed by hand in `/tmp` during research. It is not automated, because `po-bounds` forbids `git push` and no forge is reachable.

## Done when
The full suite is green through `po-run`, and the record is complete. A review finds no open critical. One commit `s110-framing-second-landing: Un second dépôt du même cadrage ne perd rien` lands on `main` through its pull request.
