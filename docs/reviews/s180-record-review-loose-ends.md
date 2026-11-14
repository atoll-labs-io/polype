# Review — s180-record-review-loose-ends

[Story](../stories.md) · [Plan](../plans/s180-record-review-loose-ends.md) · [Verification](../verif/s180-record-review-loose-ends.md)

Method version: 0.2.0

Review status: complete
Fix loop: 0
Reviewed tree: a3120cb45c4f180ae11314aa5976f86b3d65703e
Lenses run: security — file handling in po/src/record/security.rs (write_private, check_outside); dependencies — po/Cargo.lock, po/Cargo.toml (own package version only, no dependency entry added, removed or bumped)

## Scope
`git diff --name-only main...story/s180-record-review-loose-ends` lists bin/polype, po/Cargo.lock, po/Cargo.toml, po/src/record/mod.rs, po/src/record/security.rs and tests/record-review-loose-ends.oracle.test.sh, plus the story's own research, plan and verif files. Every path is inside the story's `Owns` line or is pipeline evidence. Nothing outside `Owns`, and no run interdict is broken: nothing under method/, .polype/, .claude/ or docs/decisions/, no new error code, no environment variable, feature or cfg seam, and the temp name and write order of `write_atomic` are unchanged.

## Tests
- Oracle: `po-gate oracle-intact s180-record-review-loose-ends` → exit 0
- Record: `po-gate verif-current` exits 0. The suite (`bash tests/run.sh`) exits 0 on tree 761607b1… (code identical), so it was not rerun. The record's "Not proven here" section was read: it covers the doc-comment wording and the last-write failure on an existing review, which I probed (below).
- Floor: `po-gate floor-guard … main` exits 0.
- Baseline: the oracle passed 4/4, built under a temp CARGO_TARGET_DIR.
- Bite, d-0022 fix (security.rs). Each mutation was undone and confirmed with `git diff --exit-code`.
  - Both checks off (body of `check_outside` made a no-op): 1 failure, `security_finding_of_d_0022_is_closed`. The run falls through to the old `sensitive-context-in-repo`.
  - Only the `prepare()` call removed: 0 failures.
  - Only the `write_private()` call removed: 0 failures.
  - So each call alone keeps the test green, and the `write_private()` call is held by no test. The plan says this check cannot be reached from outside; I read it, see the findings.
- Bite, mod.rs.
  - `roll_back` made a no-op that returns true: 2 failures (`failed_keep_rolls_the_review_back`, `reply_is_true_when_the_last_write_fails`).
  - Only the last-write branch's rollback removed: 1 failure (`reply_is_true_when_the_last_write_fails`).
  - Both undone and confirmed.
- Probe of the untested case (temp script, real `po`): the last write fails on an existing review, and the restore fails too, because the same temp name is blocked. The reply is `unwritable`, exit 2, `written: true`, the message names d-0001 and "the review still holds its provisional count line", and the decision is kept. That is true of the disk. The unavoidable cost: the appended block still reads "none kept, this answer fails findings-shape" although a decision was posted, and the message says so. One correction: an earlier probe run used a stale binary and showed `written: false`. That was my own error, discarded after a rebuild.
- `written` in each failure branch:
  - prepare refusal: false, nothing written.
  - keep failure: `!rolled_back`.
  - last-write failure: `!rolled_back`.
  - Each is true of the disk. One edge: `remove_file` returning NotFound because an outside actor deleted the review gives `written: true` with nothing on disk. Remark only, not reachable by po itself.
- Version: 0.3.0 → 0.3.1 together in po/Cargo.toml:3, the `po` package of po/Cargo.lock and bin/polype:27. `test_version_goes_up` holds it.
- Test budget: 4 oracle tests, within 25. No test that proves nothing: real filesystem, real gate script, no mocks.

