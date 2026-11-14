# Research — s176-state-carries-session-lines

[Story](../stories.md)

## Structuring facts
- **Root cause (#203, the part this story covers):** `po state` computes what `po-session` prints, then throws it away before serialising. `framing()` evaluates each framing item (`po/src/context/framing.rs:65-76`) but returns only `stage`/`next` (`framing.rs:11-15`, `:91`); the context `Lane` holds `path` (`po/src/context/lanes.rs:37-44`) that the state `Lane` never serialises (`po/src/state/mod.rs:9-15`, `:62-72`); `blocked_by()` returns at the first stop it meets (`lanes.rs:278-330`), and the `Fix loop:` count it parsed (`lanes.rs:310`) is dropped. Proof: reproduction below.
- No false assumption in the story. Its notes hold: s172's research lists the gaps (`.worktrees/s172-commands-read-po-state/docs/research/s172-commands-read-po-state.md:6`, `:17-21`), `ready` stays out of scope, the s174 oracle moves (Traps).
- `blocked_by` must stay the code of the first stop: `po next` and the ready set read it (`po/src/next/wave.rs:20`, `:23`; `po/src/next/lane.rs:41-43`, `:73`, `:172`, `:179`). Keeping `BlockedBy` and deriving it from the first stop leaves `next/` untouched.
- `po-session.sh` is the reference and stays as it is (story notes); it derives everything in bash (`method/hooks/po-session.sh:70-105` framing, `:196-203` lanes, `:207-239` stops, `:240` orphans, `:241-256` CLAUDE.md hint).
- Contract: an added field leaves `contract` at `1` (`docs/interface-agent.md:30`); `:84` says "Les règles sont celles de `po-session`", which the story reverses.

## Story
`po state` carries, under `framing`, one state per framing item in po-session's order with its values; each lane's `path` relative to the project root as po-session prints it; under `stops` every stop of a lane that goes to a human, each with its `code` and the values po-session prints, as fields (`Fix loop:` and `Max attempts` for `max-attempts`); `blocked_by` stays the first. On the fixtures of `tests/project-lead.test.sh`, every framing, lane and stop value po-session prints reads in `po state`, the `CLAUDE.md`/install-mode hint aside. `docs/interface-agent.md` describes the fields and makes `po` the reference. Criteria: `framing_items_are_listed`, `lanes_carry_their_path`, `every_stop_of_a_lane_is_listed`, `session_cases_read_the_same` (oracle), `contract_says_the_new_fields` (doc, judged in review). Complexity 3. `Corrige : issue #203 en partie`. Depends on s170, s175, both on `main` (`git log`: `e9de336`, `758c061`).

## Diagnostic
- Track: full. `Corrige` line (defect), and an API contract change (`docs/interface-agent.md`).
- Reproduction (po built from this worktree with `CARGO_TARGET_DIR=/tmp/s176-target`, fixture rebuilt in `/tmp` as `tests/project-lead.test.sh:109-119` plus a technical choice in `s11-root`'s plan): po-session prints `Framing: scope approved · stories missing · stories review none · architecture missing · design system missing`, `Lanes in flight: s11-root (.worktrees/s11-root), s13-max (.worktrees/s13-max)`, and three stops: `s11-root: root cause not found (…)`, `s11-root: technical choice waiting for a human (docs/plans/s11-root.md) → /po-plan s11-root`, `s13-max: Max attempts reached (Fix loop: 2, Max attempts: 2)`. `po state` gives `"framing":{"stage":"stories","next":"/po-stories"}`, lanes `{"story":"s11-root","blocked_by":"root-cause-not-found"}` and `{"story":"s13-max","blocked_by":"max-attempts"}`: no item, no path, one stop of two, no counts.
- H1 "the values are in `po state` under other names" — refuted by the reproduction: no field holds them.
- H2 "`po` reads the files differently from the hook" — refuted for the values in scope: each rule of `lanes.rs:293-329` is the hook's `:213-238` line for line (same files, `grep -x` vs `has_line`, `last_value`, digits-only counts); `framing.rs:65-72` matches `:85-94`. The only divergence left is `ready` (`po/src/next/wave.rs:14-17`, out of scope).
- H3 kept: the reads are the same, the serialised types are projections (root cause above). A prototype of the fix (outside the worktree) made the four oracle tests pass and moved only the s174 oracle.

## Current code
- `po/src/context/framing.rs` (105 lines): `Framing {stage, next}` (`:11-21`, `setup()` `:18-20`); `framing()` (`:46-92`): `Entry mode` → scope file (`:53-62`), review as `Option<bool>` (`:65-69`), architecture/design system as bools with "not needed" folded into `design_system` (`:70-72`), `scope_pending` (`:74-76`), stage chain (`:78-91`).
- `po/src/context/lanes.rs` (331 lines): `BlockedBy` (`:26-34`, kebab-case); context `Lane {story, path, stage, blocked_by}` (`:37-44`, `path` canonical, `#[allow(dead_code)]` stale since `next/lane.rs:23` reads it); `shown()` (`:119-124`) gives the path relative to `project.root`, or absolute outside it, as po-session's `rel`; `lanes()` (`:173-212`) pushes each lane (`:197`) and orphans (`:203-206`, already using `shown`); `count()` (`:270-272`), `has_line()` (`:274-276`); `blocked_by()` (`:278-331`).
- `po/src/context/mod.rs`: `Warning` (`:21-30`), re-exports (`:16-17`), setup framing when no `AGENTS.local.md` (`:143-149`).
- `po/src/state/mod.rs` (88 lines): state `Lane {story, stage, next, blocked_by}` (`:9-15`), built in `compose()` (`:62-72`).
- `method/hooks/po-session.sh` (280 lines): framing line `:95` (scope `by hand`/`approved`/`in progress`/`missing` `:78-84`, review `none`/`yes`/`no` `:86-91`, design system `not needed` `:94`); lanes `id (rel)` `:196-203`; stop lines `:215`, `:219`, `:222`, `:231`, `:237`; orphans `:129`, `:132`, `:240`.
- `docs/interface-agent.md`: JSON example `:37-77`, `framing` `:84`, `lanes[].blocked_by` `:86`, warnings `:91`.

## Attachment points
- `framing.rs`: keep the item states the stage chain already computes and return them in a new `items` field; `Framing::setup()` gets `items: []`.
- `lanes.rs`: a `Stop` enum tagged by `code` (the `Warning` pattern, `mod.rs:21-30`) with the hook's values; `blocked_by()` becomes `stops()` returning all, in the hook's order; `Lane` gains `stops` and the shown path; `blocked_by` = first stop's code.
- `context/mod.rs`: re-export `Stop`. `state/mod.rs`: serialise `path` and `stops`.
- `docs/interface-agent.md`: example and field list.
- `tests/verbs-read-project-context.oracle.test.sh:20-21`: `normalised` drops the added fields.

## Verified interfaces
- `po state` reply: `output::reply` wraps the body with `"contract": 1` (`po/src/output.rs:10-16`).
- `Project::root` is canonical (`po/src/project.rs:41`); worktree paths are canonicalised (`lanes.rs:107-108`), so `shown()` strips the prefix the way the hook's `pwd -P` top does (`po-session.sh:11`, `:121`).
- Serde: struct field order is output order; `#[serde(tag = "code", rename_all = "kebab-case")]` gives `{"code": "max-attempts", …}` with snake_case fields (`mod.rs:21-23`).
- Tests: `$PO` = `${CARGO_TARGET_DIR:-$ROOT/po/target}/release/po` (`tests/lib.sh:7`), built once by `tests/run.sh:22-26`; `scratch_repo` traps only the last `$SCRATCH` (`tests/lib.sh:47-53`).

## Traps
- **s174 oracle moves.** `tests/verbs-read-project-context.oracle.test.sh:17-26` compares `po state`, normalised, to objects recorded from `de387bb`; `framing.items`, `lanes[].path` and `lanes[].stops` break all four `same` calls (`:85`, `:95`, `:107`, `:122`; checked on the prototype). It is in `Owns`.
- No other test pins these objects: `tests/state-as-json*.sh`, `driver-next-action*`, `held-says-what-collides.oracle`, `trust-signals*`, `run-from-outside*`, `decision-inbox.test` read single fields (`jq -e '.x == …'`) and passed on the prototype.
- `next/` must not change: `wave.rs:20` frees a lane on `blocked_by == max-attempts`. A lane both `qa-blocked` and at `max-attempts` stays `qa-blocked` there, as today.
- `Fix loop:`/`Max attempts` as integers: the hook prints the raw text, so `02` prints `02` and `2` in JSON. No fixture has a leading zero.
- `po run` reads `framing.next` (`tests/run-from-outside.oracle.test.sh:298`): unchanged.
- The oracle runs po-session as the reference; once s172 makes the hook read `po state`, `session_cases_read_the_same` compares `po` with itself through the hook's formatter, still a check of the formatter.
- No migration, no new dependency (ADR-0118).

## Open questions
- Item and stop field names are a contract choice inside an extension the story asks for; settled in the plan (`item`/`state`, `file`/`command`/`fix_loop`/`max_attempts`/`branch`), no ADR: the transport and versioning rules are ADR-0107's and do not move.

## Complexity
Story: 3. After reading: 3 — four Rust files, one test's normalisation, one doc section; the reads exist, only their results are kept.

## Split
Not needed.
