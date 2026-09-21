---
validated: yes
---
# Plan — s25-method-lint

Branch `story/s25-method-lint`. Read `docs/research/s25-method-lint.md` first; this plan builds on it without repeating it.

## Story
`bin/po-lint` mechanically checks the invariants of `method/`, `tests/lint.test.sh` makes the suite fail with it, and the tests of `/po-design`, `/po-design-system` and `/po-flow` assert the **consequence** of each rule instead of its wording. Closes defects 9, 10 and 11.

Criteria: `lint_checks_every_command_declares_its_settings`, `lint_checks_tool_permissions_match_the_contract`, `lint_checks_fail_closed_rules_have_a_stop`, `lint_is_part_of_the_suite`, `design_stop_rules_bite`.

## The pivot
**A lint test that only runs the lint on a green tree proves nothing** — it passes whether the script holds three rules or zero. So `bin/po-lint` takes an optional argument, the method directory to scan (default: `method/` next to the script), and each test copies `method/` to a temp dir, **breaks exactly one thing**, and asserts the lint goes red on that `file:line`. Delete a rule from the script, the mutation test goes green, the suite fails.

How it could be wrong:
- The argument makes the script scan the wrong tree by default — compare `bash bin/po-lint` with no argument against `bash bin/po-lint method`, both must exit 0.
- A mutation is too coarse and any of the three rules would catch it — each mutation must be checked to fire on **one** rule, by asserting the reported `file:line` and the rule's own message.
- The rules are calibrated on today's `method/` and drift into false positives — the measurements in the research (41 arrow rules, 0 counter-examples) are the calibration; the lint must exit 0 on the untouched tree.

## Tasks

### `bin/po-lint`
1. [x] Header and skeleton: a bash script, `set -u`, no dependency beyond coreutils/awk/grep. `METHOD="${1:-$(dirname "$0")/../method}"`; a `report <file> <line> <rule> <message>` helper printing `<file>:<line>: [<rule>] <message>`; a counter; exit 1 when the counter is non-zero, 0 otherwise, after a one-line summary. A comment says what the script is for and that it must stay decidable without interpreting a sentence. *Test: `lint_is_part_of_the_suite`.*
2. [x] **Rule `settings`** over `$METHOD/commands/*.md` and `$METHOD/agents/*.md`: no `^Reads settings:` line → report at line 1; otherwise every backticked name on that line must appear in the setting names of `$METHOD/templates/agents-local.md` (the `Name:` of every non-empty line inside a fenced block) → report the unknown name at that line. `Reads settings: none` carries no backtick and must stay valid (`method/commands/po-help.md:8`). *Test: `lint_checks_every_command_declares_its_settings`.*
3. [x] **Rule `tools`**, three checks, all decided from the frontmatter plus a literal marker:
   - a command whose **body** names `AskUserQuestion` must declare it in `allowed-tools` → report at the first body occurrence;
   - a command declaring `Agent` must not declare `Edit`: whoever delegates does not edit (verified green over all 17 commands) → report at the `Edit` line;
   - a command whose description holds `cannot edit files or run a shell` must declare none of `Write`, `Edit`, `Bash` → report at the offending tool line;
   - a subagent whose `skills:` list holds `review-antihallu` or `stories-review` — it judges — must not declare `Write` → report at the `tools:` line.
   Files with no tool declaration at all are skipped (`po-help.md` has none). *Test: `lint_checks_tool_permissions_match_the_contract`.*
4. [x] **Rule `fail-closed`** over `$METHOD/commands/*.md` and `$METHOD/agents/*.md`, restricted to sections whose heading matches `^## (Checks|Preconditions|Step 0)` up to the next `^## `: a line holding `→` whose text **before** the arrow matches an absence trigger (`No `, `no `, `None`, `none`, `Missing`, `missing`, `not `, `` `—` ``, `Any other`, `Another`) must hold, **after** the arrow, one of `stop`, `ask`, `carry on`, `never blocks` → otherwise report the line. A comment records why the scope is narrow: over the whole file, 28 of 95 arrow lines are legitimate non-blocking branches. *Test: `lint_checks_fail_closed_rules_have_a_stop`.*
5. [x] Run `bash bin/po-lint` and `bash bin/po-lint method` from the repository root: both exit 0 and print nothing but the summary. Any breach found is a real finding — report it, do not weaken the rule to silence it.

### `tests/lint.test.sh`
6. [x] Helpers: `mutant()` copies `$METHOD` into a fresh temp dir (`scratch`-style `trap … EXIT`); `lint_on <dir>` runs `bash "$ROOT/bin/po-lint" <dir>`, capturing output and status. A comment states the file's contract: every test breaks one invariant and proves the lint sees it.
7. [x] `test_lint_is_part_of_the_suite` — `bash "$ROOT/bin/po-lint"` on the real `method/` exits 0; its output is shown in the `fail` message when it does not. This is the test that makes the suite fail with the lint.
8. [x] `test_lint_checks_every_command_declares_its_settings` — two mutants: one with the `Reads settings:` line of a command deleted, one with a backticked setting renamed to a name absent from the template. Each must exit non-zero and name that file with rule `settings`.
9. [x] `test_lint_checks_tool_permissions_match_the_contract` — four mutants, one per check of task 3: `AskUserQuestion` removed from a command's `allowed-tools` while its body still names it; `  - Edit` added to a command that declares `Agent`; `  - Bash` added to `po-execute.md`; `Write` added to `reviewer.md`'s `tools:`. Each exits non-zero with rule `tools`; each is asserted on its own so one mutation cannot stand in for another.
10. [x] `test_lint_checks_fail_closed_rules_have_a_stop` — one mutant with the stop stripped from a `## Checks` rule (`` `Design source` is `—` → stop and ask … `` becomes `→ pick internal`): exits non-zero, rule `fail-closed`, at `commands/po-design.md`. Plus one **negative control**: appending a legitimate non-blocking rule (`- `none` → continue.`) to a `## Checks` section keeps the lint at 0, so the rule is not a false-positive machine.

