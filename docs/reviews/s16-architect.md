# Review — s16-architect

[Story](../stories.md) · [Plan](../plans/s16-architect.md) · [Verification](../verif/s16-architect.md)

Diff reviewed: `git diff m2-cadrage...story/s16-architect`, one commit (77ed0cf), read by a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s16-architect` exited 0. I also checked by hand: `git diff --quiet 594a62cb… HEAD -- . ':(exclude)docs'` exited 0, so the recorded Tree is the committed code. With `Verification mode: record`, I relied on `docs/verif/s16-architect.md` (status complete; `bash tests/run.sh` exit 0, 105 passed, 0 skipped) and did not rerun the full suite. The project has no Typecheck, E2E or Build command (all `—`), so none was run. The record's "Not proven here" section says the command was never run live and the installer rerun and commit are untested. I agree, and those points are in "Not verified" below.

## Plan
- [x] All 7 tasks are present: the template, the command with its sections in the planned order and its exact phrases, the po-setup.md:17 clause, the po-help line after `/po-stories-review`, the four tests, the C07/B04 cells and the record. Nothing was changed outside the plan.
- [x] Each run interdict, checked one by one:
  - These paths have an empty diff: `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `docs/stories.md`, `docs/decisions/`, `tests/lib.sh`, `method/AGENTS.md`, `method/agents/`, `method/skills/`, `method/templates/agents-local.md` and `method/templates/adr.md`.
  - Existing tests are untouched.
  - The parity file changes only on the B04 and C07 lines.
  - No new setting was added.
  - The new files do not mention `docs/references/`, `~/dev/vault`, `/spec` or Polype ADR numbers.
  - The overlap test passed against the sources, according to the record.

## References
- [x] Every reference is real:
  - `method/skills/codebase-analysis/SKILL.md` exists.
  - `templates/adr.md` has the `adr`, `status` (with `superseded`), `scope: framing`, `supersedes` and `superseded-by` fields the command uses.
  - `## Conventions` and its placeholder exist in `method/templates/agents-local.md:66-68`.
  - Every setting in `Reads settings:` exists in the template (`Target branch`, `Package manager`, `Install`, `Test`, `Typecheck`, `E2E`, `Build`).
  - The installer (`bin/polype-dev-install`) appends `AGENTS.local.md` to `AGENTS.md`, so the "rerun the installer" step does what it says.
- [x] The capability list in Step 3 matches `docs/conception.md` ("Capacités à couvrir", 12 items). The path format `docs/decisions/NNNN-<slug>.md` matches `method/AGENTS.md:68`.

## Rules
- [x] `AGENTS.md` conventions are respected. Method files are in English and po-help is in French. The command has a `Reads settings:` line, reads the project commands from the settings and never decides them, and checks for environment files before committing.
- [x] No accepted ADR is contradicted: ADR-0009 (one brick per capability, chosen at architecture), ADR-0006 (no Killer SaaS text) and the rule that accepted ADRs are superseded, never edited.

## Tests
- [x] The assertions quote the clause behind each criterion; the section-scoped greps tie `codebase-analysis` to Step 2 and the stack, capability and integration words to Step 3. None of the six empty test shapes applies: the tests read the file under test, with no mocks and no fixtures.
- [x] 4 tests, well within the budget of 25.
- [x] Bite, three mutations. Each was run on the listed test files only, then undone, and `git diff --exit-code method/commands/po-architect.md` was clean each time. The worktree is clean at the end (`git status --porcelain` is empty).
  1. In Step 2, "Apply the `codebase-analysis` skill to the base:" replaced by "Look at the base:" → `architect.test.sh`: 1 failing test (`architect_analyses_code_before_deciding`).
  2. "Each structural choice becomes one ADR in" replaced by "Some structural choices become an ADR in" → `architect.test.sh`: 1 failing test (`architect_records_structural_decisions_as_adrs`).
  3. Deleted the Step 4 sentence "Replace only that section's placeholder or body, with Edit; every settings block stays as it is — this command reads settings, it never decides them." → `architect.test.sh` and `structure.test.sh`: **0 failing tests** (13 passed).
- [x] This story makes no existing test useless.

## Neighbours
- [x] `docs/architecture.md` is read by `po-research.md:38`, `po-plan.md:30` and `implementer.md:9`, and `method/AGENTS.md:64` says it is committed on the target branch. The command now produces it, on that branch. Nothing is broken.
- [x] `po-setup.md:17`: `setup_never_overwrites_settings` still finds its phrase, and `po-setup.md:41` ("Leave the conventions placeholder as it is") agrees with `/po-architect` being the one that fills it.

## Findings
- major — `method/commands/po-architect.md:49` — The guard that protects the settings when `AGENTS.local.md` is written ("Replace only that section's placeholder or body … every settings block stays as it is") is covered by no test. Deleting it fails 0 tests (mutation 3). The plan names this as a way the story could go wrong (pivot b). The only related test, `setup_never_overwrites_settings`, checks po-setup, not this command.
- major — `method/commands/po-architect.md:49` together with `:22` — On a rerun, `docs/architecture.md` is amended, but the Conventions body is replaced. Any convention a person wrote by hand, or added in an earlier run, can be lost. The only protection is the grouped approval in step 2 of "Approval and commit", which shows the new draft but not what it removes. The rerun path should say that existing rules are kept or amended, not overwritten.
- minor — `method/commands/po-architect.md:33` against `:38` — For the "empty repository, assumed" answer, the flow jumps to step 3 "with nothing to analyse", while step 2 states "No decision is drafted before this analysis is done." That sentence reads as absolute, so the exception should be stated there. Step 4 also asks for a `path:line` behind each rule, which an empty repository cannot give, and the command does not say what goes into Conventions in that case.
- minor — `method/commands/po-setup.md:17` — The new exception clause (only `/po-architect`, only the « Conventions » section) is not pinned by any test. It could drift back to "no other command writes this file" and nothing would notice.
- minor — `method/commands/po-architect.md:26` — "when Polype's repository is at hand" gives no way to locate it: no setting and no path. The research already expected this in M2 (no catalogue before M4), but an agent has nothing concrete to look for.

## Not verified
- **No live run of `/po-architect`** on a real repository, whether it holds a base or is empty. The tests only check that the file states its rules, not that an agent following it behaves as written: asking once, editing only `## Conventions`, numbering ADRs, the grouped approval, and a commit on the target branch named `docs: architecture`. A person should run it once on a scratch repository with a small boilerplate, and once on an empty repository, then check the diff of `AGENTS.local.md` (settings blocks unchanged) and the new ADRs.
- **The rerun path** (`docs/architecture.md` already present, ADRs superseded) was not exercised. Run it twice on the scratch repository, with the same person-authored conventions in place.
- **Installer rerun from a target project**: I read `bin/polype-dev-install` but did not run it after `AGENTS.local.md` changed. Check that the new conventions appear at the end of the regenerated `AGENTS.md`.
- **Profile lookup** (`boilerplates/<name>/profile.md`): no catalogue exists yet (M4), so this branch cannot be exercised.
- **Overlap with Killer SaaS text**: I relied on the record's full-suite run, which says the sources were present. I did not rerun `overlap.test.sh`.
- The project has no type check, E2E or build command, so none was run.

Max severity: major
Ship allowed: yes
