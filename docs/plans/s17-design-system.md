---
validated: yes
---
# Plan — s17-design-system

[Story](../stories.md) · [Research](../research/s17-design-system.md)

Branch `story/s17-design-system`. Read `docs/research/s17-design-system.md` first; this plan builds on it without repeating it.

## Story
`/po-design-system` records the project's design system once: it finds the visual source (a system already in the base, or a direction the user gives), inventories tokens and components, measures every text/surface contrast in light and dark and fixes failing tokens, then commits `docs/design-system.md` on `Target branch`. It never invents an identity. The `design-doctrine` skill holds the rules every later design step follows. Criteria (each the name of one test in `tests/design-system.test.sh`): `design_system_never_invents_an_identity`, `design_system_measures_contrast_once`, `design_doctrine_covers_new_vs_derived_and_gaps`, `design_system_template_has_tokens_components_patterns`.

## Decisions

| Question | Decision | Why |
| --- | --- | --- |
| Output | `docs/design-system.md` from `templates/design-system.md`, committed on `Target branch` at the repository root, like `docs/architecture.md` | Framing document; s18 reads it at that path |
| "A system in the base" | Theme or token files (CSS custom properties, a Tailwind theme, a theme module), a folder of UI components, the « UI components » row of `docs/architecture.md`, or a profile's UI inventory when one is reachable | Concrete signal; research open question 2 |
| "A visual direction" | Something the user supplies: brand guide, logo and palette, an existing product or site to follow, mockups from the design tool. Not a setting | `Design source` says who draws, not what it looks like (research fact 4) |
| Neither found | One AskUserQuestion asking for the source; with no source given the command ends without writing anything | Criterion 1; never invent an identity |
| Settings read | `Target branch` only | Nothing else steers this command; no new setting |
| Contrast method | WCAG 2 relative luminance and ratio, formula written in the command, computed through Bash with whichever of `python3` or `node` exists (neither → stop and say so). Colours in other notations are converted to sRGB first. Thresholds: 4.5:1 text, 3:1 large text and non-text UI (borders, focus rings, icons) | Arithmetic cannot be eyeballed; no `bin/` helper (outside Owns) |
| Which pairs | Every text token on every surface token the system actually puts it on, in light and in dark | Criterion 2 |
| Failing token | Change its lightness as little as possible, keep its hue, measure again; record before → after in the contrast table. The command edits no source file: the corrected values are handed to the person, who applies them as a quick fix they name or through a story | Law 1 and Law 5 (colours are quick-fix material, but only a person names a quick fix) |
| Measuring once | Exact sentence `This is the only stage that measures.` — later design and review stages look at the result and trust these numbers | Criterion 2; C09 |
| Forced dark mode | Every colour token needs a dark value; a light-only system is recorded as a gap, because browsers and systems that force dark mode will recolour it unpredictably | C09 trap |
| Doctrine skill | `method/skills/design-doctrine/SKILL.md`; read by this command now, preloaded by `/po-design` (s18) and the reviewer (s20) later | Criterion 3 |
| Checkpoints | One grouped AskUserQuestion showing the drafted `docs/design-system.md` (tokens, contrast results and fixes, gaps) before anything is written | Decisions belong to a person |
| Rerun | `docs/design-system.md` exists → amend it, measure the changed pairs again | Same pattern as `/po-architect` |
| Tools | Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion | Writes one doc, measures, commits; no source file |
| Lines outside Owns | One French line in `po-help.md` after `/po-architect`; C09 status cell | `pilot.test.sh:38`; conventions |

