# Review — s18-design

Diff reviewed: `git diff m2-cadrage...story/s18-design` (one commit, d9b9f3a), read in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## When blocked
Not applicable.

## Evidence reused
- [x] `po-gate verif-current s18-design` exits 0. As a second check, `git diff --quiet 0c3761f… HEAD -- . ':(exclude)docs'` also exits 0, so the record's tree is the committed code. `Verification mode: record`, so I reused the record in `docs/verif/s18-design.md`: `bash tests/run.sh` exit 0, 113 passed, status complete. I did not rerun the full suite. The project has no type check, E2E or build command (`Typecheck: —`, `E2E: —`, `Build: —`), so none were run. I read the record's "Not proven here" section: the tests are structural only, and no story was ever run through the command.

## Plan
- [x] All 7 tasks are present: the `po-design.md` sections are in the planned order with the exact phrases, both templates have the planned sections, there is one indented help line, the D03 cell is updated, and there are 4 tests. Nothing outside the plan.
- [x] Run interdicts, one by one:
  - The diff is empty for `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `docs/stories.md`, `docs/decisions/`, `bin/`, `tests/lib.sh`, `method/AGENTS.md`, `method/agents/`, `method/skills/`, `method/templates/agents-local.md`, and every existing template and command except the one `po-help.md` line.
  - `docs/parite-killer-saas.md` changes only on D03.
  - No setting was added.
  - No orchestrator or status wiring.
  - No luminance or contrast arithmetic. `python3` appears only as `http.server`.
  - Overlap: the record shows it green. I did not re-run it.

## References
- [x] Every reference was opened and resolves:
  - the `design-doctrine` skill exists (`method/skills/design-doctrine/SKILL.md`);
  - `templates/design-screen.md` and `templates/design-brief.md` are created by this diff;
  - `Worktree root`, `Design source`, `Design skill` and `Design tool` all exist in `method/templates/agents-local.md:24-26,47-49`;
  - the worktree check matches `method/commands/po-plan.md:23` word for word;
  - the promise that setup stops on `Design source: —` (`po-setup.md:38`) is kept;
  - `/po-design-system` and `/po-research` exist.
- [x] `python3 -m http.server --bind 127.0.0.1 <port>` is valid syntax.

## Rules
- [x] Method files are in English, the `po-help` line is in French, the `Reads settings:` line is correct, and the command does not write source code.
- [x] No accepted ADR is contradicted. There is one small tension with the doctrine (see the minor findings).

## Tests
- [x] Four tests, one per criterion, and each phrase is pinned to its section. None of the six empty test shapes applies.
- [x] 4 tests against a budget of 25.
- [x] Bite checks, all in `method/commands/po-design.md`, each running only `bash tests/run.sh design.test.sh`:
  - **M1:** deleted the check 4 line (the `docs/design-system.md` is missing stop). Result: 1 failing test (`design_fails_closed_without_system_or_source`). Undone; `git diff --exit-code` clean.
  - **M2:** rewrote check 5 to "…write it into `AGENTS.local.md` for them, then continue." Result: **0 failing tests**. Undone; clean.
  - **M3:** replaced "Never both." with "A new screen may get both a mockup and a brief." Result: **0 failing tests**. Undone; clean.
  - **M4:** after "Nothing is measured here." added a python3 WCAG contrast computation that fails below 4.5:1. Result: **0 failing tests**. Undone; clean.
  - At the end `git status --porcelain` was empty.
- [x] No existing test was made useless by this story.

## Neighbours
- [ ] Not clean. `method/agents/implementer.md:18` lets only `docs/research/<id>.md`, `docs/plans/<id>.md` and `docs/reviews/<id>.md` be uncommitted. Any other change makes it stop and report. `method/AGENTS.md:53` (Law 4) has the same list. `/po-design` leaves `docs/designs/<id>/` uncommitted and says "the implementer commits them with the story". See the first finding below.
- [x] `po-help.md` places the design line between research and plan. The `every_command_listed_in_help` test passes, according to the record.

## Findings
- **major** — `method/commands/po-design.md:37` against `method/agents/implementer.md:18`. The command's handoff contract is at odds with the implementer's. `/po-design` leaves `docs/designs/<id>/` uncommitted for the implementer to commit, but the implementer treats any uncommitted file outside research, plan and review as "a change you did not make → stop and report". So a story that ran `/po-design` will halt at `/po-execute`. It stops rather than failing silently, but the new stage cannot reach commit. s20 owns `method/AGENTS.md` (Law 4), but no story in `docs/stories.md` owns `method/agents/implementer.md`, so no planned cycle fixes this. The research (`docs/research/s18-design.md`, Traps) cited Law 4 but did not open the implementer's allowlist. A person should decide which story takes the implementer change, or add it to s20's Owns.
- **major** — `tests/design.test.sh:21-28`, `method/commands/po-design.md:26`. Half of criterion 1 has no test that bites. The test checks only that the phrase `` `Design source` is `—` `` appears in `## Checks`, not that the command stops there or leaves the setting alone. M2, which makes the command write the setting for the user and continue, left every test green. The plan's pivot (c) names exactly this risk.
- **minor** — `tests/design.test.sh:357`, `method/commands/po-design.md:55`. "Exactly one" is pinned only by the phrase `exactly one artefact`. Under M3, a line allowing both artefacts passed. Plan pivot (d).
- **minor** — `tests/design.test.sh:368-373`. "Nothing is measured" is pinned as one sentence. Under M4, contrast arithmetic added right after it passed. Plan pivot (b). Tests that check phrases in prose have a natural limit here, but a `! grep -Ei 'ratio|luminance|4\.5'` on the section would bite cheaply.
- **minor** — `method/commands/po-design.md:51` against Step 2. When `Design skill` is `—` and the screen is new, the command stops "before drawing", but only after Step 2 has already written `design.md`. The worktree is then left with a half-finished note that may name an artefact that will not exist. The wording follows the plan; stopping in Checks, before anything is written, would be cleaner.
- **minor** — `method/commands/po-design.md:34`, `method/templates/design-screen.md:3` against `method/skills/design-doctrine/SKILL.md` ("the committed version wins"). The command says files that are still uncommitted are "the source of truth". This is consistent in intent, since they get committed with the story, but the wording differs.
- **minor** — `method/commands/po-design.md:4-11`. `allowed-tools` has neither `Skill` nor any browser or MCP tool, yet Step 3 draws "with the skill named in `Design skill`" and Step 4 opens "whatever browser tool the session has". This works if `allowed-tools` only pre-approves tools, and not if it restricts them. I did not verify this. `po-design-system.md` has the same pattern.

## Not verified
- **No real run of `/po-design`.** I did not run it on a story with a screen, in either `internal` or `external` mode, so how an agent actually behaves (the derived-or-new call, the note, the artefact, the approval) is unobserved. A person should run it once in each mode on a throwaway story with a screen, then follow it with `/po-execute` to confirm the implementer blocking described in the first major finding.
- **No browser, no mockup served.** The story ships prose, so the Step 4 serve-and-look loop was never exercised. The same throwaway run should cover it.
- **Full suite and overlap test not rerun.** I relied on the current record (113 passed), including `method_does_not_reuse_killer_saas_text` running with the Killer SaaS sources present. A person can rerun `bash tests/run.sh overlap.test.sh` if they doubt those sources were present.
- **`allowed-tools` semantics in Claude Code** (restrict or pre-approve) and whether a `Design skill` or browser MCP tool can be called from this command: not verified. Check by running the command.
- **Installer:** I did not check that `bin/polype-dev-install` copies the two new templates into `.polype/templates/`. The research says the installer copies them wholesale. Run the installer in a scratch directory to confirm.
- **Type check, E2E, build:** the project has none of these commands, so none were run.

Max severity: major
Ship allowed: yes
