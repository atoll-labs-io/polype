# Review — s124-framing-commands-cleanup

[Story](../stories.md) · [Plan](../plans/s124-framing-commands-cleanup.md) · [Verification](../verif/s124-framing-commands-cleanup.md)

Review status: complete
Reviewed tree: e30f8fb3b1e3fd5070651d5d7f2da1286a6da8cb
Fix loop: 0
Scope: `git diff main...story/s124-framing-commands-cleanup` (merge base 6830ec4, one commit 48a3d94)
Lenses run: none (no path or content in the diff triggers Security, Migration, Dependencies or Performance)

## Scope check (Owns)
Changed files: `method/commands/po-architect.md`, `method/commands/po-setup.md`, `method/commands/po-stories-review.md`, `method/commands/po-stories.md`, `method/templates/prd.md`, `tests/framing-commands-cleanup.test.sh` (new), `tests/framing-second-landing.test.sh`, and the story's own evidence (`docs/research/`, `docs/plans/`, `docs/verif/` for s124).
- Every code path is covered by the story's `Owns` (`docs/stories.md:1929`). Nothing is outside it.
- `method/commands/po-setup.md` is also in s127's `Owns` (main's `docs/stories.md:1971`). That is not a conflict: s127 depends on s124, has no worktree in `git worktree list`, and is not running. The only other running lane, s126 (worktree at 258e693), owns `po-plan.md`, `po-flow.md`, `planner.md`, `po-research.md`, `po-orchestrator.md`, `plan-flow.md` and three tests. None of them overlap.
- Line `po-setup.md:79` (the secret scan, triage row 142) is unchanged, as the plan's run interdict asks. It is left to s127.

## Evidence reused
- `po-gate verif-current s124-framing-commands-cleanup` → exit 0. The record is complete. The last `Unit suite` row (`bash tests/run.sh`) exited 0 on code equal to the recorded tree. With `Verification mode: record` I did not rerun the full suite.
- The project has no type check (`Typecheck: —`), no E2E and no Build. The record says the same.
- The record's "Not proven here" leaves the wording quality beyond the quoted phrases, and the bite checks, to the reviewer. The bite checks were done (below).
- QA: `QA stage: —`, so this story does not go to QA and none is required.
- `po-gate floor-guard s124-framing-commands-cleanup main` → exit 0, nothing was lowered. Two existing test edits in `tests/framing-second-landing.test.sh` change the clauses they check. Plan task 6 justifies both, and the story asks for them (rows 160, 161, 164).

## Triage rows held against the diff
| Row | Status on this tree |
| --- | --- |
| 112 `prd.md` "read the whole" | closed. `templates/prd.md:9` now agrees with `po-prd.md:33,56` |
| 113 fix path ends on `/po-research` | closed. `po-stories.md:57` "Stories fixed. Next: /po-stories-review" |
| 114 Set aside does not rerun Before writing | closed. `po-stories.md:56` |
| 115 blocked review matches two Outcome bullets | closed. `po-stories-review.md:57-59`, exclusive and placed first |
| 119 forge read before `Target branch` | closed. `po-setup.md:27` and `:40` |
| 141 refused local ff-only not handled | closed. `po-setup.md:95` |
| 143 "never pushes it" not held by a test | closed. `test_setup_landing_holds` |
| 160 "means not merged" not held by a test | closed. `test_framing_merge_is_proven_per_forge` |
| 161 order check only tested the fixed layout | closed. It now compares the realignment with `read-tree` |
| 164 capital after a colon | closed |
| 177 "(ADR-0086)" outside its sentence | closed in both files. The `no-claude-md` anchor sentence is byte-identical |
| 142 secret scan | not this story's (s127), untouched as required |

