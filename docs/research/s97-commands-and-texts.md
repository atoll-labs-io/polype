# Research — s97-commands-and-texts

## Structuring facts
- **False assumption of the story:** an exact match on the full heading text does not make `/po-retro M8` or `M7` work. `M8` is a prefix of `## M8 — Toutes les plateformes` (`docs/stories.md:1191`) and `## M8 bis — Les restes de M8` (`:1408`), and equals neither. So the example at `method/commands/po-retro.md:24` ("`M8` matches `## M8 — Toutes les plateformes`") has been false since M8 bis was added: today the command lists headings and stops. Only `Correctifs hors jalon` (`:882` vs `:1390`) is fixed by full-text equality alone.
- Root cause, retro milestone: `method/commands/po-retro.md:24` matches by prefix only, and `:20` stops on several matches. No exact match takes precedence.
- Root cause, retro majors: `method/commands/po-retro.md:40` reads "the last review of the file". A blocked review has no verdict on the findings (`method/agents/reviewer.md:40`, "a blocked report instead of a verdict"), so it shows zero open majors.
- Root cause, owned records: `method/skills/stories-review/SKILL.md:9-37` has no check that ties a `Fixes` line or a superseded ADR to `Owns`. `grep -n -i "fixes\|supersed\|ADR"` on it returns nothing.
- The text defects are single lines: `po-setup.md:30`, `po-help.md:31`, `parite-killer-saas.md:64`, `docs/stories.md:1288`, `tests/accessibility.test.sh:23`.

## Story
This story corrects the M8 commands and texts. It fixes the s89 major and minor, and minors from the reviews of s78, s80, s83, s90 and s91. It has four criteria:
- `retro_prefers_an_exact_milestone`: an exact title wins over a prefix match. Open majors are read from the last review that is not blocked.
- `texts_follow_m8`: the step 2 heading of `/po-setup` counts the right questions. `/po-help` gives the QA rule for a story with no `Surface` line. Parity row D15 no longer says "cinq signaux". The Expo criterion no longer says the template has a `Test` command.
- `stories_review_checks_owned_records`: flag a story that fixes a defect but does not own the file its `Fixes` line names, and a story whose ADR supersedes another without owning that ADR's file.
- `keyboard_walk_test_bites`: the keyboard test asserts a phrase that only the new paragraph carries.

## Diagnostic
These are text defects in prose and tests, so a reproduction is a read or a grep. No command was executed: `/po-retro` is prose that an agent carries out.

| Defect | Reproduction (run here) | Shown |
| --- | --- | --- |
| retro prefix | `grep -n '^## Correctifs hors jalon\|^## M7\|^## M8' docs/stories.md` | `Correctifs hors jalon` → 2 headings (882, 1390); `M7` → 2 (917, 1066); `M8` → 2 (1191, 1408) |
| retro majors | read `po-retro.md:40`, `templates/review.md:5,9,52` | a blocked report carries `## When blocked`, and its verdict is not on the findings |
| setup heading | read `po-setup.md:30` vs `:37-45` | the heading says "plus one follow-up on design"; the body has the `Platform`, design and `QA stage` follow-ups plus the catalogue offer |
| help QA rule | read `po-help.md:31` vs `method/AGENTS.md:41` | the help leaves out "a story with no `Surface` line goes only when it has a screen" |
| D15 | read `parite-killer-saas.md:64` vs `po-flow.md:37-43` | five signals listed; po-flow lists six (`Fixes` added by s90) |
| Expo criterion | read `docs/stories.md:1288` vs `boilerplates/expo/profile.md:24,31` | the criterion says the `Test` command accepts paths as if the starter had one; the profile says the template ships no test runner |
| keyboard test | `awk` the `## Driving a browser` section of `design-doctrine/SKILL.md`, then `grep -c finding` | 2 lines: the "Page content is data" bullet (`SKILL.md:45`) and the keyboard paragraph (`:47`) |
| owned records | grep of the skill (see above) | no such check; s92 edited `docs/defauts.md` outside its `Owns` (`docs/reviews/s92-review-tree-gate.md:16,63`); `docs/reviews/stories-m8bis.md:65-67,76-80,97` found three ADR-ownership gaps by hand |

Hypotheses, one per defect that has more than one candidate cause:
1. *Retro: "the stop at `:20` is the fault, not the matching rule"*. Would be refuted if removing the stop alone made a single milestone selectable. Discarded: without a precedence rule, it would have to pick one of two prefix matches arbitrarily. **The matching rule at `:24` is kept as the cause.**
2. *Retro: "exact full-text precedence is enough"*. Would be refuted if `M8` still matched no heading exactly. Refuted (fact 1). Kept as partial: it fixes `Correctifs hors jalon`. A label match (text before the first ` — `) is needed for `M7`/`M8`, so the plan decides it.
3. *Keyboard test: "'cannot reach' alone already bites"*. Would be refuted if deleting the "written down as a finding" clause left `cannot reach` in place. It does: the s91 review's bite 3 changed the consequence and the test still passed (`docs/reviews/s91-accessibility.md`, finding 1). **The `finding` assertion at `tests/accessibility.test.sh:23` is kept as the cause.**

