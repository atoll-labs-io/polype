---
validated: yes
---
# Plan — s186-stale-decisions-are-flagged

[Story](../stories.md) · [Research](../research/s186-stale-decisions-are-flagged.md) · [ADR-0127](../decisions/ADR-0127-une-decision-perimee-est-signalee.md)

Branch `story/s186-stale-decisions-are-flagged`. Read `docs/research/s186-stale-decisions-are-flagged.md` first; this plan builds on it without repeating it. The research was written before the story's rework: its `Owns gap` and its open questions are settled (story reworked, owner's answers d-0032 → 1-A and d-0033 → 2-A on 2026-11-16, ADR-0127 now `accepted`).

## Story
A pending decision whose stories have all shipped is flagged stale (#331); the contract says a decision holds its lanes until consumed (#279). Criteria: `decision_names_its_origin_story`, `stale_decision_is_flagged`, `framing_blocks_are_never_stale`, `answer_on_a_stale_decision_says_so`, `contract_says_held_until_consumed` (judged in review), `version_goes_up` (0.5.0 → 0.6.0).

Names fixed here (the story left them to the plan):
- **Origin field**: `story`, a string of the form `s<number>-<slug>` (`^s[0-9]+-[a-z0-9-]+$`, the form `Landed::read` accepts, `po/src/context/lanes.rs:101-104`). Optional on `po inbox add`; **absent** from the file and from every reply when not given (the `consumed` precedent, `po/src/inbox/decision.rs:63-66`), so a file written without it reads byte for byte as before.
- **Mark**: `"stale": true` on the decision object, absent otherwise. **`po state`**: a top-level field `stale`, the sorted ids of the stale `pending` decisions, beside `waiting` (unchanged, ids only).
- **Framing stage**: a `blocks` entry that does not have the story-id form (real ones: `stories`, `M22 framing`, research `:47`).

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Landed set read by `po inbox`/`po answer` | in this repository: `Landed::read`/`contains` (`po/src/context/lanes.rs:81,113`), `pub use` at `po/src/context/mod.rs:17`; `po state` reuses `context.landed` (`mod.rs:114`) | — |
| `Target branch` read in `inbox/` | in this repository: `project.setting(..)` as `find` reads `Decision inbox` (`po/src/inbox/mod.rs:136-137`) | — |
| `is_story_id` (whole-string form check) | new code, ~10 lines in `po/src/inbox/decision.rs` | `story_id` (`po/src/context/stories.rs:38`) matches a prefix only (`"s01-one/x"` passes) and is private in `context/`, outside `Owns`; the check inside `Landed::read` is inline, not a function; no crate is a dependency for it and a regex crate for one pattern is not worth adding |
| Staleness predicate | new code, one method `Decision::stale(&self, landed: &Landed) -> bool` in `decision.rs` | nothing computes it today (research, hypotheses 1-2) |
| Mark on the reply, never in the file | new code: a `#[derive(Serialize)]` wrapper `Shown { #[serde(flatten)] decision: &Decision, #[serde(skip_serializing_if = "std::ops::Not::not")] stale: bool }` in `po/src/inbox/mod.rs` | a field on `Decision` would be written by `rewrite` (`rewrite.rs:79`), which serialises the whole struct into the file; `output::reply` already flattens its body (`po/src/output.rs:32-35`) |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/stale-decisions-are-flagged.oracle.test.sh` | `1781457908 7230` |

| Criterion | Test |
| --- | --- |
| `decision_names_its_origin_story` | `test_decision_names_its_origin_story` — `po inbox add` with `story` accepted, returned and written; 8 malformed values refused by `malformed-decision`, nothing written; a file without `story` reads as itself; `po record review` (s178 fixture, minor finding) posts a decision whose `story` is the reviewed id |
| `stale_decision_is_flagged` | `test_stale_decision_is_flagged` — origin alone, `blocks` alone, both, unlanded; `po inbox`, `po inbox <id>`, `po state` (`waiting` ids, `stale` apart); no file holds the mark; landing the last story flips the rest |
| `framing_blocks_are_never_stale` | `test_framing_blocks_are_never_stale` — no story named; `architecture`, `stories`, `M22 framing` in `blocks` beside a landed story |
| `answer_on_a_stale_decision_says_so` | `test_answer_on_a_stale_decision_says_so` — recorded with the mark, file unmarked, `po inbox <id>` and `--answered` unmarked afterwards; on a decision that is not stale, the reply equals the file |
| `contract_says_held_until_consumed` | — a text no script reads: judged in review (candidate for a `po-eval` control arm, #208) |
| `version_goes_up` | `test_version_goes_up` — three places agree, at least 0.6.0 |

The oracle sources `tests/decision-inbox.oracle.test.sh` and `tests/security-findings-stay-private.oracle.test.sh` inside its tests for their fixtures; it was run once on the code as it stands: the five fail for the missing feature (unknown field `story`, no mark, `stale: null`, version 0.5.0), so the fixtures work.

## Tasks
1. [x] **Decision shape** (`po/src/inbox/decision.rs`): add `#[serde(default)] pub story: Option<String>` to `NewDecision` (`:22-35`, keeps `deny_unknown_fields`) and `#[serde(default, skip_serializing_if = "Option::is_none")] pub story: Option<String>` to `Decision` (`:48-69`), before `blocks`. Add `pub(crate) fn is_story_id(s: &str) -> bool` (whole string, `s`, ≥1 digit, `-`, ≥1 of `[a-z0-9-]`) and `impl Decision { pub fn stale(&self, landed: &Landed) -> bool }`: `false` unless `status == "pending"`; `false` when any `blocks` entry fails `is_story_id`; named = `story` ∪ `blocks`; `true` iff named is non-empty and every one `landed.contains`. Re-export `is_story_id` as `pub(crate)` from `inbox/mod.rs:19`. — fails: `test_stale_decision_is_flagged`, `test_framing_blocks_are_never_stale`.
2. [x] **`po inbox add`** (`po/src/inbox/add.rs`): in `validate` (`:74-104`), a `story` that fails `is_story_id` → `Err("story <value> is not a story id s<number>-<slug>")` (→ `malformed-decision`); in `write` (`:212-230`), `story: new.story`. — fails: `test_decision_names_its_origin_story` (first two parts).
3. [x] **`po record review`** (`po/src/record/security.rs:169-187`): `story: is_story_id(id).then(|| id.to_string())`. The guard keeps `po record review` of an id that is not in story form working as today (`parse` does not check the form, `po/src/record/mod.rs:91`): such a decision is posted without `story`, never refused. `blocks` unchanged. — fails: `test_decision_names_its_origin_story` (record part); implementer test in `tests/stale-decisions-are-flagged.test.sh`: a review recorded for an id not in story form still posts its decision, without `story`.
4. [x] **The mark on read and on answer** (`po/src/inbox/mod.rs`, `po/src/inbox/rewrite.rs`): add `Shown` (see Reuse) and `fn landed(project: &Project) -> Option<Landed>` reading `Target branch` (`Setting::Value(v) if v != "—"`), `None` otherwise — no mark, never a refusal. `list` (`:151-168`): `List { pending: Vec<Shown> }`, each marked by `decision.stale(&landed)`. `show` (`:191-213`): replies a `Shown`. `answered` (`:170-189`): unchanged (an answered decision is never stale). `rewrite`: the closure becomes `FnOnce(&mut Decision) -> Result<bool, Refusal>`, the `bool` being the mark, and the reply (`:91`) a `Shown`; the file is still written from `&decision` alone (`:79`). `answer` (`:47-72`): read the landed set before `rewrite`, compute `decision.stale(&landed)` inside the closure before setting `status`, return it. `consume` (`:86-95`) returns `Ok(false)`. — fails: `test_stale_decision_is_flagged`, `test_answer_on_a_stale_decision_says_so`.
5. [x] **`po state`** (`po/src/state/mod.rs`): `pub stale: Option<Vec<String>>` right after `waiting` (`:28`); in `compose` (`:56-64`), `Some` of the ids of `pending` decisions with `decision.stale(landed)` when both `context.inbox` and `context.landed` are `Some`, `None` otherwise (sorted like `waiting`: `read_dir` already sorts). Then `tests/verbs-read-project-context.oracle.test.sh:21`: add `.stale` to `del(...)` and name s186 in the comment above `normalised` (`:14-16`) — the only change there. — fails: `test_stale_decision_is_flagged` (`po state`), `test_framing_blocks_are_never_stale`; `test_state_output_does_not_move` keeps the other fields frozen.
6. [x] **Contract** (`docs/interface-agent.md`): example of `po state` (`:57`) gains `"stale": []`; a bullet after `waiting` (`:95`) for `stale` (ids of the `pending` decisions stale by the rule below, `null` when `waiting` is or when the landed set cannot be read); decision shape (`:131-163`): `story` (optional origin story, absent when not given, written by `po record review`), the stale rule (origin and `blocks` together, at least one, all landed on `Target branch`; a `blocks` entry not of story form is a framing stage and prevents the mark), `"stale": true` computed on read, present only on a stale `pending` decision in `inbox` and `inbox <id>`, never in the file; `:160` names `story` and `stale` as the fields that may be absent; `blocks` (`:159`) says a decision holds the lanes it names until it is consumed, answered or not, stale or not (#279, `case_decisions_02_answered_not_consumed`); the `malformed-decision` row (`:174`) adds "`story` qui n'a pas la forme `s<nombre>-<slug>`"; `## answer` (`:199`): on a stale decision the reply also carries `"stale": true`, the only place an answered decision shows it. `contract` stays `1` (d-0012). — judged in review.
7. [x] **Version** 0.5.0 → 0.6.0: `po/Cargo.toml:3`, `po/Cargo.lock` (`name = "po"`, `:164-165`), `POLYPE_VERSION` in `bin/polype:27`. — fails: `test_version_goes_up`; `bin/po-version-check` in the suite.

## Scene viewpoints
—

## Run interdicts
- Empty diff for `po/src/next/`, `po/src/context/`, `po/src/output.rs`, `method/` (including `method/hooks/po-session.sh`), `tests/fixtures/driver-cases/`, `.claude/`, `.polype/`: `po next` and the session do not change (story notes).
- No `contract` bump: `po/src/output.rs` keeps `CONTRACT = 1`.
- `"stale"` never appears in a decision file: no code path serialises `Shown` to disk; `rewrite` writes `Decision` only.
- `waiting` of `po state` stays a list of strings.
- `tests/decision-inbox.oracle.test.sh` (`:110`, `:248`), `tests/answer-comes-back.oracle.test.sh` (`:108`), `tests/security-findings-stay-private.test.sh` (`:85`), `tests/security-findings-stay-private.oracle.test.sh`, `tests/state-as-json.oracle.test.sh`, `tests/decision-inbox.test.sh`: **unchanged**. Why none of the assertions the story feared moves: `story` is absent when not given, so `:110` (reply equals file) and `:248` (same keys for every pending decision) see no new key — their fixtures never set it; the mark is absent on a decision that is not stale, and none of these fixtures lands a story; `:85` checks `blocks`, which task 3 leaves alone. If one of them turns red, stop and say which assertion and why in `## Oracle changes` of the record rather than editing it silently.
- The oracle file changes only through `## Oracle changes` of the verification record.

## The pivot
Everything hinges on **the stale rule read on the decision alone, against the landed set, with "not of story form" standing for "framing stage"**. How it could be wrong:
- A `blocks` entry that is a story id written loosely (`s178`, `S178-x`) counts as a framing stage, so the decision is never marked. Conservative by design (a wrong mark costs more than a missing one); compare with the real inbox files (`.polype/inbox/d-*.json`, main checkout): every `blocks` story entry there has the full form.
- `Landed::contains` also matches a bare `s<n>:` subject (`lanes.rs:113-121`): a story `s178-x` counts as landed when a commit `s178: …` exists. Same reading as `po next` and `po state` already use; nothing new.
- The mark in the reply but not the file relies on `Shown` being the only serialised form carrying it: check `rewrite.rs:79` writes `&decision`, not the wrapper, and that `Decision` has no `stale` field. A hand-edited file holding a `stale` key keeps it in `extra` (ADR-0117) and would print it twice on a stale decision; not handled, `po` never writes one.

## Files touched
`po/src/inbox/decision.rs`, `po/src/inbox/add.rs`, `po/src/inbox/mod.rs`, `po/src/inbox/rewrite.rs`, `po/src/record/security.rs`, `po/src/state/mod.rs`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, `tests/verbs-read-project-context.oracle.test.sh`, `tests/stale-decisions-are-flagged.oracle.test.sh` (oracle, written), `tests/stale-decisions-are-flagged.test.sh` (new), `docs/decisions/ADR-0127-une-decision-perimee-est-signalee.md` (accepted, written by the planner). All inside `Owns`.

## Test strategy
Every rule lives in `po` and is reached through its verbs, at the adapter layer the project tests everything at (bash + the built binary, real git, no mock).
- Oracle: 5 tests (above).
- `tests/stale-decisions-are-flagged.test.sh`, at most 3: (a) `po record review` of an id not in story form posts its decision without `story` (task 3's guard: removing it makes the record refused); (b) without `Target branch`, `po inbox` lists the decisions, unmarked, exit 0 (task 4's fallback); (c) optional: `po state` gives `stale: null` when `Decision inbox` is missing.
- Existing suites stay green unchanged except the one `del` of task 5. Total ≤ 8 new tests, within `Test budget` 25.
- Full suite once at the end through `po-run`; no type-check command is set (`Typecheck: —`): `cargo build` in `tests/run.sh` with `--locked` is the compile check.
- Mutation candidates for the reviewer: drop the framing guard in `stale` (framing test turns red); drop the `is_empty` check (framing test, d-0001); mark answered decisions (answer test); write `Shown` in `rewrite` (`files_unmarked`).

## Done when
The seven tasks are ticked; the oracle sum is unchanged or its changes recorded; `bash tests/run.sh` is green through `po-run`; one commit on `story/s186-stale-decisions-are-flagged` carrying code, tests, research, plan, ADR-0127 and the record; a review with no open critical finding.
