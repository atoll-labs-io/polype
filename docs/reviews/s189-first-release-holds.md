# Review — s189-first-release-holds

[Story](../stories.md) · [Plan](../plans/s189-first-release-holds.md) · [Verification](../verif/s189-first-release-holds.md)

Method version: 0.6.1
Recorded: 2026-11-16T13:50:24+01:00

Diff reviewed: `git diff main...story/s189-first-release-holds`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 5cbb3e7c4f496eadb5c4ad56fce442ad15de70d3

## Ownership
I listed the diff with `git diff --name-only main...story/s189-first-release-holds` and held each path against the story's `Owns` using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. The `Owns` line covers `.github/workflows/release.yml`, `bin/po-release`, `bin/polype`, `docs/ci.md`, `tests/po-prebuilt-and-verified.oracle.test.sh`, `tests/first-release-holds.oracle.test.sh` and `tests/first-release-holds.test.sh`. The research, plan and verification files under `docs/` are the story's own evidence, so they are in scope.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. s190 also owns `bin/polype`, but it has no worktree: `git worktree list` shows only main, `framing-m22` and this story.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s189-first-release-holds` exited 0, so I reused the record and did not rerun the full suite. Its single `Unit suite` row (`bash tests/run.sh`) exited 0. The project has no type check (`Typecheck: —`). I read the record's "Not proven here" section.
- [x] `po-gate qa-current` was not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] All six tasks are present, and nothing outside the plan was changed apart from the four departures the implementer named. My verdict on each:
  - **Comment line in `release.yml`.** Harmless. The comment explains a non-obvious "why", and no test reads comments: both the s171 oracle and `publish` grep only `run:` lines.
  - **Longer header comment in `bin/po-release`.** Fine. It documents the two new modes; no finding.
  - **`bash -n` before the `mv`.** Justified. In a throwaway copy I gave `bin/polype` a `PO_SUMS='` block with no closing quote. The awk then drops the rest of the file, `bash -n` catches it, the command exits 1, `bin/polype` keeps the same cksum and the temp file is removed. Without this check the installer would have been truncated.
  - **An out-dir starting with `-` is refused.** A harmless tightening. No caller passes such a directory (checked with grep: `release.yml` and the two s171 test files). The run interdict on the out-dir mode still holds: output names, the `.sha256` line and the refusal on a version mismatch are all unchanged.
- [x] I checked each run interdict:
  - `po/`, `bin/po-version-check`, `bin/po-ci`, `ci.yml`, `tests/ci-on-every-pr*`, `tests/po-prebuilt-and-verified.test.sh` and `docs/installation.md` have an empty diff.
  - In `bin/polype`, only the comment at :30-33 changed. `POLYPE_VERSION` is still 0.6.1 and `PO_SUMS` is still empty.
  - `release.yml` still has `contents: write` alone and only the pinned checkout SHA. It has no cargo, rustc or rustup, and no `${{ }}` inside a `run:`.
  - The oracle's sum is intact.
  - Nothing was published.

## References
- [x] Every gh flag the workflow and `docs/ci.md` use exists in gh: `release view`, `create --verify-tag`, `upload --clobber`, `download --pattern --dir`. `--sums` writes the line shape that `po_expected_sum` reads; the sums it wrote in my probe were read back by the installer in `test_sums_are_written_by_a_command`.
- [x] No value merely looks right. I probed `bin/po-release` in a throwaway copy:
  - `--tag` with no value, `-x` and two arguments each exit 2.
  - `--tag 0.6.1` exits 1 and `--tag v0.6.1` exits 0.
  - A `.sha256` file with no trailing newline is refused.
  - A good set of sums is written sorted, the file mode is kept, and a second run writes nothing.

## Rules
- [x] The `AGENTS.md` conventions are respected: comments in English, the docs in French, one-line `run:` steps.
- [x] No accepted ADR is contradicted. ADR-0121 (the sum travels in the reviewed file) and ADR-0105 (`bin/po-release` reads no forge variable) still hold.

## Tests
- Oracle: `po-gate oracle-intact s189-first-release-holds` → exit 0
- [x] Floor: `po-gate floor-guard s189-first-release-holds main` exited 0, so nothing was lowered.
- [x] Oracle: `po-gate oracle-intact s189-first-release-holds` exited 0. The plan's task 5 announced a change to s171's oracle, recorded under `## Oracle changes`. I graded it below as minor.
- [x] The assertions pin the five acceptance criteria, and the tests show none of the six empty shapes. The gh double reproduces gh's two refusals, which the plan's test strategy justifies.
- [x] The story adds 7 tests, within `Test budget: 25`.
- [x] Bite: I ran each mutation on `bin/polype` or `release.yml`, ran only the story's test files, then undid it with `git checkout -- <file>`. `git diff --exit-code <file>` was clean after each one.
  - Removed `&& [ "$po_refused" = no ]` from `bin/polype:949`. `test_refused_po_cleans_nothing` failed (1 failure): "an update whose po was refused removed a machine file".
  - Replaced `[ "$version" = "$POLYPE_VERSION" ] || return 0` at `bin/polype:953` with `true`. `test_cleanup_waits_for_the_new_po` failed (1 failure): "an update that laid no po 0.6.1 removed a file the older po still reads".
  - Removed the `bin/po-release --tag` step from `release.yml`. Two tests failed: `test_tag_must_match_the_version` and `test_wrong_tag_creates_no_release`.
  - Removed `--clobber` from `release.yml`. `test_release_reruns_cleanly` failed (1 failure).
- [x] The story made no test useless.

## Neighbours
- [x] I read every caller of `bin/po-release`: `release.yml`, `tests/po-prebuilt-and-verified.oracle.test.sh:51` and `tests/po-prebuilt-and-verified.test.sh:35`. All of them use the unchanged out-dir mode.

