# Research — s12-prd-kill

## Structuring facts
- **False assumption**: criterion `prd_challenges_the_angle_in_adapt_mode` says the probes are "tirées de `docs/references/spec-interrogation.md`". That file exists only in this repository (`docs/references/spec-interrogation.md:25-29`); the installer copies `method/` only (`bin/polype-dev-install:47`), so in a target project the path does not exist. The probes must be written into `po-prd.md` itself (adapted, in our own words), not read from that path at run time.
- `/po-brief` does not exist yet (s13, `docs/stories.md:190`): `po-prd` can name it as the redirect for `new`, but nothing tests it exists.
- `Entry mode` exists in the template with values `replace` · `adapt` · `new` · `—` (`method/templates/agents-local.md:23,46`); a `—` value must stop the command, per the settings rule (`method/AGENTS.md`, "Reading settings").
- The complexity scale lives in `method/templates/stories.md:5`; C03 is already `fait — method/templates/stories.md` (`docs/parite-killer-saas.md:38`). The PRD template must reuse that scale, not define a second one.
- ADR-0006 applies with full force: Killer SaaS has its own `ks-prd` command and `prd.md` template; `tests/overlap.test.sh` fails on 8+ shared words, and the sources are present locally, so the check really runs.

## Story
`/po-prd <SaaS cible>` interrogates the user one question at a time on target, mode, core loop and graveyard, so the scope copies only the 20 % that matters. Output `docs/prd.md`, committed on `Target branch`.
- `prd_reads_entry_mode_and_refuses_new` — reads `Entry mode`; `new` → stop, point to `/po-brief`.
- `prd_asks_one_question_at_a_time` — one question per message; nothing written that the user has not validated.
- `prd_template_has_core_loop_graveyard_and_angle` — template: target, mode, core loop (table with complexity 1–5 and justification), explicit graveyard, angle, measurable success criteria.
- `prd_challenges_the_angle_in_adapt_mode` — `adapt`: the angle goes through challenge probes (evidence of pain, exact consumer, success signal).
- `prd_scores_heavy_features_toward_the_graveyard` — a feature scored 4 or 5 justifies its place, otherwise it goes to the graveyard.
Notes: `replace` = internal replacement (stop paying, keep the data); `adapt` = competing product with its own angle.

## Current code
- `method/commands/`: nine `po-*.md`, no `po-prd.md`. Shape to follow: frontmatter `description`, `argument-hint`, `allowed-tools` YAML list; body `# /po-x`, `Reads settings:` line, sections (`method/commands/po-setup.md:1-15`, `po-research.md:1-14`).
- `method/templates/`: seven templates, no `prd.md`; installed wholesale under `.polype/templates/` (`bin/polype-dev-install:47`).
- `docs/parite-killer-saas.md:37` C02 `à faire`, describes: target, mode, why, core loop 20 %, exhaustive graveyard, angle beyond parity, then need, users, constraints, measurable success criteria; nothing written without validation. Polype extension: `adapt` angle goes through a targeted interrogation.
- `docs/conception.md:37-38`: replace = parity on the core loop, assumed graveyard; adapt = kill PRD in competing mode, angle written as stories and challenged like a new idea.

## Attachment points
- New files: `method/commands/po-prd.md`, `method/templates/prd.md`, `tests/prd.test.sh`.
- Matrix: status cells of C02 and C03 in `docs/parite-killer-saas.md`.
- Not owned, left alone: `method/commands/po-help.md` (cheat sheet, would list `/po-prd`), `method/AGENTS.md` (Law 1 table), `.claude/`, `.polype/`.

## Verified interfaces
- `contains FILE PHRASE` (`tests/lib.sh:43`) exact, case-sensitive; `require_file` (`:41`); `needs_tool`/`lacks_tool` (`:28-29`) on `allowed-tools`; `settings_read_by` (`:37`); `template_settings` (`:32`).
- `tests/structure.test.sh:24-34` iterates every `method/commands/*.md`: the new command needs a `Reads settings:` line whose settings all exist in the template (`Entry mode`, `Target branch` do).
- Runner: `bash tests/run.sh prd.test.sh`.

## Traps
- `tests/overlap.test.sh` scans all of `method/`; write from the French matrix line, never from Killer SaaS memory. Watch generic phrases like "one question at a time" chains that could match.
- The command writes `docs/prd.md` and commits it: it needs `Write` and `Bash` (like `po-setup`), and `AskUserQuestion` for the mode confirmation. It must not have `Edit` on source — convention: commands that do not write code; it writes a doc only.
- Committing on `Target branch`: the command must check the current branch is `Target branch` before committing, and check `git status --porcelain` for env files (Law 6).
- `—` for `Entry mode` → stop and point to `/po-setup` or editing `AGENTS.local.md`; no guessing from the argument.
- Mode mismatch: the argument names a target, the mode comes from the setting only.
- `tests/pilot.test.sh:38-46` (`every_command_listed_in_help`) fails for any `method/commands/po-*.md` not named in `po-help.md` — missed by the first research pass, found by the first execute run.
- No migration, no executable code; tests are text-level.

## Open questions
- Whether the PRD persists `status: interviewing` between sessions (s13 does it for the brief; not required here) — plan decides; cheap and consistent.
- Whether the angle section exists in `replace` mode (C02 says "angle beyond parity" for both) — plan decides.
- How to test "one question per message" without duplicating wording: quote the command's own rule sentence.

## Complexity
Story 3 → 3. Two markdown method files and a test file; business logic is the interview flow with two modes and a scoring rule.

## Split
Not needed.
