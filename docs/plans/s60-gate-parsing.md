---
validated: yes
---
# Plan — s60-gate-parsing

Branch `story/s60-gate-parsing`. Read `docs/research/s60-gate-parsing.md` first; this plan builds on it without repeating it. Line numbers below are those of `method/hooks/po-gate.sh` before any edit.

## Story
`po-gate` refuses what it cannot read and sees what it missed, so that no gate opens because of a parse gap. Acceptance criteria, each one a test function of the same name:
1. `floor_guard_flags_a_test_renamed_out_of_the_test_tree`
2. `floor_guard_says_2_on_an_unreadable_diff`
3. `secret_scan_finds_a_pem_key_after_an_escaped_newline`
4. `verif_current_refuses_a_malformed_checks_row`
5. `qa_current_requires_a_committed_report`

## Tasks
1. [x] **Rename out of the test tree = deleted test** (floor guard, awk `BEGIN`, next to the `^D\t` loop at :336). For each `FLOOR_STATUS` line matching `^R[0-9]*\t`, split on tab into `old` and `new`. When `is_test(old)` and either `!is_test(new)`, or `ext(old) != ext(new)` and no `FLOOR_PATTERNS` extension list (field 1, already parsed into `pext[]`) contains both extensions, print `flag(old, 0, "test-file-deleted", "renamed to " new)`. `ext()` is the text after the last dot of the basename, empty without a dot, computed the way `open_file` does at :319-320. An old extension in no list (`.sh`, `.rb`…) means any extension change is flagged. Update the guard's header comment (:13-14) only if its wording no longer holds.
   Test that fails if wrong: `test_floor_guard_flags_a_test_renamed_out_of_the_test_tree` in `tests/floor-guard.test.sh`. In `floor_repo`, commit `tests/a.test.ts`, `src/b.test.ts`, `spec/c.spec.js`, then on `story/s01-a` run `git mv tests/a.test.ts attic/a.ts`, `git mv src/b.test.ts src/b.test.ts.off`, `git mv spec/c.spec.js spec/c.spec.ts`. Expect exit 1, `flagged 'tests/a.test.ts:0: test-file-deleted: renamed to attic/a.ts'`, `flagged 'src/b.test.ts:0: test-file-deleted: renamed to src/b.test.ts.off'`, `not_flagged 'spec/c.spec'`.
2. [x] **Exit 2 on an unreadable diff is tested** (no change to `po-gate.sh`; the rule at :338-344, :354, :364, :378-379 already holds, as the research reproduced). Add `test_floor_guard_says_2_on_an_unreadable_diff` to `tests/floor-guard.test.sh`. Resolve `real_git="$(command -v git)"` first, then write an executable `git` shim into a directory under `$SCRATCH/.git/` that runs the real git and, only when its arguments contain `-U0`, rewrites the output. Two cases in one test:
   (a) every `@@ … @@` header rewritten to `@@ -1 +1,9 @@`, so a hunk announces lines it does not have;
   (b) the whole `-U0` output replaced by one line `garbage`.
   Each case: `PATH="$shim_dir:$PATH" guard s01-a main` on a story that adds one plain `src/a.ts` line, then assert exit 2, empty stdout, and `cannot verify the floor of` in `guard.err`. All other git calls (`rev-parse`, `merge-base`, `--name-status`) go through untouched. Neutralising the `exit 3` of :364, or both `rc` checks of :378-379, must turn this test red.
3. [x] **PEM key after a literal `\n`** (`hit()` :167-176). The left boundary applies only when the match itself starts with a word character: a match is dropped only if both its first character and the character before it are in `[A-Za-z0-9_]`. A PEM header starts with `-` and so is never dropped; every token row (`AKIA`, `ghp_`, `sk_live_`, `sk-ant-`) starts with a letter and keeps the boundary. Rewrite the table comment at :133-135 to say exactly that. The table keeps its three fields (ADR-0028). No rule name is tested in awk.
   Test: `test_secret_scan_finds_a_pem_key_after_an_escaped_newline` in `tests/gate.test.sh`. Stage `src/tls.json` holding one line `"tls": "<five dashes>END CERTIFICATE<five dashes>\n<five dashes>BEGIN PRIV""ATE KEY<five dashes>\nMIIE"` with a literal backslash-n, header assembled at run time. Then `refused_naming 'src/tls.json:1: private-key' 'a PEM key after \n'`. The existing `desk_live_` near-miss in `test_pre_commit_refuses_obvious_keys` (:206-207) proves the boundary still holds for token rows; it must stay green, untouched.