How the workflow behaves on a real tag push (read, not run):
- **Tag that does not match the version.** The `create` job checks out the tag's commit, and `bin/po-release --tag` exits 1 before anything is created. The `po` matrix is skipped because of `needs: create`, so nothing is uploaded. A tag where `bin/polype` and `po/Cargo.toml` disagree fails the same way, on the existing equality check.
- **Re-running only the failed jobs.** `view ||` keeps the existing release and `--clobber` replaces the assets.
- **Re-running all jobs.** Every binary and its `.sha256` are rebuilt and replaced. That is safe until `PO_SUMS` lands; after that, see the major finding.
- **Odd tag names.** `GITHUB_REF_NAME` reaches the shell only through a quoted environment variable, never through `${{ }}`, so a strange tag name cannot be injected into a command.

## Lenses
Lenses run: none. No changed path names auth, routes, handlers, uploads or webhooks; no dependency or migration file changed; nothing is server-side code.
- [x] No lens findings.

## Findings
- major — .github/workflows/release.yml:33 — `--clobber` takes away the only thing that stopped a published binary from being replaced by accident.
  - Before this story, a re-run failed at upload because the asset already existed. Now a "Re-run all jobs" after the version's sums have landed in `PO_SUMS` rebuilds po. The build is not reproducible, so the new binary gets a different sum, and `--clobber` silently replaces the published one.
  - From then on every `polype install`/`update` of that version gets `po refused` and exits 1 (`bin/polype:1104`, `:1171`). It does not fall back to building from sources.
  - Integrity still holds: the refusal is fail-safe. The availability risk is new, though, and only the warning sentence in `docs/ci.md` guards against it.
  - The plan's pivot section accepted this trade-off, and `release_reruns_cleanly` requires a re-run that succeeds. A later cycle could add a guard in the workflow, for example refusing to clobber once the target-branch `PO_SUMS` holds a sum for this version.
- minor — tests/po-prebuilt-and-verified.oracle.test.sh:132 — The new clause for `bin/po-release --tag` has no end anchor, so `bin/po-release --tag x; <anything>` would pass s171's "only po-release and gh release" check.
  - The existing `gh release *` clause was already unanchored the same way, and the cargo/rustc grep at :127 still applies.
  - Anchoring the clause, e.g. `--tag "\$GITHUB_REF_NAME"$`, would restore the original meaning of the clause.
- minor — docs/ci.md:26-27 — Step 3 says re-running a release, all jobs or only the failed ones, "est sans risque". After the sums have landed, the next paragraph forbids exactly that. Wording only: step 3 could qualify it with "tant que les sommes n'ont pas atterri".

## Not verified
- **The real workflow on GitHub Actions** was not run. The tests replay the `run:` lines in file order against a gh double. Not covered: the job ordering by `needs: create`, the checkout of the tag ref, the real `gh` behaviour of `view`/`create --verify-tag`/`upload --clobber`, and the macOS and arm64 runners. The person should watch the first tag push (the step proposed after ship) and check that only `v<version>` publishes three binaries.
- **A deliberate wrong-tag push on the real forge** was not done, because nothing could be published. To cover it, push a throwaway non-matching `v*` tag on a fork and confirm the `create` job fails with no release.
- **`bin/po-release --sums` on real `.sha256` files downloaded by `gh release download`** was not run. Only files written by `po-release`, plus hand-made ones, were used. The first real release covers it.
- **`--sums` on macOS** (`mktemp` template, `cp -p`, awk `ENVIRON`) was not run. Only this Linux host was used.
- **The full unit suite** was not rerun. I relied on the current verification record (`po-gate verif-current` exited 0).

Max severity: major
Ship allowed: yes

Method version: 0.6.1
Recorded: 2026-11-16T14:06:46+01:00

Diff reviewed: `git diff main...story/s189-first-release-holds`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: ba308422d4efe9e25d2b72c08318609d3dd4aee9

## Ownership
I listed the diff with `git diff --name-only main...story/s189-first-release-holds` and checked each path against the story's `Owns` line using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`: `.github/workflows/release.yml`, `bin/po-release`, `bin/polype`, `docs/ci.md`, `tests/first-release-holds.oracle.test.sh`, `tests/first-release-holds.test.sh` and `tests/po-prebuilt-and-verified.oracle.test.sh`. The research, plan, verification and review files are the story's own evidence.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows main, `.claude/worktrees/framing-m22` (branch `fix/qa-deadline-wording`, not a story) and this story only.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s189-first-release-holds` exited 0, so I reused the record. Its last `Unit suite` row (`bash tests/run.sh`) exited 0. The project has no type check (`Typecheck: —`). I read "Not proven here".
- [x] `po-gate qa-current` was not required: `QA stage: —`, so the story does not go to QA.
- I also ran the three story test files to get a baseline before the mutations: 13 passed, 0 failed.

## Plan
- [x] The six plan tasks are still present. The fix commit 2052f0f answers loop 0's three findings: the major (rerun guard), the minor at `po-prebuilt-and-verified.oracle.test.sh:132` (the clause is now anchored) and the minor at `docs/ci.md:26-27` (the wording is now qualified). My verdict on each of the four named departures:
  1. **Oracle fixture in `publish()`.** It does not weaken any criterion. The three lines only give the copy an `origin/main` whose `PO_SUMS` is empty, as the real `fetch-depth: 0` checkout does. No assertion changed.
     - In `tag_must_match_the_version`, the wrong-tag refusal still comes from the tag comparison, which runs before the ref is read. The positive leg still requires a full publish.
     - `release_reruns_cleanly` still requires two passing runs and the same set of assets.
     - Without the fixture, every positive leg would fail, so it does not make a test pass for free. The change is logged in `## Oracle changes`.
  2. **`--tag` now requires `<target-ref>`.** Accepted. The only callers are `release.yml` and s171's oracle regex, and both were updated. Probes: with no ref, or a ref starting with `-`, the command exits 2.
  3. **The guard runs in both jobs.** Correct and needed. "Re-run failed jobs" skips `create`, so the `po` job needs its own guard before it builds.
  4. **Header comment of `bin/po-release`.** Accurate. No finding.
