# Review — s125-ship-and-fleet-cleanup

The diff reviewed is `git diff main...story/s125-ship-and-fleet-cleanup`, in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: c88317b9dfc88060955ee8453f11a3d51d7410f4

## When blocked
Not applicable. I took the tree hash again just before answering and it had not changed. `git status --porcelain` printed nothing.

## Ownership
I listed the changed paths with `git diff --name-only main...story/s125-ship-and-fleet-cleanup` and held each one against the story's `Owns` line (`docs/stories.md`, under `### s125-ship-and-fleet-cleanup`).
- [x] Every path is inside `Owns`:
  - the four method files: `method/AGENTS.md`, `method/commands/po-drive.md`, `method/commands/po-ship.md`, `method/commands/po-status.md`;
  - the four modified tests: `tests/defect-and-routing-paths.test.sh`, `tests/escalation-contract.test.sh`, `tests/ship-through-pr.test.sh`, `tests/short-subject-shipped.test.sh`;
  - the new `tests/ship-and-fleet-cleanup.test.sh`;
  - the story's own research, plan and verification record, which are in scope by construction.
- [x] Nothing is outside `Owns`.
- [x] No path is inside another running story's `Owns`. The only other lane is s124 (worktree `.worktrees/s124-framing-commands-cleanup`, not yet merged into main). Its `Owns` covers po-stories, po-stories-review, templates/prd, po-setup, po-architect and its own tests, which do not overlap with this story.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s125-ship-and-fleet-cleanup` exits 0. `Verification mode: record`: I reused the record's `bash tests/run.sh` row (exit 0) and did not rerun the full suite. The project has no type check, end-to-end or build command (all `—`). The record's "Not proven here" leaves it to this review to judge whether the prose reads correctly.
- [x] `po-gate qa-current` was not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 10 are all in the diff and match the plan's wording. Task 6, the /po-status root-cause case, is the lead's decision and in scope. Nothing appears that the plan did not ask for.
- [x] Run interdicts, checked one by one:
  - No file outside `Owns` is touched. That includes po-session.sh, po-orchestrator, the s126 files, the docs on parity with Killer SaaS and the ADRs.
  - In `AGENTS.md`, only the "Ships stay serial" sentence changed; line 57 is untouched.
  - In po-drive, only lines 52, 103 and 144 changed. Line 148 and the order of the resuming rows are unchanged.
  - In po-status, only lines 25, 27, 36 and 39 changed. Line 31 (the shipped sentence it shares with po-drive) is verbatim.
  - In po-ship, only the line 74 bullet changed, and Step 2 gained no `git push` line.
  - The installed copies were not edited.
  - In ship-through-pr, the old assertions were moved unchanged.
- [x] Every triage HOLDS row the plan names is closed by the diff: :90 and :91 (the po-drive parts), :118, :120, :126, :129, :154, :155, :156 and :170. The po-plan, planner, po-orchestrator and po-research parts of :90 and :91 belong to s126.

## References
- [x] Every reference I opened is real:
  - po-orchestrator has `## Stage 0 — Can this start?`, which holds "ends this run at once and reports that stop alone".
  - po-drive's `## A wave` holds "Meanwhile the other lanes carry on." exactly once (the mutant asserts this), and "it is not asked through AskUserQuestion, which would hold every other lane".
  - po-session.sh holds `SHORT_SHIPPED["${id%:}"]=1`, and its `grep -qx 'Root cause: not found'` matches the reading po-status now writes.
  - po-ship's `## Step 3 — Cleanup, only after proof` exists.
  - The "Not now" answer is under `Merge mode: local`.
  - The sentence "Below, `Ship confirmation` is always the effective value…" is in Step 2.
- [x] Values: `git log -1 --format=%s` compares the subject line, which is right for a one-line `<id>: <story title>` message. The test of the session output, `Ready stories: s02-y (Owns not checked: /po-drive decides)`, compares whole lines (`grep -qxF`), and the full suite passed with it on this code.

## Rules
- [x] The `AGENTS.md` conventions hold: method text is in English; the tests are bash and use `tests/lib.sh` helpers; each test function carries its criterion's name; the existing tests that changed are explained in the plan's Test strategy.
- [x] No accepted ADR is contradicted. The whole-line `grep -x` wording matches ADR-0070. The ship-order sentence keeps "in the order the reviews passed" and stays consistent with `AGENTS.md:57`. Under an effective `human` with `pr`, opening the pull request ends that ship (`po-drive.md:146`).

## Tests
- [x] Floor: `po-gate floor-guard s125-ship-and-fleet-cleanup main` exits 0, so nothing was lowered.
- [x] The assertions pin the three criteria, and none of the six hollow test shapes appear.
  - `fleet_tests_bite` first checks that each test passes on the real tree, then that the mutation actually applied, then that the test fails on the mutant.
  - The short-subject half now runs the hook on a throwaway repo instead of grepping its text.
