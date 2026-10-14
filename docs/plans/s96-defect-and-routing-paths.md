---
validated: yes
---
# Plan — s96-defect-and-routing-paths

[Story](../stories.md) · [Research](../research/s96-defect-and-routing-paths.md)

Branch `story/s96-defect-and-routing-paths`. Read `docs/research/s96-defect-and-routing-paths.md` first; this plan builds on it without repeating it. The structural choice (the marker line) is settled in `docs/decisions/ADR-0070-une-recherche-sans-cause-racine-porte-une-ligne-et-va-a-un-humain.md`, written by the planner under the number the driver reserved; commit it with the story.

## Story
A defect story (`Fixes`/`Corrige` line) runs the `diagnostic` skill on every path, and a research with no root cause goes to a human instead of a plan. Criteria: `every_path_runs_the_diagnostic`, `no_root_cause_goes_to_a_human`, `flow_names_the_qa_stage_exception`, `implementer_may_explore_a_throwaway_clone` (see the research, `## Story`).

## Tasks
All edits are additive unless stated. Quoted text is the wording to use; small grammatical adjustments are fine, but keep every backticked token exact.

1. [x] **The marker, in the skill** — `method/skills/diagnostic/SKILL.md`:
   - In `## Three hypotheses, then stop`, after the existing sentences (keep "After three discarded hypotheses, stop.", "write no plan" and "report that no root cause was found" word for word), add: "The research then opens its `## Structuring facts` with this exact line, alone on its line: `Root cause: not found`. That line hands the story to a human: no command and no agent builds a plan on a research that carries it. Once someone finds the cause, they rewrite the research without the line, and the story resumes at its plan (ADR-0070)."
   - Frontmatter `description`: replace "Preloaded by the planner for a story carrying a `Fixes` line." with "Applied to a story carrying a `Fixes` line by the planner, `/po-research` and `/po-orchestrator`."
   - In `## Reproduce`, replace "since the planner writes only research and plan" with "since the research stage writes nothing but its research, its plan and a reserved ADR". This fixes minor 5 of the s90 review: the skill now runs outside the planner too.
   - Test: `no_root_cause_goes_to_a_human` (skill clause).
2. [x] **Every research path names the skill** (major 1):
   - `method/commands/po-research.md`, `## The investigation`, after the `codebase-analysis` sentence (`:40`), add: "A story carrying a `Fixes` line (`Corrige` in a French stories file) fixes a defect: run this investigation under the `diagnostic` skill, which writes the root cause first and stops after three discarded hypotheses."
   - In `## The report`, before the finish line, add: "When the research opens with `Root cause: not found`, finish instead with: \"No root cause found for <id>: the story goes to a human, and no plan is written on this research.\""
   - Keep the existing finish line.
   - `method/commands/po-orchestrator.md`, `## Stage 2 — Research`, append: "A story carrying a `Fixes` line (`Corrige` in a French stories file) is researched under the `diagnostic` skill, the escalated `/po-flow` path included. A research that opens with `Root cause: not found` ends the run here: report it and hand the story to a human, with no plan."
   - Test: `every_path_runs_the_diagnostic`.
3. [x] **The marker stops the plan** (major 2):
   - `method/commands/po-plan.md`, `## Checks first`: add a bullet after the worktree bullet: "`docs/research/<id>.md` holding the line `Root cause: not found` → stop: the diagnostic found no cause, so the story goes to a human and no plan is written."
   - `method/agents/planner.md`, the "Defect story" bullet (`:39`): append "A research holding the line `Root cause: not found`, whether you wrote it or found it on disk, ends your run with that report: you write no plan, and the lane goes to a human."
   - Leave the "Research already on disk" bullet word for word (pinned by `tests/drive.test.sh:236-237`).
   - Test: `no_root_cause_goes_to_a_human` (planner and po-plan clauses).
4. [x] **The resume table routes it to a human** — `method/commands/po-drive.md`:
   - In `## Resuming`, insert one row between the "no worktree" row (`:49`) and the plan row (`:50`): `| research holding the line \`Root cause: not found\`, and no plan with \`validated: yes\` | a human — the diagnostic found no cause, and a plan built on that research would be a guessed fix (ADR-0070) |`.
   - Do not reuse the phrase `plan absent or without \`validated: yes\`` in the new row (`tests/drive.test.sh:212`).
   - In `## Dispatching`, step 1 (`:93`), append: "A planner that answers with a research holding `Root cause: not found` sends its lane to a human, as the resuming table says; no plan is approved or dispatched for it."
   - Test: `no_root_cause_goes_to_a_human` (row present, stage `a human`, row read before the plan row).
5. [x] **The ADRs' frontmatter** — in `docs/decisions/ADR-0068-une-story-de-defaut-porte-une-ligne-fixes-et-passe-par-le-diagnostic.md`, change the frontmatter only: `superseded-by: [ADR-0070]`. `status` stays `accepted` (partial supersession, `method/templates/adr.md:6`), and the body is unchanged. ADR-0070 is already on disk with `supersedes: [ADR-0068]`.
   - Test: `no_root_cause_goes_to_a_human` (the two frontmatter lines).
6. [x] **po-flow names the `QA stage` exception** (s80 minor) — `method/commands/po-flow.md:34`: replace the sentence with "A missing setting is a stop, never a guess, `QA stage` excepted: missing, it stops only a story that would go to QA (see `## Escalation signals`). A model setting missing → stop and name it."
   - Test: `flow_names_the_qa_stage_exception`.
