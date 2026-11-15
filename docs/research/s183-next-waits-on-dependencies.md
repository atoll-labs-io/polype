# Research — s183-next-waits-on-dependencies

[Story](../stories.md)

## Structuring facts
- Root cause: the dependency rule lives only in the ready-set loop, which skips every story that has a lane (`po/src/next/wave.rs:44` `continue`, rule at `wave.rs:53`); lane routing (`po/src/next/lane.rs:21-48`) and lane accounting (`wave.rs:20-31`: `frees`, `busy`, `taken`) never read `Story.depends_on`. Input: a lane `s02` whose `Dépend de` names an unshipped `s01`. Proof: reproduction below, `s02` gets `plan` and `s01` is held `parallel` (Parallel 1) or `owns s02` (overlap).
- False assumption of the story: `docs/interface-agent.md:100` does not list the reasons of `wait`; it lists the `next.action` values and says `reason` "nomme la porte ou le fichier qui en décide". No closed list of `wait` reasons exists anywhere (`decision <id>`, `merge waiting`, `ships serial: <id>` live only in `lane.rs:28,173,189`). The doc change is a new sentence on that line, not a value appended to a list; `contract` stays `1` either way (`docs/interface-agent.md:30`).
- Hidden third place: `ship()` (`lane.rs:171-191`) ranks every lane at stage `ship` that is not landed, merge-waiting or held by a decision. A lane waiting on a dependency would stay a competitor and hold every other ship behind it with `ships serial: <id>` — reproduced by fixture case 20 below. The fix must exclude it there too, as `lane.rs:180` already does for a decision.
- `po state` needs no change: it calls `next::lane_next` (`po/src/state/mod.rs:71`) and `next::ready`/`next::held` (`state/mod.rs:87-88`), so it carries whatever `po/src/next/` computes.

## Diagnostic
**Reproduction** (built with `CARGO_TARGET_DIR=/tmp/s183-target`, nothing written in the worktree; scratch project from the helpers of `tests/driver-next-action.oracle.test.sh`, script in `/tmp/s183-repro/repro.sh`): stories `s01-alpha` (`src/a/`), `s02-bravo` depends on `s01-alpha`; lane `s02-bravo` with a research.
- `Parallel: 1`: `po next` → `actions: [{s02-bravo, plan, "research, no plan"}]`, `ready: []`, `held: [{s01-alpha, parallel}]`. `po state` gives the lane the same `plan`.
- `Parallel: 3`, `s02` owning `src/a/x.txt`: `held: [{s01-alpha, owns, ref s02-bravo, path src/a/x.txt}]`.
- After `s01-alpha` lands: `s02` stays `plan`, `held: []`.
That is #306: s172's lane went to `plan` while it retained s176, its own dependency.

**Hypotheses**
| # | Hypothesis | Observation that would refute it | Verdict |
| --- | --- | --- | --- |
| H1 | Lane routing ignores dependencies | `lane::next` returns something other than a stage action for the repro lane | kept: `plan`; `depends_on` is read only at `wave.rs:53` (grep over `po/src`) |
| H2 | The ready set's dependency check never sees a story with a lane | the lane's story appears in `held` with `dependency` | kept: absent from `held`; `wave.rs:44` skips it |
| H3 | A lane always takes a slot and its `Owns` unless landed or past `Max attempts` | `s01` ready with `Parallel: 1` | kept: held `parallel`/`owns`; `wave.rs:20` |
| H4 | The parser misses the `Dépend de` line | the same line form holds a story without a lane | discarded: `case_ready_set_03_dependency` passes; `po/src/context/stories.rs:139-140` reads both labels |
| H5 | The shipped set misreads `s01` | after landing, `s01` still held or listed | discarded: after `land s01-alpha`, `held: []` and `s01` absent |

H1–H3 are one cause: the rule was written for the ready set only.

## Story
`po next` makes a story that already has a lane wait while a story it depends on has not shipped, so the fleet no longer locks itself when a story is inserted in front of an open lane. Criteria: `lane_waits_on_an_unshipped_dependency` (`wait`, reason `dependency` with the id; `po state` the same), `waiting_lane_takes_no_slot`, `waiting_lane_holds_nothing`, `lane_resumes_once_shipped`, `version_goes_up` (patch, three places).

