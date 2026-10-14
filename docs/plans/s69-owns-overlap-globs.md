---
track: flow
validated: yes
---
# Plan (short track) — s69-owns-overlap-globs

[Story](../stories.md)

Written by the planner on the short track (`Story track: auto`, complexity 2 ≤ `Flow threshold` 2). This one file stands in for both the research and the plan: there is no `docs/research/s69-owns-overlap-globs.md`. Validated autonomously (`Plan validation: autonomous`): no human reviewed it.

## Verified facts
**Story assumption corrected first.** The story says where the rule is checked but not where the examples live, and the natural homes are outside `Owns` (`method/AGENTS.md`, `method/templates/stories.md`). The planner settled it in `docs/decisions/ADR-0046-le-chevauchement-des-owns-est-une-regle-ecrite-prudente.md` (reserved number): one rule sentence repeated in the three checks, examples written only in check 8 of the `stories-review` skill. The implementer commits that ADR unchanged; the review counts it in scope (the plan names it, `method/skills/review-antihallu/SKILL.md:19`).

Glob syntax the rule must follow (s61, ADR-0038):
- An entry is a file path, a folder ending in `/`, or a glob where `*` stays inside one segment and `**` spans any number (`method/templates/stories.md:12`, `method/skills/agentic-stories/SKILL.md:21`).
- `po-bounds.sh` `entry_matches` (`method/hooks/po-bounds.sh:185-214`): a plain entry matches itself exactly; `x/` matches `x` and everything beneath; `*` becomes `[^/]*`; `**` becomes `([^/]+/)*` (zero or more segments), or `.*` when last; a glob ending in `/` also covers everything beneath (`:211`). So `src/*` matches `src/a` but not `src/a/b.ts`. `?`, `[`, `{` are refused (`:170`).

The three checks today, all literal:
- `/po-drive` ready set, clause 3: "its `Owns` paths are disjoint from those of the lanes already running **and** …" (`method/commands/po-drive.md:36`), report names "the path that collided and the lane holding it" (`:38`). `status` repeats it (`:145`).
- Stories review, check 8: "a directory owned by one story covers every path beneath it", and two unrelated stories that "share an `Owns` path" are critical (`method/skills/stories-review/SKILL.md:25`, severity `:28`).
- Review scope check: same directory sentence (`method/skills/review-antihallu/SKILL.md:11`), then outside → major (`:13`), inside another running story's `Owns` → critical (`:14`). Template `## Ownership` (`method/templates/review.md:15-20`) says "each path held against the story's `Owns`".
- The review compares a real diff path to entries (exact, as `po-bounds` does); `/po-drive` and the stories review compare entry to entry, which is where globs make overlap undecided.

Readers and their reach:
- `stories-reviewer` preloads `stories-review`, has Read/Grep/Glob, no shell (`method/agents/stories-reviewer.md:4-8`), and reads only `docs/stories.md`, the scope source, `AGENTS.md`, ADRs (`:17`).
- `reviewer` preloads `review-antihallu` (`method/agents/reviewer.md:6-8`), not `stories-review`. Hence the rule sentence must stand in each file; only the examples are cited.
- `/po-drive` already cites other method files by path (`method/commands/po-drive.md:29`).

Phrases other tests pin, which must survive word for word:
- `tests/drive.test.sh:24`: `its \`Owns\` paths are disjoint from those of the lanes already running **and** from those of the other stories of the batch`; `:27`: `named in the report with the path that collided`.
- `tests/stories-review.test.sh:34`: `Two stories with no dependency between them that share an \`Owns\` path are flagged as critical: run side by side, they would edit the same files.`
- `tests/ownership.test.sh:21-37`: in the review-antihallu scope section, `a directory owned by one story covers every path beneath it`, `**Outside \`Owns\` → major.**`, the critical line, `git worktree list`, …; `:82-87`: the four `- [ ]` boxes of the template's `## Ownership`; `:90-95` the ADR clause.
- `crates/` and `src/a/` appear nowhere in `method/` today (grep), so "written once" is checkable by a grep over `method/`.

## Escalation signals
| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, no data | absent — markdown only (`po-drive.md`, two skills, a template) |
| New screen | absent — story text | absent — no UI in Polype |
| Authorization or tenant scope | absent — story text | absent — `Owns` bounds lanes, not users; `po-bounds.sh` untouched |
| API contract | absent — story text | absent — no format changes; the `Owns` syntax is ADR-0038's, unchanged |
| New dependency | absent — story text | absent — no tool added; no script, by ADR-0046 |

## Story
s69: `/po-drive`, the stories review and the review's ownership check compare `Owns` that hold globs, so two lanes touching the same paths never start together. Criteria: `overlap_rule_covers_globs`, `overlap_examples_are_written_once`.

## The rule (text the tasks write)
Rule sentence, identical in the three files:

> Two `Owns` entries overlap when one path could match both: a folder `x/` covers every path beneath it, `*` matches within one path segment, `**` matches any number of segments; when in doubt, they overlap.

Citation phrase, identical in `po-drive.md` and `review-antihallu`: `the examples of check 8 of the \`stories-review\` skill`.

How to decide (written only in check 8): read a plain folder `x/` as `x/**`; compare the two entries segment by segment from the left. They are **disjoint** only when, before either has reached a `**`: two segments at the same position are different plain names, or a plain name the other's `*` segment cannot take (`a.ts` against `*.md`); or one entry ends without `/` while the other must go deeper. Two segments that both hold `*`, and everything after a `**`, count as overlapping.

