# Review — s186-stale-decisions-are-flagged

[Story](../stories.md) · [Plan](../plans/s186-stale-decisions-are-flagged.md) · [Verification](../verif/s186-stale-decisions-are-flagged.md)

Method version: 0.3.1

Diff reviewed: `git diff main...story/s186-stale-decisions-are-flagged`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 5bddd65dffe26784d5d68d43b5fd011411758103

## Ownership
Diff listed with `git diff --name-only main...story/s186-stale-decisions-are-flagged`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. The code and test paths match these entries: `po/src/inbox/`, `po/src/state/`, `po/src/record/security.rs`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, `tests/verbs-read-project-context.oracle.test.sh` and both `tests/stale-decisions-are-flagged.*`. The research, plan and verif files are pipeline evidence. ADR-0127 is added (status `A`) under `docs/decisions/`, the plan names it, and `docs/decisions/` is also in `Owns`.
- [x] No path outside `Owns`.
- [x] No path inside another running story's `Owns`. `git worktree list` shows only this story's worktree and `.claude/worktrees/framing-m22` (branch `fix/qa-deadline-wording`, which is not a story branch).
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s186-stale-decisions-are-flagged` exits 0, so the record is reused. `Unit suite` (`bash tests/run.sh`) exited 0 on this code. The project has no `Typecheck` command (`Typecheck: —`). The record's compile check is `cargo build --release --locked` inside `tests/run.sh`. I read the record's "Not proven here" section; its items are carried to Not verified.
- [x] `po-gate qa-current` is not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] All seven tasks are in the diff, and nothing is outside the plan. `story` was added to `NewDecision` and `Decision` (skip when `None`). `is_story_id` and `Decision::stale` were added. `validate` and `write` in `add.rs` were updated, and `security.rs` sets `story: is_story_id(id).then(..)`. The `Shown` wrapper and the `landed()` fallback are in place, and `rewrite` returns the mark but writes `&decision` only (`rewrite.rs:81`). `po state` has `stale`, and the oracle's `del` gains `.stale`. The contract is updated, and the version is 0.6.0 in all three places.
- [x] Each run interdict was checked:
  - The diff of `po/src/next/`, `po/src/context/`, `po/src/output.rs`, `method/`, `tests/fixtures/driver-cases/`, `.claude/` and `.polype/` is empty.
  - `CONTRACT` is untouched.
  - `Decision` has no `stale` field, and the file is written from `Decision` only.
  - `waiting` is still `Vec<String>`.
  - The protected test files are unchanged.
  - The oracle has no rows under `## Oracle changes`, and none are needed.

## References
- [x] Every import, call, API and configuration key was confirmed:
  - `crate::context::Landed`: re-exported at `po/src/context/mod.rs:17`. `Landed::read(&Project, &str)` and `contains` are at `lanes.rs:81,113`.
  - `project.setting` returning `Setting::Value`: `po/src/project.rs:55`.
  - `output::reply` with a `Serialize` body: `po/src/output.rs:32`.
  - `context.landed: Option<Landed>`: `po/src/context/mod.rs:114,148`.
  - `super::Shown` is reached from the child module `rewrite`.
  - `is_story_id` is re-exported `pub(crate)` and used from `record/security.rs`.
- [x] No value only looks right. The story-id form matches what `Landed::read` accepts (`lanes.rs:101-104`). `skip_serializing_if = "std::ops::Not::not"` omits `stale: false`. `stale: null` when the landed set is not read is in the contract and tested.

## Rules
- [x] `AGENTS.md` conventions are respected: comments are in English and sparse, `contract` stays at 1 (d-0012), and the version is bumped as ADR-0122 requires.
- [x] No accepted ADR is contradicted. The code follows ADR-0127: options 1-A and 2-A, as answered in d-0032 and d-0033.

