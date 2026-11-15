# Review — s184-session-shows-what-waits

[Story](../stories.md) · [Plan](../plans/s184-session-shows-what-waits.md) · [Verification](../verif/s184-session-shows-what-waits.md)

Method version: 0.3.1

Diff reviewed: `git diff main...story/s184-session-shows-what-waits`, read in a context that did not write it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: df65896f4389ab4fe167ddd2caf868ed053ecaa9

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-only main...story/s184-session-shows-what-waits` and checked each path against the story's `Owns` (`docs/stories.md:2975`).
- [x] Every path is inside `Owns`. `bin/polype`, `docs/interface-agent.md`, `docs/reviews/stories.md`, `method/hooks/po-session.sh`, `po/Cargo.toml`, `po/Cargo.lock`, `po/src/{context,run,state}/` and the three test files are all listed. The added ADR-0126 sits under `docs/decisions/`, which `Owns` lists, and the plan names it. The research, plan and verification files are pipeline evidence.
- [x] Nothing is outside `Owns`.
- [x] No path is inside another running story's `Owns`. The only other worktree, `.claude/worktrees/framing-m22`, is on `fix/qa-deadline-wording` and is not a story lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s184-session-shows-what-waits` exits 0, so I reused the record. `bash tests/run.sh` exited 0 on tree fa0db47…, whose code outside `docs/` matches `Tree: 9b347a0…`. The project has no type check (`Typecheck: —`). I read the record's "Not proven here" and carried it into `## Not verified`.
- [x] `po-gate qa-current` is not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 6 are all present, and I found no change the plan did not ask for.
  - Task 1: `Inbox::answered_not_consumed` in `po/src/context/mod.rs`, used by `run`.
  - Task 2: the `answered` field comes right after `waiting`.
  - Task 3: the hook's `W` lines show ids only, and the `P` line follows `Lanes in flight`.
  - Task 4: two oracle edits, both declared under `## Oracle changes`.
  - Task 5: `docs/reviews/stories.md` is a byte copy of `stories-m22.md`, checked with `cmp`.
  - Task 6: the interface bullet and sample are added, and the version moves to 0.4.0 in all three places.
- [x] Each run interdict holds:
  - `method/AGENTS.md`, `method/commands/`, `method/templates/`, `.polype/` and `.claude/` are not in the diff.
  - `po/src/context/framing.rs` is unchanged.
  - `po/src/inbox/` is unchanged.
  - No `docs/reviews/stories-m*.md` changed, and no `docs/architecture.md` was written.
  - `"contract"` stays 1.
  - No jq path in the hook reads `.question`, `.context` or `.options`. The hook prints ids only.
  - The test fixtures are synthetic (`d-000N` and a witness string). None copies a real decision.

## References
- [x] Every import, call, API and configuration key exists as used:
  - `Decision.status` and `Decision.consumed` exist, and decisions come sorted by id (`po/src/inbox/decision.rs`, per the research; the `Inbox.decisions` doc says "In id order").
  - `Inbox` is reachable from `Context.inbox`.
  - The `run::command` change is a one-to-one swap of the old predicate.
  - The jq `.answered` and `.waiting` paths match the serialised field names.
- [x] No value only looks right:
  - 0.3.2 → 0.4.0 is a minor step.
  - The contract rule in `docs/interface-agent.md:30` lets a new field keep `contract: 1`.
  - `answered` is `null` exactly when `waiting` is, because both derive from `context.inbox`.

## Rules
- [x] `AGENTS.md` conventions are respected, with one framing-file routing gap, listed as a minor finding.
- [x] No accepted ADR is contradicted. ADR-0126 is `accepted` and the plan follows its options 1-B and 2-A.

## Tests
- Oracle: `po-gate oracle-intact s184-session-shows-what-waits` → exit 0
- [x] Floor: `po-gate floor-guard s184-session-shows-what-waits main` exits 0, so nothing was lowered. `po-gate oracle-intact` also exits 0. Both oracle edits to earlier stories' files are declared and judged:
  - `tests/verbs-read-project-context.oracle.test.sh` only drops the new `.answered` field from a whole-object pin.
  - `tests/state-carries-session-lines.oracle.test.sh` mirrors the new waiting lines.
  - Neither weakens the criterion its test holds.
