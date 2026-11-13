# Research — s174-verbs-read-project-context

[Story](../stories.md)

## Structuring facts
- **Root cause #248** — the rule exists and is right (`po/src/state/lanes.rs:209-211`: a landed story returns `Stage::Ship` before any gate), but no test isolates it: the `s07-landed` fixture of `tests/state-as-json.oracle.test.sh:231-236` carries a passing review on unchanged code, so `ship-allowed` (`lanes.rs:231`) already answers `ship`. Proof: lines 209-211 deleted in a copy of `main` → the six s164 oracle tests still pass (see `## Diagnostic`).
- **Root cause #249** — the seams take no context: `next::lane_next(&str, Option<Stage>)`, `ready()`, `held()` (`po/src/next/mod.rs:28-38`), `run::session()`, `run::bounds()` (`po/src/run/mod.rs:30-36`), `trust::shipped(&StateOptions)` (`po/src/trust/mod.rs:37`); while `Stories`, the landed set, the worktree listing and the lanes' paths are private to `state/` (`po/src/state/mod.rs:3-4`, only `Framing`, `Milestone`, `Lane`, `Stage` re-exported at `:13-14`) and the decision reader is private to `inbox/` (`po/src/inbox/mod.rs:6`; only `pending_ids` is public, `:106`).
- **Story assumption that does not hold as written** — `state_output_does_not_move` asks to run "the `po` of `Target branch`" next to the story's. A test cannot build it on CI: `ci.yml` checks out `head_ref` alone (`.github/workflows/ci.yml:14-20`, default depth 1, no `main` ref), and a second cold cargo build costs ~20 s per run. The oracle freezes instead the output the `po` of `main` (de387bb) printed on the s164 fixtures, built and run by the planner (see the plan's pivot).
- Three things the context must carry are read nowhere today: dependencies and `Owns` of a story (`Story` holds only `id` and `surface`, `po/src/state/framing.rs:347-351`), the landed commit of each story (`Shipped` keeps ids only, `lanes.rs:47-50`), and each story's milestone as a lookup (sections exist, `framing.rs:359-362`).
- Warning order is part of the output and comes from the order of reads in `state::read` (`po/src/state/mod.rs:108-164`); a context that reads in another order moves `warnings`.

