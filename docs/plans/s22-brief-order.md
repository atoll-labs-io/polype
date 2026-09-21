---
track: flow
validated: yes
---
# Plan (short track) — s22-brief-order

## Verified facts

- `method/commands/po-brief.md:45-49` — `## Finish` runs in this order: (1) show the brief and write `status: approved`, (2) write the first ADR, (3) commit *and only then* check the branch and `git status --porcelain` for an environment file. The blocking checks are the last step, after the approval is already on disk. Defect n° 4 confirmed.
- `method/commands/po-brief.md:30` — the interview keeps `status: interviewing` between themes, so the only writer of `approved` is the `## Finish` step above; moving the checks ahead of it is enough to make an interruption leave the brief at `interviewing`.
- `method/commands/po-stories.md:20-21` — the string `status: approved` appears on two independent lines, one per `Entry mode` branch. `tests/stories.test.sh:17` asserts it with a whole-file `contains`, so deleting the brief requirement (line 21) keeps the test green. Defect n° 5 confirmed.
- `tests/stories.test.sh:10-19` — `test_stories_reads_prd_or_brief_by_entry_mode` is the test that holds that weak assertion; its other assertions (`Entry mode` read, the two source lines, the `—` stop) do bite and stay.
- `tests/brief.test.sh:11-57` — no test covers the `## Finish` section of `po-brief.md` at all; the two new tests do not collide with an existing one.
- `tests/lib.sh:43` — `contains` is a whole-file `grep -qF`: any assertion that must bite on one clause has to be scoped to a line or a section first. `section_of` (`tests/brief.test.sh:9`, `tests/stories.test.sh:8`) is the existing way to scope.
- `tests/prd.test.sh:13`, `tests/wiring.test.sh:27,74-75` are the only files outside the two test files that mention `po-brief`/`po-stories`; none reads their `## Finish` or `## Checks` bodies, so nothing else breaks.
- `docs/defauts.md:15-16` — defects n° 4 and 5 are the rows this story closes; the corrected rows above use the exact wording `corrigé par s21`.
- `tests/run.sh:11-22` — each `test_*` runs in its own `bash -c` with `set -eu`; `fail` ends only that test.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — the story text only names prompt files and test files | absent — no data or schema anywhere in `method/` or `tests/` |
| New screen | absent — no interface in the story text | absent — the touched files are markdown prompts and bash tests |
| Authorization or tenant scope | absent — no actor or permission in the story text | absent — no such notion in this repository |
| API contract | absent — no interface between components in the story text | absent — the `Reads settings:` lines of both commands are unchanged |
| New dependency | absent — none named | absent — the tests use only `tests/lib.sh` and coreutils |

## Story

`/po-brief` must run its blocking checks before writing anything approved, and the "approved brief" requirement of `/po-stories` must be covered by a test that actually fails when the requirement goes.

Acceptance criteria:
- [x] `brief_checks_before_writing_approved` — branch, environment files and every other blocking check pass **before** `status: approved` is written and before the ADR; an interruption leaves the brief at `status: interviewing`.
- [x] `brief_commits_approval_and_adr_together` — the approval and its ADR go in the same commit, or neither.
- [x] `stories_requires_an_approved_source_with_a_biting_test` — the test tells an approved brief from one still being written: it fails if the command accepts `status: interviewing`.

## Tasks

1. [x] Rewrite `## Finish` of `method/commands/po-brief.md` as an ordered sequence whose first step is the blocking checks — current branch is `Target branch`, `git status --porcelain` lists no environment file — and which states that an interruption before the last step leaves `docs/brief.md` at `status: interviewing`. Test able to fail: `brief_checks_before_writing_approved`.
2. [x] In that same section, make the approval and the ADR a single commit: both written after the checks, committed together as `docs: brief for <product>`, with the explicit rule that neither survives alone. Test able to fail: `brief_commits_approval_and_adr_together`.
3. [x] In the `## Checks` of `method/commands/po-stories.md`, keep the two per-mode lines as they are and add one clause refusing a source that is still being written (`status: interviewing`, or any status other than `approved`), naming the file instead of reading it. Test able to fail: `stories_requires_an_approved_source_with_a_biting_test`.
4. [x] Add `test_brief_checks_before_writing_approved` and `test_brief_commits_approval_and_adr_together` to `tests/brief.test.sh`, both scoped to the `Finish` section via the existing `section_of`. The order test must compare positions, not just presence: the line carrying the branch/environment checks comes before the line writing `status: approved`, so swapping the steps back turns it red.
5. [x] Add `test_stories_requires_an_approved_source_with_a_biting_test` to `tests/stories.test.sh`: inside the `Checks` section, **every line naming `docs/prd.md` or `docs/brief.md` must carry `status: approved` on that same line**, and the refusal clause of task 3 must be present. Remove the whole-file `contains "$STORIES" 'status: approved'` from `test_stories_reads_prd_or_brief_by_entry_mode` — that is the assertion this story replaces; its other assertions stay untouched.
6. [x] In `docs/defauts.md`, set the status cell of rows n° 4 and n° 5 to `corrigé par s22`, matching the wording of the rows already closed. Touch no other row.

## Run interdicts

- `.claude/` and `.polype/` end with an empty diff: they are installed copies of `method/`.
- No file outside the story's Owns is modified: `method/commands/po-brief.md`, `method/commands/po-stories.md`, `tests/brief.test.sh`, `tests/stories.test.sh`, `docs/defauts.md`.
- No ADR is added, edited or renumbered; no row of `docs/parite-killer-saas.md` is touched.
- `Reads settings:` of both commands stays as it is — adding or removing a setting is not this story.
- Do not weaken `tests/lib.sh` or any other test file to make a new assertion pass.

## Files touched

- `method/commands/po-brief.md`
- `method/commands/po-stories.md`
- `tests/brief.test.sh`
- `tests/stories.test.sh`
- `docs/defauts.md`
- `docs/plans/s22-brief-order.md` (this plan, committed with the code)

## Test strategy

Three tests, one per acceptance criterion, well within `Test budget: 25`. This repository has a single test layer: bash assertions over the method's prompt files, so each test belongs there by construction.

Each names the rule it would break:
- `brief_checks_before_writing_approved` — red if the checks move back after the approval, because it compares the two line numbers inside the `Finish` section, not their presence.
- `brief_commits_approval_and_adr_together` — red if the ADR gets a commit of its own or the approval is committed without it.
- `stories_requires_an_approved_source_with_a_biting_test` — red if any source line loses its `status: approved` requirement, which is exactly the hole of the current whole-file assertion, and red if the refusal of a source still being interviewed disappears.

Run: `bash tests/run.sh brief.test.sh stories.test.sh` after tasks 4 and 5, then the full `bash tests/run.sh` once every task is done (`Full suite: execute-end`). `Typecheck`, `E2E` and `Build` are `—` in this project.

## Done when

- The three acceptance criteria have a passing test that fails when its rule is removed.
- The whole suite is green, `tests/overlap.test.sh` included (new prose in `method/` is written from scratch, never from a Killer SaaS source).
- Defects n° 4 and 5 are marked corrected in `docs/defauts.md`.
- One commit on `story/s22-brief-order` carrying the code, the tests and this plan.