## Tasks
1. [x] `method/templates/design-system.md` — `# Design system — <project>`, one intro line (written by `/po-design-system`, amend through it). Sections in order: `## Sources` (visual direction, base system with paths, profile or "none"); `## Tokens` table `| Token | Role | Light | Dark | Defined at |`; `## Contrast` table `| Text | Surface | Theme | Ratio | Needed | Result | Fix |`; `## Components` inventory table `| Component | Path | Variants | States |`; `## State patterns` (empty, loading, error, success, disabled, focus — how each looks, which components); `## Do / Don't` (two lists); `## Gaps` (what the system lacks, recorded for a person, never filled by invention). — Test: `design_system_template_has_tokens_components_patterns`.
2. [x] `method/skills/design-doctrine/SKILL.md` — frontmatter `name: design-doctrine`, `description` (the rules of every design step: sources, new vs derived screens, gaps, what a mockup is; read by `/po-design-system`, preloaded by later design and review steps). Sections, each with its exact phrase:
   - repository: `The repository is the source of truth.` — design tool, mockups and chat never override what is committed.
   - screens: `A derived screen` is built from patterns the system already has → a design note listing the `deltas` only, `no mockup`; `A new screen` has a layout the system lacks → the note plus `exactly one artefact`.
   - invention: `Never invent a component or a token.` Use what the inventory lists.
   - gaps: `record the gap` in the `## Gaps` of `docs/design-system.md` (or the screen's note) and leave the decision to a person.
   - mockup: `A mockup is a reference, never code:` it is not copied into source files.
   - measuring: contrast is measured once, by `/po-design-system`; later steps look, they do not measure.
   — Test: `design_doctrine_covers_new_vs_derived_and_gaps`.
3. [x] `method/commands/po-design-system.md` — frontmatter `description`, `allowed-tools` as decided. `# /po-design-system`, `Reads settings: \`Target branch\``. Sections in order:
   - `## Checks`: no `AGENTS.local.md` → "Run /po-setup first."; repository root on `Target branch`, else stop, never switch; `docs/design-system.md` exists → rerun, amend. Read the `design-doctrine` skill.
   - `## Step 1 — The source`: detection of a system in the base (decision row); ask whether the user has a visual direction; exact sentence `This command never invents an identity:` followed by the exact phrase `with no visual direction and no system in the base, stop and ask for the source` (one AskUserQuestion); without a source the command ends having written nothing.
   - `## Step 2 — Inventory`: apply `codebase-analysis` to the UI layer; list every token (light and dark values, `path:line`) and every component (variants, states); what is missing goes to Gaps.
   - `## Step 3 — Measure contrast`: exact sentence `This is the only stage that measures.`; `every text/surface pair, in light and in dark`; formula; thresholds; tool through Bash; exact phrase `fix the failing tokens` with the lightness rule; no source file edited, corrected values handed to the person; forced dark mode trap.
   - `## Step 4 — Patterns and rules`: state patterns and do / don't drawn from the inventory, never from taste.
   - `## Approval and commit`: grouped AskUserQuestion; `git status --porcelain` lists an environment file → stop; commit `docs/design-system.md` on `Target branch` as `docs: design system`.
   - Finish line: "Design system recorded. Next: /po-research <first story id>".
   — Tests: `design_system_never_invents_an_identity`, `design_system_measures_contrast_once`.
4. [x] `method/commands/po-help.md`: after `/po-architect`, `` - `/po-design-system` — recense tokens et composants du socle, mesure une fois les contrastes en clair et en sombre ; écrit `docs/design-system.md`. `` — Test: existing `every_command_listed_in_help`.
5. [x] `tests/design-system.test.sh`, header `# s17 — design system command, design-doctrine skill and template.`, local `section_of` (copy of `tests/architect.test.sh:8`):
   - `test_design_system_never_invents_an_identity`: `needs_tool` AskUserQuestion; `This command never invents an identity:`; the phrase `with no visual direction and no system in the base, stop and ask for the source` inside `## Step 1 — The source`.
   - `test_design_system_measures_contrast_once`: `needs_tool` Bash; `This is the only stage that measures.`; `every text/surface pair, in light and in dark`; `fix the failing tokens`; these three inside `## Step 3 — Measure contrast`.
   - `test_design_doctrine_covers_new_vs_derived_and_gaps`: skill exists, frontmatter `name: design-doctrine`; the phrases of task 2.
   - `test_design_system_template_has_tokens_components_patterns`: headings `## Tokens`, `## Components`, `## State patterns`, `## Do / Don't`; `## Contrast` table header has `Light`/`Dark` via `| Theme |`.
6. [x] `docs/parite-killer-saas.md`: C09 → `fait — \`method/commands/po-design-system.md\`, \`method/skills/design-doctrine/\`, \`method/templates/design-system.md\``. No other line.
7. [x] Full suite `bash tests/run.sh` (`Full suite: execute-end`); record in `docs/verif/s17-design-system.md`.

## Run interdicts
- Empty diff for `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `docs/stories.md`, `docs/decisions/`, `bin/`, `tests/lib.sh`, every existing test, `method/AGENTS.md`, `method/agents/`, every existing `method/templates/` and `method/skills/` file, and every existing `method/commands/` file except the one line of `po-help.md`.
- `docs/parite-killer-saas.md`: only the C09 line changes.
- No new setting in `method/templates/agents-local.md`.
- No `method/commands/po-design.md` or design-screen/brief templates (s18).
- The new files do not mention `docs/references/`, `~/dev/vault`, `/spec` or Polype's own ADR numbers.
- No sentence from Killer SaaS (`tests/overlap.test.sh` green with its sources present); never open `ks-design-system.md`, Killer SaaS's `design-doctrine` or `templates/design-system.md`.

## The pivot
The command records and measures; it never writes the product's code — corrected token values go to a person. Ways it could be wrong: (a) "corrige les tokens en échec" read as editing the theme files — compare with Law 1/Law 5 and check the command leaves the doc and the code consistent by saying explicitly the code still carries the old values until applied; (b) the "no direction" stop fires on a repository that does have tokens — check the detection list; (c) contrast formula or thresholds wrong — compare with WCAG 2 (sRGB linearisation at 0.04045, weights 0.2126/0.7152/0.0722, ratio (L1+0.05)/(L2+0.05)).

## Files touched
New: `method/commands/po-design-system.md`, `method/skills/design-doctrine/SKILL.md`, `method/templates/design-system.md`, `tests/design-system.test.sh`. Edited: one line of `method/commands/po-help.md`, the C09 line of `docs/parite-killer-saas.md`. Plus `docs/research/`, `docs/plans/`, `docs/verif/` for this story.

## Test strategy
Four structural tests in `tests/design-system.test.sh`, one per criterion (budget 25). Each quotes the clause it guards, so deleting it fails the test. Existing `every_command_listed_in_help`, `every_setting_read_by_a_command_exists_in_template`, the install tests and `method_does_not_reuse_killer_saas_text` cover the rest. No visual checks: the story ships prose, no screen.

## Done when
Full suite green, one commit `s17-design-system: …` on `story/s17-design-system` holding code, tests and docs, verification record complete, review with no open critical finding.
