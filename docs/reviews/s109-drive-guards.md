# Review: s109-drive-guards

The diff was `git diff main...story/s109-drive-guards`, read in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 6a61a4379342bf67c2055d1c60a025ad3dffa5fa

## When blocked
Not applicable: the review finished. I took the tree again just before answering and it had not changed.

## Ownership
I listed the diff with `git diff --name-status main...story/s109-drive-guards`: `docs/plans|research|verif/s109-drive-guards.md` (A), `method/commands/po-drive.md` (M), `method/commands/po-orchestrator.md` (M), `tests/drive-guards.test.sh` (A).
- [x] Every path is inside `Owns` (`method/commands/po-drive.md`, `method/commands/po-orchestrator.md`, `tests/drive-guards.test.sh`). The three docs files are this story's own pipeline evidence, so they are in scope by construction.
- [x] No path is inside another running story's `Owns`. The only other worktree is s108-ship-resumes-cleanly. It is not merged (`merge-base --is-ancestor` exits 1), and its Owns are `method/commands/po-ship.md` plus three tests, so it does not overlap. s112 also owns `po-drive.md`, but it has no worktree and depends on s109.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s109-drive-guards` exits 0, so I reused the record and did not rerun the suite. The record has `Unit suite` `bash tests/run.sh` with exit 0. The project has no type check (`Typecheck: —`), no E2E and no build. I read the record's "Not proven here": it says the tests check where the guards are written, not how agents behave.
- [x] `po-gate qa-current` is not required: `Surface: —` and `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–6 are all present.
  - Task 1: start-point check between the start point and `git worktree add`, the drop paragraph, and the `## Report` entry.
  - Task 2: the automatic sentence placed after the table.
  - Task 3: drive log list extended.
  - Task 4: orchestrator `## The decisions log` placed after Stage 8, with `Finish with …` still the last line.
  - Task 5: three tests.
  - Task 6: covered by the record's full-suite run.
- [x] Nothing in the diff is outside the plan.
- [x] Run interdicts, checked one by one:
  - `po-research.md`, `po-setup.md`, `po-ship.md`, `po-flow.md`, `po-status.md`, `method/AGENTS.md`, `method/hooks/`, the existing tests, `.claude/` and `.polype/`: none is in the diff.
  - Row `:65` (`OPEN`) is unchanged, and so is the order of the `## Resuming` rows.
  - `## The ready set` and `status` are not touched.
  - The new orchestrator heading has no `— checkpoint`, so `pilot.test.sh` keeps counting two.
  - No ADR file, and no new setting on any `Reads settings:` line.

## References
- [x] Every reference the diff makes exists as the text says:
  - `po-research.md:31`, step 2, has the same `git show <start point>:docs/stories.md` heading check, so the drive's wording matches it.
  - `po-ship.md:75` does reuse an already open PR, which backs the claim in the automatic sentence.
  - `method/templates/decisions-log.md` exists.
  - `## Landing the framing` with slug `decisions-log` matches the drive's existing wording.
  - The orchestrator's Stage 4 (Plan) and Stage 7 (Review) are the stages that approve plans and start fix runs.
  - The drive's new log kinds match the `AGENTS.md` list at line 79: an implementation detail, and an answer given without asking.
- [x] The automatic sentence holds as stated. The closed row needs `CLOSED` and the waiting row needs an effective `human`, so under an effective `automatic` an `OPEN` PR falls through to the unconditional ship row.

## Rules
- [x] Method prose is in English, the test is bash using the `tests/lib.sh` helpers, and test names match the criteria. `overlap.test.sh` is covered by the full-suite run in the record.
- [x] No accepted ADR is contradicted. The new text is consistent with ADR-0077 and ADR-0080.

## Tests
- [x] Floor: `po-gate floor-guard s109-drive-guards main` exits 0, so nothing was lowered.
- [x] The assertions read only the section that owns each rule, through `section_of` and `subsection_of`. None of the six empty test shapes appears: the tests check text, not fixtures or mocks.
- [x] 3 tests against a `Test budget` of 25.
- [x] Bite: I ran only `drive-guards.test.sh` each time.
  - Removing the effective-`human` clause from the `OPEN` row: 1 failure (`pr_wait_needs_effective_human`). Undone; `git diff --exit-code` clean.
  - Removing the start-point check from `### Preparing the lanes`: 1 failure (`lane_checks_its_start_point`). Undone; clean.
  - Putting `git worktree add -b story/<id>` before the check: 1 failure, "start-point check comes after git worktree add". Undone; clean.
  - Removing `never before its ship` from the orchestrator log: 1 failure (`lone_decisions_are_all_logged`). Undone; clean.
  - After all four, `git diff --exit-code` on the whole tree was clean.
- [x] The story makes no existing test useless.

## Neighbours
- [x] I read the rest of the `## Resuming` table and the resume rules, `## The ready set`, the `## Report` and `status` paths, `po-ship.md` step 3 (open PR, then human stop, then proof of merge), and the `po-research.md` step-2 stop. The drive drops the lane rather than stopping the wave, which is consistent with how it handles an orphan and with "the other lanes carry on". Nothing is broken.

## Lenses
Lenses run: none. All changed paths are markdown method files and one bash test, with no security, migration, dependency or server-side trigger.

## Findings
- minor — `method/commands/po-orchestrator.md:89`: "once the story has shipped or the run stopped" does not say what happens when the run ends on "Pull request ready: <url>." under an effective `human` with `Merge mode: pr`. That run has neither shipped nor stopped. The orchestrator also lacks the caveat the drive carries (`po-drive.md`, `## The decisions log`): under `Merge mode: local` with a `human` "Not now", the log stays staged in the root and blocks the next local ship. Worth one sentence in a later cycle.
- minor — `method/commands/po-orchestrator.md:84`: the orchestrator logs only plan approvals and fix runs, as the criterion asks. It does not log its other lone decisions: the track it chooses at Stage 1, an implementation detail, an answer given without asking. Those are kinds `AGENTS.md:79` lists and the drive now logs. This is within the story's text but narrower than the rule.

## Not verified
- How an agent actually behaves when it follows the new prose. Nobody ran `/po-drive` against a story whose framing is not yet merged, against an open PR under `automatic`, or through a full orchestrator run that writes and lands the log. These tests check where the text is written, not what an agent does with it. A person should run `/po-drive` on a throwaway repository with one story whose heading is only on an unmerged framing branch, and confirm that the lane is dropped, the other lanes carry on, and the report names the story.
- `/po-drive status` and `po-session` still show a story waiting for its framing merge as ready. The plan deliberately leaves `status` unchanged, so this is outside the story, but a person reading `status` will not see that reason.
- The full suite, including `overlap.test.sh`: I took its result from the `po-run` row in the record and did not rerun it.
- The installed copies under `.claude/` and `.polype/` are not refreshed by this story, as the record states. Running the pipeline on this repository keeps the old wording until someone reinstalls.

Max severity: minor
Ship allowed: yes
