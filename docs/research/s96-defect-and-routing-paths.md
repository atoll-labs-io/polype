# Research — s96-defect-and-routing-paths

## Structuring facts
- **Root cause, major 1 (s90 review)**: `method/commands/po-research.md:39-47` and `method/commands/po-orchestrator.md:45-46` never name the `diagnostic` skill (0 occurrences of `diagnostic`, `Fixes` or `root cause` in either file). A `Fixes`/`Corrige` story that `/po-flow` escalates (`po-flow.md:43-47`) is then researched by `/po-research` or by `/po-orchestrator` stage 2 in the main context, which loads only the skills its text names. Only `method/agents/planner.md:9` preloads it.
- **Root cause, major 2 (s90 review)**: `method/skills/diagnostic/SKILL.md:24-25` ends a failed diagnostic with "write no plan" but leaves no line a reader can match. `method/commands/po-drive.md:50` maps "research present, plan absent" to the plan stage, and `method/agents/planner.md:42` builds the plan on any research on disk; `method/commands/po-plan.md:22-34` has no check on the research's content. So a lane with no root cause is re-planned on a guess.
- **Root cause, minor (s80 review)**: `method/commands/po-flow.md:34` says "A missing setting is a stop, never a guess", which also covers `QA stage` (read at `:15`). `:51` and `po-drive.md:24` say `QA stage` missing stops only a story that would go to QA. `po-flow` never states that exception.
- **Criterion 4**: `method/commands/po-execute.md:42`, the implementer prompt, says "never checkout or stash" with no place qualifier. s98 (`docs/stories.md`, criterion `implementer_explores_a_throwaway_clone`) lets the implementer `checkout` in a throwaway clone, so the forbidding must apply to the story worktree only.
- No story assumption is false. ADR-0068's Neutral consequence ("`/po-research` lancé à la main ne précharge pas la skill", `docs/decisions/ADR-0068-…md:33`) is the sentence the story replaces in part.

## Diagnostic
Reproduction (on the code as it stands, no file created):
- `grep -c diagnostic` → 0 on `po-research.md`, `po-orchestrator.md`, `po-plan.md` and `po-drive.md`. `grep -c Fixes` and `grep -ci 'root cause'` → 0 on the same four files.
- `po-drive.md:49-50`: the only rows matching a worktree with research and no plan send it to the plan stage.
- `po-flow.md:34` vs `:51`: the general stop sentence comes first and has no exception.
- `bash tests/run.sh diagnostic-skill.test.sh drive.test.sh flow.test.sh research.test.sh` → 27 passed. No test covers these paths, which is the defect.

Hypotheses (major 1):
1. *The skill loads by itself from its description whenever a defect story is researched.* Refuted if the description makes the planner its only trigger. It does: `SKILL.md:3` says "Preloaded by the planner", and no command frontmatter lists skills. — **discarded**.
2. *`/po-orchestrator` hands its research to the planner, so the planner preload covers it.* Refuted if stage 2 writes the research in its own context. It does: `po-orchestrator.md:46` says "Write `docs/research/<id>.md` under that contract", and its Agent dispatches are only implementer, qa and reviewer (`:57`, `:65`, `:68`). — **discarded**.
3. *Neither command names the skill, so the main context never applies it.* Refuted if either file named it. Neither does (grep above). — **kept**.

Hypotheses (major 2):
1. *`/po-plan` or the planner already refuse research without a cause.* Refuted if neither contract reads the research's content before planning. `po-plan.md:22-34` and `planner.md:42` do not. — **discarded**.
2. *Nothing on disk tells "no root cause" apart from a normal research.* Refuted if the skill fixed a readable marker. `SKILL.md:24-25` fixes only prose ("report that no root cause was found"). — **kept**.

## Story
A defect story runs the diagnostic on every path: the fleet planner, `/po-research`, and `/po-orchestrator` (also after a `/po-flow` escalation). A research with no root cause goes to a human, never to a plan. Criteria:
- `every_path_runs_the_diagnostic` — `/po-research` and `/po-orchestrator` apply `diagnostic` to a story with a `Fixes`/`Corrige` line.
- `no_root_cause_goes_to_a_human` — the skill fixes the line written when no cause was found. The `/po-drive` resume table, the planner and `/po-plan` stop the story and hand it to a human. ADR-0068 is superseded in part.
- `flow_names_the_qa_stage_exception` — `/po-flow` says a missing `QA stage` stops only a story that would go to QA.
- `implementer_may_explore_a_throwaway_clone` — the `/po-execute` implementer prompt forbids `checkout` in the story worktree only.