4. [x] **Malformed `## Checks` row refuses the record** (`record_rows` :71-95, `runs_cover_checks` :99-115). In the `## Checks` section only:
   - row 1 (the header) is skipped as today;
   - row 2 is skipped when every one of its cells matches `^[[:space:]]*:?-+:?[[:space:]]*$` (a separator), whatever its cell count;
   - every other row is malformed when it has `n < 3` cells, or when its trimmed first cell matches `^:?-+`.
   A malformed row is printed `E\037<NR>\037<the row as written>`. `runs_cover_checks` scans the rows before the `C` loop and, on the first `E`, refuses with `the Checks table of the verification record of <id> has a row it cannot read (line <NR>): <row> — rebuild it from templates/verification-record.md`. `## Runs` parsing (:82 for Runs, :89-93) behaves exactly as before: keep the old skip for Runs, branch only for Checks.
   Test: `test_verif_current_refuses_a_malformed_checks_row` in `tests/run-ledger.test.sh`, reusing `story_sandbox`, `seal`, `unit`. Case (a): a record whose `## Checks` is `| Check | Command |` / `| --- | --- |` / ``| Unit suite | `exit 0` |`` with `unit 0 'exit 0'` run, so the refusal can only come from the cell count. Case (b): the template's 3-column table with the row ``| -- Unit suite | `exit 0` | |`` and its matching run. Each case: `verif-current` exits non-zero and its stderr contains `has a row it cannot read` and the row's label text. A third check, `fresh_record; unit 0; seal; accepted`, guards against over-refusal on the template's own table.
5. [x] **`qa-current` requires a committed report** (`qa_current` :118-130, per ADR-0037). After `code_matches` passes, two last checks, both through `git -C "$(top)"`: `cat-file -e "HEAD:docs/qa/$1/report.md"` must succeed, and `status --porcelain --untracked-files=all --ignored -- "docs/qa/$1/"` must print nothing (a failing `status` also refuses). Otherwise refuse with `the QA report of <id> is current but docs/qa/<id>/ is not committed — commit it alone: git commit -m "<id>: QA evidence" -- docs/qa/<id>/ (/po-qa <id>)`. Update header comment :9 to say "committed".
   Test: `test_qa_current_requires_a_committed_report` in `tests/qa-gate.test.sh`. From `sandbox`, write a complete report bound to `HEAD^{tree}` without committing → refused, stderr names `not committed`; `git add` it → still refused; commit → passes; add an uncommitted `docs/qa/s01-a/capture-2.png` → refused.
   Same task, existing test changed: `test_qa_current_needs_a_full_tree_hash` (:51-60) commits each report it writes (`git add -A && git commit -qm …`), so its three refusals keep coming from the hash rule and not from the new one.
6. [x] **Full suite and record.** `bash tests/run.sh` through `po-run`, the verification record from `templates/verification-record.md`, commit.

## Run interdicts
- `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/skills/review-antihallu/SKILL.md`, `tests/qa-fleet.test.sh`: empty diff. The po-drive row 53 / line 62 correction belongs to s64 or a follow-up (research, first fact).
- `.claude/`, `.polype/`: empty diff (installed copies).
- `SECRET_PATTERNS` (:136-141): its rows unchanged, still three fields per row.
- `FLOOR_PATTERNS` and `FLOOR_TEST_PATHS` (:235-254): unchanged; the suffix rule is code, not a new path regex.
- No test file, plan or research holds five dashes followed by `BEGIN`, a key type and `PRIVATE KEY` as one literal: the repository's own pre-commit would refuse it.
- No production seam for tests: `po-gate.sh` gains no environment variable or flag to inject a diff; the exit-2 test goes through a `PATH` shim only.
- Existing tests unchanged except `test_qa_current_needs_a_full_tree_hash`, and only as task 5 says.
- `po-gate` exit codes stay 0/1/2 for `floor-guard`, 0/1 for the other gates.

