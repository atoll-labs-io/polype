---
validated: yes
---
# Plan — s20-wiring

[Story](../stories.md) · [Research](../research/s20-wiring.md)

Branch `story/s20-wiring`. Read `docs/research/s20-wiring.md` first; this plan builds on it without repeating it.

## Story
Rules, help, status, orchestrator and reviewer learn the framing stages and the per-story design and short track, so the whole pipeline reads end to end. Criteria (test names): `rules_list_framing_before_the_story_cycle`, `help_lists_every_command` (= existing `every_command_listed_in_help`), `status_reports_framing_and_track`, `orchestrator_picks_the_track_and_runs_design`, `reviewer_checks_design_conformity_without_measuring`. Matrix D10, D16, D17, D18.

## Decisions

| Question | Decision | Why |
| --- | --- | --- |
| Law 1 shape | A `### Framing` table (Setup, Scope, Stories, Stories review, Architecture, Design system) before a `### Per story` table that gains a `Design` row between Research and Plan, marked "stories with a screen"; then a short-track paragraph on `/po-flow` | Criterion 1 |
| Framing the orchestrator blocks on | `Entry mode` `replace`/`adapt` → `docs/prd.md` with `status: approved`; `new` → `docs/brief.md` with `status: approved`; missing → stop, point to `/po-prd` or `/po-brief`. `Entry mode: —` → project writes stories by hand, no scope check. Stories review missing or `Stories ready: no` → warn and carry on | D16 "blocked if framing is missing"; soft gate of `po-stories-review.md:44` kept |
| Track choice | `Story track: full` → full. `flow` → `/po-flow`. `auto` → `/po-flow` when complexity ≤ `Flow threshold`, else full; no complexity → full. A story whose text shows a new screen goes full directly (flow would escalate on it). `/po-flow` escalating → continue at research on the full track, reusing its worktree | Criterion 4; `po-flow.md:26-46` |
| Hand-off | On the short track the orchestrator applies `/po-flow` as written and stops sequencing its own stages | Criterion 4 |
| Design stage | New `## Stage 3 — Design` after research, for a story with a screen, applying `/po-design`; its approval is the one `/po-design` defines; the heading is not `— checkpoint` | Criterion 4; `tests/pilot.test.sh:11-12` |
| Stage numbering | 0 Can this start, 1 Track, … research, design, plan (checkpoint), execute, review, ship (checkpoint) — exactly two `— checkpoint` headings | pilot test |
| Status framing | A `Framing` step after setup: scope source per `Entry mode` (none · draft · approved), `docs/stories.md` present, stories review `Stories ready:` (yes · no · none), `docs/architecture.md` present, `docs/design-system.md` present — read on `Target branch` | Criterion 3; D17 |
| Status track | `flow` when the plan frontmatter has `track: flow`, `full` when a plan exists without it; no plan yet → the track the settings predict, suffixed `(expected)`; `auto` without complexity → `full (expected)` | Criterion 3 |
| Status per story | Adds `design` (`docs/designs/<id>/design.md` present or not) and `track`; next command for an expected flow story is `/po-flow <id>` | D17 |
| Reviewer design | Preload `design-doctrine`; inputs add `docs/design-system.md` and `docs/designs/<id>/` when present; judges conformity to the system and the screen's intent, not the mockup line by line; off-system component or token = major, critical if it breaks visual coherence; measures nothing (contrast is `/po-design-system`'s) | Criterion 5; D10; `design-doctrine` description |
| Reviewer short track | Without a research file, the plan's `## Verified facts` takes its place | Research fact 3 |
| Help | Wording only: orchestrator line names track and design; status line names framing and track. No new line | Criterion 2 already green |
| Settings read | Orchestrator + `Story track`, `Flow threshold`, `Entry mode`; status + `Entry mode`, `Story track`, `Flow threshold`; reviewer unchanged | All in template; structure test |

