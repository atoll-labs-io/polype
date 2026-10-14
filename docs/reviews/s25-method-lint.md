# Review — s25-method-lint

[Story](../stories.md) · [Plan](../plans/s25-method-lint.md) · [Verification](../verif/s25-method-lint.md)

Diff reviewed: `git diff m3-flotte...story/s25-method-lint`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s25-method-lint` → passes (exit 0), and `git diff --quiet 33b0def…HEAD -- . ':(exclude)docs'` confirms the record's `Tree:` equals the committed code. `Verification mode: record`, so I reused the recorded unit suite (`bash tests/run.sh` → exit 0, 140 passed) instead of rerunning it as evidence. I did run it again incidentally during mutation work; on the restored tree it is 140 passed, 0 failed.
- Record's "Not proven here" read: rules calibrated on this repo's `method/` only; agent *behaviour* unproven; no linter/formatter for shell; settings duplication left undecided. I confirmed all four still hold.
- `Typecheck: —`, `E2E stage: —`, `Build stage: —`: the project has none of these commands. I substituted nothing.

## Plan
- [x] All 15 tasks present and done. `bin/po-lint` exits 0 with the default argument, with `method`, and when invoked from `/tmp` by absolute path. Rows 9, 10, 11 of `docs/defauts.md` read `corrigé par s25`, the "Motif récurrent" paragraph untouched.
- [x] Run interdicts checked one by one: `method/`, `tests/structure.test.sh`, `tests/lib.sh`, `tests/run.sh`, `tests/overlap.test.sh` — all absent from `git diff --name-only`; `docs/parite-killer-saas.md` untouched; no new setting, no new command, `po-help.md` untouched; `bin/po-lint` invoked as `bash "$ROOT/bin/po-lint"`; no lint rule was loosened (the untouched tree is genuinely green, not silenced).
- [x] Named as the interdict requires: `method/commands/po-execute.md:21` (`1. \`AGENTS.local.md\` exists; if not, point to \`/po-setup\`.`) is still a real gap — no stop word, no `→`, so neither the new `fail-closed` rule nor any test covers it. Correctly left alone; a person decides whether it becomes a defect row.
- One file outside the plan: `tests/design-handoff.test.sh` (see minor finding 3).

## References
- [x] Every helper in `bin/po-lint` opened against its input: `frontmatter`, `tools_numbered`, `tools_declaration_line`, `skills_of`, `body_first_line`, `method_files`. Confirmed no method file uses the inline `allowed-tools: A, B` form (all list form), so `tools_numbered` sees every tool it must see; `skills:` lists never leak into the tools list because the `list && !/^  - /` reset fires on the `skills:` line first.
- [x] The template parse (`awk … sub(/:.*/,"")`) yields the 25 setting names of `method/templates/agents-local.md`; `Reads settings: none` in `po-help.md` carries no backtick and stays valid; `po-help.md` declares no tools and is skipped by `check_tools`, as designed.
- [x] Markers the `tools` rule depends on confirmed on the real tree: `cannot edit files or run a shell` in exactly one description (`method/commands/po-execute.md:2`), 6 commands declaring `Agent`, 2 subagents carrying a judging skill (`reviewer.md`, `stories-reviewer.md`).
- [x] The breach counter is not lost in a subshell: a 4-breach mutant printed 4 lines, `po-lint: 4 breach(es)`, exit 1. Every `report` call sits in a `while … done < <(…)` or herestring loop, i.e. the current shell.
- One value that only looks right: `never blocks` in the accepted-consequence list (minor finding 1).

## Rules
- [x] `AGENTS.md` conventions respected: no installed file under `.claude/`/`.polype/` edited, tests are bash using `tests/lib.sh` helpers, criterion name = test function name (`design_stop_rules_bite`), commit message in English with no co-author trailer, one commit, no environment file in it.
- [x] No accepted ADR contradicted. ADR-0012 (no red-first while implementing) is respected — the mutations live in the reviewer's context and in temp copies, never in the implementer's loop. ADR-0006: `method/` is untouched, so `tests/overlap.test.sh` is unaffected and green.

