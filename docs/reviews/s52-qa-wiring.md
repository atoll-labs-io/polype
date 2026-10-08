# Review — s52-qa-wiring

Reviewed tree: e2f26bd5ed2a90103e0d12b717aa27deb5ec589a
Review status: complete
Fix loop: 0
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s52-qa-wiring (branch `story/s52-qa-wiring`, one commit 24187df)

The code is ready to ship. I found no critical defect. There is one major finding about how a QA-blocked review gets routed, and two minor findings.

## Ownership
I listed the diff with `git diff --name-only main...story/s52-qa-wiring`.
- [x] All 9 code and test paths are inside `Owns`: `method/AGENTS.md`, `method/hooks/po-gate.sh`, `method/commands/po-qa.md`, `method/agents/reviewer.md`, `method/agents/implementer.md`, `method/skills/review-antihallu/SKILL.md`, `method/templates/review.md`, `tests/qa.test.sh`, `tests/qa-gate.test.sh`.
- [x] `docs/research/`, `docs/plans/` and `docs/verif/s52-qa-wiring.md` are the story's own pipeline evidence, so they are in scope.
- [ ] `docs/decisions/ADR-0029-po-qa-committe-les-preuves-qa.md` is outside `Owns`. Law 6 requires an ADR for this structural choice, so this is a gap in `Owns`, not a breach by the implementer: minor (m1).
- [x] No overlap with another running story. `git worktree list` shows only main and this worktree. s53 and s54 share paths with this story but have no worktree.

## Evidence reused
- [x] `po-gate verif-current s52-qa-wiring` exits 0. The record's tree 78b01e78… equals HEAD outside `docs/`, so I reused it: 274 tests passed, `bin/po-lint` exit 0. The project has no type check (`Typecheck: —`), no E2E and no build command. I read its "Not proven here" section.
- [x] `po-gate qa-current` is not required: this story has no screen and `QA stage: —`.

## Plan
- [x] Tasks 1–7 are all in the diff, matching the plan. I found no change the plan did not ask for.
- [x] Run interdicts hold:
  - None of the forbidden files is in the diff (po-bounds, qa agent and template, po-ship, po-review, agents-local, orchestrator, drive, status, help, README, `.claude/`, `.polype/`, root `AGENTS.md`).
  - `qa_current` reads no setting.
  - The six-step numbering of the review skill is unchanged.
  - The only changed existing test is `tests/qa.test.sh:49` (`lacks_tool Bash` → `lacks_tool Edit`). The plan justifies it and the story note asks for it.
- [x] Consistent with ADR-0029 and ADR-0026: the qa agent and its hook are untouched.

## References checked
- [x] `qa_current` calls `top`, `refuse`, `first_hash`, `tree_exists` and `code_matches`. All exist in `po-gate.sh:19-37` with matching signatures. The new subcommand is in both the `case` and the header.
- [x] The test helpers `scratch_repo`, `frontmatter`, `settings_read_by`, `needs_tool`, `lacks_tool` and `contains` exist in `tests/lib.sh`.
- [x] `QA stage` exists in `method/templates/agents-local.md:21,49`.
- [x] `docs/qa/<id>/report.md` and the `Tree:` then `QA status: <complete | blocked>` lines match `method/agents/qa.md:40,48` and `method/templates/qa.md:28-29`.
- [x] The verified, probable and unverified statuses the skill uses match the status rule in `templates/qa.md`.

## Tests
- [x] `po-gate floor-guard s52-qa-wiring main` exits 0: nothing was lowered.
- [x] Budget: 7 new tests plus 1 changed, against a budget of 25. None of the six kinds of test that prove nothing: the gate tests run the real script on a throwaway repo, and the fixtures carry no identifiers that would answer for the check under test.
- [x] Bite: I disabled two rules in turn and ran only `bash tests/run.sh qa-gate.test.sh` each time.
  1. Last status line changed to first (`tail -n 1` → `head -n 1` in `qa_current`): 1 test failed (`qa_current_reads_the_last_status`: "an earlier complete status outweighed the final blocked one").
  2. Code match removed (`code_matches "$tree"` → `true` in `qa_current`): 1 test failed (`po_gate_qa_current`: "report accepted after the code moved").
  - After each one, `git diff --exit-code method/hooks/po-gate.sh` exited 0. The final `git status --porcelain` is empty.
