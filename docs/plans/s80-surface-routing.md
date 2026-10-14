---
validated: yes
---
# Plan — s80-surface-routing

[Story](../stories.md) · [Research](../research/s80-surface-routing.md)

Branch `story/s80-surface-routing`. Read `docs/research/s80-surface-routing.md` first; this plan builds on it without repeating it. The structural choice is settled in `docs/decisions/ADR-0058-la-regle-de-routage-par-surface-est-ecrite-une-fois-dans-agents.md` (ADR-0058), written by the planner and committed with the story.

## Story
`/po-drive`, `/po-orchestrator`, `/po-flow`, `/po-status` and the review route a story to design and QA by its `Surface` line and `QA stage` (ADR-0054), falling back to "its text shows a screen" when the line is missing. Criteria: `design_follows_a_screen_surface`, `qa_follows_the_qa_stage`, `flow_escalates_a_surface_with_qa`, `review_requires_qa_for_a_surface`, `plan_names_scene_viewpoints`, `rules_speak_of_surfaces`.

## The phrases
ADR-0058 defines the rule once. Write these exact sentences, because the tests quote them. Text in angle brackets is a note to the implementer, not part of the sentence.

- **D1** — `method/AGENTS.md`, `### Per story`, new paragraph between the table (ends `:39`) and the short-track paragraph (`:41`):
  > **Design and QA, by surface.** A story **has a screen** when its `Surface` line says `screen`, or when it has no `Surface` line and its text shows a screen (ADR-0054); the design stage is for it alone. A story **goes to QA** when `QA stage` is `screens` and the story has a screen, or when `QA stage` is `surfaces` and its `Surface` line says anything but `—`; a story with no `Surface` line goes only when it has a screen. With `QA stage: —`, no story goes to QA. With `QA stage` missing, a story that has a screen or a `Surface` other than `—` cannot be routed and stops, naming the setting; any other story carries on, since no value would send it to QA. Every command, agent and template that routes a story uses these two terms and does not restate the rule (ADR-0058).
- **R1** — `method/AGENTS.md:37` QA row:
  > | QA (stories that go to QA, by `QA stage`) | `/po-qa` | `docs/qa/<id>/`, report and evidence, committed alone |
- **R2** — `method/AGENTS.md:64` last cell:
  > the review of a story that goes to QA
- **G1** — po-drive `:25`:
  > - `QA stage` missing → only the lanes of stories that would need it stop, as `AGENTS.md` (Law 1) says, each named in the report; the other lanes carry on.
- **G2** — po-drive `:53-55`, each row's first cell:
  > Each first cell starts with: record current, the story goes to QA, — in place of: record current, the story has a screen, `QA stage` is `screens`, — and everything after it (from "and the last `QA status:`" or "and `po-gate qa-current <id>`") stays word for word.
- **G3** — po-drive `:94`:
  > **The design stage**, for a story with a screen (`AGENTS.md`, Law 1): `subagent_type: designer` <rest unchanged>
- **G4** — po-drive `:96`:
  > **The QA stage**, for a story that goes to QA (`AGENTS.md`, Law 1): `subagent_type: qa` <rest unchanged, except its last sentence, which becomes:> A story that does not go to QA dispatches no qa.
- **O1** — orchestrator `:33`:
  > A story with a screen (`AGENTS.md`, Law 1) also needs <rest unchanged>
- **O2** — orchestrator `:41`:
  > A story with a screen takes the full track whatever the settings say when that screen is new: `/po-flow` would escalate on it, and the screen needs the design stage. Any story that goes to QA takes the full track too, because `/po-flow` runs no QA; `QA stage` missing for a story that has a screen or a `Surface` other than `—` → stop and name the setting.
- **O3** — orchestrator `:63`:
  > Only for a story that goes to QA (`AGENTS.md`, Law 1); skip it otherwise. `QA stage` missing for a story that has a screen or a `Surface` other than `—` → stop and name the setting.
