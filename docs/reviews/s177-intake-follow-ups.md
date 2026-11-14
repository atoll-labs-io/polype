# Review — s177-intake-follow-ups

[Story](../stories.md) · [Plan](../plans/s177-intake-follow-ups.md) · [Verification](../verif/s177-intake-follow-ups.md)

Method version: 0.2.0

Diff reviewed: `git diff main...story/s177-intake-follow-ups`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 58b2901d24b2a198e6550f8ecfe49a28fa417333

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s177-intake-follow-ups`. Each path was checked against the story's `Owns` using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`: `docs/harnais.md`, `method/commands/po-intake.md`, `method/hooks/po-gate.sh`, `tests/intake-follow-ups.oracle.test.sh`. The other paths are this story's own research, plan and verification files.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows only this lane, and `story/s178-*` and `story/s179-*` do not exist yet. s178 will also own `method/hooks/po-gate.sh`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s177-intake-follow-ups` exited 0, so I reused the record. The full suite `bash tests/run.sh` exited 0 on code equal to `Tree:` outside `docs/`. There is no type check (`Typecheck: —`). I read "Not proven here": three criteria are judged by reading, and nothing was run against a live forge.
- [x] `po-gate qa-current` is not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 6 are all present, and nothing was added outside the plan.
- [x] I checked each run interdict:
  - `method/hooks/po-intake.sh`: empty diff.
  - `po-gate.sh`: the diff stays inside `redact()` and its comment. `SECRET_PATTERNS`, `SECRET_MATCHER` and `secret_scan` are byte-identical.
  - `tests/intake-issue-becomes-a-story*.test.sh`: empty diff.
  - `failing-check-files-an-issue.oracle.test.sh`, `intake-title-bounded.oracle.test.sh`, `po/`, `README.md`, ADR-0090, ADR-0099, `.claude/` and `.polype/`: untouched.
  - The oracle checksum is intact.
  - No issue or pull request was filed or closed.

## References
- [x] I checked the gh flags on the installed version, gh 2.103.3: `gh auth status` accepts `--active` and `--json hosts`, and `gh issue list --json` accepts the `author` field. `next_secret`, `prule`, `SM_START` and `SM_LEN` exist in `SECRET_MATCHER` (`po-gate.sh:249-269`). The `## Landing the framing` behaviour the plan relies on (the root keeps the files staged) matches `po-setup.md:84`.
- [x] Values: the merged-span rule (a run of flagged characters becomes one `[redacted]`) follows from the criterion. The 1550-word bound is confirmed: both main and the branch count 1550 with `LC_ALL=C wc -w`.

## Rules
- [x] `AGENTS.md` conventions are respected: method text in English, harnais doc in French, no Killer SaaS overlap (the suite is green).
- [x] No accepted ADR is contradicted. ADR-0090 still holds: issues bearing on security still go to the person, and an issue from another author is never read into a file.

## Tests
- Oracle: `po-gate oracle-intact s177-intake-follow-ups` → exit 0
- [x] Floor: `po-gate floor-guard s177-intake-follow-ups main` exited 0, so nothing was lowered. `po-gate oracle-intact` also exited 0.
- [x] The assertions pin down the criteria. The redact oracle builds its witness strings at run time, fixes the scan's verdicts first, then checks the exact output. None of the six empty test shapes appears.
- [x] 2 tests, within `Test budget` 25.
- [x] Bite 1: I put back the pre-story in-place rewrite in `redact` (`line = … "[redacted]" …; from = SM_START + length("[redacted]")`). 1 test failed (`redact_follows_the_scan_rule`). Undone, and `git diff --exit-code method/hooks/po-gate.sh` is clean.
- [x] Bite 2: I made the matches be judged on a line already shortened by the earlier ones. 2 tests failed. Undone, and the diff is clean.
- [x] No test became useless.

## Neighbours
- [x] The only caller of `redact` is `po-intake.sh:80-82`, through the `po-gate redact` subcommand. The interface is unchanged. Its tests (`failing-check-files-an-issue*`) pass in the record. `/po-setup`'s framing landing is the code path check 8 now depends on, and I read it.

## Lenses
Lenses run: security — content: an author check on who may get an issue turned into a story (`po-intake.md:29`), and the secret redaction in `po-gate.sh` `redact()`
- [x] Lens result: the author filter applies before any issue file is read, and an issue it rejects ("held: author") is never read. Only checked numbers reach commands. No finding.

