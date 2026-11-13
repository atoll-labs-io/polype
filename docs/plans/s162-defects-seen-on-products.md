---
validated: yes
---
# Plan — s162-defects-seen-on-products

[Story](../stories.md) · [Research](../research/s162-defects-seen-on-products.md)

Branch `story/s162-defects-seen-on-products`. Read `docs/research/s162-defects-seen-on-products.md` first: this plan builds on it and does not repeat it.

## Story
Three stops a product lane should never have hit. #184: the designer refuses the planner's oracle files. #166: a story's `Owns` does not list its oracle file. #87: `/po-setup` writes a `Design skill` the designer cannot load. Criteria: `designer_accepts_the_oracle_files`, `owns_lists_the_oracle`, `setup_refuses_a_missing_design_skill`, `no_file_grows` (restated in the research). The research changes criterion 3: the designer reads only the worktree's `.claude/skills/` (`designer.md:37`), so task 2 adds the `~/.claude/skills/` path. Without it, setup would accept what the designer then refuses.

## Reuse
No new code: the story edits prose in five `method/` files. The designer's new wording is copied from `method/agents/planner.md:22` and `method/agents/implementer.md:24` ("the oracle files that `## Acceptance tests` of the plan names").

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| — | — | — |

## Acceptance tests
The three cases of the owner's rule of 2026-11-13 (`docs/stories.md:2496`), criterion by criterion. Gate check done in the research: `po-gate oracle-intact` reads only the `Oracle file` table (`method/hooks/po-gate.sh:608`), so a criterion with no test is accepted.

| Oracle file | cksum |
| --- | --- |
| `tests/defects-seen-on-products.oracle.test.sh` | `1702754200 877` |

