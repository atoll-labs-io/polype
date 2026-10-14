# Review — s121-framing-realign-and-orchestrator-log

[Story](../stories.md) · [Plan](../plans/s121-framing-realign-and-orchestrator-log.md) · [Verification](../verif/s121-framing-realign-and-orchestrator-log.md)

I reviewed the diff `git diff main...story/s121-framing-realign-and-orchestrator-log` without having written it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: df52ff3d7dd331a1e28f9e7da4eccad34a54b5ad

## When blocked
Not applicable. The tree was the same at the start and at the end of the review, and the worktree is clean.

## Ownership
I listed the diff with `git diff --name-only main...story/s121-framing-realign-and-orchestrator-log`.
- [x] Every path is inside `Owns`. The files are `method/commands/po-setup.md`, `method/commands/po-orchestrator.md`, `tests/framing-realign-and-orchestrator-log.test.sh` (new) and `tests/framing-second-landing.test.sh`. The `docs/research|plans|verif/s121-…` files are the story's own evidence. `tests/drive-guards.test.sh` is owned but was not touched, as the plan expected.
- [x] No path is outside `Owns`.
- [x] No path is inside another running story's `Owns`. The only other story worktree is s120, at 9404c10, which is the head of `main`, so that story is already merged. `framing/s122-status-ds` lives in a temporary job directory and the diff touches none of its files.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s121-…` exited 0, so I reused the record. The unit suite (`bash tests/run.sh`) exited 0 on a tree whose code outside `docs/` matches. The project has no type check (`Typecheck: —`), no E2E and no build. The record's "Not proven here" covers two things: a real forge with two framing slugs, and the stale installed copies in `.claude/` and `.polype/`.
- [x] `po-gate qa-current` is not required: `QA stage: —` and `Surface: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1 to 6 are all present, with nothing outside the plan.
  - Task 1: the Base `pr` bullet now runs in order: fetch, stop if `origin/<Target branch>` is missing, then the ff-only realignment whatever the slug, then the absent-branch clause. `Merged →` was shortened. The old "That ref missing" line is gone.
  - Task 2: the `human` sentence was rewritten. The quoted message is unchanged.
  - Task 3: the log kinds, the timing and the "Not now" caveat were added.
  - Task 4: the new test file.
  - Task 5: one assertion was dropped in `framing-second-landing.test.sh:56`.
  - Task 6: the run is in the record.
- [x] I checked each run interdict:
  - `po-drive.md`, `po-ship.md`, `po-research.md`, `po-flow.md`, `method/AGENTS.md`, the other framing commands, `method/hooks/` and `method/templates/` have an empty diff, and so do `.claude/` and `.polype/`.
  - `framing-through-pr`, `pilot`, `escalation-contract` and `lib.sh` are untouched.
  - In `po-setup.md`, the commit build, the other pr bullets (including the post-merge ff-only), local mode and the Report are unchanged.
  - No reset, stash, checkout or `--force` was added, and every `git push` names `framing/<slug>`.
  - In `po-orchestrator.md`, only `## The decisions log` changed, and no checkpoint heading was added.
  - No ADR and no new setting.

## References
- [x] Every reference I opened exists:
  - `po-orchestrator.md` `## Stage 1 — Track`, and the `/po-flow` escalation at :45.
  - `po-ship.md:76` and `:88`, which hold "Pull request ready: <url>.".
  - `po-ship.md:80`, which has Merge / Not now under local and an effective `human`.
  - `po-ship.md:81`, where a local ship stops on a modified tracked file in the root.
  - `po-drive.md` `## The decisions log`; the new "Not now" caveat is a faithful single-run rewording of it.
  - `po-setup.md:79`, the staging that the realignment interacts with.
- [x] Values: on a root already at or ahead of the ref, `git merge --ff-only` exits 0 with "Already up to date", so "stays as it is" is correct. The missing-ref stop now comes before the merge, which closes pivot risk 3.

## Rules
- [x] `AGENTS.md` conventions are respected. The method text is in English, the test is in bash with `test_` names that match the criteria, and nothing in the installed copies was edited.
- [x] No accepted ADR is contradicted (ADR-0077, ADR-0080, ADR-0081).

## Tests
- [x] Floor: `po-gate floor-guard s121-… main` exited 0, so nothing was lowered. The one assertion removed from `framing-second-landing.test.sh` is justified by plan task 5.
- [ ] The assertions only partly pin down the criteria. One clause is covered only in appearance; see Findings.
- [x] The test count is within the `Test budget`: 2 new tests out of 25.
- [x] Bite 1: I removed the slug-independent realignment and put it back under `Merged →`, which is the pre-story shape. One test failed: `every_landing_realigns_the_root`. I undid it with `git checkout`, and `git diff --exit-code` was clean.
- [x] Bite 2: I removed the sentence "A run whose ship ends on "Pull request ready: <url>." writes its rows at that moment…" from `po-orchestrator.md`. **No test failed**: framing-realign-and-orchestrator-log plus drive-guards gave 5 passed, 0 failed. I undid it with `git checkout`, and `git diff --exit-code` was clean.
- [x] No test was made useless by the story.