7. [x] **The implementer prompt forbids checkout in the story worktree only** — `method/commands/po-execute.md:42`: replace "never checkout or stash." with "never checkout or stash in the story worktree.". The rest of the prompt stays word for word.
   - Test: `implementer_may_explore_a_throwaway_clone`.
8. [x] **Tests** — create `tests/defect-and-routing-paths.test.sh` with the four functions below. Run them focused (`bash tests/run.sh defect-and-routing-paths.test.sh`), and run the neighbouring files: `diagnostic-skill`, `drive`, `qa-fleet`, `surface-routing`, `resume`, `flow`, `research`, `execute`, `model-routing`, `planner`, `overlap`. Then run the full suite once through `po-run`.

## Scene viewpoints
—

## Run interdicts
- `method/agents/implementer.md`, `method/hooks/po-bounds.sh` and `docs/installation.md` end with an empty diff: they belong to s98, which depends on this story.
- `method/templates/research.md`, `method/templates/stories.md`, `method/skills/agentic-stories/SKILL.md` and `docs/parite-killer-saas.md` have an empty diff: they are outside `Owns`.
- No existing test file is modified. `tests/research.test.sh`, `drive.test.sh`, `execute.test.sh`, `model-routing.test.sh`, `flow.test.sh` and `diagnostic-skill.test.sh` are owned but need no change. This is the story's note: all changes are additive.
- The body of ADR-0068 below its frontmatter has an empty diff. Only `superseded-by:` changes.
- The resuming table keeps every existing row, in its existing order, word for word. Exactly one row is added.
- `.claude/` and `.polype/` are untouched. No new setting appears in any `Reads settings:` line.
- The diff contains no path outside `Owns` except `docs/research/`, `docs/plans/`, `docs/verif/` of this story and ADR-0070.

## The pivot
**The marker is the exact line `Root cause: not found`, and every stop matches it with `grep -x`.** It could be wrong in three ways:
- **A model writes a variant** (`**Root cause**: not found`, a bullet, a French line). Then the drive row never matches, and the lane is re-planned on a guess. To check: the skill and every reader quote the identical backticked token; the test greps that same token in all four files.
- **Row order.** If the new row sits below the plan row, the plan row wins first and the bug stays. To check: the test compares the two row positions.
- **Prose naming does not load a skill in the main context.** Then `/po-research` still runs without the diagnostic. To check: nothing in the text tests can show it. This is the same gap as s90, and it stays under "Not proven" in the record.

## Files touched
- `method/skills/diagnostic/SKILL.md`
- `method/commands/po-research.md`, `po-orchestrator.md`, `po-plan.md`, `po-drive.md`, `po-flow.md`, `po-execute.md`
- `method/agents/planner.md`
- `docs/decisions/ADR-0068-…md` (frontmatter only), `docs/decisions/ADR-0070-…md` (new, written by the planner)
- `tests/defect-and-routing-paths.test.sh` (new)

## Test strategy
Four text tests in `tests/defect-and-routing-paths.test.sh`, one per criterion, well within `Test budget` (25). Define `section_of` locally, as `tests/diagnostic-skill.test.sh:11` does. Each test is scoped to a section, so a phrase elsewhere in the file cannot satisfy it (s90 minor 4).
- `test_every_path_runs_the_diagnostic`:
  - `section_of po-research.md 'The investigation'` contains `` `diagnostic` skill `` and `` `Fixes` `` and `Corrige`.
  - `section_of po-orchestrator.md 'Stage 2 — Research'` contains the same three.
  - Bite: deleting either new sentence fails it.
- `test_no_root_cause_goes_to_a_human`:
  - `section_of SKILL.md 'Three hypotheses, then stop'` contains `` `Root cause: not found` ``.
  - `section_of po-plan.md 'Checks first'` contains `Root cause: not found`.
  - `section_of planner.md 'The contracts you carry'`: the line starting `- **Defect story**` contains `Root cause: not found` and `write no plan`.
  - The `## Resuming` table of `po-drive.md` has exactly one row with `Root cause: not found`. Its second column starts with `a human`, and its line number is lower than that of the row holding `the lane keeps that file and never writes it again`.
  - `frontmatter` of ADR-0070 has `supersedes: [ADR-0068]`, and that of ADR-0068 has `superseded-by: [ADR-0070]`.
- `test_flow_names_the_qa_stage_exception`: the line of `po-flow.md` containing `A missing setting is a stop` also contains `` `QA stage` excepted `` and `only a story that would go to QA`.
- `test_implementer_may_explore_a_throwaway_clone`:
  - The `po-execute.md` line starting `> Story <id>. Worktree:` contains `never checkout or stash in the story worktree`.
  - That line does not contain `never checkout or stash.` (unqualified).

No visual checks: there is no screen. No type check: `Typecheck: —`.

## Done when
- One implementer commit on `story/s96-defect-and-routing-paths` carrying the code, the research, the plan, the record and ADR-0070.
- `bash tests/run.sh` is green through `po-run`, and no existing test file is changed.
- The review has no open critical finding, and the squash commit `s96-defect-and-routing-paths: Le diagnostic et le routage tiennent sur tous les chemins` is on `main`.
