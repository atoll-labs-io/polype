# Review — s123-local-copy-checksums

[Story](../stories.md) · [Plan](../plans/s123-local-copy-checksums.md) · [Verification](../verif/s123-local-copy-checksums.md)

Diff reviewed: `git diff main...story/s123-local-copy-checksums`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: df43f0cc269f854c471ef67036d65b9334e055e2

## When blocked
Not blocked.

## Ownership
I listed the diff with `git diff --name-status main...story/s123-local-copy-checksums` and held each path against the story's `Owns`.
- [x] Every path is inside `Owns`. `bin/polype`, `docs/installation.md`, `tests/installer.test.sh` and `tests/local-copy-checksums.test.sh` are all listed. `docs/plans/`, `docs/research/` and `docs/verif/` are the story's own evidence. `docs/decisions/ADR-0087-…md` is added (status A) and the plan names it, so it is in scope too.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. `git worktree list` shows only the main checkout and this worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s123-local-copy-checksums` exits 0, so I reused the record. Its `Tree:` (01a2d36…) and the run's tree (b44a0c0…) both equal HEAD outside `docs/`, checked with `git diff --quiet`. The one declared check, the unit suite `bash tests/run.sh`, exited 0. The project has no type check (`Typecheck: —`). The record's "Not proven here" says no real `install`, `update` or `remove` ran on Polype, pecten or nautile.
- [x] `po-gate qa-current`: not required. `QA stage: —`, and the story's `Surface` is `—`.

## Plan
- [x] Tasks 1 to 7 are all present. The diff holds nothing the plan did not ask for. The `## Reuse` table is respected: the `.next` then `mv` pattern, the `grep -qxF || printf >>` gitignore idiom and `sum_of` are reused, and `copy_of_the_method` is not moved into `lib.sh`.
- [x] Run interdicts, one by one:
  - `method/`, `.claude/`, `.polype/` and `AGENTS.md` are absent from the diff.
  - `tests/lib.sh`, `tests/run.sh`, `install.test.sh` and `global-install.test.sh` are unchanged.
  - Global mode sets `local_sums=""`, so `record_sum` and `finish_sums` write only `$checksums` and never create `.claude/`.
  - `remove` does not touch `.gitignore`.
  - The test that asserts on `.gitignore` (`local_sums_file_stays_out_of_git`) pins `XDG_CONFIG_HOME`. So does `committed_copies_…`.
  - No installer run happens in the worktree or the repository root: every test uses scratch repos.
  - Option B is absent.

## References
- [x] Every function I opened exists with the signature the code assumes: `has_drifted`, `sum_of`, `lay_down`, `prune_empty_dirs`, `wire_the_project`, `ignore_worktrees_and_env` and `SHIPPED_LINES`. `RECORDED[$dest]` is always set on the "modified" branch, because `has_drifted` returns true only when a sum is recorded, so `set -u` holds. `$state_dir` exists whenever `start_sums` runs, since `$checksums.next` already lives there.
- [x] Values: the file name `.claude/.polype-checksums` and the migration message match the story and the plan word for word. The sums line format `<crc> <size> <path>` is unchanged.

## Rules
- [x] `AGENTS.md` conventions are respected. Comments are in English, the doc is in French, and the test file is named after the story slug.
- [x] No accepted ADR is contradicted. ADR-0087 is followed, including the "identical to the shipped file" rule for a committed `.claude/` and the migration.

## Tests
- [x] Floor: `po-gate floor-guard s123-local-copy-checksums main` exits 0. Nothing was lowered.
- [x] Each of the four acceptance criteria has a test of the same name, plus `committed_copies_…` and the doc test. None of the six empty test shapes appear: every test runs the real `bin/polype` in scratch git repos, and the clones go through `file://`.
- [x] Budget: 6 new tests plus 1 assertion, within the `Test budget` of 25.
- [x] Bite. The worktree mutation's test run was refused by the auto-mode classifier. I reverted the edit at once, and `git diff --exit-code bin/polype` exited 0. I then ran the proof in a throwaway clone, `/tmp/tmp.KWHtDlKrq3/probe`, whose tree is the same `df43f0c…`. After each mutation I ran `git checkout -- bin/polype` there, and `git diff --exit-code` exited 0.
  - **The "equal to shipped" condition removed** (`bin/polype:472`): 1 test fails, `committed_copies_refreshed_by_a_pr_stay_intact`.
  - **Routing to the local file turned off** (`record_sum`, `:364`): 4 tests fail: `first_update_migrates`, `local_copies_have_local_sums`, `local_sums_file_stays_out_of_git` and `update_after_a_pr_refresh_replaces_stale_copies`.
  - **Read order in `load_checksums` swapped**, so `.polype/checksums` wins (`:353`): **0 failing tests**, across `local-copy-checksums`, `installer` and `install` (34 tests). See the major finding below.
- [x] No existing test is made useless by the story.