## Tests
- Oracle: `po-gate oracle-intact s186-stale-decisions-are-flagged` → exit 0
- [x] Floor: `po-gate floor-guard s186-stale-decisions-are-flagged main` exits 0, so nothing was lowered. `po-gate oracle-intact` exits 0.
- [x] The assertions pin the acceptance criteria, and none of the six empty test shapes appears. The fixtures are the real `po` binary on real git with real commits that land stories. The test `decision_names_its_origin_story` uses the actual `po record review`, not a hand-made decision.
- [x] Within `Test budget`: 7 new tests (5 oracle + 2 task tests) against a budget of 25.
- [x] Bite, each mutation undone and `git diff --exit-code` clean afterwards:
  1. Disabled the framing guard in `Decision::stale` (`if false && blocks…any(!is_story_id)`): **0 failing tests** (see Findings).
  2. Dropped the non-empty check (`named.peek().is_some() &&`): 1 failing test (`framing_blocks_are_never_stale`, d-0001 marked).
  3. Disabled the `status != "pending"` check: 1 failing test (`answer_on_a_stale_decision_says_so`, mark shown on an answered decision).
  - The `po` binary was rebuilt unmutated afterwards, and `git status --porcelain` is empty.
- [x] No test was made useless.

## Neighbours
- [x] The callers of the changed code were read, and nothing is broken:
  - The two `rewrite` callers (`answer`, `consume`) both adapted.
  - The only `NewDecision` literal outside `add.rs` is in `record/security.rs`, and it was adapted.
  - `po-session.sh` reads `.waiting` and `.answered` as before (`method/hooks/po-session.sh:74-78`) and ignores `stale`.
  - `holding_decision` in `po/src/next/` is untouched, so a stale decision still holds its lanes, as the story requires.

## Lenses
Lenses run: dependencies (`po/Cargo.lock` changed: only `po`'s own version moved, 0.5.0 → 0.6.0, and no third-party entry was added, removed or bumped). Security and performance were not triggered: no auth, URL, upload or webhook content, and no server-side code. Migration was not triggered either.
- [x] The dependencies lens raised no finding.

## Findings
- minor — po/src/inbox/decision.rs:87 — The framing guard of `Decision::stale` (`if blocks.clone().any(|entry| !is_story_id(entry)) { return false; }`) is held by no test. Disabling it fails none of the 5 oracle tests, although the plan's test strategy names this exact mutation as one that turns `framing_blocks_are_never_stale` red.
  - The reason is that the oracle's framing stages (`architecture`, `stories`, `M22 framing`) are never in the landed set anyway, so `landed.contains` already keeps them unmarked.
  - The guard only matters for an entry that is not of story form but that `Landed::contains` still matches through its short form. Example: a `blocks` entry `s178` while a commit `s178: …` exists on `Target branch` (`lanes.rs:116-119`). Without the guard such a decision would be marked stale, against the plan's "conservative by design".
  - The criterion holds today, but a regression on this guard would pass the suite. A test with a bare `s<n>` `blocks` entry next to a matching `s<n>:` commit would make the guard bite.
- minor — docs/decisions/ADR-0127-une-decision-perimee-est-signalee.md:6-7 — The frontmatter carries `accepted:` and `decisions:` keys. `templates/adr.md` does not have them, and no other ADR in `docs/decisions/` uses `decisions:`. This is a harmless difference from the template.

## Not verified
- `contract_says_held_until_consumed`: judged by reading. `docs/interface-agent.md` now says, under `blocks`, that a decision holds the lanes it names until it is consumed, answered or not, stale or not. This fulfils the criterion. No script reads it, so it is a candidate for a `po-eval` control arm (#208).
- The stale mark on a project whose `Target branch` has an `origin/<target>` copy (from the record's "Not proven here"). `Landed::read` is reused unchanged, and the tests land only on the local `main`. To cover it, a person or a later test should land a story only on `origin/main` and check `po inbox`.
- `po-session` does not show the mark (out of `Owns` by the story's notes). It is a known limit, to be filed by the lead.
- A decision the project lead posts by hand without `story` is flagged only through `blocks`. This is a known limit written in the story; no method rule asks the lead to fill the field.
- I did not read the real decision inbox of this repository, as instructed. So I did not confirm the plan's claim that every real `blocks` story entry has the full id form.
- The project has no end-to-end, build, type-check or lint command (`E2E: —`, `Build: —`, `Typecheck: —`), so none was run.
- A pre-existing `dead_code` warning on `output::not_built` (`po/src/output.rs:46`) shows in the build. It is not this diff's, and s187 owns it.

Max severity: minor
Ship allowed: yes
