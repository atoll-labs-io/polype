# Research — s168-driver-next-action

[Story](../stories.md)

## Structuring facts
- Root cause of #139 (the part this story fixes): no code computes a lane's next action, and the prose that does it twice disagrees — `method/commands/po-drive.md:63` sends a shape-blocked review to a human, `method/commands/po-execute.md:26` exempts only the two QA blocks and so starts a fix run. s168 gives `po next` the one answer (`ask`); s173 makes `/po-execute` read it.
- False assumption: "the order the reviews passed" (`ships_stay_serial_in_review_order`) is written in no file. A review carries no date (`method/templates/review.md:9-11`), and the passing one stays uncommitted until `/po-ship` commits it (`method/commands/po-ship.md:51`). The only reading is the file's modification time, which `po record` sets by its rename (`po/src/record/mod.rs:249-257`).
- False assumption: the overlap rule of check 8 is "exercised" by `tests/owns-overlap.test.sh`; that test only checks that prose quotes the rule (`tests/owns-overlap.test.sh:9-22`). No code implements it (`bin/ks-overlap` is the Killer SaaS overlap tool); `po/src/next/` writes the first one.
- Two rows of `## Resuming` need the forge (`po-drive.md:66-67`, `gh pr view`): `po state` never asks a forge (`docs/interface-agent.md:33`). Row 16 is approximated as the context already does it (`origin/story/<id>` exists, `po/src/context/lanes.rs:320-328`); row 17 (closed pull request) cannot be a fixture.
- Every input the routing needs is already in the context (`po/src/context/mod.rs:96-112`) except one visibility: `Story` (surface, deps, `Owns`) is not re-exported (`po/src/context/mod.rs:15-17`).

## Diagnostic
Defect named by the `Corrige` line: #139 (in part). #203 is the feature half (compute the action).
- Reproduction (no file created): read `method/commands/po-execute.md:26`: precondition 6 starts a fix run on any `Ship allowed: no` except `Next action:` naming `/po-qa` or the QA evidence commit; a review whose `Next action:` names `po-gate findings-shape` (`method/commands/po-review.md:42`) passes it. `po state` today gives such a lane `blocked_by: null` while `Fix loop` < `Max attempts` (`po/src/context/lanes.rs:302-319`), so nothing computed says "ask".
- H1 — `/po-drive` itself routes a shape-blocked review to a fix run. Refuted by: `po-drive.md:63` (row 13 → a human), placed above the fix-run row 64. Discarded.
- H2 — `/po-execute` run alone starts the fix run. Refuted if precondition 6 named the shape stop: it does not (`po-execute.md:26`). Kept.
- H3 — the derived state could tell the shape stop apart and nothing reads it. Refuted if a field said so: `BlockedBy` has no such variant (`lanes.rs:26-34`) and `lanes[].next` is `null` (`po/src/next/mod.rs:28-30`). Kept: the action is not computed anywhere.
Root cause: `po-execute.md:26` decides from prose with one exception missing, and no computed action exists to read instead. This story computes it; `po-execute.md` is s173's (`docs/stories.md:2781`).

## Story
`po next` gives, per lane and per ready story, one action among `plan`, `validate-plan`, `design`, `execute`, `qa`, `review`, `fix`, `ship`, `wait`, `ask`, with a reason naming the gate or file; `po state` carries the same in `lanes[].next`, `ready`, `held` (reasons `dependency`, `owns`, `parallel`, `decision` + `ref`). Criteria: `next_gives_one_action_per_lane`, `ready_and_held_say_why`, `every_routing_case_is_a_fixture`, `blocked_on_shape_asks_and_never_fixes`, `fix_loops_stop_at_max_attempts`, `ships_stay_serial_in_review_order`, `answered_decision_releases_its_lanes`. Owns: `po/src/next/`, `po/src/context/mod.rs` (visibility only), `tests/fixtures/driver-cases/`, the two `driver-next-action` test files, `tests/state-as-json.oracle.test.sh`.

## Current code
- `po/src/main.rs:23` dispatches `next` to `next::main`, which answers `not-built` (`po/src/next/mod.rs:24-26`).
- `po/src/next/mod.rs:10-22` defines `NextAction {action, reason}` and `Held {story, reason, ref}`; `lane_next`, `ready`, `held` return `None` (`:28-38`); the file carries `#![allow(dead_code)]` (`:3`).
- `po/src/state/mod.rs:68,83,84` calls `next::lane_next(context, lane)` per lane, `next::ready(context)`, `next::held(context)`; nothing else in `state/` needs to change.
- `Context::read` (`po/src/context/mod.rs:116-177`) reads once: `target`, `stories`, `landed`, `lane_settings`, `lanes`, `inbox`, `warnings`; `context.project.setting(name)` reads any other setting without a warning (`:91-92`, `po/src/project.rs:55-67`).
- Lane stage (`po/src/context/lanes.rs:214-268`): landed → `Ship`; no plan → `Research`/`Design`/`Plan`; then the lane's own `po-gate` `plan-validated`, `ship-allowed`, `verif-current`, `qa-current` (`:241-266`); `None` with a `no-gate` warning (`:237-239`) or when `QA stage` is missing/unreadable for a story that needs it (`:251-262`).
- `blocked_by` (`lanes.rs:279-331`): `RootCauseNotFound` / `TechnicalChoice` only without `validated: yes`; `QaBlocked` from the last `QA status:`; `MaxAttempts` when `Ship allowed: no`, not waiting for QA (`:307-309`), `Fix loop` ≥ `Max attempts`; `MergeWaiting` under `pr` + `human` with `refs/remotes/origin/story/<id>`.
- `Lane { story, path, stage, blocked_by }` (`lanes.rs:37-44`); `Landed::contains` (`:86-88`) knows `<id>:` and bare `s<n>:` subjects.
- `Story { id, surface, depends_on, owns, milestone }`, `has_screen()` (`po/src/context/stories.rs:6-23`); `Stories.list` keeps `docs/stories.md` order (`:31-35`).
- `Decision { id, blocks: Option<Vec<String>>, status: String, consumed: Option<Value> }` (`po/src/inbox/decision.rs:49-69`); `Inbox.decisions` in id order (`po/src/context/mod.rs:83-89`).
- `po-gate qa-current` refuses an uncommitted current report with "is current but" on stderr (`method/hooks/po-gate.sh:229`); `lanes.rs:127-138` runs gates with stdout/stderr discarded, private.

