# Research — s20-wiring

## Structuring facts
- `help_lists_every_command` is already true: `method/commands/po-help.md:11-32` lists all 16 other commands (s11–s19 each added their line) and `every_command_listed_in_help` passes (`tests/pilot.test.sh:38-46`). The help only needs its wording aligned (orchestrator "enchaîne les cinq étapes", `:30`, ignores track and design).
- `tests/pilot.test.sh:11-12` counts exactly two `## Stage .* — checkpoint` headings in the orchestrator. The design stage has its own approval (`method/commands/po-design.md:157-158`) but must not be headed `— checkpoint`, or that test breaks.
- The short track has no research file, yet `method/agents/reviewer.md:17` lists `docs/research/<id>.md` as an input; `/po-flow` works around it with a sentence in its prompt (`method/commands/po-flow.md:74`). The reviewer should state it itself.
- `design-doctrine` declares itself "preloaded by the later design and review steps" (`method/skills/design-doctrine/SKILL.md:3`), but the reviewer preloads only `review-antihallu` and `testing-doctrine` (`method/agents/reviewer.md:6-8`), and nothing in the review procedure mentions design.
- Every setting the story needs already exists in the template: `Entry mode`, `Design source`, `Story track`, `Flow threshold` (`method/templates/agents-local.md:23-28`). No new setting.

## Story
Rules, help, status, orchestrator and reviewer learn the framing stages (s11–s19) so the whole pipeline reads end to end. Criteria (tests in `tests/wiring.test.sh`, except the help one which is `every_command_listed_in_help`):
- `rules_list_framing_before_the_story_cycle` — Law 1 shows framing (setup, prd or brief per mode, stories, stories review, architecture, design system) before the per-story cycle, with design and the short track.
- `help_lists_every_command` — existing test stays green.
- `status_reports_framing_and_track` — `/po-status` shows framing state (prd or brief, stories, stories-review verdict, architecture, design system) and each story's track (`full` or `flow`).
- `orchestrator_picks_the_track_and_runs_design` — track chosen from `Story track` and `Flow threshold`, hand-off to `/po-flow` when it applies, design inserted for stories with a screen.
- `reviewer_checks_design_conformity_without_measuring` — conformity to the design system and the screen's intent; off-system component or token = major, critical if it breaks visual coherence; measures nothing.
Matrix: D10, D16, D17, D18 (`docs/parite-killer-saas.md:59,65-67`).

## Current code
- `method/AGENTS.md:10-24` — Law 1: one five-row table (research → ship) "none skipped, none reordered"; `:22` mentions `/po-setup`, orchestrator, status, help only. No framing, no design, no flow. Law 6 `:64` names only `docs/stories.md` and `docs/architecture.md` as committed on `Target branch`.
- `method/commands/po-help.md` (French) — sections Mise en place (framing commands, `:11-19`), Le cycle d'une story (`/po-design` as a sub-item of research, `:22-27`), Outils (orchestrator, status, flow, `:29-32`).
- `method/commands/po-status.md:11` reads `Target branch`, `Worktree root`, `Merge mode`, `Plan validation`; steps: setup line, per-story columns (complexity, research, plan, record, review, shipped, dependencies), output table, decisions. No framing, design or track.
- `method/commands/po-orchestrator.md:15` reads six settings; stages 0–5 fixed: research, plan (checkpoint), execute, review, ship (checkpoint). No track choice, no design, no framing check.
- `method/agents/reviewer.md` — inputs `:17`, limits, blocked report, answer shape with the two verdict lines.

## Attachment points
- `method/AGENTS.md` Law 1 (framing table before the story table; design row; short-track paragraph), Law 6 bullet on committed framing files, Ids section (`docs/designs/<id>/`).
- `method/commands/po-status.md` — `Reads settings:` + `Entry mode`, `Story track`, `Flow threshold`; a framing step; per-story `design` and `track`; flow next command `/po-flow`.
- `method/commands/po-orchestrator.md` — `Reads settings:` + `Story track`, `Flow threshold`, `Entry mode`; stage 0 framing check; a track stage; a design stage between research and plan.
- `method/agents/reviewer.md` — inputs (design files, short-track facts), `design-doctrine` preload, a design conformity section.
- `method/commands/po-help.md` — wording only.
- `docs/parite-killer-saas.md` status cells D10, D16, D17, D18.

## Verified interfaces
- Framing outputs: `docs/prd.md` (`status: approved`, `po-prd.md:25`), `docs/brief.md` (`status: approved`, `po-brief.md:31`), chosen by `Entry mode` (`po-stories.md:19-22`); `docs/reviews/stories.md` ending `Stories ready: yes|no` (`po-stories-review.md:33`), a soft gate that only warns (`:44`); `docs/architecture.md` (`po-architect.md`); `docs/design-system.md` (`po-design-system.md`).
- Design: `docs/designs/<id>/design.md` (+ `mockup.html` or `brief.md` for a new screen), uncommitted until the implementer commits (`po-design.md:122-124`); requires the worktree and `docs/design-system.md` (`:111-112`); ends "Next: /po-plan <id>" (`:160`).
- Flow: `/po-flow` refuses on `Story track: full`, accepts `flow`, and on `auto` requires complexity ≤ `Flow threshold` (`po-flow.md:26-32`); escalates on "a new screen" (`:37`); plan frontmatter `track: flow` (`method/templates/plan-flow.md:2`). A full-track plan has no `track:` key (`method/templates/plan.md:1-3`).
- Test helpers: `settings_read_by`, `needs_tool`, `contains`, `frontmatter` (`tests/lib.sh`); unknown settings in `Reads settings:` fail `tests/structure.test.sh:24-34`.

## Traps
- Tests touching owned files that must stay green: `tests/pilot.test.sh` (2 checkpoints, `Delegate to \`implementer\` the way \`/po-execute\` does`, no Edit on orchestrator, status read-only phrases incl. 'no commit, checkout, merge or file change' and 'on `Target branch` or `origin/<Target branch>`'), `tests/review.test.sh:5-51` (reviewer lacks Write, has Edit, `git diff --exit-code`, preload lines, exact sentence on `Ship allowed: no`, '**Critical** stops the ship.' in AGENTS.md), `tests/structure.test.sh` (Law 1/5/7 headings, marker line 1), `tests/install.test.sh:33,92`, `tests/overlap.test.sh` (8+ words shared with Killer SaaS).
- Flow escalates on a new screen, so a story with a screen never reaches `/po-flow` with a design pending; the orchestrator must run the track check with that in mind (a screen → full track + design).
- `.claude/` and `.polype/` in this repo are older installed copies; the story edits `method/` only.
- Baseline: `bash tests/run.sh` → 117 passed, 0 failed.
- No migration.

## Open questions
- D16 says the orchestrator is "blocked if framing is missing"; `/po-stories-review` defines its verdict as a soft gate (`po-stories-review.md:44`). Block on which framing pieces (approved prd/brief?) vs warn on the rest? The plan decides; it must not contradict the soft gate.
- How `/po-status` shows the track of a story with no plan yet: predicted from `Story track`/`Flow threshold`, or blank.
- D16 and D17 stay `partiel` (fleet and tracker are M3); only the cell text changes.

## Complexity
Story: 2 → 3. Five files plus a test file and the matrix; no code, but many existing tests pin exact phrases in these files.

## Split
Not required (below 5).
