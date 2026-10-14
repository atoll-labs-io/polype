# Research — s60-gate-parsing

[Story](../stories.md)

## Structuring facts
- **False assumption — `Owns` is not enough for AC5.** `po-drive`'s resume table relies on `qa-current` passing an uncommitted current report: row "`po-gate qa-current <id>` passes and `git … status --porcelain -- docs/qa/<id>/` lists the report → the evidence commit of `/po-qa`, without a new walk" (`method/commands/po-drive.md:53`), and the paragraph "It reads the working tree, so a current report left uncommitted passes it" (`method/commands/po-drive.md:62`). Once AC5 lands, row 53 can never match and row 52 (`qa-current` fails → the QA stage) sends such a lane to a new walk. `po-drive.md` and `tests/qa-fleet.test.sh:81` (which quotes row 53) belong to s64-qa-routing (`docs/stories.md:988`), not s60. Correction needed in the story set: s64 (or a follow-up) rewrites row 53 and line 62; s60 stays inside its `Owns`.
- AC5 reverses the "Neutral" consequence of an accepted ADR: "`qa-current` n'exige pas que le rapport soit committé" (`docs/decisions/ADR-0029-po-qa-committe-les-preuves-qa.md`, Consequences). It needs a new ADR (ADR-0037 reserved), which does not supersede ADR-0029's decision itself.
- ADR-0028 fixes the secret table's shape as `<règle>|<longueur minimale>|<ERE>` (`docs/decisions/ADR-0028-…md:19`): the PEM fix must not add a column.
- All five defects are reproduced on scratch repos against the current `method/hooks/po-gate.sh` (see "Current code"); AC2's rule already works, it only lacks a test.
- The review line numbers quoted by the story (s48 review `:182`, `:210`, `:224-225`) are stale: the same code now sits at `po-gate.sh:336`, `:364`, `:378-379`.

## Story
`po-gate` must refuse what it cannot read and see what it missed. Criteria (each is a test function name):
1. `floor_guard_flags_a_test_renamed_out_of_the_test_tree` — a test file renamed out of the test tree, or to a suffix the runner ignores, is flagged as a deleted test.
2. `floor_guard_says_2_on_an_unreadable_diff` — an unreadable diff gives exit 2; neutralising that rule makes a test fail.
3. `secret_scan_finds_a_pem_key_after_an_escaped_newline` — a PEM key following a literal `\n` inside a one-line string is refused.
4. `verif_current_refuses_a_malformed_checks_row` — a `## Checks` row without its three cells, or whose label looks like a separator, makes the record refused, naming the row.
5. `qa_current_requires_a_committed_report` — `po-gate qa-current` refuses a current but uncommitted QA report.

## Current code
`method/hooks/po-gate.sh` (395 lines, `set -euo pipefail` at :18), one dispatcher `case` at :387-395.
- **Floor guard** `floor_guard` :259-385. Name-status computed at :273 with `--find-renames`; passed to awk as `FLOOR_STATUS` :276. Only `^D\t` lines whose path `is_test` are flagged `test-file-deleted` (:336). A rename prints `R100\t<old>\t<new>` (verified), so it is never flagged. Assertion counting (:304, :316) keys on `testfile = is_test(<new path>)` (:325), so a test moved to a non-test path loses its assertions silently. Reproduced: `git mv tests/a.test.ts attic/a.ts` and `git mv src/b.test.ts src/b.test.ts.off` → exit 0, no output. The second rename stays a "test path" because `FLOOR_TEST_PATHS` row 2 `(^|/)[^/]*\.(test|spec)\.[^/]*$` (:252) matches `b.test.ts.off`.
- **Unreadable diff**: awk sets `bad` when a hunk's announced counts disagree with its lines (:338-344, :354) and exits 3 at :364 (also when input has no `diff --git a/` block and no `+++` header). Shell maps rc 3 → `unverifiable` (exit 2) at :378, any other non-zero rc → exit 2 at :379. Tests cover exit 2 only for argument/ref errors (`tests/floor-guard.test.sh:38-44`). Reproduced: a `git` shim on `PATH` that rewrites every `@@ … @@` of the `-U0` diff to `@@ -1 +1,9 @@` → exit 2, stderr "is in a format this guard cannot read".
- **Secret scan** `secret_scan` :144-208, table `SECRET_PATTERNS` :136-141 (`<rule>|<min length>|<ERE>`, comment :133-135). `hit()` :167-176 rejects a match whose preceding character is `[A-Za-z0-9_]` (:171). In `…-----\n-----BEGIN …` the char before the match is the `n` of the literal `\n`. Reproduced: exit 0 on a staged one-line JSON string holding a cert then a key.
- **Record parse** `record_rows` :71-95, `runs_cover_checks` :99-115, called from `verif_current` :66. In `## Checks`, a row is used only when `n >= 3` (:84); shorter rows fall through silently. Line :82 skips row 1 and any row whose trimmed content starts with `:?-+`, so a label like `-- Unit suite` is skipped as a separator. Reproduced: a 2-column `| Check | Command |` table with an empty `## Runs`, and a 3-column row labelled `-- Unit suite`, both → `verif-current` exit 0.
- **QA gate** `qa_current` :118-130 reads `docs/qa/<id>/report.md` from the working tree, checks the last `QA status:`, `Tree:` hash, tree existence and `code_matches`. Nothing checks git's view of the file.

