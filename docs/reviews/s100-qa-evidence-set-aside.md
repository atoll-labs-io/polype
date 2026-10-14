# Review: s100-qa-evidence-set-aside

[Story](../stories.md) · [Plan](../plans/s100-qa-evidence-set-aside.md) · [Verification](../verif/s100-qa-evidence-set-aside.md)

Diff reviewed: `git diff main...story/s100-qa-evidence-set-aside`, by a reviewer that did not write it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 59154043dfc4eae6fc4c7a4f1e344ecc6ce67c9e

## When blocked
Does not apply.

## Ownership
Diff listed with `git diff --name-only main...story/s100-qa-evidence-set-aside` (5 code/test paths plus 3 docs files).
- [x] Every path is inside `Owns`. These four method files are listed by name: `method/agents/qa.md`, `method/skills/qa-drivers/{scenarios,scene,simulation}.md`. `tests/qa-evidence-set-aside.test.sh` is also listed. `docs/research|plans|verif/s100-…` are the story's own evidence. `tests/qa-contract-holds.test.sh` is owned but unchanged, as the plan's interdict requires.
- [x] Nothing falls inside another running story's `Owns`. The only other story worktree is s99-throwaway-zone-holds (not merged into `main`, `merge-base --is-ancestor` gives exit 1). It owns `method/hooks/po-bounds.sh`, `method/agents/implementer.md`, `tests/bounds-messages.test.sh` and `tests/throwaway-zone-holds.test.sh`, with no overlap.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s100-qa-evidence-set-aside` passes (exit 0), so the record is reused. `Unit suite` (`bash tests/run.sh`) and `Lint` (`bash bin/po-lint`) both have exit-0 rows on code matching `Tree: 7191f22…` outside `docs/`. The project has no type check command (`Typecheck: —`). "Not proven here" says two things are not proven: that a real `qa` subagent applies the rule, and real Godot or ROS 2 runs. Both are carried to Not verified below.
- [x] `po-gate qa-current`: not required, because `QA stage: —` and `Surface: —` mean the story does not go to QA.

## Plan
- [x] Tasks 1–6 are all present, and nothing in the diff is outside the plan. The set-aside sentence S is byte-identical in all four files, as the test asserts. The scene stop is plural, `quit()` is added after `save_png()`, and the recorder wait is bounded at 30 s, with a finding and SIGKILL when it runs out.
- [x] Each run interdict was checked:
  - Every existing test file has an empty diff.
  - `qa.md` changes only at line 49, and its frontmatter and line 44 are untouched.
  - `scenarios.md` changes only at line 12; lines 14 and 16 are unchanged.
  - `SKILL.md`, `browser.md`, `mobile-web.md`, `boilerplates/`, `method/hooks/`, the parity doc and `docs/decisions/` are untouched.
  - Nothing under `.claude/` or `.polype/` changed.
  - No `-uall` was added.

## References
- [x] Mode `qa` allows `git ls-files`: `method/hooks/po-bounds.sh:313` lists it in `QA_GIT_VERBS`, and `check_git_read` puts no restriction on its options.
- [x] I tested the semantics of S in a scratch repo, `/tmp/tmp.M3G6IFR327/r`:
  - At the first QA, `status --porcelain --ignored` collapses the evidence into `?? docs/qa/`. `ls-files --others --exclude-standard -- docs/qa/` then lists only `docs/qa/s1/report.md`, so the line is correctly set aside.
  - With a stray `docs/qa/stray.txt`, `ls-files` also lists the stray, so the line keeps blocking. Pivot point 2 holds.
- [x] Godot's `SceneTree.quit()` is the documented exit call for a `--script` `SceneTree`. I did not check it against 4.7.2 source; the plan already says so.

## Rules
- [x] `AGENTS.md` conventions are respected: the method text is in English and the bash test uses the `lib.sh` helpers.
- [x] No accepted ADR is contradicted. ADR-0059 (run on a copy) and ADR-0044 (ignored files kept out of the evidence) are consistent with S, and `--exclude-standard` agrees with ADR-0044.