Examples table (check 8 only), columns entry, entry, verdict, why:
- `crates/*/Cargo.toml` · `crates/core/` · overlap · `crates/core/Cargo.toml`
- `src/a/*.ts` · `src/b/` · disjoint · `a` against `b`
- `src/*` · `src/a/b.ts` · disjoint · `*` stays in one segment
- `src/**/test.ts` · `src/a/` · overlap · `src/a/test.ts`
- `**/*.md` · `**/*.ts` · overlap · in doubt: nothing is compared after `**`

## Tasks
1. [x] **Check 8 holds the rule and the examples** — `method/skills/stories-review/SKILL.md:25`: keep every sentence of check 8 (the critical sentence word for word), insert the rule sentence after "directories included", then the "How to decide" paragraph and the examples table above. Severity `:28`: "an `Owns` path shared" becomes "two `Owns` entries that overlap", same severity. Tests: `test_overlap_rule_covers_globs`, `test_overlap_examples_are_written_once`; `tests/stories-review.test.sh:34` still green.
2. [x] **The review says the same rule** — `method/skills/review-antihallu/SKILL.md` scope section (`:11`): keep the directory sentence, add the rule sentence and that it holds for the two cases (`:13`, `:14`), a real diff path being an entry with no glob; cite with the citation phrase. `method/templates/review.md:16` becomes "each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill"; the four boxes unchanged. Tests: `test_overlap_rule_covers_globs`; `tests/ownership.test.sh` still green.
3. [x] **The fleet says the same rule** — `method/commands/po-drive.md` `## The ready set`: keep clause 3 word for word, follow the list with the rule sentence and the citation phrase; the dropped-story sentence (`:38`) also names the two entries that overlapped and one path matching both, keeping `named in the report with the path that collided`. Tests: `test_overlap_rule_covers_globs`; `tests/drive.test.sh` still green.
4. [x] **Tests** — new `tests/owns-overlap.test.sh` (header `# s69 — Owns overlap understands globs.`, its own `section_of`/`holds` as in `tests/drive.test.sh:7-10`):
   - `test_overlap_rule_covers_globs`: the exact rule sentence in the `## The ready set` section of `po-drive.md`, in the `**8.` paragraph of `stories-review/SKILL.md`, in the `## Before anything: the diff stays inside \`Owns\`` section of `review-antihallu/SKILL.md`; `overlap rule` in the `## Ownership` section of `templates/review.md`. Deleting the sentence from any one file fails it.
   - `test_overlap_examples_are_written_once`: the check-8 paragraph-plus-table of `stories-review` holds a line with `crates/*/Cargo.toml`, `crates/core/` and `overlap`, and one with `src/a/*.ts`, `src/b/` and `disjoint`; `grep -rlF` over `$METHOD` for `crates/*/Cargo.toml` and for `src/a/*.ts` each lists exactly that one file; the citation phrase stands in the two sections above. Copying an example elsewhere, dropping one, or dropping a citation fails it.
5. [x] **Run** — `bash tests/run.sh owns-overlap.test.sh drive.test.sh stories-review.test.sh ownership.test.sh overlap.test.sh`, then the full suite once through `po-run` (`Test: bash tests/run.sh`).

## Run interdicts
- Empty diff on `method/hooks/`, `method/AGENTS.md`, `method/agents/`, `method/templates/stories.md`, `method/templates/stories-review.md`, `method/skills/agentic-stories/`, `method/commands/po-status.md`, `method/commands/po-stories.md`, and everything under `.claude/` and `.polype/`.
- Existing tests unchanged (`tests/drive.test.sh`, `tests/stories-review.test.sh`, `tests/ownership.test.sh`); every phrase listed under "Phrases other tests pin" still present.
- `docs/decisions/ADR-0046-…md` committed as the planner wrote it; no other ADR added or edited.
- The examples (`crates/*/Cargo.toml`, `src/a/*.ts`) appear in exactly one file of `method/`.
- No sentence of 8+ words taken from Killer SaaS (`tests/overlap.test.sh`); no edit to `docs/parite-killer-saas.md` (the story implements no matrix line).

## Files touched
`method/skills/stories-review/SKILL.md`, `method/skills/review-antihallu/SKILL.md`, `method/templates/review.md`, `method/commands/po-drive.md`, `tests/owns-overlap.test.sh`; plus, written by the planner: this plan and `docs/decisions/ADR-0046-le-chevauchement-des-owns-est-une-regle-ecrite-prudente.md`.

## Test strategy
Two new text tests, one per criterion and named after it, within `Test budget` 25. The clauses are prose read by agents, so a text test quoting the exact rule sentence per file is the layer where the rule lives; each fails when its sentence, an example, or a citation is removed. No executable overlap checker is tested: none exists (ADR-0046).

## The pivot
That a prose rule, applied by agents, is enough (ADR-0046). It is wrong if agents misapply the segment-by-segment test on real `Owns` lines, launching overlapping lanes; then a shell checker usable by `/po-drive` (which has Bash) becomes necessary, the option turned down because the stories reviewer has no shell. The conservative direction ("in doubt, they overlap") limits the cost of a misreading to a wave of waiting.

## Done when
Both criteria hold, `bash tests/run.sh` is green through `po-run`, the record is complete, and one commit carries the plan, the ADR, the record and the edits.