## Attachment points
- Rename flag: the awk `BEGIN` of the floor guard, next to the `^D\t` loop (:335-336). `is_test` (:279) and the extension lists of `FLOOR_PATTERNS` (:235-248, field 1) are already loaded there.
- Exit-2 test: `tests/floor-guard.test.sh` helpers `floor_repo` :6-15, `guard` :19 (stderr in `$SCRATCH/.git/guard.err`), `flagged`/`not_flagged` :20-21.
- PEM: `hit()` :167-176 only.
- Malformed row: `record_rows` :78-88 emits rows; `runs_cover_checks` :101-114 refuses. The record template's table is 3 columns (`method/templates/verification-record.md`, `## Checks`); `evals/lib.sh:229-233` writes 3 columns too.
- QA: the end of `qa_current` :128-129, plus the header comment :9.

## Verified interfaces
- `refuse()` :21 prints `po-gate: <msg>` on stderr and returns 1; callers chain `|| return 1`.
- `top()` :20 = `git rev-parse --show-toplevel`; every git call in gates uses `git -C "$(top)"`.
- `unverifiable()` :256 prints on stderr and `exit 2`.
- Floor flag format `<path>:<line>: <rule>: <detail>` via awk `flag()` :278; deleted files use line `0` (:336).
- `record_rows` output fields separated by `\037`; `C` rows `C,label,command`, `R` rows `R,label,command,exit,tree`. `record_rows` has no other caller (grep over `bin/ evals/ tests/ method/`).
- Test harness: `tests/run.sh` runs each `test_*` in its own `bash -c "set -eu; …"`; `scratch_repo` (`tests/lib.sh:46-53`) exports `GIT_CONFIG_GLOBAL=/dev/null`. Existing helpers: `tests/gate.test.sh` `sandbox` :6-12, `refused_naming` :171-176, `passes` :15; `tests/run-ledger.test.sh` `story_sandbox` :8-15, `fresh_record` :77-81, `seal` :82-86, `unit` :88, `accepted` :87; `tests/qa-gate.test.sh` `sandbox` :13-19, `qa_report` :24-27 (commits).
- `qa-current` callers: `method/skills/review-antihallu/SKILL.md:27` (any failure → review blocked, `Next action: /po-qa <id>`), `method/templates/review.md:24`, `method/commands/po-status.md:29`, `method/commands/po-drive.md:52-53,62`.

## Traps
- **The repository's own pre-commit runs the secret scan** on every commit (`tests/gate.test.sh:220-227` installs it the same way). A test, the research or the plan holding five dashes then `BEGIN … PRIVATE KEY` literally would be refused at commit: assemble the header at run time as `tests/gate.test.sh:201` does (`"PRIV""ATE"`).
- `tests/qa-gate.test.sh:51-60` writes reports **without committing** and expects refusals for hash defects; after AC5 those refusals would come from the new rule, so the hash assertions would stop proving anything. That test must commit each report (an existing test changed because the story changes the clause around it).
- `tests/floor-guard.test.sh:95,104` renames `spec/moved.spec.ts → spec/renamed.spec.ts` and asserts `not_flagged 'spec/'`: a rename inside the test paths with the same extension must stay silent.
- `tests/run-ledger.test.sh:112-116` relies on a `—` command row being skipped and on a record without `## Checks` being refused (that refusal lives at :64-65 in `verif_current`, not in `record_rows`).
- The `## Runs` parse shares line :82 with `## Checks`; changing the separator test for Checks must leave Runs parsing as is (`po-run` writes Runs rows, `tests/run-ledger.test.sh:32-58`).
- `tests/run-ledger.test.sh:127-138` builds an eval repo whose record (`evals/lib.sh:229-233`) must still pass `verif-current`: 3 columns, fine.
- s67-record-text depends on s60 and also owns `po-gate.sh` and `tests/run-ledger.test.sh` (`docs/stories.md:1023-1028`); it ships after s60, no conflict now.
- No migration, no screen, no new dependency, no API beyond `po-gate`'s CLI, whose exit codes stay 0/1/2.
- A test that runs the guard under a `git` shim must resolve the real `git` before changing `PATH`, and scope `PATH` to the guard call only.

## Open questions
- What counts as "a suffix the runner ignores"? No runner config is read by the guard. The plan has to fix a rule from what the guard knows: the extension lists of `FLOOR_PATTERNS`.
- PEM exception: special-case the rule name `private-key`, or apply the left boundary only to matches starting with a word character (equivalent on today's table, no column added, ADR-0028 intact)? The plan decides.
- AC5: is "committed" the report alone, or the whole `docs/qa/<id>/` (captures included)? `/po-qa` commits the directory (`method/commands/po-qa.md:43`). And should a report hidden by `.gitignore` count as uncommitted?
- Should a `## Checks` table with no data row at all be refused? Not asked; a `—`-only table already passes by design (`tests/run-ledger.test.sh:112-113`).
- Quoted paths in name-status (tabs or newlines in a name) keep their quotes, so `is_test` misreads them; true for the existing `D` rule too. Out of scope.

## Complexity
Story: 3. After reading: 3. Five small, independent fixes in one script with tests already shaped for them; the only cross-file effect (po-drive row 53) is reported, not changed here.

## Split
Not needed.