### The three hardened test files
11. [x] `tests/design.test.sh` — new `test_design_stop_rules_bite`, the function that carries the criterion's name (convention: a criterion's name is its test function's name). For `/po-design`: the line naming `` `docs/design-system.md` is missing `` and the line naming `` `Design source` is `—` `` each carry `stop` **on that same line**; `## Checks` holds `Either way the command writes nothing and draws no mockup.` and the no-screen rule's `writing nothing`; and the `## Checks` heading comes **before** every `## Step ` and `## Where the design lives` heading, so no production step is reachable ahead of the gate. `test_design_fails_closed_without_system_or_source` keeps its trigger phrases unchanged. (Defect 10.)
12. [x] `tests/design-system.test.sh` — add to the **existing** `test_design_system_never_invents_an_identity` the consequence of the rule defect 9 names: the paragraph of `## Step 3 — Measure contrast` holding `The command edits no source file:` must, in that same paragraph, say what happens instead — `handed to the person`, `a quick fix they name or through a story`, `the code still carries the old values`. Strip the consequence and the test goes red. No new function name. (Defect 9.)
13. [x] `tests/flow.test.sh` — add to the **existing** `test_flow_checks_escalation_signals_twice` the consequences defect 11 says are untested: `a signal there → stop and point to` for the first check, `keep it as it is, write no plan` for the second, the `before reading the code` mention preceding the `after reading the code` one, and the `## Escalation signals` heading coming before `## The plan` so no plan is produced ahead of the gate. Its list of five signals stays. No new function name. (Defect 11.)
14. [x] Run `bash tests/run.sh` in full: everything green, `tests/structure.test.sh` and the other untouched files included.

### Traceability
15. [x] `docs/defauts.md` — set the status of rows 9, 10 and 11 to `corrigé par s25`, touching nothing else in the table and leaving the "Motif récurrent" paragraph as it is.

## Run interdicts
- `tests/structure.test.sh`, `tests/lib.sh`, `tests/run.sh`, `tests/overlap.test.sh` and every file under `method/` must end with an **empty diff**. The lint reads `method/`, it never rewrites it; a rule that would require editing a method file is a finding to report, not an edit to make.
- `method/commands/po-execute.md:21` (`if not, point to /po-setup`, no stop word) is a real gap found by the research. It is **outside `Owns`** and Law 7 leaves it to a person: do not fix it, do not add a row to `docs/defauts.md` for it. Name it in the final report.
- Do not touch `docs/parite-killer-saas.md`: this story has no `**Matrice**` line.
- `bin/po-lint` is invoked as `bash "$ROOT/bin/po-lint"`, like `tests/overlap.test.sh:13` does for `ks-overlap`; do not depend on the executable bit.
- No new setting, no new command, no change to `method/commands/po-help.md`.
- Never loosen a lint rule to make the suite pass. If the untouched `method/` fails, report the breach.

## Files touched
- `bin/po-lint` (new)
- `tests/lint.test.sh` (new)
- `tests/design.test.sh`, `tests/design-system.test.sh`, `tests/flow.test.sh` (modified)
- `docs/defauts.md` (three status cells)
- `docs/research/s25-method-lint.md`, `docs/plans/s25-method-lint.md`, `docs/verif/s25-method-lint.md` (committed with the story)

## Test strategy
The layers of `testing-doctrine` map to this repository as: the **script** is the unit under test, and the **method files** are its input. Automated tests: 5 new functions and 2 hardened ones — well inside `Test budget: 25`:

| Test | Layer | What fails if the rule is deleted |
| --- | --- | --- |
| `test_lint_is_part_of_the_suite` | script, nominal | the lint crashes or reports on a clean tree |
| `test_lint_checks_every_command_declares_its_settings` | script, mutation ×2 | rule `settings` removed → mutant passes |
| `test_lint_checks_tool_permissions_match_the_contract` | script, mutation ×4 | any of the four tool checks removed |
| `test_lint_checks_fail_closed_rules_have_a_stop` | script, mutation + negative control | rule `fail-closed` removed, or widened into false positives |
| `test_design_stop_rules_bite` | method file, structural | a stop deleted, or a production heading moved before `## Checks` |
| `test_design_system_never_invents_an_identity` (hardened) | method file, structural | the consequence of "edits no source file" deleted |
| `test_flow_checks_escalation_signals_twice` (hardened) | method file, structural | the escalation stop deleted, or `## The plan` moved ahead of it |

The mutation tests are the whole point: they are the first tests in this repository that prove a rule by removing it, which is exactly what `docs/defauts.md:34` says phrase tests cannot do. No visual check: this story has no screen.

Stages, per the doctrine: each task's test right after that task, with only its own file (`bash tests/run.sh lint.test.sh`); the full suite once when every task is done (`Full suite: execute-end`). `Typecheck: —`, `E2E stage: —`, `Build stage: —` — nothing else runs.

## Done when
- `bash tests/run.sh` is green, with the 8 functions above passing and no previously passing test broken.
- `bash bin/po-lint` exits 0 on the repository and non-zero on each mutant.
- Rows 9, 10 and 11 of `docs/defauts.md` read `corrigé par s25`.
- One commit on `story/s25-method-lint` carrying the code, the research, the plan and `docs/verif/s25-method-lint.md`.
- A review with no open critical finding.