- [x] Test count: 4 new functions and 3 changed, within `Test budget` 25.
- [x] Bite: I ran only the files that exercise each rule, and restored each file with `git checkout --`, confirmed by `git diff --exit-code`.
  - Removing the commit-message condition from po-ship's skip clause: 1 test fails (`ship_text_is_complete`, "the skip condition does not check the commit message"). Restored, clean.
  - Removing po-status's root-cause clause from "blocked stories": 1 test fails (`fleet_rules_agree`, "po-status blocked stories lacks: Root cause: not found"). Restored, clean.
  - Removing the shared ship-order sentence from `method/AGENTS.md`: 1 test fails (`fleet_rules_agree`, "AGENTS.md Law 1 lacks: …"). Restored, clean.
- [x] No test became useless because of the story. The old `read_shipped` text grep was replaced, not kept.

## Neighbours
- [x] Other statements of the same rules:
  - `po-plan.md:26` and `planner.md:39` still say "holding the line `Root cause: not found`". Those files are s126's (triage :90), so not a finding here.
  - `po-session.sh:208-215` already reads both markers the way po-status now describes them.
  - The installed root `AGENTS.md` and `.claude/commands/` still hold the old text until the lead refreshes them after ship, as the plan's "Done when" says.

## Lenses
Lenses run: none. No auth, route, upload, migration, lockfile or server-side path or content is in the diff.

## Findings
- minor — `method/commands/po-status.md:39`: the "Next" chain now writes two exits as if they were steps of the cycle ("research → a research holding `Root cause: not found` → "a human decides", never `/po-plan` → design …" and "plan → a plan waiting for a technical choice → "a human decides" with `/po-plan <id>` → approve plan"). The other exits in the chain use a "when X → Y" form, as the QA `blocked` exit does. Read straight through, the chain suggests that design follows a human decision about the research. The meaning is recoverable, but the wording is uneven.

## Not verified
- **What `git push --force-with-lease=story/<id>` does when `origin/story/<id>` does not exist yet.** The new po-ship text says "the push creates it". I tried to confirm this in a throwaway repo under /tmp, but po-bounds refused `git commit` there (unknown directory), and it refuses `git push` everywhere. I did not work around the refusal. From my reading of git, a lease with no remote-tracking ref expects the ref to be absent, so the push creates it. A person should confirm this once, with a first-time `/po-ship` on a fresh story branch, or by hand in a scratch repo.
- **How an agent actually reads the reworded prose** of /po-drive's ship order, /po-status's new blocked cases and the po-ship skip clause. The tests pin the phrases, not the behaviour of an agent following them. The first /po-drive wave with two ships passed in review, and the first /po-status run on a story whose research holds `Root cause: not found`, would show it.
- **The full suite and the overlap test with Killer SaaS on this tree** were taken from the verification record, not rerun here. The project has no type check, end-to-end or build command.
- **The installed copies** (root `AGENTS.md`, `.claude/commands/`) are not refreshed by this story. The lead does that after ship.

Max severity: minor
Ship allowed: yes

---

# Review — s125-ship-and-fleet-cleanup

I reviewed `git diff main...story/s125-ship-and-fleet-cleanup` in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 9fac51b35fe17cdbe63c8ebce2c193607e78aa16

## When blocked
Not applicable. I took the tree again just before answering and it had not changed (`9fac51b35fe17cdbe63c8ebce2c193607e78aa16`). `git status --porcelain` and `git diff --exit-code` printed nothing.

## Ownership
- [x] I held each path from `git diff --name-only main...story/s125-ship-and-fleet-cleanup` against the `Owns` line in `docs/stories.md`. Every path is covered:
  - `method/AGENTS.md` and `method/commands/po-drive.md`, `po-ship.md`, `po-status.md`;
  - `tests/defect-and-routing-paths.test.sh`, `tests/escalation-contract.test.sh`, `tests/ship-through-pr.test.sh`, `tests/short-subject-shipped.test.sh`;
  - the new `tests/ship-and-fleet-cleanup.test.sh`;
  - the story's own research, plan, verification record and review, which are in scope by construction.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`.
  - The only other worktree is s124, whose branch is still at the framing commit 6830ec4. Its `Owns` (po-stories, po-stories-review, templates/prd, po-setup, po-architect, its own tests) does not overlap with this story.
  - Since the branch base, `main` changed only s127's `Owns`/`Dépend de` lines in `docs/stories.md`. s127 now owns `po-setup.md` and `templates/brief.md`, which this story does not touch.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s125-ship-and-fleet-cleanup` exits 0 on the fix-run tree.
  - `Verification mode: record`, so I relied on the recorded `bash tests/run.sh` row (exit 0, tree 06180fd…, 2026-10-14T07:51:14Z) and did not rerun the full suite.
  - The project has no type check, end-to-end or build command (all `—`).
  - The record's "Not proven here" leaves it to the review to judge how the prose reads.
- [x] QA is not required: `QA stage: —`.

## Plan
- [x] Tasks 1 to 10 are all in the diff and match the plan's wording. The fix commit c5fb87f changes only po-status step 5 (and the record): the two exits for a missing root cause and for a technical choice now come after the chain, in a "when X → Y" form. This closes the loop-0 minor.
- [x] Run interdicts hold:
  - nothing outside `Owns` is touched;
  - `AGENTS.md:57` is verbatim;
  - in po-drive, only lines 52, 103 and 144 changed, and 148 is verbatim;
  - in po-status, line 31 (the shared sentence) is verbatim;
  - po-ship Step 2 gained no `git push` line;
  - the installed copies were not edited.
