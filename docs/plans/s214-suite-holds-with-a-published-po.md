---
track: flow
validated: yes
---
# Plan (short track) — s214-suite-holds-with-a-published-po

[Story](../stories.md)

Written by the planner. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s214-suite-holds-with-a-published-po.md`. Validated by the planner under `Plan validation: autonomous`; no human reviewed it.

## Verified facts
**Two assumptions of the story are false.**
1. *"In CI the installer downloaded the published po 0.13.0."* It did not. `tests/run.sh:14` exports `POLYPE_PO_FETCH=false`, and `bin/polype:847-853` (`po_fetch`) calls that double before any `curl`; `test_suite_environment_refuses_downloads` (`tests/po-prebuilt-and-verified.test.sh:74`) passed in the same CI run 45688818665. The real cause: the suite builds `po` with the same command, toolchain and checkout path as the release job (`tests/run.sh:23`, `bin/po-release:120-121`, both `ubuntu-latest` at `/home/runner/work/polype/polype`), so the `po` the first `install --global` builds from sources (`build_po`, after the download double fails) is byte-identical to the published one. The run from the payload then reaches `lay_po`'s only silent branch, `bin/polype:907-909` (`po` already there with the expected sum → `record_po … prebuilt`, no message), so `no po sources` (`bin/polype:866`) is never printed. Every other branch of `lay_po` (`bin/polype:890-935`) prints a line; the CI output (story's run) printed none.
   **Reproduced** outside the worktree, offline: `git archive origin/framing/po-0.13.0-sums` into `/tmp`, the `linux-x86_64` line of `PO_SUMS` replaced by the sha256 of the `po` this machine builds → `tests/run.sh state-as-json.test.sh`: 3 passed, 1 failed, the exact CI message. Unmodified, that tree passes locally (the local toolchain builds a different binary). The story's title stays true; only the "download" wording of its notes is wrong.
2. *"The installer's tests already have doubles (`PO_CURL`, `gh`)."* `PO_CURL`/`PO_GH` are `po`'s forge doubles (`tests/ship-reads-the-forge.oracle.test.sh:16`). The installer's download double is `POLYPE_PO_FETCH` (`bin/polype:847-849`), plus a `cargo` double on `PATH` (`tests/po-prebuilt-and-verified.test.sh:6-30`).

Code facts:
- `tests/state-as-json.test.sh:135-155` — `test_po_is_a_state_file_of_the_payload`: installs from `$POLYPE` (`:5`, the real `bin/polype`) with the real `cargo`, then runs `update`/`install --global` from the payload and greps `no po sources` (`:147`). `HOME` and `CLAUDE_CONFIG_DIR` are exported at `:138`; nothing pins the path `lay_po` takes.
- `bin/polype:893-896` — `POLYPE_PO_FROM_SOURCES=1` sends `lay_po` straight to `build_po`, before any sum is read; documented for users at `docs/installation.md:114`.
- The prebuilt path from the payload is already covered by `test_po_record_is_a_state_file_of_the_payload` (`tests/po-prebuilt-and-verified.test.sh:44`).
- Other tests assuming empty sums: `grep` of `tests/*.sh` for the installer's po messages (`no po sources`, `no prebuilt po`, `building po from sources`, `could not download`, `PO_SUMS`) outside the three release files s213 fixed finds only `tests/state-as-json.test.sh:147`. The decisive search was a whole-suite run on a throwaway clone of PR #520's tree (`04a003b`) with task 1 and the oracle committed and the `linux-x86_64` sum set to this machine's build, network present: **710 passed, 0 failed** — no ninth failure.
- Every assignment of `POLYPE_PO_FETCH` in `tests/` is `false` or `"$SCRATCH/fetch"` (`tests/first-release-holds.oracle.test.sh:123,197`, `tests/po-prebuilt-and-verified.test.sh:52,64`, `tests/po-prebuilt-and-verified.oracle.test.sh:79`); the one `env -i` (`tests/ci-on-every-pr.oracle.test.sh:43-44`) runs `po-ci` with a stub `Test`, never the installer. `po/` never runs the installer (`po/src/ship/land.rs:202,422` only name it in messages).

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, `docs/stories.md:3479-3494` | absent — only `tests/` changes |
| New screen | absent — `Surface: command` | absent — `Platform: cli` |
| Authorization or tenant scope | absent — story text | absent — no guard of `bin/` touched |
| API contract | absent — story text | absent — `bin/polype` untouched; `POLYPE_PO_FROM_SOURCES` already exists (`bin/polype:893`) |
| New dependency | absent — story text | absent — bash, `sed`, `grep` already used by the suite |
| Technical choice that deserves an ADR | absent — story fixes the scope ("Ne touche ni `bin/`, ni `po/`, ni `method/`") | absent — test fixture detail; ADR-0141 not used |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no `Corrige` line in the story | absent — the change is to a test fixture |

## Story
The whole suite must pass when `main` carries the sums of the current version and CI could download the prebuilt `po`, so each published version's sums land without surprise (PR #520). Criteria:
- `payload_run_keeps_its_po` — `test_po_is_a_state_file_of_the_payload` passes when the copied `bin/polype` carries the current version's sums and a download would succeed.
- `no_test_reaches_the_network_for_po` — no test downloads `po`: wherever the installer could, a double holds it, and a test proves it.
- `whole_suite_on_a_summed_tree` — the whole suite passes on PR #520's tree with this story applied, with network; the plan says how.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Pin the payload test to the source path | already in this repository: `POLYPE_PO_FROM_SOURCES=1`, `bin/polype:893-896` | — |
| Oracle fixture (summed copy, `cargo` and fetch doubles) | already in this repository: `copy_of_polype` and `publish_this_platform`, `tests/po-prebuilt-and-verified.test.sh:6-40`, copied (files are "copied, not sourced", `:4`) | — |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/suite-holds-with-a-published-po.oracle.test.sh` | `3202657813 3705` |

| Criterion | Test |
| --- | --- |
| `payload_run_keeps_its_po` | `test_payload_run_keeps_its_po` — copies Polype, a `cargo` double that always builds the same binary, `bin/po-release` publishes it for this platform and its sum goes into the copy's `PO_SUMS`; runs the copied `test_po_is_a_state_file_of_the_payload` with `POLYPE_PO_FETCH=false` (CI's case: the build equals the published binary), then with a fetch double that succeeds. Fails on today's file (seen), passes with task 1 (seen). |
| `no_test_reaches_the_network_for_po` | `test_no_test_reaches_the_network_for_po` — `tests/run.sh` exports `POLYPE_PO_FETCH=false`; every `POLYPE_PO_FETCH=` in `tests/*.sh` is `false` or `"$SCRATCH/…"`; no file unsets it or runs the installer under `env -i`. Passes today; fails when `run.sh` exports another value or a file unsets it (both seen). |
| `whole_suite_on_a_summed_tree` | no oracle test: a suite cannot run itself on another tree. Checked by task 3, its counts written in the verification record. |

## The pivot
Everything hinges on reading the CI failure as "the build equals the published binary", not "a download happened". If that reading were wrong, a double around the download would be the fix and `POLYPE_PO_FROM_SOURCES` would hide the bug. It is not wrong: the download double was proven in place in that very run (`suite_environment_refuses_downloads` ok), the failure reproduces offline once the sum equals the local build, and only `bin/polype:907-909` is silent. Pinning the test to `POLYPE_PO_FROM_SOURCES=1` keeps what it checks — a run from the payload, which has no `po/` sources, leaves `po` as it was and says so — while the prebuilt path from the payload stays covered at `tests/po-prebuilt-and-verified.test.sh:44`.

## Tasks

1. [x] `tests/state-as-json.test.sh:138`: add `POLYPE_PO_FROM_SOURCES=1` to the `export` of `test_po_is_a_state_file_of_the_payload`, with one comment line saying why (a source build can equal the published `po`, which `lay_po` then keeps silently). No other line of the function changes. Fails if wrong: oracle `test_payload_run_keeps_its_po`; the test itself on `main` (`bash tests/run.sh state-as-json.test.sh`).
2. [ ] Focused run: `bash tests/run.sh state-as-json.test.sh suite-holds-with-a-published-po.oracle.test.sh po-prebuilt-and-verified.test.sh` in the worktree.
3. [x] Criterion 3, outside the worktree, with network, in a throwaway clone (a `git archive` is not enough: the lint and `po next` tests need a repository with `origin/main`, seen): `git clone -q <repo root> <tmp>/p`, `git -C <tmp>/p fetch -q <repo root> refs/remotes/origin/framing/po-0.13.0-sums`, `git -C <tmp>/p checkout -q -b framing FETCH_HEAD`, copy the story's two test files (`tests/state-as-json.test.sh`, the oracle) over it and commit them there, then (a) `bash tests/run.sh` as is, and (b) again after replacing the `po-0.13.0-<this platform>` line of the tmp `bin/polype` with the sha256 of `po/target/release/po` built in that tmp tree, committed — (b) is CI's real condition, which (a) does not meet on a machine whose toolchain differs from the runner's. Both must end `0 failed` (the known flake #504, `real_run_drives_the_journey_repository`, rerun alone if it fails). Write both counts in the verification record.
4. [x] Full suite once in the worktree through `po-run --story s214-suite-holds-with-a-published-po --label suite -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- `git diff origin/main... -- bin/ po/ method/ .github/ tests/run.sh tests/lib.sh` is empty.
- In `tests/state-as-json.test.sh`, only `test_po_is_a_state_file_of_the_payload` changes, and only by `POLYPE_PO_FROM_SOURCES=1` plus one comment line; its `grep -qF 'no po sources'` (`:147`) and the `cksum` check (`:148`) stay.
- `tests/suite-holds-with-a-published-po.oracle.test.sh` keeps cksum `3202657813 3705`; no `tests/suite-holds-with-a-published-po.test.sh` is created (no task test needed).
- Task 3 works in a throwaway clone under a temp directory only: no `git worktree add`, `checkout`, `switch` or `stash` in the worktree or the main repository, and nothing pushed to `origin/framing/po-0.13.0-sums`.
- `docs/parite-killer-saas.md` untouched.

## Files touched
`tests/state-as-json.test.sh`, `tests/suite-holds-with-a-published-po.oracle.test.sh` (planner's oracle, unchanged), `docs/plans/s214-suite-holds-with-a-published-po.md`, `docs/verif/s214-suite-holds-with-a-published-po.md`.

## Test strategy
Two oracle tests, read by the bash suite, within `Test budget` (25); the edited `test_po_is_a_state_file_of_the_payload` is the task test. Test 1 replays CI's condition deterministically and offline with a `cargo` double (about 5 s, no real build), in both fetch cases. Test 2 is a scan of `tests/` that bites on a dropped or replaced download double; the behaviour (no `curl`/`wget` reached) stays proven by `test_suite_environment_refuses_downloads`. Criterion 3 is a recorded run, not a test. Full suite once, at the end, through `po-run`.

## Not proven here
The planner ran task 3 (b) once, as above: 710 passed, 0 failed; the implementer redoes (a) and (b) on its own code. Only CI on PR #520, rebased after this story, proves the runner's case itself.

## Done when
Task 3's two runs and the full suite are green, the run interdicts hold, and the story lands as one commit `s214-suite-holds-with-a-published-po: La suite tient quand un po précompilé est publié` through a pull request, after which PR #520 can go green.
