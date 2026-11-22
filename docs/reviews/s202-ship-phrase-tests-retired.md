# Review — s202-ship-phrase-tests-retired

[Story](../stories.md) · [Plan](../plans/s202-ship-phrase-tests-retired.md) · [Verification](../verif/s202-ship-phrase-tests-retired.md)

Method version: 0.11.0
Recorded: 2026-11-22T17:46:58+01:00

Diff reviewed: `git diff main...story/s202-ship-phrase-tests-retired`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 13a52d145bb4f6e1eac6bf30366d29b33597eb37

## Ownership
Diff listed with `git diff --name-only main...story/s202-ship-phrase-tests-retired`, each path held against the story's `Owns` (`docs/stories.md:3302`) by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. The 4 deleted and 7 edited test files and the new oracle are all listed. The plan and the record are the story's own evidence.
- [x] Outside `Owns`: none
- [x] Inside another running story's `Owns`: none. `git worktree list` shows only this lane and `.claude/worktrees/framing-m22` (branch `fix/qa-deadline-wording`, not a story).
- [x] The story has an `Owns` line

## Evidence reused
- [x] `po-gate verif-current s202-ship-phrase-tests-retired` exits 0, so I reused the record. Its `Unit suite` row (`bash tests/run.sh`) exited 0 on tree `f7bde10…`, and the gate confirmed that this tree equals the commit outside `docs/`. The project has no type check (`Typecheck: —`). I did not rerun the full suite. The record's "Not proven here" leaves `po-lint` and floor-guard to separate runs. I ran floor-guard myself (below). I did not run `po-lint`.
- [x] `po-gate qa-current`: not required, because `QA stage: —`.

## Plan
- [x] Tasks 1 to 5 are all present, and the diff holds nothing the plan did not ask for.
  - Line ranges match the edits task by task: `ship.test.sh` and `ship-follows-forge.test.sh` each keep one function, `everything-in-issues` keeps 2, the intake oracle keeps 1, `po-retro` keeps only the `lacks_tool` loop, and `session-and-gate-checks:35-36` is gone.
- [x] Run interdicts, checked one by one:
  - `method/`, `po/`, `bin/`, `tests/lib.sh`, `tests/run.sh` and `tests/routing-phrase-tests-retired.oracle.test.sh` have an empty diff (`git diff --quiet` ran clean on them). No other `docs/` path changed. `tests/journey/` and `tests/fixtures/` are not in the diff.
  - Oracle cksum is `223123017 2463`, as the plan states. `tests/ship-phrase-tests-retired.test.sh` was not created.
  - No version bump (`po/` untouched).
  - No kept assertion is added or reworded.
- [x] The moved phrase is word for word. It was `'no issue text enters a shell argument'` with message `"po-intake.md"` in the removed loop. It is now `holds "$t" 'no issue text enters a shell argument' "po-intake.md"` at `tests/intake-issue-becomes-a-story.oracle.test.sh:17`, where `t` is the same `flat "$INTAKE"`.
- [x] d-0052 exception: nothing in it was lost or reworded.
  - `test_security_goes_to_the_person` and `test_finding_text_never_enters_a_command` in `everything-in-issues` have bodies identical to main. The helpers they use (`section_of`, `has`, `holds`, `LAW`, `SHIP`) are kept.
  - In the intake oracle, the function keeps its three original `holds` plus the moved one. `flat` and `holds` are kept.
  - `test_sensitive_failure_goes_to_the_person` is unchanged, including its doctrine-row `holds` lines (`:102-106`), and `DOCTRINE` is kept.
  - H1, H4, H6 and H7 are gone. All four are named in s206's criterion `m21_bis_rules_have_their_cases` on main (`docs/stories.md:3377`).

## References
- [x] I sampled `## Classification` and opened each cited reader:
  - Each cited test function exists and is defined: `test_gate_comes_first`, `test_one_commit_no_merge`, `test_nothing_is_removed_before_the_proof`, `test_pr_mode_never_pushes_target`, `test_forge_line_is_rewritten_by_the_command`, `test_chosen_is_never_rewritten`, `test_token_never_travels`, `test_nothing_before_the_proof` (ship-files-open-findings) and `test_ships_stay_serial_in_review_order`.
  - Journey functions: `test_story_lands_on_the_full_track`, `…through_a_pull_request`, `test_two_lanes_ship_in_order`, `test_real_gates_are_crossed`, `test_human_confirmation_waits_for_the_merge` and `test_pending_decision_holds_the_lane`.
  - Driver cases: `ships.cases:33` is `merge waiting` and `:60` is `landed`. `remote-check` appears in `ship-builds-the-landing-commit.test.sh:34,42`.
  - Code readers: `land.rs:195-196` (gate through `po-gate ship-allowed`), `land.rs:239-253` (remote_check), `mod.rs:33-55` (`(forge)`/`(chosen)`), `po-bounds.sh:37` (git push refused), `bin/polype:608-631` (prints template defaults) and `bin/po-lint:117-121` (tool contract).
