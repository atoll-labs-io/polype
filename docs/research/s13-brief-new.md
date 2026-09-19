# Research — s13-brief-new

## Structuring facts
- **False assumption (same as s12)**: the notes treat `docs/references/spec-interrogation.md` as the source. That file exists only in this repository; the installer copies `method/` alone (`bin/polype-dev-install:46`), so a target project never has it. The `interrogation` skill must carry the whole procedure itself, rewritten in English in our own words, with `docs/brief.md` replacing the vault path (`docs/references/spec-interrogation.md:83`).
- `po-help` lists every command: `tests/pilot.test.sh:38-46` fails when `method/commands/po-brief.md` exists without `/po-brief` in `method/commands/po-help.md`. That file is outside Owns; s12 hit the same wall and added one line (`docs/plans/s12-prd-kill.md:25`). s13 needs the same one-line exception.
- `Entry mode` exists with `replace` · `adapt` · `new` · `—` (`method/templates/agents-local.md:23,46`); `/po-prd` already redirects `new` to `/po-brief` (`method/commands/po-prd.md:19`). `/po-brief` must mirror it: `replace`/`adapt` → `/po-prd`, `—` → stop, never guess.
- The pre-mortem needs a fresh-context subagent: `po-brief` must carry `Agent` in `allowed-tools`, as `po-review` does (`method/commands/po-review.md:8`). The reference uses `subagent_type: Plan` (`spec-interrogation.md:62`), a Claude Code built-in, not a Polype agent; no Polype agent is owned by this story.
- Killer SaaS has no brief mechanism (C04 has `—` in its columns, `docs/parite-killer-saas.md:39`), and its sources are present locally, so `tests/overlap.test.sh` runs for real.

## Story
`/po-brief` challenges a new idea like a skeptical cofounder, so the project starts from a brief that survived objections. Criteria:
- `brief_runs_only_in_new_mode` — reads `Entry mode`; `replace`/`adapt` → points to `/po-prd`.
- `interrogation_skill_has_stance_forcing_questions_gap_map_premortem` — skill `interrogation` holds the skeptical stance, the seven forcing questions, the gap map with critical dimensions, the pre-mortem by a fresh-context subagent, at least three alternatives including the cheapest.
- `brief_persists_between_sessions` — brief written to `docs/brief.md` with `status: interviewing` after each theme; the command resumes where it stopped.
- `brief_has_exit_criteria` — `status: approved` only after exit criteria: one-liner, wedge, metric, three non-goals, critical dimensions handled, pre-mortem findings settled, user agreement.

## Current code
- `method/commands/`: ten `po-*.md`, no `po-brief.md`. Closest model: `po-prd.md` (frontmatter `description`, `argument-hint`, `allowed-tools`; `Reads settings: \`Entry mode\`, \`Target branch\``; Checks / Interview rules / Sequence / Finish; commits `docs/prd.md` alone on `Target branch` after checking `git status --porcelain`) (`method/commands/po-prd.md:1-55`).
- `method/skills/`: three skills, each `SKILL.md` with frontmatter `name`, `description` (`method/skills/codebase-analysis/SKILL.md:1-4`). No `interrogation/`. Installed recursively into `.claude/skills/` (`bin/polype-dev-install:46`, `tests/install.test.sh:9-25`).
- `method/templates/`: no `brief.md`; `prd.md` is the sibling model (frontmatter + sections + tables).
- `docs/references/spec-interrogation.md` (104 lines): stance, mechanics, sequence (pitch, 7 forcing questions, premises, gap map with 13 dimensions of which 9 ★, pre-mortem + red team, alternatives), exit criteria, brief template.
- `docs/conception.md:14,39`: the new mode = full `/spec` interrogation, approved brief, then stories.

## Attachment points
- New: `method/commands/po-brief.md`, `method/skills/interrogation/SKILL.md`, `method/templates/brief.md`, `tests/brief.test.sh`.
- One line in `method/commands/po-help.md` « Mise en place », after `/po-prd` (outside Owns, forced by `pilot.test.sh:38`).
- Matrix: status cell of C04 in `docs/parite-killer-saas.md:39` (`à faire` → `fait — …`).

## Verified interfaces
- `tests/lib.sh`: `contains FILE PHRASE` (fixed string, case-sensitive), `require_file`, `needs_tool`/`lacks_tool` (read `allowed-tools` YAML list), `settings_read_by FILE` (names from the `Reads settings:` line), `frontmatter FILE`, `fail`.
- `tests/structure.test.sh:23-33`: every `method/commands/*.md` needs a `Reads settings:` line whose names all exist in the template → `Entry mode`, `Target branch` are valid.
- `tests/run.sh`: focused run `bash tests/run.sh brief.test.sh`. Baseline: 87 passed, 0 failed.
- `tests/prd.test.sh:8` shows the section-extraction idiom (`awk '/^## X/ {on=1; next} /^## / {on=0} on'`) usable to scope assertions to one section.

## Traps
- `tests/overlap.test.sh`: no line of `method/` may share 8+ consecutive words with Killer SaaS; write fresh prose.
- `tests/pilot.test.sh:38` (help lists every command) — see above.
- Method files in English (`AGENTS.local.md` conventions); `po-help` in French.
- Commands that must not write code do not get Write/Edit/Bash: `po-brief` writes `docs/brief.md` and commits it, like `po-prd` which holds Write and Bash (`po-prd.md:4-9`) — same need, same tools, plus `Agent`.
- `docs/brief.md` lives on `Target branch` in the target project; s14 will read it (`docs/stories.md:210`), so its `status: approved` frontmatter is a contract for s14.
- No migration, no code outside `method/`, `tests/`, `docs/`.

## Open questions
- Should the skill keep the web research step ("research, don't ask" on incumbents)? It needs WebSearch; the plan decides whether `po-brief` gets it or the skill makes it conditional.
- Pre-mortem subagent: name a built-in type (`Plan`) or just "a fresh subagent given only the draft"? The criterion only requires fresh context.
- Alternatives become the first ADR in the reference; in a target project that means `docs/decisions/` from `templates/adr.md` (Law 6). Whether `po-brief` writes it or only records the choice in the brief is for the plan.

## Complexity
Story 3 → 3. Four new files and one line of help; the size lies in writing ~100 lines of skill prose in our own words and in tests that pin the clauses without overfitting.

## Split
Not needed.
