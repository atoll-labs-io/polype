# Review — s68-docs-catch-up

[Story](../stories.md) · [Plan](../plans/s68-docs-catch-up.md) · [Verification](../verif/s68-docs-catch-up.md)

Diff reviewed: `git diff main...story/s68-docs-catch-up`, by a reviewer that did not write it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: d5f41e36a83231f8d604d98b0b3dd4cac4480fea

## Ownership
I listed the changed files with `git diff --name-only main...story/s68-docs-catch-up` and compared each one with the story's `Owns` line.
- [x] Every path is inside `Owns` (`README.md`, `docs/parite-killer-saas.md`, `tests/distribution-wiring.test.sh`). `docs/plans/s68-docs-catch-up.md` and `docs/verif/s68-docs-catch-up.md` are the story's own evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. The only other worktree, s69-owns-overlap-globs, is at the same commit as main, and its `Owns` does not include these files.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s68-docs-catch-up` exits 0. I reused the record: Unit suite `bash tests/run.sh` exit 0. The project has no type check, E2E or build command (`—`), so none was run.
- [x] `po-gate qa-current`: not required, the story has no screen.

## Plan
- [x] All 4 tasks are present and match the diff. Nothing was changed outside the plan.
- [x] Run interdicts, checked one by one:
  - The diff lists only the 3 owned files plus the plan and the record.
  - Nothing changed under `method/`, `.claude/`, `.polype/`, `bin/` or in any other test file.
  - In the matrix, only the H04 line changes (one line out, one in), and its Killer SaaS column is byte-identical.
  - In the README, only the pre-commit sentence changes; the cycle table is untouched.
  - No ADR was added.
  - No other stale line was touched.

## References
- [x] I opened `method/hooks/po-gate.sh`:
  - Lines 11-13 hold "on every branch".
  - `pre_commit` runs `secret_scan` before it checks the branch, so the secret refusal applies on every branch.
  - `secret_scan` covers `.env`/`.env.*` files except `.env.example`, plus private-key, AWS, GitHub, Stripe and Anthropic patterns.
  - The README sentence matches all of this.
- [x] The H04 claims match the method:
  - `method/commands/po-execute.md:33-34`: the implementer gets `Model light` up to `Light up to`, `Model strong` above.
  - `method/commands/po-drive.md:101`: the deciding roles get `Model strong`.
  - `po-review.md:29`, `po-qa.md:31` and `po-stories-review.md:29` pass `Model strong`.
  - `method/templates/agents-local.md:34-36,65-67` hold the three settings.
  - ADR-0032 and ADR-0036 exist under `docs/decisions/`.
  - The three paths cited in the status cell exist.
- [x] `polype_of` reads `$5` when the line is split on `|`, which is the Polype column; the field before the first `|` is empty. Neither changed cell contains a `|`, so `status_of` still reads the right cell.

## Rules
- [x] `AGENTS.md` conventions are respected:
  - Changing an existing test is allowed because this story changes the clause it checked; the commit message says so.
  - Only this story's own matrix line was updated.
- [x] No accepted ADR is contradicted. The cell states the limit recorded in ADR-0036.

## Tests
- [x] Floor: `po-gate floor-guard s68-docs-catch-up main` exits 0, so nothing was lowered.
- [x] The assertions quote exact phrases tied to both acceptance criteria and add negative checks: the old narrow sentence, `Identique` and `partiel`. None of the six kinds of test that prove nothing appears.
- [x] Within `Test budget`: 2 tests added and 3 stale assertions removed, against a budget of 25.
- [x] Bite (only `distribution-wiring.test.sh` was rerun after each change):
  - **Mutation 1:** I put the old narrow pre-commit sentence back in `README.md`. 1 test failed (`readme_describes_the_pre_commit`). Undone; `git diff --exit-code README.md` is clean.
  - **Mutation 2:** I set the H04 status from `fait` to `partiel`. 1 test failed (`parity_h04_matches_the_model_rule`). Undone; `git diff --exit-code docs/parite-killer-saas.md` is clean.
  - Baseline before the mutations: 6 passed, 0 failed.
- [x] The three H04 assertions this story makes false were removed, and the reason is in the plan.

## Neighbours
- [x] `grep H04 tests/` finds only `distribution-wiring.test.sh`.
- [x] `qa-fleet.test.sh:99-105` reads README lines this story does not touch.
- [x] `test_readme_describes_the_project_and_its_install` stays green; the record's full suite run exited 0.

## Lenses
Lenses run: none. The diff has no auth, routes, migrations, lockfiles or server code.
- [x] Nothing to grade.

## Findings
- minor — `tests/distribution-wiring.test.sh` (`test_parity_h04_matches_the_model_rule`): the status check requires only `method/commands/po-execute.md`. The cell also cites `po-drive.md` and `agents-local.md`, and the test would not notice if those two were dropped. This does not affect the criterion.
- minor — `docs/parite-killer-saas.md` H04: the plan's "pivot" chose `fait` while ADR-0036 leaves `Model strong` unenforced for planner and designer outside `/po-drive`. The cell states this limit openly, so I accept the status. Still, the first clause ("les rôles qui décident … tournent sur `Model strong`") reads as unconditional until the reader reaches the closing qualification.

## Not verified
- I did not run the full suite myself. I relied on the verification record (exit 0, on code that matches HEAD outside `docs/`), as `Verification mode: record` allows.
- I did not run the pre-commit hook against a staged secret on `main` to confirm the README's runtime claim. I confirmed it only by reading `pre_commit`. To cover it, a person can stage a fake `.env` on a scratch branch that is not a story branch and check that the commit is refused.
- I did not separately review whether the README's French reads well for a newcomer; that is editorial judgement.

Max severity: minor
Ship allowed: yes
