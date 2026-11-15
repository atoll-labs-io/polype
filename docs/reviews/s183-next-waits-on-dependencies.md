# Review — s183-next-waits-on-dependencies

[Story](../stories.md) · [Plan](../plans/s183-next-waits-on-dependencies.md) · [Verification](../verif/s183-next-waits-on-dependencies.md)

Method version: 0.3.1

Diff reviewed: `git diff main...story/s183-next-waits-on-dependencies`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: f6c253ed0c3b6f1702520b7faeec031ef70a7130

## Ownership
Diff listed with `git diff --name-only main...story/s183-next-waits-on-dependencies`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. `po/src/next/{lane,mod,wave}.rs` falls under `po/src/next/`. `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, `tests/fixtures/driver-cases/ready-set.cases` and `tests/next-waits-on-dependencies.oracle.test.sh` are each listed by name. The research, plan and verification files are the story's pipeline evidence.
- [ ] Outside `Owns`: none
- [ ] Inside another running story's `Owns`: none
- [ ] No `Owns` line: not the case, the line is present

## Evidence reused
- [x] `po-gate verif-current s183-next-waits-on-dependencies` → exit 0, record reused (`Verification mode: record`). The unit suite `bash tests/run.sh` exited 0 on the recorded code. Type check: none, because the project's `Typecheck` is `—`. The `cargo build --locked` inside `tests/run.sh` is the compile check.
- [x] `po-gate qa-current`: not required. The story does not go to QA (`QA stage: —`).

## Plan
- [x] All six tasks are present, and nothing outside the plan. `waiting_dependency` sits beside `holding_decision` in `po/src/next/mod.rs:110-115`. The ready set reuses it at `wave.rs:57`. The lane waits in `lane.rs:27-29`, after `landed` and before the decision check. The `ship()` competitor filter is at `lane.rs:184` and the `frees` clause at `wave.rs:20-24`. The interface sentences are at `docs/interface-agent.md:100-101`. The version is 0.3.2 in all three places.
- [x] Each run interdict checked:
  - `decisions.cases`, `ships.cases`, `tests/driver-next-action.oracle.test.sh`, `po/src/state/`, `po/src/context/`, `po/src/run/`, `method/`, `.polype/` and `.claude/` have an empty diff.
  - `NextAction` is unchanged.
  - `frees` gains only the dependency clause, so a lane waiting on a decision keeps its slot and its `Owns`.
  - In `Cargo.lock`, only the `po` version line changed.

## References
- [x] Every import, call, API and configuration key confirmed: `Landed::contains`, `Stories::find`, `Story.depends_on` (`po/src/context/stories.rs:11,140`) and `lane_next`, which `po state` calls at `po/src/state/mod.rs:71`. The crate builds `--locked`.
- [x] No value that only looks right. `waiting_dependency` returns `None` when `landed` or the stories cannot be read, which matches `wave.rs:12`. The reason format `dependency <id>` mirrors `decision <id>`. `bin/po-version-check` on the committed branch prints `po at 0.3.2, consistent with origin/main` and exits 0.

## Rules
- [x] `AGENTS.md` conventions respected. The oracle is in `tests/<slug>.oracle.test.sh` and there is no empty `.test.sh`. The code comments are in English.
- [x] No accepted ADR contradicted. The `contract` stays `1` because a reason is added and no field.

## Tests
- Oracle: `po-gate oracle-intact s183-next-waits-on-dependencies` → exit 0
- [x] Floor: `po-gate floor-guard s183-next-waits-on-dependencies main` → 0, nothing lowered. `po-gate oracle-intact` → 0. Both oracle files match the plan's sums (`2463146716 2566`, `3811447741 7076`).
- [x] Assertions pin the criteria through the real `po next` / `po state` JSON on throwaway repositories, and none of the six empty shapes appears. Case 19 checks that the lane resumes at `plan` and holds `Owns` again. Case 20 checks that the lane is excluded from the ship ranking.
- [x] Within `Test budget` 25: 5 oracle tests and 5 fixture cases.
- [x] Bite 1: `lane.rs` dependency wait disabled (`.filter(|_| false)`) → 4 failing tests (`lane_waits_on_an_unshipped_dependency`, `waiting_lane_holds_nothing`, `waiting_lane_takes_no_slot`, `every_routing_case_is_a_fixture`) → undone, `git diff --exit-code po/src/next/lane.rs` clean.
- [x] Bite 2: the `wave.rs` `frees` dependency clause disabled → 3 failing tests (`waiting_lane_holds_nothing`, `waiting_lane_takes_no_slot`, `every_routing_case_is_a_fixture`) → undone, `git diff --exit-code po/src/next/wave.rs` clean. Both bites were built with `CARGO_TARGET_DIR` under `/tmp/tmp.KXpeHBI8LV`, and the worktree's `git status` is clean after them.
- [x] No test made useless.

## Neighbours
- [x] Callers of the changed code read: `po next` (`mod.rs:73`), `po state` (`state/mod.rs:71,87-88`), the ready-set loop and `ship()`. Nothing broken; the dependency rule of the ready set behaves as before (`case_ready_set_03` passes in the replay).

## Lenses
Lenses run: dependencies — triggered by `po/Cargo.lock` and `po/Cargo.toml` among the paths. Only the crate's own version changed; no dependency was added, removed or bumped.
- [x] No lens finding.

## Findings
- none

## Not verified
- The forge `suite` check on the pull request. The plan asks for its conclusion and run URL, because it is the first real run of `bin/po-version-check` with `fetch-depth: 0` on a `po/` change. No pull request exists yet. Locally, `bin/po-version-check` on the committed branch exits 0. A person or `/po-ship` should note the check's result. If it fails on the base ref rather than on the version, file it as a defect of s182 (ADR-0125).
- The `ship()` exclusion (`lane.rs:184`) was not bitten. It is held by fixture case 20, which runs only through `every_routing_case_is_a_fixture`. In that case the ship-stage lane `s02` returns `wait dependency` from `next()` before `ship()` is reached, and the case's expectation on `s03` is what would turn red. I did not confirm that.
- Two cases have no test and were judged by reading only:
  - A lane already `merge-waiting` (pull request open) whose dependency is not shipped. Its action becomes `wait dependency <id>` instead of `wait merge waiting`. `lanes[].stops` and `blocked_by` still say `merge-waiting`. It also releases its `Owns` while its pull request is open. The story accepts this release explicitly (criterion 3 and the plan's pivot).
  - A dependency cycle between two open lanes. Both would wait indefinitely, holding nothing.

  A person should confirm that this behaviour is wanted.
- After this ship, `.polype/version` stays at 0.3.1 until the installed copies are refreshed, so `po state` on this repository will warn `method-version-mismatch` (research, `## Traps`). This is expected and was not checked here.

Max severity: none
Ship allowed: yes