## Current code
- `po-research.md:39-47` — the investigation: `codebase-analysis` named at `:40`, then six steps. It finishes at `:54` with "Next: /po-plan <id>".
- `po-orchestrator.md:43` — a `/po-flow` escalation continues at stage 2. `:45-46` — stage 2 is research "as `/po-research` describes". `:51-54` — stage 4 is the plan under the `/po-plan` contract.
- `po-plan.md:22-25` — Checks first. `:29` — an existing plan skips to Approval. `:34` — no research means a warning.
- `po-drive.md:45-62` — the resume table, first row wins. `:49` no research, `:50` research and no validated plan → plan. `:93` — planner dispatch (step 1).
- `planner.md:39` — "Defect story" bullet. `:42` — "Research already on disk" bullet.
- `SKILL.md` (diagnostic) — `:3` description, `:13` "since the planner writes only research and plan", `:24-25` the three-hypotheses stop.
- `po-flow.md:34` — the general stop sentence; `:51` — the QA paragraph.
- `po-execute.md:42` — the implementer prompt.

## Attachment points
- New paragraph in `po-research.md` `## The investigation`, plus an alternative finish line.
- `po-orchestrator.md` `## Stage 2 — Research`: name the skill and stop on the marker.
- `SKILL.md` `## Three hypotheses, then stop`: the exact marker line. Also the frontmatter description.
- `po-drive.md` resume table: one new row between `:49` and `:50`. Step 1 of the dispatch at `:93`.
- `planner.md` "Defect story" bullet; `po-plan.md` `## Checks first`.
- `po-flow.md:34`; `po-execute.md:42`.
- `docs/decisions/ADR-0068-…md` frontmatter `superseded-by`. The new ADR-0070 is reserved for this lane.

## Verified interfaces
- Test helpers in `tests/lib.sh`: `fail` `:11`, `frontmatter` `:13`, `require_file` `:41`, `contains` `:43`. `section_of`, `holds`, `before` and `only_line` are local to each test file, not in `lib.sh` (`tests/diagnostic-skill.test.sh:11`).
- The partial-supersession convention: the new ADR has `supersedes: [ADR-NNNN]`, the old one has `superseded-by: [ADR-NNNN]` and stays `accepted` (`method/templates/adr.md:6`; `tests/bounds.test.sh:502`).
- The research template already has `## Structuring facts` (`method/templates/research.md:3`), so the marker needs no template change. `method/templates/research.md` is outside `Owns`.

## Traps
- **Pinned phrases** to keep word for word:
  - `tests/drive.test.sh:212-214` greps the row containing `plan absent or without \`validated: yes\`` for "the lane keeps that file and never writes it again", and `:236-237` pins the planner's "Research already on disk" phrases.
  - `tests/qa-fleet.test.sh:66-82` uses `only_line` on several resume rows. A new row must not repeat their patterns.
  - `tests/surface-routing.test.sh:34-35` counts exactly three rows containing `| record current, the story goes to QA,`.
  - `tests/research.test.sh:10` pins "Do not repair it with `switch`, `checkout` or `stash`."
  - `tests/diagnostic-skill.test.sh:33-35` pins "After three discarded hypotheses, stop.", "write no plan" and "report that no root cause was found".
  - `tests/flow.test.sh:37-46` pins the signal phrases.
- `tests/overlap.test.sh`: new method text must be written in our own words (ADR-0006).
- `method/agents/implementer.md:23` also says "never checkout". It is owned by s98, not s96, and must stay untouched.
- `method/templates/stories.md:14` and `agentic-stories/SKILL.md:53` (s90 major 1) become true once this story lands. They are outside `Owns` and need no edit.
- No migration, no dependency, no screen.

## Open questions
- Commands name skills in prose (`po-research.md:40` already does it for `codebase-analysis`), and their `allowed-tools` lists no Skill tool. The plan follows that precedent. Whether the main context reliably loads a skill named this way is not proven here; s90's review says the same of the planner path.

## Complexity
Story 3 → 3. Seven method files take small additive edits, plus one ADR and one test file. The coupling is in the pinned phrases, not in logic.

## Split
—