- **S1** — po-status `:29`:
  > - QA: for a story that goes to QA (`AGENTS.md`, Law 1), `docs/qa/<id>/report.md` present or not, its last `QA status:`, and whether `po-gate qa-current <id>` passes; `—` for any other story; `QA stage` unset → shown as unset for a story that has a screen or a `Surface` other than `—`, never guessed;
- **S2** — po-status `:39`:
  > <replace> for a screen story under `QA stage: screens`: <with> for a story that goes to QA:
- **F1** — po-flow `:14`:
  > <add> `QA stage` <to the Reads settings line, after> `Flow threshold`
- **F2** — po-flow `## Escalation signals`, new paragraph after `:45`:
  > A story that goes to QA (`AGENTS.md`, Law 1) escalates the same way, at the first check, because its `Surface` line and `QA stage` are read before any code and `/po-flow` runs no QA. `QA stage` missing for a story that has a screen or a `Surface` other than `—` → stop and name the setting.
- **A1** — review-antihallu `:28`:
  > <the bullet starts> - For a story that goes to QA (`AGENTS.md`, Law 1): run `po-gate qa-current <id>` as well. <the middle stays word for word; after> probable and unverified ones go to `## Not verified` unless you confirm them <insert> , and so does every item of the report's `## Not seen`, with the reason the report gives <and the last sentence becomes> A story that does not go to QA has no QA to require.
- **V1** — reviewer `:25`:
  > When the story has a screen, also `docs/design-system.md` and `docs/designs/<id>/`; when it goes to QA (`AGENTS.md`, Law 1), `docs/qa/<id>/report.md` and its evidence as well.
- **V2** — reviewer, new paragraph after `:30`:
  > A story whose `Surface` is `scene` has no design system: judge the scene against the viewpoints its plan names under `## Scene viewpoints` (what each must show, its framing, scale and light), through the QA report's scene captures when it went to QA, never against `docs/design-system.md`. A viewpoint no capture shows goes to `## Not verified`.
- **V3** — reviewer `:49`, after `An empty list would claim that everything was seen.`:
  > Everything the QA report lists under `## Not seen` belongs there too, with its reason.
- **I1** — implementer `:37`, replacing from `That holds when` to the end of the paragraph:
  > That holds whenever the story does not go to QA. When it goes to QA (`AGENTS.md`, Law 1), checking its surface belongs to the QA stage: `/po-qa` runs after your commit, against the committed tree. Do not stand in for it; name in your final message what it should check.
- **T1** — `method/templates/review.md:24`:
  > - [ ] `po-gate qa-current <id>` (a story that goes to QA, `AGENTS.md` Law 1) → <passes, verified QA findings carried to Findings | fails → review blocked | not required: the story does not go to QA>
- **T2** — review template `:56`:
  > <what this review did not check, why, and what a person should do instead; every item of the QA report's `## Not seen`; for a `scene` story, each viewpoint no capture shows>
- **P1** — `method/templates/plan.md` and `plan-flow.md`, new section between `## Tasks` and `## Run interdicts`:
  > ## Scene viewpoints
  > <Only for a story whose `Surface` is `scene`; write `—` for any other. One line per viewpoint to capture: where it looks from, what it must show, and its framing, scale and light. The QA captures these viewpoints and the review judges the scene against them.>
- **H1** — po-help `:28`:
  > - `/po-design <story>` — pour une story avec écran (`Surface: screen`, ou sans ligne `Surface` un texte qui montre un écran) : dérive l'écran du design system dans `docs/designs/<id>/`.
- **H2** — po-help `:31`:
  > - `/po-qa <story>` — pour une story que `QA stage` envoie en QA : un agent vérifie sa surface avec le pilote qui lui va (navigateur, scénarios, rendu de scène, simulation) et laisse ses preuves dans `docs/qa/<id>/`, sans rien corriger. `/po-orchestrator` et `/po-drive` la lancent eux-mêmes quand `QA stage` vaut `screens` (les stories `screen`) ou `surfaces` (toute surface autre que `—`).