- [x] Every kept assertion outside the d-0052 exception has a reader:
  - `needs_tool AskUserQuestion` is read by `po-lint`.
  - The template fence defaults are read by `bin/polype`.
  - `lacks_tool` is read by `po-lint`.
  - The `session-and-gate-checks` assertions launch `po-gate` and `po-session`.
- [x] The rows classed **M** have no script reader. Examples: the framing landing of `po-setup.md`, which no `po/` module implements (its framing code only rewrites `Ship confirmation`), the retro wording, and "one failure stops".
- [x] Count, established by sourcing each `tests/*.test.sh` after `lib.sh` the way `tests/run.sh:33-36` does, on a `file://` clone of main and on the story worktree:
  - before: 180 files, 825 functions;
  - after: 177 files, 790 functions.
  This matches the plan.

## Rules
- [x] `AGENTS.md` conventions respected: bash tests and English comments, and no method file changed.
- [x] No accepted ADR contradicted. The ADR-0090/0099 `superseded-by` and body-sum checks are dropped as the plan states (they move to #442). No ADR was modified.

## Tests
- Oracle: `po-gate oracle-intact s202-ship-phrase-tests-retired` → exit 0
- [x] Floor: `po-gate floor-guard s202-ship-phrase-tests-retired main` exits 1 with exactly four `test-file-deleted` flags, for the four files of task 1. Each is justified by task 1 and `## Classification`, so all four are graded minor under Findings. `po-gate oracle-intact` exits 0.
- [x] The oracle pins `contract_tests_stay` (the kept functions and the kept phrases). The other script-read criteria are covered by s201's tests on this tree. None of the six empty test shapes appears.
- [x] Within `Test budget` (one oracle test).
- [x] Bite: I renamed `test_finding_text_never_enters_a_command` in `tests/everything-in-issues.test.sh` and deleted the moved phrase line in `tests/intake-issue-becomes-a-story.oracle.test.sh`. Running `bash tests/run.sh ship-phrase-tests-retired.oracle.test.sh` then gave 1 failing test, and its message named both mutations. I undid both with `git checkout --`, and `git diff --exit-code` came back clean.
- [x] Tests the story made useless: removed, as classified.

## Neighbours
- [x] No other file under `tests/`, `method/`, `bin/`, `po/` or `docs/harnais.md` names a deleted file or a removed function. `docs/stories-reportees.md`, `docs/stories.md` and `docs/decisions-log.md` mention the deleted files only as history or story notes, and they are outside this story's diff.

## Lenses
Lenses run: none (only bash test files under `tests/`, with no auth, migration, dependency or server code).
- [x] No lens findings

## Findings
- minor — tests/ship-through-pr.test.sh:1 — floor-guard flag `test-file-deleted`, justified by plan task 1 and `## Classification` (PR, one commit and push rules now held by `po` and the journey tests).
- minor — tests/ship-and-fleet-cleanup.test.sh:1 — floor-guard flag `test-file-deleted`, justified by the plan (ships stay serial: journey `order` and the driver test).
- minor — tests/intake-issue-becomes-a-story.test.sh:1 — floor-guard flag `test-file-deleted`, justified by the plan (H4 goes to s206, the rest is **M**).
- minor — tests/framing-second-landing.test.sh:1 — floor-guard flag `test-file-deleted`, justified by the plan (the framing landing is prose in `po-setup.md`, **M**).
- minor — tests/intake-issue-becomes-a-story.oracle.test.sh:2 — the header still announces "reviewed on its issue and landed as framing", but the file now only checks the security hold. The same holds for `tests/ship-follows-forge.test.sh:2`, which now only checks template defaults. The plan kept these lines on purpose, so this is style only.

## Not verified
- `bin/po-lint method`: neither the record nor I ran it. s201's `test_contract_tests_stay` runs it inside the recorded green suite on this tree, so it is covered indirectly. A person can run `bin/po-lint method` to confirm directly.
- I did not rerun the full suite, because `po-gate verif-current` passed. The recorded run (533 s, exit 0) is the evidence.
- The model-read rules listed as **M** and the four H rules sent to s206 now have no test at all until s206 or a `po-eval` arm (#208) covers them. I only read them; nothing executes them.
- The plan says the lead must file a `po-lint` rule candidate for `Issue tracker` readers and an addition to #442 for the ADR-0090 body sum. I did not check whether either was filed, since I make no forge calls. A person should confirm both issues exist.

Max severity: minor
Ship allowed: yes
