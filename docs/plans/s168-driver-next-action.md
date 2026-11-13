---
validated: yes
---
# Plan — s168-driver-next-action

[Story](../stories.md) · [Research](../research/s168-driver-next-action.md)

Branch `story/s168-driver-next-action`. Read `docs/research/s168-driver-next-action.md` first; this plan builds on it without repeating it.

## Story
`po next` computes, from files and git only, one action per lane and per ready story (`plan`, `validate-plan`, `design`, `execute`, `qa`, `review`, `fix`, `ship`, `wait`, `ask`) with its reason, and which stories are `ready` or `held` (`dependency`, `owns`, `parallel`, `decision` + `ref`); `po state` carries the same in `lanes[].next`, `ready`, `held`. Seven criteria, all read by a script: each has an oracle test, none is a `po-eval` candidate.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Lane routing (`po/src/next/lane.rs`) | new code on the context: `Lane.stage`, `Lane.blocked_by`, `Landed`, `Stories`, `Inbox` (`po/src/context/mod.rs:96-112`) | nothing in the repository computes an action; the stage and the stops are reused, never recomputed |
| Reading the last `Name:` line of a review, the `- Next action:` line | new 5-line helper in `next/` | `last_value` is private to `po/src/context/lanes.rs:141`, outside `Owns` |
| Running `po-gate qa-current` with its stderr | new helper in `next/`, same shape as `lanes.rs:127-138` (`bash <lane>/.polype/hooks/po-gate.sh`, `GIT_OPTIONAL_LOCKS=0`, stdin null) | `lanes.rs`'s `gate` is private and discards stderr, where "is current but" lives (`method/hooks/po-gate.sh:229`) |
| Git reads in a lane (`log --format=%s <target>..HEAD`) | `project::git(dir, args)` (`po/src/project.rs:20-33`) | — |
| Review order | `std::fs::metadata().modified()` (standard library) | no file records when a review passed (research) |
| `Owns` overlap (`po/src/next/overlap.rs`) | new code, the rule of check 8 of `method/skills/stories-review/SKILL.md` | no implementation exists; ADR-0118 forbids a glob crate |
| `po next`'s project lookup and reply | `Project::find`, `Context::read`, `output::reply`/`error` (`po/src/state/mod.rs:34-51`, `po/src/output.rs:32-44`) | — |

## Acceptance tests
The routing cases are oracle files too: each holds the state and the expected action of one rule.

| Oracle file | cksum |
| --- | --- |
| `tests/driver-next-action.oracle.test.sh` | `663357848 16761` |
| `tests/fixtures/driver-cases/a-wave.cases` | `2186897420 1206` |
| `tests/fixtures/driver-cases/checks.cases` | `2778147785 471` |
| `tests/fixtures/driver-cases/decisions.cases` | `1844296751 1554` |
| `tests/fixtures/driver-cases/ready-set.cases` | `1981898415 4521` |
| `tests/fixtures/driver-cases/resuming.cases` | `2286614019 6631` |
| `tests/fixtures/driver-cases/ships.cases` | `2181180803 2102` |
| `tests/fixtures/driver-cases/verdict.cases` | `4116377603 2181` |

| Criterion | Test |
| --- | --- |
| `next_gives_one_action_per_lane` | `test_next_gives_one_action_per_lane` — five lanes and a ready story: one action each, `po state` (run from a lane) carries the same `lanes[].next`, `ready`, `held` |
| `ready_and_held_say_why` | `test_ready_and_held_say_why` — `po state`: ready in `docs/stories.md` order within `Parallel`; held `dependency`, `owns`, `decision`, `parallel` with their `ref` |
| `every_routing_case_is_a_fixture` | `test_every_routing_case_is_a_fixture` — replays the 54 `case_*` functions of `tests/fixtures/driver-cases/*.cases`, each in a fresh project |
| `blocked_on_shape_asks_and_never_fixes` | `test_blocked_on_shape_asks_and_never_fixes` — both `Next action:` texts `/po-review` writes (`method/commands/po-review.md:42`) give `ask` |
| `fix_loops_stop_at_max_attempts` | `test_fix_loops_stop_at_max_attempts` — `Fix loop` 0, 1, 2 under `Max attempts` 2, then 1 |
| `ships_stay_serial_in_review_order` | `test_ships_stay_serial_in_review_order` — two passing reviews; swapping their times swaps `ship` and `wait` |
| `answered_decision_releases_its_lanes` | `test_answered_decision_releases_its_lanes` — pending → `wait`; answered and consumed → `execute` |