## The pivot
The pivot is **what "a suffix the runner ignores" means** (task 1). The guard reads no runner configuration, so the plan defines it as "the extension changed, and the new one is not in the same `FLOOR_PATTERNS` language list as the old". Ways it could be wrong:
- **False positive:** a legitimate migration whose extensions sit in no shared list (`a.test.sh` → `a.test.bash`) gets flagged. A planned migration is justified in its plan, so it costs a minor finding. Compare against the review skill's grading: a deleted test the plan justifies → minor.
- **False negative:** a rename inside one list that the runner does skip (`a.test.ts` → `a.test.cts` under a config matching only `*.test.ts`) passes. The review's own reading of the `R` lines still sees it.
- **Collision with existing behaviour:** `spec/moved.spec.ts → spec/renamed.spec.ts` (`tests/floor-guard.test.sh:95,104`) must stay unflagged; the new test's `spec/c.spec.js → spec/c.spec.ts` checks the same-list case.

Second-order decisions a reviewer should check:
- **PEM** (task 3): "first character of the match is a word character" stands in for "the private-key row alone". Today they are equivalent (only `private-key` starts with `-`). A future row starting with a symbol would also skip the boundary, which is right, since nothing can be the tail of an identifier there. Compare with the story note "l'exception porte sur la ligne private-key seule".
- **QA** (task 5): the ignored-files clause. A project ignoring `docs/qa/` gets refused every time (ADR-0037, Neutral), which is the intent.

## Files touched
- `method/hooks/po-gate.sh`
- `tests/floor-guard.test.sh`, `tests/gate.test.sh`, `tests/run-ledger.test.sh`, `tests/qa-gate.test.sh`
- `docs/research/s60-gate-parsing.md`, `docs/plans/s60-gate-parsing.md`, `docs/verif/s60-gate-parsing.md`
- `docs/decisions/ADR-0037-qa-current-exige-une-preuve-qa-committee.md` (written at planning, outside `Owns`; Law 6 requires it)

## Test strategy
Every rule lives in `po-gate.sh`, and every test runs the real script on a scratch repository, the layer the existing gate tests use. No test reads the script's text. Five new tests, one existing test adjusted; budget 25.

| Test | Rule it proves | Would fail if… |
| --- | --- | --- |
| `floor_guard_flags_a_test_renamed_out_of_the_test_tree` | rename out of tree / to an ignored suffix = deleted; same-list rename silent | the `R` loop is removed, or the extension clause is dropped or inverted |
| `floor_guard_says_2_on_an_unreadable_diff` | unreadable diff → 2 | `bad`, the `exit 3`, or the `rc` mapping is neutralised |
| `secret_scan_finds_a_pem_key_after_an_escaped_newline` | PEM ignores the left boundary | the boundary is applied unconditionally again |
| `verif_current_refuses_a_malformed_checks_row` | short row and dash label refuse, naming the row | the `n < 3` or the label clause is removed (cases a, b separately) |
| `qa_current_requires_a_committed_report` | report and captures must be in `HEAD` | the `cat-file` or the `status` check is removed |
| `qa_current_needs_a_full_tree_hash` (changed) | hash rules, now on committed reports | the hash checks are removed |

The `git` shim of task 2 forges input only; the detection under test is the guard's own awk (doctrine, false test 6, does not apply: the shim does not evaluate the condition). No visual check: nothing has a screen.

## Done when
- The five criteria pass, and `bash tests/run.sh` is green through `po-run`, with `docs/verif/s60-gate-parsing.md` complete and current.
- One commit on `story/s60-gate-parsing` carrying code, tests, research, plan, record and ADR-0037.
- The review has no open critical finding. The final report names the po-drive row 53 / line 62 follow-up for s64.
