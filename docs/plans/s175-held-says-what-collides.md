---
validated: yes
---
# Plan — s175-held-says-what-collides

[Story](../stories.md) · [Research](../research/s175-held-says-what-collides.md)

Branch `story/s175-held-says-what-collides`. Read `docs/research/s175-held-says-what-collides.md` first; this plan builds on it without repeating it. Defect story (`Corrige` #280): the root cause is in `## Structuring facts` of the research — the pair of `Owns` entries is dropped at `po/src/next/wave.rs:55-58`, and nothing reads the start point.

## Story
`po next` and `po state` carry, in a `held` item of reason `owns`, the held story's overlapping entry, the holder's overlapping entry and one path both cover (`null` when the overlap is only kept by prudence); a story that would be ready but that no heading of `docs/stories.md` on the start point names is held with reason `framing`, `ref` the start point, keeping its `Parallel` slot. The contract describes both without moving its number.

- `owns_collision_names_the_path` — oracle.
- `story_off_the_start_point_is_held` — oracle.
- `contract_says_the_new_fields` — judged in review (document no script reads).
- `routing_cases_follow` — oracle, plus `test_every_routing_case_is_a_fixture` of s168.

Settled by the owner on 2026-11-14 (d-0012, option a): a value added to a closed list keeps `contract` at `1`, a reader tolerates a value it does not know. No ADR is written; ADR-0122 stays unused.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Common path of two entries | new code in `po/src/next/overlap.rs`, reusing its private `segments` (`:34`) and `matches` (`:43`) | `overlap` (`:4`) answers yes/no only and must not change; no glob crate allowed (ADR-0118) |
| Start-point ref and its story ids | the origin pattern of `po/src/context/lanes.rs:57-59`, `Project::on_target` (`po/src/project.rs:92`), `Stories::parse` (`po/src/context/stories.rs:100`) | already in the repository: only the glue is new |
| `Held` optional fields | `serde` already in the crate: `#[serde(flatten)]` on an `Option<Collision>` | standard serde attribute; no new dependency |
| Expectation `expect_collision` | the `expect_*` / `check_expectations` pattern of `tests/driver-next-action.oracle.test.sh:176-203` | already in the repository, one more kind |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/held-says-what-collides.oracle.test.sh` | `3031440734 7311` |

| Criterion | Test |
| --- | --- |
| `owns_collision_names_the_path` | `test_owns_collision_names_the_path` |
| `story_off_the_start_point_is_held` | `test_story_off_the_start_point_is_held` |
| `contract_says_the_new_fields` | none — document no script reads, judged in review; candidate for a `po-eval` control arm (#208), since an outside agent reads the tolerance rule |
| `routing_cases_follow` | `test_routing_cases_follow` (replays the cases calling `expect_collision` or expecting a `framing` hold, and checks their `collision` lines itself) |

The oracle ran on the code of `Target branch` on 2026-11-14: 0 passed, 3 failed, each for the defect named.

## Tasks
1. [x] **Start point, in the context.** In `po/src/context/` (in `stories.rs`, or a new `start.rs` declared in `mod.rs`), add `pub struct StartPoint { pub reference: String, ids: <set of ids> }` with `pub fn holds(&self, id: &str) -> bool`, read by `StartPoint::read(project, target, stories_on_target)`: when `git rev-parse --verify -q refs/remotes/origin/<target>` succeeds, `reference` is `origin/<target>` and the ids are those of `Stories::parse` on `project.on_target("origin/<target>", "docs/stories.md")` — no file there means no id; otherwise `reference` is `<target>` and the ids are those of the stories already read, with no second `git show`. `Context` gains `pub start: Option<StartPoint>`, `Some` exactly when `stories` is `Some` and `present`, read right after `stories` (`po/src/context/mod.rs:132`), pushing no warning. Nothing else of the context moves. Test: `test_story_off_the_start_point_is_held`; `tests/verbs-read-project-context.oracle.test.sh` stays green.
2. [x] **Common path.** In `po/src/next/overlap.rs`, beside `overlap`, `pub fn common_path(a: &str, b: &str) -> Option<String>`, called only on a pair `overlap` accepted. Walk the segments as `overlap` does, building a path: two equal plain segments → that segment; a `*` segment against a plain one it `matches` → the plain one; two `*` segments → `None`; one side ends (the other's rest being `**` only) → the path so far, as a file. On a `**` met on one side, with `after` the segments following it on that side and `rest` the other side from that position: any `*` in `after` → `None`; if `rest` ends with `**` (a folder), `body` is `rest` without it, else `body` is `rest`; any `*` in `body` → `None`; a folder `rest` gives path + `body` + `after`, rendered as a folder (trailing `/`) when `after` is empty; a file `rest` gives path + `body` only when `body` ends with `after`, else `None`. An empty path → `None`. Expected: `src/a/x.txt`×`src/a/` → `src/a/x.txt`; `crates/core/`×`crates/*/Cargo.toml` → `crates/core/Cargo.toml`; `src/`×`src/a/` → `src/a/`; `docs/y.md`×`docs/**/x.md` → `None`; `tests/a*.sh`×`tests/*.sh` → `None`. Any `Some(p)` is a path both entries cover. Test: `test_owns_collision_names_the_path`.
3. [x] **Held carries the collision and the framing hold.** In `po/src/next/mod.rs`, `Held` gains `#[serde(flatten)] pub collision: Option<Collision>` with `Collision { entry: String, ref_entry: String, path: Option<String> }` (same derives as `Held`); `None` serializes no key, `path: None` serializes `null`. In `po/src/next/wave.rs`, the `owns` branch (`:55-58`) keeps the same holder — the first of `taken` with an overlapping pair — and records the first entry of the held story, in its `Owns` order, overlapping one of the holder's, and the first such holder entry; `entry` is the held story's, `ref_entry` the holder's, `path` is `common_path(entry, ref_entry)`. Every other reason keeps `collision: None`. In the ready branch (`:61-64`), `slots -= 1` and `taken.push(story)` stay as they are; the story goes to `ready` when `start.holds(id)`, otherwise to `held` with reason `framing` and `ref` the start point's `reference`. `ready_and_held` returns `None` when `context.start` is `None`. Tests: both oracle tests above.
4. [x] **s168's oracle follows the new fields.** In `tests/driver-next-action.oracle.test.sh`: the exact array of `test_ready_and_held_say_why` (`:286-290`) gives `s03-charlie` `"entry": "src/a/x.txt", "ref_entry": "src/a/", "path": "src/a/x.txt"` — the story changes that clause, say so in the record; add `expect_collision <id> <entry> <ref_entry> <path|null>` writing `collision\t<id>\t<entry>\t<ref_entry>\t<path>` to `$SCRATCH/expect`, and a `collision` kind in `check_expectations` comparing `[.entry, .ref_entry, (.path // "null")]` of the held item (its `read` takes one field more); raise the replay floor (`:317`) from 54 to 56. Test: `test_ready_and_held_say_why`, `test_every_routing_case_is_a_fixture`.
5. [x] **Two routing cases.** `tests/fixtures/driver-cases/ready-set.cases` gains `case_ready_set_15_owns_names_the_path` (a lane on `crates/*/Cargo.toml`, a story on `crates/core/`: `expect_held … owns s01-alpha` and `expect_collision … 'crates/core/' 'crates/*/Cargo.toml' 'crates/core/Cargo.toml'`); `a-wave.cases` gains `case_a_wave_04_off_the_start_point` under `### Preparing the lanes` (`Parallel 2`, `origin/main` set by `update-ref` before a story is added on `main` ahead of an on-origin one: `expect_ready` the first, `expect_held <added> framing origin/main`, `expect_held <next> parallel`). Each with its one-line comment, as the files do. Test: `test_routing_cases_follow`, `test_every_routing_case_is_a_fixture`.
6. [x] **The contract.** In `docs/interface-agent.md`: the common rule (`:30`) adds that a value added to a closed list does not change `contract` either, and that a reader tolerates a value it does not know (in the spirit of ADR-0117); `held[].reason` (`:86`) adds `framing` — the story is not on the start point (`origin/<Target branch>` when that ref exists, `<Target branch>` otherwise), `ref` then holds a git ref, not a story or decision id, read in the local repository, no forge asked — and, for `owns`, `entry`, `ref_entry` and `path` (one path both cover, `null` when the overlap is only kept by prudence, e.g. two wildcards in one segment or `**/x.md` against `src/y.md`), the first overlapping pair in `Owns` order, absent for every other reason. No field removed or renamed. Judged in review.
7. [x] **Full suite and type check.** `po-run --story s175-held-says-what-collides --label 'Unit suite' -- 'bash tests/run.sh'` once every task is done (it builds `po`, which is the crate's type check).

## Scene viewpoints
—

## Run interdicts
- `method/commands/po-drive.md` and everything under `method/` end with an empty diff (s173 owns the prose).
- The body of `overlap` in `po/src/next/overlap.rs` ends with an empty diff: only additions in that file.
- `po/src/context/` changes only for the start-point read; `tests/verbs-read-project-context.oracle.test.sh` and `tests/state-as-json.oracle.test.sh` keep a zero diff and stay green.
- `po/Cargo.toml` and `po/Cargo.lock` end with an empty diff (ADR-0118: no dependency added).
- `po` runs no `fetch`, `ls-remote` or forge command: the start point is `rev-parse --verify` and `git show` only.
- No closed-PR rule here (issue #286); no `po/src/run/` change, though `po run` now counts a `framing`-held story as no work.
- `docs/decisions/` gets no file: ADR-0122 stays unused.

## The pivot
The framing hold sits **after** the `Parallel` check, keeping its slot and joining `taken`: that mirrors `/po-drive` today, which computes the batch (rule 3 counting the batch) and only then drops a lane whose heading is missing from the start point. Ways it could be wrong:
- A story held for `framing` then holds a later overlapping story for `owns` with a `ref` that has no lane. Compare with `po-drive.md` `## The ready set` rule 3 ("the other stories of the batch"): same behaviour, so kept; a reviewer who reads "keeps its place" as slot only would argue otherwise.
- Precedence: a story with an unmet dependency off the start point is held `dependency`, not `framing`, since the ready set is computed before the lanes are prepared. Compare with the order of `## The ready set` then `### Preparing the lanes`.
- `common_path` returning a path neither entry covers would be worse than `null`. Check every `Some` against both entries by hand on the five examples of task 2, and on `case_ready_set_07`/`10` (`crates/core/Cargo.toml`, `src/a/test.ts`).

## Files touched
`po/src/context/mod.rs`, `po/src/context/stories.rs` (or a new `po/src/context/start.rs`), `po/src/next/overlap.rs`, `po/src/next/mod.rs`, `po/src/next/wave.rs`, `tests/driver-next-action.oracle.test.sh`, `tests/fixtures/driver-cases/ready-set.cases`, `tests/fixtures/driver-cases/a-wave.cases`, `docs/interface-agent.md`, plus `tests/held-says-what-collides.oracle.test.sh` (oracle), this plan, the research and `docs/verif/s175-held-says-what-collides.md`.

## Test strategy
Every test is bash, through the `po` binary (the crate has no `#[cfg(test)]`); layer: the verb's output, where the rule lives.
- Oracle: 3 tests (above). Changed: `test_ready_and_held_say_why` (exact array), `test_every_routing_case_is_a_fixture` (floor 56) via 2 new cases. No `tests/held-says-what-collides.test.sh` unless the implementer finds a rule the oracle leaves uncovered (for instance `## <id>` at level two, or an `origin/main` with no `docs/stories.md`): one test each at most. Total new tests: 3 to 5, within `Test budget` 25.
- Bite: removing the framing check from `wave.rs` fails `test_story_off_the_start_point_is_held` and the `a-wave` case; dropping `collision` fails `test_owns_collision_names_the_path`, `test_ready_and_held_say_why` and the `ready-set` case; a `check_expectations` that ignores `collision` still fails `test_routing_cases_follow`.
- Judged in review: `contract_says_the_new_fields` — a `po-eval` control-arm candidate.
- Visual checks: none.

## Done when
The four criteria hold, the oracle file keeps its sum, the full suite is green through `po-run`, the review has no open critical finding, and the story lands as one commit `s175-held-says-what-collides: Une story retenue dit sur quoi elle bute`, closing #280.
