# Review: s60-gate-parsing

[Story](../stories.md) · [Plan](../plans/s60-gate-parsing.md) · [Verification](../verif/s60-gate-parsing.md)

Reviewed tree: 6dd6d5d4622acdb70c8aa84cbab8eb8c2514a46e
Fix loop: 0
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s60-gate-parsing (branch `story/s60-gate-parsing`, one commit 235a736)
Scope: `git diff main...story/s60-gate-parsing`
Lenses run: none. No path or content in the diff matches a lens trigger: no auth, route or handler path, no migration, no lockfile or manifest, no server code.

## Checks
- [x] **Ownership.** The diff touches `method/hooks/po-gate.sh` and the four test files, all listed in `Owns`. It also touches the story's own research, plan and verification record, which are in scope by construction. The one path outside `Owns` is `docs/decisions/ADR-0037-qa-current-exige-une-preuve-qa-committee.md` (see m1).
  - s61-bounds-owns is the only other running worktree. Its diff shares no path with this one. Its ADR is numbered 0038, so the numbers do not collide.
- [x] **Record reused.** `po-gate verif-current s60-gate-parsing` exits 0 with both the installed copy and `method/`. Status is complete, and the `Unit suite` run (`bash tests/run.sh`) exited 0. With `Verification mode: record` I did not rerun the full suite. The project has no `Typecheck`, `E2E` or `Build` command (`—`).
- [x] **Floor guard.** `po-gate floor-guard s60-gate-parsing main` exits 0 with both the installed copy and the `method/` copy.
- [x] **QA gate.** Not required: the story has no screen.
- [x] **References.** Every function the diff calls exists in `po-gate.sh`: `ext_of`, `same_language`, `pext`/`np`, `is_test`, `code_matches`, `top` and `refuse`. Test helpers `story_sandbox`, `seal`, `unit`, `fresh_record`, `accepted`, `refused_naming`, `flagged`, `not_flagged` and `floor_repo` are all used as they are defined.
- [x] **Plan.** Tasks 1 to 6 are present, with two deviations (m2, m3).
  - The run interdicts hold. `.claude/`, `.polype/`, `po-drive.md`, `po-status.md`, `review-antihallu` and `qa-fleet.test.sh` are untouched, and `SECRET_PATTERNS`, `FLOOR_PATTERNS` and `FLOOR_TEST_PATHS` are unchanged.
  - Only `test_qa_current_needs_a_full_tree_hash` changed among the existing tests, as task 5 says.
- [x] **Regression on existing records.** I ran the new `record_rows` over every `docs/verif/*.md`, over s61's record and over `method/templates/verification-record.md`. None produces an `E` row.
- [x] **Mutation tests.** Each rule was turned off, only the relevant test file was run, then the file was restored. `git diff --exit-code` is clean.

| Rule turned off | Test file | Failing tests |
| --- | --- | --- |
| Rename check for test files removed (`0 &&`) | floor-guard | 1 |
| Extension clause of the rename check removed | floor-guard | 1 |
| New end-of-input clause `remold > 0 \|\| remnew > 0` removed | floor-guard | 1 |
| Whole `exit 3` removed | floor-guard | 1 |
| PEM exception removed (left boundary applied everywhere again) | gate | 1 |
| Left boundary removed entirely | gate | 1 (`pre_commit_refuses_obvious_keys`) |
| `n < 3` clause | run-ledger | 1 |
| Separator-label clause | run-ledger | 1 |
| Loop that refuses on an `E` row | run-ledger | 1 |
| `git status` clean check in `qa_current` | qa-gate | 1 |
| `git cat-file -e HEAD:…report.md` check in `qa_current` | qa-gate | **0** (see m3) |

- [x] **Other callers.** `qa-current` is used in `method/commands/po-drive.md:52-53,62`, `po-status.md`, `templates/review.md` and `skills/review-antihallu/SKILL.md:27`. `/po-qa`'s evidence commit is in `method/commands/po-qa.md:39-45`.

## Findings