## Findings
- major — method/commands/po-intake.md:25 — The pending-intake exception only works while `origin/<Target branch>` has not moved since the pending intake branch was cut, so it does not fully meet `pending_intake_does_not_block`.
  - The exception requires the pending `framing/intake-*` ref to descend from `origin/<Target branch>`. Any ship that lands on `Target branch` after the pending PR breaks that condition, even when the root's `docs/stories.md` still differs from `origin/<Target branch>` only by the pending branch's stories (the fast-forward succeeds whenever the ship leaves `docs/stories.md` alone).
  - From then on every run stops again until a person merges the pending PR. That is the s152 situation, and it is likely: nightly intake while the fleet ships during the day.
  - The stop message, "the root holds stories no pending intake branch carries", is then false: the pending branch does carry them, it is just stale.
  - The plan added the ancestry condition to rule out a branch that was already rebase-merged. A test that tells "not merged" apart from "descends from the tip" would cover both cases, for example the PR-state proof `## Landing the framing` of `po-setup.md:75` already uses, plus a comparison of `docs/stories.md` against `origin/<Target branch>` minus the pending stories.
  - The damage is contained: the run fails closed and stops, and nothing is written.
- minor — method/commands/po-intake.md:29 — An issue labelled `polype-intake` by another author is marked "held: author" at every run, even when a `Fixes` line already cites it (for example a story a person wrote by hand). The finish then lists it forever. Applying the author filter only to the issues left after the citation check would avoid that noise.

Word cuts (I checked all ~107 words removed beyond the plan, line by line against `main`): no rule was lost. Each removed clause was either rationale or is still stated elsewhere in the file:
- "goes to the person in the finish" for no path is covered by the `## Finish` held list.
- "the finish gives its path" for not ready is covered by "not ready (with the review path)".
- "closes when its fix ships" and "never here" are covered by the intro ("closes no issue") and the last finish line.
- "returns nothing or a report without both verdict lines" became "returns no report with both verdict lines", which covers both cases.
- "Only the new stories … are sent" is still in the reviewer prompt at :63.
- "and only those" is replaced by the author sentence's "Only".
- The ADR-0099 / Law 7 sentence is not a rule. Its pinned phrase lives in `docs/harnais.md`, which is kept.
- The pointer in check 7 now reads "as `/po-ship` recognises it" instead of naming `## The forge's review rule`. It is less exact but still sends the reader to the right place, and `## Landing` still names the section.

Criteria judged by reading:
- `only_the_hook_account_is_taken_in`: met. The login comes from `gh auth status --active --json hosts`, check 7 keeps the plain call, issues by other authors are held and named in the finish, and taskwarrior is unchanged.
- `numbering_sees_pending_branches`: met. The ids on every ref read for citations count as taken.
- `pending_intake_does_not_block`: partly met, see the major finding.