| Criterion | Test |
| --- | --- |
| `designer_accepts_the_oracle_files` | Case 3: the rule tells the designer model what to accept. No oracle test and no phrase test; the reviewer reads `designer.md` `## Checks`. It cannot become a script here: `Owns` names none, and `po-gate.sh` is outside it. Candidate for a `po-eval` control arm (#208): a designer dispatched on a worktree that holds the plan's oracle files goes on, and one that holds any other uncommitted file outside `docs/` stops. |
| `owns_lists_the_oracle` | Case 3: the rule tells the story writer and the stories-reviewer what to do. No script can check it, because oracle paths depend on the project (research, Open questions). The reviewer reads the template, `agentic-stories` and check 8 of `stories-review`. `po-eval` candidate (#208): a `docs/stories.md` whose story has criteria and an `Owns` with no place for tests gets one **major** finding, filed under check 8. |
| `setup_refuses_a_missing_design_skill` | Case 3: `/po-setup` is run by a model. No script owned by the story could run before the method is installed (`po-setup.md` Step 3 installs it). The reviewer reads `po-setup.md`. `po-eval` candidate (#208): setup given a `Design skill` that exists in neither path, or only in a plugin, offers `—` and writes `—`. **Plugin skills**: the research shows the designer does not load them (it reads a file path, `designer.md:37`), so setup refuses them. |
| `no_file_grows` | Case 1: a word count, which `wc -w` reads. `test_no_file_grows` compares `LC_ALL=C wc -w` of each of the six `method/` files in `Owns` with its count at the start point 756cb05 (designer 967, template 315, agentic-stories 1119, stories-review 1248, stories-reviewer 451, po-setup 2278). It fails if any file is larger or missing. |

The oracle passes on the start point, as a regression guard should. Bite proven before the plan: one appended line of two words in `designer.md` made it fail (`969 words, 967 before s162`), then the file was restored and `git diff --exit-code` passed.

## Tasks
1. [x] **Designer status check** (`method/agents/designer.md:20`). Add the oracle files to the allowed list, in the planner's words: "other than `docs/research/<id>.md`, `docs/plans/<id>.md`, `docs/designs/<id>/` and the oracle files that `## Acceptance tests` of the plan names → stop and report." The designer does not recompute sums (Pivot). Any other change still stops it, as before.
   Test: case 3, read by the reviewer. Run `bash tests/run.sh fleet-design.test.sh designer-browser.test.sh drive.test.sh qa.test.sh model-routing.test.sh adr-directory.test.sh defects-seen-on-products.oracle.test.sh`.
2. [x] **Designer skill paths** (`designer.md:36-39`). The skill is read from `.claude/skills/<Design skill>/SKILL.md` in the worktree, or else from `~/.claude/skills/<Design skill>/SKILL.md`. Line 39 becomes "no `SKILL.md` at either path". Keep the exact phrase '`.claude/skills/<Design skill>/SKILL.md`' (`fleet-design.test.sh:40`) and `You never draw from taste`. Pay for tasks 1-2 in the same file, for example by dropping "your `skills:` list was fixed when the method was written, while `Design skill` belongs to the project" (`:37`, 17 words) and, if needed, "Apply it; it is not restated here." (`:13`). End at ≤ 967 words.
   Test: `test_no_file_grows`, plus the run of task 1.
3. [x] **Stories template** (`method/templates/stories.md:13`). In the `Owns` placeholder, say that `Owns` lists the story's oracle file, the file its acceptance tests go in. Pay for it in the same line: shorten the overlap restatement ("stories whose entries overlap, by the overlap rule of check 8 of the `stories-review` skill, never run at the same time") to a pointer to check 8. Keep the entry syntax as it is. End at ≤ 315 words.
   Test: `test_no_file_grows`; `bash tests/run.sh stories.test.sh stories-review.test.sh owns-overlap.test.sh structure.test.sh commands-and-texts.test.sh`.
4. [x] **`agentic-stories`** (`method/skills/agentic-stories/SKILL.md:21`). In `## Owns and contracts first`, one clause: the `Owns` of a story with acceptance criteria lists its oracle file, which the planner writes before any code. Keep `Every story declares Owns:` and the syntax sentence (`stories.test.sh:34,79-80`). Pay for it in the same file, for example "Agents run stories side by side, so" → "So". End at ≤ 1119 words.
   Test: `test_no_file_grows`; `bash tests/run.sh stories.test.sh platform-setting.test.sh post-m7-texts.test.sh diagnostic-skill.test.sh intake-issue-becomes-a-story.oracle.test.sh`.
5. [x] **`stories-review` check 8** (`method/skills/stories-review/SKILL.md:25`, `:54`). Extend the last sentence of check 8, with no new check number: a story with acceptance criteria whose `Owns` covers no file for its oracle is also major. Add the same case to the **major** list (`:54`, for example "a story with no `Owns`, or none covering its oracle"). Leave the overlap rule, the decision table and the critical sentence untouched (`owns-overlap.test.sh:9`, `stories-review.test.sh:34`). Pay for it in the same file, outside those frozen sentences. End at ≤ 1248 words. Leave `method/agents/stories-reviewer.md` unchanged: it defers to the skill (`:14`).
   Test: `test_no_file_grows`; `bash tests/run.sh stories-review.test.sh owns-overlap.test.sh framing-commands-cleanup.test.sh plan-and-defect-paths-cleanup.test.sh wiring.test.sh intake-issue-becomes-a-story.oracle.test.sh`.
6. [x] **`/po-setup` refuses a missing skill** (`method/commands/po-setup.md:46`). After the `Design skill` answer, write the name only if `.claude/skills/<name>/SKILL.md` or `~/.claude/skills/<name>/SKILL.md` exists, which are the two places the designer reads. A skill only a plugin provides is neither. Otherwise say which skill is missing and how to get it (a `SKILL.md` in one of those two places), offer `—`, and write `—`. Keep the frozen sentence of `:46` (`design-handoff.test.sh:47`), `Only the source is asked here` and `Setup never fills it`. Pay for it in the same file, for example "the other one stays `—`" in `:46`, or redundant prose elsewhere. Before each cut, run `grep -lF '<phrase>' tests/*.sh`. End at ≤ 2278 words.
   Test: `test_no_file_grows`; `bash tests/run.sh $(cd tests && grep -l 'po-setup' *.test.sh)`.
7. [x] **Full suite and record**: `po-run --story s162-defects-seen-on-products --label suite -- 'bash tests/run.sh'`. `Typecheck` is `—`.

## Scene viewpoints
—

## Run interdicts
- Empty diff on `.claude/`, `.polype/`, `AGENTS.md`, `method/AGENTS.md`, `method/hooks/`, `bin/`, `method/agents/planner.md`, `method/agents/implementer.md`, `method/commands/po-design.md`, `method/commands/po-stories.md`, `docs/stories.md`.
- `method/agents/stories-reviewer.md` ends with an empty diff (task 5).
- `cksum < tests/defects-seen-on-products.oracle.test.sh` prints `1702754200 877` unless `## Oracle changes` of the record says why.
- No `tests/defects-seen-on-products.test.sh`: criteria 1 to 3 get no phrase test (case 3), and the story has no other test.
- No existing test file is edited. A frozen phrase stays.
- `stories-review` keeps ten numbered checks: no `**11.`.
- The designer does not recompute oracle sums. `po-gate oracle-intact` remains the only sum check.

## The pivot
Everything rests on three readings, each to be checked against the source named here.
1. **"listed … with their checksum"** is read as "named in the `Oracle file` table", not "recomputed by the designer". Compare with #184 ("ideally checked against their cksums") and with `review-antihallu/SKILL.md:41`. If the owner wants the designer to recompute, it costs words in a file that must not grow, and the review already checks the sums.
2. **Plugin skills refused**: based on `designer.md:37`, the designer reads a file path and never calls a plugin skill. If a subagent could load an enabled plugin skill by name, setup would refuse a skill that works. Then the fix is a designer that resolves plugins, which is a separate story.
3. **Fixed word ceilings** in the oracle, not a comparison with `main`: the CI checkout is shallow (`.github/workflows/ci.yml`), so `main`'s history may be missing there. A later story that has to grow one of these files has to raise its ceiling and say why.

## Files touched
`method/agents/designer.md`, `method/templates/stories.md`, `method/skills/agentic-stories/SKILL.md`, `method/skills/stories-review/SKILL.md`, `method/commands/po-setup.md`; `tests/defects-seen-on-products.oracle.test.sh` (planner); `docs/research/`, `docs/plans/`, `docs/verif/` of the story.

## Test strategy
- Automated: 1 test, `test_no_file_grows`, case 1. Within the `Test budget` of 25.
- Read by the reviewer, no test (case 3): `designer_accepts_the_oracle_files`, `owns_lists_the_oracle`, `setup_refuses_a_missing_design_skill`, all three `po-eval` candidates (#208).
- Regression: the existing tests that freeze these files (listed per task), then the full suite once at the end (task 7).

## Done when
The five files read as the tasks say, each at or under its ceiling. The full suite is green through `po-run`. One commit holds research, plan, oracle, record and edits. The review has no open critical finding. The PR closes #184, #166 and #87.
