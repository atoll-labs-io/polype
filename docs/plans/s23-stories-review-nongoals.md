---
track: flow
validated: yes
---
# Plan (short track) — s23-stories-review-nongoals

## Verified facts

- `method/skills/stories-review/SKILL.md:11` (check 1, Coverage) lists, for a brief, « the `## Wedge & non-goals` and each entry of `## Premises` » as items **to cover**. The non-goals are therefore counted as scope to deliver — the defect itself.
- `method/skills/stories-review/SKILL.md:13` (check 2, Graveyard) says « With a brief, there is no graveyard: mark the check as not applicable. » Nothing else in the skill reads the non-goals.
- `method/templates/brief.md:21-25`: the heading `## Wedge & non-goals` holds two different things — one line for the wedge (the capability), then a list « Non-goals, at least three: ». The wedge belongs to coverage, the list belongs to exclusions.
- `method/templates/prd.md:27` holds `## Graveyard`; `method/templates/stories-review.md:19` marks the graveyard check « (PRD only) », so a brief-based review produces no exclusion evidence at all.
- `method/templates/stories-review.md:13-16`: the `## Coverage` section is a table whose source column offers `## Wedge & non-goals`. There is no exclusion section anywhere in the template.
- `method/skills/stories-review/SKILL.md:28` rates « a graveyard feature revived » critical — wording tied to the PRD only.
- `method/skills/agentic-stories/SKILL.md:43-45` (« Scope: core loop and graveyard »), the rule the review points to, already states that with a brief a story serves « the wedge or one of the premises » — the non-goals are not listed as coverable. The review skill contradicts the rule it claims to enforce.
- `tests/stories-review.test.sh:11` defines `section_of <file> <heading>`, used by the existing tests; `tests/lib.sh:43` `contains` is exact and case-sensitive. `$METHOD` is `method/` (`tests/lib.sh:6`).
- `method/commands/po-stories-review.md` needs no change: it delegates the procedure to the skill and the template (line 30). Out of this story's `Owns`.
- `docs/defauts.md:14` carries defect n° 6, status `ouvert`.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text changes prompt files only | absent — the four files are markdown and bash |
| New screen | absent — no interface in the story | absent — no UI code in `method/` or `tests/` |
| Authorization or tenant scope | absent — no actor or permission named | absent — nothing reads roles |
| API contract | absent — no interface between stories | absent — `section_of` stays a test-local helper |
| New dependency | absent — no tool named | absent — bash and grep only, as `tests/lib.sh` already uses |

## Story

The review of the stories must treat a brief's non-goals as a PRD's graveyard: an exclusion list read against every story, never a scope item and never « not applicable ».

Acceptance criteria:
- `stories_review_treats_non_goals_as_the_graveyard` — for a brief, the scope check covers the wedge and the requirements, and the non-goals are checked as an exclusion list, never « not applicable ».
- `stories_review_template_separates_scope_and_exclusions` — the template has a coverage section and an exclusions section, each filled whatever the source.

## Tasks

1. [x] `method/skills/stories-review/SKILL.md`, check 1: for a brief, the coverage list becomes the wedge (the capability of `## Wedge & non-goals`) and each entry of `## Premises`; the non-goals leave coverage and are named as belonging to check 2. — fails `stories_review_treats_non_goals_as_the_graveyard`.
2. [x] Same file, check 2: rename it from « Graveyard » to an exclusions check that always runs — with a PRD, `## Graveyard`; with a brief, the non-goals of `## Wedge & non-goals` — and delete « mark the check as not applicable ». A story that revives an excluded item is critical either way. — fails `stories_review_treats_non_goals_as_the_graveyard`.
3. [x] Same file, `description` frontmatter and the `critical` line of `## Severity`: say « excluded item » (graveyard feature or non-goal) instead of graveyard alone, so the severity scale matches the check. — fails `stories_review_treats_non_goals_as_the_graveyard`.
4. [x] `method/templates/stories-review.md`: drop `## Wedge & non-goals` from the coverage source column in favour of the wedge alone; add a `## Exclusions` section after `## Coverage`, one row per excluded item (item, source section, revived by, revived yes/no), filled whatever the source; in `## Checks`, replace the « (PRD only) » graveyard line with an exclusions line that names both sources. — fails `stories_review_template_separates_scope_and_exclusions`.
5. [x] `tests/stories-review.test.sh`: add the two test functions, each asserting the consequence — the coverage paragraph and the coverage section of the template hold no non-goal, check 2 names both `## Graveyard` and the non-goals, the skill no longer says « not applicable », the template has a non-empty `## Exclusions` table and a checks line free of « PRD only ». — these are the tests themselves.
6. [x] `docs/defauts.md:14`: status of defect n° 6 becomes `corrigé par s23`; touch no other line.

## Run interdicts

- `.claude/` and `.polype/` end with an empty diff: they are installed copies, regenerated by `bin/polype-dev-install`.
- `method/commands/po-stories-review.md`, `method/commands/po-stories.md`, `method/skills/agentic-stories/SKILL.md` end with an empty diff: outside `Owns`.
- No line of `docs/defauts.md` other than line 14 changes.
- Do not run `bin/polype-dev-install`.
- No new test file: the two functions go into `tests/stories-review.test.sh`.

## Files touched

- `method/skills/stories-review/SKILL.md`
- `method/templates/stories-review.md`
- `tests/stories-review.test.sh`
- `docs/defauts.md`

## Test strategy

Two new functions in `tests/stories-review.test.sh` (total for this story: 2, within the budget of 25), at the only layer this repository has for prompt files: exact assertions on the text of the file under test, using `contains`, `section_of` and negative greps. Each one is written so that reverting the corresponding edit turns it red — the negative greps (« not applicable » absent, « non-goal » absent from the coverage paragraph and from the template's coverage section) are what make the old wording fail rather than merely the new wording pass. Run `bash tests/run.sh stories-review.test.sh` during the work, then the full suite `bash tests/run.sh` at the end — `tests/overlap.test.sh` also guards the new prose against Killer SaaS wording.

## Done when

- The two criteria pass, and reverting either edit turns its test red.
- `bash tests/run.sh` is green, every pre-existing test included.
- Defect n° 6 reads `corrigé par s23`.
- One commit on `story/s23-stories-review-nongoals` carrying the plan, the record and the four files.
