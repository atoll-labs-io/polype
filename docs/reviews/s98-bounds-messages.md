# Review: s98-bounds-messages

[Story](../stories.md) · [Plan](../plans/s98-bounds-messages.md) · [Verification](../verif/s98-bounds-messages.md)

I reviewed `git diff main...story/s98-bounds-messages` in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 20fc9faa3d5834875bc0cdffad26a1ab75c5bca5

## When blocked
Not blocked. I took the tree again just before answering and it was still 20fc9faa…; the worktree was clean (`git status --porcelain` empty).

## Ownership
I listed the diff with `git diff --name-only main...story/s98-bounds-messages`.
- [x] **Every path is inside `Owns` or covered by construction.**
  - `method/hooks/po-bounds.sh`, `method/agents/implementer.md`, `docs/installation.md`, `tests/bounds.test.sh`, `tests/bounds-messages.test.sh`, ADR-0050 and ADR-0052 are all in `Owns`.
  - `docs/research|plans|verif/s98-bounds-messages.md` are this story's own evidence.
  - ADR-0072 is added (status `A`) and the plan names it.
- [x] **Outside `Owns`:** none.
- [x] **Inside another running story's `Owns`:** none. `s97-commands-and-texts` is running: its worktree is listed and it is not an ancestor of main (`merge-base --is-ancestor` exits 1). Its `Owns` and its diff share no path with this one.
- [x] **The story has an `Owns` line.**

## Evidence reused
- [x] **`po-gate verif-current s98-bounds-messages` passes (exit 0).** I reused the record `/home/lecrabe/dev/atoll/polype/.worktrees/s98-bounds-messages/docs/verif/s98-bounds-messages.md`:
  - "Unit suite `bash tests/run.sh`" exited 0 on a tree whose code outside `docs/` equals `Tree:`.
  - Type check: the project has none (`Typecheck: —`).
  - E2E and Build: the project has neither (`E2E: —`, `Build: —`).
  - I read its "Not proven here" section; it is carried into Not verified below.
- [x] **`po-gate qa-current`:** not required. `Surface: —`, so the story does not go to QA.

## Plan
- [x] **Every task is present and nothing lies outside the plan:**
  - Task 1: `deny()` filters `\036`, and both messages now say "po-bounds cannot read".
  - Task 2: `{name}` is dropped in the lexer, and the comment at `:46` is updated.
  - Task 3: `lane()` gets its own TMPDIR, and the trap of `reviewer_lane` is extended.
  - Task 4: `temp_root` now runs for every mode but qa; the throwaway computation is done; `checkout` is split out; the path and redirect checks run in the throwaway repo; the header comment is updated.
  - Task 5: the texts and the `superseded-by` lines.
  - Task 6: the three tests.
  - Task 7: the `po-run` row.
- [x] **Each run interdict checked:**
  - `.claude/` and `.polype/` are untouched.
  - `po-execute.md` and `defect-and-routing-paths.test.sh` are untouched.
  - ADR-0050 and ADR-0052 change only their `superseded-by` line.
  - qa mode is unchanged apart from `deny`/`{fd}`, and `temp_root` is still skipped for qa.
  - The reviewer branch `:683-747` keeps its logic; only two message strings changed.
  - No `expect` value changed in `tests/bounds.test.sh`.
  - The awk stays POSIX (bracket expressions, no `\{`).
  - No file lies outside `Owns` or `docs/`.

## References
- [x] **Every function the diff calls was opened and confirmed:** `try_story_of_dir` (`:62`), `in_temp_zone` (`:89`), `temp_root` (`:77`), `under_temp` (`:85`), `check_temp_paths` (`:626`), `check_redirects` (`:648`), `readable` (`:302`), and `scratch_repo` in `tests/lib.sh`, together with the `run.sh` harness (one `bash -c` per test).
- [x] **Values checked:**
  - The `{name}` regex matches bash's varname rule.
  - The `/dev/*` exceptions are unchanged and match ADR-0053.
  - The tests' TMPDIR isolation holds: `LANE_TMP` and `SCRATCH` are sibling `mktemp -d` dirs, and `TMPROOT` nests under `LANE_TMP`.

## Rules
- [x] **`AGENTS.md` and local conventions are respected:** the method text is in English, there is one test file per story, and the test names match the criteria.
- [ ] **One accepted ADR's promise is not fully kept.** ADR-0072 promises "rien n'en sort vers le worktree", and the implementer's throwaway zone does not keep it against the `--work-tree` family (see M1).

