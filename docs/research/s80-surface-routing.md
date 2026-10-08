# Research — s80-surface-routing

## Structuring facts
- No assumption of the story is false. Three things it leaves out: `/po-flow` does not read `QA stage` today (`method/commands/po-flow.md:14`); `tests/fleet-design.test.sh:56` also freezes a routing phrase ("for a story whose text shows a screen"), not only `qa-gate` and `qa-fleet`; and `/po-review` holds no routing phrase at all (`method/commands/po-review.md:26,41-42` only handle a review blocked on QA), so it needs no change.
- The old rule ("a story whose text shows a screen", "when `QA stage` is `screens`") is written separately in 8 owned files, ~20 places (list under Current code). The rule ADR-0054 adds (Surface line, `surfaces` value, fallback to the text) would double that. ADR-0058 (this lane) defines two terms once in `method/AGENTS.md`, "has a screen" and "goes to QA", and every routing file uses them.
- Under `/po-drive`, the QA stage of a lane does not depend on its track (`method/commands/po-drive.md:96` has no track condition), so a flow-track lane already gets QA. Only `/po-flow` run alone has no QA (`method/commands/po-orchestrator.md:41`). That is why AC3 belongs in `/po-flow` and not in `method/agents/planner.md`, which is not owned.
- Unowned files already read `Surface` in their own words and agree with ADR-0054: `method/commands/po-qa.md:26-27`, `method/agents/qa.md:30-32`, `method/skills/qa-drivers/SKILL.md:20`. They stay untouched.

## Story
Make `/po-drive`, `/po-orchestrator`, `/po-flow`, `/po-status` and the review read the story's `Surface` line, so design and QA apply to the right stories without guessing from the text. Acceptance criteria: `design_follows_a_screen_surface`, `qa_follows_the_qa_stage`, `flow_escalates_a_surface_with_qa`, `review_requires_qa_for_a_surface`, `plan_names_scene_viewpoints`, `rules_speak_of_surfaces` (`docs/stories.md:1238-1243`).

## Current code
Routing phrases today, by file:
- `method/AGENTS.md:34` Design row "(stories with a screen)"; `:37` QA row "(stories with a screen, when `QA stage` is `screens`)"; `:43` orchestrator "adding design when the story has a screen"; `:64` QA current gate guards "the review of a story with a screen, when `QA stage` is `screens`"; `:81` "the design of a story with a screen (`docs/designs/<id>/`)" (frozen by `tests/wiring.test.sh:82`).
- `method/commands/po-drive.md:14` reads `QA stage`; `:24-25` Checks: "`QA stage` missing → only the lanes of stories whose text shows a screen stop"; resuming table `:51` design row "the story has a screen", `:53-55` three QA rows "the story has a screen, `QA stage` is `screens`"; wave `:94` design item "for a story whose text shows a screen", `:96` QA item "for a story whose text shows a screen when `QA stage` is `screens`" ending "A story without a screen, or `QA stage: —`, dispatches no qa."
- `method/commands/po-orchestrator.md:33` "A story whose text shows a screen also needs ... `docs/design-system.md`"; `:41` "A story whose text shows a new screen takes the full track ... With `QA stage: screens`, any story whose text shows a screen takes the full track too, because `/po-flow` runs no QA."; `:49` Stage 3 "Only for a story with a screen"; `:63` Stage 6 "Only for a story whose text shows a screen when `QA stage` is `screens`; ... `QA stage` missing for such a story → stop and name the setting."
- `method/commands/po-flow.md:14` Reads settings, without `QA stage`; `:35-45` `## Escalation signals`: five signals including "a new screen" (`:39`), checked before and after reading the code, then "A story that needs more than about six tasks escalates the same way." (`:45`).
- `method/commands/po-status.md:11` reads `QA stage`; `:29` QA bullet "for a story with a screen when `QA stage` is `screens` ... `QA stage` unset → shown as unset for a screen story, never guessed"; `:39` Next "design (`/po-design <id>`, a story with a screen)" and "for a screen story under `QA stage: screens`".
- `method/skills/review-antihallu/SKILL.md:28` step 1 "For a story with a screen, when `QA stage` is `screens`: run `po-gate qa-current <id>` ... With `QA stage: —`, or no screen, there is no QA to require."; nothing about the QA report's `## Not seen`.
- `method/agents/reviewer.md:25` reads design system "When the story has a screen", QA report "when `QA stage` is `screens`"; `:30` judges a screen story against `docs/design-system.md` via `design-doctrine`; nothing on `scene`; `:49` "Not verified" duty, no link to the QA report.
- `method/agents/implementer.md:24` expected `docs/designs/<id>/` "for a story with a screen" (frozen by `tests/design-handoff.test.sh:13`); `:37` "That holds when `QA stage` is `—`. When `QA stage` is `screens`, the walk of the screen belongs to the QA stage: `/po-qa` runs after your commit ... name in your final message the screens it should walk."
- `method/templates/review.md:24` box "`po-gate qa-current <id>` (screen, `QA stage: screens`) → <... | not required: no screen or `QA stage: —`>"; `:55` `## Not verified`.
- `method/templates/plan.md:11,15,21` and `method/templates/plan-flow.md:26,32,35`: `## Tasks`, `## Run interdicts`, `## Files touched`; no section for scene viewpoints.
- `method/commands/po-help.md:28` design "pour une story avec écran"; `:31` QA "pour une story avec écran : un agent parcourt en navigateur les écrans touchés ... quand `QA stage` vaut `screens`"; `:36` orchestrator "ajoute le design et la QA pour une story avec écran".
- `README.md:28` Design row "(story avec écran)"; `:31` QA row "(story avec écran, `QA stage: screens`) | `/po-qa` | les écrans parcourus en navigateur, ..."; `:37` "lancent eux-mêmes la QA d'une story avec écran ; une revue bloquée par la QA repart vers `/po-qa` sans consommer de fix run."