- [x] The assertions pin the acceptance criteria, and none of the six empty test shapes appears:
  - The real hook runs against the real built `po`.
  - The sensitive witness text is checked to be absent.
  - Consumed decisions are excluded.
  - The `nothing` and `none` cases are covered.
- [x] There are 5 new tests, within `Test budget` 25.
- [x] Bite 1: I removed the hook's `(.waiting // [])[]` W line. 1 test failed (`session_lists_pending_decisions`). Undone, and `git diff --exit-code method/hooks/po-session.sh` is clean.
- [x] Bite 2: I dropped `&& d.consumed.is_none()` from `Inbox::answered_not_consumed`. 2 tests failed (`session_counts_answered_not_consumed` and `consumed_answer_is_nothing_to_do` in `run-from-outside.test.sh`). Undone, `git diff --exit-code po/src/context/mod.rs` is clean, and `po` was rebuilt from the committed sources.
- [x] The story made no test useless.

## Neighbours
- [x] I read the callers of the changed code, and nothing is broken:
  - `po run` (`run/mod.rs`) uses the shared predicate.
  - `tests/commands-read-po-state.oracle.test.sh:95-96` uses a stub state with no `answered`: the hook prints `not read by po` on a line that does not start with `- `, so the count of 7 holds. The record's suite and my focused runs pass.
  - The other readers of `.waiting` are tests only.
  - `po inbox --answered` keeps its own copy of the predicate (`po/src/inbox/mod.rs:179`). It is out of `Owns`, and the plan keeps it on purpose.

## Lenses
Lenses run: dependencies (triggered by `po/Cargo.lock` and `po/Cargo.toml`: only the `po` package's own version moved, no dependency entry was added, removed or bumped). Security and migration have no path or content trigger. Performance did not run because there is no server-side code.
- [x] The lens found nothing.

## Findings
- minor — docs/reviews/stories.md:1 — Law 6 of `AGENTS.md` lists `docs/reviews/stories.md` among the framing files that "reach `Target branch` through a framing pull request". This story lands it on its own branch instead. This is not the implementer's breach: the story's `Owns` lists the file, and ADR-0126 option 1-B chose it. But ADR-0126 does not say that this copy is an exception to the framing-PR route. Under 2-A it sends `docs/architecture.md` through a separate framing PR, so the two files take two different routes.
- minor — docs/decisions/ADR-0126-un-depot-cadre-a-la-main-lit-son-cadrage-par-les-fichiers-de-la-loi-6.md:5 — The frontmatter has `date: 2026-11-15`, but `## Decision Outcome` and the plan say the owner chose 1-B and 2-A on 2026-11-16 (d-0030, d-0031). Since the status is `accepted`, the date should be the day of acceptance.

## Not verified
- The forge `suite` check on the pull request, where `bin/po-version-check` compares against `origin/main`. Locally the record's suite saw `main`'s HEAD (per its "Not proven here"). A person should confirm the required forge check is green on the PR.
- `po state` at this repository's root reading `stories-review: yes`. `on_target` reads `main`, so this can only be seen after the ship. The oracle proves it on a scratch copy of the working-tree files. After the merge, run `po state` at the root and confirm.
- The installed `.polype/hooks/po-session.sh` is unchanged by design. This repository's own session start will show the new lines only after `polype update .` refreshes the copies.
- The hook against this repository's real decision inbox. I deliberately did not run it, to avoid reading real (possibly sensitive) decisions. It is covered only by synthetic fixtures.
- The `docs/interface-agent.md` bullet and sample for `answered` were judged by reading only. No script reads them.
- I did not rerun the full unit suite. I relied on the record's passing run on the same code. I ran only the focused test files for the bites.

Max severity: minor
Ship allowed: yes
