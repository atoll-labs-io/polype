# Review — s204-framing-and-installer-phrase-tests-retired

[Story](../stories.md) · [Plan](../plans/s204-framing-and-installer-phrase-tests-retired.md) · [Verification](../verif/s204-framing-and-installer-phrase-tests-retired.md)

Method version: 0.11.0
Recorded: 2026-11-22T19:56:53+01:00

Diff reviewed: `git diff main...story/s204-framing-and-installer-phrase-tests-retired`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: ee704e0783e12a304c4f6099bb09e05822f5b1a6

## Ownership
Diff listed with `git diff --name-only main...story/s204-framing-and-installer-phrase-tests-retired`, each path held against the story's `Owns` (`docs/stories.md:3336`).
- [x] Every path inside `Owns`. The 21 edited and 4 deleted test files, `docs/harnais.md` and the oracle are all listed, and so is `tests/flow.test.sh` (it joined `Owns` in bb07953). The plan and the record are this story's own evidence.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. s201–s203 have landed, and the base is main at bb07953.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` exits 0, so the record is reused. The unit suite exited 0 through `po-run` on tree 25eb9d3. The type check is `—`: the project has none. "Not proven here" was read: `po-lint` was run by hand, and so was floor-guard after the commit.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–5 are all present. I rebuilt each of the 21 edited files from `main` with `sed` and `diff`: the plan's ranges deleted, then its rewritten lines applied (seven headers, plus `conversational-framing:54`, `hooks-installer-docs-cleanup:51` and `run-ledger:155`). All 21 equal the story branch exactly. The plan's line numbers are those of 3c11c33, and `tests/` is identical between 3c11c33 and bb07953.
- [x] Run interdicts checked:
  - the diff is empty in `method/`, `po/`, `bin/`, `.github/` and `tests/routing-phrase-tests-retired.oracle.test.sh`;
  - no `*.test.sh` was created for the story;
  - no assertion was reworded outside the named lines;
  - nothing is left in /tmp.

## References
- [x] I opened the readers cited by sampled rows, and each holds what its row says:
  - `framing.rs:39-52,61-69,76-83` (`status:`, `Entry mode`, `Stories ready:`);
  - `lane.rs:20,39,90` (`Story track`, `Flow threshold`, `Design source` → ask);
  - `bin/polype:623-629`;
  - `po-lint:98-114` (settings) and `:125-160` (tools, `skills_of` stories-review → no Write);
  - `po-link-artifacts:15`;
  - `signals.rs:89`;
  - `po-gate.sh:47`.
- [x] Counts confirmed:
  - files: 171 → 168;
  - functions: the delta of −53 matches 727 → 674 (54 removed, 1 added). My grep-based count reads 735 → 682, because it counts differently from `declare -F`.

## Rules
- [x] d-0051: the nine H1–H9 of the plan match the nine rules s206's criterion names for s204 (`docs/stories.md:3377`, bb07953).
- [x] I did not report the d-0052 security keepers as readerless phrase tests. The one removed security rule I found is listed under Findings.

## Tests
- Oracle: `po-gate oracle-intact s204-framing-and-installer-phrase-tests-retired` → exit 0
- [x] Oracle: `po-gate oracle-intact` exits 0, and the oracle sources s201's helpers without changing them.
- [x] Floor: `po-gate floor-guard … main` exits 1 with exactly 4 `test-file-deleted` flags (`any-harness-docs`, `migration-doc`, `prd`, `stories`). Task 1 and `## Classification` justify all four, so they are graded minor below.
- [x] Bite, run on the oracle file alone, both mutations undone with `git checkout --` and checked with `git diff --exit-code`:
  - kept function: `test_brief_checks_before_writing_approved` renamed → 1 of 1 fails ("contract tests gone: brief.test.sh:…");
  - kept line: the `'refuse, sur toutes les branches'` line of `distribution-wiring` deleted → 1 of 1 fails.
- [x] Within `Test budget` (one test).
- [x] `## The pivot` weighed. `env_word_forks_none` checks the code shape of `po-bounds.sh`, which is fair to keep. The other three grep a script's comments or wording; see the minor finding below.
- [x] `no_phrase_test_is_left`: I sampled seven files of the outside list (`state-carries-session-lines.oracle`, `driver-next-action.oracle`, `inbox-guards-bite.oracle`, `po-change-needs-a-version.oracle`, `held-says-what-collides.oracle`, `ship-builds-the-landing-commit.oracle`, `artifact-links-backfill`). Every `docs/` or `README` mention in them is a fixture written into a throwaway repo; none is a phrase read from the method. The `docs/harnais.md` section follows task 4 and is true of the tree, except for the one rule named under Findings.

