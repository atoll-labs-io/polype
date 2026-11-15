---
validated: yes
---
# Plan — s183-next-waits-on-dependencies

[Story](../stories.md) · [Research](../research/s183-next-waits-on-dependencies.md)

Branch `story/s183-next-waits-on-dependencies`. Read `docs/research/s183-next-waits-on-dependencies.md` first; this plan builds on it without repeating it. Fixes #306.

## Story
A lane whose story depends on a story not shipped yet gets `wait`, reason `dependency <id>`, from `po next` and `po state`; it takes no `Parallel` slot and holds no `Owns`; once the dependency ships it resumes where its files put it. `po` goes from 0.3.1 to 0.3.2. Criteria: `lane_waits_on_an_unshipped_dependency`, `waiting_lane_takes_no_slot`, `waiting_lane_holds_nothing`, `lane_resumes_once_shipped`, `version_goes_up`.

Root cause (research, `## Structuring facts`): the dependency rule exists only in the ready-set loop (`po/src/next/wave.rs:53`), which skips stories with a lane (`wave.rs:44`); `lane.rs:21-48` and `wave.rs:20-31` never read `depends_on`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `waiting_dependency(context, id) -> Option<&str>` in `po/src/next/mod.rs` | already in this repository: the shape of `holding_decision` (`mod.rs:110-121`) and the `find` of `wave.rs:53`, moved into one predicate | — (the first rung holds: no new logic, the ready set's rule shared with the lane) |
| Lane `wait` and the two exclusions | already in this repository: `act("wait", …)` (`lane.rs:28`), the competitor filter (`lane.rs:180`), `frees` (`wave.rs:20`) | — |
| Five routing cases, one oracle file | already in this repository: the fixture helpers and replay of `tests/driver-next-action.oracle.test.sh:24-326` | — |

## Acceptance tests
Each criterion is the first case of the owner's sorting of 2026-11-13: `po next` and `po state` already compute what it fixes, so its oracle test reads their JSON. The interface sentence of task 4 speaks to a reader (an external agent), so it gets no test: the reviewer judges it by reading.

| Oracle file | cksum |
| --- | --- |
| `tests/next-waits-on-dependencies.oracle.test.sh` | `2463146716 2566` |
| `tests/fixtures/driver-cases/ready-set.cases` | `3811447741 7076` |

| Criterion | Test |
| --- | --- |
| `lane_waits_on_an_unshipped_dependency` | `test_lane_waits_on_an_unshipped_dependency` (replays `case_ready_set_16_…`, then compares `po state`'s `lanes[].next`) |
| `waiting_lane_takes_no_slot` | `test_waiting_lane_takes_no_slot` (`case_ready_set_17_…`, `Parallel: 1`) |
| `waiting_lane_holds_nothing` | `test_waiting_lane_holds_nothing` (`case_ready_set_18_…`, overlapping `Owns`) |
| `lane_resumes_once_shipped` | `test_lane_resumes_once_shipped` (`case_ready_set_19_…`: `plan` / `research, no plan`, slot and `Owns` held again) |
| `version_goes_up` | `test_version_goes_up` (three places agree, above 0.3.1) |

`ready-set.cases` also gains `case_ready_set_20_waiting_lane_is_not_a_ship`, not a criterion: it guards the third place the research found (`ship()`), and runs through `test_every_routing_case_is_a_fixture`. On the code as it stands, cases 16, 17, 18 and 20 and `test_version_goes_up` fail; case 19 passes (it bites a fix that would wait forever or free a lane whose dependency shipped).

## Tasks
1. [x] **Shared predicate** — in `po/src/next/mod.rs`, beside `holding_decision`, add `fn waiting_dependency<'a>(context: &'a Context, id: &str) -> Option<&'a str>`: the first entry of the story's `depends_on`, in its order, that `context.landed` does not contain; `None` when `context.landed` or `context.stories` is `None` or the story is not in `docs/stories.md`. Make `wave.rs:53` call it instead of its own `find`, so the ready set and the lane read one rule. Test: `case_ready_set_03_dependency` and `test_ready_and_held_say_why` keep passing (the ready set's `dependency` unchanged).
2. [x] **The lane waits** — in `lane::next` (`po/src/next/lane.rs`), right after the landed check (`:24-26`) and before the decision check (`:27`), return `act("wait", format!("dependency {dependency}"))` when `waiting_dependency` names one. In `ship()`, add `&& waiting_dependency(context, &other.story).is_none()` to the competitor filter (`:176-181`), as for a decision. Tests: `test_lane_waits_on_an_unshipped_dependency`, `test_lane_resumes_once_shipped`, `case_ready_set_20_waiting_lane_is_not_a_ship`.
3. [x] **The lane holds nothing** — in `ready_and_held` (`po/src/next/wave.rs:20`), `frees` also returns true when `waiting_dependency(context, &lane.story)` is `Some`; `busy` and `taken` both read `frees`, so the lane leaves `Parallel` and stops holding `Owns`. The lane's story stays skipped by the loop (`:44`): it is in `actions` as `wait`, never in `ready` nor `held`. Tests: `test_waiting_lane_takes_no_slot`, `test_waiting_lane_holds_nothing`, `test_lane_resumes_once_shipped`.
4. [x] **The contract** — `docs/interface-agent.md`: on line 100, after "`reason` nomme la porte ou le fichier qui en décide", one sentence saying that `wait` carries `dependency <id>` when a story the lane's story depends on has not shipped, and that such a lane counts neither in `Parallel` nor for `owns` until it ships; on line 101, the `owns` reason reads that a lane in progress holds one of its paths, a lane waiting on a dependency holding none. `contract` stays `1` (a reason added, `docs/interface-agent.md:30`). Check: reviewer reading; no phrase test.
5. [x] **Version** — 0.3.1 → 0.3.2 in `po/Cargo.toml:3`, `po/Cargo.lock:165` (the `name = "po"` entry, by hand or by a plain `cargo build`, never `cargo update`) and `POLYPE_VERSION` of `bin/polype:27`, in the same edit: `tests/run.sh:23` builds `--locked`. Test: `test_version_goes_up`; after the commit, `bin/po-version-check` on the story branch exits 0.
6. [x] **Suite and commit** — full suite through `po-run` once every task is done; commit the code, the two oracle files, the research and the plan together. The research is not rewritten.

## Scene viewpoints
—

## Run interdicts
- Empty diff for `tests/fixtures/driver-cases/decisions.cases` and `ships.cases` (s185, s186), `tests/driver-next-action.oracle.test.sh` (its floor of 56 stays; the replay is untouched), `po/src/state/`, `po/src/context/`, `po/src/run/`, `method/`, `.polype/` (including `.polype/version`, which stays 0.3.1 until the installed copies are refreshed outside the story), `.claude/`.
- The two oracle files keep the sums above; a change goes through `## Oracle changes` of the record.
- No `NextAction` field added or renamed (`po/src/next/mod.rs:15-18`): the id travels in `reason`.
- A lane waiting on a decision keeps its slot and its `Owns`: `wave.rs` `frees` gains the dependency clause only.
- No `cargo update`: `po/Cargo.lock` changes on the `po` entry's version line only.

## The pivot
The lane's dependency is checked against the shipped set alone, before anything else the lane says, and releases the lane's slot and `Owns` at once. Ways it could be wrong:
- **Releasing `Owns` of a lane that already has code.** A lane at `execute`, `review` or `ship` whose dependency appeared later frees its paths; the dependency may then edit the same files and the waiting lane meets a conflict at its ship. The story asks for it (criterion 3, "même quand leurs `Owns` se recouvrent"); compare with `case_ready_set_18` and with Law 1's `Owns` rule, which bounds lanes that *run*: a waiting lane does not run.
- **Order against the other waits.** Dependency comes before decision and before every stop (`ask` for `Root cause: not found`, `Max attempts`…): a lane with both waits on its dependency first. This mirrors the ready set (`wave.rs:53-55`); check that no `ask` of `decisions.cases` or `resuming.cases` turns into `wait` (none of them declares a dependency).
- **An unreadable shipped set.** `waiting_dependency` returns `None` when `context.landed` is `None`, so the lane routes as before rather than waiting on nothing proven; `ready` and `held` are already `null` in that case (`wave.rs:12`).

**For the review — first `po/` change since s182.** This pull request is the first real run of `bin/po-version-check` inside the `suite` check, and of the full-history checkout (`fetch-depth: 0`, `.github/workflows/ci.yml:15-18`). Locally the suite test `tests/po-change-needs-a-version.test.sh` passes vacuously before the commit (it reads committed versions against `origin/main`), so the review notes: `bin/po-version-check` run on the committed story branch and its exit; the `suite` check of the pull request, its conclusion and its run URL; and, if the forge check fails on the base ref rather than on the version, that s182's ADR-0125 is what failed, filed as a defect, not fixed here.

## Files touched
`po/src/next/mod.rs`, `po/src/next/lane.rs`, `po/src/next/wave.rs`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, `tests/fixtures/driver-cases/ready-set.cases` (oracle, written), `tests/next-waits-on-dependencies.oracle.test.sh` (oracle, written), `docs/research/…`, `docs/plans/…`. No `tests/next-waits-on-dependencies.test.sh`: no test beyond the oracle is needed.

## Test strategy
Automated, all at the routing layer where the rule lives (`po next` / `po state` JSON on throwaway repositories), 5 oracle tests + 5 fixture cases, within `Test budget` 25. Cases 16–19 run twice, once through their criterion test and once through `test_every_routing_case_is_a_fixture`: the repository wants every routing case as a fixture (s168) and every criterion as a function of its oracle file; the cost is four scratch repositories, about a second. No Rust unit test (the crate has none; `po` is tested through its binary). Visual checks: none. Full suite once at the end through `po-run`; no type check command (`Typecheck: —`), `cargo build --locked` in `tests/run.sh` is the compile check.

## Done when
Every task ticked; the oracle files at their sums; full suite green on the story's code through `po-run`; `bin/po-version-check` exits 0 on the committed branch; review with no open critical finding and the forge `suite` check noted as above; landed as one commit `s183-next-waits-on-dependencies: Une lane dont la dépendance n'est pas livrée attend, sans rien retenir`.