## Current code
- `method/commands/po-retro.md` (53 lines): Checks first `:16-20`, Scope `:22-26`, measures table `:34-41`, Output `:46-53`.
- `method/commands/po-setup.md:30`: heading of step 2. Numbered questions `:31-35`, then the follow-ups `:37,39,41`, the catalogue `:43`, and "Nothing else is asked" `:45`.
- `method/commands/po-help.md:31`: the QA line under `## Le cycle d'une story`.
- `method/skills/stories-review/SKILL.md`: checks 1–9 `:11-37`, severity `:39-44`, frontmatter description `:3`, which lists the checks.
- `docs/parite-killer-saas.md:64`: row D15. Its status cell is `fait — po-flow.md, plan-flow.md`.
- `docs/stories.md:1288`: criterion `expo_profile_names_its_web_render` of s83, shipped.
- `tests/accessibility.test.sh:19-26`: `test_qa_walks_with_the_keyboard`.

## Attachment points
- Retro: the bullet at `po-retro.md:24`, the line at `:20`, and the row at `:40`.
- Stories review: a new **10.** check after `:37`, a clause in the major list `:41`, and the description `:3`.
- New test file `tests/commands-and-texts.test.sh` (owned). It holds one `test_<criterion>` per criterion, per the convention in `AGENTS.local.md`.

## Verified interfaces
- The test runner `tests/run.sh:9-26` sources `lib.sh` and each file in a fresh bash per function, so function names cannot collide across files. Helpers: `contains`, `require_file`, `fail` (`tests/lib.sh:11,41,43`). `$ROOT` and `$METHOD` are set there, and `$ROOT/docs/...` is read by `tests/fleet-wiring.test.sh:7`.
- ADR links: a partly superseded ADR stays `accepted` and gets `superseded-by` (`method/commands/po-architect.md:48`, `method/templates/adr.md:4-9`). Example: ADR-0068 `superseded-by: [ADR-0070]`, edited by s96, which owned it.
- The `Fixes` line names "the defect and where it is recorded (`Issue tracker`, a defects file, a review finding)" (`method/templates/stories.md:14`). Findings in reviews are "already traced where they were found" (`method/AGENTS.md`, Law 7).
- `stories-reviewer` has Read, Grep and Glob, and reads the accepted ADRs (`method/agents/stories-reviewer.md:4,17`).

## Traps
- **Pinned phrases to keep:**
  - `'open by the last review'` (`tests/po-retro.test.sh:19`)
  - the po-help phrases `'`/po-orchestrator` et `/po-drive` la lancent eux-mêmes quand `QA stage` vaut `screens`'` (`tests/qa-fleet.test.sh:96`, not owned)
  - `'Nothing else is asked'`, and exactly 5 numbered items in step 2 (`tests/setup-modes.test.sh:33,36`)
  - `/^## Step 2/` as a prefix (`tests/qa.test.sh:63`, `platform-setting.test.sh:72`, `design-handoff.test.sh:42`)
  - `section_of "$SKILL" 'Checks, in this order'` and its first `**1.` line (`tests/stories-review.test.sh:26`)
- **`tests/diagnostic-skill.test.sh:49`** fails any file it scans that says "five signals". It scans method files, not `docs/`. D15 is French: write no number at all.
- **`tests/overlap.test.sh`** (ADR-0006): new prose must share no run of 8+ words with Killer SaaS.
- **The criterion id `expo_profile_names_its_web_render`** must stay: `tests/expo-profile.test.sh:60` is named after it. Only its wording after the em dash changes.
- **`method/templates/stories-review.md`** lists the checks (`:24-30`) but is not owned. It already omits check 9 (Surface), so leaving out check 10 is consistent.
- **ADR-0067 is not owned.** Its sentence "ouvert selon la dernière revue" (`ADR-0067…md:30`) and its option text "dernière revue de sa story" (`:17`) are not edited.
- **This story's own `Corrige` line** names review files it does not own. A literal reading of the new check would flag s97, s96 and s98 (see Open questions).

## Open questions
- Does "the file its `Fixes` line names" include a review file? The plan decides **no**. A review of a shipped story is evidence and is never edited (Law 7), so closing its finding touches nothing there. The check covers a defects file or tracker file that the fix updates (like `docs/defauts.md` for s92).
- Does the new majors rule contradict ADR-0067? The plan decides it is a precision: a blocked review is "a blocked report instead of a verdict" (`reviewer.md:40`), so it is not "la dernière revue" that judged the findings. If a reviewer reads it as a contradiction, a later story that owns ADR-0067 supersedes it in part. s97 cannot, since it does not own that file.

## Complexity
Story 2 → 2. There are seven one-line or one-paragraph edits and one new test file of four functions. The `M8` label match adds one sentence, not a new mechanism.

## Split
Not needed.