- [x] Run interdicts: in `bin/polype`, only the comment changed (`POLYPE_VERSION` is 0.6.1 and `PO_SUMS` is empty). `po/`, `ci.yml` and `docs/installation.md` are untouched. Nothing was published and no real forge was called.

## References
- [x] `git show <ref>:bin/polype`, the awk extraction of the block and the `grep -qF "  po-<v>-"` match all behave as intended.
  - `po-0.6.1-` does not match `po-0.6.10-`.
  - `actions/checkout` with `fetch-depth: 0` fetches `refs/heads/*` into `refs/remotes/origin/*`, so `origin/main` exists on a tag push. This was read, not run.
- [x] Probes in the worktree (read-only):
  - `--tag v0.6.1 refs/remotes/origin/does-not-exist` exits 1 ("cannot read bin/polype"), so it fails closed.
  - `--tag v0.6.1 main` exits 0.
  - `--tag v0.6.2 main` exits 1.

## Rules
- [x] The `AGENTS.md` conventions are respected: comments in English, `docs/ci.md` in French, one-line `run:` steps, no `${{ }}` inside a `run:`.
- [x] ADR-0105 holds: `bin/po-release` reads no forge variable, because the ref is passed as an argument. ADR-0121 holds: the sums stay in the reviewed file.

## Tests
- Oracle: `po-gate oracle-intact s189-first-release-holds` → exit 0
  tests/first-release-holds.oracle.test.sh: changed, logged in ## Oracle changes — fix run: `publish` first gives the copy an `origin/main` holding its own `bin/polype` (empty `PO_SUMS`), as the release job's `fetch-depth: 0` checkout does; no assertion changes — review major at `release.yml:33`: `bin/po-release --tag` now reads `PO_SUMS` at `origin/main` and refuses when it cannot, so a replay without that ref fails every release. The fixture gives the replay what the real checkout gives; `release_reruns_cleanly` and `tag_must_match_the_version` still assert what they did. The sum in the plan no longer matches this file
  po-gate: 1 logged oracle change(s) of s189-first-release-holds to judge
- [x] Oracle: `po-gate oracle-intact` exited 0, with one logged change to judge. I judged it above: it does not weaken any criterion.
- [x] Floor: `po-gate floor-guard s189-first-release-holds main` exited 0.
- [x] The assertions pin the five criteria. None of the six empty test shapes appears. The gh double is justified in the plan.
- [x] 8 tests, within `Test budget: 25`.
- [x] Bite: each mutation was undone with `git checkout -- bin/po-release`, and `git diff --exit-code` was clean after each.
  - **Mutation 1.** I prefixed the "already summed" check with `false &&`, so it never refuses. 1 test failed: `test_rerun_refused_once_sums_landed` ("a rerun of v0.6.1 passed although main holds its sums").
  - **Mutation 2.** I replaced `exit 1` in the unreadable-ref branch with `released=""`, so it fails open. 0 tests failed across all three story files, and a direct probe on a missing ref then exited 0. The fail-closed behaviour holds today, but only my probe shows it; no test checks it (see Findings).
- [x] No test made useless.

## Neighbours
- [x] I read the callers of `bin/po-release`: `release.yml`, `tests/po-prebuilt-and-verified.oracle.test.sh` and `tests/po-prebuilt-and-verified.test.sh`. The out-dir mode is unchanged.

