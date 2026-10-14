# Review — s127-hooks-installer-docs-cleanup

Diff reviewed: `git diff main...story/s127-hooks-installer-docs-cleanup` (merge base 553700b, s124; `main` has since moved to fc8caf4 with s126, and none of s126's paths overlap this diff). The review ran in a context that did not write the code. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 60a7bd130ee1f364512b0c06d5bd3a72d8efcb8c

## When blocked
— (not blocked)

## Ownership
The changed paths come from `git diff --name-only main...story/s127-hooks-installer-docs-cleanup`. Each was checked against the story's `Owns` line (`docs/stories.md:1972`).
- [x] Every path is inside `Owns`. The 17 code and doc paths each match an `Owns` entry exactly. The other three are this story's own `docs/research/`, `docs/plans/` and `docs/verif/` files, which are in scope by construction.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows only main and this worktree. s128 will own `method/templates/review.md`, but it has no worktree, so it is not running.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` exits 0, so the record is reused. `Verification mode: record`, Unit suite `bash tests/run.sh` exited 0 on the recorded tree. Type check, E2E and Build are `—`: the project has none.
  - The record's "Not proven here" section says:
    - the real `/po-setup` framing landing was never run;
    - `remove` without jq was only tested on Linux.
- [x] `po-gate qa-current` is not required: `QA stage: —` and `Surface: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–10 are all present, and nothing in the diff falls outside the plan.
- [x] Run interdicts, checked one by one:
  - `method/hooks/pre-commit`, `po-ship.md`, `bin/po-eval`, `simulation.md`, `tests/gate.test.sh`, `tests/review-tree-gate.test.sh`, `tests/scene-and-simulation-drivers.test.sh` and `tests/project-lead.test.sh` have an empty diff.
  - In ADR-0080 only the `superseded-by` line changes. ADR-0081 and ADR-0056 have an empty diff, and no new ADR was added.
  - The s105 plan has an empty diff.
  - `po-gate.sh:70` still reads the last `^([-*] )?Ship allowed:` line.
  - `pre-commit` with no argument still diffs against HEAD. My probe confirmed it: exit 0 with no base, exit 1 with a base.
  - In `templates/review.md` only the Findings placeholder changed.
  - `bin/polype` contains no sed or awk rewrite of `settings.json`.
  - In the parity doc only the H04 row changed.

## References
- [x] Every reference opened:
  - `paired_value` and `paired_hash` (`po-gate.sh:37-53`).
  - `settings_file_is_usable` and `cmd_remove` (`bin/polype:288`, `:559-567`). The ordering is confirmed: the manifest files, including po-session.sh, are deleted before `unwire_session_hook` runs, so the new comment is accurate.
  - The stop message quoted in `docs/installation.md` matches `po-ship.md:64` and `po-setup.md:63` word for word.
  - `po-brief.md:41`, `:57` and `prd.md:9` agree with the new `brief.md:8`.
- [x] Values checked:
  - `<base>` is resolved through `git rev-parse --verify --quiet "<base>^{commit}"` before it reaches `git diff`. A bad base is refused (tested), and an option-shaped base cannot reach git as an option.
  - `[[:space:]]*$` in `VERDICT_LINE` tolerates CR.

## Rules
- [x] The `AGENTS.md` conventions are respected: English method files, tests written in bash with `lib.sh` helpers, and the ADR-0080 edit is frontmatter only, as Law 6 allows.
- [ ] One accepted ADR is touched in its spirit: ADR-0056. See finding M1.

## Tests
- [x] Floor guard: `po-gate floor-guard s127-hooks-installer-docs-cleanup main` exits 0, so nothing was lowered.
- [x] The assertions pin the criteria. I found none of the six empty shapes:
  - the scan test builds a real temp index from the base;
  - the jq-less test removes jq from PATH and checks for that.
- [x] Test count: 8 new tests and 3 extended, within `Test budget` 25.
- [x] Bite checks. Each mutation was undone, and `git diff --exit-code` was clean after each one:
  - Dropping `${DIFF_BASE:+…}` from the `-U0` content diff in `secret_scan` → 1 failing test (`hooks-installer-docs-cleanup` + `gate`).
  - Putting back the old `VERDICT_LINE='^([-*] )?Ship allowed:'` → 1 failing test (`hooks_say_what_they_do_bullet_keeps_the_block`; `review-tree-gate` and `gate` stay green).
  - Dropping `" in a throwaway repo"` from the `check_config_key` call → 1 failing test (`throwaway_refuses_another_work_tree`).
  - Replacing the jq-less `grep -qF` in `unwire_session_hook` with `false` → 1 failing test (`installer_and_docs_agree_remove_without_jq`).
  - Dropping `${DIFF_BASE:+…}` from the two `--name-only -z` path lists (env-file list in `secret_scan`, and `claude_md_check`) → **0 failing tests**. See finding M2.
- [x] No test was made useless by the story.

## Neighbours
- [x] `check_config_key`'s reviewer callers pass no second argument, and `${2-}` keeps the message unchanged for them.
- [x] `paired_value`'s QA and verif callers keep their own patterns.
- [x] `git_env_word`'s two call sites were both rewritten and keep the old success and failure semantics. GIT_DIR and GIT_WORK_TREE cases in the bounds tests are covered by the green suite in the record.
- [x] `method/hooks/pre-commit` calls `pre-commit` with no argument and is unaffected.

## Lenses
Lenses run:
- **Security.** Triggered by content: `method/hooks/po-gate.sh` changes the secret and CLAUDE.md scan that `/po-setup` relies on, and the ship-allowed verdict reading.
  - The base argument cannot be injected.
  - My probe confirms that a `.env` the commit adds over `<base>`, while HEAD already holds it, is now refused (exit 1); without a base it passes (exit 0), as before.
  - On the verdict bound, see M1. It opens no ship of unjudged code. A borrowed `Reviewed tree:` must still equal the current code outside `docs/`, and the last `Review status:` line of the file must still say `complete`.
- Migration, dependencies and performance did not run: their triggers are absent.

## Findings
- **major** — `method/hooks/po-gate.sh:66` (`VERDICT_LINE`) against `method/commands/po-ship.md:18` and ADR-0056 (M1).
  - The new code bounds a verdict block only on an exact `Ship allowed: yes|no` line.
  - ADR-0056's Decision Outcome says the bounding line is `Ship allowed:` with a bullet allowed. It also says the same reading is described for the check without the hook. `po-ship.md:18`, outside `Owns` and interdicted, still describes that check as "the verdict line before it", meaning any `Ship allowed:` line.
  - So the gate and its hookless description now disagree. A findings bullet starting `Ship allowed:` passes the gate but would refuse by hand. That direction is fail-safe.
  - The narrower bound also partly reopens ADR-0056's rejected third option. An earlier stacked review ending in a qualified `Ship allowed: no (…)` no longer closes its block, so a later review that lost its `Reviewed tree:` or `Review status:` would borrow the earlier one's.
  - The borrowed tree must still match the current code, so no unjudged code ships. But the decision ADR-0056 records, one reading shared by the hook and its hookless description, no longer holds.
  - Fix in a later cycle: align `po-ship.md:18` (and `bin/po-eval:113` if it should follow), and record the narrowed bound in an ADR that refines or supersedes ADR-0056, rather than leaving it as a "refinement" in the plan's pivot.
- **major** — `method/hooks/po-gate.sh:198` and `:264`: the base is applied to the staged-path lists of `secret_scan` (env-file check) and `claude_md_check`, but no test covers it (M2).
  - Removing `${DIFF_BASE:+"$DIFF_BASE"}` from both lists fails no test. Only the content (token) diff is covered.
  - The behaviour itself is correct: my probe shows a `.env` added over `<base>` is refused only with the base.
  - The plan's "fails if the base is ignored" holds for one of the three diffs only, so half of the security-relevant fix for row 142 is untested.
  - Fix: extend `test_hooks_say_what_they_do_scan_reads_the_base` with a `.env` (or `CLAUDE.md`) that HEAD already tracks and the temp index adds over the base.
- **minor** — `method/hooks/po-gate.sh:292`: the story-branch staged list (`pre_commit`) also takes `<base>`, and no test covers that. The only caller passing a base, `/po-setup`, never runs on `story/*`, so this is coherence only.

## Not verified
- A real `/po-setup` framing landing that calls `po-gate.sh pre-commit <base>`, with a real temporary index and `commit-tree`. Only the hook was exercised, in scratch repos (by the tests and by my probe in `/tmp/tmp.jvduEzoy76`). To cover it, a person runs one framing landing on a test project whose root HEAD is ahead of `<base>`.
- `remove` without jq on macOS bash 3.2. The record covers Linux only. To cover it, a person runs `polype remove` on macOS with jq absent.
- The new `docs/installation.md` subsection on moving from `Merge mode: local` to `pr` was read, not followed: no project was migrated. To cover it, a person follows the steps on a local-mode project that has a remote.
- The `scene.md` key `application/run/main_scene` and the Godot profile's resolution wording were not checked against a running Godot 4.7.2. They are text-only.
- The unit suite and the type check were not rerun: they come from the record, as explained above.

Max severity: major
Ship allowed: yes

---

# Review: s127-hooks-installer-docs-cleanup

Diff reviewed: `git diff main...story/s127-hooks-installer-docs-cleanup`. The merge base is 553700b (s124). `main` has since moved to fc8caf4 with s126, and none of s126's paths overlap this diff. The review ran in a context that did not write the code. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 94771e40710624dd22501ba87c490bedbf8235a4

## When blocked
— (not blocked)

## Ownership
- [x] Every path is inside `Owns` (`docs/stories.md`, s127). The 17 code and doc paths each equal an `Owns` file entry, ADR-0080 included. The research, plan, verif and review files are this story's own evidence, so they are in scope by construction.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows only main and this worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s127-hooks-installer-docs-cleanup` exits 0. `Verification mode: record`, and the last Unit suite run of `bash tests/run.sh` exited 0 on code equal to the fix-run commit.
  - The project has no type check, E2E or build (`Typecheck`, `E2E` and `Build` are `—`).
  - "Not proven here" says the real `/po-setup` landing was never run, and `remove` without jq was tested on Linux only.
- [x] QA is not required: `QA stage: —` and `Surface: —`.

## Plan
- [x] Tasks 1–10 and the fix-run items M1, M2 and the minor are present. The diff holds nothing the plan did not ask for.
- [x] Run interdicts, checked:
  - These files have an empty diff: `pre-commit`, `po-ship.md`, `bin/po-eval`, `simulation.md`, `tests/gate.test.sh`, `tests/review-tree-gate.test.sh`, `tests/scene-and-simulation-drivers.test.sh`, `tests/project-lead.test.sh`, the s105 plan, ADR-0081 and ADR-0056.
  - In ADR-0080, only `superseded-by` changes.
  - In `templates/review.md`, only the Findings placeholder changes.
  - In the parity doc, only H04 changes.
  - `bin/polype` contains no sed or awk rewrite of `settings.json`.
- [x] M1 (loop 0) is closed as the lead decided. `ship_allowed` in `method/hooks/po-gate.sh:71`, `:75` is back to `'^([-*] )?Ship allowed:'`, and that function has no diff against the merge base. The template sentence ("any line that does closes the review's verdict block") is now true of that bound.
- [ ] The story's criterion text still asks for the opposite bound. See finding 1.

## References
- [x] Opened:
  - `DIFF_BASE` is applied to all four staged diffs (`po-gate.sh:196`, `:206`, `:262`, `:290`).
  - The dispatcher passes `${2:-}`.
  - The base is resolved through `rev-parse --verify --quiet "<base>^{commit}"`, so a resolved SHA reaches git and no option-shaped argument can.
  - `check_config_key`'s callers are `po-bounds.sh:747`, `:751` and `:810`.
  - `git_env_word` and `ENV_WORD` are used at `:700` and `:715-716`.
  - `unwire_session_hook` is in `bin/polype`.
  - The stop line in `docs/installation.md` is identical to `po-ship.md:64`.

## Rules
- [x] The `AGENTS.md` conventions hold: English method files, bash tests on `lib.sh`, and a frontmatter-only ADR-0080 edit as Law 6 allows.
- [x] ADR-0056 holds again: the hook and the hookless description in `po-ship.md:18` share one bound.

## Tests
- [x] Floor guard: `po-gate floor-guard s127-hooks-installer-docs-cleanup main` exits 0.
- [x] None of the six empty shapes. The scan tests build real temp indexes from the base, the jq-less test proves jq is unreachable, and the review fixture is one a reviewer could write.
- [x] Test count: 9 new tests and 3 extended, within `Test budget` 25.
- [x] Bite checks. Each mutation was undone with `git checkout --` and checked with `git diff --exit-code`, which came back clean.
  - Base removed from the env-file list (`po-gate.sh:196`) → 1 failure (`scan_reads_the_base`). This was 0 at loop 0, so M2 is closed.
  - Base removed from the `CLAUDE.md` list (`:262`) → 1 failure (`scan_reads_the_base`).
  - Base removed from the story staged list (`:290`) → 1 failure (`story_list_reads_the_base`). The loop-0 minor is closed.
  - Verdict bound narrowed to an exact `yes|no` line (`:71`, `:75`) → 1 failure (`findings_bullet_warned`). `gate` and `review-tree-gate` stay green.
  - The jq-less `grep -qF` replaced with `false` (`bin/polype`) → 1 failure (`remove_without_jq`).
  - The `" in a throwaway repo"` suffix dropped (`po-bounds.sh:810`) → 1 failure (`throwaway_refuses_another_work_tree`).

## Neighbours
- [x] `method/hooks/pre-commit` calls with no argument, so it still diffs against HEAD.
- [x] `/po-setup:79` is the only caller that passes a base. The other framing commands land "this way", through that section.
- [x] The reviewer callers of `check_config_key` pass no `$2`, so their message is unchanged.
- [x] Both `git_env_word` call sites keep their success and failure meaning.

## Lenses
Lenses run:
- **Security.** Triggered by content: `method/hooks/po-gate.sh` changes the secret, env-file and `CLAUDE.md` scan that the `/po-setup` landing relies on.
  - The base cannot be injected.
  - All three scans read what the commit adds over `<base>`, and each is bitten by a test.
  - The verdict reading is unchanged from main.
- Migration, dependencies and performance did not run: their triggers are absent.

## Findings
1. **major**: `docs/stories.md`, criterion `hooks_say_what_they_do` of s127, against `method/hooks/po-gate.sh:71`, `:75`.
   - The criterion asks that a findings bullet starting with `Ship allowed:` no longer closes a verdict block. The fix run deliberately kept ADR-0056's bound, so such a bullet still closes the block, and a sound review holding one is refused. That is fail-safe.
   - Only the template warning addresses triage row 80. That clause of the criterion is unmet as written.
   - The plan records the choice, but `docs/stories.md` (outside `Owns`) still says the opposite. This is the incoherence case (story against accepted ADR) that `AGENTS.md`, "What goes to the person", sends to the person; here the lead settled it alone.
   - Fix, done by a person: amend the criterion to "templates/review.md warns against it", or, if the narrower bound is wanted, write an ADR that supersedes ADR-0056 and align `po-ship.md:18` and `bin/po-eval`.

## Not verified
- **The real `/po-setup` landing.** A framing landing that calls `po-gate.sh pre-commit <base>` with a real temp index and `commit-tree` was not run. Only the hook was exercised, in scratch repos. To cover it, a person runs one framing landing on a test project whose root HEAD is ahead of `<base>`.
- **`remove` without jq on macOS bash 3.2.** The record covers Linux only. To cover it, a person runs `polype remove` on macOS with jq absent.
- **The new local→pr subsection of `docs/installation.md`.** It was read, not followed. To cover it, a person migrates one local-mode project that has a remote.
- **The Godot wording.** The `scene.md` key `application/run/main_scene` and the profile's resolution wording were not checked against a running Godot 4.7.2. They are text only.
- **The lead's decision log.** Whether the M1 decision has its line in `docs/decisions-log.md` is outside this diff and was not checked. None was found in the worktree or on `main`; it lands after the wave.
- **The unit suite and the type check.** They were not rerun. They come from the record; the project has no type check.

Max severity: major
Ship allowed: yes
