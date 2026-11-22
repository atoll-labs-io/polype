# Review — s203-qa-and-design-phrase-tests-retired

[Story](../stories.md) · [Plan](../plans/s203-qa-and-design-phrase-tests-retired.md) · [Verification](../verif/s203-qa-and-design-phrase-tests-retired.md)

Method version: 0.11.0
Recorded: 2026-11-22T18:35:27+01:00

Diff reviewed: `git diff main...story/s203-qa-and-design-phrase-tests-retired`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: d6fbaa684312fb509b5ea1526c4b140d96597439

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s203-qa-and-design-phrase-tests-retired`: 32 test paths, plus the plan and the record.
- [x] Every path inside `Owns`. The 7 deleted files, the 24 edited files and the new oracle are all named on the story's `Owns` line. The plan and the record are this story's own pipeline evidence.
- [x] Outside `Owns`: none
- [x] Inside another running story's `Owns`: none. The other worktrees (`framing/s206-names-s203-rules`, `fix/qa-deadline-wording`) are not story lanes, and s204 waits on this story.
- [x] The story has an `Owns` line

## Evidence reused
- [x] `po-gate verif-current` passes. I reused the record: `Unit suite` `bash tests/run.sh` exit 0 on code equal to `Tree: dea8fbc…` outside `docs/`. I did not rerun the full suite. The project has no type check (`Typecheck: —`). I read the record's "Not proven here".
- [x] `po-gate qa-current`: not required. The story has `Surface: command` and `QA stage: —`, so it does not go to QA.

## Plan
- [x] Each task is present and nothing falls outside the plan. In each of the 24 edited files, the story file equals the `5b79bfd` file with exactly the plan's line ranges deleted. I checked this with `sed` and `diff`, file by file. That covers the seven QA files the first attempt emptied (`qa`, `qa-gate`, `qa-drivers`, `qa-fleet`, `qa-contract-holds`, `qa-reads-ignore-rules`, `qa-report-returned-as-text`): each one matches its ranges exactly. Hunk boundaries that differ from the plan in `git diff` are only the diff algorithm shifting blank or identical lines.
- [x] The one added line in `scene-and-simulation-drivers.test.sh:16` is `  contains "$SIMULATION" "$SET_ASIDE"`, placed after base `:46`. It is the loop's `contains "$SIMULATION" "$phrase"` with `$SET_ASIDE` filled in, written the way `:39` writes it for the scene. The two match word for word.
- [x] Run interdicts, checked one by one:
  - nothing under `method/`, `po/`, `bin/`, `boilerplates/` or `docs/` changes, other than the plan and the record;
  - `tests/lib.sh`, `tests/run.sh`, `tests/journey/` and `tests/fixtures/` are untouched;
  - `routing-phrase-tests-retired.oracle` and `qa-lanes-isolated.oracle` are untouched;
  - no test file outside `Owns` changes, and no `s203…test.sh` was created;
  - no version bump;
  - no kept line was reworded.

## References
- [x] Every helper and reader I opened is real:
  - `tests_defined` is at `routing-phrase-tests-retired.oracle.test.sh:222`. The `sed '/^test_/,$d'` source keeps it, since the first `test_` line is `:227`.
  - `lane.rs:86-94,105-114,179-193` and `lane.rs:110` (`is current but`) exist as cited.
  - `stories.rs:149` reads the `- **Surface**` line.
  - `po-lint:144,276` and `bin/polype` `missing_settings` (template settings) exist as cited.
  - `record/mod.rs:175-181` refuses an answer with no `QA status:` line.
- [x] Counts match the plan: 177 → 171 files and 790 → 726 functions, counted the way `tests/run.sh` loads them (`declare -F` after sourcing, base taken from a throwaway clone). That is 65 functions removed and 1 added.

## Rules
- [x] `AGENTS.local.md` conventions are respected: tests are bash, and no existing clause test was changed beyond what the plan says.
- [x] No accepted ADR is contradicted. I applied d-0051 (H1–H10 removed and named for s206) and d-0052 option c (S1–S7 kept).

## Tests
- Oracle: `po-gate oracle-intact s203-qa-and-design-phrase-tests-retired` → exit 0
- [x] Floor: `po-gate floor-guard … main` exits 1 with exactly 7 `test-file-deleted` flags, the files of task 1. Task 1 and `## Classification` justify all seven. Graded below.
- [x] The oracle pins `contract_tests_stay`. The other script-read criteria are held by s201's tests on this tree. None of the six empty test shapes appears in the oracle.
- [x] Within `Test budget` (one oracle test).
- [x] Bite 1: I removed the unrolled `contains "$SIMULATION" "$SET_ASIDE"`. Result: 1 failing test (`contract_tests_stay`). Undone with `git checkout`, then `git diff --exit-code` was clean.
- [x] Bite 2: I renamed `test_designer_writes_only_in_the_story_design_folder` (S5). Result: 1 failing test. Undone, then `git diff --exit-code` was clean.
- [x] `po-gate oracle-intact` exits 0.
- [x] d-0052: every line of S1–S7 is still present with its text unchanged. The range check proves no S line was touched.

