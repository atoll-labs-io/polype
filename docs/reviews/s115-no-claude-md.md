# Review — s115-no-claude-md

Review status: complete
Reviewed tree: ffe24897ddedcfaac311542c2c77e6975d713e68
Fix loop: 0
Scope: `git diff main...story/s115-no-claude-md` (one commit, 6170f08)
Lenses run: none (nothing in the diff touches auth, routes, migrations, lockfiles or server code)

## Scope check (Owns)
I checked every changed path against the `Owns` line in `docs/stories.md:1787`.
- `bin/polype`, `method/AGENTS.md`, `method/hooks/po-gate.sh`, `method/hooks/po-session.sh`, `method/commands/po-setup.md`, `method/commands/po-architect.md`, `docs/installation.md`, `tests/install.test.sh` and `tests/no-claude-md.test.sh` are all listed in `Owns`.
- `docs/research/`, `docs/plans/` and `docs/verif/` for s115 are the story's own pipeline evidence, so they are in scope.
- `docs/decisions/ADR-0086-…md` is a new file (status A) and the plan names it, so it is in scope.
- `docs/decisions/ADR-0073-…md` is an existing ADR the diff modifies, and `Owns` does not list it. A written rule requires the edit (Law 6: "only its frontmatter links … plus its `status`, set to `superseded`"), and the diff touches exactly those two frontmatter lines. This is a gap in `Owns`, reported as minor.
- Other running lane: `story/s116-eval-arms-same-environment` owns `bin/po-eval` and two test files. No overlap.
- `.claude/` and `.polype/` are not in the diff, so that run interdict holds.

## Evidence reused
- `po-gate verif-current s115-no-claude-md` exits 0. `Verification mode: record` applies: the unit suite (`bash tests/run.sh`, exit 0) is proven for this code, so I did not rerun the whole suite. The project has no type check (`Typecheck: —`).
- I read the record's "Not proven here": the installed copies are not refreshed, and Claude Code's CLAUDE.md-over-AGENTS.md precedence is taken from the ADRs, not tested.
- The story has `QA stage: —` and `Surface: —`, so there is no QA and no design to check.
- `po-gate floor-guard s115-no-claude-md main` exits 0: nothing was lowered.

## Steps
1. **Reuse of proven results:** see above.
2. **References:** I opened each one and they all exist.
   - `refuse` (`po-gate.sh:23`) returns 1, which is what `|| found=yes` relies on.
   - `wire_the_project` is called by `cmd_install` (`:395`) and `cmd_update` (`:438`); `cmd_init` goes through `cmd_install`. The early `return` for global mode comes before `absorb_claude_md`, so the global `~/.claude/CLAUDE.md` is never reached.
   - `drop_legacy_claude_md_import` is now called only from `unwire_the_project` (`:482`).
3. **Diff against the plan:** all seven tasks are present as written.
   - The absorption runs before `assemble_agents_md`.
   - The sources are deleted only after `mv -f` has replaced `AGENTS.local.md`.
   - Without an `AGENTS.local.md`, the file is left in place and a message goes to stderr.
   - `secret_scan` and its count are unchanged.
   - `po-session` adds no git call and writes nothing.
   - The plan's Reuse table matches the diff.
   - The change to the existing `install.test.sh` test is justified in the plan.
4. **Tests:** 4 new tests and 1 changed, within the `Test budget` of 25. No hollow test found: the tests run the real `bin/polype`, `po-gate.sh` and `po-session.sh` in scratch directories, with no mocks. The pre-commit test uses `git add -f` so a global gitignore cannot make the index empty. Bite results (one mutation at a time; after each one I restored the file and confirmed it with `git diff --exit-code`):
   | Mutation | Tests run | Failed |
   | --- | --- | --- |
   | `po-gate.sh` `case`: `CLAUDE.md\|CLAUDE.local.md` changed to `CLAUDE.mdXX` | no-claude-md, gate | 1 (precommit_refuses_claude_md) |
   | `po-gate.sh`: `--diff-filter=d` removed | no-claude-md | 1 (deletion phase) |
   | `bin/polype`: `absorb_claude_md` moved after `assemble_agents_md` | no-claude-md, install | 1 (AGENTS.md lacks `# Project notes`) |
   | `bin/polype`: collect step uses `cat` instead of `grep -vx '@AGENTS.md'` | no-claude-md | 1 (import moved into AGENTS.local.md) |
   | `bin/polype`: the no-`AGENTS.local.md` guard set to `false` | no-claude-md, install | 2 |
   Every rule I disabled turned at least one test red.