## Current code
- `po/src/next/lane.rs:21-84` `next`: landed → `ship` (`:24`), decision → `wait "decision <id>"` (`:27-29`), then stage rules. `ship()` `:171-191`, competitor filter `:176-181`.
- `po/src/next/wave.rs:9-74` `ready_and_held`: `frees` (`:20`) = landed or `MaxAttempts`; `busy` (`:21-24`) = lanes not freed and not merge-waiting; `taken` (`:27-31`) = stories of lanes not freed (their `Owns` hold others); loop skips landed, laned, orphaned stories (`:44`), then dependency (`:53`), decision, owns, parallel, framing.
- `po/src/next/mod.rs:110-121` `holding_decision`: the shared per-story predicate both files use.
- `po/src/context/lanes.rs:113` `Landed::contains(&self, id: &str) -> bool`; `context.landed: Option<Landed>`; `Stories::find(id)` `stories.rs:148`.

## Attachment points
- New shared predicate beside `holding_decision` in `po/src/next/mod.rs` (first dependency not landed, `None` when stories or landed are unreadable).
- `lane.rs` `next`, between the landed check (`:24`) and the decision check (`:27`), mirroring the ready set's order (dependency before decision, `wave.rs:53-55`).
- `lane.rs` `ship()` competitor filter `:176-181`.
- `wave.rs:20` `frees`, which feeds both `busy` and `taken`; `wave.rs:53` may reuse the predicate.
- `docs/interface-agent.md:100` (`next.reason`) and `:101` (`held[].reason` `owns`: "une lane en cours tient un de ses chemins").
- Version: `po/Cargo.toml:3`, `po/Cargo.lock:165`, `bin/polype:27` (`POLYPE_VERSION="0.3.1"`).

## Verified interfaces
- `NextAction { action: String, reason: String }` (`mod.rs:15-18`): no `ref` field, so the id travels in `reason`, as `decision d-0001` does (`decisions.cases:11`).
- `pub fn lane_next(context, lane) -> Option<NextAction>` (`mod.rs:98`), used by `po next` (`mod.rs:73`) and `po state` (`state/mod.rs:71`).
- Fixture helpers (`tests/driver-next-action.oracle.test.sh:24-181`): `story <id> <surface> <deps> [owns…]`, `lane`, `research_in`, `land`, `recorded_lane`, `review_in`, `reviewed_at`, `expect_lane|ready|held`; replay by `test_every_routing_case_is_a_fixture` (`:300-326`, floor 56 cases, now 61 with this story's five).
- `bin/po-version-check` compares committed `HEAD` with its merge base on `origin/<Target branch>` (`bin/po-version-check:24-60`); run on this repository by `tests/po-change-needs-a-version.test.sh:6`.

## Traps
- `tests/run.sh:23` builds with `cargo build --locked`: `po/Cargo.lock` must carry the new version in the same edit as `Cargo.toml`, or the whole suite stops at "po does not build".
- `bin/po-version-check` reads committed versions (`git show HEAD:…`): run before the story's commit, the suite test `po-change-needs-a-version.test.sh` passes vacuously (HEAD = `origin/main`). The real proof is the `suite` check on the pull request (full history via `fetch-depth: 0`, `.github/workflows/ci.yml:15-18`); this is its first run on a `po/` change (s182's note, `docs/stories.md:2948`).
- `.polype/version` stays `0.3.1` (installed copy, never edited by a story): after this story `po state` on this repository warns `method-version-mismatch` until the next installed-copy refresh, as after s180.
- No existing fixture or test opens a lane for a story with an unshipped dependency (grep of `story … s0` lines and `Depends on`/`Dépend de` in `tests/`): `project-lead.test.sh:61-80` and `state-carries-session-lines.oracle.test.sh:190` open a lane only for `s04-d`, which has none. A prototype of the fix built in `/tmp` passed every test of `driver-next-action.oracle.test.sh`, `held-says-what-collides.oracle.test.sh`, `state-carries-session-lines.oracle.test.sh`, `project-lead.test.sh`, `state-as-json.oracle.test.sh` and `short-subject-shipped.test.sh`, and the four routing oracle tests.
- Releasing a waiting lane's `Owns` lets its dependency edit the same files: the waiting lane may later meet a conflict at its ship. The story asks for it (criterion 3); the plan names it as the pivot.
- `decisions.cases` and `ships.cases` belong to s185/s186 (story note): the ship-serial case of this story goes into `ready-set.cases`.

## Open questions
- Should a lane waiting on a decision also free its slot? Out of scope (story names dependencies only); not changed.

## Complexity
Story 2 → 2: three small edits in one folder, plus a third place (`ship()`) the story did not name, a doc sentence and a version bump. No migration, no new dependency, no structural choice.