## Neighbours
- [x] The other callers of the Base logic and of the decisions log still match:
  - The other framing commands only point to `## Landing the framing`, which is unchanged.
  - `/po-drive`'s log section is consistent with the new orchestrator text.
  - `drive-guards` `lone_decisions_are_all_logged` still passes, because `never before its ship` was kept.
  - No other file in `method/` mentions the root realignment.

## Lenses
Lenses run: none. The diff touches only markdown method prose and bash text tests: no auth, routes, migrations, lockfiles or server code.

## Findings
- major — `tests/framing-realign-and-orchestrator-log.test.sh:47` — The assertion `'Pull request ready: <url>.'` does not test the new timing rule (orchestrator rows are written at "Pull request ready"). That phrase was already in the same section, in the pre-existing `Finish with "<id> shipped.", "Pull request ready: <url>.", …` line at `method/commands/po-orchestrator.md:92`. `section_of` runs to the end of the file because no `##` heading follows the log. Deleting the timing sentence fails no test (bite 2), so the clause only looks covered. The plan's test strategy says the opposite: removing "the "Pull request ready" timing" should turn it red. Fix: assert a phrase only the new sentence carries, for example `writes its rows at that moment` or `a \`pr\` ship never inspects the root`.
- minor — `method/commands/po-setup.md:68` — The realignment now runs before the path is staged at :79, on every `pr` landing. A root with a modified or untracked framing file (typically `docs/decisions-log.md` during a log landing, when `origin/main` already holds an earlier landed log) will see the ff-only refused more often, and the report gets noisier. The plan's pivot accepts this. Nothing is lost: the landing goes on, and the post-merge ff-only at :90 realigns once the file is staged. I note it so the noise is expected, not as a defect.

## Not verified
- How an agent actually behaves on a real forge with two framing slugs: realignment, refusal reporting, and deleting a merged branch only on its own slug. These are method-prose rules and no test can run them here. A person should run two framing landings on different slugs against a GitHub test repository, merge one by hand, and watch the next landing on the other slug.
- That the orchestrator really writes log rows for the track choice, implementation details and answers given without asking, and does so at "Pull request ready". The tests only check that the text is present. A person should run `/po-orchestrator` on a `pr` story with `Ship confirmation: human` and check `docs/decisions-log.md`.
- The installed copies in `.claude/commands/` and `.polype/` keep the old wording until a reinstall, as the record says. A person should refresh them after the ship.
- The unit suite was not rerun. I relied on the `po-run` record (exit 0 on an equivalent tree), except for the focused files I ran during the bite.

Max severity: major
Ship allowed: yes

---

# Review — s121-framing-realign-and-orchestrator-log

I reviewed `git diff main...story/s121-framing-realign-and-orchestrator-log` without having written any of it. Each finding is graded critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 476c3cef19f0d644642a90ff9410804b6c144fe7

## When blocked
Not applicable. The tree was 476c3cef… when I started and still 476c3cef… just before this answer. The worktree is clean.

## Ownership
I listed the diff with `git diff --name-status main...story/s121-framing-realign-and-orchestrator-log`.
- [x] Every path is inside `Owns`:
  - `method/commands/po-setup.md`
  - `method/commands/po-orchestrator.md`
  - `tests/framing-realign-and-orchestrator-log.test.sh` (added)
  - `tests/framing-second-landing.test.sh`
  - The `docs/research|plans|verif|reviews/s121-…` files are the story's own evidence.