**M1 (major): `qa-current` counts ignored files, but the evidence commit can never commit them, so the gate refuses for good and its advice cannot work.**
- **Where:** `method/hooks/po-gate.sh`, in `qa_current`, the call `status --porcelain --untracked-files=all --ignored -- "docs/qa/$1/"`.
- **Cause:** `/po-qa` makes its evidence commit with `git add -- docs/qa/<id>/` and then `git commit -- docs/qa/<id>/` (`po-qa.md:42-43`). Git never stages ignored files that way. So any ignored file under `docs/qa/<id>/` (a `.DS_Store` from a global excludes file, a `*.png` rule, a stray log) leaves `!!` in the status output for ever.
- **Reproduced** in a scratch repo with `.DS_Store` ignored:
  - the report committed alone → `qa-current` exits 0;
  - after `touch docs/qa/s01-a/.DS_Store`, the advised commit fails with "nothing to commit", and `qa-current` keeps exiting 1 with "is current but docs/qa/s01-a/ is not committed — commit it alone…".
- **Effect:**
  - The message neither names the offending file nor gives a remedy that works.
  - The review skill routes a `qa-current` failure to `/po-qa`, and `po-drive.md:52` re-enters QA without spending a `Max attempts` unit. A lane in this state can re-walk QA without limit.
- **Mismatch with ADR-0037:** the ADR justifies the clause by saying it "colle au pathspec du commit de preuve", which is false for ignored files. Its "Neutral" consequence only covers a project that ignores all of `docs/qa/`.
- **Fix:** drop `--ignored`, or refuse with a distinct message that names the ignored path.

**m1 (minor): ADR file outside `Owns`.** `docs/decisions/ADR-0037-…md` is not in the `Owns` line. Law 6 requires an ADR for this structural choice, so this is a gap in the story's `Owns`, not a breach. The plan states it openly.

**m2 (minor): code change the plan did not ask for.**
- Task 2 says "no change to `po-gate.sh`; the rule … already holds". The implementer instead added `remold > 0 || remnew > 0` to the floor guard's `END`.
- Without it, case (a) of `floor_guard_says_2_on_an_unreadable_diff` would pass as clean: a hunk cut short at the end of the diff was not caught. So the research's premise was wrong.
- The change is correct (a valid diff always empties its hunk counters) and tested, and the commit message and the record's "Not proven here" say so. The plan was not updated to record the deviation.

**m3 (minor): the `cat-file` check is redundant and untested.**
- The plan's test table says removing `cat-file -e HEAD:docs/qa/<id>/report.md` would turn `qa_current_requires_a_committed_report` red. It does not (0 failures).
- The `status --porcelain --untracked-files=all --ignored` check already refuses every case where the report is missing from `HEAD`: untracked `??`, staged `A `, ignored `!!`. Either drop the clause or correct the plan's claim.

**m4 (minor): method texts are now stale about `qa-current`.**
- `method/commands/po-drive.md:53`: the evidence-commit resume row can no longer match.
- `method/commands/po-drive.md:62`: "It reads the working tree, so a current report left uncommitted passes it" is now false.
- `method/skills/review-antihallu/SKILL.md:27`: the list of failure causes omits "not committed", and its `/po-qa` routing sends this case to a new walk when an evidence commit would do.
- All three files are outside this story's `Owns`. ADR-0037, the record and the commit message state it, and s64 (which depends on s60 and owns `po-drive.md`) is set to fix the drive row. The skill text is not covered by any story yet.

**m5 (minor): ADR-0037 overrides part of ADR-0029 without saying so in its header.** It replaces ADR-0029's "Neutral" consequence (uncommitted report passes, "à revoir") but has `supersedes: []`. A reader of ADR-0029 gets no link to the change.

## Not verified
- **The full unit suite on this tree.** I relied on the record (`Unit suite` exit 0, record current per `verif-current`) and only ran the four touched test files for the mutations. To cover it, run `bash tests/run.sh` once.
- **Rename detection under `diff.renames=false` or with copy detection.** `--find-renames` is pinned in the guard, so I did not exercise other user settings. Paths containing tabs or quotes in a `R` line of `--name-status` were not tested. A person could add a rename whose path has a space or non-ASCII characters to a scratch repo and run `floor-guard`.
- **Any awk other than the local one.** The new awk functions (`ext_of`, `same_language`, `separator()` reading the global `n`) were run only with this machine's awk, not with mawk or BSD awk. To cover it, run `tests/floor-guard.test.sh`, `tests/run-ledger.test.sh` and `tests/gate.test.sh` on macOS or with mawk.
- **A real `/po-drive` lane going through the new `qa-current` refusal**, including the re-walk loop described in M1. I reasoned it from `po-drive.md:52` and the review skill, and reproduced only the gate's side. To cover it, run a screen story through `/po-drive` with an ignored file planted in `docs/qa/<id>/`.

Max severity: major
Ship allowed: yes
