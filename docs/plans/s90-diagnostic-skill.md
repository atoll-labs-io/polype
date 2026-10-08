---
track: flow
validated: yes
---
# Plan (short track) — s90-diagnostic-skill

Written by the `planner` subagent on the short track. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s90-diagnostic-skill.md`. Decision recorded in `docs/decisions/ADR-0068-une-story-de-defaut-porte-une-ligne-fixes-et-passe-par-le-diagnostic.md` (written by the planner, uncommitted).

## Verified facts
- **Assumption half false:** the story says the stories template and `agentic-stories` define a `Corrige` line. Neither does: `method/templates/stories.md:10-13` lists Complexity, Depends on, Surface, Owns only; `method/skills/agentic-stories/SKILL.md` never names it (grep empty). The line exists only in Polype's own French `docs/stories.md:319,340,…,1166,1399`, where it names a defect of `docs/defauts.md` or a review finding. This story creates the definition. The template is English, so the field is `**Fixes**`, read as `Fixes` or `Corrige` — precedent `method/commands/po-execute.md:34` reads `Complexité`/`Complexity` (ADR-0068).
- No `diagnostic` skill exists: `method/skills/` holds ten skills, none named so. Skills install by directory glob (`bin/polype:86,100`), no registry to update; `bin/po-eval:60-71` checks every skill an agent's frontmatter lists, so `method/skills/diagnostic/SKILL.md` must exist once the planner lists it.
- Skill frontmatter is `name:` + `description:` (`method/skills/testing-doctrine/SKILL.md:1-4`).
- Planner preloads via frontmatter `skills:` (`method/agents/planner.md:6-8`). Its signal sentence counts five: `method/agents/planner.md:32`; the short-track contract repeats "the five signals": `planner.md:39`.
- `/po-flow` counts five at `method/commands/po-flow.md:37` (list `:38-42`), repeats "the five signals" at `:63`; QA escalation paragraph at `:50` (s80). First check runs on the story text before any worktree (`:44`), so a `Fixes` line is visible there.
- `method/templates/plan-flow.md:13` says "Each of the five"; table rows `:17-21`.
- Frozen phrases: `tests/flow.test.sh:38-61` (the five signal phrases, 'before/after reading the code', 'A single signal', 'a signal there → stop and point to', 'keep it as it is, write no plan', `## Escalation signals` before `## The plan`); `tests/surface-routing.test.sh:47-49`; `tests/planner.test.sh:9-55` — `cap_of` takes the **1st and 2nd** "`<n> lines at most`" of `planner.md` and compares them to the research then plan caps; `tests/drive.test.sh:175-231` (Limits phrases).
- Planner limits: writes only research, plan and the reserved ADR (`planner.md:52`) — so reproduction may not create a test or source file in the worktree.
- Research template has no diagnostic section (`method/templates/research.md`, not owned): the skill names the section the planner adds.
- ADR-0012 (`docs/decisions/ADR-0012-pas-de-rouge-dabord.md`): no red-first while implementing; the bite proof is the reviewer's (`method/skills/review-antihallu/SKILL.md:42`). "The test that would have caught it" is planned, not run red by the implementer.
- `docs/parite-killer-saas.md:64` (D15) still says five signals — not in `Owns`, left as is.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, `docs/stories.md:1363-1374` | absent — only markdown method files and one bash test change |
| New screen | absent — `Surface: —` | absent — no UI anywhere in the diff |
| Authorization or tenant scope | absent — story text | absent — no hook, gate or bounds file touched (`method/hooks/` out of `Owns`) |
| API contract | absent — story text | absent — the `Fixes` line is an optional story field read by agents, not an API; no hook parses it (`po-bounds.sh` reads only `**Owns**`) |
| New dependency | absent — story text | absent — bash and markdown only |
| Defect to fix (`Fixes`/`Corrige` line) | absent — s90 has no such line | absent |

Six tasks; QA not applicable (`Surface: —`).

