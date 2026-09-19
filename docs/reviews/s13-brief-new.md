# Review — s13-brief-new

Diff reviewed: `git diff m2-cadrage...story/s13-brief-new` (commit 8afef38), in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s13-brief-new` exited 0. The record (`docs/verif/s13-brief-new.md`, Tree 5d7471b) is marked complete, and `bash tests/run.sh` gave exit 0 with 91 passed. I reused it (`Verification mode: record`) and did not rerun the full suite. The project has no type check, no E2E and no build command (`—`), so none were run. The record's "Not proven here" section says the tests are structural only; I carried that into "Not verified" below.

## Plan
- [x] Tasks 1–7 are all present: the template, the skill, the command, one line in `po-help.md`, the 4 tests, the C04 matrix cell and the record. Nothing falls outside the plan.
- [x] Run interdicts, checked one by one:
  - Nothing changed in `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `tests/lib.sh` or `method/AGENTS.md` (`git diff --exit-code` is clean).
  - No existing test file changed. The only new test file is `tests/brief.test.sh`.
  - The only change to an existing `method/` file is the one added line in `po-help.md`.
  - In `docs/parite-killer-saas.md`, only the C04 line changed (one `-` line, one `+` line).
  - `grep -rn "references/\|vault" method/` finds nothing.
  - For overlap with Killer SaaS, I relied on the record's green `overlap.test.sh`.

## References
- [x] Every reference I opened exists:
  - Test helpers: `settings_read_by`, `frontmatter`, `contains`, `require_file`, `fail`, `$METHOD` (all in `tests/lib.sh`).
  - Templates and neighbours: `templates/adr.md`, `templates/brief.md`, `po-prd.md:22` (which redirects `new` to `/po-brief`).
  - `Entry mode` and its values: `method/templates/agents-local.md:23,46`.
  - Tools `Agent` and `AskUserQuestion` are already used by other commands. `WebSearch` is new here; the plan decided to add it.
  - The local `section_of` helper runs in its own `bash -c`, so it cannot collide with other test files.
- [x] The ADR path `docs/decisions/0001-<slug>.md` matches Law 6 (`NNNN-<slug>.md`). The status values `interviewing` → `approved` match the story and the s14 contract (`docs/stories.md:215`).

## Rules
- [x] `AGENTS.md` conventions are respected: method files are in English, `po-help` is in French, there is a `Reads settings:` line, templates are referred to as `templates/<name>.md`, and a command that commits has Write and Bash.
- [x] No accepted ADR is contradicted. On ADR-0006 I relied on the recorded overlap test.

## Tests
- [x] The assertions pin each of the four acceptance criteria, and none of the six empty test shapes appears. The tests are structural, which is this project's convention.
- [x] 4 tests, within `Test budget: 25`.
- [x] Bite: I disabled 5 rules, ran only `brief.test.sh` after each, and restored the file each time. `git diff --exit-code` was clean after each restore and at the end.

  | Rule disabled | Failing tests |
  | --- | --- |
  | M1: `po-brief.md` `` `new` → continue `` changed to a stop | 0 |
  | M2: the explicit-agreement exit criterion deleted | 1 |
  | M3: resume on `status: approved` changed to "start a new interview over it" | 0 |
  | M4: ★ removed from the Evaluation dimension in the skill | 1 |
  | M5: the "fresh context, only the draft" pre-mortem clause replaced by "receives the whole conversation" | 1 |

- [x] No test became useless because of this story.

## Neighbours
- [x] `po-prd.md` redirects `new` to `/po-brief`, and `/po-brief` sends `replace`/`adapt` back to `/po-prd` with the same `—` wording, so the two are consistent. `po-help` lists the command, which satisfies `pilot.test.sh:38`. No other file in `method/` or `bin/` refers to brief or interrogation.

## Findings
- major — `method/commands/po-brief.md:41-45` (Finish). Step 1 writes `status: approved` and step 2 writes the ADR before step 3 checks the branch and the environment files. If either check stops the command, `docs/brief.md` stays approved but uncommitted. The next `/po-brief` run then hits the Persistence clause ("With `status: approved` → stop"), so the command can never commit it again. The user must commit it by hand or revert the status. There is also no branch check before the interview starts writing `docs/brief.md`, so the brief is written into whatever branch is checked out. `po-prd.md` (outside this diff) has the same ordering. The damage is contained and the user is told, so this does not block the ship.
- minor — `tests/brief.test.sh:11-16`. `brief_runs_only_in_new_mode` does not check that `new` continues. Turning `new` into a stop (M1) fails 0 tests. The story's criterion only asks for the redirect for `replace`/`adapt`, but the test name promises more than it checks.
- minor — `tests/brief.test.sh:44-48`. The rule "an approved brief stops the command" has no test. Removing it (M3) fails 0 tests, yet it protects the approved brief that s14 reads.
- minor — `method/commands/po-brief.md:25`. Resume looks for "an empty section", but the brief created from `templates/brief.md` never has an empty section: unfilled sections hold `<…>` placeholders. The clause should say "a section still holding its placeholder".
- minor — `method/commands/po-brief.md:34` vs `method/skills/interrogation/SKILL.md` (Exit criteria). The skill requires a critical dimension marked `open risk` to come "with a way to retire it"; the command's gate does not. This is the command/skill drift the plan's pivot (b) warned about.

## Not verified
- **A live run of `/po-brief`.** I did not check that an agent actually follows the text: one question per message, persistence after each theme, resume from a half-filled brief, the pre-mortem subagent really getting only the draft, the ADR written at finish, the commit on `Target branch`. The tests only prove the clauses exist. A person should run `/po-brief` in a scratch target project with `Entry mode: new`, stop midway, resume, and finish once on the wrong branch to see the major finding happen.
- **Incumbent research with WebSearch and the no-search fallback.** Neither was exercised. A person should run the incumbents step once with WebSearch available and once without.
- **Installation of the new skill and template into a target project.** I relied on the recorded green `install.test.sh`, which copies `method/` recursively. A person should run `bin/polype-dev-install` into a temporary directory and confirm that `.claude/skills/interrogation/SKILL.md` and `.polype/templates/brief.md` are there.
- **Overlap with Killer SaaS (ADR-0006) and the rest of the suite.** Taken from the record, not rerun.
- **E2E, build and type check.** The project has none (`—`).

Max severity: major
Ship allowed: yes
