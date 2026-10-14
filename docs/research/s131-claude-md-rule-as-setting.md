# Research — s131-claude-md-rule-as-setting

[Story](../stories.md)

## Structuring facts
- **False assumption of the story: its `Owns` misses `tests/structure.test.sh`.** `test_settings_template_one_value_per_line` refuses any fenced line of the template whose name holds a dot (`grep -vE '^[A-Z][A-Za-z0-9 ]*:…'`, `tests/structure.test.sh:11`), so `Project CLAUDE.md: absorbed` fails it. The line must be fenced: `po-lint` only knows fenced settings (`bin/po-lint:93-96`) and `missing_settings` only names fenced ones (`bin/polype:293-307`). `po-bounds` reads `Owns` at the fork point (`method/hooks/po-bounds.sh:155-180`), so the implementer is refused that file until the story's `Owns` gains it on `Target branch` and the lane forks again from there.
- The whole CLAUDE.md policy sits in three places: `absorb_claude_md` (`bin/polype:338-369`) called unconditionally by `wire_the_project` (`bin/polype:430-441`); `claude_md_check` (`method/hooks/po-gate.sh:259-271`) called by `pre_commit` (`po-gate.sh:286`); the flag loop of `waiting_for_a_human` (`method/hooks/po-session.sh:236-238`). None reads a setting today.
- `remove` already does what `kept_keeps_and_imports` asks of it: `drop_legacy_claude_md_import` (`bin/polype:325-333`) drops every `@AGENTS.md` line and the file when nothing else is left; it runs from `unwire_the_project` (`bin/polype:631-633`) whatever the setting.
- A missing setting is already named by `missing_settings` on `install`, `update` (`bin/polype:440`) and `check` (`bin/polype:627`), from the template's fenced lines: adding the template line gives `check` its message for free.
- Existing tests rely on absorption **without** the setting: their fixtures need `Project CLAUDE.md: absorbed` or a new expectation (`tests/no-claude-md.test.sh:26,40-44,50,92-99`, `tests/install.test.sh:57-66`).

## Story
Turn ADR-0086's "no project CLAUDE.md" into a per-project setting `Project CLAUDE.md`: `absorbed` (ADR-0086, written by `/po-setup` as default) or `kept`; a missing line changes nothing. Criteria: `setting_has_two_values`, `kept_keeps_and_imports`, `missing_setting_changes_nothing`, `adr_records_the_choice` (ADR-0089, reserved; ADR-0086 touched only in its frontmatter).

## Current code
- `absorb_claude_md` (`bin/polype:338-369`): for each regular root `CLAUDE.md`/`CLAUDE.local.md` (symlinks skipped, `:341`): import-only → deleted (`:343-345`), no `AGENTS.local.md` → left with a message (`:346-347`), else appended under `## Notes moved from CLAUDE.md` then deleted (`:352-368`). Writes aside then `mv` (`:362-363`).
- `wire_the_project` (`bin/polype:430-441`): `absorb_claude_md`, `absorb_agents_md`, `assemble_agents_md`, …, `missing_settings >&2`; global mode returns first (`:431`), so `~/.claude/CLAUDE.md` is never touched.
- Setting read in the installer: one inline `sed -n 's/^Worktree root:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*$/\1/p' … | head -n 1` (`bin/polype:272-275`); no shared helper.
- `claude_md_check` (`po-gate.sh:260-271`): lists staged non-deleted paths (`--diff-filter=d`, honours `DIFF_BASE`), refuses any basename `CLAUDE.md`/`CLAUDE.local.md` with `<path>: CLAUDE.md staged — …`. Header comment `po-gate.sh:12-15`. `top()` (`po-gate.sh:26`) gives the repo or worktree root.
- `po-session.sh`: `setting()` sed reader (`:25-27`), values read at `:29-34`; flag line text `"$name: Claude Code reads it instead of AGENTS.md → polype update . moves it into AGENTS.local.md"` (`:237`).
- Texts: `method/AGENTS.md:149` (the only-CLAUDE.md sentence + installer/pre-commit sentence), `po-setup.md:56` and `po-architect.md:72` (`Never commit a \`CLAUDE.md\` (ADR-0086).` + the same sentence), `po-setup.md:31` Step 2 heading, `:48` "Nothing else is asked beyond …".
- Template `method/templates/agents-local.md`: Pipeline block `:9-38`, values table `:40-69`; names padded so values start at column 20 (`Project CLAUDE.md:` is 18 chars, like `Ship confirmation:`).

