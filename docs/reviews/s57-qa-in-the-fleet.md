# Review: s57-qa-in-the-fleet

[Story](../stories.md) · [Plan](../plans/s57-qa-in-the-fleet.md) · [Verification](../verif/s57-qa-in-the-fleet.md)

Diff reviewed: `git diff main...story/s57-qa-in-the-fleet`, one commit (9c1609f), read by a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 63bd52bfa172bab04a19b919486b8a5e5cf5b358

## When blocked
- Not blocked.

## Ownership
I listed the diff with `git diff --name-only main...story/s57-qa-in-the-fleet` (13 paths) and held each path against the `Owns` line in `docs/stories.md:870`.
- [x] All method, README and test paths are inside `Owns`: `README.md`, `method/commands/po-{drive,help,orchestrator,review,status}.md`, `tests/{drive,fleet-design,qa-fleet}.test.sh`.
- [x] Pipeline evidence is in scope by construction: `docs/research/`, `docs/plans/` and `docs/verif/` for s57.
- [x] One path is outside `Owns`: `docs/decisions/ADR-0034-la-flotte-committe-la-preuve-qa-et-le-retour-en-qa-ne-coute-aucune-boucle.md`. A written rule requires it (AGENTS.md Law 6: "Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`"), so this is a gap in `Owns`, graded minor. The plan announces it.
- [x] No collision with another running story. The only other unmerged worktree is `story/s55-reviewer-evals`, which owns `evals/`, `bin/po-eval` and `tests/evals.test.sh`, so nothing is shared. s58 also owns `tests/fleet-design.test.sh`, but it has no worktree or branch, so it is not running.

## Evidence reused
- [x] `po-gate verif-current s57-qa-in-the-fleet` passes (exit 0). Both the installed and the `method/` copies of the hook agree. I reused the record (`Verification mode: record`): `bash tests/run.sh` exit 0, 288 passed; `bin/po-lint` exit 0. The project has no type check command (`Typecheck: —`), so none was run. I read the record's "Not proven here" section.
- [x] `po-gate qa-current`: not required. The story has no screen, and this project sets no `QA stage` in AGENTS.local.md.

## Plan
- [x] Tasks 1 to 7 are all present: po-review loop and outcome, orchestrator Stage 6 and the renumbering, the drive wave and verdict, the four drive resume rows plus two paragraphs, po-status, help and README, and the run. The wording matches the plan. Nothing outside the plan.
- [x] Each run interdict was checked:
  - No changes to any of these paths: `method/hooks/po-gate.sh`, `po-qa.md`, `method/agents/qa.md`, `method/agents/reviewer.md`, `method/skills/review-antihallu/`, `method/templates/`, `po-flow.md`, `po-execute.md`, `method/AGENTS.md`, `AGENTS.md`, `AGENTS.local.md`, `.claude/`, `.polype/`, `tests/review.test.sh`, `docs/stories.md`.
  - The po-drive frontmatter is unchanged (no Write or Edit added).
  - The existing resume rows keep their text.
  - The wave section holds exactly five `subagent_type:` entries.
  - The orchestrator keeps its two `— checkpoint` headings, and its Stage 4 and Stage 5 headings are unchanged.
  - The `/po-drive` help line is unchanged.
  - po-review gained no Bash.
  - No test was removed. The only changed assertions are the two wave-order lines.

## References
- [x] Every reference was opened and confirmed:
  - The `qa_current` gate (`method/hooks/po-gate.sh:66-78`). Its file read is the working tree and its tree comparison excludes `docs`, so the new paragraph's claim "a current report left uncommitted passes it" is accurate.
  - The commit sequence in `method/commands/po-qa.md`.
  - The `Tree:` step in `method/agents/qa.md:40`.
  - `QA stage` in `method/templates/agents-local.md:21,49`.
  - `review-antihallu/SKILL.md:27`, which writes `/po-qa` as `Next action:`.
  - ADR-0026 and ADR-0029.
  - `settings_read_by` in `tests/lib.sh:37`.
- [x] Values: the bound of "two QA evidence commits" is a choice recorded in ADR-0034. Nothing else depends on an unconfirmed value.

## Rules
- [x] AGENTS.local.md conventions are respected: the method is in English, the help in French, every setting named on a `Reads settings` line exists in the template, and the tests are bash using `tests/lib.sh`.
- [x] No accepted ADR is contradicted. ADR-0034 extends ADR-0029: the driver makes the same commit `/po-qa` describes, and `po-bounds` and the `qa` agent are untouched.

