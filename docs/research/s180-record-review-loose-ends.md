# Research — s180-record-review-loose-ends

[Story](../stories.md)

## Structuring facts
- Root cause 1 (the finding of d-0022, text kept off the repository by ADR-0123): `prepare()` at `po/src/record/security.rs:149-153` and `write_private()` at `po/src/record/security.rs:228-233`, as the private file named by `po inbox d-0022` describes. Input: a marked answer with the fixture of `test_security_finding_of_d_0022_is_closed`. Proof: today the run ends on `sensitive-context-in-repo` (`po/src/inbox/add.rs:48`) instead of `private-folder-unusable`.
- Root cause 2: `po/src/record/mod.rs:268-274` — when the rewrite of the count line fails after `keep()` posted a decision, `po` replies `written: false` and does nothing to the review, which keeps its block and the provisional line written at `mod.rs:250`. Proof: oracle output `{"error":"unwritable",…,"written":false}` with the review on disk.
- Root cause 3 is a missing test, not wrong code: the rollback at `mod.rs:260-265` works (the oracle test passes today), and no test holds it (review of s178, loop 1, bite at `mod.rs:261-264` left 13/13 green).
- Smaller lie of the same shape: `mod.rs:261` drops the result of the rollback (`let _ =`) and replies `written: false` even if the restore failed.
- No error code is new: `private-folder-unusable` (`security.rs:160`, `:210`) and `unwritable` (`mod.rs:251`, `:271`) exist; `docs/interface-agent.md:265` and `method/` do not change. The fix applies the rules of ADR-0123 on `Private folder` (`docs/decisions/ADR-0123-*.md:60-63`), it changes none.

## Story
Close the three findings the review of s178 left open in `po record review`, one version of `po` (0.3.0 → 0.3.1). Criteria: `security_finding_of_d_0022_is_closed`, `failed_keep_rolls_the_review_back`, `reply_is_true_when_the_last_write_fails`, `version_goes_up` (story `docs/stories.md:2886-2901`).

## Diagnostic
Reproduced by running the oracle (`tests/record-review-loose-ends.oracle.test.sh`, written by this stage) on the code as it stands, built into `/tmp/s180-plan-target` (nothing built inside the worktree): 1 passed (`failed_keep_rolls_the_review_back`), 3 failed:
- `security_finding_of_d_0022_is_closed` → `"error":"sensitive-context-in-repo"`.
- `reply_is_true_when_the_last_write_fails` → `the review is on disk but the reply says written false`; message `… Is a directory (os error 21); the security findings wait in decision d-0001`.
- `version_goes_up` → `po's version 0.3.0 is not above 0.3.0`.

Hypotheses, one per defect:
- H1 (finding of d-0022): the cause is the one its private file states, at `security.rs:151`. Refuted if the oracle's fixture were refused `private-folder-unusable`. It is not → **kept**.
- H2 (last write): the branch at `mod.rs:268` has no rollback. Refuted if the review were absent after the failure. It is present with `written: false` → **kept**.
- H3 (rollback untested): the rollback at `mod.rs:261-264` is broken. Refuted if the oracle's two rollback cases pass on today's code. They pass → **discarded**; the defect is the missing test only.

## Current code
- `po record review` order (`mod.rs:143-304`): parse, worktree, version, template, stdin; `security::split` (`:191`); `security::prepare()` when there are marked findings (`:205-210`, refusal `written: false`, nothing written); oracle gate (`:212`); `existing` read (`:226-229`); first `write_atomic` with `Security findings: <n> — none kept, this answer fails findings-shape` (`:249-252`); `findings-shape` gate (`:253`); `security::keep` unless the gate exited 1 (`:256-266`); final `write_atomic` with `— decision <id>` (`:268-275`); reply (`:280-303`).
- `write_atomic` (`mod.rs:308-317`): temp file `.<name>.po-record.<pid>` beside the report, then `rename`.
- `security::prepare` (`security.rs:149-153`) → `Keeper { project, inbox_dir, folder }`; `folder = private_folder(&project)?.join(project.name())`.
- `security::keep` (`security.rs:157-194`): `write_private` then `inbox::post_decision`; on a post refusal, removes the private file (`:190`).
- `private_folder` (`security.rs:198-226`): setting read, `~/` expansion, absolute check, `inbox::place(..) != Place::Outside` → `private-folder-unusable` (`:222-224`).
- `write_private` (`security.rs:228-240`): `DirBuilder` 0700 recursive (`:230`), file `create_new` 0600 (`:233`).
- `inbox::place` (`po/src/inbox/add.rs:118-144`): lexical check under the root, then the nearest existing ancestor canonicalised and its git common dir compared; re-exported `po/src/inbox/mod.rs:16`.
- `gate::run` (`po/src/record/gate.rs:17-23`): `bash <worktree>/.polype/hooks/po-gate.sh <name> <id>`, cwd the worktree; bash is po's direct child.