## Attachment points
- `wire_the_project` (`bin/polype:432`): replace the bare `absorb_claude_md` call by a dispatch on the setting.
- `claude_md_check` (`po-gate.sh:260`): early `return 0` on `kept`.
- `waiting_for_a_human` flag loop (`po-session.sh:236-238`): message per value.
- Template Pipeline block after `Light up to` (`agents-local.md:37`) and a table row after `:69`; Polype's `AGENTS.local.md:35`.
- `po-setup.md` Step 2 (new follow-up beside `Ship confirmation`, `:40`), `:48`, Step 3 `:56`; `po-architect.md:14` (`Reads settings:`) and `:72`.

## Verified interfaces
- `missing_settings` prints `missing setting: <name>: <template value>`; returns nothing without `AGENTS.local.md` (`bin/polype:295`).
- `has_exact_line`, `throwaway_home`, `run_polype` helpers are local to `tests/no-claude-md.test.sh:9-22`; `scratch_repo`, `template_settings`, `settings_read_by`, `frontmatter`, `contains` in `tests/lib.sh`.
- `tests/leftovers.test.sh:19-26` and `tests/platform-setting.test.sh:115-121` run `polype check "$ROOT"` and fail on any `missing setting:` → Polype's `AGENTS.local.md` must carry the new line in the same commit as the template.
- Held wording: `tests/framing-commands-cleanup.test.sh:27` (exact Step 2 heading), `:42` (`Never commit a \`CLAUDE.md\` (ADR-0086).`), `tests/no-claude-md.test.sh:106-110` (the only-CLAUDE.md sentence in three files, `the pre-commit refuses one at any depth`), `tests/commands-and-texts.test.sh:31-35` (heading keeps `Platform`, `QA stage`, `catalogue`), `tests/setup-modes.test.sh:36` (`Nothing else is asked`), `tests/install-collisions.test.sh:235-240` (AGENTS.md and po-setup phrases about what the installer appends — must survive).
- ADR-0086 frontmatter `superseded-by: []`, `status: accepted`; its body below the frontmatter has `cksum` `1287032947 3025` today.

## Traps
- `tests/hooks-installer-docs-cleanup.test.sh:6-30` (not owned) stages a `CLAUDE.md` in a repo with no `AGENTS.local.md` and expects a refusal: the missing-setting branch must keep refusing.
- `tests/install.test.sh:57-66` (`test_install_drops_the_legacy_claude_md_import`) expects an import-only `CLAUDE.md` deleted with no `AGENTS.local.md`: that contradicts `missing_setting_changes_nothing`; the clause it checks changes, so the test changes.
- `tests/installer.test.sh:103-113,115-130` exercise `remove` with no `AGENTS.local.md`: unchanged behaviour, must stay green.
- `po-session.sh`'s `setting()` takes a BRE: the dot in `Project CLAUDE.md` matches any char, harmless; `po-gate` and `bin/polype` should escape it.
- `po-gate` runs inside story worktrees and under `GIT_INDEX_FILE` at the root (`po-setup.md` landing); it reads `$(top)/AGENTS.local.md` from the working tree, not the index.
- Root `AGENTS.md`, `.claude/`, `.polype/` are installed copies (AGENTS.local.md conventions): not refreshed by a story.
- `docs/installation.md` still says the installer absorbs any CLAUDE.md; it belongs to s132 (`tests/docs-and-eval-cleanup.test.sh:15-16` holds its wording).
- No migration; no new dependency.

## Open questions
- Should `kept` move an `@AGENTS.md` line found lower in the file to the top, or prepend a second one? (plan: one occurrence, at the top.)
- Symlinked root `CLAUDE.md` under `kept`: write through, replace, or leave? (plan: leave and say so, as `absorb_claude_md` skips symlinks.)
- Under `kept`, does `/po-setup` commit `CLAUDE.md`? (plan: only a root `CLAUDE.md` git already tracks.)
- A value other than `absorbed`/`kept` (`keep`): treated like a missing line (plan), not refused.

## Complexity
Story 3 → 3. Three small dispatches, one new installer function, texts and fixtures; the risk is in test fixtures that assumed unconditional absorption and in the `Owns` gap above.

## Split
—