## Neighbours
- [x] Nothing else in `bin/`, `method/`, `tests/` or `evals/` reads `.polype/checksums`. I searched with grep: only the installer's own tests mention it. The global no-`.next`-leftover check at `tests/global-install.test.sh:154` is untouched. In project mode, `finish_sums` always moves or removes `.polype/local-checksums.next`.

## Lenses
Lenses run: none. The diff has no auth or route path, no migration, no lockfile or manifest, and no server-side code.
- [x] No lens findings.

## Findings
- major — `bin/polype:353` (`load_checksums`). The rule that the local sums are read last, and so win over `.claude/` lines in `.polype/checksums`, is covered by no test. Swapping the order fails 0 of 34 tests. The plan's pivot 2 asked for exactly this check, with an old-format `.polype/checksums`: "Compare against `update_after_a_pr_refresh_replaces_stale_copies` with an old-format `.polype/checksums`". The test that ran uses only new-format files, where the order makes no difference. This is a real case: a checkout already migrated pulls a `.polype/checksums` committed by a checkout still on the old installer. With the wrong order, the original bug would come back silently.
- minor — `docs/installation.md:211` (`## Les trois fichiers d'état`) and the header comment at `bin/polype:14` still say "three state files". A project now has a fourth, `.claude/.polype-checksums`, and ADR-0087 says "quatre fichiers". The new paragraph describes the file, but the heading and the count are stale. The test `installation_doc_names_the_local_sums` relies on that heading, so renaming it means updating the test too.
- minor — `docs/installation.md:250-256`. The research settled that `check` does not apply the "identical to shipped" rule. In a project that commits `.claude/`, `check` run after pulling a refresh and before `update` will list the refreshed copies as modified. The research's open question says "the doc says so", but the new text describes only `update`'s behaviour.
- minor — `tests/local-copy-checksums.test.sh` (`test_local_copies_have_local_sums`). The `init` case runs after `remove`, which has already deleted the local file. So the `finish_sums` branch that removes a stale local file when a project goes from `install` to `init` is never exercised.

## Not verified
- I did not run a real `polype update` on Polype's root, pecten or nautile. Those first updates perform the migration, and the record says so too. A person should run `polype check` then `polype update` on each project once this ships, and confirm that `.claude/.polype-checksums` appears, the `.claude/` lines leave `.polype/checksums`, and `.gitignore` gains the line only where git did not already ignore the file.
- I did not run a cross-version scenario where two checkouts of the same project run different installer versions (one before s123, one after) and commit `.polype/checksums` alternately. This is the case the major finding is about. A person should reproduce it in scratch repos, or the next cycle should add the missing test.
- I did not run the full suite myself. I relied on the `po-run` record (exit 0 on this exact code outside `docs/`). The bite runs covered `local-copy-checksums.test.sh`, `installer.test.sh` and `install.test.sh` only.
- I did not test a crash between the two `mv` calls of `finish_sums`, which would leave the two sums files out of step.
- There is no type check, E2E or build: the project has none (`Typecheck: —`, `E2E: —`, `Build: —`).
- The probe clone `/tmp/tmp.KWHtDlKrq3/probe` is left in the temp dir, back at its committed state.

Max severity: major
Ship allowed: yes

---

# Review — s123-local-copy-checksums

Diff reviewed: `git diff main...story/s123-local-copy-checksums`, read by a reviewer that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 41f32e0e87538b18c3f0719e81deebfd46cba92d

## When blocked
Not blocked. I took the tree again just before answering and got the same hash, `41f32e0e…`. The worktree was clean.

## Ownership
I listed the diff with `git diff --name-status main...story/s123-local-copy-checksums` and checked each path against the story's `Owns` line.
- [x] **Code paths:** `bin/polype`, `docs/installation.md`, `tests/installer.test.sh` and `tests/local-copy-checksums.test.sh` are all in `Owns`.
- [x] **Pipeline evidence:** the `docs/research/`, `docs/plans/`, `docs/verif/` and `docs/reviews/` files of s123 are the story's own evidence.
- [x] **ADR:** `docs/decisions/ADR-0087-…md` is newly added (status A) and the plan names it, so it is in scope.
- [x] **Other stories:** `git worktree list` shows only `main` and this worktree, so the diff touches no other running story's paths.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] **Verification record:** `po-gate verif-current s123-local-copy-checksums` exits 0 (`Verification mode: record`). The last run of `bash tests/run.sh` exited 0 on tree `84a2d92…`, and the gate confirms that matches the committed code outside `docs/`. I relied on that record and did not rerun the full suite.
- [x] **Checks the project does not have:** `Typecheck`, `E2E` and `Build` are all `—`.
- [x] **What the record says it does not prove:** no real install, update or remove ran on Polype, pecten or nautile, and no cross-version scenario with two real installer versions ran.
- [x] **QA:** not required. `QA stage: —` and `Surface: —`.

