# Review: s53-review-lenses

Reviewed tree: 0f1746303ae37b633d9193c7f37bb0abb10fcbf8
Fix loop: 0
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s53-review-lenses (branch `story/s53-review-lenses`, one commit `8fac9ed`)
Review status: complete

## Ownership
I listed the diff with `git diff --name-only main...story/s53-review-lenses`. The `Owns` line is `method/skills/review-lenses/`, `method/agents/reviewer.md`, `method/skills/review-antihallu/`, `method/templates/review.md`, `tests/review-lenses.test.sh`.
- [x] All five code paths are inside `Owns`.
- [x] The story's own evidence (`docs/research/`, `docs/plans/`, `docs/verif/` for s53) is in scope by construction.
- [x] `docs/decisions/ADR-0030-lentilles-de-revue-prechargees-dans-le-reviewer.md` is outside `Owns`. AGENTS.md Law 6 requires it ("Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`"), so this is a gap in the story's `Owns`, not an implementer breach. Graded minor.
- [x] No other running story is affected. The only other open lane, `story/s54-untrusted-output`, touches `method/AGENTS.md` and `tests/structure.test.sh` plus its own docs. Neither branch touches the other's files.

## Evidence reused
- [x] `po-gate verif-current s53-review-lenses` exited 0. `Verification mode: record`. The record `Tree: 301927bb…` matches HEAD outside `docs/` (`git diff --quiet` exit 0). The status is complete and every exit code is 0:
  - focused tests: 29 passed
  - `bin/po-lint`: clean
  - full suite (`bash tests/run.sh`): 280 passed
  - `ks-overlap` against gstack: 0 lines

  I did not rerun any of these.
- [x] `Typecheck: —`, `E2E: —`, `Build: —`: the project has none of these commands. The diff changes no routing and no manifest.
- [x] There is no screen and `QA stage` is not `screens`, so no QA is required.
- [x] I read the record's "Not proven here" section. Its gaps are carried into Not verified below.

## Plan
- [x] Task 1 (skill): the file is 63 lines, inside the 60-90 target. Every pinned phrase is there verbatim: the four-row trigger table, `No scale of its own`, the authz-critical sentence, the in-place rename sentence, expand/contract/rollback, `one dependency per change`, `changelog`, `install scripts`, `reason in the plan`, `**potential impact**` and `Never put a number on it`. The skill has no verdict line. One gap: the plan's "each lens list 5-8 bullets" is not met (see Findings).
- [x] Task 2 (reviewer): `review-lenses` is preloaded after `review-antihallu`. The sentence on line 16 is kept verbatim and the new sentence is appended. Tools, settings and Limits are unchanged, and there is still no Write.
- [x] Task 3 (procedure): one added section, `## After the six steps: the lenses`, sits between step 6 and `## Severity`. No existing line changed and there are still six `**N. ` steps.
- [x] Task 4 (template): `## Lenses` sits between Neighbours and Findings, with one `Lenses run:` line and the checkbox. The verdict pair is still last and single.
- [x] Task 5 (tests): six functions, named after the criteria. Task 6 is covered by the record.
- [x] Run interdicts: no existing test and no file under `bin/`, `.claude/`, `.polype/`, `method/commands/` or `method/hooks/` was changed. No new setting, no new severity word.

## References
- [x] The test helpers `frontmatter`, `lacks_tool`, `require_file`, `fail` and `$METHOD` all exist in `tests/lib.sh`.
- [x] The installer copies `method/skills` as a whole directory (`bin/polype:86,100`), so the new skill gets installed with no list to update.
- [x] `bin/po-lint:150` keys the "judges but declares Write" rule on `review-antihallu`, which the reviewer still preloads.
- [x] `"hasInstallScript": true` is the real npm lockfile (v2/v3) field.

## Rules
- [x] The code matches ADR-0030 (accepted): a skill preloaded by the single reviewer, applied after step 6.
- [x] The story's "short, rewritten lists" note is respected. The skill is 63 lines and `ks-overlap` against gstack is clean.

