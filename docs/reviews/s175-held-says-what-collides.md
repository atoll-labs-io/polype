# Review — s175-held-says-what-collides

[Story](../stories.md) · [Plan](../plans/s175-held-says-what-collides.md) · [Verification](../verif/s175-held-says-what-collides.md)

Method version: 0.2.0

Diff reviewed: `git diff main...story/s175-held-says-what-collides`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: d9021a4fa6afbaa216d72f884535633f1a5d92d8

## When blocked
- Not blocked.

## Ownership
I listed the diff with `git diff --name-only main...story/s175-held-says-what-collides` and checked each path against the story's `Owns`, using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`:
  - `po/src/context/mod.rs` and `po/src/context/start.rs` fall under `po/src/context/`.
  - `po/src/next/{mod,overlap,wave}.rs` fall under `po/src/next/`.
  - `docs/interface-agent.md`, `tests/driver-next-action.oracle.test.sh` and `tests/held-says-what-collides.oracle.test.sh` are listed by name.
  - The two `.cases` files fall under `tests/fixtures/driver-cases/`.
  - The research, plan and verif files are the story's own evidence.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. The two other worktrees are s171, which owns `bin/po-release`, `bin/polype`, `tests/run.sh` and similar, and s173, which owns `method/commands/po-drive.md`, `po-execute.md`, its tests and `bin/po-lint`. Neither shares a path with this diff. s170 also owns `po/src/context/mod.rs`, but it has no worktree and it depends on s175.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s175-held-says-what-collides` exits 0. I reused the record: Unit suite `bash tests/run.sh`, exit 0, at 2026-11-14T09:04:09Z.
  - The project has no type check (`Typecheck: —`); the `cargo build` inside `tests/run.sh` stands in for it.
  - I read the record's "Not proven here" section and carried its items to Not verified.
- [x] `po-gate qa-current`: not required, because `QA stage: —` sends no story to QA.

## Plan
- [x] Tasks 1–7 are all present, and nothing is outside the plan.
  - Task 1: `StartPoint` lives in a new `start.rs`, declared in `mod.rs` and read right after `stories`.
  - Task 2: `common_path` was added beside `overlap`.
  - Task 3: `Held.collision` uses flatten, and the framing hold comes after the `Parallel` slot is taken.
  - Task 4: s168's oracle follows the new fields; the change is declared in `## Oracle changes` of the record.
  - Task 5: two new routing cases.
  - Task 6: the contract.
  - Task 7: the record.
- [x] Each run interdict holds:
  - `method/` is unchanged.
  - The body of `overlap` is unchanged; that file only gains lines.
  - `po/src/context/` changes only for the start-point read.
  - `tests/verbs-read-project-context.oracle.test.sh` and `tests/state-as-json.oracle.test.sh` are unchanged.
  - `po/Cargo.toml` and `po/Cargo.lock` are unchanged.
  - There is no fetch, ls-remote or forge call: only `rev-parse --verify -q` and `git show`. The oracle's git and forge stubs confirm this.
  - `po/src/run/` is unchanged, and no file was added under `docs/decisions/`.

## References
- [x] I opened and confirmed every call and type the diff uses:
  - `Project::git` and `Project::on_target` (`po/src/project.rs:69,92`)
  - `Stories::parse` (`po/src/context/stories.rs:100`, accepts headings of level 2 and deeper)
  - `segments` and `matches` (`overlap.rs:34,43`)
  - the origin pattern of `lanes.rs:57-59`
  - `Collision`, imported in `wave.rs`
- [x] I checked `common_path` by hand on the plan's five examples, on `src/a/x.txt`×`src/a/`, `po/`×`po/`, `docs/**/x.md`×`docs/a/x.md`, `**/x.md`×`src/y.md`, and on glob/glob pairs. Every `Some` it returns is covered by both entries, apart from the edge case in the second finding.

## Rules
- [x] The `AGENTS.md` conventions are respected: tests are bash, the oracle file is unchanged (cksum), and the edit to s168's oracle is declared.
- [x] No accepted ADR is contradicted. ADR-0118 holds (no glob crate, no new dependency), and the contract number stays `1` as the owner settled on 2026-11-14 (d-0012).