## Attachment points
- `po/src/next/mod.rs`: `main`, `lane_next`, `ready`, `held` — signatures fixed by s174, called from `state/` unchanged.
- `po/src/context/mod.rs:17`: add `Story` to the re-exports (the one change the story allows there).
- `tests/state-as-json.oracle.test.sh:136-139` (ready/held/lanes[].next asserted `null`) and `:151` (`next` asserted `not-built`) — the assertions this story makes false.

## Verified interfaces
- `next::lane_next(&Context, &context::Lane) -> Option<NextAction>`, `next::ready(&Context) -> Option<Vec<String>>`, `next::held(&Context) -> Option<Vec<Held>>` (`po/src/next/mod.rs:28-38`).
- `output::reply(body, code)`, `output::error(code, err, msg)`, `OK`/`UNREADABLE` (`po/src/output.rs`); `Project::find(&cwd)` (`po/src/project.rs:38`); `project::git(dir, args)` with `GIT_OPTIONAL_LOCKS=0` (`:20-33`).
- `context::Warning::OrphanWorktree { path, branch }` (`po/src/context/mod.rs:25`).
- `LaneSettings { qa_stage, max_attempts, merge_mode, confirmation }` (`lanes.rs:148-153`).
- Settings the routing needs beyond the context: `Parallel`, `Plan validation`, `Design source` — all three in this repository's `AGENTS.local.md` and the template (`method/templates/agents-local.md:12,27,32`).
- Contract: actions and held reasons (`docs/interface-agent.md:85-86`); `ready`, `held`, `lanes[].next` are `null` until their story ships (`:88`). `po next`'s own output is not in the contract (`:24`).

## Traps
- `tests/state-as-json.oracle.test.sh:136-139,151` fail once `next` is built: s168 owns that file and changes those three assertions only.
- `tests/verbs-read-project-context.oracle.test.sh:20-21` drops `ready`, `held`, `lanes[].next` before comparing: unaffected, but `warnings` must not change — `next/` pushes no warning (the context is borrowed immutably anyway).
- `test_state_reads_only_files_and_git` (`tests/state-as-json.oracle.test.sh:164-201`) stubs `git` and fails on any argument word `fetch|pull|push|ls-remote|commit|checkout|switch|stash|worktree add|update-ref`, and on any `gh`/`curl`; it times `po state` on this repository under 1 s. `po next` must use `git log`/`rev-list` only, and run `po-gate qa-current` only for lanes at stage `qa`.
- `lane_next` is called per lane by `state`: the serial-ship rule needs the other lanes, so it must read them from the context (stage, `blocked_by`, review mtime) without running their gates again.
- `Lane.path` and `Story.milestone` carry `#[allow(dead_code)]` in files outside `Owns` (`lanes.rs:39-41`, `stories.rs:15-17`): they stay.
- No new crate (ADR-0118, `po/Cargo.toml`): glob matching for `Owns` is hand-written (`*` within a segment, `**`, folders).
- Tests are bash only (`tests/run.sh`); no `cargo test` runs anywhere.
- `po-drive.md` has no row for a review with no `Ship allowed:` line; `AGENTS.md` Law 3 counts it as blocked.

## Open questions
- `Plan validation: autonomous` with a plan left at `validated: no`: `po-drive.md:54` resumes "the plan", `:119` says the planner validates; the plan picks `plan` (planner) under `autonomous`, `validate-plan` under `human`.
- Does an answered but unconsumed decision still hold its lane? The criterion names only `pending`; the lead must consume before acting (`method/AGENTS.md`, `## The project lead`). The plan holds until consumed.
- `Parallel` slots: `po-drive.md` frees a lane only past `Max attempts` (`:144`) and a merge-waiting lane takes no slot (`:42`); lanes waiting for a human for another reason keep theirs. Kept as written.
- A story with no `Owns` line: no entry to compare, so it never collides. `po-drive.md` and check 8 are silent; check 8 flags it as a major finding of the stories review.
- `held` carries no colliding path nor entries, which `po-drive.md`'s report names (`:40,165`); adding fields would change `docs/interface-agent.md`, outside `Owns`. Left to s173.

## Complexity
Story: 4. After reading: 4. The code is small (one folder, about five hundred lines), but the risk the story names is real: 54 routing cases, one forge-only row that no fixture can carry, and the review order read from a modification time.

## Split
Not needed at 4.
