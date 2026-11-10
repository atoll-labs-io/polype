# Review — s157-qa-reads-ignore-rules

[Story](../stories.md) · [Plan](../plans/s157-qa-reads-ignore-rules.md) · [Verification](../verif/s157-qa-reads-ignore-rules.md)

Diff reviewed: `git diff main...story/s157-qa-reads-ignore-rules`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 936c3fe3664d1904b8e472e6b10fd346fcfe6e41

## When blocked
- Failure cause: n/a
- Missing: n/a
- Required adaptation: n/a
- Next action: n/a

## Ownership
I listed the diff with `git diff --name-status main...story/s157-qa-reads-ignore-rules` and checked each path against the story's `Owns` line.
- [x] Every path is inside `Owns`. `method/hooks/po-bounds.sh`, `tests/qa-reads-ignore-rules.test.sh` and `docs/decisions/ADR-0026-…` (status M) are listed in `Owns`. `docs/decisions/ADR-0103-…` (status A) is in `Owns` and the plan names it. `docs/research|plans|verif/s157-…` are the story's own evidence.
- [x] No path outside `Owns`.
- [x] No path inside another running story's `Owns`. The only other story worktree is `story/s156-qa-report-returned-as-text`, and its changes (ADR-0029, `method/agents/qa.md`, `po-drive.md`, `po-qa.md`, qa tests) do not overlap these paths.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s157-qa-reads-ignore-rules` → exit 0. I reused the record: `bash tests/run.sh` exited 0 on code equal to `Tree:` outside `docs/`. The project has no type check command (`Typecheck: —`). The record's "Not proven here" says there is no E2E, no build and no type check, and that QA is off.
- [x] `po-gate qa-current` is not required: with `QA stage: —` and `Surface: —`, the story does not go to QA.

## Plan
- [x] Tasks 1–5 are all present: two verbs in `QA_GIT_VERBS` (`po-bounds.sh:319`), the header citation at `:21`, ADR-0103, ADR-0026's `superseded-by`, four tests, and the full suite through `po-run`. Nothing is outside the plan.
- [x] I checked each run interdict:
  - the `po-bounds.sh` diff touches only lines 21 and 319;
  - the ADR-0026 diff is the `superseded-by` line alone, and `status: accepted` stays;
  - there is no diff to `tests/bounds*.test.sh`, `method/agents/qa.md`, `method/agents/reviewer.md`, `qa-drivers/`, ADR-0047, ADR-0051, `.claude/` or `.polype/`;
  - no verb other than `check-ignore` and `check-attr` was added;
  - `qa.md:57` is unchanged.

## References
- [x] I opened every reference the diff and the ADR rely on:
  - `QA_GIT_VERBS` and its matcher `check_git_read` (`po-bounds.sh:582-611`); the space-delimited `*" $verb "*` match holds;
  - the `--output` refusal at `:586`, which runs before the list check, so it still applies to the new verbs;
  - the reviewer story zone, which calls `check_git_read` at `:772`, so the reviewer gains the verbs as ADR-0103 says;
  - `qa.md:57` ("A po-bounds refusal is a stop");
  - ADR-0026:33 ("la QA reformule").
  - Test helpers `scratch_repo`, `contains` and `require_file` exist in `tests/lib.sh`.
- [x] No value that only looks right. `check-ignore` and `check-attr` only print the ignore and attribute rules and write nothing. `--source` and `--stdin` only read.

## Rules
- [x] `AGENTS.md` conventions are respected. The ADR is in French, the code and tests in English, the test function names match the criteria, and the tests are bash using the `lib.sh` helpers.
- [x] No accepted ADR is contradicted. ADR-0026 is replaced on the list only, so it keeps `status: accepted` and only its `superseded-by` link changes, as Law 6 requires for a partial supersession.

## Tests
- [x] Floor: `po-gate floor-guard s157-qa-reads-ignore-rules main` → exit 0, nothing lowered.
- [x] The tests call the real hook through a real linked worktree, so they are at the policy layer. None of the six empty test shapes appears.
  - `qa_still_refuses_writing_verbs` also checks that the code list and the ADR-0103 list hold the same verbs.
  - The ADR-0026 body is pinned by its original list phrase.
- [x] Within `Test budget`: 4 tests against a budget of 25.
- [x] Bite 1: removing `check-ignore` from `QA_GIT_VERBS` → 2 tests failed (`qa_allows_check_ignore`, `qa_still_refuses_writing_verbs`). I undid it, and `git diff --exit-code method/hooks/po-bounds.sh` was clean.
- [x] Bite 2: making the `*) deny` branch of the matcher a no-op → 1 test failed (`qa_still_refuses_writing_verbs`: "qa allows git add -A"). I undid it, and `git diff --exit-code` was clean. A final `git diff --exit-code` on the whole worktree was also clean.
- [x] No test became useless because of this story.

## Neighbours
- [x] `check_git_read` has two callers: mode qa (`:761`) and the reviewer story zone (`:772`). Both get the widened list on purpose (ADR-0047:31, ADR-0103). The record shows `tests/bounds.test.sh` and `tests/bounds-messages.test.sh` stay green within the full suite.

## Lenses
Lenses run: security, set off by `method/hooks/po-bounds.sh`, the permission hook deciding which git commands the qa and reviewer agents may run.
- [x] Security lens: the allowlist grows only by two read-only verbs, and `--output` stays refused for them. Nothing to report.

## Findings
- none

## Not verified
- **The installed copy.** `.polype/hooks/po-bounds.sh` (the copy a real QA or reviewer session runs) is not refreshed by this story, as its plan requires. The fix reaches agents only after a reinstall. After ship, a person should run the installer's `update` and check that the installed `QA_GIT_VERBS` line holds both verbs.
- **The lagon repro.** I did not rerun the original case from #167 (`git -C <worktree> check-ignore -v site/dist site/.astro` inside a real `/po-qa` walk on lagon). The tests replay it against the hook with a scratch repo, not against a live QA subagent. A person can replay it on lagon's next QA walk.
- **No separate full-suite run.** I did not run the full suite myself; I relied on the `po-run` record, which `verif-current` accepted for this code.
- **Lagon's ignore rules.** I did not check git's own behaviour for `check-ignore` and `check-attr` beyond the manual's option list. I accepted that they are read-only from that list and the plan's pivot.

Max severity: none
Ship allowed: yes