## Neighbours
- [x] No remaining test names a removed file or function. `routing-phrase-tests-retired.oracle` is unchanged.

## Lenses
Lenses run: none. Only `tests/` and `docs/` changed: no auth, migration, lockfile or server code.
- [x] No lens findings.

## Findings
Security findings: 2 — decision d-0054
- minor — docs/plans/s204-framing-and-installer-phrase-tests-retired.md:77 — The `distribution-wiring` row says "read by person". The removed `test_rules_point_at_the_installer` and `test_help_mentions_installation_and_status` read `method/AGENTS.md` and `po-help.md`, which a model reads, so they are **M**, not **P**.
- minor — docs/plans/s204-framing-and-installer-phrase-tests-retired.md:115 — Three of the four pivot tests (`no_squash` on `po-gate.sh`, and both `session_comment_*` on `po-session.sh`) launch nothing; they grep a script's comments. They are kept only because the launch count credits a mention as a launch. The plan and `docs/harnais.md` disclose this, but the counter, not the test, is what should change.
- minor — docs/plans/s204-framing-and-installer-phrase-tests-retired.md:124 — `po-gate floor-guard` flags 4 deleted test files: `any-harness-docs`, `migration-doc`, `prd` and `stories`. Task 1 and `## Classification` name each one with its reason, so each flag is minor.

## Not verified
- I did not rerun the full suite: `verif-current` passes. I ran only the oracle (clean, then under two mutations).
- I did not check `po-lint method` myself; the record says it was run by hand and not recorded.
- I sampled about ten classification rows and seven outside files, not all of them. A person could read the remaining rows of `## Classification` with the same security question.
- That a model still follows the framing prose whose tests were removed (H1–H9) is left to s206's real run.
- `README.md`/`docs/` path checks wait on #442.

Max severity: major
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-22T20:12:25+01:00

Diff reviewed: `git diff main...story/s204-framing-and-installer-phrase-tests-retired`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 38aa8476fdac7becd71e4465a74795b3bd2d3574

## Ownership
I listed the diff with `git diff --name-status main...story/s204-framing-and-installer-phrase-tests-retired`. It has 30 paths, the same set as in fix loop 0. The fix commit bf0b5be touches only five of them: the plan, the review, the oracle, `tests/distribution-wiring.test.sh` and `tests/hooks-installer-docs-cleanup.test.sh`.
- [x] Every path is inside `Owns`, or is this story's own evidence.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current` exits 0, so I reused the record. The last unit-suite run exited 0 on tree f901c090 through `po-run`. The project has no type check (`—`). I read "Not proven here": `po-lint` and floor-guard were run by hand.
- [x] `po-gate qa-current` is not required, because `QA stage: —`.
- [x] Counts as `tests/run.sh` loads them: 168 files and 675 functions. This matches the plan's corrected figures (53 removed, 1 added).

## Plan
- [x] I rebuilt both files the fix changed from `git show bb07953:<file>`, using exactly the plan's current ranges and rewritten lines. Both equal the story branch byte for byte (`diff` is empty):
  - `distribution-wiring`: `:2` rewritten, `:5,7-13,16-34,38-138,147-168` deleted;
  - `hooks-installer-docs-cleanup`: `:2` and `:51` rewritten, `:57,98-128` deleted. Base `:31` is no longer deleted.
- [x] The two restored lines match bb07953 word for word: `contains "$RULES" 'Never edit an installed file'` (base `:35`) and `contains "$METHOD/commands/po-setup.md" 'po-gate.sh pre-commit <base>'` (base `:31`).
  - Of `test_rules_point_at_the_installer`, only the function shell and that one line came back, plus `RULES` (base `:4`).
  - Nothing else from the removed functions came back: `HELP`, `MATRIX`, `tokens_of`, `status_of` and `polype_of` are all gone.
  - No unused name is left: `RULES`, `README` and `GATE` are each used.
  - The rewritten header of `distribution-wiring` is true of what the file now holds.
