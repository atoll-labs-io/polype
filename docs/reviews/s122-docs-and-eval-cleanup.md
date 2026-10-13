# Review — s122-docs-and-eval-cleanup

Diff reviewed: `git diff main...story/s122-docs-and-eval-cleanup`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 650e8dc4481c29a938cad8579ca70e6cdac382fc

## When blocked
Not blocked.

## Ownership
I listed the diff with `git diff --name-only main...story/s122-docs-and-eval-cleanup` (13 paths) and checked each one against the `Owns` line at `docs/stories.md:1882`.
- [x] Every path is inside `Owns`: `bin/po-eval`, `docs/installation.md`, `evals/cases/rebuilt-helper.sh`, `method/AGENTS.md`, `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/hooks/po-gate.sh`, `tests/docs-and-eval-cleanup.test.sh`, `tests/install.test.sh`, `tests/rebuilt-helper-single-defect.test.sh`. The story's own `docs/research|plans|verif/s122-docs-and-eval-cleanup.md` are in scope by construction. `tests/resume.test.sh` is owned but not touched, as the plan requires.
- [x] Nothing is outside `Owns`.
- [x] Nothing falls inside another running story's `Owns`: `git worktree list` shows no other story worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s122-docs-and-eval-cleanup` passes (exit 0), so I reused the record: `bash tests/run.sh` exited 0. The project has no type check (`Typecheck: —`), no E2E and no build. I read the record's "Not proven here" section, and it is carried into Not verified below.
- [x] `po-gate qa-current` is not required: `QA stage: —` and the story's `Surface` is `—`.