## Tests
- [x] **Floor:** `po-gate floor-guard s98-bounds-messages main` exits 0; nothing was lowered.
- [x] **Assertions pin down the criteria, with none of the six empty shapes.** The hook is fed real command JSON, and the clone and linked worktree fixtures are real repositories.
- [x] **Budget:** 3 new tests, within `Test budget` 25.
- [x] **Bite.** I ran only `bounds-messages.test.sh` and `bounds.test.sh`. Each change was undone and `git diff --exit-code method/hooks/po-bounds.sh` came back clean:
  - A. checkout allowed outside the throwaway repo (`[ "$throwaway" = yes ]` → `true`): 5 failing tests.
  - B. path and redirect checks off in the throwaway repo (`if false`): 1 failing test.
  - C. `deny` filter off: 1 failing test.
  - D. `{name}` branch removed from the lexer: 1 failing test.
  - E. "story worktree judged first" removed (`! try_story_of_dir "$dir" &&`): **0 failing tests** (m1).
- [x] **No test made useless.** `bounds.test.sh` changed only its setup and traps, as the plan announced.

## Neighbours
- [x] **Callers and texts read, nothing broken:**
  - `deny` has many callers, and the filter is harmless for all of them.
  - `readable` is kept.
  - The lexer is shared by all modes, and `{fd}` now becomes a redirect target, which `check_redirects` reads in the temp zone. My probe `cd <clone> && git log {fd}><worktree>/x` was refused, as expected.
  - Other texts that forbid `checkout` (`AGENTS.md` Law 4, po-research, po-flow, po-drive, planner, designer) concern worktree setup and are still accurate.
  - The reviewer agent's own temp-dir rule is unchanged.

## Lenses
Lenses run: security. It was triggered by `method/hooks/po-bounds.sh`, which is the permission and policy guard of the agents (the rules that decide where they may write).
- [x] Each lens finding is graded and listed below.

## Findings
- **major — `method/hooks/po-bounds.sh:752-782`, ADR-0072 "Dans le dépôt jetable" (`docs/decisions/ADR-0072-l-implementer-explore-un-depot-jetable-du-repertoire-temporaire.md`), `docs/installation.md:87-90`.**
  - **The open route.** In implementer mode, a `checkout` in the throwaway repo now passes when git is pointed at the story worktree by `--work-tree=<WT>`, `-c core.worktree=<WT>` or `GIT_WORK_TREE=<WT>`. I probed the hook directly in a throwaway clone under /tmp, and all three exited 0:
    - `git -C <clone> --work-tree=<WT> checkout main -- .`
    - `git -C <clone> -c core.worktree=<WT> checkout main -- .`
    - `GIT_WORK_TREE=<WT> git -C <clone> checkout main -- .`

    The reviewer mode refuses all three; the implementer mode checks none of them. Before this story, implementer `checkout` was refused everywhere, so this route is new.
  - **Why it is not a hook fix.** These are deliberate forms, not mistakes. Following ADR-0052, the request is a new ADR that adds them to the list of accepted bypasses, not a change to the hook.
  - **The overstatement.** ADR-0072 ("rien n'en sort vers le worktree") and `installation.md` currently say more than the hook holds.
- **minor — `method/hooks/po-bounds.sh:754`.**
  - **The untested rule.** The rule "a story worktree is judged first" (`! try_story_of_dir "$dir"`), which ADR-0072 states under "Ordre", fails no test when removed (bite E: 0 failures). `$WT` never lies under the tests' TMPDIR, so the branch is never exercised.
  - **Narrow reach.** It matters only when the whole project lives under `$TMPDIR`. In that setup the main checkout already counts as a throwaway repo by the ADR's own definition, as the plan's pivot accepts.
- **minor — `method/agents/implementer.md:23`.**
  - **The text.** It tells the implementer to "clone it under the temp dir" but never says that a local source must be cloned as `file://<path>` when the clone runs from the temp dir.
  - **The probe.** `cd /tmp/... && git clone <worktree path> r3` was refused, which is the cost ADR-0072 accepts. Only `docs/installation.md` mentions `file://`; the reviewer's agent file states it.

## Not verified
- **Live sessions.** `.claude/` and `.polype/` still hold the old hook until the post-ship refresh, so the hook guarding real sessions is not the one reviewed (record, "Not proven here"). A person should rerun a throwaway-clone checkout in a real implementer session after the refresh.
- **Real behaviour after the `git clone` refusal.** Whether a real implementer turns to a `file://` clone after `cd /tmp && git clone /local/path x` is refused was not exercised (record).
- **Other awk implementations.** The `{name}` lexer branch ran only under gawk (and `gawk --posix`); BWK awk and mawk are not installed here (record). Someone should run `bash tests/run.sh bounds-messages.test.sh` on macOS or with mawk.
- **Suite, type check, E2E, build.** I did not rerun the full suite; I relied on the current `po-run` record. The project has no type check, E2E or build (`—`).
- **Commands that read nothing back.** I did not probe implementer git commands whose arguments look like paths but are not, such as `git -C <clone> log -- '<pathspec magic>'` or `remote add` with a local path. Only the forms listed above were exercised.
- **Refused command.** One of my commands was refused by po-bounds: `git -C /home/lecrabe/dev/atoll/polype merge-base …`, because it runs git in the main checkout. I got that information by running the same reads with `git -C <story worktree>`, the route the reviewer agent file prescribes. No other gesture was needed.

Max severity: major
Ship allowed: yes