- [x] Triage rows :90 and :91 (the po-drive parts), :118, :120, :126, :129, :154, :155, :156 and :170 are each closed by the diff. The po-plan, planner, po-orchestrator and po-research parts belong to s126.

## References
- [x] Every reference I opened exists:
  - po-ship Step 2's "Below, `Ship confirmation` is always the effective value…", and its three effective-value bullets (pr/human, pr/automatic, local/human);
  - po-ship's `## Step 3 — Cleanup, only after proof`;
  - po-drive's `## A wave` step 1 and the resuming row;
  - po-orchestrator's `## Stage 0 — Can this start?`;
  - `SHORT_SHIPPED["${id%:}"]=1` in po-session.sh;
  - `mutant`/`run_against` copied from `tests/tech-choice-backstop.test.sh:12-22`, as the plan's Reuse says.
- [x] Values:
  - `git log -1 --format=%s` reads the subject, which is right for a one-line `<id>: <story title>` message.
  - `grep -qxF` matches the whole session line.

## Rules
- [x] Conventions hold: method text is in English; the tests are bash and use `tests/lib.sh` helpers; each test function carries its criterion's name; the changes to existing tests are explained in the plan's Test strategy.
- [x] No accepted ADR is contradicted:
  - the `grep -x` wording matches ADR-0070;
  - the ship-order sentence keeps "in the order the reviews passed" and agrees with `AGENTS.md:57` and `po-drive.md:148`;
  - "a ship that fails … leaves the other lanes running" (`po-drive.md:150`) agrees with "a failure … ends that ship, and the next one starts".

## Tests
- [x] Floor: `po-gate floor-guard s125-ship-and-fleet-cleanup main` exits 0.
- [x] None of the six hollow test shapes appear.
  - `fleet_tests_bite` checks each test on the real tree, then that the mutation applied, then that the test fails on the mutant.
  - The short-subject half runs the hook on a scratch repo.
- [x] Count: 4 new functions and 3 changed, within `Test budget` 25.
- [x] Bite. For each mutation I ran only the files that exercise the rule, then restored the file with `git checkout --` and confirmed it with `git diff --exit-code`:
  1. po-ship push refspec retargeted (`<sha>:refs/heads/<Target branch> story/<id>`), running `ship-through-pr` and `ship-and-fleet-cleanup`: 1 fails (`push_targets_only_the_story_ref`, "the story push no longer sends <sha>:refs/heads/story/<id>"). Restored, clean.
  2. ", the effective value" removed from the `automatic` bullet of Step 2: 1 fails (`ship_text_is_complete`, "a confirmation bullet lacks 'the effective value'"). Restored, clean.
  3. The fix run's override "when the research holds `Root cause: not found` → …" removed from po-status step 5: 1 fails (`fleet_rules_agree`, "po-status Next chain lacks: Root cause: not found"). Restored, clean.

## Neighbours
- [x] Other statements of the same rules:
  - `po-plan.md:26` and `planner.md:39` still say "holding the line `Root cause: not found`". They are s126's files, so not a finding here.
  - `po-help.md` says nothing about ship order.
  - `docs/decisions-log.md:15` agrees with the new reading.
  - The installed root `AGENTS.md` and `.claude/commands/` still hold the old text until the lead refreshes them after ship, as the plan says.

## Lenses
Lenses run: none. The diff has no auth, route, upload, migration, lockfile or server-side path or content.

## Findings
None. The loop-0 minor (the po-status "Next" chain wrote two exits as steps of the cycle) is resolved by c5fb87f, and I found nothing new.

## Not verified
- **A push to a remote where `origin/story/<id>` is stale.** The planner reproduced the case where no ref exists (research line 47: the push creates the branch, exit 0, git 2.56). I could not try any push myself: po-bounds refuses `git push` everywhere. Step 2 runs `git fetch origin` without `--prune`, so the stale case remains. If the remote branch was deleted outside this clone, for example by hand on the forge, the local `origin/story/<id>` survives. A plain `--force-with-lease=story/<id>` would then refuse ("stale info"), or the skip condition would read the stale head. This does not arise when the deletion came from Step 3's own `git push origin --delete`, which also drops the tracking ref. A person should run a first `/po-ship` on a branch deleted on the forge only, or replay the case in a scratch repo.
- **How an agent actually reads the reworded prose:** the ship order and the "Proving a ship" sentence in /po-drive, and /po-status's new blocked cases and Next-chain exits. The tests pin phrases, not agent behaviour. The first /po-drive wave that has two ships pass review, and a /po-status run on a research holding `Root cause: not found`, would show it.
- **The full suite and the overlap test with Killer SaaS on this tree** come from the verification record, not a rerun. The project has no type check, end-to-end or build command.
- **The installed copies** are not refreshed by this story; the lead does it after ship.

Max severity: none
Ship allowed: yes
