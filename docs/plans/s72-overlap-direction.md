---
track: flow
validated: yes
---
# Plan (short track) — s72-overlap-direction

Written by the planner on the short track (`Story track: auto`, complexity 2 ≤ `Flow threshold` 2). This one file stands in for the research and the plan: there is no `docs/research/s72-overlap-direction.md`. Validated autonomously (`Plan validation: autonomous`): no human reviewed it.

## Verified facts
**Story assumption that proved wrong (read first).** Criterion `every_overlap_text_cites_the_rule` asks `method/AGENTS.md` to cite the rule *instead of* "sharing a path". The sentence `two stories sharing one of those paths never run at once` (`method/AGENTS.md:51`) is pinned by `tests/fleet-wiring.test.sh:42`, which is outside this story's `Owns`; `po-bounds` lets the implementer write only `docs/` and `Owns` (`method/hooks/po-bounds.sh:5-8`), so that test cannot be updated. Resolution: keep the pinned clause and add a sentence that defines "sharing" by the overlap rule. The citation is added; the word "sharing" stays in that one file. Replacing it outright would need `tests/fleet-wiring.test.sh` added to the story's `Owns`.

- `method/skills/review-antihallu/SKILL.md:11` holds the rule sentence (`… when in doubt, they overlap.`) then `It holds for both cases below, a real diff path being an entry with no glob; see the examples of check 8 of the \`stories-review\` skill.` That second sentence is the s69 review's major (`docs/reviews/s69-owns-overlap-globs.md`, Findings): doubt passes an uncertain diff path as inside `Owns`.
- Exact matching of one path against one entry exists: `entry_matches` in `method/hooks/po-bounds.sh:185-214` (file entry equal, folder entry `x/` covers `x` and beneath, glob segment by segment, `*` within a segment, `**` across segments).
- ADR-0046 (`docs/decisions/ADR-0046-…md`, Considered Options) already says the review compares only a real diff path against an entry, the entry-against-entry work being `/po-drive`'s and the stories review's. The fix aligns with it: no new ADR (reserved ADR-0048 stays unused).
- `method/skills/review-antihallu/SKILL.md:13-14`: the two cases, `**Outside \`Owns\` → major.**` (pinned by `tests/ownership.test.sh:24,83`) and `**Inside another running story's \`Owns\` → critical.**`.
- `tests/owns-overlap.test.sh:9,20,37` pins the full rule sentence and the citation `the examples of check 8 of the \`stories-review\` skill` in the antihallu scope section: both must survive.
- `method/commands/po-drive.md:40` (ready set) already names `the two entries that overlapped and one path matching both`. `:139` (Report: `the stories dropped for a conflict with the path that collided`) and `:147` (status: `an \`Owns\` collision with the path that collided and the lane holding it`) do not. `:147`'s phrase is pinned by `tests/resume.test.sh:57`; `:40`'s `named in the report with the path that collided` by `tests/drive.test.sh:28`.
- Texts that say "share a path" without the rule: `method/commands/po-stories.md:42` (`two stories sharing a path depend on one another`), `method/templates/stories.md:12` (`stories sharing a path never run at the same time`), `method/templates/stories-review.md:30` (`no path shared by two stories with no dependency between them`), `method/AGENTS.md:51`. `method/commands/po-status.md:36` says `an \`Owns\` collision, with the path that collided and the lane holding it` (pinned only on `an \`Owns\` collision`, `tests/fleet-wiring.test.sh:73`).
- `method/templates/stories.md:12` also holds two pinned clauses (`tests/stories.test.sh:75-76`): the syntax clause and `any other text on the line is refused`.
- `method/skills/stories-review/SKILL.md:27`, "How to decide": the clause `or a plain name that the other's \`*\` segment cannot take (\`a.ts\` against \`*.md\`)` has no verb (s69 review, minor). `:25` holds `share an \`Owns\` path`, pinned by `tests/stories-review.test.sh:34`, and not named by criterion 3: left as is.
- Test helpers: `require_file`, `fail`, `$METHOD` (`tests/lib.sh`, `tests/run.sh`); `tests/owns-overlap.test.sh:12-13` defines `section_of` and `holds` locally.

## Escalation signals
| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text: method text only | absent — every owned file is markdown or a bash text test |
| New screen | absent — story text | absent — no UI in Polype's `method/` |
| Authorization or tenant scope | absent — story text | absent — the review scope check is wording; `po-bounds.sh` is not touched |
| API contract | absent — story text | absent — no command arguments or file formats change; `templates/review.md` unchanged |
| New dependency | absent — story text | absent — tests use only `grep`/`awk` already in `tests/owns-overlap.test.sh` |

## Story
As a developer I want the review to match a diff path exactly against `Owns` and every method text to cite the same overlap rule, so that doubt never lets an out-of-scope path through. Criteria: `diff_paths_match_owns_exactly`, `drive_reports_name_the_entries`, `every_overlap_text_cites_the_rule`, `how_to_decide_reads_as_a_sentence`.

## Tasks
Citation phrase used everywhere below, verbatim: `the overlap rule of check 8 of the \`stories-review\` skill` (called CITE2).

1. [x] **Review direction** — `method/skills/review-antihallu/SKILL.md:11`: keep the rule sentence untouched; replace only the sentence `It holds for both cases below, a real diff path being an entry with no glob; see …` with:
   > A diff path is matched exactly against the entries of its own story, as `po-bounds` matches them: it is inside `Owns` when it equals a file entry, lies beneath a folder entry or fits a glob segment by segment, and outside `Owns` when no entry covers it. The doubt clause of the rule serves only the check against another story's `Owns` and the comparison of two entries; see the examples of check 8 of the `stories-review` skill.
   Test: `test_diff_paths_match_owns_exactly` fails if the exact-match sentence or the doubt-scope sentence is missing, or if `It holds for both cases below` is still there.