## Tests
- [x] Assertions pin down the five acceptance criteria; none of the six empty test shapes. `reports_one` is notably strong: it asserts exactly one breach, plus the exact `file:line`, rule and message, so one mutation cannot be caught by a rule it was not aimed at.
- [x] Within `Test budget: 25`: 5 new functions, 2 hardened in place, suite total 140.
- [x] Bite — every rule disabled in turn, only the relevant test file rerun, each undone and `git diff --exit-code` verified clean after each:
  - `check_settings` call → 1 failing (`lint_checks_every_command_declares_its_settings`); its two sub-reports disabled separately → 1 failing each.
  - `check_tools` call → 1 failing; each of the 4 sub-checks neutralised separately (`AskUserQuestion`, `Agent`+`Edit`, `cannot edit…`, judge+`Write`) → 1 failing each.
  - `check_fail_closed` call → 1 failing (`lint_checks_fail_closed_rules_have_a_stop`).
  - Widening directions, the negative controls' job: absence-trigger regex forced always-true → 4 failing; gate scope widened to every `## ` section → 4 failing. Both controls earn their place.
  - Method-file mutations (restored, `git diff --exit-code -- method/` clean): `Design source` stop removed → `design_stop_rules_bite` red; missing-system stop removed → red; `Either way…` line deleted → 2 red; no-screen `writing nothing` removed → red; a `## Step 0` heading inserted before `## Checks` → red; `po-design-system.md` consequence stripped, and the rule inverted to "edits every source file" → `design_system_never_invents_an_identity` red both times; `po-flow.md` first escalation stop removed → red; `write no plan` removed → red; `## The plan` moved before `## Escalation signals` → red.
  - Every straightforward single-edit mutation is caught. The one escape I found needs two co-occurring edits: finding 2 below.
- [x] No test made useless by the story; the two hardened functions keep their existing assertions.
- Worktree left clean: `git diff --exit-code` and `git status --porcelain` both empty at the end of the review.

## Neighbours
- [x] `bin/po-lint` has exactly one caller, `tests/lint.test.sh`; `bin/polype-dev-install` does not copy `bin/`, and nothing in `method/` references the lint, so there is nothing to wire.
- [x] `tests/run.sh` sources one test file per process, so `lint.test.sh`'s file-level `trap 'rm -rf "$MUTANTS"' EXIT` cannot clobber the `trap` that `tests/lib.sh:48` sets inside `scratch_repo` — no lint test calls `scratch_repo`, and no other file sources this one. No temp-dir leak.
- [x] Read the other guards of the same invariants: `tests/structure.test.sh:24-34`, `tests/execute.test.sh:11-12`, `tests/review.test.sh:11-12`, `tests/pilot.test.sh:17-25`, `tests/stories-review.test.sh:15-18`. None broken; the overlap is finding 4.