## Story
Refactor `po state` onto one project context built once per call, handed to every seam later stories fill (`lane_next`, `ready`, `held`, `session`, `bounds`, `shipped`), with no output change; and make the "landed → `ship`" rule bite in a test.
- `state_output_does_not_move` — same object field for field, `warnings` included, on the s164 fixtures; still read-only, no lock, < 1 s on this repo.
- `landed_lane_reports_ship_whatever_its_review` — a landed lane is `ship` with its review missing or stale; the test fails without the rule (#248).
- `verbs_receive_one_context` — the context holds root, settings, stories with deps and `Owns`, landed set and commits, milestones, framing, lanes with path and stage, decisions with `status`/`blocks`/`consumed`; nothing of it private to `state/` or `inbox/`; review-judged.

## Diagnostic
**Reproduction (#248).** `git archive main` into `/tmp/s174-base/src`, built with `cargo build --release --locked`. Copy to `/tmp/s174-base/mut`, `sed -i '209,211d' po/src/state/lanes.rs`, then `bash tests/run.sh state-as-json.oracle.test.sh` → `6 passed, 0 failed`. The defect reproduces: the rule is unguarded.
**Reproduction (#249).** Read-only: the signatures above, and `crate::state::Stage` is the only `state` item `next/` can reach (`po/src/next/mod.rs:8`). s168 could not compute `ready` without re-parsing `docs/stories.md`.

| # | Hypothesis | Refuting observation | Result |
| --- | --- | --- | --- |
| H1 | #248 is a code defect: a landed lane is not reported `ship` | a landed lane with no review or a stale review prints `ship` on `main`'s `po` | discarded — draft oracle test passes on `main`'s `po` (`s04` no review, `s07` stale review → `ship`) |
| H2 | #248 is a masked rule: the fixture also passes `ship-allowed` | deleting the rule makes some s164 test fail | kept — no test fails (above); the same deletion makes the draft s174 oracle fail: `s04-code-recorded: review instead of ship; s07-landed: execute instead of ship` |
| H3 | #249: the context is reachable through some public path | a `pub` item of `state/` exposing stories or lanes, or a `pub` decision reader | discarded for state (`mod framing; mod lanes;` private, `state/mod.rs:3-4`) — kept as cause |

## Current code
- `po/src/main.rs:1-35` — declares the modules and dispatches verbs; `next`, `run`, `continue` print `not-built` (`next/mod.rs:24`, `run/mod.rs:22-28`).
- `po/src/project.rs:8-95` — `Project { root, local_md }`, `find` resolves a worktree to the main checkout (`:38-48`), `setting` (`:55-67`), `git` with `GIT_OPTIONAL_LOCKS=0` (`:20-33`), `commit` short 7 (`:80-84`), `on_target` (`:92-94`).
- `po/src/state/mod.rs` — `Warning` enum (`:16-25`), `Warnings` dedup push (`:27-36`), `State` output (`:38-53`), `Settings` helpers `required`/`usable`/`optional` (`:55-88`), `main` (`:90-106`), `read` (`:108-164`), `waiting` (`:166-184`).
- `po/src/state/framing.rs` — `Framing`, `Milestone`, `Story { id, surface }`, `Section`, `Stories::read/parse/find` (`:400-450`), `framing()` (`:474-520`), `milestone()` (`:523-532`).
- `po/src/state/lanes.rs` — `Stage`, `BlockedBy`, `Lane` (`:15-43`), `Shipped::read` by `git log --format=%s <target> [origin/<target>] --` (`:53-82`), `worktrees()` (`:95-110`), `gate()` runs the lane's own `po-gate.sh` (`:120-131`), `lanes()` (`:147-199`) calls `next::lane_next(&id, stage)` (`:184`), `stage()` (`:201-255`), `blocked_by()` (`:266-318`).
- `po/src/inbox/mod.rs` — verbs (`:35-45`), `answer` (`:49-74`), `pending_ids` (`:106-114`), `locate` (`:117-139`); `decision.rs` — `Decision` with `status`, `blocks`, `consumed` (`:256-276`), `read_dir` (`:289-314`).

## Order of reads in `state::read` (the warning order)
1 `method-version-mismatch` (`mod.rs:112-120`) → 2 `Target branch` usable (`:122`) → 3 stories, landed (`:124-125`, no warning) → 4 framing: `Entry mode` (`framing.rs:481`) → 5 lanes: `Max attempts`, `Merge mode`, `Ship confirmation` (`lanes.rs:155-165`), `Worktree root` (`:167`), then per worktree in `git worktree list` order: `no-gate`, `QA stage`, `orphan-worktree` (`:171-197`); without a target only `Worktree root` (`mod.rs:142`) → 6 `Decision inbox` usable, then `unreadable-decision` per file or for the folder (`mod.rs:166-184`). `QA stage` is read with `optional` (`lanes.rs:155`): no warning when missing unless a lane needs it (`:239-241`).

## Attachment points
- New `po/src/context/` (in `Owns`): the context type and its reader; `mod context;` in `po/src/main.rs`.
- `po/src/state/` becomes a composer of `State` from the context; `framing.rs` / `lanes.rs` move under `context/` or become `pub` from it.
- Seam signatures in `po/src/next/mod.rs:28-38`, `po/src/run/mod.rs:30-36`, `po/src/trust/mod.rs:37`; their types (`NextAction`, `Held`, `Session`, `Bounds`, `Shipped`, `Trust`, `StateOptions`) stay where they are.
- `po/src/inbox/mod.rs:106` — `pending_ids` replaced or joined by a public decision reader built on `decision::read_dir`.

## What s168, s169 and s170 need (their criteria)
| Client criterion | Needs from the context |
| --- | --- |
| s168 `next_gives_one_action_per_lane` | each lane's id, path (research/plan/review files), stage; framing; ready stories |
| s168 `ready_and_held_say_why` | stories with deps and `Owns`; landed set; lanes; `Parallel` setting; pending decisions' `blocks` |
| s168 `fix_loops_stop_at_max_attempts`, `blocked_on_shape_asks_and_never_fixes` | lane path (review file); `Max attempts`; project root (`po-gate`) |
| s168 `ships_stay_serial_in_review_order` | lanes with stage `ship` and their paths (review order is read from the files) |
| s168 `answered_decision_releases_its_lanes` | decisions with `status`, `blocks`, `consumed` |
| s169 `run_starts_one_lead_session` | root; framing `next` |
| s169 `run_refuses_when_nothing_to_do` | ready stories (from s168), lanes, answered unconsumed decisions |
| s169 `run_refuses_unproven_bounds` | root (`.claude/agents/`); the user's Polype folder is s169's own |
| s170 `shipped_stories_carry_trust` | landed stories, landed commit of each, each story's milestone and the current one; target branch (reviews, plans read on it); `--all` stays in `trust::state_options` |
| s170 `checks_are_read_only_on_request` | landed commit of each story |

## Verified interfaces
- `pub fn lane_next(_story: &str, _stage: Option<Stage>) -> Option<NextAction>` (`next/mod.rs:28`); `pub fn ready() -> Option<Vec<String>>` (`:32`); `pub fn held() -> Option<Vec<Held>>` (`:36`).
- `pub fn session() -> Option<Session>`, `pub fn bounds() -> Option<Bounds>` (`run/mod.rs:30,34`).
- `pub fn state_options(args: &[String]) -> Result<StateOptions, String>`, `pub fn shipped(_options: &StateOptions) -> Option<Vec<Shipped>>` (`trust/mod.rs:30,37`). Name clash: `trust::Shipped` (output) vs `state::lanes::Shipped` (landed set).
- `pub fn pending_ids(dir: &Path) -> io::Result<Pending>` (`inbox/mod.rs:106`), used only at `state/mod.rs:172`.
- Story header in `docs/stories.md`: `- **Depends on**` / `- **Dépend de**`, ids taken by the id pattern as `po-session.sh:182-185` does; `- **Owns**` entries in backticks (`method/templates/stories.md:13`).

## Traps
- **Warning order** (section above). Reading a new setting with `required`/`usable` (e.g. `Parallel` for s168) adds a `missing-setting` warning and moves the output; the context must expose `Project::setting` or read new settings with `optional`.
- **Gate cost**: each lane runs up to four `po-gate.sh` processes (`lanes.rs:228-251`); the context must not add a gate call, or the < 1 s check of `tests/state-as-json.oracle.test.sh:196-200` suffers.
- **Landed commit**: `Shipped::read` reads `%s` only (`lanes.rs:60`); adding `%H` keeps one `git log`. A story landed twice (fix) — the most recent subject first in `git log` order.
- **dead_code**: fields only s168-s170 read warn; `next/`, `run/`, `trust/` already use a module-level `#![allow(dead_code)]` (`next/mod.rs:3`).
- The s174 oracle sources `tests/state-as-json.oracle.test.sh` inside its tests for s164's fixture helpers (`fixture`, `lane`, `plan_in`, `code_in`, `record_in`, `review_in`, `decision`, `po_in`, `need_po`, `shipped_version`); s168-s170 own that file and must keep those names.
- Tests that run: `tests/state-as-json*.test.sh`, `tests/decision-inbox*.test.sh`, `tests/answer-comes-back*.test.sh`, `tests/record-writes-reports*.test.sh` (crate builds), full suite via `Test`.
- No migration; no dependency (ADR-0118, `po/Cargo.toml:7-10`).

## Open questions
- Should `inbox::locate` (`inbox/mod.rs:117-139`) be rebuilt on the context too? The story limits `inbox/` to opening the reader; the plan leaves `locate` as is.
- The stale-review lane not landed (`s06`) reports `execute` (its record no longer matches); the oracle only asserts "not `ship`".

## Complexity
3 → 3. A mechanical refactor of ~600 lines in four files with one real risk, the warning order, which the oracle pins; the new readers (deps, `Owns`, landed commit) are small.

## Split
—