## Findings
- minor — po/src/record/security.rs:245 — the second call of `check_outside`, inside `write_private`, fails no test when removed; only the `prepare()` call is held by `test_security_finding_of_d_0022_is_closed` (the plan says this branch cannot be reached from outside)
- minor — po/src/record/security.rs:229 — security finding, detail handed to the lead privately
- minor — po/src/record/security.rs:232 — security finding, detail handed to the lead privately
- minor — po/src/record/security.rs:245 — security finding, detail handed to the lead privately

## Remarks
- The commit message, the test names and the plan only say "the finding of d-0022". The weakness is not described there.
- Step 2: `inbox::place` and `Place` (po/src/inbox/add.rs:118, imported at security.rs:11) exist with the signatures used, and `keep()` is the only caller of `write_private`. The reuse matches the plan's `## Reuse`.
- Dependencies lens: only the crate's own version moves in Cargo.lock. No changelog or install-script check applies.

## Not verified
- Test 2's root branch (a plain file in place of the 0500 folder): I ran as a normal user. Running the oracle once as root would cover it.
- No real concurrent race was attempted against the window between the check and the open in `write_private`. It was judged by reading only.
- Platforms other than Linux (macOS canonicalisation, `/private/tmp`): not run.
- ADR-0123 was not reread in full; I relied on the plan and the s178 review for its rule.
- No QA: `QA stage: —`.

Max severity: minor
Ship allowed: yes

Method version: 0.2.0