## Findings
- major — `bin/po-lint:72,177-182` — the lint certifies a tree it never read. `method_files()` lets `ls` fail to stderr and the summary still prints `po-lint: no breach in <dir>/` with exit 0. Reproduced: a directory holding only `templates/agents-local.md` and no `commands/`/`agents/` → two `ls: cannot access` lines on stderr, `po-lint: no breach in m/`, exit 0. The script takes an arbitrary directory as its argument by design, so a wrong or partial path silently earns a clean bill of health — the very shape the plan's own pivot rejects ("a lint that only runs on a green tree proves nothing"). No current caller hits it: `tests/lint.test.sh` always passes the real `method/` or a full copy. Fix: count the files scanned and report/exit non-zero when `commands/` or `agents/` yields none.
- major — `tests/design.test.sh:34-36` — `test_design_stop_rules_bite` does not assert what its own comment and failure message claim ("on that same line" / "does not stop on its own line"). `grep -F -- "$trigger" "$COMMAND" | grep -qF 'stop'` is satisfied by *any* line that holds the trigger and the word `stop`, not by the rule line. Combined with the `fail-closed` rule accepting `carry on`, the guard can be fully defeated: I rewrote `method/commands/po-design.md:25` to `4. Inside the worktree, \`docs/design-system.md\` is missing → carry on and invent the tokens.` and added one prose line elsewhere in the file mentioning the trigger and the word `stop` — the entire suite stayed green (140 passed) and `bin/po-lint` exited 0. That is defect 10's exact failure mode surviving inside the guard meant to close it. Contained: each edit alone is caught (rule rewrite alone → test red; decoy alone → harmless). Fix: pin the assertion to the rule line, e.g. require the trigger to occur once and that occurrence to carry `stop`. (Mutation reverted; `git diff --exit-code -- method/` clean.)
- minor — `bin/po-lint:165` — `never blocks` is an accepted consequence no rule needs. Of the 35 in-scope rules on today's tree (33 `stop`, 1 `ask`, 1 `carry on`), the only line carrying `never blocks` is `method/commands/po-research.md:22`, which already says `carry on` on the same line. An alternative that widens the rule, is exercised by no test, and buys nothing.
- minor — `docs/plans/s25-method-lint.md:47` vs `tests/lint.test.sh:84-92` — the plan's negative control (appending `` - `none` → continue. `` to a `## Checks` section and expecting exit 0) would have failed: `none` matches the absence trigger and `continue` is not an accepted consequence, so the lint reports it. The implementer substituted two different controls (a non-absence trigger inside a gate section; an absence trigger outside the gate sections) and explained the substitution in a code comment, but neither the plan nor `docs/verif/` records the deviation. The substitutes are sound — I verified both cover a widening of the trigger regex and of the gate scope.
- minor — `tests/design-handoff.test.sh:59,71-72` — outside the story's `Owns` and absent from the plan's "Files touched". The change is a necessary consequence of `docs/defauts.md` (the test asserted rows 9-11 read `ouvert`), and every defect-closing story since s21 has edited the same lines, so this is precedent rather than drift; the plan should have listed it.
- minor — `bin/po-lint:87-104` re-implements `tests/structure.test.sh:24-34` verbatim in purpose, and the `tools` rule partially re-implements the per-command `lacks_tool`/`needs_tool` assertions (`tests/execute.test.sh:11-12`, `tests/review.test.sh:11-12`, `tests/pilot.test.sh:17-25`). The research raised the first as an open question and the plan accepted it explicitly; the second overlap is never mentioned. Two implementations of one rule can drift apart. The doctrine's "same rule tested in two layers" applies, tempered by the fact that the lint is the generic net and the per-file tests only cover files someone remembered.
- minor — `tests/lint.test.sh:44-88` — the first use of `sed -i` in this suite, and the `s/…/…\n…/` replacements are GNU-only; BSD/macOS `sed` treats `-i` without a suffix as consuming the filename, so the mutation tests would break there. No target platform is stated in `AGENTS.local.md`, so this is a portability note for contributors, not a breach.
- minor — `bin/po-lint:131` — the "must not touch the code" check keys on the literal sentence `cannot edit files or run a shell` in a description, present in exactly one file (`method/commands/po-execute.md`). Reword that description and the sub-rule silently stops applying, with nothing to notice. Impact limited: `tests/execute.test.sh:11` independently asserts that command lacks `Write`/`Edit`/`Bash`, and `method/commands/po-review.md`, which also must not edit, is covered by `tests/review.test.sh:37-38`.
- minor — `docs/research/s25-method-lint.md:6-7` and `docs/plans/s25-method-lint.md:19` — both say "41 arrow rules" in the gate sections; the count on today's tree is 35. `docs/verif/` records 35, so the record is right and the upstream documents drifted. The calibration conclusion (0 counter-examples, lint green) is unaffected.

## Not verified
- **Any method tree other than this one.** All three rules are calibrated against this repository's `method/`; I confirmed they are green here and that both widening directions turn the suite red, but nothing here shows how they behave on a method tree written in another voice. `bin/po-lint` is not installed into user projects today, so the exposure is future. A person should run it against the first externally-written method tree before relying on it there.
- **That any agent obeys the rules the lint and the hardened tests check.** These are structural checks on prompt text — heading order, a trigger and its consequence on one line, a frontmatter tool list. I read no transcript and ran no end-to-end pass. The only behavioural evidence in this repository is under `docs/validation/`, and this story adds none. A person should run `/po-design` against a worktree with no `docs/design-system.md` and confirm it actually stops, and `/po-flow` on a story carrying an escalation signal and confirm no plan is written.
- **Lint and formatting of the shell sources.** `AGENTS.local.md` declares no linter or formatter (`Typecheck: —`, and no shell linter setting exists); I did not substitute `shellcheck`. A person who wants that coverage should add it as a setting first.
- **No screen in this story**, so no design artefact, no browser look and no `docs/design-system.md` conformity to judge: `docs/designs/s25-method-lint/` does not exist, correctly.
- **The full unit suite as first-hand evidence**: I reused the record for it, per `Verification mode: record`. I did run the 5 touched files directly (22 passed) and the full suite on the restored tree (140 passed).
- **Third parties**: none in this diff; `bin/po-lint` depends only on bash, coreutils, awk and grep, all of which I exercised directly rather than through a mock.

Max severity: major
Ship allowed: yes
