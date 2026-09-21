---
track: flow
validated: yes
---
# Plan (short track) — s28-ownership

## Verified facts

- `method/skills/review-antihallu/SKILL.md:9-30` holds the whole procedure: `## Six steps, all of them, in this order`, then six bold-numbered steps. Step 2 (`:19`) is the first that reads the diff (« Open everything the diff refers to »). The scope check must sit above it.
- `tests/review.test.sh:29-30` counts the steps with `grep -cE '^\*\*[1-6]\. '` and demands exactly 6. That file is **not** in this story's `Owns`, so the new check must not be a seventh numbered step; it becomes a section placed before `## Six steps`.
- `method/agents/reviewer.md:24` points at « step 4 of the procedure » by number. Numbering the scope check as step 1 would shift bite proof to step 5 and falsify that sentence — another reason the check goes before the numbered list, not into it.
- `method/agents/reviewer.md:15` announces the skill as « The procedure — six steps and the severity scale ». The announcement must name the scope check too; that line is inside `Owns`.
- `method/agents/reviewer.md:18` (`## Inputs`) lists what the reviewer reads: plan, research, `AGENTS.md`, ADRs, design files. `docs/stories.md` is absent, yet the `Owns` lines live there and nowhere else — the reviewer cannot check a scope it never reads.
- `Owns` semantics are already settled and must not be re-invented: `method/skills/stories-review/SKILL.md:25` — « a directory owned by one story covers every path beneath it » — and `method/skills/agentic-stories/SKILL.md:21`.
- `method/commands/po-drive.md:35` states the driver's side of the same rule (`Owns` paths disjoint from the running lanes). The reviewer's check is the *a posteriori* half; the wording must agree with it. `po-drive.md` is owned by s29/s30 — read only.
- **A story's commit legitimately contains files its `Owns` never lists.** `git show --stat 91ecdfb` (s27): `docs/plans/s27-drive.md`, `docs/research/…`, `docs/reviews/…`, `docs/verif/…` — none of them in s27's `Owns` (`docs/stories.md:398`) — plus `docs/parite-killer-saas.md`, required by the `Matrice` convention of `AGENTS.local.md`. Without both carve-outs the check fires on every story of this repository.
- s28's own `Owns` does **not** list `docs/parite-killer-saas.md`; s31 (`docs/stories.md`, `### s31-fleet-wiring`) owns it and names A02 and D09 among the statuses it updates. This story leaves the matrix alone.
- Which stories are "running" is derivable with the reviewer's tools: `git worktree list` plus `git branch --list 'story/*'`, the same source `/po-status` uses (`method/commands/po-status.md:22`). The reviewer has Bash, Read, Grep, Glob (`method/agents/reviewer.md:4`).
- `tests/lib.sh:43` `contains` is exact and case-sensitive (`grep -qF`); `tests/lib.sh:41` `require_file`; `tests/lib.sh:29` `needs_tool`. `tests/drive.test.sh:8` shows the `section_of` awk helper used to pin an assertion inside one section — each test file defines its own copy.
- `bin/po-lint` rules are settings, tools and fail-closed (`bin/po-lint:74,106,147`); it does not parse skills, and `reviewer.md` keeps its tools and its `Reads settings:` line unchanged, so no lint rule is touched. `bash bin/po-lint` exits 0 today.
- Baseline: `bash tests/run.sh` → **149 passed, 0 failed**.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — the story changes a prompt, a skill and a test | absent — markdown and bash only, no data |
| New screen | absent — no interface named | absent — nothing rendered anywhere in the diff |
| Authorization or tenant scope | absent — no actor or permission named | absent — no role read by any touched file |
| API contract | absent — no interface between stories | absent — `Owns` already has its meaning fixed in `stories-review/SKILL.md:25`; nothing new is defined |
| New dependency | absent — no tool named | absent — `git worktree list` and `git branch` are already used by the method |

## Story

A story's diff must stay inside the paths its `Owns` declares, and the reviewer is where that is caught — so two lanes running side by side cannot silently edit the same file.

- `reviewer_checks_the_diff_against_owns` — the review compares the diff's files to the story's `Owns` paths; a file out of scope is a major finding, critical when it belongs to another story currently running.
- `review_procedure_places_the_ownership_step_first` — the scope check comes before the diff is read, because it decides what has to be read.

## Tasks

1. [x] In `method/skills/review-antihallu/SKILL.md`, add a section **before** `## Six steps, all of them, in this order`: the file list comes from `git diff --name-only <Target branch>...story/<id>`, each path is held against the story's `Owns` in `docs/stories.md` (a directory covers everything beneath it), and this comes first because it decides what the rest of the review reads.
   *Test that fails without it:* `test_review_procedure_places_the_ownership_step_first`.
2. [x] In that same section, write the two severities: out of `Owns` → **major**, named with the path and the `Owns` line it missed; → **critical** when that path is in another story's `Owns` and that story is running (its worktree in `git worktree list`, its `story/<id>` branch not merged into `Target branch`), because one of the two edits is lost at ship.
   *Test:* `test_reviewer_checks_the_diff_against_owns`.
3. [x] In that same section, write the two carve-outs and the missing case: this story's own pipeline evidence (`docs/research/<id>.md`, `docs/plans/<id>.md`, `docs/verif/<id>.md`, `docs/reviews/<id>.md`, `docs/designs/<id>/`) is in scope by construction, `Owns` never listing it; a path a written rule of `AGENTS.md` requires is not a breach by the implementer but a gap in the story's `Owns`, quoted and reported as minor; a story with no `Owns` line is reported as unverifiable scope, never as clean.
   *Test:* `test_reviewer_checks_the_diff_against_owns`.
4. [x] In `method/agents/reviewer.md`, add `docs/stories.md` to `## Inputs` as the source of the `Owns` lines, and amend line 15 so the announced procedure names the scope check alongside the six steps. Do not renumber anything; « step 4 » must stay true.
   *Test:* `test_reviewer_checks_the_diff_against_owns`.
5. [x] Write `tests/ownership.test.sh` with exactly the two functions named after the criteria, each using `section_of` to assert inside the new section rather than anywhere in the file, and the ordering test comparing line numbers of the new heading and of `## Six steps`.
   *Test:* itself — it fails on the current tree and passes after tasks 1-4.
6. [x] Run `bash tests/run.sh` (expect 151 passed, 0 failed) and `bash bin/po-lint` (expect exit 0), and record both in `docs/verif/s28-ownership.md`.

## Run interdicts

- `tests/review.test.sh` ends with an empty diff: its six-step count stays valid, which is why the scope check is not a numbered step.
- `method/commands/po-review.md`, `method/templates/review.md`, `method/AGENTS.md`, `method/commands/po-drive.md`, `method/skills/stories-review/SKILL.md`: not in `Owns`, empty diff.
- `docs/parite-killer-saas.md`: empty diff. A02 and D09 belong to s31, which lists them as statuses to update.
- `.claude/` and `.polype/` are installed copies: empty diff.
- No existing test modified; the 149 already passing stay passing.

## Files touched

- `method/skills/review-antihallu/SKILL.md`
- `method/agents/reviewer.md`
- `tests/ownership.test.sh` (new)
- `docs/plans/s28-ownership.md`, `docs/verif/s28-ownership.md` (pipeline evidence)

## Test strategy

Two bash tests in `tests/ownership.test.sh`, one per acceptance criterion, names identical to the criteria — well inside `Test budget: 25`. Following the `testing-doctrine` skill, each pins the clause that matters by quoting a short exact phrase, and the ordering test asserts a structural relation (heading line numbers) that a move would break, not the presence of a word. No test asserts a whole paragraph: prose reworded without changing the rule must not turn red.

## Done when

- The scope check exists in the skill above the six numbered steps, with its two severities, its two carve-outs and its missing-`Owns` case.
- `reviewer.md` reads `docs/stories.md` and announces the check.
- `bash tests/run.sh` → 151 passed, 0 failed; `bash bin/po-lint` → exit 0.
- One commit on `story/s28-ownership`, a review with no open critical finding.