## Tests
- [x] Floor: `po-gate floor-guard s53-review-lenses main` exited 0, so nothing was lowered.
- [x] Six tests, within `Test budget: 25`. They check method text only, which is the only test layer this repository has (per its conventions).
- [x] Bite: I disabled four rules one at a time and ran only `review-lenses.test.sh` each time. Each change failed exactly one test. After each run I undid the change and checked the file with `git diff --exit-code`.
  1. Removed `**A missing authorization check is critical.**` → 1 failure (`security_lens_rates_a_missing_authz_check_critical`).
  2. Removed `  - review-lenses` from the reviewer's frontmatter → 1 failure (`one_reviewer_one_verdict`).
  3. Removed the template's `Lenses run:` line → 1 failure (`lenses_are_triggered_by_the_diff`).
  4. Changed the rename grade from "major" to "minor" → 1 failure (`migration_lens_rejects_in_place_renames`).
- [x] The worktree is clean afterwards (`git status --porcelain` empty, `git diff --exit-code` 0).

## Neighbours
- [x] I read the callers and consumers of the changed files: `method/commands/po-review.md` (its prompt names `review-antihallu`, still valid), `tests/review.test.sh`, `tests/ownership.test.sh`, `tests/qa-gate.test.sh`, `tests/floor-guard.test.sh` and `bin/po-lint`. None is broken. `po-gate ship-allowed` reads only the last verdict line, which is unchanged.

## Lenses
Lenses run: none. The diff has no auth/route/upload/webhook/LLM path or content, no migration, no lockfile or manifest, and no server-side code. It holds only method markdown and bash tests.
- [x] No lens ran, so no lens finding.

## Findings
- major — method/skills/review-lenses/SKILL.md:21 — "A lens looks at the diff only, never at the rest of the repository." This conflicts with review-antihallu step 2 ("Open everything the diff refers to") and step 6 (check the neighbours). It also clashes with the skill's own critical rule on line 39 ("A missing authorization check is critical"):
  - An authorization check often lives in a policy or middleware the diff only calls. Read literally, this line stops the reviewer from opening that file. The reviewer then either raises a false critical that blocks the ship, or ignores the line.
  - The dependency bullet "The changelog between the old and new versions was read" also needs something outside the diff.
  - Suggested wording: "a lens judges only what the diff changes, and opens what that code calls to confirm a finding". This is contained and not silent, so it waits for a later cycle.
- minor — method/skills/review-lenses/SKILL.md:43-63 — The plan (task 1 and Run interdicts) asks for 5-8 bullets per lens. Migration has 3 and Performance has 4. The story only requires the four performance items, and the bound was meant to stop copied checklists, so nothing is lost. It is still a departure from the validated plan that nobody recorded.
- minor — docs/decisions/ADR-0030-lentilles-de-revue-prechargees-dans-le-reviewer.md — This file is outside the story's `Owns`, but AGENTS.md Law 6 requires an ADR for this structural choice. The fix is to list `docs/decisions/` in `Owns` for stories that record an ADR. The code needs no change.

## Not verified
- **Copy check against agent-skills:** no local copy exists on this machine, so `bin/ks-overlap` never ran against it. A person should fetch agent-skills and run `python3 bin/ks-overlap <agent-skills repo> 8` against `method/skills/review-lenses/`.
- **Copy check against Killer SaaS (ADR-0006):** `tests/overlap.test.sh` skips silently because the Killer SaaS copy is absent here, so "280 passed" does not cover it. A person should run that test on a machine that has the copy.
- **Whether a real reviewer applies the lenses:** no live reviewer was run on a diff that holds an authz route, a migration or a lockfile. Triggering them correctly, grading a missing authz check critical and filling `Lenses run:` are behaviour, not text, and are left to s55's evals. A person could run `/po-review` on a seeded story with a lockfile and a handler missing an ownership check.
- **Installed copies:** `.claude/` and `.polype/` are not refreshed by this story. The plan leaves that to a separate commit after ship. Until then, the reviewer running in this repository (including this review) does not preload `review-lenses`.
- **ADR numbering:** I did not check against other planned stories. `main` has ADR-0029 and ADR-0032, so ADR-0030 is free there. Whether another unshipped story has reserved 0030 is not visible from git.

Max severity: major
Ship allowed: yes