## The output of `po next`
`{"contract": 1, "actions": [{"story", "action", "reason"}…], "ready": [ids], "held": [{"story", "reason", "ref"}…], "warnings": [the context's]}`, exit 0. `actions` holds every lane, then every ready story (`plan`, reason `ready`). `ready`/`held` are those of `po state`. Unreadable inputs (no `Target branch`, no stories, no `Worktree root`) make `actions`, `ready`, `held` `null`; a missing or non-numeric `Parallel` makes `ready` and `held` `null`. Any argument → exit 2 `unknown-option`; outside a project → exit 2 `not-a-project`, as `state` says it.

## Routing — the case table
A lane's action: the first row that holds wins. `id` is the lane's story; files are read in the lane's worktree.

| # | When | Action | Reason |
| --- | --- | --- | --- |
| L1 | `id` landed on `Target branch` (`Landed::contains`) | `ship` | `landed` |
| L2 | a decision with no `consumed` whose `blocks` names `id` (first in id order) | `wait` | `decision <d-id>` |
| L3 | `stage` null: no `.polype/hooks/po-gate.sh` in the lane / otherwise | `ask` | `no po-gate` / `setting unreadable: QA stage` |
| L4 | no `docs/research/<id>.md` and no `docs/plans/<id>.md` | `plan` | `no research` |
| L5 | `blocked_by` `root-cause-not-found` | `ask` | `Root cause: not found` |
| L6 | `blocked_by` `technical-choice` | `ask` | `Technical choice: waiting for a human` |
| L7 | no `docs/plans/<id>.md` | `plan` | `research, no plan` |
| L8 | `stage` `plan`: `Plan validation` `human` / `autonomous` / else | `validate-plan` / `plan` / `ask` | `plan-validated refuses` (else `setting unreadable: Plan validation`) |
| L9 | story has a screen, no `docs/designs/<id>/design.md`: no `docs/design-system.md` in the lane / `Design source` missing or `—` / else | `ask` / `ask` / `design` | `no docs/design-system.md` / `Design source unset` / `no design` |
| L10 | `stage` `execute` | `execute` | `verif-current refuses` |
| L11 | `stage` `qa`: `blocked_by` `qa-blocked` / lane's `po-gate qa-current <id>` stderr holds `is current but` / else | `ask` / `qa` / `qa` | `QA status: blocked` / `QA evidence not committed` / `qa-current refuses` |
| L12 | `stage` `review`, no `docs/reviews/<id>.md` | `review` | `no review` |
| L13 | last `Ship allowed:` is `yes` (the gate refused it, or `stage` would be `ship`) | `review` | `ship-allowed refuses` |
| L14 | no `Ship allowed:` line | `ask` | `review without verdict` |
| L15 | implementer commits (`<Target branch>..HEAD`, subjects other than `<id>: QA evidence`) > last `Fix loop:` + 1 (absent → 0) | `review` | `review judged earlier code` |
| L16 | last `Review status:` `blocked`, last `- Next action:` holds `/po-qa` or `QA evidence`: ≥ 2 `<id>: QA evidence` commits at the tip since the last implementer commit / else | `ask` / `review` | `QA evidence committed twice` / `review waited for QA` |
| L17 | last `Review status:` `blocked`, last `- Next action:` holds `findings-shape` | `ask` | `findings-shape refused` |
| L18 | `Max attempts` not a number / `Fix loop` ≥ `Max attempts` / else | `ask` / `ask` / `fix` | `setting unreadable: Max attempts` / `Max attempts reached` / `Ship allowed: no` |
| L19 | `stage` `ship`, `blocked_by` `merge-waiting` | `wait` | `merge waiting` |
| L20 | `stage` `ship`: the first of the competing lanes by (review file mtime, `docs/stories.md` order) / another | `ship` / `wait` | `ship-allowed passes` / `ships serial: <first id>` |

Competing lanes (L20): `stage` `ship`, not landed, not `merge-waiting`, not held by L2 — all read from the context, no gate run again.

Ready set, per story of `docs/stories.md` in order, skipping landed stories, stories with a lane, and stories whose `story/<id>` an `orphan-worktree` warning names: a dependency not landed → held `dependency`, `ref` the first such; a decision with no `consumed` naming it → `decision`, `ref` its id; an `Owns` entry overlapping a held entry → `owns`, `ref` the holder; no slot left → `parallel`, `ref` null; otherwise ready, and its entries are held from then on. Held entries: every lane's story except landed and `max-attempts` lanes (`po-drive.md:144`), lanes in `docs/stories.md` order, then the ready stories. Slots: `Parallel` minus the lanes that are neither landed, `merge-waiting` nor `max-attempts`. A story with no `Owns` holds and collides with nothing.

