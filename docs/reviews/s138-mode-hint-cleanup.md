# Review — s138-mode-hint-cleanup

[Story](../stories.md) · [Plan](../plans/s138-mode-hint-cleanup.md) · [Verification](../verif/s138-mode-hint-cleanup.md)

Diff reviewed: `git diff main...story/s138-mode-hint-cleanup`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 634fe73914cfef08b2bdb3243e2eae2a26401572

## Ownership
I listed the diff with `git diff --name-status main...story/s138-mode-hint-cleanup`. It holds one commit, 97a4513.
- [x] Every path is inside `Owns`. `method/hooks/po-session.sh` (M) and `tests/update-keeps-mode.test.sh` (M) are both on the `Owns` line. `docs/plans/`, `docs/research/` and `docs/verif/s138-mode-hint-cleanup.md` are the story's own pipeline evidence, so they are in scope by construction.
- [x] No path falls inside another running story's `Owns`. The only other lane is s137 (worktree `.worktrees/s137-modified-copy-survives-drop`). It owns `bin/polype`, `docs/installation.md`, ADR-0092/0088 and `tests/drop-keeps-modified.test.sh`, and the diff touches none of them.

## Evidence reused
- [x] `po-gate verif-current s138-mode-hint-cleanup` passes (exit 0). The record is complete and its `Unit suite` row (`bash tests/run.sh`) exited 0. I reused it and did not rerun the full suite. The project has no `Typecheck`, `E2E` or `Build` command (`—`). The record's "Not proven here" says the same.
- [x] `po-gate qa-current` is not required. `QA stage: —` and `Surface: —`, so the story does not go to QA.

## Plan
- [x] All four tasks are present and nothing falls outside the plan. Task 1 rewrites the comment at `po-session.sh:241-242`. Task 2 adds the `absorbed_settings` helper at `tests/update-keeps-mode.test.sh:29`, used at `:105` and `:126`, plus `mode_is init` after the init run. Task 3 adds the two tests and updates the header line. Task 4 is the `po-run` row.
- [x] Each run interdict was checked:
  - The hook diff touches comment lines only, and the code at `:243-248` is byte-identical.
  - `bin/polype`, `.polype/` and `.claude/` have an empty diff.
  - No other test file changed.
  - No assertion was removed. The only change to old lines is the two `printf` lines moving into the helper.
  - Both `rm -f "$P/.polype/mode"` lines are kept.
  - No ADR was written.

## References
- [x] I confirmed what the change refers to: `recorded_mode` exists at `bin/polype:83` and `:92-101`; `mode_is`, `fresh_project` and `run_polype` exist in the test file; `$HOOK` points to `$METHOD/hooks/po-session.sh`.
- [x] The helper's settings text is byte-identical to the `printf` it replaces on `main`, including `Project CLAUDE file: absorbed`, which triggers the hint line.

## Rules
- [x] `AGENTS.local.md` conventions are respected: tests are bash, test names match the criteria, comments are in English, and no hook line goes past 100 characters.
- [x] No accepted ADR is contradicted. The new comment matches ADR-0091: `init .` repairs an inflated project.

## Tests
- [x] Floor: `po-gate floor-guard s138-mode-hint-cleanup main` exited 0, so nothing was lowered.
- [x] The assertions pin down the criteria, and none of the six empty test shapes appears. `test_session_comment_says_why` reads `$HOOK`, not its own file. `test_absorbed_settings_helper` counts the `printf` lines and reads both test bodies with awk.
- [x] 2 new tests and 2 reworked, well within `Test budget` 25.
- [x] Bite 1: I replaced the deduction branch (`[ "$recorded" != project ]` → `false`, `po-session.sh:245`). `test_session_hint_infers_init_without_mode` failed, 1 failing test, and `test_hints_say_init` stayed green as the plan expects. Undone with `git checkout --`; `git diff --exit-code` is clean.
- [x] Bite 2: I put back the old comment, "would lay the commands". `test_session_comment_says_why` failed, 1 failing test. Undone; `git diff --exit-code` is clean.
- [x] Bite 3: I disabled the recorded-mode branch (`if [ "$recorded" = init ] ||` → `if false ||`). 0 tests failed, 9 passed. Undone; `git diff --exit-code` is clean. See the minor finding below.
- [x] No test became useless because of this story.

## Neighbours
- [x] I read the other places that mention the changed text. `tests/update-keeps-mode.test.sh:120` checks the French docs for "poserait" and is unaffected. Nothing else refers to the comment or the helper.

## Lenses
Lenses run: none (no path or content in the diff triggers security, migration, dependencies or performance)
- [x] No lens findings.

## Findings
- minor — `method/hooks/po-session.sh:244` (code not in the diff) and `tests/update-keeps-mode.test.sh:107` — The recorded-mode branch (`[ "$recorded" = init ]`) is not tested. Disabling it fails none of the 9 tests in the file. `test_hints_say_init` does run with `.polype/mode` set to `init`, which the new `mode_is` line confirms, so the criterion holds as written. But its manifest has no command copies, so the deduction branch outputs `polype init .` anyway. Only an inflated init project would tell the two branches apart: `.polype/mode` set to `init` with `.claude/commands/` in the manifest. That is exactly the case the new comment names, and no test covers it. The gap predates s138 (s136 code), so this is minor. It should be filed in the Issue tracker for a later cycle.
- minor — `method/hooks/po-session.sh:241-242` — The comment's wording is awkward: "advise polype init ., the advised command and …" says "advise" twice, and the trailing `.` reads like the end of the sentence. It is correct and meets the criterion; this is style only.

## Not verified
- I did not rerun the full unit suite. I relied on the `po-run` record, whose tree matches this code. Only `tests/update-keeps-mode.test.sh` ran here, during the bites.
- The project has no type check, end-to-end or build command (`—`). Nothing of that kind was checked, and none applies to a bash comment and a test helper.
- I did not run the hook on an inflated init project (mode `init`, manifest with commands), because no test fixture exists for it. To cover it, a person or a later story should set up that case with `polype install` and then write `.polype/mode`, run `po-session`, and confirm the hint says `polype init .`.
- I did not open the GitHub issues #95 and #102. I relied on the story's and the research's account of them.

Max severity: minor
Ship allowed: yes
