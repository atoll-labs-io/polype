# Research — s18-design

[Story](../stories.md)

## Structuring facts
- `/po-design` is a **story stage**, not a framing command: it runs inside `<Worktree root><id>/` on `story/<id>` (criterion `design_lives_in_the_story_worktree`), so its checks copy `/po-plan`'s worktree contract (`method/commands/po-plan.md:23`), not `/po-architect`'s "repository root on `Target branch`" (`method/commands/po-architect.md:19-20`).
- The stop on `Design source: —` is already promised: `method/commands/po-setup.md:38` "every design command stops on it and asks for the source again". `/po-design` must keep that promise literally (stop, ask, write nothing).
- `docs/design-system.md` is committed on `Target branch` by `/po-design-system` (`method/commands/po-design-system.md` « Approval and commit »); a story worktree starts from that branch (`method/commands/po-research.md` « The worktree » step 1), so the check "system exists" is a file check inside the worktree.
- The Killer SaaS local sources exist and `tests/overlap.test.sh` runs for real (1 passed on this branch); it has same-named templates `design-screen.md`, `design-brief.md` (`docs/research/s17-design-system.md:4`). Write only from D03 (`docs/parite-killer-saas.md:52`) and the `design-doctrine` skill.
- `tests/pilot.test.sh:38-46` matches `grep -F "/po-design"`, which `/po-design-system` already satisfies in `po-help.md`: the help test stays green without a new line. Precedent (s12–s17) still added one line each; `po-help.md` is owned by s20.

## Story
`/po-design <story>` derives the story's screen from the design system so plan and implementation start from a decided screen. Criteria:
- `design_fails_closed_without_system_or_source` — no `docs/design-system.md`, or `Design source` at `—` → stop, no mockup.
- `design_distinguishes_new_and_derived_screens` — derived → `design.md` with deltas only; new → `design.md` plus exactly one artefact (`mockup.html` for `internal`, `brief.md` for `external`).
- `design_renders_and_looks_without_measuring` — a mockup is opened in a browser over local HTTP, light and dark, desktop and mobile widths; look for what is broken, measure nothing; say what could not be seen.
- `design_lives_in_the_story_worktree` — everything is written under `docs/designs/<id>/` in the story worktree, which wins over any external tool.

## Current code
- `method/commands/`: no `po-design.md`. Models: `po-design-system.md` (s17, design command with Bash + AskUserQuestion, reads `design-doctrine`), `po-plan.md` (story-stage checks: id match, worktree path + branch, "Everything below reads and writes inside the worktree").
- `method/skills/design-doctrine/SKILL.md`: truth in the repository; derived = deltas, no mockup; new = "exactly one artefact"; never invent component/token; gaps recorded; mockup never code; "Contrast is measured once, by `/po-design-system` … Later steps … do not measure again". Its description already says it is "preloaded by the later design and review steps".
- `method/templates/`: no `design-screen.md` nor `design-brief.md`. `design-system.md` holds tokens, contrast, components, state patterns, do/don't, gaps.
- `method/templates/agents-local.md:24-26,47-49`: `Design source` (`internal` / `external` / `—`), `Design skill` (skill drawing screens when internal), `Design tool` (tool when external).
- Parity D03 (`docs/parite-killer-saas.md:52`): blocked without design system; design source per project; derived → deltas without mockup, new → exactly one artefact; final fidelity (all states, light/dark, desktop/mobile, real text); rendered and looked at over local HTTP on both themes and widths; what could not be checked is said; gaps recorded, never invented; repo wins; mockup is a reference, never code. Status `à faire`.

## Attachment points
- New: `method/commands/po-design.md`, `method/templates/design-screen.md` (→ `docs/designs/<id>/design.md`), `method/templates/design-brief.md` (→ `docs/designs/<id>/brief.md`), `tests/design.test.sh`.
- Status cell of D03 (`docs/parite-killer-saas.md:52`).
- Optional one line in `method/commands/po-help.md` « Le cycle d'une story » (outside Owns, per s12–s17 precedent).
- Installer copies commands and templates wholesale (`bin/polype-dev-install`, s17 research): nothing to register.
- Orchestrator/status/rules wiring (design inserted between research and plan) is s20 (`docs/stories.md:302-311`); not here.

## Verified interfaces
- `tests/lib.sh`: `contains`, `require_file`, `needs_tool`/`lacks_tool`, `frontmatter`, `settings_read_by`, `fail`.
- `tests/design-system.test.sh:9`: local `section_of FILE HEADING` awk idiom to pin a clause to a section.
- `tests/structure.test.sh:24-34`: every command has a `Reads settings:` line whose names exist in the template. Available: `Target branch`, `Worktree root`, `Design source`, `Design skill`, `Design tool`.
- Baseline on `story/s18-design` (from `m2-cadrage` 1558f98): `bash tests/run.sh` → 109 passed, 0 failed.

## Traps
- Overlap test: fresh English prose; avoid stock sentences.
- Method files in English; `po-help` in French.
- `Reads settings:` only template settings.
- The mockup check needs Bash (local HTTP server, browser); the command writes files (Write) and asks (AskUserQuestion). It must not measure: no contrast arithmetic, unlike `po-design-system.md` Step 3.
- Design output stays uncommitted under `docs/` like research and plan (`method/AGENTS.md` Law 4 "legitimately holds uncommitted work under `docs/`"); the implementer commits it with the story.
- Installed copies `.claude/`, `.polype/` are not edited.

## Open questions
- Where the "derived vs new" call comes from: the command decides by comparing the story's screen with the patterns in `docs/design-system.md`, and asks the user when unsure. Plan fixes the rule.
- How the browser is driven: the command should use whatever browser tool the session has (headless Chromium/Playwright screenshot, a browser MCP) and serve `docs/designs/<id>/` with `python3 -m http.server` on localhost; with no browser, it says the mockup was not looked at. Not `file://`.
- `external`: the `brief.md` is what the external tool (`Design tool`) is given; the command does not render it. Whether it then waits for an export is out of scope — the brief is the artefact.
- Does `/po-design` require the research file? Reasonable: it reads it when present (screens the story touches), like `/po-plan`.
- Story without a screen: the command says so and stops without writing anything; s20 decides when the orchestrator calls it.

## Complexity
3 → 3. Three prose files plus a test file, one parity cell, an optional help line; no code path, no migration.

## Split
Not needed.