- [x] The plan's figures were updated to match the fix:
  - oracle cksum `3879645666 32911`, which equals the file's actual `cksum`;
  - `S204_KEPT_LINES` has 233 lines, matching the oracle file;
  - function counts 675 and 53;
  - the run-interdict sentence now names the two restored base lines.
- [x] Run interdicts: the diff is empty in `method/`, `po/`, `bin/`, `boilerplates/`, `.github/`, `tests/lib.sh`, `tests/run.sh`, `tests/journey/` and `tests/routing-phrase-tests-retired.oracle.test.sh`.

## Findings of fix loop 0
- The `distribution-wiring` classification row is closed. It now reads "model, person", with **M** for `method/AGENTS.md` and `po-help.md` and **P** for the matrix and README. Its removed ranges are correct: four functions (`help_mentions…`, `readme_describes_the_project…`, `parity_matrix…`, `parity_h04…`) plus the rest of `test_rules_point_at_the_installer`. The `hooks-installer-docs-cleanup` row no longer lists `:31` and names the **S** function. The "Kept as they are" list names both restored functions.
- The pivot finding was filed by the lead as issue 462 against the launch counter. It is not raised again here.
- The floor-guard finding still holds, as before (see Findings).
- The security findings recorded under decision d-0054 are lifted. Both restored assertions are back word for word, are named in the plan as **S** under d-0052, and are pinned by the oracle (see Tests).

## Tests
- Oracle: `po-gate oracle-intact s204-framing-and-installer-phrase-tests-retired` → exit 0
- Oracle: `po-gate oracle-intact s204-framing-and-installer-phrase-tests-retired` → exit 0
- [x] Oracle: `po-gate oracle-intact` exits 0. The oracle's change is declared in `## Oracle changes` of the record. It adds one kept function and two kept lines, so it strengthens `contract_tests_stay` and weakens nothing.
- [x] Floor: `po-gate floor-guard … main` exits 1 with the same 4 `test-file-deleted` flags as before. All four are justified by task 1.
- [x] Clean run of the oracle, `distribution-wiring` and `hooks-installer-docs-cleanup`: 9 passed, 0 failed.
- [x] Bite, run on the oracle file alone:
  - I removed both restored items: `test_rules_point_at_the_installer` and the restored `hooks-installer-docs-cleanup` line. `contract_tests_stay` fails, naming the function, its line and the hooks line.
  - I then put `distribution-wiring` back (`git checkout --`, `git diff --exit-code` clean) and reran. It still fails, naming only the hooks line, so each removal fails the oracle on its own.
  - I undid the second mutation and checked with `git diff --exit-code` and `git status --porcelain`: both clean.
- [x] Within `Test budget`: the oracle is the story's one test.

## Neighbours
- [x] `docs/harnais.md` was not touched by the fix, and its new section is still true:
  - The restored assertions fall under its d-0052 exception: "the other kept functions are named in the plans of s202 to s204 and pinned by their oracles", and this plan and this oracle now name and pin both.
  - "README.md and docs/ are no longer read by any test, apart from what security keeps" still holds. The only reader is the **S** function `test_readme_describes_the_pre_commit`.

## Lenses
Lenses run: none. Only `tests/` and `docs/` changed: no auth paths, migrations, lockfiles or server code.
- [x] No lens findings.

## Findings
- minor — docs/plans/s204-framing-and-installer-phrase-tests-retired.md:124 — `po-gate floor-guard` flags 4 deleted test files: `any-harness-docs`, `migration-doc`, `prd` and `stories`. Task 1 and `## Classification` name each one with its reason, so each flag is minor.

## Not verified
- I did not rerun the full suite, because `verif-current` passes. I ran only the oracle and the two files the fix changed, clean and then under the mutations above.
- I did not run `bin/po-lint method` myself. The record says it was run by hand and not recorded.
- I compared only the two files the fix changed against the base. The other 19 edited files are unchanged since fix loop 0, and that review rebuilt them; a person who wants full coverage can repeat the same `sed`/`diff` rebuild on them.
- I did not read the text of the d-0054 security findings (inbox and private folder are out of my reach). I judged the fix by what the lane describes and by the base, not against the findings' own wording. A person holding d-0054 should confirm the two restored lines are what it asked for.
- That a model still follows the framing prose whose tests were removed (H1–H9) is left to s206's real run. The `README.md`/`docs/` path checks wait on #442.

Max severity: minor
Ship allowed: yes
