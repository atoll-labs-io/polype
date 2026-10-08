---
validated: yes
---
# Plan — s97-commands-and-texts

Branch `story/s97-commands-and-texts`. Read `docs/research/s97-commands-and-texts.md` first. This plan builds on it and does not repeat it.

## Story
This story brings the commands and texts in line with what M8 left. It is a defect story (`Corrige`): the root causes are written in the research. Criteria:
- `retro_prefers_an_exact_milestone`
- `texts_follow_m8`
- `stories_review_checks_owned_records`
- `keyboard_walk_test_bites`

## Tasks
1. [x] **`/po-retro` milestone matching** (`method/commands/po-retro.md`).
   - Replace the last sentence of the milestone bullet at `:24` with a three-step precedence:
     - (a) a heading whose whole text, after its `#` marks, equals the argument;
     - (b) otherwise, a heading whose label equals it, the label being the text before the first ` — ` (the whole text when there is none);
     - (c) otherwise, a heading whose text starts with it.
   - The first step that matches anything decides. Several matches within that step → list and stop.
   - Keep the example `M8` matches `## M8 — Toutes les plateformes` (true again by its label), and add one showing that an exact title wins over a longer heading that starts with it.
   - At `:20`, reword "matching several headings" to "matching several headings at the first step that matches", so the stop applies only there.
   - Test: `test_retro_prefers_an_exact_milestone` fails if the exact-match sentence is gone or comes after the prefix rule.
2. [x] **`/po-retro` open majors** (`po-retro.md:40`).
   - The row reads the majors under `## Findings` of the last review of the file that is not blocked (`Review status: blocked`).
   - It shows them as "open by the last review that is not blocked". This keeps the pinned substring `open by the last review` (`tests/po-retro.test.sh:19`).
   - A file whose reviews are all blocked gives "no review judged the findings", never zero (same rule as `:44`).
   - Keep the ADR-0067 and Law 3 citations in the row.
   - Test: same function, asserting the "not blocked" clause sits in the `**majors still open**` row.
3. [x] **Stories review: owned records** (`method/skills/stories-review/SKILL.md`). Add check **10. Owned records** after check 9. It has two clauses, worded in the project's terms with no Polype path:
   - **(i) The defect record.** A story with a `Fixes` line (`Corrige` in a French stories file) must own the defects file or tracker file that the line names as the defect's record, since marking the defect fixed edits that file. A review finding named there needs no `Owns` entry: a review is evidence and stays as written (Law 7).
   - **(ii) The superseded ADR.** A story whose text says its ADR supersedes another, wholly or in part, must own that other ADR's file, since its `superseded-by` line changes (`templates/adr.md`).
   - Each breach is **major**: add it to the `major` list of `## Severity`.
   - Append "owned records" to the frontmatter `description` list of checks.
   - Test: `test_stories_review_checks_owned_records`.
4. [x] **Text corrections** (one test, `test_texts_follow_m8`):
   - `method/commands/po-setup.md:30`: heading → `## Step 2 — Five questions, one AskUserQuestion call each, plus the Platform, design and QA stage follow-ups and the catalogue offer`. It stays a `## Step 2` prefix, and the body is untouched.
   - `method/commands/po-help.md:31`: after `(toute surface autre que `—`)`, add `; une story sans ligne `Surface` n'y va que si elle a un écran`. The pinned phrases of `tests/qa-fleet.test.sh:96-97` stay character for character.
   - `docs/parite-killer-saas.md:64` (D15): replace `cinq signaux d'escalade (migration, nouvel écran, authz ou tenant, contrat d'API, nouvelle dépendance)` with `signaux d'escalade (migration, nouvel écran, authz ou tenant, contrat d'API, nouvelle dépendance, défaut à corriger signalé par une ligne `Fixes` ou `Corrige`)`, with no number. The other cells of D15 stay unchanged.
   - `docs/stories.md:1288`: keep the id `expo_profile_names_its_web_render` and everything up to `sert le rendu web de l'app`. Replace `, et sa commande `Test` accepte des chemins.` with `; le gabarit n'a pas de commande de test, et la commande `Test` du profil est celle qu'une première story installe, qui accepte des chemins (ADR-0062, ADR-0069).`
5. [x] **Keyboard test bites** (`tests/accessibility.test.sh:23`).
   - Replace the asserted phrase `'finding'` with `'written down as a finding'`. Only the keyboard paragraph (`design-doctrine/SKILL.md:47`) carries it; `:43` says "is written down, not followed".
   - Edit nothing else in the file. The record says so (changed test, changed clause).
   - Test: `test_keyboard_walk_test_bites` in the new file asserts two things. `tests/accessibility.test.sh` holds `'written down as a finding'` and no longer asserts the bare `'finding'`. In the skill's `## Driving a browser` section, `written down as a finding` sits on exactly one line, the one holding `keyboard alone`.
6. [x] **New test file and runs.**
   - Create `tests/commands-and-texts.test.sh` with the four `test_<criterion>` functions. Use `contains`/`fail` from `tests/lib.sh`, read sections with the same `section_of` awk as `tests/po-retro.test.sh:7`, and read `$ROOT/docs/...` for the two docs files.
   - Run the focused files: `bash tests/run.sh commands-and-texts.test.sh po-retro.test.sh accessibility.test.sh stories-review.test.sh setup-modes.test.sh qa-fleet.test.sh qa.test.sh platform-setting.test.sh design-handoff.test.sh expo-profile.test.sh`.
   - Then run the full suite once through `po-run --story s97-commands-and-texts --label 'Unit suite' -- 'bash tests/run.sh'`. It includes `overlap.test.sh` (ADR-0006).

