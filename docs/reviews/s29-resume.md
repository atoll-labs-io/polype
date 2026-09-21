# Review — s29-resume

Diff reviewed: `git diff m3-flotte...story/s29-resume`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s29-resume` → passes (record `Tree: 01ddd39…` equals HEAD `a6d6542` outside `docs/`), so `docs/verif/s29-resume.md` is reused for the unit suite (154 passed) and for `bash bin/po-lint` (exit 0). `Verification mode: record`. `Typecheck: —`, `Build: —`, `E2E: —`: the project declares none and none was substituted. `po-gate plan-validated s29-resume` also passes.
- I ran `bash tests/run.sh resume.test.sh drive.test.sh` only as the baseline and the mutation runs of the bite step (8 passed at baseline).

## Plan
- [x] Task 1 — `## Resuming` added at `method/commands/po-drive.md:39-58`, between `## The ready set` and `## A wave`, with the seven-row table and the two safety rules the plan dictated.
- [x] Task 2 — orphan check widened to the path axis at `:65-67`; the phrases `tests/drive.test.sh` pins (`You prepare each lane's worktree yourself`, `git worktree add -b story/<id>`) are untouched.
- [x] Task 3 — `## Report` extended at `:94,96`; the side-effect clause for `status` now also forbids writing `docs/reviews/<id>.md` and running a gate that could change a file.
- [x] Task 4 — `tests/resume.test.sh`, three functions named exactly after the three acceptance criteria, shaped like `tests/drive.test.sh` (local `section_of`/`holds`, `require_file` from `tests/lib.sh`).
- [x] Task 5 — suite and lint recorded.
- Nothing outside the plan: the commit touches exactly `method/commands/po-drive.md`, `tests/resume.test.sh` and the story's own three `docs/` files.
- Run interdicts, one by one: `docs/parite-killer-saas.md` untouched (D17 is s31-fleet-wiring's, confirmed at `docs/stories.md:466-467`) · `method/AGENTS.md`, `method/commands/po-help.md`, `method/commands/po-status.md` untouched · `method/templates/agents-local.md` untouched, and every backticked setting in the new prose (`Worktree root`, `Max attempts`, `Target branch`) is already on the `Reads settings:` line at `:14` · `tests/drive.test.sh` untouched · `.claude/` and `.polype/` untouched · no literal `subagent_type: <name>` added inside `## A wave` (`test_drive_dispatches_lanes_in_one_message` stays green) · no source file outside the two owned paths.

## References
- [x] `method/commands/po-review.md` exists and `:25` says what the new prose attributes to it (previous `Fix loop:` + 1, 0 when there is none) — the table row `a fix run, at loop `Fix loop:` + 1` matches both it and the pre-existing `:84` ("the loop number raised by one"), and "attempts spent = the `Fix loop:` value" agrees with `A story gets at most `Max attempts` fix runs`.
- [x] `po-gate plan-validated` and `po-gate verif-current` both exist (`method/hooks/po-gate.sh:18-23,35-47`) and behave as the table claims; `verif_current` really is the record/stale discriminator.
- [x] `git worktree list --porcelain` and `git rev-parse --abbrev-ref HEAD` produce what the orphan clause relies on (checked live in this worktree).
- [x] `/po-status`'s derivation (`method/commands/po-status.md:22-31`) covers every state the table names, so "the derivation above, extended" is accurate and does not contradict `:28`.
- [x] `$METHOD`, `fail`, `require_file` all come from `tests/lib.sh:6,11,41`; `tests/run.sh:6` globs `*.test.sh`, so the new file is picked up.
- [x] No value that only looks right: no default, limit or status code is introduced.

## Rules
- [x] `AGENTS.md` conventions respected: method file in English, `Reads settings:` unchanged and complete, commands referred to by path, commit message in English with no co-author trailer, no `.env` file in the diff, research 52 lines and plan 80 lines (within the caps).
- [x] The diff stays inside the story's `Owns` (`method/commands/po-drive.md`, `tests/resume.test.sh`) — the rule s28 just shipped.
- [x] No accepted ADR contradicted; ADR-0016 (driver dispatches, subagents write) and ADR-0012 (no red-first) are both honoured.

## Tests
- [x] Three phrase assertions, one per acceptance criterion, each scoped to the section that owns the rule; none of the six empty shapes (no self-run query, no impossible input, no swallowing `catch`, no fixture or mock at all).
- [x] 3 tests against `Test budget: 25`.
- [x] Bite — nine rules disabled one at a time, each run over `resume.test.sh drive.test.sh` only, each undone immediately:
  - table row 3 stripped of `po-gate verif-current` → 1 failing (`drive_resumes_from_what_exists`)
  - stale-record sentence (`:52`) deleted → 1 failing (same)
  - `Fix loop:` durability rule (`:56`) deleted → 1 failing (same)
  - `never replayed` rule (`:58`) deleted → 1 failing (same)
  - `## Resuming` moved after `## A wave` → 1 failing (same, on the ordering assertion)
  - orphan clause reverted to the pre-story branch-only wording (`:65`) → 1 failing (`drive_detects_an_orphan_worktree`)
  - never-repaired orphan sentence (`:67`) deleted → 1 failing (same)
  - `status` per-lane clause (`:96`) deleted → 1 failing (`drive_status_reports_lanes`)
  - new side-effect clause removed from `:94` → 1 failing (same)
  - all undone; `git diff --exit-code` and `git status --porcelain` clean at the end of the review.
- [x] No existing test modified, none made useless.

## Neighbours
- [x] The two other readers of `po-drive.md` — `tests/drive.test.sh` (five tests, including the `subagent_type` order grep at `:45-47`) and `tests/lint.test.sh` — pass at this tree; the sharpest trap named in the research is avoided.
- [x] `method/agents/planner.md` read as the consumer of the "resume at the plan" row (see finding 1). `method/commands/po-status.md` read as the derivation the section extends.

## Findings
- major — `method/commands/po-drive.md:45` (table row 2) vs `:58` and `:73`, against `method/agents/planner.md:37-39,50` — "research present, plan absent → the same stage, at the plan" is stated but nothing can carry it out. The only agent that writes a plan is `planner`; the dispatch step hands it "the story id and the absolute worktree path" and explicitly says "its research … is its own contract, which you do not restate", and `planner.md` has no clause about an existing `docs/research/<id>.md` — it writes research then plan. So a lane resuming at this row re-runs the research and overwrites the file that `:58` ("No research, plan, record or review is overwritten") forbids overwriting. The driver is left with two rules it cannot both obey. The fix belongs in `planner.md` or in the dispatch line, both outside this story's `Owns`, which is why the implementer could not have closed it here.
- major — `method/commands/po-drive.md:47-48` — rows 4 and 5 overlap and the table gives no precedence. A lane interrupted *after* a fix run (record current, and the previous blocked review still on disk with `Ship allowed: no`) matches row 5 under any reading, so the driver dispatches another fix run instead of the reviewer: the implementer stage is replayed — the exact thing `:58` forbids — and one `Max attempts` unit is burnt, pushing the story to a human handoff earlier than it should. Nothing in the section distinguishes a review older than the current record from one that is the latest artefact; the record's `Tree:` against the review would be a discriminator.
- minor — `method/commands/po-drive.md:46-47` — `po-gate verif-current <id>` and `po-gate plan-validated <id>` are written bare, but the hook resolves its own root from the current directory (`method/hooks/po-gate.sh:12`, `git rev-parse --show-toplevel`). Run from the repository root rather than from `<Worktree root><id>`, both answer about the wrong tree and refuse, sending a well-advanced lane back to an earlier stage. The lead sentence ("from the files of `<Worktree root><id>`") implies the right place and `po-status.md:29` uses the same bare form, so this is a phrasing risk, not a broken rule: `cd <Worktree root><id> && po-gate …` would remove it.
- minor — `method/commands/po-drive.md:40` vs `:65-67` — the derivation is required "before any subagent is dispatched", and the orphan check also happens before dispatch, but their order is unspecified. A story whose worktree is an orphan would have its stage derived from another branch's files and `status` would print that stage; the lane is dropped from the wave regardless, so the damage stops at a misleading line in the report.

## Not verified
- **That a driver actually resumes anything.** `/po-drive` is prose executed by an agent; the tests prove the clauses are present and worded as the story requires, nothing more. No run of `/po-drive` on an interrupted fleet was performed, and this repository has no harness for one. A person should drive a real fleet, interrupt it at each of the seven table rows — in particular after a fix run, which is finding 2 — and check where each lane resumes.
- **The full suite and the method lint were not rerun**: reused from the record, which `po-gate verif-current` proves current. I ran only `resume.test.sh` and `drive.test.sh`, the two files the bite step needed.
- **Killer SaaS overlap** (`tests/overlap.test.sh`): taken from the record, which states the sources were present at the default path; I did not run `bin/ks-overlap` myself. If that matters, rerun it with the sources in place before shipping.
- **No screen**: this story has no `docs/designs/s29-resume/`, no component and no token, so no design conformity was assessed.
- **The wiring of the fleet into the rules, the help and `/po-status`** is out of this diff on purpose (s31-fleet-wiring owns those files and matrix line D17 stays `partiel`). Nobody has yet checked that the resume table and `/po-status`'s derivation stay in step once s31 edits the latter.

Max severity: major
Ship allowed: yes
