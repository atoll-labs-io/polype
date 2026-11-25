---
track: flow
validated: yes
---
# Plan (short track) — s213-release-tests-survive-landed-sums

[Story](../stories.md)

Written by the planner. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s213-release-tests-survive-landed-sums.md`. Validated by the planner under `Plan validation: autonomous`; no human reviewed it.

## Verified facts
No assumption of the story proved false. The seven failures it names were reproduced outside the worktree on a `git archive` of `af2c324` (head of `origin/framing/po-0.13.0-sums`, PR #520): 13 passed, 7 failed, exactly those seven; `tests/po-prebuilt-and-verified.test.sh` (not owned) passes there.

- `bin/polype:28` sets `POLYPE_VERSION="0.13.0"`; `bin/polype:34` opens `PO_SUMS='`, empty on `main` (closing `'` on the next line). PR #520 changes only `bin/polype`, adding three lines `<sha256>  po-0.13.0-<platform>` inside that block.
- `bin/po-release:29-57` (`--tag`): refuses a tag other than `v<version>` (:30), a shallow checkout (:34), a HEAD outside `<target-ref>` (:36), an unreadable `bin/polype` at the ref (:38), a missing block (:40), and every commit of the ref's history whose block held `  po-<version>-` (:44-53, message `held the sums of <version>`). `.github/workflows/release.yml:20` and `:37` run it before any `gh` call.
- Cause of six failures: each `copy_of_polype` copies the real `bin/` — `tests/first-release-holds.oracle.test.sh:20`, `tests/first-release-holds.test.sh:13` — then commits the copy's `bin/polype` as `origin/main` (`publish` :91-93, `tagged_on_main` :103; `tagged_commit` :57, `main_commit` :64-80 of the test file). Once the real block holds the 0.13.0 sums, the `--tag` guard (:44-53) refuses, as it should.
- Both fixtures state the pre-sum state as intended: `tests/first-release-holds.oracle.test.sh:87` ("holding no sum yet"), `tests/first-release-holds.test.sh:53` ("(empty PO_SUMS)").
- Cause of the seventh: `tests/po-prebuilt-and-verified.oracle.test.sh:22` copies the real `bin/`; `test_installer_falls_back_to_sources` (:175) installs before `expect_release_sum` and expects a fallback to sources, but `po_expected_sum` (`bin/polype:839-845`) finds the landed real sum for this platform, so the fetched double's sum is refused. Other tests there pass only because `expect_release_sum` (:59-61) inserts its sum right after `PO_SUMS='`, ahead of the landed one, and `po_expected_sum` returns the first match.
- Fix verified outside the worktree, on both `af2c324` and `7a28ef6` (`main`): two lines added right after the `cp -R "$ROOT/bin" …` of each of the three `copy_of_polype` — a `sed -i` that deletes every line strictly inside the copy's block, and a check that `sums_block` is empty — give 17 passed, 0 failed, `bin/po-release` untouched. The oracle below passes on both fixed trees and fails `release_tests_hold_with_landed_sums` on unfixed `main`; with the refusal at `bin/po-release:52` turned into an `echo`, `release_still_refuses_a_summed_version` fails.
- Conventions: fixtures are "copied, not sourced" (`tests/first-release-holds.oracle.test.sh:6`, `tests/first-release-holds.test.sh:5`), so each file gets its own two lines; `sed -i` is already used in these files (`tests/first-release-holds.oracle.test.sh:163`, `:196`); `ROOT` comes from `tests/lib.sh:5`.
- Two of the three files are earlier stories' oracles: `tests/first-release-holds.oracle.test.sh` is s189's (header :2), `tests/po-prebuilt-and-verified.oracle.test.sh` is s171's (header :2). Changing them is deliberate and owned by this story (`docs/stories.md:3471`); `po-gate oracle-intact` reads only this plan's oracle (`method/hooks/po-gate.sh:603-640`).

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, `docs/stories.md:3465-3477` | absent — only `tests/` files change |
| New screen | absent — `Surface: command` | absent — no UI in this repository (`Platform: cli`) |
| Authorization or tenant scope | absent — story text | absent — the release guard is kept, not changed (`bin/po-release:29-57`) |
| API contract | absent — story text | absent — `bin/polype`, `bin/po-release`, `po/` untouched |
| New dependency | absent — story text | absent — `sed`, `awk`, `bash` already used by these files |
| Technical choice that deserves an ADR | absent — story fixes the approach ("Corrige le test, pas `bin/po-release`") | absent — test fixture detail; no ADR-0141 drafted |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no `- **Corrige** :` line in the story (the form at `docs/stories.md:319`) | absent — the change is to test fixtures |

