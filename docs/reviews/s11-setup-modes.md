# Review — s11-setup-modes

[Story](../stories.md) · [Plan](../plans/s11-setup-modes.md) · [Verification](../verif/s11-setup-modes.md)

Diff reviewed: `git diff m2-cadrage...story/s11-setup-modes` (commit 8ce9bdc), in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s11-setup-modes` exited 0. I also ran `git diff --quiet c6a3caf… HEAD -- . ':(exclude)docs'` and it exited 0, so the record's tree matches the committed code. With `Verification mode: record`, I reused the record: task tests exit 0 (3 passed), full suite `bash tests/run.sh` exit 0 (82 passed, including `overlap.test.sh` and `structure.test.sh`). The project has no Typecheck, E2E or Build command (all `—`), so none was run. I read the record's "Not proven here" section. It lists three things: how setup behaves when an agent runs it, that no design command exists yet, and that this repo's `AGENTS.local.md` lacks the new settings.

## Plan
- [x] All five tasks are present. Nothing is outside the plan: the diff touches only the two owned `method/` files, the new test file, the B02 and C01 status cells in the parity matrix, and the story's research, plan and record under `docs/`.
- [x] Each run interdict checked:
  - `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `tests/structure.test.sh` and `tests/lib.sh` have an empty diff.
  - The only `method/` files changed are `po-setup.md` and `templates/agents-local.md`.
  - In the parity matrix, only the Statut cells of B02 and C01 changed.
  - No command reads the new settings: `Reads settings: none` is unchanged and no other method file mentions them.
  - Killer SaaS overlap is clean according to the reused suite run.

## References
- [x] The helpers the tests use exist where the research says: `template_settings` (tests/lib.sh:32), `contains`, `fail`, `$METHOD`. The three phrases quoted by `structure.test.sh` are kept verbatim in `po-setup.md`.
- [x] The defaults (`Story track: auto`, `Flow threshold: 2`) match the story notes in docs/stories.md:170. `—` for `Entry mode` and `Design source` is required by criterion 3 and argued in the plan's pivot section.

## Rules
- [x] `AGENTS.md` conventions respected: method text in English, one test file per story, criterion names used as test function names, matrix cells updated.
- [x] No accepted ADR contradicted. ADR-0006 overlap is covered by the reused suite run.

## Tests
- [x] The assertions pin down the three criteria. None of the six empty test shapes: the tests read the real files under test, with no fixtures or mocks.
- [x] 3 tests, within `Test budget` 25.
- [x] Bite. After each change I ran only `setup-modes.test.sh`, restored the file from a copy, and `git diff --exit-code` came back clean:
  - removed the `Design source` table row → 1 test failed (`settings_template_declares_framing_settings`)
  - removed the `Design skill:` line from the settings block → 1 failed (same test)
  - removed setup question 4 → 1 failed (`setup_asks_entry_mode_and_design_source`, "lists 4 questions")
  - added a sixth question → 1 failed (same test, "lists 6 questions")
  - replaced "every design command stops on it and asks for the source again" with a silent default → 1 failed (`setup_never_defaults_design_silently`)
  - Final `git status --porcelain` and `git diff --exit-code` on the whole worktree: clean.
- [x] No existing test is made useless by the story.

## Neighbours
- [x] The only other readers of the template are `tests/structure.test.sh:10,19,30` and `tests/lib.sh:33`. The new lines follow the `Name: value` format they expect, and the reused suite run is green. No installer or hook parses these setting names.

## Findings
- major — method/commands/po-setup.md:33 — Question 4 says to ask for `Design skill` "when the answer is `internal`" "in the same call". But AskUserQuestion shows all of a call's questions at once and collects all the answers together, so the follow-up can't depend on the source answer within one call. An agent following this literally has two choices: make a sixth call, which breaks "one AskUserQuestion call each" and the five-question limit, or ask for the skill and the tool whatever the answer. Either way it strays from the text. Contained, no silent damage (nothing reads these settings yet). Possible fix: ask the source together with a free-text "skill or tool name" in the one call, then write the name to the setting the answer selects.
- minor — method/templates/agents-local.md:23-24,47 and po-setup.md:38 — `—` now has a second meaning. For `Entry mode` and `Design source` it means "not chosen yet, stop and ask". But `AGENTS.md` ("Reading settings") and parity line A08 define `—` as "this project has none". A project with no screens now has no way to say "no design": the design commands would keep asking. The story's criterion 3 requires this behaviour, so it isn't an implementation mistake. It should be settled (for example with a distinct `none` value) before s18/s19/s20 read the setting.
- minor — method/commands/po-setup.md:33 — The "not decided yet" option isn't linked explicitly to writing `—`. The link only comes from the template default and line 38. One clause ("which leaves it at `—`") would remove the ambiguity.
- minor — tests/setup-modes.test.sh:14-17 — `Design skill`, `Design tool` and `Flow threshold` are checked only for having a row in the table, not for its content. That is acceptable for this criterion; noted for completeness.

## Not verified
- How `/po-setup` behaves when an agent actually runs it: the five AskUserQuestion calls, the conditional skill/tool prompt, and the `AGENTS.local.md` it writes. I have no sandbox project to run it in. A person should run `/po-setup` in a throwaway repository once for each design source (`internal`, `external`, not decided) and check the call count and the resulting settings.
- The "design commands stop on `—`" rule: no design command exists yet. It has to be checked in s18/s19/s20 against the real commands.
- I didn't check how s12/s13 should treat `Entry mode: —` (neither story says). Their plans should decide.
- This repository's own `AGENTS.local.md` doesn't declare the six new settings. That file isn't owned by this story. Someone should add them on `m2-cadrage` before any command reads them here.
- I didn't rerun the Killer SaaS overlap or the full suite. They are taken from the record, which matches the committed tree.
- The project has no type check, E2E or build command (all `—`), so none exists to run.

Max severity: major
Ship allowed: yes
