# Review — s45-clean-uninstall

[Story](../stories.md) · [Plan](../plans/s45-clean-uninstall.md) · [Verification](../verif/s45-clean-uninstall.md)

Diff reviewed: `git diff m4-catalogue...story/s45-clean-uninstall` (one commit, 3c5d5b7), by a reviewer that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## Ownership
I listed the diff's paths with `git diff --name-only m4-catalogue...story/s45-clean-uninstall`. The story's `Owns` line is `bin/polype`, `tests/installer.test.sh`, `docs/defauts.md` (docs/stories.md:674).
- [x] Every path is inside `Owns`: `bin/polype`, `tests/installer.test.sh`, `docs/defauts.md`. The other two, `docs/plans/s45-clean-uninstall.md` and `docs/verif/s45-clean-uninstall.md`, are the story's own evidence.
- [x] Nothing is outside `Owns`.
- [x] No path belongs to another running story. `git worktree list` shows only main, m4-catalogue and this worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s45-clean-uninstall` exits 0. `git diff --quiet 84202168… HEAD -- . ':(exclude)docs'` also exits 0. The record is complete and every exit code is 0: focused run 12/12, full suite 210/210. With `Verification mode: record` I reused it and did not rerun the suite. The project has no type check, E2E or build command (all `—` in AGENTS.local.md), so none ran. I read the record's "Not proven here" section: global mode is not exercised, and the text at docs/installation.md:173 is left for later.

## Plan
- [x] Task 1: the deletion branch is in `unwire_the_project` (bin/polype:365-369). Neither branch leaves a temp file.
- [x] Tasks 2 and 3: the two tests are added. Their names match the acceptance criteria with the `test_` prefix.
- [x] Task 4: defect 31 in docs/defauts.md is now marked `corrigé par s45`.
- [x] Nothing outside the plan.
- [x] Run interdicts, one by one:
  - `docs/installation.md`, `method/`, `.claude/`, `.polype/` all have an empty diff.
  - Only the allowed files changed.
  - `cmd_remove` still runs in the same order (prune, then unwire). The global early return and `.gitignore` handling are unchanged.
  - No existing test was modified.

## References
- [x] Opened and confirmed:
  - `assemble_agents_md` creates `CLAUDE.md` with `touch` and appends `@AGENTS.md` (bin/polype:178-179).
  - `ignore_worktrees_and_env` always writes two lines to `.gitignore` (bin/polype:188-191).
  - `unwire_the_project` has one caller, `cmd_remove` (bin/polype:394).
  - The test helpers `project`, `polype`, `require_file` and `scratch_repo` (tests/lib.sh:46) exist as used.
  - The plan's "Verified facts" line numbers match the code.
- [x] Check on values: `grep -q '[^[:space:]]'` counts a file as empty when it holds nothing or only whitespace. That matches "nothing but blank lines" in the plan.

## Rules
- [x] AGENTS.md conventions are followed: bash tests, one test function per criterion, English comments and commit message, no installed file edited.
- [x] No accepted ADR is contradicted.

## Tests
- [x] Assertions:
  - Criterion 1 checks both halves: the file is absent after remove; with user content, the content survives and the import line is gone.
  - Criterion 2 uses `find` for empty files and for `*.polype-next` files.
  - None of the six test shapes that prove nothing: the tests drive the real installer in a scratch repo, with no mocks and no catch that swallows errors.
- [x] 2 tests, within `Test budget` (25).
- [x] Bite. After each mutation I ran only `installer.test.sh`:
  1. Condition forced to `true` (the old behaviour: always rename) → 2 tests fail (`remove_deletes_a_claude_md_it_created`, `remove_leaves_no_empty_file_behind`) → undone, `git diff --exit-code bin/polype` clean.
  2. Else branch no longer removes `CLAUDE.md.polype-next` → 1 test fails (`remove_leaves_no_empty_file_behind`) → undone, clean.
  3. Condition forced to `false` (always delete) → 2 tests fail (`remove_deletes_a_claude_md_it_created` and the existing hand-written-CLAUDE.md test) → undone, `git diff --exit-code` clean over the whole tree.
- [x] No test became useless. The second half of `test_remove_deletes_a_claude_md_it_created` overlaps the existing `test_installer_remove_restores_a_hand_written_agents_md` (see minor finding).

## Neighbours
- [x] `cmd_remove` is the only caller and it is unaffected.
- [x] Global mode returns before the changed code.
- [x] `docs/installation.md:173` still says only that remove "retire la ligne `@AGENTS.md` de `CLAUDE.md`". It is now incomplete but not wrong, it is outside `Owns`, and the plan flags it.

## Findings
- minor — bin/polype:365-369 — The deletion is keyed on what is left in the file, not on whether the installer created it. If a user's `CLAUDE.md` was already empty or whitespace-only before install, `remove` now deletes it. It has no content, so the damage is negligible, but the story title says "it created" and the code does not track that.
- minor — tests/installer.test.sh:115-128 — The second half of `test_remove_deletes_a_claude_md_it_created` (user content is kept, the import is removed) repeats the assertions of `test_installer_remove_restores_a_hand_written_agents_md` (lines 107-113). The same rule is tested twice in the same layer.
- minor — docs/installation.md:173 — The remove description doesn't say that a `CLAUDE.md` left empty is deleted. The file is outside this story's `Owns`, so the fix is a later story or a quick fix.

## Not verified
- Global mode (`install --global` / `remove --global`): no test covers it for this change. Reading the code shows it returns before the changed block, but I did not run it. A person can run `bin/polype install --global` then `remove --global` on a throwaway HOME and confirm no project `CLAUDE.md` is touched.
- A `CLAUDE.md` that is a symlink, or has CRLF line endings: I did not exercise either. `grep -vx '@AGENTS.md'` won't match `@AGENTS.md\r`, but that was already true before this story. A person on a Windows-edited project could check it by hand.
- I did not rerun the full suite. I relied on the current record (210/210, tree 84202168…).
- There is no type check, E2E or build: the project has none (`—`).

Max severity: minor
Ship allowed: yes