## Story
The release tests must hold when `main` already carries, in `PO_SUMS`, the sums of the current version, so every published version's sums can land (PR #520). Criteria:
- `release_tests_hold_with_landed_sums` — the tests of the three owned files pass when the copied `bin/polype` already holds the sums of the version they test.
- `release_still_refuses_a_summed_version` — the release still refuses to rebuild a version whose sums landed on `main`; no guard of `bin/po-release` removed or weakened.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Emptying the copy's block | already in this repository: the range form of `sed -i` used at `tests/first-release-holds.oracle.test.sh:163`, block shape `bin/po-release:93-96` | — |
| Check the block is empty | already in this repository: the block reader `awk` of `tests/first-release-holds.oracle.test.sh:258` | — |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/release-tests-survive-landed-sums.oracle.test.sh` | `3746022349 4760` |

| Criterion | Test |
| --- | --- |
| `release_tests_hold_with_landed_sums` | `test_release_tests_hold_with_landed_sums` — copies Polype and the three files into a scratch tree, writes three sums of `POLYPE_VERSION` into its `PO_SUMS`, runs every `test_` function of the three files there, and requires the seven tests of PR #520 among them |
| `release_still_refuses_a_summed_version` | `test_release_still_refuses_a_summed_version` — the real `bin/po-release --tag v<version> origin/main` passes on an unsummed `origin/main`, then refuses with `held the sums of <version>` once `origin/main` holds them |

## The pivot
Everything hinges on this: the three fixtures mean "a version not yet summed", so emptying their copy's block restores what they were written for, instead of weakening them. It would be wrong if a test of these files needed the real block; none reads it — `test_sums_are_written_by_a_command` and `expect_release_sum` write their own sums — and the oracle runs every test of the three files with the sums present. The added check fails the fixture if the block shape ever changes so that `sed` empties nothing.

## Tasks

1. [x] `tests/first-release-holds.oracle.test.sh`, `copy_of_polype` (:15-41): right after the `cp -R "$ROOT/bin" …` line (:20), add `sed -i "/^PO_SUMS='\$/,/^'\$/{/^PO_SUMS='\$/!{/^'\$/!d}}" "$C/bin/polype"`, then a line failing the fixture when the `awk` block reader (as at :258) prints anything; one comment line saying why (the copy stands for a version not yet summed, whatever `main` holds). Fails if wrong: `release_reruns_cleanly`, `tag_must_match_the_version` on a tree with landed sums; oracle `test_release_tests_hold_with_landed_sums`.
2. [x] `tests/first-release-holds.test.sh`, `copy_of_polype` (:8-30): the same two lines and comment right after `cp -R "$ROOT/bin" "$ROOT/.github" "$C/"` (:13). Fails if wrong: `release_only_from_a_commit_of_the_target_branch`, `rerun_refused_after_later_sums_replace_them`, `rerun_refused_once_sums_landed`, `tag_guard_fails_closed`; oracle test 1.
3. [x] `tests/po-prebuilt-and-verified.oracle.test.sh` (s171's oracle), `copy_of_polype` (:17-45): the same right after `cp -R "$ROOT/bin" "$ROOT/method" "$C/"` (:22). Fails if wrong: `installer_falls_back_to_sources`; oracle test 1.
4. [x] Record in `## Oracle changes` of `docs/verif/s213-release-tests-survive-landed-sums.md` the deliberate change of the two earlier oracles (s189's and s171's files, tasks 1 and 3) and why; leave this story's oracle unchanged.
5. [x] Verify outside the worktree on PR #520's tree: `git archive af2c324` into a fresh temporary directory, apply the story's diff there, run `bash tests/run.sh first-release-holds.oracle.test.sh first-release-holds.test.sh po-prebuilt-and-verified.oracle.test.sh po-prebuilt-and-verified.test.sh release-tests-survive-landed-sums.oracle.test.sh` with `CARGO_TARGET_DIR` in that directory; write the counts in the record's "Not proven here" or notes. Then the full suite through `po-run` in the worktree.

## Scene viewpoints
—

## Run interdicts
- `git diff origin/main... -- bin/ po/ method/ .github/ tests/lib.sh tests/run.sh tests/po-prebuilt-and-verified.test.sh` is empty: no guard of `bin/po-release` moves, `bin/polype` keeps its block as `main` has it.
- In the three owned files, only the `copy_of_polype` functions change; no `test_` function is removed, renamed or edited.
- `tests/release-tests-survive-landed-sums.oracle.test.sh` keeps cksum `3746022349 4760`; no `tests/release-tests-survive-landed-sums.test.sh` is created.
- Nothing is pushed to, or checked out from, `origin/framing/po-0.13.0-sums`; no `git worktree add`, `checkout`, `switch` or `stash` for task 5 — `git archive` into a temporary directory only.
- `docs/parite-killer-saas.md` untouched (no parity line involved).

## Files touched
`tests/first-release-holds.oracle.test.sh`, `tests/first-release-holds.test.sh`, `tests/po-prebuilt-and-verified.oracle.test.sh`, `tests/release-tests-survive-landed-sums.oracle.test.sh` (planner's oracle, unchanged), `docs/plans/s213-release-tests-survive-landed-sums.md`, `docs/verif/s213-release-tests-survive-landed-sums.md`.

## Test strategy
Two oracle tests, both read by scripts (the bash suite), within `Test budget` (25); no task test file, since the 17 existing tests of the three files are the task tests. Test 1 is end to end at the fixture layer: it fails on today's files once sums are present (seen on unfixed `main`). Test 2 pins the `--tag` history guard through the real `bin/po-release`, so a weakened guard fails even if the edited fixtures drift (seen with :52 neutralised). Focused runs after tasks 1-3: `bash tests/run.sh <file>` plus the oracle; the full suite once, at the end, through `po-run`. Both nested runs take about 10 s.

## Done when
The five files named in task 5 pass on `main`'s tree and on PR #520's tree, the full suite is green, the run interdicts hold, and the story lands as one commit `s213-release-tests-survive-landed-sums: Les tests de release tiennent quand les sommes de la version sont sur main` through a pull request, after which PR #520 can go green.