## Tests
- [x] Floor: `po-gate floor-guard s100-qa-evidence-set-aside main` gives exit 0, so nothing was lowered.
- [x] The assertions pin the three criteria with phrases unique to their clauses, and none of the six empty test shapes appears. There are no fixtures or mocks; these are text-contract checks, as the project's convention requires.
- [x] 3 tests, well within the budget of 25.
- [x] Bite: each mutation was run on `tests/qa-evidence-set-aside.test.sh` (plus neighbours where noted), then undone and confirmed with `git diff --exit-code`:
  - **M1:** the consequence of the 60 s bound in `scenarios.md` flipped to `complete`, together with the qa.md no-driver line: 1 failing (`bounded_waits_bite`). The old `qa-contract-holds` tests stay green, which confirms the old gap is now covered only by the new file.
  - **M2:** the qa.md no-driver consequence alone flipped to `complete`: 1 failing (`bounded_waits_bite`).
  - **M3:** S removed from `scene.md`: 1 failing (`first_qa_sets_its_evidence_aside`).
  - **M4:** "wait at most 30 seconds of real time for it to exit" replaced with "wait for it to exit" in `simulation.md`: 0 failing across the s100, ros-simulation and scene-and-simulation test files (9 passed). See minor finding 1.
  - **M5:** `, then \`quit()\` so the engine exits…` removed from `scene.md`: 1 failing (`scene_and_recorder_stop_cleanly`).
- [x] The story makes no existing test useless. The weaker same-line checks of `qa-contract-holds.test.sh` are kept on purpose, per the plan's interdict.

## Neighbours
- [x] `scenarios.md:16` still says "the process group you started, and only that one". That is correct, because that driver starts one API process. `tests/scene-and-simulation-drivers.test.sh:13,54` still holds: `$SET_ASIDE` is kept, and its `lacks` targets `simulation.md`, which already used the plural. `browser.md` and `mobile-web.md` do not compare the state of the repository, so they need no S. `po-qa.md` runs no status comparison.

## Lenses
Lenses run: none. No security, migration, dependency or server-side paths or content are in the diff; it is method prose plus one bash test.

## Findings
- minor — `tests/qa-evidence-set-aside.test.sh:29-30`: no test pins the recorder wait's bound itself ("wait at most 30 seconds of real time for it to exit"). Rewording it back to an unbounded "wait for it to exit" keeps the whole suite green (M4, 0 failures). The `lacks` check pins only one exact earlier wording. The pinned sentence "a recorder still running after 30 seconds is a finding" still implies the bound, which is why this is minor. Fix: pin `wait at most 30 seconds of real time`.
- minor — `method/skills/qa-drivers/simulation.md:30`: the 30 s real-time bound for the recorder has no measurement behind it, as pivot point 3 admits. A bound that is too short fails visibly: it becomes a finding, never a false `complete`. Listed only as an unconfirmed value.

## Not verified
- **Whether a real `qa` subagent applies S at a project's first QA.** No QA was run. A person should run `/po-qa` on a story with a screen or a surface in a project that has no `docs/qa/` yet, and confirm the walk does not end `blocked` on `?? docs/qa/`.
- **The Godot engine actually exits after `quit()` in a `--script` `SceneTree` under `xvfb-run`.** Godot is not installed here. A person should run one scene capture on the Godot profile and confirm that no engine process outlives its capture.
- **The ROS 2 recorder closes within 30 s on SIGINT, and SIGKILL leaves a usable finding.** ROS 2 is not available here, so no real walk was run. A person should run one walk on the jazzy profile.
- **The full suite and lint.** I did not rerun them; I relied on the record's `po-run` rows, which the gate checks. I ran only the focused test files listed above.

Max severity: minor
Ship allowed: yes