## Tasks
1. [x] `method/AGENTS.md` Law 1: replace the intro sentence and the single table by: a sentence saying framing runs once before the first story; `### Framing` table (Stage · Command · Produces): Setup `/po-setup` `AGENTS.local.md`; Scope `/po-prd` (`replace`, `adapt`) or `/po-brief` (`new`), per `Entry mode` → approved `docs/prd.md` or `docs/brief.md`; Stories `/po-stories` `docs/stories.md`; Stories review `/po-stories-review` `docs/reviews/stories.md` with `Stories ready:`; Architecture `/po-architect` `docs/architecture.md` and ADRs; Design system `/po-design-system` `docs/design-system.md`. Then `### Per story` with "none skipped, none reordered", the five existing rows plus `Design | /po-design | docs/designs/<id>/` (stories with a screen) after Research. Then a paragraph: short track `/po-flow` does research and plan in one context for a story `Story track` and `Flow threshold` allow, and keeps every gate. Update the paragraph on `/po-setup`/orchestrator/status/help accordingly. Law 6 first bullet: framing files committed on `Target branch`; `docs/designs/<id>/` travels on `story/<id>`. — Test: `rules_list_framing_before_the_story_cycle`.
2. [x] `method/commands/po-orchestrator.md`: description mentions track and design; `Reads settings:` adds `Story track`, `Flow threshold`, `Entry mode`; stage 0 framing check as decided; `## Stage 1 — Track` as decided (hand-off to `/po-flow`, escalation back); `## Stage 2 — Research`; `## Stage 3 — Design` (screen only, `/po-design`, reuse an existing `docs/designs/<id>/design.md`); then Plan — checkpoint, Execute, Review, Ship — checkpoint, renumbered, their text unchanged except numbers. — Test: `orchestrator_picks_the_track_and_runs_design`; pilot tests stay green.
3. [x] `method/commands/po-status.md`: `Reads settings:` adds `Entry mode`, `Story track`, `Flow threshold`; new step `**Framing.**` as decided; per-story bullets `track` and `design`; output table columns add track and design; "Next" includes `/po-flow <id>` and `/po-design <id>`. — Test: `status_reports_framing_and_track`.
4. [x] `method/agents/reviewer.md`: `  - design-doctrine` in skills; inputs sentence for design files and short-track facts; `## Design conformity` section as decided. — Test: `reviewer_checks_design_conformity_without_measuring`; `tests/review.test.sh` stays green.
5. [x] `method/commands/po-help.md`: wording of the orchestrator and status lines (French). — Test: `every_command_listed_in_help`.
6. [x] `tests/wiring.test.sh`, header `# s20 — framing and short track wired into rules, status, orchestrator and reviewer.`, with a local `section_of`:
   - `test_rules_list_framing_before_the_story_cycle`: in Law 1, `### Framing` appears before `### Per story`; framing names `/po-setup`, `/po-prd`, `/po-brief`, `/po-stories`, `/po-stories-review`, `/po-architect`, `/po-design-system`; per story names `/po-design` and `/po-flow`; `/po-design` row after `/po-research` and before `/po-plan` (line order).
   - `test_status_reports_framing_and_track`: `Reads settings:` has `Entry mode`, `Story track`, `Flow threshold`; phrases `docs/prd.md`, `docs/brief.md`, `Stories ready:`, `docs/architecture.md`, `docs/design-system.md`, `track: flow`, `/po-flow`.
   - `test_orchestrator_picks_the_track_and_runs_design`: reads `Story track` and `Flow threshold`; track section holds `` `Story track` ``, `` `Flow threshold` ``, `/po-flow`; a design stage heading exists before the plan checkpoint heading and holds `/po-design`.
   - `test_reviewer_checks_design_conformity_without_measuring`: preload line `  - design-doctrine`; `## Design conformity` holds `major`, `critical`, `visual coherence`, `measures nothing` (exact wording chosen in task 4).
7. [x] `docs/parite-killer-saas.md` status cells only: D10 → `fait — \`method/agents/reviewer.md\``; D16 → `partiel — \`method/commands/po-orchestrator.md\` (piste, design, cadrage) ; flotte en M3`; D17 → `partiel — \`method/commands/po-status.md\` (cadrage, design, piste, depuis les fichiers) ; tracker en M3`; D18 unchanged (already `fait`).
8. [x] Full suite `bash tests/run.sh`; record in `docs/verif/s20-wiring.md`.

## Run interdicts
- Empty diff for `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `docs/stories.md`, `docs/decisions/`, `bin/`, `tests/lib.sh`, every existing test file, `method/skills/`, `method/hooks/`, `method/templates/`, every `method/commands/` file except the four owned, every `method/agents/` file except `reviewer.md`.
- Existing phrases pinned by tests in owned files kept verbatim (`tests/pilot.test.sh`, `tests/review.test.sh`, `tests/structure.test.sh`, `tests/install.test.sh:33,92`).
- No new setting. No Killer SaaS text (`tests/overlap.test.sh` green).
- `docs/parite-killer-saas.md`: only D10, D16, D17 cells change.

## The pivot
The orchestrator's framing block. It could be wrong by (a) blocking projects that write stories by hand — compare against `method/AGENTS.md` "Stories are written in `docs/stories.md`" and `Entry mode: —`; (b) turning the stories review into a hard gate — compare against `po-stories-review.md:44`; (c) disagreeing with `/po-flow` on track rules — compare against `po-flow.md:26-32`.

## Files touched
`method/AGENTS.md`, `method/commands/po-orchestrator.md`, `method/commands/po-status.md`, `method/agents/reviewer.md`, `method/commands/po-help.md`, `tests/wiring.test.sh`, `docs/parite-killer-saas.md`, plus `docs/research|plans|verif/s20-wiring.md`.

## Test strategy
Four new static tests in `tests/wiring.test.sh` (one per criterion) plus the existing help test: 5 checks, within `Test budget` 25. Each quotes phrases that only the new clauses carry, so removing a clause fails its test. Existing `pilot`, `review`, `structure`, `install`, `overlap` suites guard regressions. No visual check.

## Done when
All five criteria green, full suite green, one commit on `story/s20-wiring`, review without open critical.