2. [x] **Drive reports** — `method/commands/po-drive.md`, `## Report`: line 139 becomes `Then the stories dropped for a conflict, each with the path that collided and the lane holding it, plus the two entries that overlapped and one path matching both; the lanes handed to a human; and the dependencies still blocking.`; line 147 keeps `an \`Owns\` collision with the path that collided and the lane holding it` and appends `, plus the two entries that overlapped and one path matching both` before the next item. Test: `test_drive_reports_name_the_entries` fails if a Report line holding `the path that collided` lacks `the two entries that overlapped and one path matching both`, or if fewer than two such lines exist.
3. [x] **Citations** — exact new wording:
   - `method/AGENTS.md:51`: after `— the second waits for the first to ship.` add `Two stories share a path when an \`Owns\` entry of one overlaps an entry of the other, by the overlap rule of check 8 of the \`stories-review\` skill.` (pinned clause kept).
   - `method/commands/po-stories.md:42`: `- [ ] Every story declares Owns, and two stories whose \`Owns\` entries overlap, by the overlap rule of check 8 of the \`stories-review\` skill, depend on one another.`
   - `method/commands/po-status.md:36`: `an \`Owns\` collision, with the path that collided, the lane holding it, and the two entries that overlapped by the overlap rule of check 8 of the \`stories-review\` skill with one path matching both;`
   - `method/templates/stories.md:12`: replace `stories sharing a path never run at the same time` with `stories whose entries overlap, by the overlap rule of check 8 of the \`stories-review\` skill, never run at the same time`.
   - `method/templates/stories-review.md:30`: `- [ ] Owns: every story declares one; no two stories with no dependency between them hold entries that overlap by the overlap rule of check 8 of the \`stories-review\` skill`
   Test: `test_every_overlap_text_cites_the_rule` fails if any of the five files lacks CITE2, or if `po-stories.md`, `templates/stories.md` or `templates/stories-review.md` still holds `sharing a path` or `no path shared` (`method/AGENTS.md` is exempt: its pinned clause stays and its new sentence says "share a path" on purpose).
4. [x] **Grammar** — `method/skills/stories-review/SKILL.md:27`: the disjoint sentence becomes `They are **disjoint** only when, before either has reached a \`**\`, one of these holds: two segments at the same position are different plain names; a plain name meets a \`*\` segment that cannot take it (\`a.ts\` against \`*.md\`); or one entry ends without \`/\` while the other must go deeper.` Rest of the paragraph and the table untouched. Test: `test_how_to_decide_reads_as_a_sentence` fails if check 8 lacks `one of these holds: two segments at the same position are different plain names;` or `a plain name meets a \`*\` segment that cannot take it`, or still holds `or a plain name that the other`.
5. [x] **Tests and runs** — add the four functions above to `tests/owns-overlap.test.sh` (header comment may gain `s72`), reusing its `section_of`/`holds` and the check-8 `awk` extraction; run `bash tests/run.sh owns-overlap.test.sh`, then the full suite once through `po-run --story s72-overlap-direction --label test -- 'bash tests/run.sh'`.

## Run interdicts
- Empty diff for `tests/fleet-wiring.test.sh`, `tests/resume.test.sh`, `tests/drive.test.sh`, `tests/ownership.test.sh`, `tests/stories.test.sh`, `tests/stories-review.test.sh`, `method/templates/review.md`, `method/hooks/`, `.claude/`, `.polype/`, `docs/parite-killer-saas.md`, `docs/decisions/`.
- The two existing functions of `tests/owns-overlap.test.sh` keep their bodies; the rule sentence and the citation `the examples of check 8 of the \`stories-review\` skill` stay in `review-antihallu` and `po-drive`'s ready set.
- No example of the check-8 table (`crates/*/Cargo.toml`, `src/a/*.ts`) copied into any other `method/` file.
- `stories-review` check 8 line `Two stories with no dependency between them that share an \`Owns\` path are flagged as critical…` unchanged (pinned outside `Owns`).
- `po-drive.md` lines outside `## Report` unchanged; `method/AGENTS.md` changed only on the `**\`Owns\` bounds a lane**` line.
- No ADR written (ADR-0048 unused).

## Files touched
`method/skills/review-antihallu/SKILL.md`, `method/commands/po-drive.md`, `method/AGENTS.md`, `method/commands/po-stories.md`, `method/commands/po-status.md`, `method/templates/stories.md`, `method/templates/stories-review.md`, `method/skills/stories-review/SKILL.md`, `tests/owns-overlap.test.sh`, plus this plan and `docs/verif/s72-overlap-direction.md`.

## Test strategy
Four bash text tests, one per criterion, in `tests/owns-overlap.test.sh` (the story's own test file); total for the file six, well within `Test budget` 25. Each pins a short exact phrase of the new text in the section where it must live, and the three that fix a wrong wording also assert the old wording is gone, so reverting a task fails its test. Neighbour tests that pin the kept clauses (`fleet-wiring`, `resume`, `drive`, `ownership`, `stories`, `stories-review`, `overlap`) prove nothing was broken through the full suite run once at the end. Whether agents now apply exact matching on real diffs is not provable by a text test.

## Done when
All tasks ticked; `bash tests/run.sh` green through `po-run`; one commit on `story/s72-overlap-direction` with this plan and the record; a review with no open critical finding.
