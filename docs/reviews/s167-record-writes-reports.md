# Review — s167-record-writes-reports

[Story](../stories.md) · [Plan](../plans/s167-record-writes-reports.md) · [Verification](../verif/s167-record-writes-reports.md)

Diff reviewed: `git diff main...story/s167-record-writes-reports`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: b1a8917b6357b766bd3245f9f070de8f98e056e2

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s167-record-writes-reports`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`: `po/src/record/{mod,compose,gate}.rs` fall under `po/src/record/`. The five commands, `method/templates/review.md` and the five test files are each listed by name. `docs/research|plans|verif/s167-…` are pipeline evidence.
- [x] Outside `Owns` → none.
- [x] Inside another running story's `Owns` → none. `git worktree list` shows only main and this worktree. `tests/state-as-json.oracle.test.sh` is also in the `Owns` of s168, but s168 has no worktree, and s165 has already landed on main (f5ba595, the merge base).
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s167-record-writes-reports` → exit 0, record reused. `Tree: 118ba33…`. The last `Unit suite` row (`bash tests/run.sh`) exited 0 on the committed code. The first row exited 1, and the record explains it as a harness defect: `tests/readme-onboarding.test.sh` builds `po` from a clone of HEAD into the shared `CARGO_TARGET_DIR`. The project has no type check (`Typecheck: —`).
- [x] `po-gate qa-current` is not required: `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–8 are present and match `## The interface these tasks fix`:
  - every refusal, its exit code and its `written` flag
  - the header taken from the first two non-empty template lines, with links to missing targets dropped
  - the answer's own header stripped
  - the stamp, the oracle line and where it is inserted
  - atomic write, append for a review and a whole rewrite for QA
  - `--composed`
  - the edits to the five commands and the template
  - the three owned tests adjusted as task 7 lists
- [x] Each run interdict checked:
  - Nothing under `po/` changed outside `po/src/record/`; `Cargo.toml` and `Cargo.lock` are untouched.
  - `method/hooks/po-gate.sh`, `method/agents/`, `method/skills/`, `method/templates/qa.md`, `docs/interface-agent.md`, `.polype/` and the ADRs are untouched.
  - No test outside `Owns` changed. `state-as-json.oracle.test.sh` only loses `record` from the verb list.
  - `po-review.md` keeps the `findings-shape` Bash rule and has no bare Bash. `po-qa.md` has no Write or Edit.
  - `po record` runs only read-only `project::git` and the two gates. It never stages or commits.
  - No new dependency and no new ADR.
  - The oracle file's cksum `2236172868 10865` matches the plan.

## References
- [x] Every import, call and key was opened and confirmed:
  - `Project::find` and `project::git` (`po/src/project.rs:20,38`)
  - `output::reply`, `REFUSED` and `UNREADABLE` (`po/src/output.rs`)
  - the dispatch in `main.rs:25`
  - `po-gate.sh` `findings-shape`, which checks only the last block (`:98-131`); refusals go to stderr (`:40`)
  - `oracle-intact`
  - the install path `~/.claude/polype/po` (`method/AGENTS.md:151`, `docs/interface-agent.md:12`)
  - the opening lines of `templates/qa.md`, and `agents/qa.md:61`, which says the qa answer starts at its title
- [x] Values checked: exit codes 0, 1 and 2 match the plan's table and the `po` contract. The link line starts with `[Story](` in both templates.

## Rules
- [x] `AGENTS.md` conventions respected: method files are in English, the commit message is in English, and there is no co-author trailer.
- [x] No accepted ADR contradicted: the coordinator still records and the judging subagent still writes nothing (ADR-0102, ADR-0104).

## Tests
- [x] Oracle: `po-gate oracle-intact s167-record-writes-reports` → exit 0 (intact; `## Oracle changes` empty).
- [x] Floor: `po-gate floor-guard s167-record-writes-reports main` → 0, nothing lowered.
- [x] Assertions pin down the acceptance criteria. The oracle runs the real binary on a scratch git project that uses the method's own gate and templates. None of the six empty test shapes is present.
- [x] Within `Test budget`: 8 new tests out of 25.
- [x] Bite: 3 rules disabled, one at a time. After each, `git checkout -- po/src/record/mod.rs` and `git diff --exit-code` came back clean.
  - The `story/<id>` branch guard disabled (`if false && …`) → 1 failing test (`record_refuses_the_wrong_branch`).
  - The findings-shape gate run on `--composed` reports too → 1 failing test (`composed_report_is_not_checked`).
  - Findings-shape exit 1 treated as success → 1 failing test (`record_checks_the_shape`).
- [x] Tests made useless by the story are removed. The phrase assertions on the old heredoc and header prose are gone, as task 7 lists.

## Neighbours
- [x] Other readers of the report files were read, and nothing is broken:
  - `po/src/state/lanes.rs:277-297` reads the last `QA status:` and `Fix loop:`; the stamp lines do not disturb either.
  - `po-gate ship-allowed` and `findings-shape` read the last verdict block. A `Method version:` line sits before each block.
  - `bin/po-link-artifacts` skips files whose line after the title starts with `[Story](`.

## Lenses
Lenses run: security — `po record` writes a file whose path comes from a CLI argument (`<id>`). The id is refused when it contains `/`, starts with `.` or is empty, so the write stays under `docs/reviews/` or `docs/qa/<id>/` of the worktree. No finding.
- [x] Each lens finding graded on the scale above and listed under Findings.

## Findings
- minor — method/commands/po-review.md:9 — `/po-review` keeps the `Write` tool even though recording now goes only through `po record` and the command says "write nothing by hand" (line 38). This context never needs `Write` any more, and keeping it leaves open the hand-written path the story removes.
- minor — method/commands/po-review.md:38 — "a refusal with `"written": false` → stop, name `polype install`" sends every unwritten refusal to `polype install`. That includes `wrong-branch`, `unwritable` and `empty-answer`, for which reinstalling is not the remedy. `empty-answer` also exits 1, so it matches the "Exit 1 → dispatch the reviewer once more" rule at line 42 as well. The same over-broad remedy is at method/commands/po-qa.md:42 ("another refusal → stop and name `polype install`"). The stop itself is right in every case, so no damage is silent.

## Not verified
- I did not check whether the narrowed rule `Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" record review:*)` matches the command `/po-review` actually runs. That command starts with `cd <worktree> &&` and carries a heredoc, so it may raise a permission prompt. The plan accepts this, and the record lists it under "Not proven here". A person should run `/po-review` once on a real story and see whether a prompt appears.
- No live `/po-review`, `/po-qa`, `/po-orchestrator` or `/po-drive` run went through `po record`. The binary was exercised only on scratch projects. A person should watch the first fleet wave after this ships record one review and one QA report.
- `commands_call_po_record` and `resume_paths_reuse_the_report` are rules read by a model. I judged them by reading the diffs of the five commands; only their word counts are tested. They are candidates for a `po-eval` control arm (#208).
- I did not rerun the full suite; I relied on the record. The record also describes a harness defect outside `Owns`: `readme-onboarding.test.sh` builds `po` from HEAD into the shared target dir, so an uncommitted tree gives a false red. The lead should file it.
- This repository's installed `.polype/` still holds the old review template note until the next `bin/polype-dev-install`.

Max severity: minor
Ship allowed: yes
