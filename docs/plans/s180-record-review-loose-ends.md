---
validated: yes
---
# Plan — s180-record-review-loose-ends

[Story](../stories.md) · [Research](../research/s180-record-review-loose-ends.md)

Branch `story/s180-record-review-loose-ends`. Read `docs/research/s180-record-review-loose-ends.md` first; this plan builds on it without repeating it. The finding of d-0022 is read with `~/.claude/polype/po inbox d-0022` from the repository root, then the file its `context` names. Its text goes into no file of the repository, no test name and no commit message: say "the finding of d-0022".

## Story
`po record review` closes the three findings the review of s178 left open (loop 1), in one version of `po`.
- `security_finding_of_d_0022_is_closed` — fixed as its text proposes; refused before any write, naming `private-folder-unusable`.
- `failed_keep_rolls_the_review_back` — the review back to its bytes, or absent; `written: false`, no decision, the text nowhere; tested for an absent and an existing review.
- `reply_is_true_when_the_last_write_fails` — `written` true of the disk, no provisional `none kept` line, the decision kept and named.
- `version_goes_up` — 0.3.0 → 0.3.1 in `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| The check of the d-0022 fix | already here: `inbox::place` (`po/src/inbox/add.rs:118`, re-exported `po/src/inbox/mod.rs:16`) and the `unusable` refusal of `security.rs:209-211`, `:160` | — |
| One rollback used by both failure branches | already here: the restore/remove of `po/src/record/mod.rs:261-264`, moved into a small function over `write_atomic` (`mod.rs:308`) and `std::fs::remove_file` | — |
| Version bump | no code | — |

## Acceptance tests
Every criterion is something a script reads (the reply of `po`, the disk, the inbox, three version lines): all four have an oracle test; none is judged in review and none is a `po-eval` candidate.

| Oracle file | cksum |
| --- | --- |
| `tests/record-review-loose-ends.oracle.test.sh` | `3899006989 5550` |

| Criterion | Test |
| --- | --- |
| `security_finding_of_d_0022_is_closed` | `test_security_finding_of_d_0022_is_closed` — the fixture the finding names, a marked answer; exit 1, `private-folder-unusable`, `written: false`, no review, no decision, the witness nowhere, nothing under the folder the fixture points at. Root-proof: it rests on no file mode. |
| `failed_keep_rolls_the_review_back` | `test_failed_keep_rolls_the_review_back` — the project folder under `Private folder` (`$SCRATCH/private/project`) at mode 0500, the reviewer's own probe; once with no review (absent after), once after an unmarked review was recorded (`cmp` byte-identical). **Under root**, where 0500 binds nothing, the test puts a plain file at that path instead (`id -u` = 0): the folder creation of `write_private` then fails for every user, the same failure branch is reached and the same assertions run. It never skips. |
| `reply_is_true_when_the_last_write_fails` | `test_reply_is_true_when_the_last_write_fails` — see "How the last write is made to fail" below. Absent review: reply `unwritable`, non-zero exit, `written` matches whether the review exists, no `none kept` line if it does, one decision, pending, its id in the message. |
| `version_goes_up` | `test_version_goes_up` — the three version lines agree and sort above 0.3.0 (`sort -V`); no literal `0.3.1`, so the next bump does not break it. |

**How the last write is made to fail — no seam in `po`.** `findings-shape` runs after the first write and before `keep()` (`mod.rs:250-258`), from the worktree's own `.polype/hooks/po-gate.sh` (`po/src/record/gate.rs:13-23`), with `po` as bash's direct parent. The test wraps that hook in its fixture: on `findings-shape` it creates a folder named like the next temp file of `write_atomic` (`docs/reviews/.<id>.md.po-record.$PPID`, `mod.rs:312`), then runs the real gate. The rewrite of the count line then fails with `EISDIR` for any user, root included, while removing a new review still works. Nothing is added to `po`: no environment variable, no feature, no `cfg`, so no normal run can reach a weakened path. The hook is a file of the worktree that anyone able to run `po record` there can already edit, so the fixture uses no power a real caller lacks.

Ran on the code as it stands (built in `/tmp`): `failed_keep_rolls_the_review_back` passes (the rollback works, only its test was missing), the three others fail as the research records.

## Tasks
1. [x] **Fix of d-0022** in `po/src/record/security.rs`, as the text of the finding proposes, at the two places it names: in `prepare()` (`:149-153`), so the refusal comes before the review is written; and in `write_private()` (`:228-233`), between the folder creation and the opening of the file, so a folder that appears in between is refused too. The refusal is the existing `private-folder-unusable`, exit `output::REFUSED`, its message naming the setting like `security.rs:210`. `write_private` gets what the check needs (the `Project`) from `keep()`, its only caller. Update the doc comment of `keep()` (`:155-156`) only if it turns false. Test: `test_security_finding_of_d_0022_is_closed`.
2. [x] **One rollback, truthful replies** in `po/src/record/mod.rs`: move the restore/remove of `:261-264` into a function `roll_back(path, existing) -> bool` (restore `existing` through `write_atomic`, or `remove_file` when there was none; `true` when it succeeded). The `keep()` failure branch (`:260-265`) replies `written: !rolled_back` instead of always `false`. The last-write branch (`:268-274`) calls it too, keeps error `unwritable` and exit `output::UNREADABLE`, still names `decision {posted}` in its message, and replies `written: !rolled_back`; when the rollback fails, the message also says the review still holds the provisional count line. Update the comment at `:247-248` only if it turns false. Tests: `test_failed_keep_rolls_the_review_back` (both cases go through the shared function), `test_reply_is_true_when_the_last_write_fails`.
3. [x] **Version 0.3.1** in `po/Cargo.toml:3`, the `po` package of `po/Cargo.lock:165` and `POLYPE_VERSION` at `bin/polype:27`, together. Check `cargo build --release --locked --manifest-path po/Cargo.toml` passes (the suite builds `--locked`, `tests/run.sh:23`). Test: `test_version_goes_up`.
4. [x] **Focused run** after tasks 1-3, without `po-run`: `bash tests/run.sh record-review-loose-ends.oracle.test.sh security-findings-stay-private.oracle.test.sh security-findings-stay-private.test.sh record-writes-reports.oracle.test.sh record-writes-reports.test.sh`. All green; no s178 or s167 test changes.
5. [x] **Full suite, around issue #254.** `tests/readme-onboarding.test.sh` clones the committed HEAD and rebuilds `po` into the suite's shared `CARGO_TARGET_DIR`. So: commit the story first (code, oracle, research, plan; message in English, no text of d-0022), then `po-run --story s180-record-review-loose-ends --label suite -- 'bash tests/run.sh'` on that committed code, then `git commit --amend` adding only `docs/verif/s180-record-review-loose-ends.md` (the code tree does not move, so the record's `Tree:` holds). Typecheck: `—`.

## Scene viewpoints
—

## Run interdicts
- Empty diff for `method/`, `.polype/`, `.claude/`, `docs/interface-agent.md`, `docs/decisions/` (ADR-0123 included) and every test file outside `Owns`, notably `tests/security-findings-stay-private.oracle.test.sh` and `tests/record-writes-reports{,.oracle}.test.sh`.
- No new error code in `po`: only `private-folder-unusable` and `unwritable`, which exist. A fix that seems to need one stops and says so (the contract is outside `Owns`).
- No test seam in `po`: no environment variable, cargo feature, `cfg` or hidden option added for a test (`git diff main...story/s180-record-review-loose-ends -- po/` holds none).
- The temp name of `write_atomic` (`.<name>.po-record.<pid>` beside the report, `mod.rs:312`) and the order first write → `findings-shape` → `keep()` → last write stay as they are: the oracle's trigger relies on both.
- The text of the finding of d-0022 appears in no file of the repository, no test name, no comment, no commit message (`grep` of the diff and `git log` for any phrase of the private file finds nothing).
- `tests/record-review-loose-ends.test.sh` is created only if it holds at least one test; none is expected.
- The installed `~/.claude/polype/po` and the private file of d-0022 are not touched; nothing is built into `po/target` of the main checkout by hand.

## The pivot
The last-write criterion rests on a trigger from outside: the fixture's gate hook, which runs between the two writes, blocks the temp name of the next write. Ways it could be wrong:
- **Reordering or renaming in `mod.rs`.** If the gate moved after `keep()`, or `write_atomic` changed its temp name, the trigger would stop firing and the test would fail for a reason unrelated to the criterion. Compare `mod.rs:250-268` and `:312` with the run interdict above.
- **The existing-review case of this branch is not tested.** The trigger also blocks the restore, which goes through `write_atomic`: on such a disk the rollback fails, `po` must reply `written: true`, and the provisional line cannot be removed by any write. The shared `roll_back` is held for an existing review by `test_failed_keep_rolls_the_review_back`; the reviewer should read the last-write branch's use of its result.
- **The d-0022 fix sits at two places, and each alone passes its test.** A bite on one of them stays green; the reviewer neutralises both together, then each alone and reads the remaining one.

## Files touched
`po/src/record/security.rs`, `po/src/record/mod.rs`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `tests/record-review-loose-ends.oracle.test.sh` (written by this stage), `docs/research/s180-record-review-loose-ends.md`, `docs/plans/s180-record-review-loose-ends.md`, `docs/verif/s180-record-review-loose-ends.md`.

## Test strategy
- Layer: the command `po record review` end to end in a scratch project (the s167/s178 fixture), the only layer where the reply, the disk and the inbox are seen together. Real filesystem, real gate script, real inbox: no mock.
- Automated: the 4 oracle tests, within `Test budget` 25. No other test: the doc-comment edits are judged by reading.
- Root: tests 1 and 3 rest on no file mode; test 2 swaps the 0500 folder for a plain file under root and keeps all its assertions.
- No test pins `0.3.0` (`grep -rn '0\.3\.0' tests/` is empty); the seven tests that read `POLYPE_VERSION` at run time (research, Traps) follow the bump.
- Visual checks: none.

## Done when
One commit on `story/s180-record-review-loose-ends` holding the code, the oracle, the research, the plan and the record, with the full suite green through `po-run` on that code; a review with no open critical finding, which says the finding of d-0022 is closed without describing it; landed as `s180-record-review-loose-ends: <story title>` through a pull request.