Overlap (check 8): a folder `x/` reads `x/**`; segments compared from the left; `**` on either side → overlap; two plain names that differ → disjoint; a plain name against a segment with `*` → disjoint unless the `*` pattern matches it; two `*` segments → go on; one entry ends while the other goes on → disjoint, unless all that remains is `**`; both end → overlap.

### The cases, section by section of `method/commands/po-drive.md`
- **`## The ready set`** (`ready-set.cases`): 01 ready · 02 shipped → neither · 03 dependency · 04 dependency shipped by `s<n>:` · 05 owns, a lane · 06 owns, the batch · 07 `crates/*/Cargo.toml` vs `crates/core/` overlap · 08 `src/a/*.ts` vs `src/b/` disjoint · 09 `src/*` vs `src/a/b.ts` disjoint · 10 `src/**/test.ts` vs `src/a/` overlap · 11 `Parallel` reached · 12 a merge-waiting lane keeps its `Owns`, takes no slot · 13 orphan worktree → neither · 14 a `Max attempts` lane frees its `Owns` and slot.
- **`## Resuming`**, rows 1-19 (`resuming.cases`): 01 L4 · 02 L5 · 03 L6 · 04 L7 · 05 L8 human · 06 L8 autonomous · 07 L9 design · 08 L10 no record · 09 L10 stale record · 10 L11 blocked · 11 L11 uncommitted · 12 L11 · 13 L12 · 14 L15 · 15 L16 `/po-qa` · 16 L17 · 17 L18 fix · 18 L13 · 19 L19 · 20 L20 alone · 21 L1 · 22 L4 with a short-track plan → `execute`. Row 17 (closed pull request) has no case: it needs `gh`, which `po` never runs.
- **`## A wave`** (`a-wave.cases`): 01 L9 no design system · 02 L9 `Design source: —` · 03 a design note on disk → `execute`. Orphans: ready-set 13.
- **`## Checks`** (`checks.cases`): 01 `QA stage` missing asks for the story that needs it, not for a `Surface: —` story.
- **`## The verdict, and the fix runs`** (`verdict.cases`): 01 L16 QA evidence committed · 02 L16 twice · 03 L18 `Fix loop` 1 → `fix` · 04 L18 `Fix loop` 2 → `ask` · 05 L17 check could not run.
- **`## Ships, one at a time`** (`ships.cases`): 01 L20 review order · 02 a merge-waiting lane is no ship · 03 `automatic` with an open pull request → `ship` · 04 a landed lane's cleanup is no ship.
- **Decisions** (`decisions.cases`, the story's own rule): 01 pending → `wait` · 02 answered, not consumed → `wait` · 03 consumed → resumes · 04 a held story · 05 a stop already asked waits rather than asking twice.

Not routing cases, so not fixtures: `## Validating`'s grouped question (L8 says who validates), the model per role, ADR number reservation, the decisions log, `## Report`, and runtime events (an Agent tool refusing a model, a ship that fails, a subagent answering nothing).

## Tasks
1. [x] `po/src/context/mod.rs:17`: `pub use stories::{Stories, Story};` — the only change in `context/`. Test: the crate builds (`tests/run.sh` builds it first).
2. [x] `po/src/next/overlap.rs`: `overlap(a: &str, b: &str) -> bool` as written above. Tests: `ready-set.cases` 05-10 through `test_every_routing_case_is_a_fixture`; a wrong `*` or `**` rule turns 07-10.
3. [x] `po/src/next/lane.rs`: rows L1-L20, filling `next::lane_next` (always `Some` for a lane). Reads lane files with `std::fs`; runs the lane's `po-gate qa-current` only under L11, `git log` only under L15-L16 (`project::git`, `GIT_OPTIONAL_LOCKS=0`). Tests: `resuming`, `a-wave`, `checks`, `verdict`, `decisions` cases; `test_blocked_on_shape_asks_and_never_fixes`; `test_fix_loops_stop_at_max_attempts`.
4. [x] L20 in `lane.rs`: the serial ship order from the context and the review files' mtime. Tests: `test_ships_stay_serial_in_review_order`, `ships.cases`.
5. [x] `po/src/next/wave.rs`: one function computing `(ready, held)`, behind `next::ready` and `next::held`. Tests: `test_ready_and_held_say_why`, `ready-set.cases`, `decisions.cases` 04.
6. [x] `next::main`: the `po next` verb as `## The output of po next` says; drop `#![allow(dead_code)]` from `next/mod.rs`. Test: `test_next_gives_one_action_per_lane`.
7. [x] `tests/state-as-json.oracle.test.sh` (s164's oracle, in this story's `Owns`): line 136 drops `"ready", "held"` from the list asserted `null`; lines 138-139 assert `lanes[].next` is an object with `action` and `reason` instead of `null`; line 151 loops on `run continue` only. Nothing else in the file changes. Test: `bash tests/run.sh state-as-json.oracle.test.sh`.
8. [x] `tests/driver-next-action.test.sh`, the implementer's tests: `po next extra` → exit 2 `unknown-option`; L14; L8 with `Plan validation` deleted; L18 with `Max attempts` deleted; `ready`/`held` `null` without `Parallel`; `po next` on this repository under one second, writing nothing. At most 6 tests.
9. [x] Full suite through `po-run --story s168-driver-next-action --label 'Full suite' -- 'bash tests/run.sh'` (`Full suite: execute-end`); `Typecheck` is `—`.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `po/src/context/` except the `pub use` line of task 1; `po/src/state/`, `po/src/inbox/`, `po/src/record/`, `po/src/run/`, `po/src/trust/`, `po/src/main.rs`, `po/src/project.rs`, `po/src/output.rs`, `po/Cargo.toml`, `po/Cargo.lock` (ADR-0118).
- Empty diff: `method/` (`po-drive.md` and `po-execute.md` are s173's), `docs/interface-agent.md`, `tests/verbs-read-project-context.oracle.test.sh`, every test file outside `Owns`.
- `tests/state-as-json.oracle.test.sh`: only the three assertions of task 7.
- `po next` and `po state` run no `gh`, `curl`, `claude`, and no git command that writes, locks or asks a remote; `test_state_reads_only_files_and_git` stays green unchanged.
- `next/` pushes no warning: `po state`'s `warnings` are the same with or without this story (`tests/verbs-read-project-context.oracle.test.sh` checks them).
- No action outside the contract's ten (`docs/interface-agent.md:85`), no held reason outside its four (`:86`).
- Oracle files change only through `## Oracle changes` of the verification record.

## The pivot
The routing order of the table, ported from `po-drive.md`'s first-match table and its paragraphs, with four readings the prose does not settle:
1. **The review order is the review file's mtime.** `po record` writes it by a rename (`po/src/record/mod.rs:249-257`), so the mtime is when the verdict was recorded; a copy or a `touch` breaks it. Compare with `po-drive.md:147` and `po-ship.md:51`. If it proves wrong, a `Recorded:` line written by `po record` (s167's folder) is the fix, in another story.
2. **A decision holds until consumed**, not only while pending (L2): the criterion names `pending`; compare with `## The project lead` of `method/AGENTS.md`, where the lead consumes before acting. Case `decisions` 02 pins the choice.
3. **`autonomous` → `plan`, `human` → `validate-plan`** for a plan left unapproved (L8): `po-drive.md:54` resumes "the plan", `:119-123` validates per setting; `planner.md:47` approves under `autonomous`.
4. **L4 needs no plan either.** `po-drive.md:51` reads "no research" alone, but a short-track lane has a plan and no research (`method/agents/planner.md`, `track: flow`): read literally, row 1 would send it back to planning.
Also check: L1 before L2 (a landed lane is cleaned up whatever its decisions), and L2 before every `ask` (a stop already in the inbox waits).

## Files touched
`po/src/context/mod.rs`, `po/src/next/mod.rs`, `po/src/next/lane.rs`, `po/src/next/wave.rs`, `po/src/next/overlap.rs`, `tests/state-as-json.oracle.test.sh`, `tests/driver-next-action.test.sh`, plus the oracle files above (written, not changed) and `docs/research/`, `docs/plans/`, `docs/verif/` of the story.

## Test strategy
All at the adapter layer the project has: bash tests launching the built `po` on throwaway repositories, the only layer `tests/run.sh` runs. The real git and the real `po-gate.sh` are used, no mock. Count: 7 oracle tests (the 54 cases are one test, `every_routing_case_is_a_fixture`, as a property test counts once) + at most 6 implementer tests = 13 ≤ `Test budget` 25. A neutralised rule is caught: removing L17 turns two cases and one test; reversing L20's order turns `ships` 01 and its test; dropping `consumed` from L2 turns `decisions` 02-03. No visual check.

## Done when
`po next` and `po state` agree on every case, the full suite is green through `po-run`, the review finds no critical, and the story lands as one commit `s168-driver-next-action: La prochaine action d'une lane est calculée, pas interprétée`.