- [x] No path is outside `Owns`.
- [x] No path falls inside another running story's `Owns`.
  - The previous review was wrong to call s120 already merged. `story/s120-session-and-gate-checks` (ee0f0ea) is **not** an ancestor of `main` (`merge-base --is-ancestor` exits 1), and its worktree is live.
  - Its `Owns` (`method/hooks/po-gate.sh`, `po-session.sh`, `tests/session-and-gate-checks.test.sh`, `tests/gate.test.sh`, `tests/project-lead.test.sh`, plus `method/AGENTS.md`, `po-ship.md` and `tests/review-tree-gate.test.sh` according to the commit on main) does not overlap any s121 path.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s121-…` exits 0. The record's `Tree: fc245f7…` matches. Its last `Unit suite` row (`bash tests/run.sh`) exits 0 on that code. The fix commit 7d5fd8b changed only the test file, and a new run followed it.
  - The project has no type check (`Typecheck: —`), no E2E (`E2E: —`) and no build (`Build: —`).
  - The record's "Not proven here" lists two things: a real forge with two framing slugs, and the stale installed copies.
- [x] `qa-current` is not required: `QA stage: —` and `Surface: —`.

## Plan
- [x] Tasks 1 to 6 are present, with nothing outside the plan; I checked them in the previous loop and the method files have not changed since.
- [x] The fix run (7d5fd8b) touches only `tests/framing-realign-and-orchestrator-log.test.sh:47` and the record. It swaps the always-true `'Pull request ready: <url>.'` for two phrases that only the new timing sentence carries: `writes its rows at that moment` and ``a `pr` ship never inspects the root``. That is exactly the fix the fix-loop-0 major asked for.
- [x] The run interdicts still hold:
  - The diff on `po-drive.md`, `po-ship.md`, `po-research.md`, `po-flow.md`, `method/AGENTS.md`, `method/hooks/`, `method/templates/`, `.claude/` and `.polype/` is empty.
  - No reset, stash, checkout or `--force` was added.
  - Every `git push` line names `framing/<slug>`.
  - Nothing changed outside `## The decisions log` of `po-orchestrator.md`.

## References
- [x] Every reference I opened exists:
  - `po-ship.md:76` and `:88` ("Pull request ready: <url>.")
  - `po-ship.md:80` (Merge / Not now)
  - `po-ship.md:81` (the local ship stops on a modified tracked file in the root)
  - `po-drive.md:155`, which the new "Not now" sentence rewords faithfully.
- [x] Values: in `po-ship.md`, the root check (`:81`) comes only in the local branch, so "a `pr` ship never inspects the root" is accurate.

## Rules
- [x] The `AGENTS.md` conventions hold: method text in English, bash tests named after the criteria, no installed copy edited.
- [x] No accepted ADR is contradicted (ADR-0077, ADR-0080, ADR-0081).

## Tests
- [x] Floor: `po-gate floor-guard s121-… main` exits 0. The assertion dropped from `framing-second-landing.test.sh` is justified by plan task 5.
- [x] None of the six tests that prove nothing are present. The assertions read the section that owns each rule.
- [x] 2 new tests, within the `Test budget` of 25.
- [x] Bite 1: I deleted the timing sentence ("A run whose ship ends on "Pull request ready…" … never inspects the root.") from `po-orchestrator.md`.
  - **1 failure**: `orchestrator_logs_every_lone_decision` ("lacks: writes its rows at that moment").
  - The other 4 tests in framing-realign plus drive-guards passed.
  - I restored the file with `git checkout`, and `git diff --exit-code` was clean.
  - The major from fix loop 0 is closed.
- [x] Bite 2: I deleted the "Not now" caveat sentence.
  - **1 failure**: `orchestrator_logs_every_lone_decision`.
  - I restored it, and `git diff --exit-code` was clean.
- [x] Bite 3: I deleted the slug-independent `git merge --ff-only` line from **Base**.
  - **2 failures**: `every_landing_realigns_the_root` and `framing-second-landing` `root_realigns_after_a_merge`.
  - I restored it, and `git diff --exit-code` was clean.

## Neighbours
- [x] The other framing commands only point to `## Landing the framing`.
- [x] `/po-drive`'s log section agrees with the new orchestrator text.
- [x] `drive-guards` `lone_decisions_are_all_logged` still passes.

## Lenses
Lenses run: none. The diff is markdown method prose and bash text tests, so no trigger path or content is present.

## Findings
- minor — `method/commands/po-setup.md:68`: the realignment now runs on every `pr` landing, before the path is staged.
  - A root holding a modified framing file will therefore see the fast-forward refused more often, and the report will be noisier.
  - The plan's pivot accepts this, and nothing is lost: the landing carries on, and the post-merge ff-only realigns afterwards.
  - Carried over from fix loop 0. It is an expected behaviour, not a defect.

## Not verified
- **Behaviour on a real forge with two framing slugs.** Not checked: the realignment, how a refusal is reported, and a merged branch being deleted only by a landing on its own slug. These are prose rules, and nothing here can run them. A person should:
  1. land two framing slugs against a GitHub test repository;
  2. merge one of them by hand;
  3. watch the next landing on the other slug.
- **Log rows written in a real run.** Not checked: that `/po-orchestrator` actually writes rows for the track choice, the implementation details and the answers given without asking, and does so at "Pull request ready". The tests only check that the text is present. A person should run it on a `pr` story with an effective `human` and inspect `docs/decisions-log.md`.
- **Installed copies.** `.claude/commands/` and `.polype/` keep the old wording until a reinstall. A person should refresh them after the ship.
- **Full suite.** I did not rerun it. I relied on the `po-run` record (exit 0 on matching code) and ran only the focused files during the bites.

Max severity: minor
Ship allowed: yes
