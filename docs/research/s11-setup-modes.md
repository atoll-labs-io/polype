# Research — s11-setup-modes

[Story](../stories.md)

## Structuring facts
- No false assumption: `po-setup` does ask exactly three questions today (`method/commands/po-setup.md:29-34`) and the template has none of the six framing settings (`method/templates/agents-local.md:9-50`).
- The frontmatter `description` also says "three answers" (`method/commands/po-setup.md:2`): it must follow the count, or the command contradicts itself.
- `tests/structure.test.sh:8-13` rejects any fenced template line not matching `Name: value` with no `#`: every new default needs a real value, `—` included.
- `tests/structure.test.sh:24-34` requires every setting a command reads to exist in the template — adding them now unblocks s12, s13, s18, s19, which will read them.
- This repository's own `AGENTS.local.md` lacks the new settings; it is not owned by this story and lives on `Target branch`.

## Story
`/po-setup` must also ask the entry point (replace / adapt / new) and who draws the screens, so framing follows the right path and the design source is never picked silently.
- `settings_template_declares_framing_settings` — template declares `Entry mode` (`replace`·`adapt`·`new`), `Design source` (`internal`·`external`), `Design skill`, `Design tool`, `Story track` (`full`·`flow`·`auto`), `Flow threshold`, each in the values table.
- `setup_asks_entry_mode_and_design_source` — five questions in total: the three current ones plus entry point and design source, no more.
- `setup_never_defaults_design_silently` — the command says a design source left at `—` makes design commands stop and ask again.
Notes: keep never-overwrite, look-before-asking, grouped commit; `Story track` defaults to `auto`, `Flow threshold` to `2`; M1 tests of `tests/structure.test.sh` stay green.

## Current code
- `method/commands/po-setup.md` (42 lines): refuses to touch an existing `AGENTS.local.md` (:17), step 1 reads the repo (:21-27), step 2 three AskUserQuestion calls (:29-34, "Nothing else is asked" :34), step 3 copies the template, `.gitignore`, installer, commit `chore: set up polype` (:36-40). `Reads settings: none` (:13).
- `method/templates/agents-local.md` (56 lines): `## Pipeline` fenced block (:9-23), values table (:25-39), `## Commands` block (:43-50), conventions placeholder (:56).
- `docs/parite-killer-saas.md:28` (B02) and `:36` (C01): both `partiel`, both naming the design/short-track/entry-mode settings as M2 work.

## Attachment points
- New settings: a fenced block in `agents-local.md` — either inside `## Pipeline` or a new `## Framing` section with its own fence and table. `template_settings` (`tests/lib.sh:32-34`) reads every fence, so both work.
- New questions: `po-setup.md` step 2 list and its "Nothing else is asked" sentence; step 3.1 ("fill in the answers") already covers writing them.

## Verified interfaces
- `template_settings` — `tests/lib.sh:32`, prints the part before `:` of each non-empty fenced line.
- `contains FILE PHRASE` — `tests/lib.sh:43`, fixed-string, case-sensitive.
- `require_file` — `tests/lib.sh:41`.
- Runner: `bash tests/run.sh setup-modes.test.sh` (`tests/run.sh:5-6`), each `test_*` in its own process with `set -eu`.
- `tests/overlap.test.sh` + `bin/ks-overlap`: any 8+ consecutive words shared with Killer SaaS fails.

## Traps
- `tests/structure.test.sh:36-44` quotes exact phrases of `po-setup.md` (`If \`AGENTS.local.md\` is already there, do not touch it.`, `lists the \`Worktree root\` folder and \`.env*\``, `` `.claude/` and `.polype/` together``): keep them verbatim.
- `test_settings_template_one_value_per_line`: a value like `replace` is fine; no inline `#` or trailing comment.
- AskUserQuestion takes at most four options per question; the entry mode has three, design source two (plus `—`?), so each fits one call.
- Setting names with spaces (`Entry mode`) are matched by `grep -qx` against `template_settings` output — exact case.
- Matrix lines B02 and C01 stay `partiel`: fleet/profile/boilerplate settings remain for M3/M4.
- No migration, no code outside `method/` and `tests/`.

## Open questions
- Template default for `Entry mode` and `Design source`: `—` (setup always asks, design commands then stop) seems required by the third criterion; the plan decides and says so.
- Where `Design skill` / `Design tool` are asked: as part of the design-source question (skill for `internal`, tool for `external`) to keep five questions — plan decides.
- Section placement: a separate `## Framing` block vs extending `## Pipeline`.

## Complexity
Story 2 → 2. Two markdown files and one test file; no executable code.

## Split
Not needed.
