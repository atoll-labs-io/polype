# Review: s64-qa-routing

Reviewed tree: a489cc68c5b6884614b89edeeced0a06615699dc
Fix loop: 0
Review status: complete
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s64-qa-routing (branch `story/s64-qa-routing`, one commit, 46a516f)
Scope: `git diff main...story/s64-qa-routing`
Lenses run: none. No path or content in the diff matches the Security, Migration, Dependencies or Performance triggers. The diff is prose command files and one bash test.

## Summary
The story does what it set out to do. Six commands now share one definition of a review blocked on QA: `Review status: blocked` and a `Next action:` naming `/po-qa`. They also share a second case, "blocked on QA evidence": `Review status: blocked` and a `Next action:` naming the `<id>: QA evidence` commit. All six send each case to the same place. In the `/po-drive` resume table, the dead row that read "lists the report" is replaced by a row that reacts to the gate's `is current but` refusal. That row sits below the human row and above the QA-stage row, and the false sentence saying "passes it" is corrected. `/po-status` now sends a `blocked` QA report to a human, as `/po-drive` does. I found no critical or major defect. There are two minor findings.

## Scope check (Owns)
Changed paths compared with the `Owns` line of `docs/stories.md:990`:
- `method/commands/po-{review,orchestrator,drive,flow,execute,status}.md` and `tests/qa-fleet.test.sh`: all inside `Owns`.
- `docs/research/`, `docs/plans/` and `docs/verif/s64-qa-routing.md`: the story's own evidence, in scope by construction.
- `docs/decisions/ADR-0041-…md`: added (status `A`) and named by the plan, so it is in scope by construction.
- No overlap with the other running lane. `story/s62-bounds-scan` touches only ADR-0039 among these areas. ADR-0040 is left unused on purpose (`docs/plans/s63-review-texts.md:80`), so the jump to 0041 is not a collision.

## Step 1: reused evidence
- `po-gate verif-current s64-qa-routing` exited 0 (`Verification mode: record`). The record is complete, with `Tree: b14c799…`. Its runs are `bash tests/run.sh` (exit 0) and `bin/po-lint` (exit 0), on trees whose code outside `docs/` matches. I relied on this record and did not rerun the full suite.
- Type check: the project has none (`Typecheck: —`).
- The record's "Not proven here" section says the gate's behaviour is unchanged, and that whether an agent actually follows the texts is left to review. Both points are accepted.
- QA: no screen, so there is no QA to require.
- No routing or manifest change, so the build is left to ship (`Build: —`; the project has none).

## Step 2: references
- `po-gate.sh:144` holds the refusal `the QA report of $1 is current but docs/qa/$1/ is not committed`. The gate checks freshness before the commit check (`:139-144`), so `is current but` only appears for a report that is current and uncommitted.
- `review-antihallu/SKILL.md:28` sets the uncommitted case's `Next action:` to the evidence commit and says it does not name `/po-qa`. P2 matches that.
- ADR-0034 and ADR-0037 exist. ADR-0041 is coherent with both.
- `po-orchestrator`, `po-flow` and `po-status` have Bash. `po-execute` and `po-review` stay without Bash, so they stop and name the commit instead of making it, as ADR-0041 says. No frontmatter changed.

## Step 3: diff against the plan
Tasks 1–8 are all present and match the plan's fixed phrases P1, P2, M1, M2 and G word for word. I checked the run interdicts:
- Empty diff everywhere else.
- In the drive table, only the inserted row, the removed row and the rewritten row differ.
- In `tests/qa-fleet.test.sh`, only the assertions at `:74` and `:81` changed, and no test was removed.
- No ADR number above 0041.

No unrequested change.

## Step 4: tests
- **Floor:** `po-gate floor-guard s64-qa-routing main` exited 0. Nothing was lowered.
- **Budget:** 4 new tests plus 2 adjusted assertions, within the budget of 25.
- **Bite:** I ran 4 mutations. After each one I ran only the relevant test files, then restored the file and confirmed it with `git diff --exit-code`. All four were restored and the worktree is clean.

| # | Mutation | Tests run | Tests that failed |
|---|---|---|---|
| 1 | Removed `Review status: blocked` from the P1 clause in `po-flow.md` step 3 | qa-fleet | 1 (`flow_and_execute_send_qa_blocks_to_qa`) |
| 2 | Swapped the drive's new evidence-commit row with the QA-stage row | qa-fleet + drive | 1 (`drive_resumes_on_an_uncommitted_report`) |
| 3 | Removed the status clause from P1 in `po-execute.md` precondition 6 | qa-fleet | 1 (`flow_and_execute_send_qa_blocks_to_qa`) |
| 4 | Removed "blocked report → a human decides" from `po-status.md` Next | qa-fleet | 1 (`status_agrees_with_the_fleet_on_a_blocked_report`) |

## Step 5: values
- The fixed phrases match `po-gate.sh` and `review-antihallu`.
- The two-evidence-commit bound is carried unchanged from ADR-0034 and extended to cover both returns.

## Step 6: neighbours
- `po-qa.md` (the evidence commit itself), `po-help.md` and `README.md` hold no routing rule that this change contradicts.
- `review-antihallu` already produces exactly the P1 and P2 shapes these commands now recognise.

## Findings
1. **minor**: the negative scan in `test_qa_blocked_needs_a_blocked_status` (`tests/qa-fleet.test.sh`) does not catch a missing status clause in most of the files it scans.
   - It reads one line at a time and is satisfied when `` `Review status: blocked` `` appears anywhere on that line.
   - In `po-flow.md:78`, `po-execute.md:26`, `po-review.md:26` and `po-drive.md:125`, the P2 clause sits on the same line as P1 and carries the status. Removing the status from P1 there still passes the scan; mutation 1 showed this.
   - Those clauses are still protected by the exact-phrase assertions, so coverage holds. The scan only really bites on lines where P1 stands alone (`po-review.md:41`, orchestrator Stage 7, drive row 56). Its comment and the plan claim more than it does.
2. **minor**: P1 is checked before P2 in `po-review.md` Outcome, `po-execute.md` and `po-flow.md`.
   - The gate's own refusal for the uncommitted case ends with `(/po-qa $1)` (`po-gate.sh:144`).
   - A reviewer that pasted the whole gate message into `Next action:` would match P1 first and trigger a needless new walk, not the evidence commit.
   - `review-antihallu/SKILL.md:28` forbids naming `/po-qa` there, and the result is a wasted walk, not lost data. Contained.

## Not verified
- **Agent behaviour:** whether a session following these command texts actually routes P1 and P2 as written. The tests check strings, not behaviour. To cover it, a person should run `/po-drive` or `/po-orchestrator` on a screen story with `QA stage: screens` and a deliberately uncommitted current `docs/qa/<id>/report.md`, then check that the lane makes the evidence commit without a new walk, and that a review blocked on P2 goes back to review at the same `Fix loop:`.
- **Full suite and lint:** I did not rerun them. I relied on the current record (exit 0 on matching code); only `qa-fleet.test.sh` and `drive.test.sh` were run during the mutations.
- **Installed copies:** the copies in `.claude/` and `.polype/` are not refreshed by this story, by design. Once it ships, someone needs to refresh them so the pipeline running on this repo picks up the change.

Max severity: minor
Ship allowed: yes