## Tests
- [x] Floor: `po-gate floor-guard s57-qa-in-the-fleet main` exits 0, so nothing was lowered.
- [x] Assertions pin down the six criteria, including order checks by line number. None of the six empty test shapes applies to string assertions on prose contracts.
- [x] Six new tests and two changed assertions, within the budget of 25.
- [x] Bite 1: I moved the resume row "a blocked review whose `Next action:` names `/po-qa`" below the fix-run row in `po-drive.md`, then ran `qa-fleet`, `drive` and `resume`. 1 test failed (`drive_resumes_on_qa_current`: "a review blocked on QA must not fall into the fix-run row"). Undone; `git diff --exit-code` is clean.
- [x] Bite 2: I removed the same-`Fix loop:` clause from `po-review.md`, then ran `qa-fleet` and `review`. 1 test failed (`qa_blocked_review_goes_back_to_qa`). Undone; `git diff --exit-code` is clean.
- [x] No test is made useless by this story.

## Neighbours
- [x] I read the other places that route a blocked review:
  - `po-flow.md` and `po-execute.md` still send a review blocked on QA to a fix run when run by hand. This is not in `Owns`, and ADR-0034 (Neutral) and the research (:51, :57) both trace it.
  - In the orchestrator, screen stories under `QA stage: screens` now avoid `/po-flow`.
  - In the drive, QA runs whatever track the planner chose.
  - Only the orchestrator file itself refers to its stage numbers, and its own text was updated.

## Lenses
Lenses run: none. The diff has only method prose and bash tests: no auth, routes, migrations, lockfiles or server-side code.
- [x] Nothing to grade.

## Findings
- major — `method/commands/po-review.md:25,38`, `method/commands/po-orchestrator.md:68`, `method/commands/po-drive.md` (resume row "a blocked review whose `Next action:` names `/po-qa`", and the verdict section). A review counts as "blocked on QA" when its `Next action:` names `/po-qa`. That test does not also require `Review status: blocked`, but `templates/review.md` puts a `Next action:` line in every review. So a complete review blocked on real findings can trip it, for example critical QA findings carried over by `review-antihallu` step 1 whose `Next action:` reasonably says "fix, then `/po-qa`, then `/po-review`".
  - What happens: the review is routed to a QA return at the same `Fix loop:`. The code is unchanged, so the walk repeats and the same review comes back. After two QA evidence commits the lane goes to a human, and the fix run never happens.
  - Why the plan's analysis does not hold: its pivot assumes the second reviewer will not name `/po-qa` again, but nothing guarantees that.
  - Impact: contained (it ends at a human, and no `Max attempts` unit is lost), but the lane is misrouted.
  - Suggested fix: require `Review status: blocked` together with `/po-qa` in `Next action:`.
- minor — `method/commands/po-status.md:39`. For a screen story whose last QA report is `blocked`, `qa-current` fails, so "Next" suggests `/po-qa <id>`. But `/po-drive`'s resume table (first QA row) and ADR-0034 send that case to a human, because "a walk that could not happen fails the same way when replayed". The two commands give different next steps for the same state.
- minor — `docs/decisions/ADR-0034-…md` is outside the story's `Owns`, but AGENTS.md Law 6 requires it. This is a gap in `Owns`, not a breach by the implementer.

## Not verified
- No real `/po-drive` or `/po-orchestrator` run took a screen story through the new QA stage, the evidence commit or a QA return. The resume-table order was checked on paper, using the plan's three worktree cases plus the stale-record and blocked-report cases. A person should drive one screen story under `QA stage: screens` in a scratch project:
  - once with a review blocked on QA;
  - once with an uncommitted current report, to confirm the evidence-commit row fires.
- The drive's QA dispatch does not apply `/po-qa`'s preconditions 5 and 6 (`Dev` at `—`, no screen) itself; it relies on the `qa` agent stopping without a report. I read this, but no run exercised it.
- I did not run the full suite again: I relied on the record, whose tree matches the code. I ran only the focused files for the two bites.
- `/po-flow` and `/po-execute` run by hand still misroute a review blocked on QA (traced in ADR-0034). A later story owning those files should close this.
- s58 (not started) also owns `tests/fleet-design.test.sh`. Whoever ships second should expect to rebase that file.

Max severity: major
Ship allowed: yes
