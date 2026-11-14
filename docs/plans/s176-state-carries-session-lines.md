---
validated: yes
---
# Plan — s176-state-carries-session-lines

[Story](../stories.md) · [Research](../research/s176-state-carries-session-lines.md)

Branch `story/s176-state-carries-session-lines`. Read `docs/research/s176-state-carries-session-lines.md` first; this plan builds on it without repeating it.

## Story
`po state` stops discarding what it already reads: under `framing`, one state per framing item in po-session's order and words; on each lane, its `path` as po-session prints it; under `stops`, every stop of a lane that goes to a human, with the values po-session prints as fields; `blocked_by` stays the first stop's code. The contract doc makes `po` the reference. Criteria: `framing_items_are_listed`, `lanes_carry_their_path`, `every_stop_of_a_lane_is_listed`, `session_cases_read_the_same`, `contract_says_the_new_fields`.

### The fields this plan fixes (contract 1, additions only)
| Field | Shape | Values |
| --- | --- | --- |
| `framing.items` | array, in this order: `scope`, `stories`, `stories-review`, `architecture`, `design-system`; `[]` at stage `setup` | `{"item": <name>, "state": <word>}`; `state` is po-session's word: scope `approved` / `in progress` / `missing` / `by hand`; stories `present` / `missing`; stories-review `yes` / `no` / `none`; architecture `present` / `missing`; design-system `present` / `missing` / `not needed` |
| `lanes[].path` | string | relative to the project root, absolute when the worktree is outside it (`shown()`, `po/src/context/lanes.rs:119-124`) |
| `lanes[].stops` | array, in po-session's order (`po-session.sh:213-238`); `[]` when none | `{"code": "root-cause-not-found", "file": "docs/research/<id>.md"}`, `{"code": "technical-choice", "file": "docs/plans/<id>.md", "command": "/po-plan <id>"}`, `{"code": "qa-blocked", "file": "docs/qa/<id>/report.md"}`, `{"code": "max-attempts", "fix_loop": <int>, "max_attempts": <int>}`, `{"code": "merge-waiting", "branch": "story/<id>"}` |
| `lanes[].blocked_by` | unchanged | `stops[0].code`, `null` when `stops` is empty |

Orphan worktrees stay `orphan-worktree` warnings (they already carry `path` and `branch`); the `CLAUDE.md`/install-mode hint stays in the hook; `ready` is untouched (s172).

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Framing item states | already in this repository: the reads of `framing()` (`po/src/context/framing.rs:65-76`) | — the values are computed there; only a tri-state for scope and design system is added, from the same reads |
| `Stop` enum tagged by `code` | already in this repository: the `Warning` pattern (`po/src/context/mod.rs:21-30`) | — same serde attributes, new variants |
| All stops of a lane | already in this repository: `blocked_by()` (`lanes.rs:278-331`) | — its rules are kept, it pushes instead of returning |
| Lane path | already in this repository: `shown()` (`lanes.rs:119-124`), used for orphans (`:204`) | — |
| `blocked_by` from the first stop | already in this repository: `BlockedBy` (`lanes.rs:26-34`) | — kept as is, so `po/src/next/` does not change |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/state-carries-session-lines.oracle.test.sh` | `529154698 12486` |

| Criterion | Test |
| --- | --- |
| `framing_items_are_listed` | `test_framing_items_are_listed`: walks a project from no brief to framing done, then `Entry mode: —`, then no `AGENTS.local.md`; at each step `framing` is exactly `{stage, next, items}` as the table above says |
| `lanes_carry_their_path` | `test_lanes_carry_their_path`: `.worktrees/s01-a` from the root and from inside the lane; the absolute path of a lane under an absolute `Worktree root` outside the project |
| `every_stop_of_a_lane_is_listed` | `test_every_stop_of_a_lane_is_listed`: a lane with root cause + technical choice, one with QA blocked + `Fix loop: 3` at `Max attempts: 2`, one waiting for its merge, one with none: exact `{story, blocked_by, stops}` |
| `session_cases_read_the_same` | `test_session_cases_read_the_same`: the four fixtures of `tests/project-lead.test.sh:60-172` rebuilt (all states of the last one, a root `CLAUDE.md` added to the escalations); po-session's framing, lanes and waiting lines, `- CLAUDE*.md:` lines removed, equal `po state` put through a jq formatter of the same lines |
| `contract_says_the_new_fields` | — documentation no script reads: judged in review (task 5). Not a `po-eval` candidate: no model reads it as a rule |

## Tasks
1. [x] **Framing items** — `po/src/context/framing.rs`: add `pub struct Item { item: &'static str, state: &'static str }` (Serialize, Clone, Debug, PartialEq) and `pub items: Vec<Item>` after `next` in `Framing`; `Framing::setup()` gets `items: Vec::new()`. In `framing()`, compute the scope state from the existing scope match and `exists`/`frontmatter_status` (`None` scope → `by hand`; file absent → `missing`; `status: approved` → `approved`; else `in progress`), derive `scope_pending` from it, and split the design system into `present` / `not needed` (file absent, stories present, `no_story_has_a_screen()`) / `missing` without changing the stage chain (`:78-90`). Update the module comment: these are `po`'s rules now. Test: `test_framing_items_are_listed`; `test_state_output_does_not_move` after task 4 proves `stage`/`next` did not move.
2. [x] **Every stop** — `po/src/context/lanes.rs`: add `pub enum Stop` with `#[serde(tag = "code", rename_all = "kebab-case")]` and the five variants of the table (`fix_loop`, `max_attempts` as `u64`, the values `count()` already parses), plus `Stop::code() -> BlockedBy`. Rename `blocked_by()` to `stops()` returning `Vec<Stop>`: the same five rules in the same order (`:293-329`), each pushing instead of returning. `Lane` gains `pub stops: Vec<Stop>` and the shown path (`shown(project, &worktree.path)`); `blocked_by` becomes `stops.first().map(Stop::code)` at `:196-197`. Fix the comments that say "first per-lane stop" and "as po-session.sh reads them". Re-export `Stop` in `po/src/context/mod.rs:17`. Test: `test_every_stop_of_a_lane_is_listed`; `tests/state-as-json.test.sh` `test_blocked_by_names_each_stop_and_orphans_warn` stays green.
3. [x] **Serialise** — `po/src/state/mod.rs`: the state `Lane` gets `path: String` after `story` and `stops: Vec<Stop>` after `blocked_by`, filled in `compose()` (`:62-72`) from the context lane. Test: `test_lanes_carry_their_path`, `test_session_cases_read_the_same`.
4. [x] **s174 oracle normalisation** — `tests/verbs-read-project-context.oracle.test.sh:20-21`: `del(.ready, .held, .session, .bounds, .shipped, .framing.items?)` and `map(del(.next, .path, .stops))`; extend the comment at `:14-16` to say the fields s176 adds are dropped too. The recorded objects (`:74-128`) do not change. Test: `test_state_output_does_not_move` passes (it fails on all four `same` calls without this task, checked on a prototype).
5. [x] **Contract** — `docs/interface-agent.md`: add `"items"` to `framing` and `"path"`, `"stops"` to the lane of the example (`:37-77`); at `:84` describe `framing.items` with its names and words, and replace "Les règles sont celles de `po-session`" by: `po` is the reference, which the session hook will read (s172); at `:86` describe `lanes[].path` and `lanes[].stops` per code, and say `blocked_by` is the code of the first stop. Remove no field, keep `contract` `1`. Check: review reads it against the table above.
6. [x] **Suite** — `po-run --story s176-state-carries-session-lines --label 'Unit suite' -- 'bash tests/run.sh'`; then `cargo build --release --locked` has no new warning for `po/` (the type check of this crate).

