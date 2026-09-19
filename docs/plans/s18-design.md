---
validated: yes
---
# Plan — s18-design

Branch `story/s18-design`. Read `docs/research/s18-design.md` first; this plan builds on it without repeating it.

## Story
`/po-design <story>` derives one story's screen from `docs/design-system.md` inside the story worktree, so plan and implementation start from a decided screen. A derived screen gets a note of deltas; a new screen gets the note plus exactly one artefact, which is looked at in a browser but never measured. Criteria (each the name of one test in `tests/design.test.sh`): `design_fails_closed_without_system_or_source`, `design_distinguishes_new_and_derived_screens`, `design_renders_and_looks_without_measuring`, `design_lives_in_the_story_worktree`.

## Decisions

| Question | Decision | Why |
| --- | --- | --- |
| Where it runs | Story stage: `<Worktree root><id>` on `story/<id>`, checked like `/po-plan` (`po-plan.md:23`); mismatch → stop, point to `/po-research <id>`, never switch | Criterion 4; Law 4 |
| Output | Everything under `docs/designs/<id>/` of the worktree: `design.md` always, plus `mockup.html` or `brief.md` for a new screen. Left uncommitted; the implementer commits it with the story | Criterion 4; Law 4 "uncommitted work under `docs/`" |
| Source of truth | The files under `docs/designs/<id>/` win over any external tool or chat until a person changes them by running `/po-design` again | Criterion 4; doctrine |
| Fail closed | `docs/design-system.md` missing → stop, point to `/po-design-system`. `Design source` is `—` → stop and ask the person to set it in `AGENTS.local.md` (never set it for them). Both: nothing written, no mockup | Criterion 1; `po-setup.md:38` promise |
| Story with no screen | Say so and stop, writing nothing | Avoids empty design notes |
| Derived vs new | Derived when every region of the screen maps to a pattern and components already in `docs/design-system.md`; new otherwise. Unsure → one AskUserQuestion | Criterion 2; doctrine |
| Artefact per source | `internal` → `mockup.html`, drawn through the `Design skill`; `external` → `brief.md` from `templates/design-brief.md`, handed to the `Design tool`. Exactly one, never both | Criterion 2 |
| Missing skill or tool | `internal` with `Design skill` at `—` and a new screen → stop before drawing (derived screens need no artefact, so they proceed). `external` with `Design tool` at `—` → write the brief for no named tool and say so | "Reading settings" in `AGENTS.md` |
| Fidelity | Mockup and brief cover every state the screen has (empty, loading, error, success, disabled, focus as relevant), light and dark, desktop and mobile, real text — no placeholder copy | D03 |
| Looking | Serve `docs/designs/<id>/` over local HTTP (`python3 -m http.server --bind 127.0.0.1`), never `file://`; open it in whatever browser tool the session has, in light and dark, at desktop and mobile widths; look for what is broken. Exact sentence `Nothing is measured here.` — contrast belongs to `/po-design-system`. What could not be seen (no browser, a state not reachable) is written in the note | Criterion 3; doctrine « Measuring » |
| Brief | Not rendered (it is text for a tool); the note says so | Criterion 3 applies to mockups |
| Approval | One grouped AskUserQuestion showing the note (and the artefact's path) before finishing; a change goes back to its step | A screen is a decision |
| Settings read | `Worktree root`, `Design source`, `Design skill`, `Design tool` | Only these steer it |
| Tools | Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion | Writes docs, serves a mockup; no source file |
| Outside Owns | D03 status cell; one French sub-line under step 1 of « Le cycle d'une story » in `po-help.md` | Conventions; s12–s17 precedent (help test already green) |

## Tasks
1. [x] `method/templates/design-screen.md` — `# Design — <id>`, one intro line (written by `/po-design` into `docs/designs/<id>/design.md`; the files in that folder win over any external tool). Sections: `## Screen` (what it shows, for whom, reached from where); `## Kind` (`derived` — pattern reused — or `new`); `## Deltas` (what differs from the reused pattern; a derived screen's note holds only this); `## Components and tokens` (names from `docs/design-system.md` only); `## States`; `## Themes and widths`; `## Artefact` (`none`, `mockup.html` or `brief.md`); `## Seen and not seen`; `## Gaps`. — Test: `design_distinguishes_new_and_derived_screens`.
2. [x] `method/templates/design-brief.md` — `# Design brief — <id>`, intro (handed to the `Design tool`; what comes back is a reference, the repository wins). Sections: `## Goal`, `## Real content`, `## Layout`, `## System to use` (tokens and components of `docs/design-system.md`, nothing else; a missing one is a gap to raise, not to invent), `## States`, `## Themes and widths`. — Test: `design_distinguishes_new_and_derived_screens`.
3. [x] `method/commands/po-design.md` — frontmatter `description`, `argument-hint: <story id or name>`, `allowed-tools` as decided. `# /po-design`, `Reads settings:` line as decided, `Story: $ARGUMENTS`. Sections in order:
   - `## Checks`: no `AGENTS.local.md` → `/po-setup`; id match against `docs/stories.md`; worktree path and `story/<id>` branch (as `/po-plan`); exact phrase `` `docs/design-system.md` is missing `` → stop, point to `/po-design-system`; exact phrase `` `Design source` is `—` `` → stop, ask the person to set it; exact sentence `Either way the command writes nothing and draws no mockup.`; story without a screen → say so, stop. Then read the `design-doctrine` skill, the story, `docs/research/<id>.md` when present, `docs/design-system.md`.
   - `## Where the design lives`: exact phrase `` `docs/designs/<id>/` `` in `the story worktree`; exact sentence `These files are the source of truth for the screen:` followed by the external-tool rule; left uncommitted, committed by the implementer.
   - `## Step 1 — Derived or new`: rule of the decision table, AskUserQuestion when unsure.
   - `## Step 2 — The note`: fill `templates/design-screen.md` into `design.md`; derived → exact phrase `the deltas only` and `no artefact`; components and tokens from the inventory only, gaps recorded not filled.
   - `## Step 3 — The artefact`: new screen only, `exactly one artefact`: `internal` → `` `mockup.html` `` through `Design skill`; `external` → `` `brief.md` `` from `templates/design-brief.md` for `Design tool`; missing skill/tool rules; fidelity rule; the mockup is a reference, never copied into source.
   - `## Step 4 — Look at the mockup`: exact phrases `over local HTTP`, `in light and in dark`, `at desktop and at mobile width`, `Nothing is measured here.`, `what could not be seen`; stop the server afterwards.
   - `## Approval`: grouped AskUserQuestion; nothing is reported done before approval.
   - Finish line: "Design written to docs/designs/<id>/ in <path>. Next: /po-plan <id>".
   — Tests: all four.
4. [x] `method/commands/po-help.md`: under step 1 of « Le cycle d'une story », add `` - `/po-design <story>` — pour une story avec écran : dérive l'écran du design system dans `docs/designs/<id>/`. `` indented as a sub-item. — Test: existing `every_command_listed_in_help`.
5. [x] `tests/design.test.sh`, header `# s18 — /po-design and its two templates.`, local `section_of` (as `tests/design-system.test.sh:9`):
   - `test_design_fails_closed_without_system_or_source`: `needs_tool` AskUserQuestion; the two stop phrases and `Either way the command writes nothing and draws no mockup.` inside `## Checks`.
   - `test_design_distinguishes_new_and_derived_screens`: in the command, `the deltas only` inside `## Step 2 — The note`; `exactly one artefact`, `` `mockup.html` ``, `` `brief.md` `` inside `## Step 3 — The artefact`; `design-screen.md` has `## Deltas` and `## Artefact`; `design-brief.md` exists with `## System to use`.
   - `test_design_renders_and_looks_without_measuring`: `needs_tool` Bash; the five phrases of task 3 inside `## Step 4 — Look at the mockup`.
   - `test_design_lives_in_the_story_worktree`: `story/<id>` inside `## Checks`; `` `docs/designs/<id>/` ``, `the story worktree` and `These files are the source of truth for the screen:` inside `## Where the design lives`.
6. [x] `docs/parite-killer-saas.md`: D03 → `fait — \`method/commands/po-design.md\`, \`method/templates/design-screen.md\`, \`method/templates/design-brief.md\``. No other line.
7. [x] Full suite `bash tests/run.sh` (`Full suite: execute-end`); record in `docs/verif/s18-design.md`.

## Run interdicts
- Empty diff for `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `docs/stories.md`, `docs/decisions/`, `bin/`, `tests/lib.sh`, every existing test, `method/AGENTS.md`, `method/agents/`, `method/skills/`, every existing `method/templates/` file, and every existing `method/commands/` file except the one line of `po-help.md`.
- `docs/parite-killer-saas.md`: only the D03 line changes.
- No new setting in `method/templates/agents-local.md`.
- No orchestrator, status or rules wiring of `/po-design` (s20).
- `po-design.md` computes no contrast ratio: no luminance formula, no `python3`/`node` arithmetic.
- No sentence from Killer SaaS (`tests/overlap.test.sh` green with its sources present); never open Killer SaaS's `ks-design`, `design-screen.md` or `design-brief.md`.

## The pivot
`/po-design` is a story stage that writes under `docs/designs/<id>/` of the worktree and fails closed. Ways it could be wrong: (a) it reuses `/po-design-system`'s "repository root on `Target branch`" checks — compare its `## Checks` with `po-plan.md:23`; (b) "no measuring" leaks — look for ratios or thresholds in `po-design.md`; (c) the `Design source: —` stop sets the setting on the user's behalf — compare with `AGENTS.md` « Reading settings » and `po-setup.md:38`; (d) a new screen could end with two artefacts or a derived one with a mockup — read Steps 2–3 against the doctrine.

## Files touched
New: `method/commands/po-design.md`, `method/templates/design-screen.md`, `method/templates/design-brief.md`, `tests/design.test.sh`. Edited: one line of `method/commands/po-help.md`, the D03 line of `docs/parite-killer-saas.md`. Plus `docs/research/`, `docs/plans/`, `docs/verif/` for this story.

## Test strategy
Four structural tests in `tests/design.test.sh`, one per criterion (budget 25). Each pins its clauses to the section that must hold them, so deleting or moving a clause fails the test. Existing `every_command_listed_in_help`, `every_setting_read_by_a_command_exists_in_template`, install tests and `method_does_not_reuse_killer_saas_text` cover the rest. No visual checks: the story ships prose, no screen.

## Done when
Full suite green, one commit `s18-design: …` on `story/s18-design` holding code, tests and docs, verification record complete, review with no open critical finding.
