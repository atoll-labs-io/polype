# Research — s187-inbox-guards-bite

[Story](../stories.md)

## Structuring facts
- No false assumption in the story. Every defect it names reproduces on `ccee639` (po 0.6.0); the line numbers of its notes still hold, except `security.rs:223-236`, now `:225-227` and `:233-242`.
- Root cause of #263, #260, #329, #364 (and the lead's addition): the guards are right, no test reaches them. A mutant of each, built outside the worktree, passes every test file that touches the inbox (18 files, list under `## Diagnostic`): `rewrite.rs:99` `create_new` → `create` (the parallel test fails 6 runs of 10), `add.rs:168` `Elsewhere` → `Outside`, `add.rs:130` comparison → `if true`, `decision.rs:87` guard → `if false`: 0 failures each.
- Root cause of #328: `kept_out_of_git` (`po/src/inbox/add.rs:189-198`) returns a `bool` and drops the `Place`; its callers (`add.rs:53-62`, `rewrite.rs:48-54`) and `security.rs:225-227,233-242` only see "not outside" and print the text written for `InRoot`. Input: any value `place` classes `Unverified` (`add.rs:124-135`). Proof: the three refusals quoted under `## Diagnostic`.
- Root cause of #290: `output::not_built` (`po/src/output.rs:46-52`) has no caller (`grep -rn not_built po/src` finds only its definition); `cargo build` warns on it. `docs/interface-agent.md:29` still lists `not-built`.
- Everything stays inside `Owns`. Patch bump 0.6.0 → 0.6.1 (`po/Cargo.toml:3`, `po/Cargo.lock:165`, `bin/polype:27`).

## Story
A regression on the lock of a decision or on the check of its path must fail the suite every time. Criteria: `held_lock_is_refused_every_time` (a held lock gives `inbox-busy`, released it passes; mutation proof by the reviewer), `path_in_an_outside_worktree_is_refused` (sensitive `context` in a worktree outside the root, plain path), `written_and_folded_paths_agree` (a path only the as-written/folded comparison refuses is refused; mutation proof), `unverified_path_says_so` (message no longer says "in the repository" nor `.gitignore`; codes unchanged), `not_built_is_gone` (no `dead_code` warning; contract drops `not-built`), `version_goes_up` (patch, three places). Lead's addition: one implementer test for the framing guard of `Decision::stale` (#364).

## Diagnostic
Reproduction (po built from the worktree; mutants copied to `/tmp/s187-mut*`, nothing written in the worktree but this research, the plan and the oracle):
- #290: `cargo build --release --locked --manifest-path po/Cargo.toml` → `warning: function 'not_built' is never used --> src/output.rs:46:8`. A second, fresh build replays the warning (cargo caches it), so a test can read it without rebuilding.
- #263: mutant A (`rewrite.rs:99` `.create(true)`): `test_parallel_answers_record_one` failed 6 of 10 runs. Held-lock probe on real po: `.d-0001.lock` planted → `po answer` exits 2 `inbox-busy` after ~1 s (`LOCK_TRIES` 50 × `LOCK_PAUSE` 20 ms, `rewrite.rs:14-15`), file stays `pending`, the planted lock stays (`Lock` is only built on success, `rewrite.rs:100`). Same probe on mutant A: exit 0, `answered`.
- #260: real po refuses `context` `<scratch>/side/x.md` and `<scratch>/side/docs/new/x.md` (worktree `side` outside the root) with `sensitive-context-in-repo`; mutant B accepts both. The existing case `"$s/far/gone/../../side/x.md"` (`tests/record-review-loose-ends.test.sh:70`) never reaches the common-dir check: it is `Unverified` first (`add.rs:154-156`).
- #329: one context that only the comparison of `add.rs:129-134` refuses (the oracle's `test_written_and_folded_paths_agree` holds it) is refused by real po and accepted by mutant C.
- #328: unverifiable values, real po:
  - `po inbox add`: `inbox-not-ignored`, "…/far/gone/../into/inbox/ lies in the repository and git does not ignore it: add it to .gitignore or set Decision inbox outside"
  - `po answer`: `inbox-not-ignored`, "…/far/into/../../.polype/inbox/ lies in the repository and git does not ignore it"
  - `po record review`: `private-folder-unusable`, "Private folder \"…/far/gone/../into/\" lies inside the repository; nothing was written"
- #364: decision `blocks: ["s01"]`, commit `s01: landed` on `main`: real po → no `stale`, `po state` `stale: []`; mutant D → `stale: true`, `stale: ["d-0001"]`. `Landed::commit` matches the short form (`po/src/context/lanes.rs:118-121`).
- Files run against mutants B, C, D (0 failures): `answer-comes-back{,.oracle}`, `decision-inbox{,.oracle}`, `record-review-loose-ends{,.oracle}`, `security-findings-stay-private{,.oracle}`, `record-writes-reports{,.oracle}`, `stale-decisions-are-flagged{,.oracle}`, `run-from-outside{,.oracle}`, `drive-executes-next.oracle`, `driver-next-action.oracle`, `state-as-json.oracle`, `session-shows-what-waits.oracle`.

