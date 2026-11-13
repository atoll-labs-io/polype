# Review — s160-intake-title-bounded

[Story](../stories.md) · [Plan](../plans/s160-intake-title-bounded.md) · [Verification](../verif/s160-intake-title-bounded.md)

Diff reviewed: `git diff main...story/s160-intake-title-bounded`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: db9af018369454b0ca7c57cc5e3e98562e67ebb0

## When blocked
- Failure cause: n/a
- Missing: n/a
- Required adaptation: n/a
- Next action: n/a

## Ownership
I listed the diff with `git diff --name-only main...story/s160-intake-title-bounded` and held each path against the story's `Owns`, using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. `method/hooks/po-intake.sh`, `method/hooks/po-gate.sh`, `docs/harnais.md` and `tests/intake-title-bounded.oracle.test.sh` are listed there. `docs/research|plans|verif/s160-intake-title-bounded.md` are the story's own evidence. There is no `tests/intake-title-bounded.test.sh`, as the plan says.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. The only other running lane is `story/s159-ci-on-every-pr`. It touches `.github/workflows/ci.yml`, `AGENTS.local.md`, `bin/po-ci`, `docs/ci.md`, `method/commands/po-ship.md`, `method/templates/agents-local.md` and its own tests. None of those is in this diff.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s160-intake-title-bounded` passes (exit 0), so I reused the record. The unit suite `bash tests/run.sh` exited 0 on code equal to the record's `Tree:`. The project has no type check (`Typecheck: —`). I read "Not proven here": the word bounds, the awk exit move from 2 to 3 having no deterministic test, harnais read by eye, and invalid UTF-8 not covered.
- [x] `po-gate qa-current` is not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Each task is present and nothing is outside the plan.
  - T1: the `sub(/ - .*/, "", f)` is in the `FAILED` branch only.
  - T2: the cut is the `po-ship.md:90` recipe under `LC_ALL=C.UTF-8`, placed after the scrub, and its output has no trailing newline.
  - T3: `-r` check added, awk exit changed from 2 to 3 at both sites, header line updated.
  - T4: header trims.
  - T5: one line of `docs/harnais.md:15`.
- [x] I checked each run interdict:
  - The oracle cksum is `1150097721 5270` and `po-gate oracle-intact` exits 0.
  - The diff is empty on `tests/failing-check-files-an-issue.oracle.test.sh`, `tests/failing-check-files-an-issue.test.sh` and `tests/review-findings-shape.test.sh`.
  - `po-gate.sh` changed only in the header at :19 and in the `findings_shape` comment and body. `redact` and `SECRET_PATTERNS` are untouched.
  - In `po-intake.sh`, `scrub` and its two calls are unchanged, and the cut runs after `scrub "$d/title.raw"`.
  - No `.claude/` or `.polype/` file is in the diff.
  - `wc -w`: po-intake 1615 (main 1623) and po-gate 5758 (main 5767), both within the bound.

## References
- [x] I opened every call and key. `shape_unreadable` and `refuse` exist in `po-gate.sh`. `$d/title` is read by `report()`, by the exact-title match against `gh issue list`, and by `gh issue create --title`. The recipe in `po-ship.md:90` matches the one used here.
- [x] No value only looks right. The 80-character bound matches `/po-ship` step 3 as the story asks. The awk exit 3 does not clash with awk's own fatal exit 2, which now reaches `shape_unreadable` (issue #134's path).

## Rules
- [x] The `AGENTS.md` conventions are respected: English in method files, French in `docs/harnais.md`, no installed copy edited, word count not increased (Direction).
- [x] No accepted ADR is contradicted. An unreadable review exits 2 and says so, which is the cannot-run class of ADR-0096.

## Tests
- [x] Floor: `po-gate floor-guard s160-intake-title-bounded main` gives 0, nothing lowered.
- [x] The assertions pin down the four criteria by calling `po-intake` and `po-gate` as a caller does. `gh` is a stub of a third-party CLI and only logs. None of the six empty test shapes is present.
- [x] 4 tests, within `Test budget` (25).
- [x] Bite: I made five changes, each undone afterwards and confirmed clean with `git diff --exit-code`.
  - FAILED-branch `sub()` removed: 1 failing test (`fingerprint_drops_the_assertion_message`).
  - 80-character `sed` cut removed: 1 failing test (`title_is_cut_at_80_characters`).
  - `LC_ALL=C.UTF-8` changed to `LC_ALL=C` (byte cut): 1 failing test (`title_is_cut_at_80_characters`, which shows the split `é`).
  - `-r` check removed: 1 failing test (`unreadable_review_exits_2`, now reporting "no verdict block").
  - awk `exit 3` put back to `exit 2`: 1 failing test in `review-findings-shape.test.sh` (`gate_checks_findings_shape`). The move from 2 to 3 is therefore covered, despite the plan saying it was not.
- [x] No test is made useless by the story.

## Neighbours
- [x] I read the other callers of `findings-shape`: `po-review.md:41`, `po-flow.md:90` and `po-orchestrator.md:73,81`. They treat exit 2 as "check could not run" and exit 1 as "refused". Both meanings are kept: a missing `## Findings` still exits 1 through `refuse`. Both trackers in `po-intake` read the same `$d/title`, so both get the bound.

## Lenses
Lenses run: none. The diff touches no auth, route, migration, lockfile or server-side path, and contains no trigger content. On secrets, I checked by reading that the title cut runs after the scrub, so it cannot cut a secret in a way that would slip past `redact`.

## Findings
none

## Not verified
- **A real GitHub title limit.** The `gh` stub accepts any title length, so no test reproduces the refusal behind #197. The fix rests on the title equality the oracle asserts. A person can confirm it by running `po-intake` once against a scratch GitHub repository with a 400-character failing line.
- **A host without the `C.UTF-8` locale, or a failing line that is not valid UTF-8.** `sed` may then cut by bytes or not at all. The plan accepts this as `/po-ship` does (`po-ship.md:92`). To check it, run the oracle on a minimal image such as Alpine/musl.
- **Issues opened before this change.** An issue with a title of 81 to 256 characters, or with a pytest title that kept its message, will no longer match the new title exactly. Its next failure opens one new issue instead of commenting on the old one. This is a one-off consequence of the story's wording, not a defect. A person may close such old issues by hand.
- **The installed copies.** `.polype/hooks/po-intake.sh` and `.polype/hooks/po-gate.sh` still differ from `method/`, which is expected until the next install refresh. That refresh is outside this diff.

Max severity: none
Ship allowed: yes