What a pushed tag would make the workflow do (read; I checked the guard's logic with probes):
- **First run, no sums anywhere.** `create` checks out the tag with full history. `--tag` passes, because `origin/main` has an empty `PO_SUMS`. The release is created. Each `po` runner runs the guard again, builds and uploads with `--clobber`. A wrong tag, or `bin/polype` and `po/Cargo.toml` disagreeing, stops `create` before anything is created, and `needs: create` skips the matrix.
- **Reruns.** While the sums have not landed, they are kept (`view ||` and `--clobber`). Once `main`'s `PO_SUMS` holds this version, they are refused before any forge call.
- **Older tag rerun after the next version's sums replace the block.** It passes the guard; see Findings.

## Lenses
Lenses run: security — `.github/workflows/release.yml`
- [x] Each lens finding is graded and listed under Findings.

## Findings
Security findings: 1 — decision d-0035
- major — bin/po-release:38 — The rerun guard only reads the `PO_SUMS` of the current `main`, and `--sums` replaces every line of that block (`bin/po-release`, comment "Every line of the block is replaced").
  - So once version N+1's sums land, the lines for version N are gone from `main`. A rerun of `vN` (re-running an old workflow run, or re-pushing the tag) then passes the guard, rebuilds and `--clobber`s the published N binaries.
  - Every installer still at N carries N's sums in its own `bin/polype`, so it then gets `po refused`.
  - Reproduced in a throwaway clone. With `main` holding a 0.6.1 sum, `--tag v0.6.1 origin/main` exited 1. After a commit replacing the block with 0.7.0 sums, it exited 0.
  - `docs/ci.md` ("Une fois les sommes atterries, la release refuse de se relancer") states this guarantee without that limit.
  - A fix could search the history of `bin/polype` on the target ref (e.g. `git log -G "  po-<v>-" <ref> -- bin/polype`) rather than its tip.
- major — tests/first-release-holds.test.sh:107 — The fail-closed branch of the guard (`bin/po-release:32-35`, "cannot read bin/polype at <ref>") is covered by no test. Turning it into a fail-open branch left all 13 tests of the three story files green. A regression would silently bring back the loop-0 major. A test calling `--tag v<version>` with a missing ref and expecting a refusal would hold it.
- minor — bin/po-release:37 — A target ref whose `bin/polype` exists but has no `PO_SUMS='` line (for example the block renamed) yields an empty extraction, and the guard passes. This is fail-open on a malformed source, unlike the missing-ref case. Refusing when the block is absent would make both cases consistent.

## Not verified
- **The real workflow on GitHub Actions** was not run, since nothing could be published or sent to a forge. Not covered:
  - that `actions/checkout@v4.4.0` with `fetch-depth: 0` on a tag push really creates `refs/remotes/origin/main`;
  - job ordering by `needs: create`;
  - the real `gh` behaviour of `view`, `create --verify-tag` and `upload --clobber`;
  - the macOS and arm64 runners.

  The person should watch the first `v0.6.1` push and confirm three binaries and their `.sha256` files appear. If `origin/main` is missing, the release refuses with "cannot read bin/polype".
- **A rerun after the sums landed, on the real forge,** was not done. Only the replay against the gh double covers it.
- **`bin/po-release --sums` on `.sha256` files downloaded by `gh release download`**, and on macOS, was not run. The first real release covers it.
- **One point of the security finding** was read, not run. It belongs to that finding and is not described here.
- **The full unit suite** was not rerun. I relied on the current verification record (`po-gate verif-current` exited 0), plus my own run of the three story test files.

Max severity: major
Ship allowed: yes

Method version: 0.6.1
Recorded: 2026-11-18T09:37:34+01:00

Diff reviewed: `git diff main...story/s189-first-release-holds`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 2
Reviewed tree: b9e49d41a65fbef548704cc074c3ab5e8f82e019

## Ownership
I listed the diff with `git diff --name-only main...story/s189-first-release-holds` and checked each path against the story's `Owns` line.
- [x] Every path is inside `Owns`: `.github/workflows/release.yml`, `bin/po-release`, `bin/polype`, `docs/ci.md`, `tests/first-release-holds.oracle.test.sh`, `tests/first-release-holds.test.sh` and `tests/po-prebuilt-and-verified.oracle.test.sh`. The research, plan, verification and review files are the story's own evidence.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows main, `.claude/worktrees/framing-m22` (branch `fix/qa-deadline-wording`, not a story) and this story.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s189-first-release-holds` exited 0. Its last `Unit suite` row (`bash tests/run.sh`, tree 310dcf6…) exited 0, so I did not rerun the full suite. The project has no type check (`Typecheck: —`). I read "Not proven here".
- [x] `po-gate qa-current` was not required: `QA stage: —`.
- My baseline run of the two story test files before any mutation: 11 passed, 0 failed.

## Plan
- [x] Fix commit f359e53 answers loop 1:
  - **Major at `bin/po-release:38`.** Resolved. The guard now reads every commit of the target ref's history that `git log -S "  po-<v>-"` reports, and refuses when any of them held this version's sums inside the block. Mutation E bites.
  - **Major at `tests/first-release-holds.test.sh:107`.** Resolved. The unreadable-ref branch is now held by `test_tag_guard_fails_closed`. Mutation C bites.
  - **Minor at `bin/po-release:37`.** Resolved. A missing `PO_SUMS='` line now refuses. Mutation D bites.
- [x] Fix run 2 added three tests and changed no oracle file (`git show --stat f359e53`). `docs/ci.md` now states what the guard enforces and when it refuses.
- [x] Run interdicts still hold:
  - In `bin/polype`, only the comment changed. `POLYPE_VERSION` is 0.6.1 and `PO_SUMS` is empty.
  - `po/`, `ci.yml` and `docs/installation.md` are untouched.
  - `release.yml` keeps `contents: write` alone and the pinned checkout. It has no `${{ }}` inside a `run:`.
  - Nothing was published and no forge was called.

## References
- [x] Every git verb the guard uses exists and behaves as the code expects: `rev-parse --is-shallow-repository`, `merge-base --is-ancestor`, `show <ref>:<path>`, `log --full-history -S … -- <path>`.
- [x] The block extraction stops at the closing `'`. It no longer uses a pipe, so `grep -q` cannot fail it under `pipefail`.

## Rules
- [x] Comments are in English, `docs/ci.md` is in French, and every `run:` fits on one line.
- [x] ADR-0105 holds: `bin/po-release` reads no forge variable, because the ref comes in as an argument. ADR-0121 holds: the sums stay in the reviewed file.

## Tests
- Oracle: `po-gate oracle-intact s189-first-release-holds` → exit 0
  tests/first-release-holds.oracle.test.sh: changed, logged in ## Oracle changes — fix run: `publish` first gives the copy an `origin/main` holding its own `bin/polype` (empty `PO_SUMS`), as the release job's `fetch-depth: 0` checkout does; no assertion changes — review major at `release.yml:33`: `bin/po-release --tag` now reads `PO_SUMS` at `origin/main` and refuses when it cannot, so a replay without that ref fails every release. The fixture gives the replay what the real checkout gives; `release_reruns_cleanly` and `tag_must_match_the_version` still assert what they did. The sum in the plan no longer matches this file
  po-gate: 1 logged oracle change(s) of s189-first-release-holds to judge
- Oracle: `po-gate oracle-intact s189-first-release-holds` → exit 0
- [x] Oracle: exit 0, with one logged change to judge. It is the `publish()` fixture change of fix run 1, which loop 1 already judged as not weakening any criterion. Fix run 2 did not touch the oracle.
- [x] Floor: `po-gate floor-guard s189-first-release-holds main` exited 0.
- [x] 11 story tests plus one changed assertion in s171's oracle, within `Test budget: 25`. None of the six empty test shapes appears. The gh double is justified in the plan.
- [x] Bite. Each mutation was made on `bin/po-release`, then I ran only the two story test files. After each one, `git checkout -- bin/po-release` restored the file and `git diff --exit-code bin/po-release` was clean.
  - **A.** Shallow-checkout refusal turned into `true`. 1 test failed: `tag_guard_fails_closed`.
  - **B.** One refusal of the guard disabled. 1 test failed. The details belong to the security finding.
  - **C.** The refusal when `bin/polype` cannot be read at the ref turned into `|| true`. 1 test failed: `tag_guard_fails_closed`.
    - That test catches it only through the message it expects. The block check right after it would still refuse, so behaviour stays closed either way.
  - **D.** Missing-`PO_SUMS`-block refusal turned into `true`. 1 test failed: `tag_guard_fails_closed`.
  - **E.** History search replaced by the tip of the ref only. 1 test failed: `rerun_refused_after_later_sums_replace_them`.
  - **F.** The refusal when the history cannot be read turned into `|| true`. 0 tests failed. See Findings.
- [x] With the code unchanged, `release_reruns_cleanly` passes: a rerun before any sums land still succeeds. So do `rerun_refused_once_sums_landed`, whose first two publishes run with only another version's sums on main, and the positive leg of `tag_guard_fails_closed`.

## Neighbours
- [x] I read the callers of `bin/po-release`: `release.yml`, `tests/po-prebuilt-and-verified.oracle.test.sh` (its new anchored `--tag … <ref>` clause matches `origin/main`) and `tests/po-prebuilt-and-verified.test.sh`. The out-dir mode is unchanged.

**Cost of the history search.**
- `git log -S` limited to `bin/polype` diffs only the commits that touch that file, so its cost grows with that number times the file's size.
- On this repository: 401 commits on main, 30 touching `bin/polype` (1299 lines). The search took 0.013 s.
- The real cost on a long history is the full clone that `fetch-depth: 0` now makes in all four jobs, not the search. That is the price of reading history, and there is no cheaper way to read it.

**Failure modes.**
- Every guard that cannot read what it compares refuses: shallow checkout, missing ref, missing file, missing block.
- Two places stay open:
  - the history-read refusal at `:44` is untested (mutation F);
  - the loop's `|| continue` at `:46` skips an unreadable commit. That is correct for a commit that deleted `bin/polype`, but fails open on a missing blob, for example in a partial clone.
- A commit that both adds the block line and removes the same string elsewhere in `bin/polype` would escape `-S`, because `-S` counts occurrences. That is contrived, so it is not a finding.

**Lock-out of a legitimate first release.** I found none by reading.
- On a tag push, `actions/checkout` with `fetch-depth: 0` gives a full, non-shallow history, a detached HEAD at the tagged commit, and `refs/remotes/origin/*`.
- On a tag set on a commit of main, every check passes, and main's empty `PO_SUMS` has no history of 0.6.1 sums (the probe above returned 0 commits).
- Refusals that are wanted:
  - a tag set before its commit landed on main;
  - a "re-run failed jobs" after the sums PR has landed.
- A sums PR that is later reverted locks that version for good. `docs/ci.md` documents this as intended.

## Lenses
Lenses run: security — `.github/workflows/release.yml`, `bin/po-release`
- [x] Each lens finding is graded and listed under Findings.

## Findings
Security findings: 1 — decision d-0036
- minor — bin/po-release:44 — The "cannot read the history" refusal is covered by no test. Turning it into `|| true` (mutation F) left all 11 story tests green. Nearby, `|| continue` at `:46` skips a commit whose `bin/polype` cannot be read instead of refusing. On a full checkout both are close to unreachable. Holding `:44` with a test, and refusing at `:46` unless the commit deleted the file, would match the comment at `:31` ("a guard that cannot read what it compares never passes").

## Not verified
- **The real workflow on GitHub Actions** was not run, since nothing could be published or sent to a forge. Not covered:
  - that `actions/checkout@v4.4.0` with `fetch-depth: 0` on a tag push brings a non-shallow history and `refs/remotes/origin/main`;
  - job ordering by `needs: create`;
  - the real behaviour of `gh` `view`, `create --verify-tag` and `upload --clobber`;
  - the macOS and arm64 runners, which have their own `git` versions for `--is-shallow-repository`.

  The person should watch the first `v0.6.1` push. If the guard refuses with "shallow" or "cannot read bin/polype", the checkout did not bring what the guard reads.
- **The history search on a repository with a long history, or a partial clone,** was measured only on this repository (30 commits touching `bin/polype`).
- **`bin/po-release --sums` on `.sha256` files downloaded by `gh release download`, and on macOS,** was not run. The first real release covers it.
- **One point of the security finding** was read, not run. It belongs to that finding.
- **The full unit suite** was not rerun. I relied on the current verification record (`po-gate verif-current` exited 0), plus my own runs of the two story test files.

Max severity: major
Ship allowed: yes

Method version: 0.6.1
Recorded: 2026-11-18T10:07:24+01:00

Diff reviewed: `git diff main...story/s189-first-release-holds`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 3
Reviewed tree: 90780f6120cae59cf1e1761a8160d70718290198

## Ownership
Diff listed with `git diff --name-only main...story/s189-first-release-holds`, and each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`: `.github/workflows/release.yml`, `bin/po-release`, `bin/polype`, `docs/ci.md`, `tests/first-release-holds.oracle.test.sh`, `tests/first-release-holds.test.sh` and `tests/po-prebuilt-and-verified.oracle.test.sh`. The research, plan, verif and review files are the story's own evidence.
- [x] No path lies inside another running story's `Owns`. The only other worktree is `.claude/worktrees/framing-m22`, on `fix/qa-deadline-wording`, and it is not a story lane.

## Evidence reused
- [x] `po-gate verif-current s189-first-release-holds` → exit 0, so I reused the record (Tree 4edb21b…, status complete). I read its "Not proven here" section. I also ran the two story test files myself on the unmutated code: 12 passed, 0 failed.
- [x] `po-gate qa-current`: not required. `QA stage` is `—`.

## Plan
- [x] Fix run 3 (a4b01fd) touches the following, all of it the decision the owner took on d-0036 plus the previous loop's minor:
  - `bin/po-release`: the second argument of `--sums`, two new refusals in `--sums`, and the loop refusal at `:47-51`;
  - one test added, one test rewritten, and the oracle fixture;
  - `docs/ci.md`, the section on publishing a version.

  Nothing in it goes outside the plan.
- [x] Run interdicts still hold:
  - `po/`, `ci.yml` and `docs/installation.md` are untouched.
  - In `bin/polype`, only the comment changed. `POLYPE_VERSION` is 0.6.1 and `PO_SUMS` is still empty.
  - `release.yml` is unchanged since loop 2.
  - Nothing was published and no forge was called.

## References
- [x] Every git verb the new code uses exists and behaves as the code expects: `rev-parse --verify -q refs/tags/v<version>^{commit}`, `merge-base --is-ancestor <commit> <ref>`, `ls-tree <commit> -- <path>`.
- [x] `usage()` and the header comment now name `--sums <dir> <target-ref>`. The only callers of `--sums` are the story's own tests and `docs/ci.md`.

## Rules
- [x] Comments are in English and `docs/ci.md` is in French.
- [x] ADR-0105 holds: `bin/po-release` reads no forge variable, and the ref is passed as an argument. ADR-0121 holds: the sums are written into the reviewed `bin/polype`.

## Tests
- Oracle: `po-gate oracle-intact s189-first-release-holds` → exit 0
  tests/first-release-holds.oracle.test.sh: changed, logged in ## Oracle changes — fix run: `publish` first gives the copy an `origin/main` holding its own `bin/polype` (empty `PO_SUMS`), as the release job's `fetch-depth: 0` checkout does; no assertion changes — review major at `release.yml:33`: `bin/po-release --tag` now reads `PO_SUMS` at `origin/main` and refuses when it cannot, so a replay without that ref fails every release. The fixture gives the replay what the real checkout gives; `release_reruns_cleanly` and `tag_must_match_the_version` still assert what they did. The sum in the plan no longer matches this file
  tests/first-release-holds.oracle.test.sh: changed, logged in ## Oracle changes — fix run 3: `test_sums_are_written_by_a_command` gives the copy a commit of `origin/main` tagged `v$VERSION` (new helper `tagged_on_main`) and calls `bin/po-release --sums "$sums" origin/main`; no assertion changes — the fix of the security finding of d-0036 makes `--sums` take the target ref as a second argument, as ADR-0105 wants it given what it compares against; the fixture gives the command what a person's clone of `main` gives. The written block, the byte-identical second run and the install from the sums are asserted as before
  po-gate: 2 logged oracle change(s) of s189-first-release-holds to judge
- [x] Oracle: `po-gate oracle-intact` → exit 0, with 2 logged changes to judge.
  - The first is loop 1's `publish()` fixture, already judged.
  - The second is fix run 3's change to `test_sums_are_written_by_a_command`. It adds a setup helper, `tagged_on_main`, which commits `bin/polype`, tags it `v$VERSION` and points `origin/main` at it. It also passes `origin/main` as the new argument. Every assertion is unchanged: the block written equals the three `.sha256` lines, `bin/polype` still parses, a second run leaves it byte-identical, and an install lays the published po from those sums.
  - The fixture gives the command what a person's clone of `main` gives, so the criterion `sums_are_written_by_a_command` is not weakened.
- [x] Floor: `po-gate floor-guard s189-first-release-holds main` → exit 0, nothing lowered.
- [x] 12 story tests, plus one assertion changed in s171's oracle, within `Test budget: 25`. None of the six empty test shapes appears.
  - The rewritten `test_sums_refuse_a_broken_line` now runs with a valid tag on `origin/main`, expects exit 1 and checks each refusal's own message. That is stronger than the old `-ne 0`, which an exit 2 from the wrong usage would have passed.
- [x] Bite. Each mutation was made on `bin/po-release`, then I ran only `first-release-holds.test.sh` and `first-release-holds.oracle.test.sh`. After each one, `git checkout -- bin/po-release` restored the file and `git diff --exit-code bin/po-release` was clean.
  - **G** and **H**, the two new `--sums` refusals for d-0036: each fails 1 test, `sums_only_for_a_tag_of_the_target_branch`.
    - G bites only through its expected message, because H still refuses right after it, so behaviour stays closed either way.
  - **I**, the history-read refusal at `:45` turned into `|| true` (loop 2's mutation F): 1 failure, `tag_guard_fails_closed`. Loop 2's minor is resolved.
  - **J**, the refusal at `:50` (`[ -z "$listed" ] || refuse`) replaced by `true`: 0 failures.
  - **K**, the `ls-tree` refusal at `:49` turned into `|| true`: 0 failures.
  - **L**, `:50` changed to refuse unconditionally, even for a commit that deleted the file: 0 failures. See Findings.
- [x] Decision d-0036: resolved. It is held by `test_sums_only_for_a_tag_of_the_target_branch`.

## Neighbours
- [x] I read every caller of `bin/po-release`: both `--tag` lines and the `dist` line in `release.yml`, s171's oracle and task test (build mode only, unchanged), and the story's tests. Nothing calls `--sums` with the old single argument.
- [x] `docs/ci.md` against the code:
  - Step 3 lists the `--tag` refusals as the code has them at `:30-58`.
  - Step 4 lists the `--sums` refusals at `:64-67` and `:77-86`, and the no-write case at `:102-104`.
  - It claims nothing the code does not hold. It omits a few refusals (no `.sha256` at all, no single `PO_SUMS=' ` line, a block that would no longer parse), but it does not present its list as complete.
- [x] A first release, followed step by step: I found no refusal the person cannot get past.
  - Step 2 tags a commit of main.
  - Step 3 passes on that commit: it is an ancestor of `origin/main`, main's `bin/polype` holds the block, and no commit of main ever held `  po-0.6.1-` (`git log -S` found none).
  - Step 4 passes once `git fetch --tags origin` and a fresh `origin/main` are in place, and both are written in the step.
  - Every refusal names its own remedy: fetch the tags, tag a commit of main, or publish a new version.
- [x] Edge case, read but not run. If main bumps its version before the sums of the previous version land, `--sums` on main looks for the new tag and refuses. The way out is to release the new version. The doc does not mention this, but the refusal message points to the missing tag.

## Lenses
Lenses run: security — `.github/workflows/release.yml`, `bin/po-release` (release publishing and the sums every installer trusts)
- [x] The lens finding is graded and listed under Findings.

## Findings
Security findings: 1 — decision d-0037
- minor — bin/po-release:47 — The block at `:47-51` changes no outcome and no test exercises it.
  - Mutations J, K and L all leave the 12 tests green.
  - A missing blob makes the `git log -S` at `:44` fail first, so the refusal is caught at `:45`.
  - A commit that deleted `bin/polype` is listed only after a commit that added the version's sums, so the version is refused there anyway.
  - The record says this openly. Either drop the block or keep it with a comment that it is defensive only.

## Not verified
- **The real workflow on GitHub Actions** was not run, since nothing could be published or sent to a forge. Not covered:
  - the `fetch-depth: 0` checkout on a tag push bringing `refs/remotes/origin/main` and a full, non-shallow history;
  - `needs: create` ordering;
  - the real `gh release view`, `create --verify-tag` and `upload --clobber`;
  - the macOS and arm64 runners' `git`.

  The person should watch the first `v0.6.1` push.
- **The forge-side ruleset on release tags** is set outside the story and was not inspected. The person should confirm that it covers creating, updating and deleting `v*` tags.
- **`--sums` on `.sha256` files from a real `gh release download`, and on macOS,** was not run. The first real release covers it.
- **Step 4 of `docs/ci.md` on a clone whose local tag diverges from the forge's tag** was not run. `git fetch --tags` does not overwrite an existing local tag. The person should fetch tags into a fresh clone.
- **The full unit suite** was not rerun. I relied on the current verification record (`po-gate verif-current` exited 0), plus my own runs of the two story test files.
- **Type check, end-to-end and build:** the project has none (`Typecheck`, `E2E`, `Build` are `—`).

Max severity: major
Ship allowed: yes

Method version: 0.6.1
Recorded: 2026-11-18T11:10:12+01:00

Review status: complete
Fix loop: 4
Reviewed tree: c13d15bcc8e2d35b9ef60b42d40e5cc0acddc82a

## Ownership
I listed the diff with `git diff --name-status main...story/s189-first-release-holds` and checked each path against the story's `Owns` (`docs/stories.md:3068`).
- [x] Every path is inside `Owns`: `.github/workflows/release.yml`, `bin/po-release`, `bin/polype`, `docs/ci.md`, `tests/first-release-holds.oracle.test.sh`, `tests/first-release-holds.test.sh`, `tests/po-prebuilt-and-verified.oracle.test.sh`, and `docs/decisions/ADR-0129-…md` (status `A`). The ADR is covered by the `docs/decisions/` entry, which the merge d2da1f1 brought in from main's framing commit cfdc503. The research, plan, verif and review files are the story's own evidence.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows main, `.claude/worktrees/framing-m22` (branch `fix/qa-deadline-wording`, not a story) and this lane.
- [x] The merge d2da1f1 adds no code to the story. It touches only `docs/decisions-log.md` and `docs/stories.md`, which sit on main and are outside the `main...story` diff.

## Evidence reused
- [x] `po-gate verif-current s189-first-release-holds` exited 0 (Tree a168ca4…, status complete, last `Unit suite` row exit 0). I did not rerun the full suite. I read "Not proven here".
- [x] The gate compares code outside `docs/` only, and fix run 4 added an ADR under `docs/`. So I ran the 34 test files that read `docs/decisions`, `docs/ci.md` or `ADR directory`: 222 passed, 0 failed. I also ran the two story test files and s171's oracle unmutated: all green.
- [x] `po-gate qa-current` is not required (`QA stage: —`). The project has no type check, E2E or build (`—`).

## Plan
- [x] Fix run 4 (56283b4) changes `bin/po-release:46-48`, adds ADR-0129, adds four lines to `docs/ci.md` and updates the verif and review files. It touches no test and no oracle.
- [x] The plan does not list the ADR. The story's notes (`docs/stories.md:3077`) put `docs/decisions/` in `Owns` for ADR-0129 alone, which the owner accepted, so it is not an unrequested change.
- [x] **The owner's decision on the security finding of d-0037, against ADR-0129 and `docs/ci.md`.** The ADR records it faithfully:
  - It chooses option A and dates the owner's choice 2026-11-18 (d-0037 to d-0039).
  - It says who may write: the owner, plus `release.yml` with `contents: write`, which matches the workflow's `permissions`, and `ci.yml`, which is `contents: read`. It mentions the ruleset on `v*` tags.
  - It names the risk that stays, in the generic terms of its own Context.
  - It says what lifts the risk: the identical rebuild of `po`. That rebuild is indeed placed in M23 (`docs/stories.md:3385`, decisions d-0038 and d-0039).
  - It says when the decision reopens.
  - It describes only what the code binds: tag to version, tag to a commit of the target branch, single publication, sums only from a tag of main. I checked each against `bin/po-release:29-63`.
  - Option B's rejection rests on ADR-0105, which holds: `bin/po-release` reads no forge variable.
  - The `docs/ci.md` sentence (`:40-43`) gives the same instruction as the ADR's Neutral consequence, and its relative link resolves.
  - Since the owner accepted this in an accepted ADR, I do not raise it again.
- [x] The previous minor at `bin/po-release:47` is settled as the commit says: one refusal line replaces the branch. Its claim that the line is unreachable is wrong, though; see Findings.
- [x] Run interdicts still hold. `po/`, `ci.yml` and `docs/installation.md` are untouched. In `bin/polype`, only the comment changed (`POLYPE_VERSION` 0.6.1, `PO_SUMS` empty). `release.yml` is unchanged in this run. Nothing was published and no forge was called.

## References
- [x] `git log --full-history -S … -- bin/polype` and `git show <commit>:bin/polype` behave as the code expects. Neither main nor the story branch has any commit with `  po-0.6.1-` in `bin/polype` (0 commits), so the first release is not locked out.

## Rules
- [x] Comments are in English, and `docs/ci.md` and the ADR are in French.
- [x] The ADR follows `templates/adr.md` and the `ADR-NNNN-<slug>.md` naming of its neighbours. "Option choisie" also appears in 16 other ADRs.

## Tests
- Oracle: `po-gate oracle-intact s189-first-release-holds` → exit 0
  tests/first-release-holds.oracle.test.sh: changed, logged in ## Oracle changes — fix run: `publish` first gives the copy an `origin/main` holding its own `bin/polype` (empty `PO_SUMS`), as the release job's `fetch-depth: 0` checkout does; no assertion changes — review major at `release.yml:33`: `bin/po-release --tag` now reads `PO_SUMS` at `origin/main` and refuses when it cannot, so a replay without that ref fails every release. The fixture gives the replay what the real checkout gives; `release_reruns_cleanly` and `tag_must_match_the_version` still assert what they did. The sum in the plan no longer matches this file
  tests/first-release-holds.oracle.test.sh: changed, logged in ## Oracle changes — fix run 3: `test_sums_are_written_by_a_command` gives the copy a commit of `origin/main` tagged `v$VERSION` (new helper `tagged_on_main`) and calls `bin/po-release --sums "$sums" origin/main`; no assertion changes — the fix of the security finding of d-0036 makes `--sums` take the target ref as a second argument, as ADR-0105 wants it given what it compares against; the fixture gives the command what a person's clone of `main` gives. The written block, the byte-identical second run and the install from the sums are asserted as before
  po-gate: 2 logged oracle change(s) of s189-first-release-holds to judge
- Oracle: `po-gate oracle-intact s189-first-release-holds` → exit 0
- [x] Oracle: exit 0, with 2 logged changes to judge. Both are earlier fix runs' fixture changes (`publish()` and `tagged_on_main`), already judged as not weakening their criteria. Fix run 4 did not touch any oracle.
- [x] Floor: `po-gate floor-guard s189-first-release-holds main` → exit 0.
- [x] 12 story tests plus one changed assertion in s171's oracle, within `Test budget: 25`. None of the six empty test shapes appears.
- [x] Bite, on `bin/po-release`. After each mutation I ran only `first-release-holds.test.sh` and `first-release-holds.oracle.test.sh`, then `git checkout -- bin/po-release`; `git diff --exit-code` was clean each time.
  - **M.** The history check at `:51` replaced by `if false`: 2 tests failed, `rerun_refused_once_sums_landed` and `rerun_refused_after_later_sums_replace_them`.
  - **N.** The new refusal at `:47-48` replaced by `|| continue`: 0 tests failed. The record says this up front. See Findings for why the record's reason does not hold.

## Neighbours
- [x] The callers of `bin/po-release` are unchanged since loop 3: `release.yml`, s171's oracle and task test (build mode), and the story's tests.
- [x] What the new line changes. In a throwaway clone (removed afterwards), I made three commits:
  1. add a comment line holding `  po-0.6.1-` to `bin/polype`;
  2. move `bin/polype` away;
  3. move it back.

  Then `bin/po-release --tag v0.6.1 HEAD` exits 1 with "cannot read bin/polype at commit … ". The fix-run-3 version of the script exits 0 on the same history. The new refusal fails closed, but it locks that version for good, and its message points at reading rather than at a dropped file.

## Lenses
Lenses run: security — `bin/po-release`, `.github/workflows/release.yml`, ADR-0129 (release publishing and the sums every installer trusts)
- [x] The security finding of d-0037 is lifted, citing decision d-0037: the owner accepted it in ADR-0129, which records it faithfully. The lens found nothing new.

## Findings
- minor — bin/po-release:47 — The refusal now reachable at `:47-48` is held by no test (mutation N: 0 failures). The verification record also gives a wrong reason for leaving it untested.
  - The record says "a normal clone cannot reach that line, since the history search reads the same blobs first".
  - A commit that drops or moves `bin/polype` while the file still holds `  po-<v>-` is listed by `-S`. Its tree has no `bin/polype`, so the line refuses. My probe reached it in an ordinary clone.
  - When the dropped text sat in the block, the refusal is correct anyway. When it sat elsewhere, the version is locked for good with a misleading message.
  - This needs contrived history and fails closed. Either a test for the dropped-file case, or a record that says what the line really does, would settle it.

## Not verified
- **The forge's actual state** that ADR-0129 relies on was not inspected, since no forge was called:
  - only the owner holds write access to the repository and its releases;
  - the "release tags" ruleset reserves create, move and delete of `v*` tags to admins.

  The owner should confirm both in the repository settings.
- **The real workflow on GitHub Actions** was not run. Not covered:
  - the `fetch-depth: 0` checkout bringing `origin/main` and a non-shallow history on a tag push;
  - `needs: create` ordering;
  - real `gh release view`, `create --verify-tag` and `upload --clobber`;
  - the macOS and arm64 runners' `git`.

  The person should watch the first `v0.6.1` push.
- **`--sums` on `.sha256` files from a real `gh release download`, and on macOS,** was not run. The first real release covers it.
- **The full unit suite** was not rerun. I relied on the current record (`po-gate verif-current` exit 0), plus my run of the 34 test files that read the ADR folder or `docs/ci.md`, and of the story's test files.
- **Type check, end-to-end and build:** the project has none (`Typecheck`, `E2E`, `Build` are `—`).

Max severity: minor
Ship allowed: yes
