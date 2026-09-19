# Research — s17-design-system

## Structuring facts
- Killer SaaS has same-named files in the local sources read by `tests/overlap.test.sh:5`: `commands/ks-design-system.md`, `skills/design-doctrine/`, `templates/design-system.md` (and `design-screen.md`, `design-brief.md` for s18). The overlap check runs for real: write only from the French description C09 (`docs/parite-killer-saas.md:44`) and D03 (`:52`, for the doctrine), never from those sources.
- `po-help` must list every command: `tests/pilot.test.sh:38-46` fails as soon as `method/commands/po-design-system.md` exists without `/po-design-system` in `method/commands/po-help.md`. `po-help.md` is owned by s20 (`docs/stories.md:302`), but s12–s16 each added one line in « Mise en place » (`po-help.md:13-18`); same here, outside Owns.
- Nothing reads `docs/design-system.md` yet; s18 will (`docs/stories.md:280`, `design_fails_closed_without_system_or_source`). This story fixes that file's location and shape: produced by the command, committed on `Target branch` like `docs/architecture.md` (`method/AGENTS.md:64`, framing documents on the target branch).
- The criterion's "visual direction" is not a setting. `Design source` (`method/templates/agents-local.md:24`) says *who draws screens* (internal/external/—), not what they look like. The stop condition therefore rests on two facts found at run time: no system in the base, no direction from the user.
- Contrast needs arithmetic: the command must compute ratios (WCAG relative luminance), so it needs Bash; no measuring helper exists in `bin/` (only `ks-overlap`, `polype-dev-install`).

## Story
`/po-design-system` inventories tokens and components and measures contrasts once, so each screen is composed from a stable system. Criteria:
- `design_system_never_invents_an_identity` — no visual direction given and no system in the boilerplate → the command stops and asks for the source.
- `design_system_measures_contrast_once` — measures every text/surface pair in light and dark, fixes failing tokens, says it is the only stage that measures.
- `design_doctrine_covers_new_vs_derived_and_gaps` — skill `design-doctrine`: new screen (one artefact) vs derived screen (deltas, no mockup), never invent a component or token, gaps recorded, the repository is the source of truth, a mockup is never code.
- `design_system_template_has_tokens_components_patterns` — template holds tokens, component inventory, state patterns, do / don't.

## Current code
- `method/commands/`: no `po-design-system.md`. Closest model: `po-architect.md` (s16) — framing command, frontmatter `description` + `allowed-tools` list incl. `AskUserQuestion`; `Reads settings:` line; « Checks » (no `AGENTS.local.md` → "Run /po-setup first."; repository root on `Target branch`, never switch; rerun → amend); numbered steps; one grouped AskUserQuestion for approval; `git status --porcelain` env check; commit on `Target branch`; closing line "Next: …".
- `method/skills/`: six skills, each `SKILL.md` with frontmatter `name`, `description` (e.g. `codebase-analysis/SKILL.md:1-4`). No `design-doctrine`.
- `method/templates/`: no `design-system.md`. `architecture.md` has a « UI components » map row (`architecture.md:17`) — the design system's inventory starts from it when present.
- `docs/conception.md:16` "Design system + maquettes — contrastes mesurés une fois"; `:30` pipeline order Architecture → Design system; `:52` target stack Tailwind + shadcn/ui, light/dark themes; `:67` a boilerplate profile carries a UI inventory "for the design system".
- `method/commands/po-setup.md:33,38`: `Design source` asked at setup; left `—`, "every design command stops on it and asks for the source again".
- Parity C09 (`docs/parite-killer-saas.md:44`): consign, never invent; stop without a visual source; boilerplate component inventory; tokens, components, patterns, do/don't; **only phase that measures** (each text/surface pair, light and dark); forced-dark-mode trap. Status `à faire`.

## Attachment points
- New: `method/commands/po-design-system.md`, `method/skills/design-doctrine/SKILL.md`, `method/templates/design-system.md`, `tests/design-system.test.sh`.
- One line in `method/commands/po-help.md` « Mise en place », after `/po-architect` (forced by `pilot.test.sh:38`).
- Status cell of C09 (`docs/parite-killer-saas.md:44`). D03 (`:52`) belongs to s18; D10 to s20.
- Installer copies `method/commands`, `skills` (nested folders too), `templates` (`bin/polype-dev-install:44-47`, `tests/install.test.sh:18`): nothing to register.

## Verified interfaces
- `tests/lib.sh`: `contains FILE PHRASE` (fixed, case-sensitive), `require_file`, `needs_tool`/`lacks_tool` (read `allowed-tools:` list or `tools:` inline), `frontmatter`, `settings_read_by`, `fail`.
- `tests/architect.test.sh:8`: local `section_of FILE HEADING` awk idiom, to pin a clause to one section.
- `tests/structure.test.sh:26-35`: every command needs a `Reads settings:` line with only template settings. Available: `Target branch`, `Design source`, `Design skill`, `Design tool` (`agents-local.md:11,24-26`).
- Baseline on `story/s17-design-system` (from `m2-cadrage` 6f59d9d): `bash tests/run.sh` → 105 passed, 0 failed.

## Traps
- `tests/overlap.test.sh`: fresh prose only (see first fact). Avoid long stock phrases about WCAG copied from anywhere.
- `tests/pilot.test.sh:38`: help line.
- `tests/structure.test.sh`: `Reads settings:` line with template settings only.
- Method files in English; `po-help` in French.
- Framing command: works at the repository root on `Target branch`, commit with env-file check, like `po-architect.md` « Approval and commit ».
- Installed copies `.claude/`, `.polype/` not edited.
- No migration, no code outside `method/`, `tests/`, `docs/`.

## Open questions
- Which settings the command reads: `Target branch` surely; `Design source` only if the command uses it (e.g. note that screens drawn later follow it). Plan decides; do not create a setting for the "visual direction".
- What counts as "a system in the boilerplate": theme/token files (CSS variables, Tailwind config, theme module) or a UI components folder, plus the profile's UI inventory when a profile exists. Plan fixes the signal.
- How the ratio is computed: a short inline computation through Bash (python3 or node, whichever exists) vs. a script under `bin/`. A new `bin/` script is outside Owns — prefer inline, formula in the command.
- Thresholds: 4.5:1 body text, 3:1 large text and non-text UI (WCAG AA). State them; fixing a failing token = adjust lightness of the token, record the before/after in the template's contrast table.
- Forced dark mode trap (browser/OS forcing dark on a light-only site): where to put it — command (dark variants required for every token) and doctrine.
- Who preloads `design-doctrine`: s18's `/po-design` and s20's reviewer. Here, the command reads it; say so in the skill description.

## Complexity
3 → 3. Four new files of prose plus one test file; one outside-Owns help line; no code path, no migration.

## Split
Not needed.