## Plan
- [x] All 9 tasks are present and match the diff, including task 7 (the `/po-status` review bullet, which the lead's note puts in scope). There is no change the plan did not ask for.
- [x] Run interdicts, checked one by one:
  - The diff does not touch `tests/drive.test.sh`, `short-subject-shipped.test.sh`, `reuse-ladder-eval.test.sh`, `ship.test.sh`, `no-claude-md.test.sh`, `resume.test.sh`, `evals/lib.sh`, `evals/cases/missing-tenant-filter.sh`, `method/commands/po-ship.md`, `method/hooks/po-session.sh`, any ADR or `docs/decisions-log.md`.
  - It does not touch the installed copies (root `AGENTS.md`, `.claude/`, `.polype/`).
  - In `bin/po-eval`, only the final message changed. `drift_check` still runs and still `exit 2`s under `--control`.
  - In `po-gate.sh`, only comment lines changed.

## References
- [x] Every reference I opened exists:
  - `$control` is set at `bin/po-eval:160/167`.
  - `$cfg` is local to `drift_check` at `:65`.
  - The gate's two status checks (`paired_value` + `lstatus`) at `method/hooks/po-gate.sh:68-71` match the new Law 3 row and the `po-drive.md:146` text word for word.
  - `no_story_has_a_screen` at `method/hooks/po-session.sh:54-62` requires stories to exist, each with a `Surface` line and none of them `screen`. The new `po-status.md:21` bullet says exactly that.
  - ADR-0086 exists and supersedes ADR-0073.
  - `docs/decisions-log.md:40` records the owner's `CLAUDE.local.md` decision that `installation.md` now cites.
- [x] One value did not hold up exactly: the `installation.md:9-11` wording about which files mask `AGENTS.md` (see Findings).

## Rules
- [x] The `AGENTS.md` conventions are respected: method text is in English, docs are in French, and the test file is named after the story slug with one function per criterion.
- [x] No accepted ADR is contradicted. The new rows follow ADR-0086 and the gate's actual behaviour.

## Tests
- [x] Floor: `po-gate floor-guard s122-docs-and-eval-cleanup main` gives exit 0, so nothing was lowered. Narrowing `test_demo_app_unchanged` is what the criterion `recipe_plan_counts_three_tests` and plan task 4 ask for.
- [x] The assertions pin down each criterion, both the phrase that was added and the phrase that was removed. None of the six empty test shapes appears. The drift test exercises both modes through the fake-`claude` harness, with zero model calls.
- [x] 7 new tests, 1 renamed, 1 narrowed, within `Test budget` 25.
- [x] Bite 1: I flipped `[ "$control" = yes ]` to `= nope` in `bin/po-eval:84`. `docs-and-eval-cleanup.test.sh` then had 1 failing test (`drift_message_fits_the_mode`). Undone; `git diff --exit-code bin/po-eval` is clean.
- [x] Bite 2: I put the old `po-drive.md:64` row back ("refuses its `Reviewed tree:`"). Running `docs-and-eval-cleanup.test.sh` and `drive.test.sh` gave 1 failing test (`drive_resumes_a_review_the_gate_refuses`). Undone; `git diff --exit-code method/commands/po-drive.md` is clean.
- [x] Tests the story made useless are gone: the archive-story and recipe-count checks were removed from `test_demo_app_unchanged`, as planned.

## Neighbours
- [x] I read the other places that describe the ship gate:
  - `method/commands/po-ship.md:18` already states both status checks.
  - `method/commands/po-review.md:36` and `method/agents/reviewer.md:27,51` speak only of the tree, which is correct in their context.
  - In `/po-drive` `## Resuming`, the `Review status: blocked` + `/po-qa` row (`:62`) still sits above the widened row (`:64`), so the first-match order holds.
  - No other file references the old install test name.

## Lenses
Lenses run: none. The diff contains no auth/route/upload paths, no migration, no lockfile or manifest, and no server-side query code.
- [x] There are no lens findings.

## Findings
- minor — `docs/installation.md:9-11` — "Claude Code ne lit `AGENTS.md` que tant qu'il n'en existe pas" names only `CLAUDE.md` as what masks `AGENTS.md`. ADR-0086 (Context) says a `CLAUDE.local.md` masks it as well. The pronoun "en" is also ambiguous. Suggested wording: "…que tant qu'aucun `CLAUDE.md` ni `CLAUDE.local.md` n'existe".
- minor — `tests/docs-and-eval-cleanup.test.sh` (`test_status_design_system_matches_session`) — it asserts two strings in `method/hooks/po-session.sh`, a file this diff does not change. These assertions guard against drift in a neighbour, not this story's rule. They are harmless, but they mean the test can fail for another story's change.

## Not verified
- I did not run `bin/po-eval` against a real model. Both arms were exercised only through the fake `claude` of the test harness. A person who wants to see the `--control` drift message in real use should run `bin/po-eval --control --model <m> rebuilt-helper` with a deliberately drifted `~/.claude/agents/reviewer.md`. That is a paid call.
- The resume rows of `/po-drive` and the review bullet of `/po-status` are method text that an agent reads. The tests check the wording, not a driver resuming a lane whose favourable review has no `Review status:`. To cover it, a person should run `/po-drive status` on a story whose review holds `Ship allowed: yes` with no `Review status:` line, and confirm that it routes to review rather than to ship.
- The installed copies (root `AGENTS.md`, `.polype/hooks/po-gate.sh`) are not refreshed on this branch. The lead must refresh them after ship, as the plan's "Done when" says.
- There is no type check, E2E or build in this project (`Typecheck: —`, `E2E: —`, `Build: —`), so none was run.
- The date of the owner's `CLAUDE.local.md` decision is unsettled: the story says 2026-10-14, `docs/decisions-log.md:40` says 2026-10-13. The doc deliberately cites the log without a date. A person should correct whichever source is wrong.

Max severity: minor
Ship allowed: yes

---

# Review — s122-docs-and-eval-cleanup

Diff reviewed: `git diff main...story/s122-docs-and-eval-cleanup`, by a reviewer that did not write it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: 2e35e9dcb274eddee0da8b97e05e3ba46e2431e5

## When blocked
Not blocked.

## Ownership
I listed the diff with `git diff --name-only main...story/s122-docs-and-eval-cleanup` (14 paths) and checked each one against `docs/stories.md:1882`.
- [x] Every path is inside `Owns`: `bin/po-eval`, `docs/installation.md`, `evals/cases/rebuilt-helper.sh`, `method/AGENTS.md`, `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/hooks/po-gate.sh`, `tests/docs-and-eval-cleanup.test.sh`, `tests/install.test.sh`, `tests/rebuilt-helper-single-defect.test.sh`.
- [x] The story's own `docs/research|plans|verif|reviews/s122-docs-and-eval-cleanup.md` are in scope by construction.
- [x] Nothing is outside `Owns`.
- [x] Nothing falls in another running story's `Owns`. `git worktree list` shows only the root and this worktree. The two `s122:` commits on `main` (550fa73, 38b3fbf) only change `docs/stories.md`.

## Evidence reused
- [x] `po-gate verif-current s122-docs-and-eval-cleanup` passes (exit 0). The last `Unit suite` row (`bash tests/run.sh`, exit 0) covers the current code outside `docs/`, so I reused it and did not rerun the suite.
- [x] Since the loop-0 tree `650e8dc…`, the only code change outside `docs/` is two removed lines in `tests/docs-and-eval-cleanup.test.sh`. The other fix-run change is in `docs/installation.md`.
- [x] The project has no type check, E2E or build (`Typecheck: —`, `E2E: —`, `Build: —`), so none was run.
- [x] QA is not required: `QA stage: —` and `Surface: —`.

## Plan
- [x] All 9 tasks are in the diff, as the loop-0 review found.
- [x] The fix commit `6c17d3d` handles the two loop-0 minors and changes nothing else:
  - `installation.md:9-11` now names both `CLAUDE.md` and `CLAUDE.local.md` as masking `AGENTS.md`.
  - The two `po-session.sh` assertions are gone from `test_status_design_system_matches_session`.
- [x] The run interdicts hold:
  - `po-gate.sh`: only comment lines changed.
  - `bin/po-eval`: only the final drift message changed, and it still `exit 2`s under `--control`.
  - The diff does not touch `docs/decisions-log.md`, any ADR or the installed copies.

## References
- [x] The new masking sentence matches `docs/decisions/ADR-0086-l-installeur-absorbe-le-claude-md-dans-agents-local-md.md:14`: "ne lit `AGENTS.md` que si aucun `CLAUDE.md` ni `CLAUDE.local.md` n'existe".
- [x] The Law 3 row and the `po-drive.md:146` text match `ship_allowed` in `method/hooks/po-gate.sh:62-77`. The gate checks two statuses: `pstatus` (the status paired with the verdict) and `lstatus` (the file's last `Review status:` line).
- [x] The `po-status.md:21` rule matches `method/hooks/po-session.sh:89`: missing design system, stories present, and `no_story_has_a_screen`.
- [x] `docs/decisions-log.md:40` (s115 ship row) records "the owner approved absorbing both files", which is what `installation.md` cites.
  - Per the lead, the decision itself was taken on 2026-10-14. The row's 2026-10-13 is the s115 ship that raised the question, so the story date and the log do not contradict each other.

## Rules
- [x] Method text is in English and docs are in French.
- [x] There is one test function per criterion, named after it.
- [x] No accepted ADR is contradicted.

## Tests
- [x] Floor: `po-gate floor-guard s122-docs-and-eval-cleanup main` exits 0.
- [x] None of the six empty test shapes appears.
- [x] Budget: 7 new tests, 1 renamed, 1 narrowed, within `Test budget` 25.
- [x] Bite 1: I flipped the `--control` branch of the drift message (`bin/po-eval`, `if [ "$control" = yes ]` → `= nope`, that line only) and ran `docs-and-eval-cleanup.test.sh`. 1 test failed (`drift_message_fits_the_mode`). Undone; `git diff --exit-code bin/po-eval` is clean.
- [x] Bite 2: I put back the loop-0 wording of `docs/installation.md` (the commit 94f13c3 version, without `CLAUDE.local.md` in the masking clause) and ran `docs-and-eval-cleanup.test.sh`, `install.test.sh` and `no-claude-md.test.sh`. 0 tests failed, so the fix-run wording is not guarded (see Findings). Undone; `git diff --exit-code docs/installation.md` is clean.
- [x] The worktree is clean (`git status --porcelain` is empty).

## Neighbours
- [x] `installation.md:195-196` still says "tant qu'un `CLAUDE.md` existe… Claude Code le lit à la place d'`AGENTS.md`". That line is unchanged context and stays true.
- [x] The other places that describe the ship gate were checked at loop 0 and are untouched since.

## Lenses
Lenses run: none. There are no auth, route or upload paths, no migration, no lockfile or manifest, and no server-side query code.

## Findings
- minor — `docs/installation.md:11`: "l'installeur absorbe celui qu'il trouve" refers back, in the singular, to two files ("ni `CLAUDE.md` ni `CLAUDE.local.md`"). The installer absorbs both when both exist, so "ceux qu'il trouve" would be accurate. `tests/docs-and-eval-cleanup.test.sh:16` pins the singular phrase `celui qu'il trouve (ADR-0086)`, so the test would have to change along with it.
- minor — `docs/installation.md:9-11`: no test guards the loop-0 correction that `CLAUDE.local.md` also masks `AGENTS.md`. Putting back the old wording failed nothing (bite 2). This is prose outside the story's criteria, so it is noted rather than required.

## Not verified
- I did not run `bin/po-eval` against a real model. The drift message was only exercised through the fake `claude` of the test harness. To see it for real, a person should run `bin/po-eval --control --model <m> rebuilt-helper` with a deliberately drifted `~/.claude/agents/reviewer.md`. That is a paid call.
- The resume row of `/po-drive` and the review bullet of `/po-status` are method text read by an agent. The tests check the wording, not a driver acting on it. To cover it, a person should run `/po-drive status` on a story whose review holds `Ship allowed: yes` with no `Review status:` line, and confirm it routes to review rather than to ship.
- The installed copies (root `AGENTS.md`, `.polype/hooks/po-gate.sh`) are not refreshed on this branch. The lead must refresh them after ship, as the plan's "Done when" says.
- The project has no type check, E2E or build, so none was run.
- `docs/decisions-log.md` carries no row dated 2026-10-14 for the owner's `CLAUDE.local.md` decision. The approval only appears inside the 2026-10-13 s115 ship row. If a dated record is wanted, a person should add one. This story's run interdicts forbid touching the log.

Max severity: minor
Ship allowed: yes

---

# Review — s122-docs-and-eval-cleanup

Diff reviewed: `git diff main...story/s122-docs-and-eval-cleanup`, by a reviewer that did not write it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 2
Reviewed tree: c3e4ad6dccf5ddfd9764f4550f9e977d5b69dc44

## When blocked
Not blocked.

## Ownership
I listed the diff with `git diff --name-status main...story/s122-docs-and-eval-cleanup` (14 paths) and checked each one against the `Owns` line at `docs/stories.md:1882`.
- [x] Every code path is inside `Owns`: `bin/po-eval`, `docs/installation.md`, `evals/cases/rebuilt-helper.sh`, `method/AGENTS.md`, `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/hooks/po-gate.sh`, `tests/docs-and-eval-cleanup.test.sh`, `tests/install.test.sh`, `tests/rebuilt-helper-single-defect.test.sh`.
- [x] The story's own `docs/research|plans|verif|reviews/s122-docs-and-eval-cleanup.md` are in scope by construction.
- [x] Nothing falls inside another running story's `Owns`. `git worktree list` shows only the root (`main`) and this worktree.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s122-docs-and-eval-cleanup` exits 0, both when I started and again before answering. `Verification mode: record`, so I reused the last `Unit suite` row (`bash tests/run.sh`, exit 0) and did not rerun the full suite.
- [x] The project has no type check, no E2E and no build (`Typecheck: —`, `E2E: —`, `Build: —`), so none was run.
- [x] I read the record's "Not proven here" section; its items are carried into Not verified below.
- [x] QA is not required: `QA stage: —` and the story's `Surface` is `—`.
- [x] I ran `bash tests/run.sh docs-and-eval-cleanup.test.sh install.test.sh` only as the baseline for the bites: 19 passed, 0 failed.

## Plan
- [x] All 9 tasks are in the diff, as the loop-0 and loop-1 reviews found.
- [x] Fix run 2 (`9146fee`) handles loop 1's two minors and changes nothing else:
  - `docs/installation.md:11` now reads "absorbe ceux qu'il trouve", in the plural.
  - `tests/docs-and-eval-cleanup.test.sh:15-16` pins the plural phrase and adds a check on "ni `CLAUDE.local.md` : Claude Code ne lit", which guards the loop-0 correction.
- [x] The run interdicts hold:
  - The diff does not touch `docs/decisions-log.md`, any ADR or the installed copies.
  - In `po-gate.sh`, only comment lines changed.
  - In `bin/po-eval`, only the drift message at `:84` changed, and the function still `exit 2`s under `--control`.

## References
- [x] I re-read `ship_allowed` in `method/hooks/po-gate.sh:61-77`. It refuses for a missing review, a verdict that is not `yes`, a paired or last `Review status:` that is not `complete`, or a missing or stale `Reviewed tree:`.
- [x] Those checks agree with the new Law 3 row, the widened `po-drive.md:64` row ("whatever the reason"), the `po-drive.md:146` ships text and the `po-status.md:30` bullet.
- [x] The masking sentence in `installation.md:9-11` agrees with ADR-0086, as loop 1 already confirmed.

## Rules
- [x] Method text is in English and docs are in French.
- [x] There is one test function per criterion, named after it.
- [x] No accepted ADR is contradicted.

## Tests
- [x] Floor: `po-gate floor-guard s122-docs-and-eval-cleanup main` exits 0.
- [x] None of the six kinds of test that prove nothing appears.
- [x] Budget: 7 new tests, 1 renamed and 1 narrowed, within `Test budget` 25.
- [x] Bite 1: I dropped "ni `CLAUDE.local.md`" from `installation.md:10` and ran `docs-and-eval-cleanup.test.sh`. 1 test failed (`installation_cites_adr_0086`). Undone; `git diff --exit-code docs/installation.md` is clean. The loop-1 finding that this wording was unguarded is closed.
- [x] Bite 2: I put back "celui qu'il trouve" in `installation.md:11`. 1 test failed (`installation_cites_adr_0086`). Undone; `git diff --exit-code` is clean.
- [x] Bite 3: I flipped `bin/po-eval:84` from `= yes` to `= nope`, on that line only. 1 test failed (`drift_message_fits_the_mode`). Undone; `git diff --exit-code bin/po-eval` is clean.
  - My first attempt at this bite used a global sed that flipped all 5 `$control` tests in the file. I undid it, checked it was clean and redid it on line 84 only. The count above comes from that precise run.
- [x] The worktree is clean (`git status --porcelain` is empty).

## Neighbours
- [x] `installation.md:195-196` ("tant qu'un `CLAUDE.md` existe… à la place d'`AGENTS.md`") is unchanged context and still true.
- [x] The other places that describe the ship gate (`po-ship.md`, `po-review.md`, `reviewer.md`) were checked at loop 0 and are untouched since.

## Lenses
Lenses run: none. There are no auth, route or upload paths, no migration, no lockfile or manifest, and no server-side query code.

## Findings
None.

## Not verified
- I did not run `bin/po-eval` against a real model. The drift message was only exercised through the fake `claude` of the test harness. To see it in real use, a person should run `bin/po-eval --control --model <m> rebuilt-helper` with a deliberately drifted `~/.claude/agents/reviewer.md`. That is a paid call.
- The resume row of `/po-drive` and the review bullet of `/po-status` are method text that an agent reads. The tests check the wording, not a driver acting on it. To cover it, a person should run `/po-drive status` on a story whose review has `Ship allowed: yes` but no `Review status:` line, and confirm it routes to review rather than to the ship.
- The installed copies (root `AGENTS.md`, `.polype/hooks/po-gate.sh`) are not refreshed on this branch. The lead refreshes them after ship, as the plan's "Done when" says.
- The project has no type check, E2E or build, so none was run.
- `docs/decisions-log.md` has no row dated 2026-10-14 for the owner's `CLAUDE.local.md` decision. The lead says the date is settled and will log it; this story's run interdicts forbid touching the log.

Max severity: none
Ship allowed: yes