## Scene viewpoints
—

## Run interdicts
- `method/hooks/po-session.sh`: empty diff (it is the reference; s172 rewires it).
- `po/src/next/`, `po/src/run/`, `po/src/trust/`, `po/src/inbox/`, `po/src/record/`: empty diff. `BlockedBy` keeps its five values.
- `po/Cargo.toml`, `po/Cargo.lock`: empty diff (no dependency, ADR-0118).
- `tests/project-lead.test.sh`, `tests/state-as-json.test.sh`, `tests/state-as-json.oracle.test.sh`: empty diff. In `tests/verbs-read-project-context.oracle.test.sh`, only `normalised` and its comment move.
- `tests/state-carries-session-lines.oracle.test.sh`: cksum stays `529154698 12486`.
- No field of `po state` removed or renamed; `contract` stays `1`; `ready`, `held`, `lanes[].next` unchanged on every existing test.
- `tests/state-carries-session-lines.test.sh` is not created (no test beyond the oracle).

## The pivot
`po state` reports what it already reads, without a new rule: the hook's words go into JSON as they are, and `blocked_by` stays the first stop so every reader of it is unchanged. Ways it could be wrong:
- **A stop order or rule drifts** while turning `return` into `push`: compare `stops()` with `po-session.sh:213-238` rule by rule; `test_session_cases_read_the_same` covers each of the five lines and the ordinary-lane cases that print nothing.
- **`blocked_by` changes for a lane with two stops**: it must be the first of the hook's order (root cause before technical choice, QA before max attempts); `next/wave.rs:20` frees a lane only on `max-attempts`, as today.
- **The design-system tri-state changes `stage`**: `design_system` must still be "file present or not needed"; `test_framing_items_are_listed` and the s174 oracle check `stage` and `next`.

## Files touched
`po/src/context/framing.rs`, `po/src/context/lanes.rs`, `po/src/context/mod.rs`, `po/src/state/mod.rs`, `docs/interface-agent.md`, `tests/verbs-read-project-context.oracle.test.sh`, `tests/state-carries-session-lines.oracle.test.sh` (oracle, written), `docs/research/…`, `docs/plans/…`, `docs/verif/…`.

## Test strategy
- Automated: the four oracle tests, at the layer that owns the rule — the `po state` binary on scratch repositories, no mock. One existing test changes its normalisation (task 4) because the story adds fields; its recorded objects stay. Four new tests, within `Test budget` (25).
- The oracle's `session_cases_read_the_same` uses po-session as the reference while it still derives in bash; after s172 it checks the hook's formatter against `po`.
- Not automated: `contract_says_the_new_fields`, read in review.
- Full suite once at the end through `po-run`; no other check.

## Done when
The six tasks are ticked, the full suite passes through `po-run`, `po` builds without a new warning, the review finds no critical, and the story lands as one commit `s176-state-carries-session-lines: …` on `main` through a pull request.
