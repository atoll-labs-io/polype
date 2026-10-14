# Review — s131-claude-md-rule-as-setting

[Story](../stories.md) · [Plan](../plans/s131-claude-md-rule-as-setting.md) · [Research](../research/s131-claude-md-rule-as-setting.md) · [Record](../verif/s131-claude-md-rule-as-setting.md)

Reviewed tree: d50b8fb1990a43789d25b458993d3bc343b7482a
Fix loop: 0
Review status: complete
Lenses run: none (the diff touches a CLI installer, two shell hooks, method texts and tests: no auth or route paths, no migration, no lockfile or manifest, no server-side code)

## Summary
The story turns ADR-0086's "no project CLAUDE.md" rule into a per-project setting, `Project CLAUDE file`. It has two values. `absorbed` keeps the ADR-0086 rule. `kept` leaves both files in place, puts `@AGENTS.md` at the top of the root `CLAUDE.md`, and the pre-commit and `po-session` let the files through. With the line missing or set to any other value, nothing is touched and the setting is named.

The setting is read in three places:
- the installer, through `local_setting` and `handle_claude_md` in `/home/lecrabe/dev/atoll/polype/.worktrees/s131-claude-md-rule-as-setting/bin/polype`;
- the pre-commit, in `claude_md_check` of `method/hooks/po-gate.sh`;
- the `waiting_for_a_human` part of `method/hooks/po-session.sh`.

The texts, the template, Polype's own `AGENTS.local.md`, ADR-0089 and the ADR-0086 frontmatter are updated as well.

The diff matches the plan task by task. All the bite mutations were caught. One part of the code disagrees with ADR-0089 (finding 1).

## Scope (Owns)
Every changed path is either covered by the story's `Owns` or is the story's own evidence (`docs/research/`, `docs/plans/`, `docs/verif/`).
- ADR-0089 is listed in `Owns` (`docs/decisions/ADR-0089-*`), and the plan names it.
- ADR-0086 is listed in `Owns`. Its diff changes only the line `superseded-by: [ADR-0089]`, and the body checksum stays `1287032947 3025` (asserted by `test_adr_records_the_choice`).
- `git worktree list` shows only `main` and this story's worktree, so no other running lane shares a path. s132 shares `bin/polype` and `method/hooks/po-session.sh` but has no worktree yet.

## Evidence relied on
- `po-gate verif-current s131-claude-md-rule-as-setting` exited 0 (`Verification mode: record`). The record shows `bash tests/run.sh` exited 0 on code equal to `Tree:` outside `docs/`. I did not rerun the full suite.
- The project has no type check, end-to-end or build (`—` in AGENTS.local.md).
- The story's `Surface` is `command` and `QA stage` is `—`, so no QA is required.
- `po-gate floor-guard s131-claude-md-rule-as-setting main` exited 0: nothing in the diff makes the checks easier to pass.
- Run interdicts all hold:
  - Empty diff on root `AGENTS.md`, `.claude/`, `.polype/`, `docs/installation.md`, `README.md` and `tests/structure.test.sh`.
  - Empty diff on `tests/hooks-installer-docs-cleanup.test.sh` and `tests/installer.test.sh`, both still green.
  - The body of `drop_legacy_claude_md_import` is unchanged; only the comment above it changed.

## Bite proof
Each mutation was undone with `git checkout -- <file>`, and `git diff --exit-code` confirmed the file was restored.
1. `po-gate.sh`: removed the `[ "$keep" = kept ] && return 0` line. Ran claude-md-setting, no-claude-md and hooks-installer-docs-cleanup: 1 test failed (`kept_keeps_and_imports`).
2. `bin/polype` `handle_claude_md`: made the missing value absorb too (`absorbed|"")`). Ran claude-md-setting, no-claude-md, install and installer: 4 tests failed (`missing_setting_changes_nothing`, `install_creates_no_claude_md_and_spares_one_without_settings`, `install_drops_the_legacy_claude_md_import`, `installer_remove_restores_a_hand_written_agents_md`).
3. `bin/polype` `keep_claude_md`: kept the lower `@AGENTS.md` lines (`cat` in place of `grep -vx`). Ran claude-md-setting: 1 test failed (`kept_keeps_and_imports`).
4. `po-session.sh`: made `kept` add a flag line. Ran claude-md-setting: 1 test failed (`kept_keeps_and_imports`).