## Neighbours
- [x] s204's oracle will source the same helpers; this diff does not change them. No other test sources a deleted file.

## Lenses
Lenses run: none. The diff only deletes bash phrase tests and adds a bash oracle; it has no security, migration, dependency or performance trigger.
- [x] No lens findings

## What only a product proves
This repeats the plan's list (`docs/plans/s203-qa-and-design-phrase-tests-retired.md:158-181`). These rules have no test left, and no journey proves them:
- Browser and mobile: the phone viewport at 360 and 412 CSS px, never by zoom; one capture per state and width; 44×44 targets, safe areas, keyboard, no hover; native prompts, notifications, camera and gestures never reported as seen.
- Accessibility: visible focus, named controls, text alternatives, not by colour alone, the keyboard-only walk.
- Scene: headless capture under `xvfb-run` with `--xr-mode off`; one capture per viewpoint and the uniform-colour check; `## Not seen` for comfort, scale and hand tracking; processes stopped.
- Simulation: ROS and Gazebo isolation variables, `/clock` advancing; bag record and extract, `ros2 daemon stop`, no node left; `## Not seen` for noise, friction and emergency stop.
- Scenarios: one invalid input per criterion, the error transcript, one transcript per scenario.
- Design: the mockup rendered over local HTTP in light and dark, desktop and mobile, nothing measured; contrast measured once on every text/surface pair; deltas only for a derived screen, one artefact for a new one.
- QA report: steps, capture, severity and `verified`/`probable`/`unverified`; the `Driver:` and `Evidence:` lines.
- Profiles: the iOS and Expo `Test` commands fail on red; Expo and Flutter `Dev` serve the web render.

The list misses some items; see the major finding.

## Findings
Security findings: 2 — decision d-0053
- major — docs/plans/s203-qa-and-design-phrase-tests-retired.md:158 — `what_only_a_product_proves_is_listed` is incomplete against the removed tests. Three QA rules lose their test, no journey proves them, and they are not on the list:
  - the first QA sets `?? docs/qa/` aside when its parent holds nothing else (the deleted `qa-evidence-set-aside:test_first_qa_sets_its_evidence_aside`);
  - the surface×platform driver mapping itself (`qa-drivers:test_qa_picks_the_driver_of_the_surface`; H3 covers only the stop);
  - the scenario service started on a free port in its own process group, then checked silent after the stop (`scenario-driver`, base `:22-28`).
- minor — docs/plans/s203-qa-and-design-phrase-tests-retired.md:91 — The `qa-gate:test_review_requires_a_current_qa_report` row names `lane.rs:105-114` as its reader. That only covers routing review after QA. The same test also pinned reviewer-side rules that only a model reads: verified QA findings become review findings, and the `qa-current` box in `templates/review.md`. These should carry **M**.
- minor — tests/qa-and-design-phrase-tests-retired.oracle.test.sh:38 — The comment says `S203_KEPT_LINES` holds "every security assertion the owner kept". It holds only part of them. Not pinned:
  - S5: `'No source file, no test file, no commit'`, `'the files stay uncommitted'`, `'never code'` and the `git worktree add` line in `fleet-design`;
  - S6: `'never code: nothing in it is copied into source files'` and the designer line in `designer-browser`;
  - S7: `'handed to the person'` and `'the code still carries the old values'`.

  Deleting one of these lines would pass the oracle. They are all present on this tree.
- minor — tests/qa.test.sh:41 — `local … setup="$METHOD/commands/po-setup.md" row step` is now unused, a leftover of the deleted step-2 lines.
- minor — docs/plans/s203-qa-and-design-phrase-tests-retired.md:184 — `po-gate floor-guard` flags 7 deleted test files: `accessibility`, `bricks`, `capability-bricks`, `catalogue-wiring`, `design`, `mobile-web-driver` and `qa-evidence-set-aside`. The plan names each one and gives its reason, so each flag is graded minor here.

