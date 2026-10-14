# Review: s67-record-text

[Story](../stories.md) · [Plan](../plans/s67-record-text.md) · [Verification](../verif/s67-record-text.md)

Reviewed tree: 6883246c8cee99fc1c089393deca596f79a884a0
Fix loop: 0
Scope: `git diff main...story/s67-record-text`
Lenses run: none. No changed path names auth, routes, handlers, migrations, lockfiles or server code, and the diff has no content that triggers a lens.

## Scope (Owns)
Owns: `method/agents/implementer.md`, `method/hooks/po-gate.sh`, `tests/run-ledger.test.sh`, `tests/qa-gate.test.sh`.
- The 4 code and test paths are all inside `Owns`.
- `docs/plans/s67-record-text.md` and `docs/verif/s67-record-text.md` are the story's own evidence, so they are in scope by construction.
- `docs/decisions/ADR-0044-qa-current-ne-compte-plus-les-fichiers-ignores.md` is added (status `A`) and the plan names it, so it is in scope by construction.
- No path in the diff is outside scope.

## What I relied on
- `po-gate verif-current s67-record-text` exited 0. The setting is `Verification mode: record`, so I did not rerun the full suite. The record's `Unit suite` (`bash tests/run.sh`) exited 0 on code matching `Tree:`. Type check, E2E and Build are `—`: the project has none of them.
- The record's "Not proven here" says the installed copies under `.claude/` and `.polype/` are not refreshed by this story.
- No screen, so no QA was required.

## Steps
1. **Proven runs:** reused, as described above.
2. **References:** every reference checks out.
   - `refuse` (po-gate.sh:22) prints `po-gate: …`, so the test's `${err##*— po-run }` extraction holds.
   - `fresh_record`, `seal`, `accepted`, `story_sandbox`, `sandbox`, `qa_report`, `passes` and `$RUN` all exist and are used in the existing test files.
   - `git check-ignore -q` is used correctly: it reports only untracked paths, which is the case it is meant to name.
3. **Plan:** tasks 1 to 6 are all present, and I found no change the plan did not ask for.
   - Run interdicts hold: there is no diff on `testing-doctrine`, `verification-record.md`, `po-run.sh`, `po-qa.md`, `po-drive.md`, `.claude/`, `.polype/` or ADR-0037.
   - The phrase `is current but docs/qa/$1/ is not committed` and the `cat-file` clause are kept word for word (`tests/qa-fleet.test.sh:185` still pins the phrase).
   - ADR-0044 is consistent with the code.
4. **Tests:**
   - Floor: `po-gate floor-guard s67-record-text main` exited 0, so nothing was lowered.
   - Budget: 3 new tests, well under the budget of 25.
   - None of the six kinds of test that prove nothing applies. The gate tests run the real `po-gate.sh`, and the hint is proven by running it through `eval`.
   - Bite, measured by running only the affected test file each time:

| Mutation | Files run | Failures |
| --- | --- | --- |
| Gate hint back to `\"$label\"` / `\"$command\"` | run-ledger.test.sh | 1 (`suggested_command_is_single_quoted`) |
| Hint keeps single quotes but drops the `'\''` escaping (`qc="'$command'"`) | run-ledger.test.sh | 1 (same) |
| `--ignored` put back in `qa_current` | qa-gate.test.sh | 1 (`qa_current_ignores_ignored_files`) |
| `cat-file -e HEAD:…/report.md` clause replaced by `true` | qa-gate.test.sh | 1 (same; this closes the s60 m3 gap) |

   Each mutation was undone, and `git diff --exit-code` confirmed it. The worktree is clean, and the tree was unchanged when I finished.
5. **Values:**
   - `q="'\\''"` in double quotes gives `'\''`, which is the standard POSIX escape.
   - Inside a single-quoted word, `$`, backticks and `"` are not expanded, so `po-run.sh:33` records the command byte for byte. The test's command (`test "$(echo 'a b')" = 'a b'`) covers all three plus `'`.
   - Bash 5.2+ `patsub_replacement` does not apply: the replacement holds no `&`.
6. **Neighbours:**
   - The only other place that shows the `po-run … -- "<command>"` form is `method/skills/testing-doctrine/SKILL.md:62` (see m1).
   - `po-drive.md:62` and ADR-0041 rely only on the `is current but` phrase, which is unchanged.
   - Nothing else parses the hint.

## Findings
- **m1 (minor):** `method/skills/testing-doctrine/SKILL.md:62` still says `po-run --story <id> --label <check> -- "<command>"` (double quotes). That now contradicts the implementer and the gate, and a reader who follows the skill with a command holding `$` or `"` gets a recorded command the gate refuses. The file is outside `Owns`; the plan saw this and left it, correctly. A later story should switch it to single quotes.
- **m2 (minor):** ADR-0037's frontmatter still says `status: accepted` and `superseded-by: []`, while ADR-0044 declares `supersedes: [ADR-0037]`. Earlier supersessions in the repo (ADR-0003, 0004, 0013, 0014) mark the old ADR `superseded`. ADR-0044 replaces only one clause of ADR-0037, and the plan forbids touching ADR-0037. Still, the link now runs one way only, and a reader of ADR-0037 is not sent on to ADR-0044.
- **m3 (minor, design note, not a defect):** as ADR-0044 says under "Bad", a capture the project ignores (for example `*.png`) now passes `qa-current` but never travels in the squash. This is accepted in the ADR and in the plan's pivot. I note it so reviewers of screen stories know that a missing capture can be silent.

No critical or major findings.

## Not verified
- **Full suite:** not rerun. I relied on the record (mode `record`), and only ran `run-ledger.test.sh` and `qa-gate.test.sh` for the mutations (18/18 green before mutating). To cover it: nothing needed unless the record is in doubt; otherwise run `bash tests/run.sh`.
- **A real fix run:** the "Fix run: keep the record" instruction is checked only by a text test. No implementer has actually been run in fix mode against an existing record. To cover it: watch the next real fix loop and check that the `## Runs` rows survive.
- **Installed copies:** `.claude/` and `.polype/` still carry the old gate and implementer text until the method is refreshed. Until then, pipeline runs in this repository use the double-quoted hint and `--ignored`. To cover it: run the usual "Refresh the installed method" step after ship.
- **Other bash versions:** the quoting was checked on bash 5.3.20 only, not on macOS's bash 3.2. To cover it: run `bash tests/run.sh run-ledger.test.sh` under `/bin/bash` 3.2 if macOS users matter.

Max severity: minor
Ship allowed: yes