## Bite checks (each change undone; `git diff --exit-code` confirmed the file was restored every time)
1. Removed the set-aside bullet in `po-stories.md` → `framing-commands-cleanup.test.sh`: 1 of 3 failed (`stories_paths_agree`).
2. Removed the sentence "The command ends with "Stories fixed. Next: /po-stories-review"…" → 1 of 3 failed (`stories_paths_agree`).
3. Replaced the local refusal clause in `po-setup.md:95` with a plain "Then" → 1 of 3 failed (`setup_landing_holds`).
4. Removed "It never commits to `Target branch` directly and never pushes it." → 1 of 3 failed (`setup_landing_holds`).
5. Moved the root realignment bullet out of **Base** to after the commit block → `framing-second-landing.test.sh` plus `framing-realign-and-orchestrator-log.test.sh`: 2 of 5 failed (`root_realigns_after_a_merge`, `every_landing_realigns_the_root`).
6. Swapped the whole **Base** block with **The commit, built beside the checkout** → 1 of 3 failed (`root_realigns_after_a_merge`, "the realignment does not precede the commit build"). This confirms the rewritten order check now holds a real rule (row 161).

Within `Test budget` (25): three new functions and two edited ones.

## Findings
1. **minor**: `method/commands/po-stories.md:52`. The opening sentence now reads "those stories, plus the ones a removal breaks (the next bullets), and no other, as the review's outcome named them". The trailing "as the review's outcome named them" now seems to cover the broken stories too, but the outcome never names those. The rule is right in the bullets below it (`:56`, `:57`); only this summary sentence is ambiguous.
2. **minor**: `tests/framing-commands-cleanup.test.sh` `test_setup_landing_holds` holds only the Step 1 half of the forge-timing rule. If someone reverted `po-setup.md:40` to "from what step 1 read of the forge", the contradiction of row 119 would come back and no test would fail.
3. **minor**: `docs/plans/s124-framing-commands-cleanup.md:9` says "the ten `HOLDS` rows" but lists eleven (112-115, 119, 141, 143, 160, 161, 164, 177). The research makes the same miscount. This is evidence only and all eleven are closed.

No critical or major finding. Steps 2, 3, 5 and 6 found nothing else:
- Every reference opens to what it names: `## The forge's review rule` and the CODEOWNERS/protection reads of `Target branch` in `po-ship.md:35-36`, `po-prd.md:56`, the `templates/stories-review.md` status values, and the `tests/lib.sh` helpers.
- Every plan task is present, and no change was made that the plan did not ask for.
- The neighbours agree with the diff: `stories-review/SKILL.md:48` and `po-orchestrator.md:31` (blocked implies `Stories ready: no`), and `po-prd.md`.
- `overlap.test.sh` passes.

## Not verified
- No framing command was run end to end, so the new prose was never followed in a live repository. A person could run `/po-stories` on a throwaway repo, set one story aside so that a remaining story breaks, and check that the fix path asks about the broken story and ends with "Next: /po-stories-review".
- The refused `git merge --ff-only framing/<slug>` in `Merge mode: local` was never reproduced. To cover it, diverge a local `framing/<slug>` from `Target branch` in a throwaway repo, land a framing commit, and check the stop and the report.
- The `/po-setup` forge reading after question 1 was not exercised against a real forge with CODEOWNERS or branch protection.
- The full unit suite was not rerun. I relied on the `po-run` record (exit 0 on this code).
- The project has no type check, E2E or build command (`—`), so none was run.
- `method/templates/brief.md:8` still asks to read the whole brief. It is outside this story's `Owns` and now belongs to s127 (`installer_and_docs_agree`).

Max severity: minor
Ship allowed: yes

---

# Review: s124-framing-commands-cleanup

Review status: complete
Reviewed tree: 8eaee874387918897257295836d67b9cee276465
Fix loop: 1
Scope: `git diff main...story/s124-framing-commands-cleanup`. Merge base is 6830ec4. Three commits: 48a3d94 (story), 78fec04 (review), 9dc40d5 (fix run).
Lenses run: none. No path or content in the diff triggers Security, Migration, Dependencies or Performance.

## Scope check (Owns)
The diff changed these files:
- `method/commands/po-architect.md`, `po-setup.md`, `po-stories-review.md`, `po-stories.md`
- `method/templates/prd.md`
- `tests/framing-commands-cleanup.test.sh` (new)
- `tests/framing-second-landing.test.sh`
- the story's own `docs/research|plans|reviews|verif/s124-…` files, which are in scope by construction

Every code path is in the story's `Owns` (`docs/stories.md:1929`). The fix commit 9dc40d5 touches only `po-stories.md` and the new test file, plus the story's own evidence.

