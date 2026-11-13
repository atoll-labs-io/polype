---
validated: yes
---
# Plan — s174-verbs-read-project-context

[Story](../stories.md) · [Research](../research/s174-verbs-read-project-context.md)

Branch `story/s174-verbs-read-project-context`. Read `docs/research/s174-verbs-read-project-context.md` first; this plan builds on it without repeating it.

## Story
`po state` is rebuilt on one project context, read once per call and handed to every seam that s168, s169 and s170 fill, without moving a field of its output (#249); the rule "landed → `ship`" gets a test that bites (#248).
- `state_output_does_not_move` — same object as `Target branch`'s `po` on the s164 fixtures, `warnings` included; still read-only, no lock, < 1 s on this repository.
- `landed_lane_reports_ship_whatever_its_review` — a landed lane is `ship` with its review missing or stale; the test fails when the rule is removed.
- `verbs_receive_one_context` — the six seams receive one context holding what the research's client table lists; nothing of it private to `state/` or `inbox/`; `state` is built on it. Review-judged.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `Context` type and its reader | already in this repository: the body of `state::read` (`po/src/state/mod.rs:108-184`), `framing.rs`, `lanes.rs`, moved, not rewritten | — |
| Parsing `Depends on` / `Dépend de` and `Owns` of a story | new code in `Stories::parse` (`po/src/state/framing.rs:407-446`), same id pattern as `story_id` (`:372-386`) and as `po-session.sh:182-185` | nothing in the crate reads those lines; the standard library has no Markdown parser and ADR-0118 forbids a dependency |
| Landed commit per story | already in this repository: `Shipped::read` (`lanes.rs:53-82`), format `%H %s` instead of `%s` | — |
| Public decision reader | already in this repository: `inbox::decision::read_dir` (`po/src/inbox/decision.rs:289-314`), made reachable | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/verbs-read-project-context.oracle.test.sh` | `1051114135 7925` |

| Criterion | Test |
| --- | --- |
| `state_output_does_not_move` | `test_state_output_does_not_move` — four runs on s164's fixtures (seven lanes, a technical-choice stop, an orphan worktree, an unreadable decision; then settings removed and another version; then no `Target branch`; plus one run from inside a lane), each compared with the object `main`'s `po` (de387bb) printed, normalised for the fixture's commit, the version stamp and the scratch path. Fields s168-s170 compute (`ready`, `held`, `session`, `bounds`, `shipped`, `lanes[].next`) are left out so those stories do not break it; their `null` stays checked by s164's `test_state_prints_one_json_object`. The read-only, no-lock and < 1 s clauses stay checked by s164's `test_state_reads_only_files_and_git`, unchanged. |
| `landed_lane_reports_ship_whatever_its_review` | `test_landed_lane_reports_ship_whatever_its_review` — `s04` landed with no review, `s07` landed then a commit after its passing review → both `ship`; `s06` not landed with a stale review → not `ship`. Checked by the planner: passes on `main`'s `po`, fails with `lanes.rs:209-211` deleted. |
| `verbs_receive_one_context` | — code-structure rule no script reads (owner's rule of 2026-11-13): no oracle test, judged by the reviewer against the client table of the research; not a `po-eval` candidate, since no model reads it. |

No assertion of `tests/state-as-json.oracle.test.sh` changes: the landed case lives in this story's oracle under the criterion's own name; changing the `s07-landed` fixture as well would test the same rule twice (testing-doctrine, cut 3). That file ends with an empty diff.

## Tasks
1. [x] **Context skeleton.** Create `po/src/context/mod.rs`, register `mod context;` in `po/src/main.rs`. Move into it, unchanged in behaviour, `Warning`, `Warnings`, the `required`/`usable`/`optional` setting helpers (`state/mod.rs:16-88`), `Stage`, `BlockedBy` (`lanes.rs:15-35`), and the readers of `framing.rs` and `lanes.rs` (as `context/stories.rs`, `context/framing.rs`, `context/lanes.rs`, or kept whole — the split is the implementer's). `state/` re-exports what it serialises. Rename the landed set `Landed` to end the clash with `trust::Shipped`. `next/mod.rs` imports `Stage` from `crate::context`. — Test: `bash tests/run.sh state-as-json.oracle.test.sh verbs-read-project-context.oracle.test.sh` green (the crate builds, nothing moved).
2. [x] **Stories carry dependencies, `Owns` and milestone.** `Story` gains `depends_on: Vec<String>` (every id the `- **Depends on**` / `- **Dépend de**` line holds, by the `story_id` pattern; `—`, `none`, `aucune` give none), `owns: Vec<String>` (each backticked entry of `- **Owns**`, verbatim) and `milestone: Option<String>` (the `## M…` section it sits in). Read only inside a story, like `Surface` (`framing.rs:438-443`). — Test: `test_state_output_does_not_move` (milestone counts unchanged); the parsing itself is first exercised by s168's oracle, and the reviewer reads it against `po-session.sh:182-185`.
3. [x] **Landed set records the landed commit.** `Landed::read` runs the same single `git log` with `--format=%H %s`; it keeps, per full id and per bare `s<n>`, the first (most recent) commit; `contains` unchanged; add `commit(id) -> Option<&str>`. — Test: `test_landed_lane_reports_ship_whatever_its_review`, `test_state_output_does_not_move` (milestone `shipped: 1`).
4. [x] **Open the decision reader.** In `po/src/inbox/mod.rs`: `pub use decision::Decision;` and a `pub fn read_decisions(dir) -> io::Result<(Vec<Decision>, Vec<PathBuf>)>` over `decision::read_dir`; `pending_ids` and `Pending` go (their one caller, `state/mod.rs:172`, moves to the context). No verb, refusal or message of `inbox`/`answer` changes; `locate` stays. — Test: `bash tests/run.sh decision-inbox.oracle.test.sh decision-inbox.test.sh answer-comes-back.oracle.test.sh answer-comes-back.test.sh` green.
5. [x] **`Context::read(project)`.** One function holding, with `pub` fields: `project` (root, `setting()` for any setting a later story needs, read without warning), `target`, the lane settings already read, `stories`, `landed`, `framing`, `milestone` (current), `lanes: Option<Vec<context Lane { story, path, stage, blocked_by }>>`, `inbox: Option<Inbox { dir, decisions, unreadable }>`, `warnings`. It performs the reads **in the order the research lists** (`## Order of reads`), runs no gate more than today, and keeps the landed rule first in `stage()` (`lanes.rs:209-211`). Fields only later stories read carry a scoped `#[allow(dead_code)]` with one line of why. — Test: `test_state_output_does_not_move` (warning order, every field), `test_landed_lane_reports_ship_whatever_its_review`.
6. [x] **New seam signatures.** `next::lane_next(&Context, &context::Lane) -> Option<NextAction>`, `next::ready(&Context)`, `next::held(&Context)`, `run::session(&Context)`, `run::bounds(&Context)`, `trust::shipped(&Context, &StateOptions)`; bodies still return `None`; `next::main`, `run::main`, `run::resume` still print `not-built`; `NextAction`, `Held`, `Session`, `Bounds`, `Shipped`, `Trust`, `StateOptions`, `state_options` stay where they are. Only these signatures and imports change in the three `mod.rs`. — Test: `test_state_prints_one_json_object` of s164 (fields `null`, verbs `not-built`).
7. [x] **`state` composed from the context.** `state::main` keeps its option parsing, `not-a-project` error and exit codes; `read` becomes `Context::read` then the `State` object: `waiting` = ids of `pending` decisions in the inbox order, `lanes[]` = context lanes with `next` from `lane_next(&ctx, lane)`, the six seams called with `&ctx`. `State` and the output `Lane` keep their field order. Then the full suite: `po-run --story s174-verbs-read-project-context --label "Unit suite" -- 'bash tests/run.sh'`. — Test: the whole s164 oracle and this story's oracle green; full suite green.

## Scene viewpoints
—

## Run interdicts
- `po/Cargo.toml`, `po/Cargo.lock`: empty diff (ADR-0118).
- `po/src/record/`, `po/src/output.rs`, `po/src/inbox/add.rs`, `po/src/inbox/rewrite.rs`, `po/src/inbox/decision.rs`: empty diff.
- In `po/src/next/`, `po/src/run/`, `po/src/trust/`: only `mod.rs`, and in it only seam signatures and `use` lines; no new file there, no computed value.
- `tests/state-as-json.oracle.test.sh`, `tests/decision-inbox*.test.sh`, `tests/answer-comes-back*.test.sh`, `method/`, `docs/interface-agent.md`, `bin/`: empty diff.
- No new `missing-setting` or other warning on any fixture; no git command beyond those `main`'s `po` runs; `GIT_OPTIONAL_LOCKS=0` kept on every git and gate call.
- No `cargo test` target and no Rust test module are added: the suite does not run them (`tests/run.sh:19-23`).

## The pivot
The oracle compares `po state` with output **frozen from `main`'s `po`** rather than building `Target branch`'s `po` inside the test. It could be wrong in three ways:
1. *The golden misses a field the refactor can move.* The four runs cover every field the six seams leave alone, each warning code reachable without a QA setting, and warning order across settings, lanes, worktrees and inbox. Uncovered: `no-gate`, the `QA stage` warnings, `merge-waiting`, `max-attempts`, `qa-blocked`, `root-cause-not-found` — the reviewer compares `stage()` and `blocked_by()` line by line with `main` (`lanes.rs:201-318`).
2. *A later story legitimately changes a compared field.* s168-s170 own `next`, `ready`, `held`, `session`, `bounds`, `shipped`, which the test drops; a story that adds a warning on these fixtures would break it and does not own this file. Compare with each later story's `Owns` before it runs.
3. *The s164 helpers this test sources get renamed* by a later owner of `tests/state-as-json.oracle.test.sh`; the test then fails loudly, not silently.

## Files touched
`po/src/context/` (new), `po/src/main.rs`, `po/src/state/mod.rs`, `po/src/state/framing.rs` and `po/src/state/lanes.rs` (moved or emptied), `po/src/next/mod.rs`, `po/src/run/mod.rs`, `po/src/trust/mod.rs`, `po/src/inbox/mod.rs`, `docs/research/…`, `docs/plans/…`, `docs/verif/…`, `tests/verbs-read-project-context.oracle.test.sh` (written by the planner).

## Test strategy
- Automated: the two oracle tests above (2 of `Test budget` 25), at the only layer this crate tests, the binary run on a throwaway repository. No `tests/verbs-read-project-context.test.sh`: no task adds a rule the oracle and s164's tests do not already reach; the deps/`Owns` parser gets its first test in s168, where its result becomes observable. A Rust unit test would not run in `Test`.
- Existing tests that guard the refactor without change: `tests/state-as-json.oracle.test.sh` (nulls, `not-built`, read-only, < 1 s, stages), `tests/state-as-json.test.sh`, `tests/decision-inbox*.test.sh`, `tests/answer-comes-back*.test.sh`.
- Bite checks for the reviewer: delete `lanes.rs:209-211` (or its moved copy) → `test_landed_lane_reports_ship_whatever_its_review` fails; move the inbox read before the lanes → `test_state_output_does_not_move` fails (both checked by the planner on `main`'s code).
- Visual checks: none.

## Done when
One commit on `story/s174-verbs-read-project-context` with code, research, plan, record and oracle; full suite green through `po-run`; review with no open critical finding; the PR closes #248 and #249.
