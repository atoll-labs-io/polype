# Review — s110-framing-second-landing

[Story](../stories.md) · [Plan](../plans/s110-framing-second-landing.md) · [Verification](../verif/s110-framing-second-landing.md)

I added the `Review status:` line under the title, where `templates/review.md` puts it, and laid the header out like the template. The findings and verdict are unchanged. The tree has not moved: `git rev-parse 'story/s110-framing-second-landing^{tree}'` still prints 7016ddd52df8d9b30686209a8dd6441260e5a42a.

Diff reviewed: `git diff main...story/s110-framing-second-landing` (commit 20348c8), in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 7016ddd52df8d9b30686209a8dd6441260e5a42a

Lenses run: none. No security, migration, dependency or performance trigger: the diff is one method markdown file and one bash text test.

## Ownership
- **Paths changed:** `method/commands/po-setup.md` and `tests/framing-second-landing.test.sh`. Both are on the story's `Owns` line (docs/stories.md:1708).
- **Pipeline files:** the story's own research, plan and verification record, which are in scope by construction.
- **Other lanes:** the only other running lane is s111-tech-choice-backstop. Its `Owns` covers neither file.
- **ADRs:** none added or modified.

## Step 1 — Verification record reused
- `po-gate verif-current s110-framing-second-landing` exited 0.
- The record is complete: the unit suite (`bash tests/run.sh`) exited 0 on code identical outside `docs/`.
- The project has no type check (`Typecheck: —`), so none was run.
- I relied on the record's "Not proven here": no real push, no forge merge, and no `gh pr view` on several pull requests sharing one head.
- The story does not go to QA (`QA stage: —`).

## Step 2 — References
All of these exist and match what the diff says:
- `## The forge's review rule` of `po-ship.md`, which tells the forge from `origin`.
- Step 3 of `/po-ship`: `gh pr view … --json state --jq .state` must print exactly `MERGED`.
- ADR-0081: GitLab `ff`, Forgejo `fast-forward-only`, and GitHub's rebase that rewrites every SHA.
- The helper shapes copied from `tests/framing-through-pr.test.sh`.

## Step 3 — Diff against the plan
- **Task 1:** the `**Base.**` block was rewritten in the planned order. The open-PR-only condition is removed; lines :67 and :68 are kept.
- **Task 2:** the sentence was added after the quoted `human` message, and that message is unchanged.
- **Task 3:** three tests, one per acceptance criterion.
- **Task 4:** done (a `po-run` row exists and the record is filled), but its checkbox is still unticked (finding 4).
- **Run interdicts, all respected:**
  - the rest of `po-setup.md` is unchanged;
  - no `git reset --keep`;
  - every `git push` line names `framing/<slug>`;
  - no new ADR;
  - `framing-through-pr.test.sh` is untouched.

## Step 4 — Tests
- **Floor:** `po-gate floor-guard s110-framing-second-landing main` exited 0.
- **Budget:** 3 tests, within the budget of 25. None of the six kinds of test that prove nothing.
- **Bite:** each mutation changed `method/commands/po-setup.md`, and only `framing-second-landing.test.sh` was run after it. Each was undone and confirmed restored with `git diff --exit-code`.

| # | Mutation | Tests failing |
|---|---|---|
| 1 | Removed the "`gh` missing … Ancestry is never the proof of a merge on GitHub …" clause | 1 (`framing_merge_is_proven_per_forge`) |
| 2 | Put back the `gh pr list --head framing/<slug> --state open` condition | 1 (`second_landing_stacks_on_the_framing_branch`) |
| 3 | Removed the `--ff-only` realignment and its refusal clause from Base | 1 (`root_realigns_after_a_merge`) |
| 4 | Changed "Any other state, or no pull request …, means not merged" to "means merged" | **0** |
| 5 | Removed the sentence added to the `human` bullet | 1 (`root_realigns_after_a_merge`) |

