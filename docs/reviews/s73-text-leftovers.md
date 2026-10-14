# Review — s73-text-leftovers

[Story](../stories.md) · [Plan](../plans/s73-text-leftovers.md) · [Verification](../verif/s73-text-leftovers.md)

Diff reviewed: `git diff main...story/s73-text-leftovers` (one commit, af1f9cf). I did not write this code. Findings are graded critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: ca7b8bcb15a13d1c9cb57074d70e34f62188575f

## When blocked
Not applicable.

## Ownership
I listed the changed files with `git diff --name-status main...story/s73-text-leftovers` and checked each path against the story's `Owns` line (`docs/stories.md:1118`).
- [x] Every path is inside `Owns`. The changed files are `AGENTS.local.md`, ADR-0024, ADR-0029, ADR-0037 (each named by its exact file), `method/skills/testing-doctrine/SKILL.md` (covered by the `method/skills/testing-doctrine/` folder entry) and `tests/leftovers.test.sh`. `docs/plans/s73-text-leftovers.md` and `docs/verif/s73-text-leftovers.md` are the story's own pipeline evidence. No new ADR was added.
- [x] Nothing is outside `Owns`.
- [x] No overlap with another running story. The only other running lane is `s71-bounds-heredoc-expansion`, which owns `method/hooks/po-bounds.sh` and `tests/bounds.test.sh`. This diff touches neither.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s73-text-leftovers` passed (exit 0), so I reused the record. Its tree is `22d9507…`, status complete, and the declared `Unit suite` (`bash tests/run.sh`) has a `po-run` row with exit 0. The project has no `Typecheck`, `E2E` or `Build` command (`—`), so none was run. The record's "Not proven here" says the same.
- [x] `po-gate qa-current` was not needed: the story has no screen and `QA stage` is `—`.

## Plan
- [x] All five tasks are present, and nothing in the diff falls outside the plan.
- [x] I checked each run interdict:
  - **ADR bodies unchanged:** only three lines changed under `docs/decisions/`, and each is a `superseded-by:` line. No `status:` line changed.
  - **Other ADRs:** no diff on ADR-0034, 0038, 0039, 0041 or 0044, nor on any other ADR. No ADR-0049 was created.
  - **Installed and protected files:** no diff on `AGENTS.md`, `.claude/`, `.polype/`, `bin/polype`, `method/templates/agents-local.md`, `implementer.md` or `po-gate.sh`.
  - **`AGENTS.local.md`:** only the two added lines changed.
  - **Testing doctrine:** only the sentence on line 62 changed.
  - **Existing tests:** none was modified.

## References
- [x] I opened and confirmed every reference:
  - `method/templates/agents-local.md` lines 21 and 78 (`QA stage:          —` and `Dev:               —`, same alignment).
  - `implementer.md:42` (single quotes, inner quote written `'\''`).
  - `po-gate.sh:122-124` (`ql`/`qc` single-quoted hint).
  - The successor ADRs, each in its own words: ADR-0038:14 and ADR-0039:14 ("Ce point d'ADR-0024 est remplacé ici"); ADR-0037:14 ("seule sa conséquence neutre change" about ADR-0029); ADR-0041:35 (it replaces ADR-0037's "Bad" consequence); ADR-0044:7 and :14 (`supersedes: [ADR-0037]`).
- [x] I ran `bash bin/polype check .` in the worktree. It prints `Polype 0.2.0 installed in …`, no `missing setting:` line, and `missing:` only for `.claude/` files, which a worktree does not have.
- [x] About the plan's open question: ADR-0034 extends ADR-0029 (it adds the driver as the committer in a lane) without replacing any of its clauses. Its own text, at :15, :20 and :21, still relies on ADR-0029. Leaving it out of ADR-0029's `superseded-by` is right.
- [x] No value that only looks right.

## Rules
- [x] `AGENTS.md` conventions are respected: tests are bash, one file named for the story, with `test_<criterion>` functions. The method text stays in English.
- [x] No accepted ADR is contradicted. The bodies are untouched, and the story asks for these frontmatter edits explicitly.

## Tests
- [x] Floor: `po-gate floor-guard s73-text-leftovers main` exited 0, so nothing was lowered.
- [x] There are three tests, one per acceptance criterion. None has one of the six empty shapes. The third test runs the real `bin/polype check` and guards against a crashed `check` with the `installed in` check.
- [x] Three tests is well within the `Test budget` of 25.
- [x] Bite: I disabled three rules in turn, ran only `leftovers.test.sh` each time, and confirmed the change was undone with `git diff --exit-code`.
  - ADR-0029 line reset to `superseded-by: []`: `replaced_adrs_point_to_their_successor` failed.
  - `QA stage:` line removed from `AGENTS.local.md`: `polype_declares_every_template_setting` failed.
  - Same removal, with the test's exact-line grep turned off for the run: the test still failed, on the `missing setting: QA stage: —` line from `bin/polype check`. So both halves of that test bite on their own.
  - The doctrine test needs no mutation to prove it: it asserts the single-quoted form is present and the double-quoted form is absent.
- [x] No test is made useless by this story.

## Neighbours
- [x] Searching `method/` turns up no remaining `-- "<command>"` form. `po-run.sh` usage lines and the `po-gate.sh` hint agree with the new doctrine text.
- [x] Nothing in `tests/`, `bin/` or `method/` reads `superseded-by` on these three ADRs. `tests/grouped-validation.test.sh:65-66` only checks ADR-0014.

## Lenses
Lenses run: none. The diff has no auth or route path, no migration, no lockfile or manifest, and no server-side code.

## Findings
- **minor** — `docs/decisions/ADR-0037-qa-current-exige-une-preuve-qa-committee.md:7` (and ADR-0038:7, ADR-0039:7, ADR-0041:7, outside `Owns`): the links now go one way only.
  - The predecessors name their successors, but the successors still say `supersedes: []`. ADR-0044 is the only one that names its predecessor.
  - Partial supersession (`superseded-by` set while `status: accepted`) is a new convention. `method/templates/adr.md` and `method/commands/po-architect.md:48` don't describe it; po-architect.md:48 still pairs `superseded-by` with `status: superseded`.
  - The literal point of s60 m5 ("ADR-0037 … has `supersedes: []`") stays open. A reader of ADR-0029 now gets the link, though.
  - Fix: a later story can add the reverse links and one sentence on partial supersession to the ADR template.
- **minor** — `method/skills/testing-doctrine/SKILL.md:62`: the clause "which writes their row in the verification record" now comes after the inserted appositive and its parenthesis. "Which" reads as if it referred to the argument rather than to `po-run`. Moving the quoting note after the main clause would read more cleanly.

## Not verified
- **The installed copies under `.claude/` and `.polype/`, and the copy of `AGENTS.local.md` inside `AGENTS.md`.** They are refreshed on `main` by a separate commit after ship, as the plan says. Until then, the installed `testing-doctrine` skill (the one loaded into this review) still shows `-- "<command>"`. A person should check that the post-ship refresh commit carries the new line.
- **`polype check` from the repository root.** I ran it only in the worktree, which has no `.claude/`, so its exit status was 1 because of those files. I did not see a clean exit 0 on a full install. A person can run `bash bin/polype check .` at the root after ship and the refresh.
- **The type check, the end-to-end suite and the build.** The project has none of these commands (`—`), so they were not run.
- **The unit suite.** I did not rerun the whole suite. I relied on the record's `po-run` row, which `verif-current` confirmed is on this code (`Verification mode: record`). Only `leftovers.test.sh` was run here, for the bite checks.
- **Successor ADRs written later.** I did not check whether one will replace ADR-0039 (the plan mentions one coming from the s71 lane). That chain continues from ADR-0039 and is outside this diff.

Max severity: minor
Ship allowed: yes
