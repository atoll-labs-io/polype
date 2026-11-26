# Review — s214-suite-holds-with-a-published-po

[Story](../stories.md) · [Plan](../plans/s214-suite-holds-with-a-published-po.md) · [Verification](../verif/s214-suite-holds-with-a-published-po.md)

Method version: 0.11.0
Recorded: 2026-11-26T01:50:51+01:00

Diff reviewed: `git diff main...story/s214-suite-holds-with-a-published-po`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 45fdc5440619b0f8e8bf90eb6a77954fdf3f36d5

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Ownership
Diff listed with `git diff --name-only main...story/s214-suite-holds-with-a-published-po`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. The two test files, `tests/state-as-json.test.sh` (M) and `tests/suite-holds-with-a-published-po.oracle.test.sh` (A), lie under `tests/`. `docs/plans/…` and `docs/verif/…` are the story's own pipeline evidence.
- [ ] Outside `Owns` → major: none
- [ ] Inside another running story's `Owns` → critical: none. `git worktree list` shows only main and this worktree.
- [ ] No `Owns` line on this story: not the case. The `Owns` line is `tests/`.

## Evidence reused
- [x] `po-gate verif-current s214-suite-holds-with-a-published-po` → exit 0, record reused. It holds one `bash tests/run.sh` run, exit 0. Type check: the project has none (`Typecheck: —`).
- [x] `po-gate qa-current`: not required, because `QA stage: —` sends no story to QA.

## Plan
- [x] Each task present, and nothing outside the plan.
  - Task 1: one comment line plus `POLYPE_PO_FROM_SOURCES=1` on the `export` at `tests/state-as-json.test.sh:138-139`. No other line of the function changed.
  - Task 3: the record's "Not proven here" holds the counts of runs (a) and (b), 710 passed and 0 failed in each.
  - Task 4: the record's `## Runs` shows the full suite with exit 0.
  - Task 2 is left unticked (see Findings). I ran it here.
- [x] Each run interdict checked:
  - (1) Diff limited to `tests/state-as-json.test.sh` and the oracle. `bin/`, `po/`, `method/`, `.github/`, `tests/run.sh` and `tests/lib.sh` are untouched.
  - (2) Only `test_po_is_a_state_file_of_the_payload` changes. The `grep -qF 'no po sources'` and `cksum` checks stay.
  - (3) Oracle intact (`oracle-intact` exit 0). No `tests/suite-holds-with-a-published-po.test.sh` exists.
  - (4) Throwaway clone: nothing in the worktree shows a checkout or stash. I cannot observe the clone itself.
  - (5) `docs/parite-killer-saas.md` untouched.

## References
- [x] Every reference confirmed:
  - `POLYPE_PO_FROM_SOURCES` → `bin/polype:893-896` sends `lay_po` straight to `build_po`.
  - `build_po` prints `no po sources` when `po/Cargo.toml` is absent (`bin/polype:865-866`).
  - The silent branch is `bin/polype:907-909`.
  - `po_fetch` reads the `POLYPE_PO_FETCH` double (`bin/polype:847-853`), and `tests/run.sh:14` exports `false`.
  - `copy_of_polype` and `publish_this_platform` are at `tests/po-prebuilt-and-verified.test.sh:6-40`.
  - `ROOT` comes from `tests/lib.sh:5`, so inside the oracle's copy `POLYPE` resolves to the summed copy.
- [x] No value that only looks right. The plan's root-cause reading (the source build is byte-identical to the published binary, which reaches the silent branch) matches the code.

## Rules
- [x] `AGENTS.md` conventions respected: bash tests, an oracle file kept apart, and one English comment that explains why.
- [x] No accepted ADR contradicted.

## Tests
- Oracle: `po-gate oracle-intact s214-suite-holds-with-a-published-po` → exit 0
- [x] Floor: `po-gate floor-guard s214-suite-holds-with-a-published-po main` → 0, nothing lowered. `po-gate oracle-intact` → 0.
- [x] Assertions pin the acceptance criteria, and none of the six empty test shapes appears.
  - The `cargo` double is a documented fixture copied from the s171 test, not a mock of the condition under test.
  - The oracle runs the real copied test against a `bin/polype` whose `PO_SUMS` holds the sum of the binary the double builds.
- [x] Within `Test budget`: 2 new tests out of 25.
- [x] Bite 1: dropped ` POLYPE_PO_FROM_SOURCES=1` from `tests/state-as-json.test.sh`, then ran the oracle file. 1 failing test (`payload_run_keeps_its_po`, with the CI message). Undone with `git checkout --`, and `git diff --exit-code` was clean.
- [x] Bite 2: `tests/run.sh` exported `POLYPE_PO_FETCH=` instead of `false`, then ran the oracle file. 1 failing test (`no_test_reaches_the_network_for_po`). Undone, and `git diff --exit-code` was clean.
- [x] Focused run after both undos: `bash tests/run.sh suite-holds-with-a-published-po.oracle.test.sh state-as-json.test.sh` gave 6 passed and 0 failed.
- [x] No test made useless. The prebuilt path run from the payload stays covered by `test_po_record_is_a_state_file_of_the_payload` (`tests/po-prebuilt-and-verified.test.sh:44`).

## Neighbours
- [x] Callers read. `run.sh` runs each test in its own `bash -c`, so the new export cannot leak into other tests. `POLYPE_PO_FROM_SOURCES` is referenced nowhere else in `tests/`.

## Lenses
Lenses run: none. Only test files changed, with no lockfile, manifest, migration, auth or server-side path.
- [x] No lens finding.

## Findings
- minor — docs/plans/s214-suite-holds-with-a-published-po.md:74 — Task 2 (the focused run) is left `[ ]` while tasks 1, 3 and 4 are ticked, so the plan's progress bar under-reports the work. I ran the focused run here and it is green.

## Not verified
- **Criterion `whole_suite_on_a_summed_tree`.** It is not re-run here. That would take a full clone of PR #520's tree (`origin/framing/po-0.13.0-sums`, `04a003b`) plus about 12 minutes of suite, twice. The review relies on the record's counts (710 passed and 0 failed for (a) and (b)). A person should rebase PR #520 after this story lands and watch its CI. Only the `ubuntu-latest` runner proves the case where the built binary equals the published one.
- **The real-cargo path of `test_po_is_a_state_file_of_the_payload`.** I ran it only in the focused run on this machine, whose toolchain does not produce the published binary. The CI condition is covered by the oracle's `cargo` double, not by a real build.
- **The network.** No test here was run with network access to the real release URL. The double's presence is proven lexically (oracle test 2) and behaviourally by the existing `test_suite_environment_refuses_downloads`.
- **The oracle's lexical scan.** It catches `unset`, `env -u` and `env -i` only on the same line as the variable or the installer name. A drop of the double written another way (a multi-line `env`, or a variable built indirectly) would slip past it. This is accepted by the plan as a scan, not a proof.

Max severity: minor
Ship allowed: yes