## Steps 5 and 6 — Values and neighbours
- The exact `MERGED` match, `--ff-only` and the branch deletion are the same as in the existing automatic path and in step 3 of `/po-ship`.
- No other method file restates the framing Base: `framing/<slug>` appears only in `po-setup.md`, and the other framing commands point to this section.

## Findings

1. **major — the new sentence in the `human` bullet promises more than Base does.**
   - **Where:** `method/commands/po-setup.md`, the `human` bullet: "Once a person merges, the next landing of any framing command realigns the root as **Base** says."
   - **Why it is wrong:** Base only checks the merge of the landing command's own `framing/<slug>`, and each command has its own slug. For example, after a person merges `framing/architect`, a `/po-stories` landing on `framing/stories` never checks `framing/architect`. So it neither realigns the root because of that merge nor deletes that stale remote branch.
   - **Why it is only major:** no content is lost. The next landing on the same slug, or the automatic path, fast-forwards everything. But the sentence claims that the leftover of s106 minor 3 is closed, when it is only closed for each slug separately.
   - **Fix:** say "the next landing on that same `framing/<slug>`", or make Base check every waiting `framing/*` branch.

2. **minor — one rule has no test.** Inverting "Any other state, or no pull request from that branch, means not merged" fails no test (bite 4). Only the `` `MERGED` `` token is checked. If a CLOSED or OPEN pull request were read as merged, the bug of losing a landing's content on GitHub would come back. The fix is to assert this clause in `test_framing_merge_is_proven_per_forge`.

3. **minor — one check is nearly empty.** In `test_root_realigns_after_a_merge`, the check that `**The commit, built beside the checkout**` comes before `GIT_INDEX_FILE=<tmp> git read-tree <base>` only tests the file's fixed layout, which always holds. What actually proves the realignment happens before the build is the `holds` check on `base_block`, which bite 3 confirmed.

4. **minor — progress bar.** Task 4 in `docs/plans/s110-framing-second-landing.md` is still `[ ]`, although the record shows its `po-run` row and a complete status.

5. **minor — wording.**
   - The unchanged line "That ref missing → stop" now comes after the Merged bullet instead of the bullet that names `origin/<Target branch>`. So "that ref" is less clear, and the stop is reached only after the ancestry proof has already used `origin/<Target branch>`.
   - "→ stop: Ancestry …" has a capital letter after a colon, there only to match the test string.

6. **minor — a behaviour change the criterion requires, for a person to note.** On GitHub, a framing pull request that a person *closed* to reject it now counts as not merged. The next landing on that slug stacks on its commits and carries them into a new pull request. The criterion asks for exactly this ("qu'une pull request soit ouverte ou non"), so it is not a defect against the story. But nobody recorded this product consequence.

## Not verified
- **A real forge.** No push, no pull request, no forge merge and no `gh pr view framing/<slug>` were run against GitHub: `po-bounds` forbids `git push` and no forge is reachable here. A person should try this on a scratch GitHub repo:
  - land twice on one slug and check that both commits survive in one pull request;
  - merge it, then land a third time and check that the root realigns and the branch is deleted.
- **Several pull requests from one branch.** I did not check which pull request `gh pr view <branch>` picks when one head branch has a merged one and an open one. This is the plan's own main risk. Reproduce it on a scratch repo and inspect `--json state`.
- **Forgejo, Gitea and GitLab.** The ancestry proof is untested on any of them, and ADR-0081 itself says Forgejo's `fast-forward-only` is not verified on a real instance. A squash merge would never pass the ancestry check, so landed content would be shipped again as duplicates.
- **A branch the forge auto-deletes after merge.** Base then takes the "no remote branch" path, and the root is not realigned until a later automatic landing. The plan acknowledges this; I did not probe it.
- **The research probes.** The hand probes in `/tmp` cited by the plan and the record were not rerun.

Max severity: major
Ship allowed: yes
