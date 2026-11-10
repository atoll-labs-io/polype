# Review — s149-planner-writes-the-oracle

[Story](../stories.md) · [Plan](../plans/s149-planner-writes-the-oracle.md) · [Verification](../verif/s149-planner-writes-the-oracle.md)

Diff reviewed: `git diff main...story/s149-planner-writes-the-oracle`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 8b41d37dafd9462eabc25ac46c331d97da9b4846

## Ownership
Diff listed with `git diff --name-only main...story/s149-planner-writes-the-oracle` (17 paths), each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. That covers all 12 `method/`, `AGENTS.local.md` and `tests/` paths. ADR-0098 is listed in `Owns`, and it is also added (status `A`) and named by the plan. The research, plan and verif files are the story's own evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. The other running worktrees are s156 and s157, on the QA report and bounds. This diff touches no `po-gate.sh` or `review-antihallu` path, which s150 holds.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s149-planner-writes-the-oracle` → exit 0, so I reused the record. `Verification mode: record`. The last unit suite run (`bash tests/run.sh`) exited 0. `Typecheck`, `E2E` and `Build` are `—`: the project has none of these commands. I read "Not proven here". It says the two earlier failing runs came from a defect on `main`, fixed before the rebase.
- [x] `po-gate qa-current`: not required. `QA stage: —`, `Surface: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–9 are all present: the `## Acceptance tests` section in both plan templates, the convention in `AGENTS.local.md`, the planner's Limits bullet, state check and contracts, the po-plan and po-flow bullets, the Law 4 clause, `## Oracle changes` in the record template, the implementer's `:24`, `:41` and `:46` and its Limits bullet, the po-execute precondition 9 and the oracle sentence in both commands, the doctrine, ADR-0098 and the test file. Nothing outside the plan.
- [x] I checked each run interdict:
  - In `tests/`, only the new file was added, and there is no `.oracle.test.sh`.
  - `.claude/`, `.polype/` and the root `AGENTS.md` are untouched.
  - `method/hooks/` and `review-antihallu` are untouched.
  - `templates/stories.md` and `docs/parite-killer-saas.md` are untouched.
  - No other ADR changed.
  - The frozen sentences of planner.md:55, Law 4, implementer.md:24, the design sentence and "Disabling guards on purpose…" are all intact.
  - The po-execute frontmatter is unchanged.
  - No `Reads settings:` line or setting changed.
  - `## Runs` is still the last section of the record template.

## References
- [x] `cksum < <file>` matches the form used in `bin/polype` (plan, Reuse). ADR-0012 and ADR-0052 exist under `docs/decisions/`. `po-gate.sh` reads the record by section (`## Checks` and `## Runs`, po-gate.sh:151), so the new `## Oracle changes` table cannot be mistaken for a check row. `po-run.sh:57` still finds `## Runs`.
- [x] No value that only looks right. plan-flow.md is 65 lines, under the 150 limit.

## Rules
- [x] `AGENTS.md` conventions respected: method text in English, the ADR in French, no installed copy edited.
- [x] No accepted ADR contradicted. ADR-0098 sets `supersedes: []` and says it complements ADR-0012.

## Tests
- [x] Floor: `po-gate floor-guard s149-planner-writes-the-oracle main` → 0, nothing lowered.
- [x] Each assertion quotes a phrase from inside its own section (`section_of`/`holds`). None of the six empty test shapes.
- [x] 7 tests, within `Test budget: 25`.
- [x] Bite, three mutations, each undone and confirmed clean with `git diff --exit-code`:
  - Removed the Law 4 oracle clause in `method/AGENTS.md` → 1 failing test (`oracle_files_are_expected_work`).
  - Deleted the "**The oracle is the one exception.**" bullet in `method/agents/planner.md` → 2 failing tests (`oracle_lives_in_its_own_files`, `planner_writes_oracle_files`).
  - Deleted the oracle bullet from the implementer's Limits → 1 failing test (`implementer_keeps_the_oracle`).
- [x] No test made useless by the story.

## Neighbours
- [x] I read the other places that list expected uncommitted work or check the worktree state:
  - `designer.md:20` runs before the plan, so no oracle exists yet.
  - `qa.md:29` and `:49` run after the implementer's commit.
  - `po-research.md:53`, `po-design.md:31`, the orphan rules of po-drive and po-session, and `po-ship.md:99` need no change.
- [x] The planner's frozen Limits wording (`tests/drive.test.sh:220-226`, `tests/planner.test.sh`) still holds. The full suite is green per the record.

## Lenses
Lenses run: none. No path or content in the diff matches a lens trigger: this is method text and a bash test, with no auth, migration, dependency or server code.

## Findings
- minor — method/commands/po-plan.md:17 — The opening line still says "source files are out of reach for this command", and po-flow.md:19 says "never a source file". Both commands are now told to write test files (po-plan.md:41, po-flow.md:65).
  The planner got an explicit "**The oracle is the one exception.**" framing, the very risk the plan's pivot named, but neither command did. A reader of either command may take an oracle test file as a source file and skip it.
  `tests/plan.test.sh:28` freezes that sentence and sits outside `Owns`, so the fix is to add an exception clause after it, not to reword it.
- minor — method/agents/planner.md:22 — The state check accepts the oracle files only "once that plan is on disk", yet the Limits bullet (planner.md:56) and po-plan.md:41 say to write the oracle "Before the plan". A planner stopped between writing the oracle and writing the plan is resumed onto untracked test files with no plan. It then stops and hands over to a human, instead of picking up its own work.
  The stop is safe, so nothing is damaged silently. Accepting the files the story's `Owns` lists, or writing the plan first, would close the gap.

## Not verified
- Whether planner, implementer and orchestrator agents actually follow the new wording at run time. These are text tests, and the record says the same. A person should watch the first story planned after this lands: oracle files written, sums taken with `cksum < <file>`, and the implementer leaving them alone or logging a row under `## Oracle changes`.
- That the `## Oracle changes` rows are judged at review. The check that compares sums, and the review step for it, belong to s150, not this story.
- The verification record says the `main` defect was "fixed on `main` by #170". The commit on `main` is titled "(#168)". I did not query the forge to reconcile the number. This does not affect the gate, which passed on the current tree.
- I did not rerun the full suite, because the record was reused under `Verification mode: record`. I ran only `planner-writes-the-oracle.test.sh`: 7/7 green before and after the mutations.

Max severity: minor
Ship allowed: yes