Hypotheses:
1. *The parallel test always catches a non-exclusive lock* — refuted by 4 passes of 10 on mutant A. Discarded.
2. *The lock itself is broken today* — refuted: the held-lock probe on real po gives `inbox-busy` every time. Discarded.
3. *The `..` case of `record-review-loose-ends.test.sh:70` covers an outside worktree* — refuted: it stops at `Unverified` (`add.rs:155`) and mutant B passes it. Discarded.
4. *The #328 text is wrong because `place` misclasses outside paths* — refuted: the refusals are intended (`Unverified` is "never taken for outside", `add.rs:116-117`); only the text, chosen without the `Place`, is wrong. Discarded; kept cause above.
5. *Kept*: each guard lacks a test that reaches it alone; the messages lose the `Place` at `kept_out_of_git`'s `bool`.

## Current code
- `po/src/inbox/add.rs` — `post` (`:37-68`): sensitive context must be absolute and `Place::Outside` (`:39-52`, message `:49`), inbox must be `kept_out_of_git` (`:53-62`, message `:58`). `Place` (`:109-118`), `place` (`:124-135`: as-written vs folded comparison `:129-134`), `resolve` (`:141-171`: common-dir check `:163-170`), `kept_out_of_git` (`:189-198`).
- `po/src/inbox/rewrite.rs` — `rewrite` (`:34-94`): `kept_out_of_git` check (`:48-54`, message `:52`), lock beside the file `.<id>.lock` (`:57`), `take` (`:97-110`, `create_new` `:99`).
- `po/src/record/security.rs` — `private_folder` (`:201-229`, place check `:225-227`), `check_outside` (`:233-242`), both through `inbox::place` and `Place` re-exported at `po/src/inbox/mod.rs:17`.
- `po/src/output.rs` — `#[allow(dead_code)]` on `REFUSED` (`:6`), now used (`add.rs:47`, `security.rs:161`); `not_built` (`:46-52`) unused.
- `po/src/inbox/decision.rs:82-92` — `stale`, framing guard `:87`.
- `docs/interface-agent.md:29` (exit-code list naming `not-built`), `:179-180` and `:197` (refusal tables: "pointe dans le dépôt", "boîte dans le dépôt que git n'ignore pas").

## Attachment points
- Messages: a method on `Place` beside its definition (`add.rs:109-118`) giving why a path is not outside; `kept_out_of_git` returns the reason instead of a `bool`; its two callers and the two checks of `security.rs` print it.
- Dead code: delete `output.rs:46-52` and the stale `#[allow(dead_code)]` of `:6`.
- Tests: `tests/inbox-guards-bite.oracle.test.sh` (written, the oracle) and `tests/inbox-guards-bite.test.sh` (implementer).

## Verified interfaces
- `pub(crate) fn place(project: &Project, path: &Path) -> Place` (`add.rs:124`), `pub(crate) enum Place { Outside, InRoot(PathBuf), Elsewhere, Unverified }` (`add.rs:110-118`).
- `pub(super) fn kept_out_of_git(project: &Project, dir: &Path) -> bool` (`add.rs:189`); callers `add.rs:53`, `rewrite.rs:48` only.
- `pub fn error(code: i32, error: &str, message: impl Into<String>) -> i32` (`output.rs:37`).
- `type Refusal = (i32, &'static str, String)` in `security.rs`, `unusable` closure (`security.rs:212-214`).
- `Decision::stale(&self, &Landed) -> bool` (`decision.rs:82`); `po state` lists marked ids under `stale` (probe above).
- Test helpers reused: `secure_fixture`, `answer`, `rec`, `SECURE_FINDINGS` (`tests/security-findings-stay-private.oracle.test.sh:10-44`, sourcing `tests/record-writes-reports.oracle.test.sh`); `fixture`, `valid`, `po_in` (`tests/decision-inbox.oracle.test.sh:14,38-82`).

## Traps
- No test pins the text of the messages that change (`grep` over `tests/`); `docs/interface-agent.md` quotes no message. Codes and exits must not move: `tests/record-review-loose-ends.test.sh:67-107` and `decision-inbox.oracle` check them.
- `bin/po-version-check` (run by a suite test) refuses a change under `po/` without the bump in all three places.
- The held-lock test waits ~1 s for `inbox-busy`; renaming the lock (`rewrite.rs:57`) would break the oracle.
- The `not_built_is_gone` oracle runs `cargo build` into the `CARGO_TARGET_DIR` that `tests/run.sh:11` exports; fresh, it only replays warnings.
- Story notes: no text anywhere, tests included, describing how to get past the check; test names do not describe the weakness.
- `tests/answer-comes-back.test.sh` and `tests/record-review-loose-ends.test.sh` are in `Owns` but need no change.

## Open questions
- Exact wording of the new messages: a plan detail (no test pins them beyond the three forbidden phrases).

## Complexity
Story 2 → 2. Code change is small (one method, one signature, one deletion); the weight is in tests, and the oracle already shows each one bites.

## Split
Not needed.