## Plan
- [x] **Tasks:** all seven are present in the diff. The fix commit `fca364c` handles the loop-0 findings:
  - the major (the `load_checksums` read order was untested) now has a new test, `test_local_sums_win_over_an_old_format_polype_checksums`;
  - "three state files" is gone from the `bin/polype` header comment and from the doc heading, and the doc test was renamed to match;
  - `check`'s behaviour in a project that commits `.claude/` is documented;
  - the `install`→`init` case now runs without going through `remove`.
- [x] **Reuse table respected:** the `.next`-then-`mv` pattern, the `grep -qxF || printf >>` gitignore idiom and `sum_of` are reused, and `copy_of_the_method` stays out of `lib.sh`.
- [x] **Run interdicts:**
  - The diff does not touch `method/`, `.claude/`, `.polype/`, `AGENTS.md`, `lib.sh`, `run.sh`, `install.test.sh` or `global-install.test.sh`.
  - Global mode sets `local_sums=""`.
  - `remove` leaves `.gitignore` alone.
  - Both tests that assert on `.gitignore` pin `XDG_CONFIG_HOME`.
  - Every installer run happens in a scratch repo.

## References
- [x] I opened `has_drifted`, `sum_of`, `lay_down`, `shipped_pairs`, `collect_shipped`, `prune_empty_dirs`, `wire_the_project`, `cmd_check`, `cmd_update` and `cmd_remove`. All exist and match how the diff uses them.
- [x] `lay_down` copies byte for byte (`cp`, then `chmod` only). So comparing `sum_of "$src"` with the copy is a sound test of "identical to the shipped file".
- [x] When `update` falls back to `install` (no manifest), the migration message is skipped.
- [x] **Values:** the file name `.claude/.polype-checksums`, the migration message and the `<crc> <size> <path>` line format all match the story and the plan.

## Rules
- [x] **Language:** comments are in English and the doc is in French.
- [x] **ADRs:** ADR-0087 is followed, and the diff contradicts no accepted ADR.
- [x] **Test count:** there are 7 new tests, one more than the plan's six. The extra one is the fix for the loop-0 major, and the total stays within `Test budget` 25.

## Tests
- [x] **Floor:** `po-gate floor-guard s123-local-copy-checksums main` exits 0, so no check was made easier to pass.
- [x] **Tests that prove nothing:** none of the six kinds is present. Every test runs the real `bin/polype` in scratch repos, and clones use `file://`.
- [x] **Bite:** I made each change below in the worktree, ran only `local-copy-checksums.test.sh`, then ran `git checkout -- bin/polype`. `git diff --exit-code bin/polype` exited 0 after each one.

| Mutation | Line in `bin/polype` | Tests failed (of 7) | Failing test |
| --- | --- | --- | --- |
| Read order of `load_checksums` swapped | `:353` | 1 | `local_sums_win_over_an_old_format_polype_checksums` ("the stale copy was not refreshed") |
| "Equal to shipped" condition removed | `:472` | 1 | `committed_copies_refreshed_by_a_pr_stay_intact` |
| `finish_sums` no longer deletes an old local file | `:382` | 1 | `local_copies_have_local_sums` ("init left local sums…") |

The loop-0 review had already shown that routing sums to the local file bites 4 tests.

## Neighbours
- [x] Nothing else in `method/`, `evals/`, `tests/lib.sh` or `tests/run.sh` reads `checksums`. `local-checksums.next` is always moved or deleted by `finish_sums` in project mode, so nothing is left behind in the committed `.polype/`.

## Lenses
Lenses run: none. The diff has no auth or route path, no migration, no lockfile or manifest, and no server-side code.

## Findings
- minor — `docs/installation.md`, the new paragraph in `## Les fichiers d'état` and the `remove <projet>` line. A few added lines run well past the roughly 100-column wrap the rest of the file uses. This is style only.

## Not verified
- **Real first updates.** I ran no real `polype update` on Polype's root, pecten or nautile, and those first updates are where the migration happens. After shipping, a person should run `polype check` then `polype update` on each project. They should confirm three things: `.claude/.polype-checksums` appears, the `.claude/` lines leave `.polype/checksums`, and `.gitignore` gains the line only where git did not already ignore the file.
- **Two real installer versions.** No scenario had two real installer versions committing alternately. The new test only simulates the old format by appending lines. The manual check above covers the realistic case.
- **Full suite.** I did not rerun it; I relied on the `po-run` record. My bite runs covered `local-copy-checksums.test.sh` only.
- **Crash inside `finish_sums`.** I did not test a crash between its two `mv` calls, which would leave the two sums files out of step.
- **`check` before `update`.** In a project that commits `.claude/`, `check` still reports copies refreshed by a pull as `modified:` until `update` runs. This is by design and now documented, and I did not exercise it.
- **Type check, E2E, build.** The project has none (`Typecheck: —`, `E2E: —`, `Build: —`).

Max severity: minor
Ship allowed: yes