## Not verified
- I did not rerun the full suite; I relied on the `po-run` record. The 24 edited files were not each run focused here. Only the oracle ran, before and after the two bites.
- I did not check that the oracle fails on the base tree (the plan says it does until task 4). A person can run it on a checkout of `5b79bfd`.
- The grounding tests fetch upstream repositories. Whether they ran or were skipped in the recorded run was not read.
- `kept_assertions_have_a_reader` was judged by sampling, not exhaustively. I opened the readers of the `qa`, `qa-gate`, `qa-fleet`, `qa-report-returned-as-text`, `platform-setting` and `designer-browser` rows. The remaining **M**/**P** rows were taken from the plan.
- `bin/po-lint method` was not rerun. The record says it was run separately but not recorded.
- No QA report exists, because the story does not go to QA. Nothing on the product list above was observed by anyone.

Max severity: major
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-22T18:53:12+01:00

Diff reviewed: `git diff main...story/s203-qa-and-design-phrase-tests-retired`, judged by a context that did not write it. Fix run 1 is commit 5142a05. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 4e7f9e460eaf562b7a204133c7fd3b8b70da0983

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
`git diff --name-only main...story/s203-qa-and-design-phrase-tests-retired` lists 32 test paths plus the plan, the record and the review. Fix run 1 touched only `qa-report-returned-as-text`, `scenario-driver`, `qa`, the oracle, the plan and the record.
- [x] Every path is inside `Owns` (`docs/stories.md:3319`). The plan, the record and the review are this story's own pipeline evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows only main, this lane and `fix/qa-deadline-wording`, which is not a story lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` passes (exit 0). I reused the record: `Unit suite` `bash tests/run.sh` exited 0 on code equal to `Tree: fe36ed7…` outside `docs/`. The full suite was not rerun. The project has no type check (`Typecheck: —`), no E2E and no build. I read the record's "Not proven here".
- [x] `qa-current` is not required: the story has `Surface: command` and `QA stage: —`.
- [x] Counts, as `tests/run.sh` loads the files: 171 files and 727 functions, as expected.

## Previous findings (fix loop 0)
- [x] Major, product list incomplete: closed. `## What only a product proves` now names the first QA's set-aside of `?? docs/qa/`, the surface×platform mapping, and the scenario service on a free port in its own process group.
- [x] Minor, `qa-gate:test_review_requires_a_current_qa_report` row: closed. The row now reads `lane.rs:105-114`, D, J, and gives the reviewer-side rules **M**.
- [x] Minor, S5/S6/S7 lines not pinned: closed. The oracle now pins lines 57, 59 and 65-72. I checked that each pinned line is present in its file.
- [x] Minor, unused `local` in `tests/qa.test.sh`: closed. The line is removed and nothing else in the function changed.
- [x] Minor, floor-guard flags: unchanged and still justified. They are graded again below.

## Security decision d-0053
- [x] `qa-report-returned-as-text` matches base `5b79bfd` word for word on `:4` (`QA_AGENT`), `:11` (`section_of`), `:17-18`, `:20` and the assertion at `:24`. The base's `local report final` comes back as `local report`, because `final` is no longer used. No other line of the removed functions came back: `git diff 5b79bfd` adds only that `local` line.
- [x] In `scenario-driver`, base lines `:31` and `:34` came back word for word. `:32-33` were not restored, and the product list now holds them.
- [x] Bites, run on the oracle alone and each undone with `git checkout` and a clean `git diff --exit-code`:
  - deleting the S8 assertion: 1 failure (`contract_tests_stay`);
  - deleting the `'and only that one'` line: 1 failure;
  - deleting the `'127.0.0.1'` line: 1 failure;
  - deleting the S5 `'never code'` line of `fleet-design`: 1 failure.

## Plan
- [x] Fix run 1 matches the fix-loop findings and the d-0053 answer. Nothing was changed beyond that.
- [x] On main, H1–H10 are named one by one in s206's `m21_bis_rules_have_their_cases` (`docs/stories.md:3377`, commit 693a73d). The ten clauses match the plan's H1–H10.
- [x] Run interdicts hold. Nothing under `method/`, `po/`, `bin/`, `boilerplates/` or `docs/` changed apart from the plan, the record and the review. No version bump.

## References
- [x] The restored helpers resolve. `section_of` is defined in the file, and `$QA_AGENT` points to `method/agents/qa.md`. A focused run of the oracle, `qa-report-returned-as-text`, `scenario-driver` and `qa`: 10 passed, 0 failed.

## Tests
- Oracle: `po-gate oracle-intact s203-qa-and-design-phrase-tests-retired` → exit 0
  tests/qa-and-design-phrase-tests-retired.oracle.test.sh: changed, logged in ## Oracle changes — `S203_KEPT` adds `test_qa_returns_its_report`; `S203_KEPT_LINES` adds the restored lines of `qa-report-returned-as-text` and `scenario-driver` and the S5, S6, S7 lines the review found unpinned. New cksum `1497978296 7488` (was `3547054909 6749`). — Fix run 1: the review's minor on the keep list, and the assertions restored under d-0053 and d-0052 option c (S8, S9 of the plan).
  po-gate: 1 logged oracle change(s) of s203-qa-and-design-phrase-tests-retired to judge
- Oracle: `po-gate oracle-intact` exit 0, with one logged change. The new cksum `1497978296 7488` matches the file. The change only adds kept functions and pinned lines, so it strengthens `contract_tests_stay` and does not weaken it. Accepted.
- [x] Floor: `po-gate floor-guard … main` exits 1 with exactly the 7 `test-file-deleted` flags of task 1. All 7 are justified in the plan, so they are graded minor.
- [x] Within `Test budget`: one oracle test.
- [x] Bites: see the d-0053 section, 4 out of 4 bite.

## Neighbours
- [x] No other test sources the changed files. s204's oracle sources s201's helpers, which are unchanged.

## Lenses
Lenses run: none. The diff only changes bash phrase tests and an oracle, so no security, migration, dependency or performance trigger fires.
- [x] No lens findings

## What only a product proves
This repeats the plan's list (`docs/plans/s203-qa-and-design-phrase-tests-retired.md`, `## What only a product proves`):
- Browser and mobile:
  - the 360 and 412 CSS px viewport, never set by zoom;
  - one capture per state and width;
  - 44×44 targets, safe areas, keyboard, no hover;
  - native prompts, notifications, camera and gestures never reported as seen.
- Accessibility: visible focus, named controls, text alternatives, not by colour alone, keyboard-only walk.
- Scene:
  - `xvfb-run` with `--xr-mode off`;
  - one capture per viewpoint, plus the uniform-colour check;
  - `## Not seen` for comfort, scale and hand tracking;
  - processes stopped.
- Simulation:
  - ROS and Gazebo isolation variables, `/clock` advancing;
  - bag record and extract, `ros2 daemon stop`, no node left;
  - `## Not seen` for noise, friction and emergency stop.
- Scenarios:
  - one invalid input per criterion, the error transcript, one transcript per scenario;
  - the service started on a free port in its own process group, then checked silent after the stop.
- QA drivers:
  - the first QA sets `?? docs/qa/` aside when its parent holds nothing else;
  - the surface×platform driver mapping itself.
- Design:
  - mockup rendered over local HTTP in light and dark, desktop and mobile;
  - contrast measured once on every text/surface pair;
  - deltas only for a derived screen, one artefact for a new one.
- QA report: steps, capture, severity, `verified`/`probable`/`unverified`; the `Driver:` and `Evidence:` lines.
- Profiles: the iOS and Expo `Test` commands fail on red; Expo and Flutter `Dev` serve the web render.

## Findings
Security findings: 0. Decision d-0053 is lifted: both restored assertions are back word for word against `5b79bfd`, and the oracle pins them and bites on them.
- minor — docs/plans/s203-qa-and-design-phrase-tests-retired.md:199 — Some plan text still describes the first run and now contradicts the fix:
  - Task 2 (`:199`) still lists `:4,…,11-12,…,17-48` and task 4 (`:208`) still lists `:31-34` as deleted. Both ranges include lines fix run 1 restored (S8, S9), which the classification table and `## Rules the owner decides` now keep.
  - `:65` still gives cksum `3547054909 6749`, and the run interdict at `:239` still says the oracle keeps that sum.

  The gate is not affected: `## Oracle changes` logs the new sum and `oracle-intact` passes. But a reader who replays the tasks, such as s204 or s206 reusing this plan's shape, would delete S8 and S9 again.
- minor — docs/plans/s203-qa-and-design-phrase-tests-retired.md:184 — `po-gate floor-guard` flags 7 deleted test files: `accessibility`, `bricks`, `capability-bricks`, `catalogue-wiring`, `design`, `mobile-web-driver` and `qa-evidence-set-aside`. Task 1 and `## Classification` name each one with its reason, so each flag is minor.

## Not verified
- I did not rerun the full suite and relied on the `po-run` record. Only the oracle and the four files touched by the fix were run focused here.
- I did not check that the oracle fails on base `5b79bfd`. A person can run `bash tests/run.sh qa-and-design-phrase-tests-retired.oracle.test.sh` on that checkout.
- I did not read whether the grounding tests ran or were skipped in the recorded run, since they reach upstream repositories.
- `kept_assertions_have_a_reader` was sampled at fix loop 0. This time I re-read only the rows the fix changed.
- `bin/po-lint method` was not rerun. The record says it was run but not recorded.
- No QA report exists, because the story does not go to QA. Nothing on the product list above has been observed by anyone. A person covers it when s206's real run walks a screen, scene, simulation and scenario story.
- I did not read the text of decision d-0053 (inbox and private folder). I judged the lift only from what the lane states.

Max severity: minor
Ship allowed: yes
