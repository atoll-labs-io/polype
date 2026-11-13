# Review — s164-state-as-json

[Story](../stories.md) · [Plan](../plans/s164-state-as-json.md) · [Verification](../verif/s164-state-as-json.md)

Diff reviewed: `git diff main...story/s164-state-as-json`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: ce0390e9e17f709e736a732ac8012bcea8ea7260

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s164-state-as-json`, and each path checked against the story's `Owns` using the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. `po/**`, `bin/polype`, `method/templates/agents-local.md`, `AGENTS.local.md`, `docs/interface-agent.md`, `docs/installation.md`, `.gitignore`, `evals/lib.sh`, `tests/lib.sh`, `tests/run.sh`, `tests/state-as-json.oracle.test.sh` and `tests/state-as-json.test.sh` are all covered by entries. The research, plan and verif files are the story's own evidence. `docs/decisions/ADR-0118-les-dependances-du-crate-po.md` is added (status `A`) and the plan names it, so it is in scope by construction.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows only the main checkout and this lane.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s164-state-as-json` exits 0, so the record is reused. `Verification mode: record`. Its last `Unit suite` run (`bash tests/run.sh`) exited 0, on code outside `docs/` that equals HEAD. The project has no type check (`Typecheck: —`). The suite's first step (`cargo build --release --locked`) type-checks the Rust. I read the record's "Not proven here" section: the panic reply, the branch where cargo fails, timing with many lanes, the CI runner, and the docs.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 9 and 8 bis are all present, and nothing outside the plan was added. `chrono` is declared but not used yet. ADR-0118 sets it once for s165, s166 and s170, as the plan says.
- [x] Each run interdict checked:
  - `method/` diff is limited to `agents-local.md`; `po-session.sh`, `po-gate.sh` and `method/AGENTS.md` are untouched.
  - `ci.yml`, `bin/po-ci`, `.claude/`, `.polype/` and `docs/a-trancher.md` are untouched, and no existing `tests/*.test.sh` changed.
  - No crate beyond option 1 bis; no `clap`, no `build.rs`, no network call.
  - No `deny_unknown_fields`: s164 parses no outside input. `inbox::DecisionStatus` is a narrow view that ignores unknown fields.
  - `po/src/` has exactly the layout in the plan.
  - `tests/lib.sh` only gains `PO`.

## References
- [x] Every import, call, API and configuration key opened and confirmed:
  - Gate CLI `po-gate.sh <gate> <id>`, called inside the lane.
  - `payload_dir`, `base` and `POLYPE_VERSION` (`bin/polype:27,36,41`); `is_payload_state_file` as used by `refuse_foreign_payload_files`.
  - `CARGO_PKG_VERSION` is `0.2.0`, which equals `POLYPE_VERSION` and `.polype/version`.
  - Every serde attribute.
- [x] No value that only looks right. I compared the ported rules line by line with `po-session.sh` and found them equivalent: settings reader, `Ship confirmation` suffix, scope and framing order, `Stories ready` first word, the "design system not needed" rule, worktree and orphan classification, shipped by full or short id, and the `blocked_by` conditions including the QA-evidence skip and `loops >= max`. On this repository, `po state` gives framing `stories-review` (main has no `docs/reviews/stories.md`, which the research expected) and milestone `M21` 10/0. It also warns `missing-setting: Decision inbox`, which is correct because main's `AGENTS.local.md` lacks that line until this story lands.

## Rules
- [x] `AGENTS.md` conventions respected: commits in English, tests in bash, the oracle written by the planner and intact (`po-gate oracle-intact` exits 0).
- [x] No accepted ADR contradicted. ADR-0095: `po` is a payload state file. ADR-0116: the hooks are unchanged. ADR-0117: `po` warns on another version and reads files through narrow views. ADR-0118: the dependencies match exactly.

## Tests
- [x] Floor: `po-gate floor-guard s164-state-as-json main` exits 0; nothing was lowered.
- [x] The assertions pin down the six criteria against the real binary, the real git, the real `po-gate` and the real installer. There are no mocks; stubs are used only to detect forge or model calls. None of the six empty test shapes is present.
- [x] Within `Test budget`: 10 of 25.
- [x] Bite, each undone and confirmed with `git diff --exit-code`. Each run covered `state-as-json.oracle.test.sh` and `state-as-json.test.sh`. I rebuilt `po/target` from the committed source afterwards.
  - `verif-current` gate flipped in `stage()`: 1 failing test (`lane_stage_follows_the_gates`).
  - `pending` filter removed in `inbox::pending_ids`: 1 failing test (`waiting_reads_the_inbox_setting`).
  - "Shipped → `ship`" rule removed from `stage()`: **0 failing tests**. See Findings.
- [x] No test is made useless by the story.

## Neighbours
- [x] Other callers read:
  - `is_payload_state_file` is used by `refuse_foreign_payload_files` for every flavour. `po` is now skipped there, as the plan intends, and `test_po_is_a_state_file_of_the_payload` covers it.
  - `tests/run.sh` now always exports a throwaway `CLAUDE_CONFIG_DIR` for every test file; the recorded full run is green.
  - `evals/lib.sh` `eval_base` is isolated in the same way.

## Lenses
Lenses run: dependencies (`po/Cargo.toml`, `po/Cargo.lock` added); performance (a gate process run per lane inside a loop in `po/src/state/lanes.rs`). Security and migration did not trigger.
- [x] Dependencies: one decision covers all three crates, and the plan and ADR-0118 name them. On Linux the tree is 14 crates (`cargo tree`). These are new dependencies, so there is no changelog delta. The build scripts are not mentioned anywhere; see Findings.
- [x] Performance: up to four `bash po-gate.sh` processes per lane run one after another. The plan's pivot accepts this, and it is timed on 7 lanes and on this repository, under one second. The potential impact grows with the lane count; it is bounded by `Parallel`, so there is no finding.

## Findings
- major — po/src/state/lanes.rs:209 — The rule "a story shipped on `Target branch` → stage `ship`" is not tested. With the three lines removed, all 10 story tests still pass. The `s07-landed` fixture of `test_lane_stage_follows_the_gates` also carries a passing review on unchanged code, so the `ship-allowed` gate already returns `ship` and hides the rule. That rule is what reports a landed lane still on disk (its clean-up), which the plan's stage table depends on. A landed lane whose review no longer matches the code (for example, a fix commit after the landing) would never show it. A fixture where the landed lane has no passing review, or code changed after its review, would make the test bite.
- major — po/src/next/mod.rs:28 — The seams s164 gives later stories carry no context. `lane_next(&str, Option<Stage>)`, `ready()` and `held()` (called at `po/src/state/mod.rs:159-160`), plus `run::session()` and `trust::shipped(&StateOptions)`, receive no project root, no lane path, no parsed stories, no shipped set and no settings. Meanwhile `Stories`, `Shipped` and the worktree listing are private to `state/`: `mod framing;` is private, and only `Framing` and `Milestone` are re-exported. s168's `Owns` is `po/src/next/` alone, and it must compute `fix` from a lane's review, `ready` and `held` from the stories, the shipped set, the lanes and `Owns`, and serial ships across lanes. It can only do this by either re-implementing the whole derivation inside `next/` (duplicate parsing) or editing `po/src/state/`, which is outside its `Owns`. This goes against the story's own note: « les stories suivantes remplissent leur dossier sans toucher aux tiens ». The research asked the reviewer to check whether s168 can route. The stage values themselves are routable (blocked review vs. landed lane can be told apart from files), but not through this interface.
- minor — po/Cargo.lock — The dependencies lens asks that install scripts be read. The lockfile brings in crates with build scripts (`serde`, `serde_core`, `serde_json`, `proc-macro2`, `num-traits` via `autocfg`, and others), and neither the record nor the plan says they were read.

## Not verified
- CI on a fresh `ubuntu-latest` runner: `ci.yml` is unchanged and relies on the image's cargo. This shows only when the PR's checks run. A person should confirm the `bin/po-ci` check is green on the pull request.
- The panic hook's `internal` reply and the installer's "cargo could not build po" branch. No test triggers them; I judged them by reading only (`po/src/output.rs`, `build_po` in `bin/polype`). Check by hand with a deliberate `panic!()` build and a crate broken on purpose.
- `po state` timing with many lanes. It was only measured on 7 lanes and on this repository; time it on a fixture with many lanes before s168 adds more work per lane.
- The docs of task 8 (`docs/interface-agent.md`, `docs/installation.md`) were judged by reading; no script checks them.
- `tests/run.sh` now needs cargo and, for the first build, network access to fetch crates. I did not check this on a machine without network or cargo; it is a contributor-facing change to verify once.
- The real `~/.claude/polype/po` on this machine was not installed or exercised: the review ran only in throwaway config directories.

Max severity: major
Ship allowed: yes