The tests: 4 new ones plus fixture and wording edits to 3 existing test files, well within `Test budget: 25`. None of the six kinds of test that prove nothing was found: the tests go through the real `bin/polype`, `po-gate.sh pre-commit` and `po-session.sh` in throwaway repos with a throwaway HOME.

## Findings

1. **major** — `polype check` says nothing when the value is neither `absorbed` nor `kept`, but ADR-0089 says it must name the setting.
   - ADR-0089 `## Decision Outcome` says: « Ligne absente, ou valeur qui n'est ni `absorbed` ni `kept` : … `check`, l'installeur et `po-session` nomment le réglage ».
   - `missing_settings` (`bin/polype`, around lines 297-312) treats any `Name:` line as present, whatever its value.
   - Probe, in a temp repo with `Project CLAUDE file: keep` and a root `CLAUDE.md`:
     - the installer prints `CLAUDE.md left in place: Project CLAUDE file is not set to absorbed or kept…`;
     - `polype check` prints nothing about the setting (grep exit 1).
   - `test_missing_setting_changes_nothing` checks the `check` output only for the empty value, so the gap is untested.
   - The damage is contained: the installer and `po-session` do name the typo, and nothing is touched or absorbed silently.
   - Fix options: either `check` validates this setting's value, or ADR-0089 drops `check` from the typo clause, which would need a superseding ADR since ADR-0089 is accepted.

2. **minor** — The comment at `bin/polype:232` (`A hand-written AGENTS.md joins the settings as a CLAUDE.md does (ADR-0086, ADR-0088)`) now holds only under `absorbed`. The same goes for "absorbed the same way" in the `method/AGENTS.md` paragraph. Neither is wrong, but both read as if absorption were unconditional.

3. **minor** — The new Pipeline line `Project CLAUDE file: absorbed` puts its value at column 22, while every other value starts at column 20. The plan announced this, and it is cosmetic.

## Not verified
- **No real Claude Code session was started** to confirm that a kept `CLAUDE.md` starting with `@AGENTS.md` makes Claude Code load the rules (the verification record says the same). To cover it, a person opens a session in a `kept` project and checks that the Polype rules are in context.
- **The symlinked root `CLAUDE.md` branch of `keep_claude_md`** (it leaves the link and prints a message) was read, not run, and no test covers it. To cover it, run `polype update` with `CLAUDE.md` as a symlink under `kept`.
- **A CRLF or BOM `CLAUDE.md` under `kept`** was not tried. The `@AGENTS.md\r` line would not match `grep -vx`, so a second, non-exact import line could stay. To cover it, try one CRLF file.
- **The pre-commit during `/po-setup`'s landing under `GIT_INDEX_FILE` at the repository root** was not exercised: it reads `$(top)/AGENTS.local.md` from the working tree. I judged it from the code only.
- **Effect on pecten and nautile** after their next `update` (they stop absorbing until they write the line): ADR-0089 states it, but it was not checked in those repositories.
- **The `/po-setup` AskUserQuestion follow-up** was read as text only. No interactive setup was run.
- There is no QA report (`QA stage: —`), so there is no `## Not seen` to carry over.

Max severity: major
Ship allowed: yes

---

# Review — s131-claude-md-rule-as-setting

[Story](../stories.md) · [Plan](../plans/s131-claude-md-rule-as-setting.md) · [Research](../research/s131-claude-md-rule-as-setting.md) · [Record](../verif/s131-claude-md-rule-as-setting.md)

Reviewed tree: 4857e2143d5bb44c657b36046888049472afca00
Fix loop: 1
Review status: complete
Lenses run: none (the fix touches a CLI installer, method text and a bash test. There is no auth, route, migration, lockfile or server-side path, and none of the trigger content appears.)

## Summary
This loop checks fix commit `fb9de79` against the three findings of loop 0.
- **Finding 1 (major) is closed.** `missing_settings` in `/home/lecrabe/dev/atoll/polype/.worktrees/s131-claude-md-rule-as-setting/bin/polype` (about lines 298-322) now records the first `Project CLAUDE file` value. If that value is neither `absorbed` nor `kept`, `polype check` prints `invalid setting: Project CLAUDE file: <value> (set it to absorbed or kept)`, as ADR-0089 requires. `test_missing_setting_changes_nothing` now checks that line for the `keep` typo. `test_kept_keeps_and_imports` checks that `check` says nothing for `kept`.
- **Finding 2 (minor) is closed.** The comment at `bin/polype:232` and the `method/AGENTS.md` paragraph now say a hand-written `AGENTS.md` is absorbed whatever the setting says, while a `CLAUDE.md` is absorbed only under `absorbed`.
- **Finding 3 (minor, value at column 22) was left on purpose**, as the lead allowed. It is carried below.
- **One loop-0 "Not verified" item is now covered.** `keep_claude_md` treats a CRLF `@AGENTS.md\r` line as the import, and a new CRLF case in `test_kept_keeps_and_imports` covers it.