## Attachment points
- Definitions: `method/AGENTS.md`, `### Per story`, a paragraph after the table (`:39`) and before the short-track paragraph (`:41`).
- `/po-flow`: `## Escalation signals`, after `:45`; `Reads settings` line `:14`.
- Plan templates: a new `## Scene viewpoints` section between `## Tasks` and `## Run interdicts`. s87 (`docs/stories.md:1327`) will have its scene driver capture "les points de vue que le plan nomme", so this heading becomes its contract.

## Verified interfaces
- `QA stage` values: `screens` · `surfaces` · `—` (`method/templates/agents-local.md:54`).
- `Surface` line: `- **Surface**: <value>` in the template (`method/templates/stories.md:12`). Polype's own stories write `- **Surface** : —`, with a French space (`docs/stories.md:1234`). The rule therefore says "its `Surface` line", never an exact prefix.
- QA report section for what was not seen: `## Not seen` (`method/templates/qa.md:27`).
- Test helpers: `contains`, `require_file`, `fail`, `settings_read_by`, `frontmatter` (`tests/lib.sh:13,37,43`). `section_of` is redefined per test file (`tests/qa-fleet.test.sh:12`).
- An ADR the diff adds is in scope without `Owns` only if the plan names it (`method/skills/review-antihallu/SKILL.md:19`).

## Traps
- Frozen phrases that must change with their clause (all owned):
  - `tests/qa-fleet.test.sh:39` (orch Stage 6 '`QA stage` is `screens`'), `:57` (drive QA item, same), `:63` (drive Checks "whose text shows a screen stop"), `:89` (status "for a screen story"), `:96-97` (help), `:100` (README QA row regex);
  - `tests/qa-gate.test.sh:100` (AGENTS /po-qa row '`QA stage` is `screens`'), `:126` (implementer);
  - `tests/fleet-design.test.sh:56` (drive design item).
- Phrases that must survive word for word:
  - `tests/qa-fleet.test.sh:40-42` (Stage 6 sentences); `:58-61` (drive QA item); `:71-72` and `:177-179`, the resuming-row tails '`QA status:` of `docs/qa/<id>/report.md` is `blocked` | a human', 'refuses a report that `is current but` not committed | the evidence commit of `/po-qa`, without a new walk', '`po-gate qa-current <id>` fails | the QA stage';
  - `tests/qa-fleet.test.sh:43` 'because `/po-flow` runs no QA' in Stage 1; `:105` README 'une revue bloquée par la QA repart vers `/po-qa` sans consommer de fix run';
  - `tests/qa-gate.test.sh:116-118` review-antihallu sentences; `:125` implementer '**If a task produces a screen, open it in a browser before you finish**';
  - `tests/design-handoff.test.sh:13,17`; `tests/wiring.test.sh:82`;
  - `tests/flow.test.sh:38-48` the five signals and 'a new screen'.
- `tests/flow.test.sh:78-81`, `tests/plan.test.sh:14-16` and `tests/planner.test.sh:14-17` check headings of the plan templates: add a section, rename none (story note, `docs/stories.md:1245`).
- `method/agents/planner.md:32,39` says "Five signals"; it is not owned. The QA escalation must therefore not become a sixth signal: it goes in as a sentence like the "six tasks" one.
- `tests/qa-fleet.test.sh:144-148` checks every `Next action:`+`/po-qa` line of six commands also carries `Review status: blocked`. New text must not pair those two without it.
- `tests/overlap.test.sh` (ADR-0006): new method text in our own words.
- Root `AGENTS.md`, `.claude/`, `.polype/` are installed copies: never edited by the story.
- No migration, no dependency.

## Open questions
- Should `/po-status` show the story's surface as a column? The plan says no: AC2 asks only that the QA routing agree. It would also widen a table that `tests/qa-fleet.test.sh:90` freezes.
- Is a `scene` story without `QA stage: surfaces` judged against its viewpoints with no captures? The plan says yes: the reviewer reads the code against the viewpoints, and puts each viewpoint it could not see under `## Not verified`.

## Complexity
Story 4 → 4. About 13 files are touched in wording only, plus 3 existing tests and one new test file. The risk is the one the story names, the routing rule diverging across files. ADR-0058 lowers it, and the new test checks that the old formulas are gone.

## Split
Not needed (score 4).