## Scene viewpoints
—

## Run interdicts
- Empty diff on every ADR under `docs/decisions/`, ADR-0067 included. No ADR is written: reserved ADR-0071 stays unused (see The pivot).
- Empty diff on `method/templates/stories-review.md`, `method/agents/stories-reviewer.md`, `method/AGENTS.md`, `method/commands/po-flow.md`, `boilerplates/`, `tests/qa-fleet.test.sh`, `tests/expo-profile.test.sh`, `tests/diagnostic-skill.test.sh`, `.claude/`, `.polype/`.
- In `docs/stories.md`, only line 1288 changes: no other story, no checkbox, not s97's own text.
- In `docs/parite-killer-saas.md`, only row D15 changes, and its status cell stays `fait — …`.
- In `tests/accessibility.test.sh`, only the phrase on line 23 changes.
- The body of step 2 of `po-setup.md` (`:31-47`) is unchanged: still five numbered questions and `Nothing else is asked`.
- `/po-retro` gains no Write/Edit tool and no `git log` (`tests/po-retro.test.sh:24-30`).
- The new skill text names no Polype-specific path such as `docs/defauts.md`.

## The pivot
This plan rests on three readings. Each can be checked against a written source.

1. **The milestone label step.** The criterion asks only for "exact before prefix". Full-text equality alone leaves `/po-retro M8` stopped, and the command's own example false (research, fact 1). The label step (the text before the first ` — `) is what makes `M8` and `M7` work.
   - **Where it could be wrong:** a project whose milestone headings use another separator gets no label match and falls back to prefix. That is harmless: it is today's behaviour.
   - **Check against:** `docs/stories.md:917,1066,1191,1408`.
2. **"Last review that is not blocked" refines ADR-0067 and does not contradict it.** ADR-0067 says a major is open "quand il figure dans la dernière revue de sa story" (`ADR-0067…md:17`). A blocked review is "a blocked report instead of a verdict" (`method/agents/reviewer.md:40`), so it judged no finding. No ADR is written.
   - **Where it could be wrong:** a reviewer may read "dernière revue" literally. Even so, s97 does not own ADR-0067, so by its own check 10 (ii) it may not supersede it. That would be a later story's job.
3. **The `Fixes` clause excludes review files.** Read literally, "le fichier que sa ligne Fixes désigne" would flag s96, s97 and s98, whose `Corrige` lines name reviews they rightly do not own. The check targets the record the fix edits (the s92 case, `docs/reviews/s92-review-tree-gate.md:16`).
   - **Where it could be wrong:** a project might mark review findings as closed inside the review file. Nothing in the method does that (Law 7), and `templates/review.md` has no closure field.

## Files touched
- `method/commands/po-retro.md`
- `method/commands/po-setup.md`
- `method/commands/po-help.md`
- `method/skills/stories-review/SKILL.md`
- `docs/parite-killer-saas.md`
- `docs/stories.md`
- `tests/accessibility.test.sh`
- `tests/commands-and-texts.test.sh` (new)
- Pipeline evidence: `docs/research/`, `docs/plans/` and `docs/verif/` files for s97

## Test strategy
There are four new functions in `tests/commands-and-texts.test.sh`, one per criterion, and one phrase changes in an existing test. The budget is 25. Each test fails if its rule is deleted:
- **`test_retro_prefers_an_exact_milestone`**:
  - The Scope section holds the whole-text equality sentence, the label sentence and the prefix sentence, and the line of the first precedes the line of the last.
  - The `**majors still open**` row holds `not blocked`.
  - Deleting the precedence, or reverting the row, turns it red.
- **`test_texts_follow_m8`**:
  - The `## Step 2` heading line holds `Platform`, `QA stage` and `catalogue`, and not `plus one follow-up on design`.
  - `po-help.md` holds `une story sans ligne `Surface` n'y va que si elle a un écran`.
  - The `| D15 |` line lacks `cinq signaux` and holds `Fixes`.
  - The `expo_profile_names_its_web_render` line lacks `et sa commande `Test` accepte des chemins` and holds `qu'une première story installe`.
- **`test_stories_review_checks_owned_records`**:
  - The `Checks, in this order` section has a `**10.` line holding `Fixes`, `Owns`, `supersedes` and `superseded-by`.
  - The `## Severity` major line holds the new breach.
  - The skill does not hold `docs/defauts.md`.
- **`test_keyboard_walk_test_bites`**: described in task 5. It guards the guard, because the reviewer's bite on `accessibility.test.sh` is what s91 lacked.

There is no visual check: no screen.

## Done when
- One implementer commit on `story/s97-commands-and-texts`, carrying the code, the tests and the evidence.
- The full suite is green, with a `po-run` row in `docs/verif/s97-commands-and-texts.md`.
- The review has no open critical finding.
- After ship, the installed copies are refreshed by a person (`bin/polype-dev-install .`).