- [x] The plan's main risk (`## The pivot`) holds: I replayed the pre-commit hook in a scratch repo. On a `story/s01-a` branch whose plan is `validated: no`, a commit containing only `docs/qa/s01-a/` with a 4000-byte random binary capture passed. `git commit -m … -- docs/qa/s01-a/` left a modified `src/a` out of the commit, as the plan says.

## Values
- [x] The status regex `^QA status:[[:space:]]*complete[[:space:]]*$` accepts only the bare value. It rejects the template placeholder `<complete | blocked>` and `complete, mostly`. Only a full 40-hex `Tree:` counts, through the existing `first_hash`.

## Neighbours
- `bin/po-lint:142-146` flags a "cannot edit files or run a shell" description; the new `po-qa.md` description avoids that phrase, and the record shows lint clean.
- `po-execute.md` keeps its own no-shell wording, which is correct for it.
- `po-review.md:38` and `po-orchestrator.md:61-63` route every blocked review to a fix run. See M1.

## Findings

### M1 (major): a review blocked by `qa-current` is sent to a fix run that cannot fix it
- Files:
  - `method/skills/review-antihallu/SKILL.md:27` sets `/po-qa <id>` as `Next action:`.
  - `method/commands/po-review.md:38` says "Run /po-execute <id> (fix run)" for any `Ship allowed: no`.
  - `method/commands/po-orchestrator.md:63` says "Blocked → back to stage 5 as a fix run".
- Problem: in a project with `QA stage: screens`, a screen story that has no current QA report gets a blocked review. Both callers then start the implementer in fix mode. The implementer has nothing to fix, and the new `implementer.md` text tells it not to stand in for QA. That uses up the two fix loops and hands the story to a person.
- It gets worse: every real fix commit makes the QA report stale again, so each later review blocks for the same reason.
- s57 will rewire the orchestrator and drive, but `po-review.md` is in neither s52's nor s57's `Owns`, so its message stays wrong even after s57.
- Damage is contained: it only affects projects that turned on `QA stage: screens`, and a person is told in the end.
- Fix: in s57 or a new story, route a review blocked by `qa-current` to `/po-qa`, not to a fix run, and add `po-review.md` to that story's `Owns`. Until then, do not refresh the installed method of a project that uses `QA stage: screens`.

### m1 (minor): ADR-0029 is outside `Owns`
- File: `docs/decisions/ADR-0029-po-qa-committe-les-preuves-qa.md`.
- Law 6 requires it ("Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`"), so the gap is in the story's `Owns`. The plan says so itself. Nothing to change in the code.

### m2 (minor): `qa-current` does not check that the report is committed
- File: `method/hooks/po-gate.sh:66-78`.
- The gate reads `docs/qa/<id>/report.md` from the working tree. If `/po-qa`'s evidence commit was refused and nobody noticed, an up-to-date report that was never committed still passes. The review then judges evidence that is not in the tree being reviewed, and the story's squash may not include it.
- ADR-0029 accepts this ("Neutral") and asks for it to be revisited with s57. I record it so s57 decides it.

## Not verified
- I did not run `/po-qa` in a real Claude Code session. I do not know whether Bash in `allowed-tools` stays limited to the three git commands the command names; only its text limits it, no hook does. **To cover:** a person runs `/po-qa` on a screen story with a browser tool and checks that exactly one commit, `<id>: QA evidence`, touching only `docs/qa/<id>/`, lands on `story/<id>`.
- No reviewer has been sent against a real screen story under `QA stage: screens`. I checked the skill's `qa-current` step by reading it, not by running it. **To cover:** a person runs `/po-review` on such a story with no report, then with a stale report, and checks that each review is blocked with `/po-qa <id>` as `Next action:`.
- I replayed the pre-commit hook through `po-gate pre-commit` directly, not through the installed `.polype/hooks/pre-commit` wrapper with `core.hooksPath` turned on.
- I did not rerun the full suite. I relied on the current record, as `Verification mode: record` allows.
- The project has no type check, no E2E and no build command (`—`).
- No screen in this story, so nothing visual to check.

Max severity: major
Ship allowed: yes
