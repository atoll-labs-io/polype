# Review: s69-owns-overlap-globs

Diff reviewed: `git diff main...story/s69-owns-overlap-globs`, by a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: ed579562d8143d6cd7c2b5112a17b7a05e9e66fd

## When blocked
Not applicable.

## Ownership
I listed the diff with `git diff --name-only main...story/s69-owns-overlap-globs` and checked each path against the story's `Owns`.
- [x] Every path is inside `Owns`. `method/commands/po-drive.md`, `method/skills/stories-review/SKILL.md`, `method/skills/review-antihallu/SKILL.md`, `method/templates/review.md` and `tests/owns-overlap.test.sh` are all listed. The plan and the record are the story's own evidence. `docs/decisions/ADR-0046-le-chevauchement-des-owns-est-une-regle-ecrite-prudente.md` is newly added (status A) and the plan names it, so it is in scope by construction.
- [x] Outside `Owns`: nothing.
- [x] Inside another running story's `Owns`: nothing. `git worktree list` shows only main and this worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s69-owns-overlap-globs` passed (exit 0), so I reused the record. It shows status complete and `bash tests/run.sh` exiting 0. The project has no type-check command (`Typecheck: —`), so none ran. The record's "Not proven here" section says no executable overlap checker exists (ADR-0046) and that whether agents apply the rule correctly is judged at review.
- [x] `po-gate qa-current` was not required: the story has no screen, and `QA stage` is not set to `screens`.

## Plan
- [x] Tasks 1–5 are all present. Nothing in the diff goes beyond the plan.
- [x] I checked each run interdict:
  - The diff does not touch `method/hooks/`, `method/AGENTS.md`, `method/agents/`, `method/templates/stories.md`, `method/templates/stories-review.md`, `method/skills/agentic-stories/`, `po-status.md`, `po-stories.md`, `.claude/` or `.polype/`.
  - `tests/drive.test.sh`, `tests/stories-review.test.sh` and `tests/ownership.test.sh` are unchanged, and the phrases they pin are still present in the edited files.
  - ADR-0046 is the only ADR added. No existing ADR was edited.
  - The examples live in exactly one file of `method/`: the test greps for this, and my mutation M2 below confirms it.
  - `docs/parite-killer-saas.md` was not touched. `overlap.test.sh` is part of the green suite in the record.

## References
- [x] Every reference resolves:
  - Check 8 of `method/skills/stories-review/SKILL.md` exists and holds the rule sentence, the "How to decide" paragraph and the examples table.
  - The `review-antihallu` skill holds the rule sentence that the template's "overlap rule" points to.
  - The test helpers `require_file`, `fail` and `$METHOD` come from `tests/lib.sh` and `tests/run.sh`.
- [x] I checked the glob semantics against `entry_matches` in `method/hooks/po-bounds.sh` (lines 185–214):
  - `*` stays within one segment, `**` spans any number of segments, and `x/` covers everything beneath it.
  - The table's verdicts agree, including `src/*` against `src/a/b.ts` being disjoint.
  - `**/*.md` against `**/*.ts` is marked overlap on purpose. That is the cautious direction ADR-0046 chose and records as its "Bad" consequence.

## Rules
- [x] `AGENTS.md` conventions are respected: method text is in English, the test is in bash with one file per story, and test function names match the criterion names.
- [x] No accepted ADR is contradicted. The glob syntax is still ADR-0038's, and ADR-0046 is followed.

## Tests
- [x] Floor: `po-gate floor-guard s69-owns-overlap-globs main` exited 0. Nothing was lowered.
- [x] The assertions quote the exact rule sentence in each section, the two required examples with their verdicts, the single-location grep and both citation phrases. None of the six tests-that-prove-nothing patterns appears.
- [x] Two tests, within the budget of 25.
- [x] Bite: each mutation was run against only `owns-overlap.test.sh`, then undone and confirmed with `git diff --exit-code`.
  - M1 removed "when in doubt, they overlap" from `review-antihallu`: `overlap_rule_covers_globs` failed (1 failing test).
  - M2 copied the `crates/*/Cargo.toml` example into `po-drive.md`: `overlap_examples_are_written_once` failed (1 failing test).
  - M3 removed the citation from `po-drive.md`: `overlap_examples_are_written_once` failed (1 failing test).
  - The final `git diff --exit-code` over the whole worktree was clean.
- [x] The story makes no existing test useless.

## Neighbours
- [x] Other places that talk about "sharing a path" are `method/AGENTS.md`, `po-stories.md`, `po-status.md` and `templates/stories.md`. They are outside `Owns`, and ADR-0046 lists them on purpose as left for a later story. Inside the owned `po-drive.md`, two places were not updated; see the minor finding below.

## Lenses
Lenses run: none. The diff is markdown method text and one bash text test: no auth, migration, lockfile or server-side code.

## Findings
- **major** — `method/skills/review-antihallu/SKILL.md:11`. The rule sentence, which ends "when in doubt, they overlap", is declared to hold "for both cases below". For the "Outside `Owns` → major" case, "overlap" means "inside `Owns`". So when a reviewer is unsure whether a diff path matches a glob entry, the text tells them to pass the path as in scope. That is the permissive direction, the opposite of the cautious intent in ADR-0046.
  - Why it matters: `po-bounds` guards only Write/Edit, so a path written through Bash relies on this review check.
  - Why it is contained: a concrete path against one entry can always be decided exactly (as `entry_matches` does), so real doubt should be rare.
  - Fix: say that a diff path is matched exactly against the entries, and keep "in doubt → overlap" for the critical check against another story and for entry-against-entry comparisons.
- **minor** — `method/commands/po-drive.md:139` and `:147`. The final report and the `status` answer still describe a conflict only as "the path that collided and the lane holding it". Line 40 now also asks for "the two entries that overlapped and one path matching both", so the three places in one file disagree.
- **minor** — `method/skills/stories-review/SKILL.md:27`, the "How to decide" sentence. The clause "or a plain name that the other's `*` segment cannot take (`a.ts` against `*.md`)" has no verb, so the sentence is ungrammatical. The plan's colon-and-list wording was clearer.

## Not verified
- I did not check that agents apply the segment-by-segment rule correctly on real `Owns` lines. That is the plan's pivot, and only text tests cover it. A person should run `/po-stories-review` and `/po-drive status` on a `docs/stories.md` with glob entries (for example `crates/*/Cargo.toml` next to `crates/core/`) and check that the verdicts are right.
- I did not run the full suite or the pinned neighbour tests myself. I relied on the `po-run` record, which `verif-current` validated for this code.
- I did not check the installed copies under `.claude/` and `.polype/`. By convention they are refreshed after ship; until then, the pipeline running on this repository still uses the old literal wording.
- The other method files that still say "share a path" (`method/AGENTS.md`, `po-stories.md`, `po-status.md`, `templates/stories.md`) were left out on purpose (ADR-0046, outside `Owns`). A later story should align them.

Max severity: major
Ship allowed: yes