- **H3** — po-help `:36`:
  > <replace> ajoute le design et la QA pour une story avec écran <with> ajoute le design pour une story avec écran et la QA pour une story que `QA stage` y envoie
- **M1** — `README.md:31`:
  > | QA (story que `QA stage` envoie en QA) | `/po-qa` | la surface vérifiée avec son pilote, preuves dans `docs/qa/<id>/` |
- **M2** — `README.md:37`:
  > <replace> lancent eux-mêmes la QA d'une story avec écran <with> lancent eux-mêmes la QA d'une story que `QA stage` y envoie

Each quoted text is written exactly; `<…>` parts are instructions, not text. In the P1 body the angle brackets are part of the template text.

## Tasks
1. [x] `method/AGENTS.md`: write D1, R1 and R2; leave `:34`, `:43` and `:81` as they are. Tests that fail if this is wrong: `test_design_follows_a_screen_surface` and `test_qa_follows_the_qa_stage` (D1), `tests/qa-gate.test.sh` `test_rules_list_qa_in_the_story_cycle` (R1, updated in task 8), `test_rules_speak_of_surfaces` (R2).
2. [x] `method/commands/po-drive.md`: G1, G2, G3, G4. Leave the design row `:51` and the `## Resuming` prose under the table as they are. Tests: `test_qa_follows_the_qa_stage` (G2), `tests/qa-fleet.test.sh` `test_drive_wave_includes_qa` (G1, G4) and `test_drive_resumes_on_qa_current` / `test_drive_resumes_on_an_uncommitted_report` (row order and tails kept), `tests/fleet-design.test.sh:56` (G3).
3. [x] `method/commands/po-orchestrator.md`: O1, O2, O3. `method/commands/po-status.md`: S1, S2. Tests: `test_design_follows_a_screen_surface` (O1, and no `text shows a` left), `test_qa_follows_the_qa_stage` (S1, S2), `tests/qa-fleet.test.sh` `test_orchestrator_runs_qa_for_a_screen` (O3 and 'because `/po-flow` runs no QA' kept in O2) and `test_status_reports_qa` (S1).
4. [x] `method/commands/po-flow.md`: F1, F2. The five signal bullets and the "six tasks" sentence stay as they are. Test: `test_flow_escalates_a_surface_with_qa`, plus `tests/flow.test.sh` unchanged and still green.
5. [x] The review side: A1 in `method/skills/review-antihallu/SKILL.md`, V1, V2, V3 in `method/agents/reviewer.md`, T1 and T2 in `method/templates/review.md`, I1 in `method/agents/implementer.md`. Tests: `test_review_requires_qa_for_a_surface` (A1, V1, V2, V3), `test_rules_speak_of_surfaces` (T1), `tests/qa-gate.test.sh` `test_review_requires_a_current_qa_report` (A1 keeps its three frozen sentences) and `test_implementer_hands_the_screen_to_qa` (I1, updated in task 8).
6. [x] P1 in both plan templates. Test: `test_plan_names_scene_viewpoints`; `tests/plan.test.sh`, `tests/planner.test.sh`, `tests/flow.test.sh` unchanged and green.
7. [x] H1, H2, H3 in `method/commands/po-help.md`; M1, M2 in `README.md`. Tests: `test_rules_speak_of_surfaces` (H2, M1 third cell), `tests/qa-fleet.test.sh` `test_help_and_readme_show_qa` (H3, M1, updated in task 8; its `:96` phrase is a prefix of H2's last sentence and stays).
8. [x] Tests:
   - Update the clauses this story changes. In `tests/qa-fleet.test.sh`: `:39` → `'Only for a story that goes to QA'`; `:57` → `'for a story that goes to QA'`; `:63` → `` '`QA stage` missing → only the lanes of stories that would need it stop' ``; `:89` → the S1 phrase `` '`QA stage` unset → shown as unset for a story that has a screen or a `Surface` other than `—`, never guessed' ``; `:97` → the H3 phrase; `:100` → the regex `'^| QA (story que `QA stage` envoie en QA) | `/po-qa` |'`. In `tests/qa-gate.test.sh`: `:100` → `grep -qF 'stories that go to QA'` with its message; `:126` → the I1 sentence up to `` `/po-qa` ``. In `tests/fleet-design.test.sh:56` → the G3 prefix. Update the header comments that say "screen story" where they describe the changed clause.
   - Write `tests/surface-routing.test.sh` (see Test strategy).
   - Run the focused files, then the full suite once through `po-run`.

## Run interdicts
- `method/commands/po-review.md` ends with an empty diff. It holds no routing phrase (research), even though it is in `Owns`.
- These must end with an empty diff: `method/commands/po-qa.md`, `method/agents/qa.md`, `method/skills/qa-drivers/`, `method/commands/po-design.md`, `method/commands/po-execute.md`, `method/agents/planner.md`, `method/templates/qa.md`, `method/templates/agents-local.md`, `method/hooks/`. They are outside `Owns` and already agree with ADR-0054.
- Root `AGENTS.md`, `.claude/` and `.polype/` end with an empty diff. They are installed copies, refreshed in a separate commit after ship.
- `po-flow`'s five signal bullets, `## Escalation signals` heading and "Five" wording stay as they are (`method/agents/planner.md:32` is not owned and says "Five signals").
- No existing heading of `plan.md` or `plan-flow.md` is renamed, moved or removed.
- The rule from D1 is not restated anywhere else: no owned file other than `method/AGENTS.md` contains `when \`QA stage\` is \`surfaces\``.
- `tests/flow.test.sh`, `tests/plan.test.sh`, `tests/planner.test.sh`, `tests/wiring.test.sh` and `tests/design-handoff.test.sh` end with an empty diff.
- No `/po-status` column is added (open question, research). The table header `· record · qa · review ·` is unchanged.
- No Killer SaaS text (ADR-0006); `tests/overlap.test.sh` stays green.

## The pivot
**Everything rests on ADR-0058.** The two terms are defined once in `method/AGENTS.md`, and the routing files use them instead of restating the rule. It could be wrong in three ways:
1. **An agent that routes does not load `AGENTS.md`.** Subagents and commands run with the project's `AGENTS.md` in context. Check: each routing sentence also names `AGENTS.md` (Law 1), so a reader who lacks it knows where to look.
2. **A routing place keeps the old formula.** The usual traces are "whose text shows a screen", "`QA stage` is `screens`" and "screen story". Compare with: `grep -rn "text shows a\|QA stage\` is \`screens\|screen story" method/commands/po-drive.md method/commands/po-orchestrator.md method/commands/po-status.md method/commands/po-flow.md method/skills/review-antihallu/ method/agents/reviewer.md method/agents/implementer.md method/templates/review.md`. It should print nothing.
3. **D1 disagrees with ADR-0054 or with the unowned `qa-drivers/SKILL.md:20`**, for instance by sending a story with `Surface: —` and a text that shows a screen to QA. Compare D1 with ADR-0054 § Decision Outcome, "QA" and "Surface d'une story": once a `Surface` line exists, it decides, and the text is read only when the line is missing.

## Files touched
`method/AGENTS.md`, `method/commands/po-drive.md`, `method/commands/po-orchestrator.md`, `method/commands/po-status.md`, `method/commands/po-flow.md`, `method/skills/review-antihallu/SKILL.md`, `method/agents/reviewer.md`, `method/agents/implementer.md`, `method/templates/review.md`, `method/templates/plan.md`, `method/templates/plan-flow.md`, `method/commands/po-help.md`, `README.md`, `tests/qa-fleet.test.sh`, `tests/qa-gate.test.sh`, `tests/fleet-design.test.sh`, `tests/surface-routing.test.sh` (new). Pipeline evidence: `docs/research/s80-surface-routing.md`, this plan, `docs/decisions/ADR-0058-la-regle-de-routage-par-surface-est-ecrite-une-fois-dans-agents.md`.

## Test strategy
Every check here is on method text, in bash. Each new test pins only phrases that no updated existing test already pins, so no rule is tested twice. Count: 6 new functions plus 8 changed assertions in 3 existing files, within `Test budget` 25.

`tests/surface-routing.test.sh`. Its helpers (`section_of`, `holds`) are redefined locally, as `qa-fleet` does.
- `test_design_follows_a_screen_surface`: `method/AGENTS.md` contains the D1 sentence `` A story **has a screen** when its `Surface` line says `screen`, or when it has no `Surface` line and its text shows a screen ``. `po-orchestrator.md` contains the O1 prefix. None of `po-drive.md`, `po-orchestrator.md`, `po-status.md` and `po-flow.md` contains `text shows a`. *It bites* if the definition is dropped, or if any routing file keeps its own text rule.
- `test_qa_follows_the_qa_stage`: `method/AGENTS.md` contains the three D1 clauses `` when `QA stage` is `screens` and the story has a screen ``, `` when `QA stage` is `surfaces` and its `Surface` line says anything but `—` `` and `` a story with no `Surface` line goes only when it has a screen ``. The `## Resuming` section of `po-drive.md` has exactly 3 lines containing `| record current, the story goes to QA,`. `po-status.md` contains `for a story that goes to QA:`. None of `po-drive.md`, `po-orchestrator.md` and `po-status.md` contains `` `QA stage` is `screens` ``, `` `QA stage: screens` `` or `screen story`. *It bites* if the `surfaces` clause or the fallback is removed, if one resuming row keeps the old wording, or if status says something else.
- `test_flow_escalates_a_surface_with_qa`: `settings_read_by po-flow.md` lists `QA stage`. The `## Escalation signals` section holds `` A story that goes to QA (`AGENTS.md`, Law 1) escalates the same way `` and `` `/po-flow` runs no QA ``.
- `test_review_requires_qa_for_a_surface`: step 1 of review-antihallu (the awk range `**1.` to `**2.`) holds `` For a story that goes to QA (`AGENTS.md`, Law 1) `` and `` every item of the report's `## Not seen` ``. The skill no longer contains `` For a story with a screen, when `QA stage` is `screens` ``. `reviewer.md` holds the V1 clause `` when it goes to QA (`AGENTS.md`, Law 1), `docs/qa/<id>/report.md` ``, the V2 phrases `` judge the scene against the viewpoints its plan names under `## Scene viewpoints` `` and `` never against `docs/design-system.md` ``, and the V3 sentence.
- `test_plan_names_scene_viewpoints`: for each of `plan.md` and `plan-flow.md`, the exact line `## Scene viewpoints` exists, after `## Tasks` and before `## Run interdicts`, and its body holds `` `scene` ``, `framing`, `scale` and `light`.
- `test_rules_speak_of_surfaces`: `method/AGENTS.md` holds R2 and no longer contains `stories with a screen, when`. `templates/review.md` holds `(a story that goes to QA` and `not required: the story does not go to QA`. `po-help.md` holds `un agent vérifie sa surface avec le pilote qui lui va` and no longer contains `parcourt en navigateur les écrans touchés`. `README.md` holds `la surface vérifiée avec son pilote` and no longer contains `story avec écran, \`QA stage: screens\``.

Existing assertions updated with their clause: the 8 listed in task 8. No visual checks; there is no screen. Runs: each task's focused files (`bash tests/run.sh qa-fleet.test.sh` and so on); the full suite once at the end with `po-run --story s80-surface-routing --label test -- 'bash tests/run.sh'`. `Typecheck` is `—`.

## Done when
- Every box above is ticked, the full suite is green, and the `po-run` row is recorded in `docs/verif/s80-surface-routing.md`.
- One commit carries the code, the tests, the research, this plan and ADR-0058, in English, with no co-author trailer.
- The review has no open critical finding, and the story ships squashed onto `main`.