## Tests
- Oracle: `po-gate oracle-intact s175-held-says-what-collides` → exit 0
`Oracle: po-gate oracle-intact s175-held-says-what-collides` → 0.
- [x] Floor: `po-gate floor-guard s175-held-says-what-collides main` → 0. Nothing was lowered; the replay floor went up from 54 to 56.
- [x] The assertions pin down the criteria, and none of the six shapes of test that prove nothing appears:
  - The tests use exact JSON objects through the real `po` binary on throwaway repositories.
  - `po state` is compared field by field with `po next`.
  - Git and forge are stubbed only to log calls; the real git still runs.
- [x] The tests stay within `Test budget` 25: three new oracle tests, two fixture cases and two edited s168 tests.
- [x] Bite 1: I turned `if start.holds(id)` into `if true || …` in `po/src/next/wave.rs`. **3 tests failed**: `story_off_the_start_point_is_held`, `routing_cases_follow` and `every_routing_case_is_a_fixture`. I undid it with `git checkout`, and `git diff --exit-code` came back clean.
- [x] Bite 2: I made `path: common_path(mine, theirs)` always `None` in `wave.rs`. **4 tests failed**: `owns_collision_names_the_path`, `routing_cases_follow`, `every_routing_case_is_a_fixture` and `ready_and_held_say_why`. Undone the same way; `git diff --exit-code` clean.
- [x] The story leaves no test useless.

## Neighbours
- [x] `ready_and_held` has three callers: `po next` (`next/mod.rs:68`), `next::ready` (used by `po run`, `run/mod.rs:168`) and `next::held` (`po state`). A story held for `framing` no longer counts as ready for `po run`; the plan accepts this.
- [x] `Context::read` now runs one extra `rev-parse`, plus a `git show` when origin exists, for every verb. That cost is negligible, and no other field moves.

## Lenses
Lenses run: none. There are no auth, migration, lockfile or manifest paths, and `po` is a local CLI with no server-side code or query loop.
- [x] No lens findings.

## Findings
- minor — po/src/next/overlap.rs:93 — `common_path` returns `None` (JSON `path: null`) whenever the side opposite a `**` holds a glob segment.
  - This also covers overlaps that are certain, not just kept by prudence. Examples: `x/*.md` against `x/`, or a literal `src/**` against `src/*.ts`; both entries cover any `x/foo.md`.
  - The contract (`docs/interface-agent.md:86`) says `path` is `null` "quand le recouvrement n'est gardé que par prudence". A reader would wrongly conclude these pairs may not really collide.
  - Fix either the wording (null also when no concrete path can be named without inventing a file name) or the code. Not wrong data, only an imprecise contract.
- minor — po/src/next/overlap.rs:68 — when one side ends where the other has only a trailing `**`, the shorter entry is returned as a file.
  - For a file entry `src/a` against a folder `src/a/`, it returns `src/a`, which is the folder itself rather than a path beneath it.
  - `overlap` already accepts that unusual pair, so this is an edge case with no realistic `Owns` line behind it, but the returned path is not strictly "un chemin que les deux couvrent".

## Not verified
- I did not re-run the full suite: the record proves it for this code (`Verification mode: record`).
- **The worktree's `po/target/release/po` was stale, so do not trust test runs that use it.** At review time it had been built at 10:03 CET from sources without `start.rs`, and cargo still considered it fresh. Run against that binary, the two oracle files fail.
  - My runs used a separate fresh build (`CARGO_TARGET_DIR=/tmp/tmp.eS0E4dZsPP/target`): 10/10 tests pass on the committed code.
  - I could not tell which process wrote that binary. Its timestamps do not fit a build from the committed sources, so I suspect something else in the environment, outside this story's diff.
  - A person should run `cargo clean --manifest-path po/Cargo.toml` (or delete `po/target/`) in this worktree before the next local run.
- `contract_says_the_new_fields` is judged by reading only: no script reads it, as the plan says. It is a candidate for a `po-eval` control arm (#208), not covered here.
- That `po run` counts a story held for `framing` as no work is untested; the plan deliberately leaves `po/src/run/` alone. If it matters, a person should check `po run` on a project whose only candidate is off `origin/main`.
- A real repository with a fetched `origin/main` lagging behind local `main` was only simulated with `update-ref` in throwaway repositories, never with a real remote.
- The project has no end-to-end, build or lint stage (`E2E: —`, `Build: —`).

Max severity: minor
Ship allowed: yes