Review status: complete
Fix loop: 1
Reviewed tree: f7bc6979eda9251e4701cefbd2d8ce5ca3a47763
Lenses run: security — path handling in po/src/inbox/add.rs (`place`) and po/src/record/security.rs (`check_outside`, `write_private`); dependencies — po/Cargo.lock, po/Cargo.toml (only the crate's own version moves)

## Scope
`git diff --name-only main...story/s180-record-review-loose-ends` lists these paths:
- code: bin/polype, po/Cargo.lock, po/Cargo.toml, po/src/inbox/add.rs, po/src/record/mod.rs, po/src/record/security.rs
- tests: tests/record-review-loose-ends.oracle.test.sh, tests/record-review-loose-ends.test.sh
- the story's own research, plan and verif files

The story's `Owns` line covers every one of them, including `po/src/inbox/` after the owner's answer d-0024. Nothing touches method/, docs/interface-agent.md, .polype/ or .claude/, and no new error code appears. The fix commit 7f9d37e changes add.rs, security.rs and the record, and adds the new test file.

## Tests
- Oracle: `po-gate oracle-intact s180-record-review-loose-ends` → exit 0
- Gates. Each gate below exits 0:
  - `po-gate floor-guard … main`.
  - `po-gate verif-current`: the suite exits 0 on tree 2a88f208…, whose code matches the reviewed code, so I did not rerun it. I read the record's "Not proven here" section, including its two fix-run entries.
- Inbox tests unchanged. The diff touches no file under tests/ besides the story's two files. tests/decision-inbox*.test.sh and tests/security-findings-stay-private*.test.sh are untouched. I ran them on a build of this tree under a temp CARGO_TARGET_DIR, and with the story's files they give 29 passed, 0 failed.
- Bite tests. Only the story's two test files were rerun after each mutation. Each mutation was undone and checked clean with `git diff --exit-code`.

| # | Mutation | Failing tests |
| --- | --- | --- |
| A | Remove the check in `write_private` | 1 (`folder_that_appears_after_prepare_is_refused`) |
| B | Open under the configured path instead of the canonical one | 0 (the window can't be tested without a race; the record says it was judged by reading) |
| C | `place` folds the path lexically before resolving, as on main | 1 (`private_folder_value_resolves_as_written`) |
| D | Make the `check_outside` body a no-op | 2 (`security_finding_of_d_0022_is_closed`, `folder_that_appears_after_prepare_is_refused`) |
| E | Remove only the `prepare()` call | 0 (the second check and the rollback give the same outcome on disk) |
| F | Make `roll_back` a no-op | 3 (the two rollback oracles and the first new test) |

- **Comparing `place` with main.** I ran `po inbox add` with a sensitive context through about 30 paths, on main's `po` and on this tree's. Plain paths, trailing slashes, a link outside the repository, a missing tail, a link loop, paths under `.git`, under the root and in another worktree, and relative input give the same answer on both. The inputs where the two differ are the subject of the finding below.
- **Decision context.** It now names a canonical path. Nothing in po/src, bin/ or method/ compares it with the configured `Private folder`. Agents read it through `po inbox <id>` and open it as a path. On a platform where the temp dir is a symlink, the s178 oracle line `case "$context" in "$SCRATCH/private/"*` would not match. CI runs on ubuntu only.
- Test budget: 6 tests, within 25. The second test file follows the conventions and holds review findings.

## Findings
- major — po/src/inbox/add.rs:136 — security finding, detail handed to the lead privately

## Previous findings (Fix loop 0)
- minor — security.rs:245, second call untested: resolved. Bite A shows that `test_folder_that_appears_after_prepare_is_refused` now holds it.
- minor — security.rs:229, security finding: resolved, detail handed to the lead privately.
- minor — security.rs:232, security finding: resolved for `po record review`; a variant remains in the shared helper (the finding above). Detail handed to the lead privately.
- minor — security.rs:245, security finding: resolved as proposed, detail handed to the lead privately.

## Remarks
- The commit message, the two new test names and the new doc comment of `check_outside` ("checked before anything is written, and again on the path the file is then opened under") do not describe a weakness. The two test names describe the behaviour they hold, and their fixtures show no more than they have to.
- Bite E: the `prepare()` check alone is held by no test. Its job is to refuse before the review is written; the rollback hides the difference on disk.
- Step 2: the calls of `inbox::place`, `Place`, `Component` and `normalise` exist with the signatures used. `write_private` is called only from `keep()`.
- Dependencies lens: only the crate's own version moves to 0.3.1, the same in po/Cargo.toml:3, Cargo.lock and bin/polype:27.

## Not verified
- No real concurrent race against the window left in `write_private` (bite B can't be caught). Judged by reading.
- macOS and other platforms whose temp dir is a symlink: not run. The s178 oracle's prefix check on the context may fail there; a person should run the suite once on macOS.
- The root branch of the 0500 fixture: I ran as a normal user, not as root.
- ADR-0123 not reread in full.
- No QA: `QA stage: —`.

Max severity: major
Ship allowed: yes

Method version: 0.2.0

Diff reviewed: `git diff main...story/s180-record-review-loose-ends`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 2
Reviewed tree: 24f5e9f9ec312d131ce2a9f5c1730f536d9f7625

## Ownership
`git diff --name-only main...story/s180-record-review-loose-ends` lists these paths:
- bin/polype, po/Cargo.lock, po/Cargo.toml, po/src/inbox/add.rs, po/src/record/mod.rs, po/src/record/security.rs
- tests/record-review-loose-ends.oracle.test.sh, tests/record-review-loose-ends.test.sh
- the story's own research, plan and verif files

- [x] Every path is inside the story's `Owns` line (`po/src/record/`, `po/src/inbox/`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype` and the story's two test files), or is pipeline evidence.
- [x] Nothing lies outside `Owns`, and nothing lies inside another running story's `Owns`.
- [x] The fix commit dc0ea34 changes only po/src/inbox/add.rs, the story's second test file and the record.

## Evidence reused
- [x] `po-gate verif-current` exits 0. The suite exited 0 on tree 4e8f716a…, whose code matches the reviewed code, so I did not rerun it. I read "Not proven here", including both of its "Fix run 2" entries.
- [x] `po-gate qa-current` is not required: `QA stage: —`.

## Plan
- [x] Fix mode: the change answers the finding of loop 1 and the owner's choice in d-0025 (refuse rather than resolve). Nothing else changes.
- [x] Interdicts hold:
  - no new error code;
  - nothing under method/, docs/interface-agent.md, .polype/ or .claude/;
  - the four guarded test files (tests/decision-inbox{,.oracle}.test.sh and tests/security-findings-stay-private{,.oracle}.test.sh) are unmodified, both in the diff and on disk.

## References
- [x] `Place::Unverified` is handled at every use of `Place`:
  - add.rs:44 (`== Outside`): refused.
  - add.rs:187-189 (`kept_out_of_git`): Unverified → false, refused.
  - security.rs:223 and :232 (`!= Outside`): refused.
  - mod.rs:16 only re-exports it.
  - No caller takes Unverified for outside.
- [x] Reading `place`: for a path without `..`, `place` is `resolve(abs)`. That matches main's code, with two branches that main answered Outside and this tree answers Unverified. Both are stricter and cannot be reached without a race: no existing ancestor, and an ancestor that exists but cannot be canonicalised. The record notes both.
- [x] The doc comment of `place` (add.rs:117-120) states the rule: a `..` after the nearest existing ancestor, or a disagreement between the filesystem reading and the hand fold, gives Unverified. It does not describe how the earlier gap worked.
- [x] The three new test names state behaviour, not the weakness.

## Rules
- [x] `AGENTS.md` conventions are respected: commit message in English, no co-author trailer, version 0.3.1 identical in po/Cargo.toml, Cargo.lock and bin/polype.
- [x] No accepted ADR is contradicted. ADR-0123's `Private folder` rule still holds.

## Tests
- Oracle: `po-gate oracle-intact s180-record-review-loose-ends` → exit 0
- [x] Floor: `po-gate floor-guard s180-record-review-loose-ends main` → 0, nothing lowered
- [x] Baseline, built under a temp CARGO_TARGET_DIR: the story's two files and the four guarded files give 32 passed, 0 failed.
- [x] Real filesystem, real git, real gate script, no mocks. None of the six empty test shapes.
- [x] 9 tests (4 oracle + 5), within `Test budget` 25.
- [x] Bite. After each mutation I reran only the files that exercise the rule. Each mutation was undone with `git checkout --` and confirmed clean with `git diff --exit-code`:

| # | Mutation | Failing |
| --- | --- | --- |
| M1 | `place` returns the as-written answer without comparing it with the folded one (add.rs:127) | 0 of 19 |
| M2 | `resolve` no longer refuses a `..` in the missing part (add.rs:152) | 1 (`a_path_that_cannot_be_verified_is_refused`) |
| M3 | `kept_out_of_git` takes Unverified for outside (add.rs:188-189) | 1 (`an_inbox_that_cannot_be_verified_is_refused`) |
| M4 | security.rs:223 lets Unverified pass, alone | 0 of 22 (`check_outside` in `prepare()` still refuses) |
| M5 | security.rs:223 and :232 both let Unverified pass | 2 (`a_private_folder_that_cannot_be_verified_is_refused`, `private_folder_value_resolves_as_written`) |

  - M2 leaves the inbox and private-folder tests green because the M1 comparison also catches their shapes.
  - I built M1 and ran it through the full parity set. Compared with main, it accepts only extra paths that physically lie outside: 2 contexts, 3 inbox values and 2 private folders. No decision and no witness lands in a repository. So M1 removes the parity with main, not a protection. See the findings.

## Neighbours
- [x] Every caller of `place` and of `kept_out_of_git` was read (above).
- [x] `post` (add.rs:37) and `inbox::find` are unchanged.
- [x] The build warning (`not_built` never used, output.rs:46) also appears on main. It is not new.

## Parity run (main's `po` vs this tree's)
- **Builds.**
  - main (ccbfc47): cloned via file:// into a temp dir.
  - this tree: built from the worktree.
  - Each under its own temp CARGO_TARGET_DIR. Nothing was installed over ~/.claude/polype/po.
- **Paths.** I wrote my own list of 158 paths, with and without `..`, through links of several kinds, relative input, trailing and empty components, the root itself and deep missing tails.
- **Fixture.** Each path ran in a fresh fixture, so a folder created by one probe never affected the next.

| Channel | Paths run | Differ | main refuses, this tree accepts |
| --- | --- | --- | --- |
| sensitive `context` of `po inbox add` | 158 | 31: main accepts, this tree refuses | 0 |
| `Decision inbox` setting | 154 (4 absolute non-scratch paths skipped; they would write into system folders) | 36: 34 main accepts → refused; 2 main `inbox-unwritable` → refused | 0 |
| `Private folder` with `po record review` | 153 (5 skipped, same reason) | 37: 29 main accepts → refused; 8 refused on both, under another code | 0 |

- **Differences.**
  - Every path whose answer from `place` differs holds a `..`, and every such difference goes towards refusal.
  - Three `..`-free Private folder values are refused by both binaries: main as `sensitive-context-in-repo` after writing, this tree as `private-folder-unusable` before writing. `place` itself answers them the same on both binaries; the sensitive-context channel shows it. The earlier refusal comes from the d-0022 check of loop 0 in security.rs, not from this fix.
- **Totals:** 465 probes per binary, 104 differ, 0 in the unsafe direction, 0 `..`-free paths whose `place` answer changed. On this tree no decision and no witness text lands inside a repository, on any channel.

## Lenses
Lenses run: security — path handling in po/src/inbox/add.rs (`place`, `resolve`, `kept_out_of_git`) and po/src/record/security.rs (Private folder checks); dependencies — po/Cargo.toml, po/Cargo.lock (only the crate's own version moves, 0.3.0 → 0.3.1; no dependency entry added, removed or bumped)
- [x] Each lens finding graded and listed below.

## Findings
- minor — po/src/inbox/add.rs:189 — an `Unverified` answer reaches refusals that say the path lies in the repository: "lies in the repository and git does not ignore it: add it to .gitignore or set Decision inbox outside" (add.rs:58), and "lies inside the repository" (security.rs:224, :236). That text is also given for values that lie outside the repository, and the advice to add the path to .gitignore cannot lift the refusal. The error codes are right; only the message text is untrue for this case.
- minor — po/src/inbox/add.rs:127 — the comparison of the as-written answer with the folded one fails no test when disabled (bite M1: 0 failures). A probe of that mutant shows that it then accepts only extra paths that physically lie outside. What the comparison adds is the claimed parity with main ("nothing main refuses is accepted"), and no test holds that parity.

## Previous findings (Fix loop 1)
- major — po/src/inbox/add.rs:136, security finding: **resolved**. The parity run shows 0 paths that main refuses and this tree accepts, and no decision or witness inside a repository, on all three channels. Detail handed to the lead privately.

## Remarks
- A few `Decision inbox` values spelled with `..` that main accepted as a git-ignored folder inside the repository are now refused. That is the strict direction the owner chose in d-0025. Paths without `..` keep their answer, so the default `.polype/inbox/` is unaffected.
- The commit message says only "address review findings". It does not describe the weakness.

## Not verified
- **Root.** No run as root. The 0500 branch of the s178 oracle fixture under root was not exercised. A person should run the story's two test files and the s178 files once as root.
- **macOS.** Not run, nor any other platform whose temp folder is a symlink. Canonical paths differ there. A person should run the suite once on macOS.
- **Races.** None attempted: between `place` and `create_dir_all`; between the canonical check and the open in `write_private`; inside `place`, where the as-written and the folded readings are two separate filesystem walks. Judged by reading only.
- **Unreachable branches.** `Unverified` for an existing ancestor that cannot be canonicalised, and for a path with no existing ancestor, was judged by reading. Neither was reached in the probes.
- **Repository layouts.** A git directory separate from the work tree (`--separate-git-dir`) and submodules were not probed.
- **ADR-0123.** Not reread in full.
- **QA.** None: `QA stage: —`.

Max severity: minor
Ship allowed: yes
