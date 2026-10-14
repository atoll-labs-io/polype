# Review — s136-session-hint-infers-init

[Story](../stories.md) · [Plan](../plans/s136-session-hint-infers-init.md) · [Verification](../verif/s136-session-hint-infers-init.md)

Diff reviewed: `git diff origin/main...story/s136-session-hint-infers-init`, in a context that did not write it. I used `origin/main` as the target branch because the local `main` ref is behind. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: d5d4a6c32be6abe3e5249023f1f76cfecf7df0cc

## When blocked
Not applicable.

## Ownership
Diff listed with `git diff --name-only origin/main...story/s136-session-hint-infers-init`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`. `tests/update-keeps-mode.test.sh` is the story's only `Owns` entry. The other three paths are this story's own plan, research and verif files under `docs/`, which are in scope by construction.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. s135 also owns this test file, but `git worktree list` shows no s135 story worktree, and s135 shipped.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s136-session-hint-infers-init` → exit 0, so the record is reused: `bash tests/run.sh` exited 0. I also read its "Not proven here" section. The project has no type check (`Typecheck: —`), no E2E (`E2E: —`) and no build (`Build: —`), so none was run.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Task 1: the test is present, placed after `test_hints_say_init`, and has both halves. The init project with `.polype/mode` removed expects `polype init .`. The full install with `.polype/mode` removed expects `polype update .`. It also checks the plan's pivot: the manifest holds a `.claude/commands/` line before the mode file is removed.
- [x] Task 2: the record is complete and its run is green.
- [x] Run interdicts, one by one:
  - (1) Nothing outside `tests/update-keeps-mode.test.sh` and `docs/` changed. `method/hooks/po-session.sh` and `bin/polype` have an empty diff.
  - (2) The existing tests in the file are unchanged. The diff only adds lines, all of them after `test_hints_say_init`.
  - (3) Nothing touches #95, #96 or #97.

## References
- [x] Every call opened and confirmed in the test file:
  - `fresh_project` and `run_polype` (`tests/update-keeps-mode.test.sh:9-23`)
  - `$HOOK` (`:5`, `$METHOD/hooks/po-session.sh`)
  - `fail` (`tests/lib.sh`)
- [x] The expected line matches what the hook prints at `method/hooks/po-session.sh:251`, with the value of `again` set at `:241-247`. `${line/polype init ./polype update .}` is a literal bash substitution and gives the `update` form.
- [x] No value that only looks right. The test rewrites `CLAUDE.local.md` after the second `install` because, with `absorbed`, the installer absorbs that file. That rewrite is needed.

## Rules
- [x] `AGENTS.md` and `AGENTS.local.md` conventions are respected: a bash test, the criterion's name matches the test function's name, and existing tests are untouched.
- [x] No accepted ADR is contradicted. The inference behaviour comes from ADR-0091 and is unchanged.

## Tests
- [x] Floor: `po-gate floor-guard s136-session-hint-infers-init origin/main` → exit 0, nothing lowered.
- [x] The assertions pin down both halves of the acceptance criterion with exact-line matches (`grep -qxF`). None of the six empty test shapes: the test runs the real installer and the real hook, with no mocks.
- [x] Within `Test budget`: 1 of 25.
- [x] Bite. Baseline: `bash tests/run.sh update-keeps-mode.test.sh` gives 7 passed.
  - (a) Added `&& false` inside the inference branch at `po-session.sh:245` → 1 failing test (`session_hint_infers_init_without_mode`).
  - (b) Replaced the `! grep -q '^\.claude/commands/'` manifest test with an always-true check, so a full install is also taken for init → 1 failing test. The failure is in the full-install half ("po-session does not infer a full install without .polype/mode").
  - Undone with `git restore`, then `git diff --exit-code method/hooks/po-session.sh` was clean and `git status --short` is empty.
- [x] No test is made useless by the story.

## Neighbours
- [x] No code changed. The other tests of the hook (`tests/claude-md-setting.test.sh`, `tests/project-lead.test.sh`) are untouched, and the recorded full suite is green.

## Lenses
Lenses run: none. The diff is one test file plus pipeline docs, and no lens trigger matches it.
- [x] No lens findings.

## Findings
- minor — `tests/update-keeps-mode.test.sh:121-122`: the `AGENTS.local.md` `printf` is copied verbatim from `test_hints_say_init` (`:99-100`). A small helper (for example `absorbed_settings`) would keep the two tests from drifting apart.

## Not verified
- The live session-start display in a real Claude Code session on a pre-M13 project (pecten, nautile) was not observed. Only the hook's stdout in a throwaway project was checked. A person should run `bash .polype/hooks/po-session.sh` in pecten or nautile after removing `.polype/mode` (or before repairing with `polype init .`) and check that the hint names `polype init .`.
- The project has no type check, E2E or build, so none was run.

Max severity: minor
Ship allowed: yes