## Story
As a developer I want a diagnostic skill the planner follows for a story that fixes a defect, so that no fix leaves without a found cause.
- `no_fix_without_a_root_cause` — the `diagnostic` skill asks to reproduce the defect, write the root cause with the proof that shows it, and only then plan the fix and the test that would have caught it.
- `stop_after_three_failed_hypotheses` — after three discarded hypotheses the research stops and says so instead of proposing a fix at random.
- `defect_stories_get_the_diagnostic` — a defect story is recognised by its `Corrige` line, defined by the stories template and `agentic-stories`; the planner preloads `diagnostic` and applies it to such a story; `/po-flow` and the planner send it to the full track; the texts that counted "five signals" (`/po-flow`, planner, short-plan template) give the updated list.

## Tasks

1. [x] **Write `method/skills/diagnostic/SKILL.md`.** Frontmatter `name: diagnostic`, a `description:` saying it is preloaded by the planner for a story with a `Fixes` line. Body in your own words (ADR-0006, `tests/overlap.test.sh`), in this order, each a `##` section:
   - `## When` — a story carrying `Fixes` (`Corrige` in a French stories file); always on the full track, during the research.
   - `## Reproduce` — run the defect on the code as it stands, with the inputs the defect names: a command, an existing test, a request. Write what was run and what it showed. Never create a file in the worktree to do it (planner limits); a reproduction that needs a new test becomes the plan's test task instead, and the research says the defect was not reproduced and why. A defect that does not reproduce is a finding reported, not a reason to fix blind.
   - `## Hypotheses` — one at a time, each with the observation that would refute it, recorded as kept or discarded with its evidence.
   - `## Root cause` — written first in `## Structuring facts` of the research: the `path:line` at fault, the input that reaches it, and the proof (output, trace, line read) tying symptom to cause. A symptom is not a cause. A `## Diagnostic` section of the research carries the reproduction and the hypotheses.
   - `## Only then, the plan` — the fix task targets the cause, and a task adds the test that would have caught the defect (fails on the code before the fix — proven by the reviewer's bite check, ADR-0012, not run red by the implementer).
   - `## Three hypotheses, then stop` — a bold rule: after three discarded hypotheses, stop: write the research with the three and what refuted each, write no plan, and report that no root cause was found. No guessed fix, no defensive patch around the symptom.
   Test: `test_no_fix_without_a_root_cause`, `test_stop_after_three_failed_hypotheses`.
2. [x] **Define the line.** `method/templates/stories.md`: after `**Owns**`, add `- **Fixes**: <…>` — optional, only on a story that fixes a defect, naming the defect and where it is recorded (`Issue tracker`, a defects file, a review finding), written `Corrige` in a French stories file; a story with this line takes the full track and is researched under the `diagnostic` skill. `method/skills/agentic-stories/SKILL.md`: a `## Defect stories` section (after `## Surface`) saying the same — Law 7 keeps defects out of stories unless a person turns one into a story; such a story carries `Fixes` (`Corrige`), its criteria name the wrong behaviour and the expected one. Test: `test_defect_stories_get_the_diagnostic`.
3. [x] **Planner.** `method/agents/planner.md`: add `  - diagnostic` under `skills:`; rewrite `:32` without a count — "These signals send a story back…: a migration, a new screen, authorization or tenant scope, an API contract, a new dependency, a defect to fix — a story carrying a `Fixes` line (`Corrige` in a French stories file)." keeping the rest of the paragraph; `:39` "the five signals" → "each escalation signal"; add a contract bullet **Defect story** after **Research**: a story with a `Fixes`/`Corrige` line is researched under the preloaded `diagnostic` skill, root cause before any plan, and three discarded hypotheses end in a report with no plan. Mention the skill in the "Where the facts come from" paragraph (`:13`). **Write no new "lines at most" phrase.** Tests: `test_defect_stories_get_the_diagnostic`; `planner.test.sh`, `drive.test.sh` stay green.
4. [x] **`/po-flow`.** `method/commands/po-flow.md:37` → "These signals send a story to the full track:" and add a sixth bullet "- a defect to fix: a `Fixes` line (`Corrige` in a French stories file), whose research follows the `diagnostic` skill on the full track." `:63` "the five signals" → "each escalation signal". Keep every phrase `flow.test.sh` and `surface-routing.test.sh` freeze. Test: `test_defect_stories_get_the_diagnostic`.
5. [x] **`method/templates/plan-flow.md`.** `:13` "Each of the five" → "Each escalation signal"; add a table row `| Defect to fix (\`Fixes\` or \`Corrige\` line) | absent — <where checked> | absent — <where checked> |`. Test: `test_defect_stories_get_the_diagnostic`, `test_plan_flow_template_carries_verified_facts`.
6. [x] **`tests/diagnostic-skill.test.sh`** (header `# s90 — the diagnostic skill.`), three tests, then `po-run` the full suite:
   - `test_no_fix_without_a_root_cause` — skill exists with `name: diagnostic`; the headings `## Reproduce`, `## Root cause`, `## Only then, the plan` appear **in that order** (line numbers compared); the root-cause section names `path:line` and the proof; the plan section names the test that would have caught the defect.
   - `test_stop_after_three_failed_hypotheses` — the stop section holds "three" discarded hypotheses, "no plan" and the report clause.
   - `test_defect_stories_get_the_diagnostic` — `planner.md` frontmatter holds `  - diagnostic`; planner, `po-flow.md` `## Escalation signals` and `plan-flow.md` each name `Fixes` and `Corrige`; stories template has a `- **Fixes**:` line naming `Corrige`; `agentic-stories` names both; none of `planner.md`, `po-flow.md`, `plan-flow.md` matches `grep -i 'five signals\|of the five'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff for everything outside `Owns` plus this plan and ADR-0068: notably `method/templates/research.md`, `method/commands/po-research.md`, `method/commands/po-orchestrator.md`, `method/AGENTS.md`, `docs/parite-killer-saas.md`, `.claude/`, `.polype/`, every existing `tests/*.test.sh`.
- `planner.md`: the 1st and 2nd "`lines at most`" stay 200 then 250; Limits and Checks lines unchanged.
- `po-flow.md`: the five original signal phrases, the QA paragraph (`:50`) and the order `## Escalation signals` before `## The plan` stay.
- No line of `method/` copied from Killer SaaS or gstack: `tests/overlap.test.sh` green.
- ADR-0068 is not rewritten by the implementer (accepted).

## Files touched
`method/skills/diagnostic/SKILL.md` (new), `method/templates/stories.md`, `method/skills/agentic-stories/SKILL.md`, `method/agents/planner.md`, `method/commands/po-flow.md`, `method/templates/plan-flow.md`, `tests/diagnostic-skill.test.sh` (new); plus this plan and ADR-0068, committed with the code.

## The pivot
Everything hinges on the trigger being the `Fixes` line read under two spellings. Wrong if a project writes a third form (e.g. `Fix`, `Bug`) — the skill then never fires; the test pins only these two, and `agentic-stories` must say exactly these two.

## Test strategy
Three tests in one new file, one per criterion, bash text checks per the repository convention; well under `Test budget` (25). Ordering is checked by heading line numbers, so moving "Root cause" after the plan section fails the first test. The negative grep for "five signals" fails if any of the three files keeps the count. Task tests run as `bash tests/run.sh diagnostic-skill.test.sh`; the full suite runs once at the end through `po-run --story s90-diagnostic-skill --label test -- 'bash tests/run.sh'`.

## Done when
The three criteria hold, the full suite (`bash tests/run.sh`) is green including `flow`, `planner`, `drive`, `surface-routing`, `overlap`, one commit on `story/s90-diagnostic-skill`, and a review with no open critical finding.