## Not verified
- `/po-intake` was not run against a live GitHub repository. Not checked: a pending intake PR, a second `gh` account, how `gh issue list --json author` shows the Actions bot (`app/github-actions` or otherwise), and the superseding flow (merge the newer PR, close the older one, then fast-forward the root). A person should run it once on a sandbox repository: one issue filed by `po-intake.sh`, one labelled by another account, two runs back to back with the first PR left open, and a third run after an unrelated commit lands on `Target branch` (this one exercises the major finding).
- The three criteria judged by reading had no `po-eval` control arm run (#208). They are candidates, as the plan says.
- A model's reading of the denser wording left after the word cuts was not tested. Only the text was judged.

Max severity: major
Ship allowed: yes

Method version: 0.2.0

Diff reviewed: `git diff main...story/s177-intake-follow-ups`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 58b2901d24b2a198e6550f8ecfe49a28fa417333

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s177-intake-follow-ups`. Each path was checked against the story's `Owns` using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`: `docs/harnais.md`, `method/commands/po-intake.md`, `method/hooks/po-gate.sh`, `tests/intake-follow-ups.oracle.test.sh`. The other paths are this story's own research, plan and verification files.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows only this lane, and `story/s178-*` and `story/s179-*` do not exist yet. s178 will also own `method/hooks/po-gate.sh`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s177-intake-follow-ups` exited 0, so I reused the record. The full suite `bash tests/run.sh` exited 0 on code equal to `Tree:` outside `docs/`. There is no type check (`Typecheck: —`). I read "Not proven here": three criteria are judged by reading, and nothing was run against a live forge.
- [x] `po-gate qa-current` is not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 6 are all present, and nothing was added outside the plan.
- [x] I checked each run interdict:
  - `method/hooks/po-intake.sh`: empty diff.
  - `po-gate.sh`: the diff stays inside `redact()` and its comment. `SECRET_PATTERNS`, `SECRET_MATCHER` and `secret_scan` are byte-identical.
  - `tests/intake-issue-becomes-a-story*.test.sh`: empty diff.
  - `failing-check-files-an-issue.oracle.test.sh`, `intake-title-bounded.oracle.test.sh`, `po/`, `README.md`, ADR-0090, ADR-0099, `.claude/` and `.polype/`: untouched.
  - The oracle checksum is intact.
  - No issue or pull request was filed or closed.
- [x] Word cuts: I checked all ~107 words removed beyond the plan, line by line against `main`. No rule was lost. Each removed clause was either rationale or is still stated elsewhere in the file:
  - "goes to the person in the finish" for no path is covered by the `## Finish` held list.
  - "the finish gives its path" for not ready is covered by "not ready (with the review path)".
  - "closes when its fix ships" and "never here" are covered by the intro ("closes no issue") and the last finish line.
  - "returns nothing or a report without both verdict lines" became "returns no report with both verdict lines", which covers both cases.
  - "Only the new stories … are sent" is still in the reviewer prompt at :63.
  - "and only those" is replaced by the author sentence's "Only".
  - The ADR-0099 / Law 7 sentence is not a rule. Its pinned phrase lives in `docs/harnais.md`, which is kept.
  - The pointer in check 7 now reads "as `/po-ship` recognises it" instead of naming `## The forge's review rule`. It is less exact but still sends the reader to the right place, and `## Landing` still names the section.
- [x] Criteria judged by reading:
  - `only_the_hook_account_is_taken_in`: met. The login comes from `gh auth status --active --json hosts`, check 7 keeps the plain call, issues by other authors are held and named in the finish, and taskwarrior is unchanged.
  - `numbering_sees_pending_branches`: met. The ids on every ref read for citations count as taken.
  - `pending_intake_does_not_block`: partly met, see the major finding.

## References
- [x] I checked the gh flags on the installed version, gh 2.103.3: `gh auth status` accepts `--active` and `--json hosts`, and `gh issue list --json` accepts the `author` field. `next_secret`, `prule`, `SM_START` and `SM_LEN` exist in `SECRET_MATCHER` (`po-gate.sh:249-269`). The `## Landing the framing` behaviour the plan relies on (the root keeps the files staged) matches `po-setup.md:84`.
- [x] Values: the merged-span rule (a run of flagged characters becomes one `[redacted]`) follows from the criterion. The 1550-word bound is confirmed: both main and the branch count 1550 with `LC_ALL=C wc -w`.

## Rules
- [x] `AGENTS.md` conventions are respected: method text in English, harnais doc in French, no Killer SaaS overlap (the suite is green).
- [x] No accepted ADR is contradicted. ADR-0090 still holds: issues bearing on security still go to the person, and an issue from another author is never read into a file.

## Tests
- Oracle: `po-gate oracle-intact s177-intake-follow-ups` → exit 0
- [x] Floor: `po-gate floor-guard s177-intake-follow-ups main` exited 0, so nothing was lowered. `po-gate oracle-intact` also exited 0.
- [x] The assertions pin down the criteria. The redact oracle builds its witness strings at run time, fixes the scan's verdicts first, then checks the exact output. None of the six empty test shapes appears.
- [x] 2 tests, within `Test budget` 25.
- [x] Bite 1: I put back the pre-story in-place rewrite in `redact` (`line = … "[redacted]" …; from = SM_START + length("[redacted]")`). 1 test failed (`redact_follows_the_scan_rule`). Undone, and `git diff --exit-code method/hooks/po-gate.sh` is clean.
- [x] Bite 2: I made the matches be judged on a line already shortened by the earlier ones. 2 tests failed. Undone, and the diff is clean.
- [x] No test became useless.

## Neighbours
- [x] The only caller of `redact` is `po-intake.sh:80-82`, through the `po-gate redact` subcommand. The interface is unchanged. Its tests (`failing-check-files-an-issue*`) pass in the record. `/po-setup`'s framing landing is the code path check 8 now depends on, and I read it.

## Lenses
Lenses run: security — content: an author check on who may get an issue turned into a story (`po-intake.md:29`), and the secret redaction in `po-gate.sh` `redact()`
- [x] Lens result: the author filter applies before any issue file is read, and an issue it rejects ("held: author") is never read. Only checked numbers reach commands. No finding.

## Findings
- major — method/commands/po-intake.md:25 — The pending-intake exception only works while `origin/<Target branch>` has not moved since the pending intake branch was cut, so it does not fully meet `pending_intake_does_not_block`.
  - The exception requires the pending `framing/intake-*` ref to descend from `origin/<Target branch>`. Any ship that lands on `Target branch` after the pending PR breaks that condition, even when the root's `docs/stories.md` still differs from `origin/<Target branch>` only by the pending branch's stories (the fast-forward succeeds whenever the ship leaves `docs/stories.md` alone).
  - From then on every run stops again until a person merges the pending PR. That is the s152 situation, and it is likely: nightly intake while the fleet ships during the day.
  - The stop message, "the root holds stories no pending intake branch carries", is then false: the pending branch does carry them, it is just stale.
  - The plan added the ancestry condition to rule out a branch that was already rebase-merged. A test that tells "not merged" apart from "descends from the tip" would cover both cases, for example the PR-state proof `## Landing the framing` of `po-setup.md:75` already uses, plus a comparison of `docs/stories.md` against `origin/<Target branch>` minus the pending stories.
  - The damage is contained: the run fails closed and stops, and nothing is written.
- minor — method/commands/po-intake.md:29 — An issue labelled `polype-intake` by another author is marked "held: author" at every run, even when a `Fixes` line already cites it (for example a story a person wrote by hand). The finish then lists it forever. Applying the author filter only to the issues left after the citation check would avoid that noise.


## Not verified
- `/po-intake` was not run against a live GitHub repository. Not checked: a pending intake PR, a second `gh` account, how `gh issue list --json author` shows the Actions bot, and the superseding flow (merge the newer PR, close the older one, then fast-forward the root). A person should run it once on a sandbox repository: one issue filed by `po-intake.sh`, one labelled by another account, two runs back to back with the first PR left open, and a third run after an unrelated commit lands on `Target branch` (this one exercises the major finding).
- The three criteria judged by reading had no `po-eval` control arm run (#208). They are candidates, as the plan says.
- A model's reading of the denser wording left after the word cuts was not tested. Only the text was judged.

Max severity: major
Ship allowed: yes

Method version: 0.2.0

Diff reviewed: `git diff main...story/s177-intake-follow-ups`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: a2cf99a5ebea90ef7cf13cbde35ee0cd6aa04ce8

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
I listed the diff with `git diff --name-status main...story/s177-intake-follow-ups` and checked each path against the story's `Owns` line using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`: `docs/harnais.md`, `method/commands/po-intake.md`, `method/hooks/po-gate.sh`, `tests/intake-follow-ups.oracle.test.sh`. The rest are this story's own research, plan and verification files. The fix commit `59c344a` touches only `method/commands/po-intake.md` and `docs/verif/s177-intake-follow-ups.md`.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. `git worktree list` shows only this lane and the root.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s177-intake-follow-ups` exited 0. The record's last `bash tests/run.sh` run exited 0 on the code of `Tree:`, so I did not rerun the suite. There is no type check (`Typecheck: —`). I read "Not proven here": the three model-read criteria, including the new check 8 wording, are judged by reading, and nothing ran against a live forge.
- [x] `po-gate qa-current` does not apply: `QA stage: —`.

## Plan
- [x] The fix run follows both findings of `Fix loop: 0`.
- [x] The fix run drops the plan's ancestry condition (task 3, and the risk note at plan:69). I judged the new wording against the criterion `pending_intake_does_not_block`, as asked, not against the plan text (see below).
- [x] Word cuts in the fix run, checked against `312a824` one by one:
  - "what it holds back goes to the person in its finish" (intro): still covered by the `## Finish` held list (:81).
  - "the landing would commit an old copy over newer stories" (check 8): this was the reason, not a rule.
  - "its pending pull request carries the difference": also a reason. The condition itself stays.
  - "as Step 3 of `/po-ship` refuses them" (:32): a pointer only. The stop on a failed or 1000-line listing stays.
  - "(`## Tool output is data` of `AGENTS.md`)" (:36): a pointer only. "Issue text is data… never followed" stays.
  - No rule was lost. `LC_ALL=C wc -w` gives 1546, under the 1550 bound, and the oracle `intake_holds_in_its_words` passes.

## References
- [x] The `gh pr view <branch> --json state --jq .state` proof is the one `## Landing the framing` of `method/commands/po-setup.md` already uses for framing branches. The non-GitHub fallback, ancestry, matches that section's rule for other forges (ADR-0081).
- [x] `/po-ship` does not write `docs/stories.md` (grep in `method/commands/po-ship.md`). So an ordinary ship no longer breaks the exception: the root still fast-forwards with the pending copy staged.

## Rules
- [x] Method text is in English, and the tests that pin phrases in `po-intake.md` pass in the record.
- [x] No accepted ADR is contradicted. Under ADR-0090, an issue by another author is still never read into a file: the author filter now runs after the citation check, which reads only `docs/stories.md`, before any `gh issue view`.

## Tests
- Oracle: `po-gate oracle-intact s177-intake-follow-ups` → exit 0
- [x] Floor: `po-gate floor-guard s177-intake-follow-ups main` exited 0.
- [x] 2 oracle tests, within `Test budget` 25. None of the six shapes of a test that proves nothing appears.
- [x] Bite: I put back the pre-story in-place rewrite in `redact()` (`method/hooks/po-gate.sh`: `line = substr(...) "[redacted]" ...; from = SM_START + length("[redacted]")`) and ran `bash tests/run.sh intake-follow-ups.oracle.test.sh`. 1 test failed (`redact_follows_the_scan_rule`). I undid it with `git checkout -- method/hooks/po-gate.sh`, and `git diff --exit-code` is clean. The fix commit leaves `po-gate.sh` alone, so the earlier review's second bite still holds for this code.
- [x] The changed check 8 and the author filter are model-read rules with no oracle by design (direction, "Criteria and tests"). Nothing to bite there.

## Neighbours
- [x] `## Landing the framing` (`po-setup.md`) leaves the committed files staged in the root, and the new check 8 relies on that. That is unchanged. Its own merged-or-not proof uses the same PR-state test, so the two commands agree on what "pending" means.

## Lenses
Lenses run: security — content: an author check on who may get an issue turned into a story (`po-intake.md:29`), and the secret redaction in `po-gate.sh` `redact()`
- [x] The author filter still runs before any issue file is read, and only checked numbers reach commands. No finding.

## Earlier findings (Fix loop: 0)
- **major — `po-intake.md:25`, the pending exception breaks once `Target branch` moves: resolved.**
  - The ancestry condition is replaced by two others. The first is "not merged": on GitHub, the pull request state is `OPEN`; elsewhere, the branch is no ancestor of the target. The second: the ref's copy deletes no line of the target's copy (`git diff --numstat`).
  - Against `pending_intake_does_not_block`: after an unrelated ship, the root fast-forwards with its staged copy, and that copy equals the ref's. The ref only adds lines over the target, so the root differs from the target only by what the open branch carries, and the run goes on.
  - A rebase-merged branch is no longer `OPEN`, so it no longer counts as pending. That covers the case the plan's ancestry condition was there for (plan:69).
  - A copy that lost the target's lines fails the no-deletion test and stops, as "any other difference stops" requires.
  - When `Target branch` itself changes `docs/stories.md` (a framing landing), the fast-forward is refused and the run stops. The root then lacks the target's lines, so the criterion also says stop. This is the stop the plan keeps on purpose (plan:70).
  - The stop message now says "no open intake branch carries", which is true in the cases that reach it.
- **minor — `po-intake.md:29`, an issue by another author that a `Fixes` line already cites was held at every run: resolved.**
  - The filter now reads "Of the issues no line cites (below), only one authored by …", so a cited issue is no longer marked "held: author".

## Findings
none

## Criteria judged by reading
- `pending_intake_does_not_block`: met, see above.
- `only_the_hook_account_is_taken_in`: met, unchanged since loop 0 apart from the order fix.
- `numbering_sees_pending_branches`: met, unchanged (:46).

## Not verified
- `/po-intake` was never run against a live GitHub repository. Not checked:
  - a pending intake pull request, including what `gh pr view framing/intake-<ts>` prints when one branch name has several pull requests;
  - a second `gh` account;
  - how `--json author` shows the Actions bot;
  - the superseding flow.

  A person should run it on a sandbox repository:
  - one issue filed by `po-intake.sh`, and one labelled by another account;
  - two runs back to back with the first PR left open;
  - a third run after an unrelated ship lands on `Target branch`; it should carry on;
  - a fourth run after a framing landing changes `docs/stories.md`; it should stop on the refused fast-forward.
- The non-GitHub fallback (ancestry plus no deletion) was judged only from the text. No forge other than GitHub was available.
- The three model-read criteria had no `po-eval` control arm run (#208). They remain candidates.
- How a model reads the denser check 8 (two nested conditions in one sentence) was not tested. Only the text was judged.

Max severity: none
Ship allowed: yes