5. **Values that look right:**
   - The heading `## Notes moved from CLAUDE.md`, the `polype update .` hint and the shared sentence match the story and plan text.
   - A missing final newline in `AGENTS.local.md` is handled by the `tail -c 1` test.
   - GNU grep ends its output with a newline even when the source's last line has none.
6. **Neighbours:**
   - `install_writes_no_claude_md` (`tests/install.test.sh:48-53`) and `installer.test.sh:106` still pass. They pass only because their projects have no `AGENTS.local.md` (see minor 3).
   - `docs/installation.md:9-10` still cites ADR-0073 (minor 2).

## Findings
- **minor 1 — `Owns` gap: `docs/decisions/ADR-0073-plus-de-claude-md-claude-code-lit-agents-md.md`.** The Law 6 rule requires the superseding frontmatter edit (`status: superseded`, `superseded-by: [ADR-0086]`), and the story notes ask for it. The implementer did nothing wrong; the story's `Owns` line just does not list the file.
- **minor 2 — stale ADR reference.** `docs/installation.md:9-10` still says "Aucun `CLAUDE.md` : Claude Code lit `AGENTS.md` de lui-même (ADR-0073)". ADR-0073 is now superseded, so this should point to ADR-0086.
- **minor 3 — the test name and message in `tests/install.test.sh:48-53` (`install_writes_no_claude_md`) no longer say what the test checks.** Its failure text "install touched the project's own CLAUDE.md" now holds only because that scratch project has no `AGENTS.local.md`. With one, the file is absorbed by design.
- **minor 4 — punctuation.** In `method/commands/po-setup.md:56` and `method/commands/po-architect.md:72`, the reference sits after the sentence's full stop: "…in `AGENTS.local.md`. (ADR-0086)". `method/AGENTS.md` puts the reference inside its sentence instead.
- **minor 5 — something for the person to decide: `CLAUDE.local.md` moves into a tracked file.** `CLAUDE.local.md` is usually a private, gitignored file. Absorbing it puts its content into `AGENTS.local.md`, which is committed, and from there into the generated `AGENTS.md`. The story and ADR-0086 ask for exactly this, so the code is not at fault. But ADR-0086's Consequences do not mention that private notes become shared. That touches personal data, which AGENTS.md lists among the reasons to ask the person, so they should confirm it.

## Not verified
- **Claude Code's actual precedence** (it reads `CLAUDE.md`/`CLAUDE.local.md` instead of `AGENTS.md`) is taken from ADR-0073/0086, not observed. To cover it, start a Claude Code session in a scratch project with and without a `CLAUDE.md` and see which rules load.
- **`.claude/CLAUDE.md` inside a project** is neither absorbed nor flagged by `po-session`. The pre-commit does refuse it, because it matches on the basename. The story scope covers root files only, and I did not check whether Claude Code treats that path the same way as a root `CLAUDE.md`.
- **The installed copies** (`.polype/hooks/`) of this repository still run the old behaviour until a `polype update`, as the record says. I did not exercise the new pre-commit as a real git hook, only as `po-gate.sh pre-commit`.
- **I did not rerun the full suite.** I relied on the `po-run` record on this code (`Verification mode: record`).
- **Edge cases I did not test:** a symlinked `AGENTS.local.md` (the `mv` would replace the link with a regular file), an `@AGENTS.md` line ending in CRLF (it would not be stripped), and repeated absorptions (each adds another `## Notes moved from CLAUDE.md` heading).

The worktree is clean after the bite proof (`git diff --exit-code` passes), and the tree was the same at the start and at the end of the review.

Key files:
- /home/lecrabe/dev/atoll/polype/.worktrees/s115-no-claude-md/bin/polype
- /home/lecrabe/dev/atoll/polype/.worktrees/s115-no-claude-md/method/hooks/po-gate.sh
- /home/lecrabe/dev/atoll/polype/.worktrees/s115-no-claude-md/method/hooks/po-session.sh
- /home/lecrabe/dev/atoll/polype/.worktrees/s115-no-claude-md/tests/no-claude-md.test.sh
- /home/lecrabe/dev/atoll/polype/.worktrees/s115-no-claude-md/docs/installation.md

Max severity: minor
Ship allowed: yes