Nothing else in the code changed.

## Scope (Owns)
- The fix commit changes `bin/polype`, `method/AGENTS.md`, `tests/claude-md-setting.test.sh`, `docs/verif/<id>.md` and `docs/reviews/<id>.md`.
  - The first three are listed in the story's `Owns` line (`docs/stories.md`, around line 2040).
  - The last two are the story's own evidence.
- The scope of the whole diff is unchanged from loop 0.
- `git worktree list` shows only `main` and this worktree, so no other running lane is involved.

## Evidence relied on
- `po-gate verif-current s131-claude-md-rule-as-setting` exited 0 (`Verification mode: record`). The last `Unit suite` row ran `bash tests/run.sh`, exited 0, and was taken on tree `8ab5066…` (11:33:35Z), whose code outside `docs/` matches the commit. I did not rerun the full suite.
- The project has no type check, no end-to-end run and no build (`—` in AGENTS.local.md).
- `Surface` is `command` and `QA stage` is `—`, so no QA is required.
- `po-gate floor-guard s131-claude-md-rule-as-setting main` exited 0: nothing in the diff makes the checks easier to pass.

## Bite proof
Each mutation was undone with `git checkout -- bin/polype`, and `git diff --exit-code` confirmed the file was clean.
1. **The new `check` rule.** I replaced the `invalid setting` print with `print ""` and ran `claude-md-setting.test.sh`. 1 test failed (`missing_setting_changes_nothing`). I ran this mutation twice, with the same result.
2. **The CRLF import match.** I set `import='@AGENTS\.md'`, dropping the optional `\r`, and ran `claude-md-setting.test.sh`. 1 test failed (`kept_keeps_and_imports`, on the CRLF case: the `od -c` output showed a second `@AGENTS.md\r` line left in the file).

The fix adds assertions to existing tests and no new test function, so the story stays well inside `Test budget: 25`. None of the six kinds of test that prove nothing appears: the new assertions run the real `bin/polype check` and `install` on throwaway projects.

## Findings

1. **minor** — `keep_claude_md` builds its pattern as `$'@AGENTS\\.md\r\\?'`, and `grep -x` then reads it as a basic regular expression. In a basic regular expression, `\?` is a GNU extension, so BSD/macOS grep may not treat the `\r` as optional. The pattern is at `bin/polype:395`, and it is the only use of `\?` in `bin/` and `method/hooks/`. Also, a CRLF file comes out with mixed line endings: the new first line `@AGENTS.md` ends in LF, the rest keep CRLF (the test asserts exactly that). This is harmless on Linux, which is where it was tested.
2. **minor** — The `Project CLAUDE file: absorbed` value starts at column 22, while the other Pipeline values start at column 20. This is carried from loop 0 and was left on purpose, because realigning would touch other setting lines.

## Not verified
- **No real Claude Code session was started** to confirm that a kept `CLAUDE.md` starting with `@AGENTS.md` loads the rules. To cover it, a person opens a session in a `kept` project and checks that the Polype rules are in context.
- **A symlinked root `CLAUDE.md` under `kept`** was read, not run, and no test covers it. To cover it, run `polype update` with `CLAUDE.md` as a symlink.
- **A `CLAUDE.md` starting with a BOM under `kept`** was not tried. The first line would not equal `@AGENTS.md`, so a second import line could be added. To cover it, run `install` on a BOM file.
- **The CRLF and `\?` behaviour on BSD/macOS grep** was not tried. To cover it, run `test_kept_keeps_and_imports` on macOS.
- **The pre-commit during `/po-setup`'s landing under `GIT_INDEX_FILE`** was judged from the code only.
- **The effect on pecten and nautile** after their next `update` (they stop absorbing until they write the line) was not checked in those repositories.
- **The `/po-setup` follow-up question** was read as text only; no interactive setup was run.
- There is no QA report (`QA stage: —`), so there is no `## Not seen` list to carry over.

Max severity: minor
Ship allowed: yes