## Attachment points
- `security.rs`: `prepare()` and `write_private()` (the two places the finding of d-0022 names).
- `mod.rs`: the two failure branches after the first write (`:260-265`, `:268-274`).
- Version: `po/Cargo.toml:3`, `po/Cargo.lock:165` (package `po`), `bin/polype:27` (`POLYPE_VERSION`).

## Verified interfaces
- `pub(crate) fn place(project: &Project, path: &Path) -> Place` — `po/src/inbox/add.rs:118`; `Place::{Outside, InRoot(PathBuf), Elsewhere}` `:107-113`.
- `Project::name(&self) -> String` — `po/src/project.rs:73-78` (basename of the main checkout's root).
- `fn write_atomic(path: &Path, text: &str) -> std::io::Result<()>` — `mod.rs:308`.
- `fn refuse(code: i32, error: &str, message: impl Into<String>, written: bool) -> i32` — `mod.rs:64`.
- `output::REFUSED` (exit 1), `output::UNREADABLE` (exit 2) as used at `security.rs:160`, `mod.rs:251`.
- Test helpers reused: `secure_fixture`, `answer`, `decisions`, `WITNESS`, `SECURE_FINDINGS` (`tests/security-findings-stay-private.oracle.test.sh:6-48`), `rec`, `fixture` (`tests/record-writes-reports.oracle.test.sh:14-62`); the project folder under `Private folder` is `$SCRATCH/private/project` (`tests/security-findings-stay-private.test.sh:77`).

## Traps
- `tests/run.sh:23` builds `cargo build --release --locked`: `po/Cargo.lock` must move with `po/Cargo.toml`, or the whole suite stops.
- Issue #254: `tests/readme-onboarding.test.sh:114` installs from a clone of the committed HEAD (`file://$ROOT`) and rebuilds `po` into the shared `CARGO_TARGET_DIR`: run the full suite on committed code only.
- No test pins `0.3.0`: `grep -rn '0\.3\.0' tests/` is empty. These read `POLYPE_VERSION` from `bin/polype` at run time: `tests/installer.test.sh:36`, `tests/po-prebuilt-and-verified.oracle.test.sh:27`, `tests/state-as-json.oracle.test.sh:15`, `tests/driver-next-action.oracle.test.sh:20`, `tests/project-lead.test.sh:103`, `tests/run-from-outside.test.sh:61`, `tests/run-from-outside.oracle.test.sh:92`.
- Tests outside `Owns` that touch the paths changed: `tests/security-findings-stay-private.oracle.test.sh` and `tests/record-writes-reports{,.oracle}.test.sh`. None pins the two failure branches nor the code of the d-0022 fix (no `unwritable`, `none kept` or `po-record.` in them); the s178 oracle's refusals concern the configured path, unchanged. `tests/security-findings-stay-private.test.sh` (in `Owns`) needs no change either.
- The oracle's trigger for the last write relies on two facts: `findings-shape` runs between the first write and `keep()` (`mod.rs:250-258`), and the temp name of `write_atomic` (`mod.rs:312`).
- Mode 0500 binds no one under root; the oracle swaps in a plain file there (see plan).
- `.polype/version` of this repository reads `0.2.0` and is not the story's: it is the installed method stamp, outside `Owns`.

## Open questions
- An existing review whose last write fails on a disk that then also refuses the restore: no write can remove the provisional line. The plan has the reply say `written: true` and name the line; the oracle tests the absent-review case of this branch only (the existing case of the shared rollback is held by `failed_keep_rolls_the_review_back`).
- The fix of d-0022 sits at the two places its finding names; each makes the oracle pass alone, and only the one in `prepare()` is reachable from outside.

## Complexity
Story 2 → 2 after reading: two files of `po/src/record/`, two refusal paths already in place, no new error code, no method or contract change.

## Split
—