Other running stories:
- `git worktree list` shows only one other lane, s126. Its branch is an ancestor of `main` (`merge-base --is-ancestor` exit 0), so it is not running, and its `Owns` does not overlap this one anyway.
- s127 shares `method/commands/po-setup.md` (main's `docs/stories.md`). It has no worktree and depends on s124, so there is no conflict.

Main has moved since the merge base, but none of the files this story owns changed on `main` between 6830ec4 and 49958d3.

## Evidence reused
- `po-gate verif-current s124-framing-commands-cleanup` exited 0. The last `Unit suite` row exited 0 on code equal to this tree outside `docs/`. With `Verification mode: record`, I did not rerun the suite in the worktree.
- The project has no Typecheck, E2E or Build command (all `—`), so none was run.
- `QA stage: —`, so the story does not go to QA.
- `po-gate floor-guard s124-framing-commands-cleanup main` exited 0: nothing was lowered. Plan task 6 justifies the two edits to `tests/framing-second-landing.test.sh`.
- Extra probe: I cloned the repo as a throwaway copy in `/tmp/tmp.HWzKXvuClo/repo`, merged the story into the current `main` (49958d3), and ran `bash tests/run.sh` there. 553 passed, 0 failed. The story still agrees with s125, s127's framing and M10.

## Loop-0 findings, held against the fix
1. **Closed.** The ambiguous summary at `po-stories.md:52` now reads "and no other; the review's outcome names only the first group."
2. **Closed.** `test_setup_landing_holds` now also checks Step 2 for "from that reading of the forge, made once `Target branch` is known". The bite check below shows it holds.
3. **Closed.** The plan and research now say "eleven" rows.

All eleven triage rows (112-115, 119, 141, 143, 160, 161, 164, 177) stay closed on this tree. Row 142 (`po-setup.md:79`) is untouched, as the run interdict requires.

## Bite checks
Each change was undone, and `git diff --exit-code` confirmed the file was restored.
1. Reverted `po-setup.md:40` to "from what step 1 read of the forge." The `framing-commands-cleanup.test.sh` file then failed 1 of 3 tests (`setup_landing_holds`: "Step 2 lacks: …").
2. Removed "Only this bullet applies to it." and both "With a complete review" qualifiers from `po-stories-review.md`. The same file failed 1 of 3 tests (`stories_paths_agree`).

The loop-0 bites on the unchanged rules still apply: set-aside bullet, Next line, local refusal, never-pushes, realignment order.

The test count is within `Test budget` (25): three new functions and two edited ones.

## Findings
No new finding. Steps 2, 3, 5 and 6 found nothing else on the fix commit:
- The heading the new assertion uses (`po-setup.md:31`) exists exactly as quoted.
- "Stories fixed. Next: /po-stories-review" is the only fix-path ending. `po-stories-review.md` Outcome ("Run /po-stories <ids>, then /po-stories-review again") agrees with it.
- No other method file refers to the `/po-stories` finish lines.

The plan's line numbers (for example `:62` for Finish, now `:63`) are slightly stale. That is evidence text only, so it is not a finding.

## Not verified
- **The new prose was never followed live.** No framing command was run end to end. To cover it, run `/po-stories` on a throwaway repo, set aside one story so that a remaining story breaks, and check that the fix path asks about it and ends with "Stories fixed. Next: /po-stories-review".
- **The local ff-only refusal was never reproduced.** This is the refused `git merge --ff-only framing/<slug>` under `Merge mode: local`. To cover it, make a local `framing/<slug>` diverge from `Target branch` in a throwaway repo, land a framing commit, and check that it stops, the branch is kept, and the report names it.
- **The forge reading was not tested against a real forge.** `/po-setup` now reads the forge after question 1. A person should run setup against a repository that has `CODEOWNERS` or branch protection on a non-default target branch.
- **The suite was not rerun in the worktree.** I relied on the `po-run` record. It was run once, on main plus this branch, in the throwaway clone.
- **No type check, E2E or build.** The project has none of these commands.
- **One gap is left to s127.** `method/templates/brief.md:8` still asks for the whole brief to be read. It is outside this story's `Owns` and belongs to s127.

Max severity: none
Ship allowed: yes
