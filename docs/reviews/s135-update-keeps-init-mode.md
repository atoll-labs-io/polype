# Review: s135-update-keeps-init-mode

[Story](../stories.md) · [Plan](../plans/s135-update-keeps-init-mode.md) · [Verification](../verif/s135-update-keeps-init-mode.md)

Reviewed tree: 023c630f40a4adb5ea8c56e52f35754a2ffdc019
Fix loop: 0
Scope: `git diff origin/main...story/s135-update-keeps-init-mode` (origin/main = 0ebfc94; the local `main` ref lags, as the caller said)
Lenses run: none (no auth, migration, dependency or server-side path or content in the diff)
Review status: complete

## Verdict in brief
No critical findings. The fix does what issue #73 asked for. `update` now reads the activation mode from `.polype/mode` before it builds `PAIRS`, and falls back to reading the manifest when that file is missing. `install <project>` never reads it. `init` and `install` write it, and `remove` deletes it. There is one major finding: the inference branch of the po-session hint is never exercised by a test.

## Scope check (Owns)
I compared every changed path against the `Owns` line. All of them are covered:
- `bin/polype`, `method/hooks/po-session.sh`, `method/commands/po-setup.md`, `docs/installation.md`, `README.md` and `tests/update-keeps-mode.test.sh` are listed.
- `docs/decisions/ADR-0091-la-mise-a-jour-garde-le-mode-d-activation.md` matches `docs/decisions/ADR-0091-*`, and the plan names it.
- `docs/plans/`, `docs/research/` and `docs/verif/` hold the story's own pipeline evidence, which is in scope by construction.

`git worktree list` shows no other story worktree, so no other lane can overlap.

## Steps
1. **Reuse what is proven.** `po-gate verif-current` passes (exit 0). With `Verification mode: record`, I relied on the record: one `bash tests/run.sh` run, exit 0, on a tree whose code matches `Tree: 64e3823…`. The project has no type check, E2E or build command (`Typecheck: —`, `E2E: —`, `Build: —`), so none was run. Read "Not proven here": the pecten and nautile repairs, and the refresh of the installed copies, are left out on purpose. The story does not go to QA (`QA stage: —`).
2. **References.** `command` is a `local` in `main` (`bin/polype:766`). `parse_target` sees it through bash's dynamic scoping, and is only ever called from `main`, so `set -u` is safe. `init` reaches `parse_target` with `command=init` and `mode=init` already set. `stamp_mode` runs at both stamp sites, and `mode_file` is set at the end of `parse_target`, before any use. `absorb_agents_md` (`:271`) and `handle_claude_md` (`:429`) already branch on `$mode`, as the plan says.
3. **Plan.** All 8 tasks are present, and the run interdicts are respected: no change to `drop_laid_file`, to `cmd_check`, to the global path or to `.claude/` and `.polype/`. The `## Reuse` rows match the diff.
4. **Tests.**
   - Floor: `po-gate floor-guard s135-update-keeps-init-mode origin/main` exits 0. No test file was deleted or weakened.
   - Count: 6 tests, against a budget of 25.
   - Bite (each mutation undone, then `git diff --exit-code` clean):
     - (a) Never read the mode on update (`true || mode=…`): 2 failures (`init_then_update_stays_init`, `mode_inferred_without_state`).
     - (b) Inference in `recorded_mode` always answers `project`: 1 failure (`mode_inferred_without_state`).
     - (c) po-session `again` always `polype update .`: 1 failure (`hints_say_init`).
     - (d) po-session inference branch (manifest without `.claude/commands/`) disabled with `&& false`: **0 failures** across `update-keeps-mode`, `no-claude-md` and `claude-md-setting` (14 tests).
5. **Values.** The `^\.claude/commands/` inference matches what `target_is_a_project` lays in init mode (templates and hooks only). An unknown value in `.polype/mode` falls back to inference. With no manifest, the answer is `project`, so `update` falls back to `install`, as before.
6. **Neighbours.**
   - `cmd_check` works from the manifest, not from `PAIRS`, so an init project is not reported as missing commands.
   - The `cmd_update` → `cmd_install` fallback keeps `mode=project` when there is no manifest.
   - `docs/installation.md:322,334` still say "relance `polype init <projet>` ou `polype update <projet>`". That is now correct either way.

## Findings
- major — the po-session inference branch is untested. Lines 244-245 of `method/hooks/po-session.sh` choose `polype init .` when there is no `.polype/mode` and the manifest has no `.claude/commands/` line. Criterion `mode_inferred_without_state` explicitly requires "po-session applique la même règle". Mutation (d) disabled that branch and no test failed: `test_hints_say_init` only covers a project that has a mode file. This matters most for projects activated before this version, which have no `.polype/mode`. The fix: a po-session case with `.polype/mode` removed on an init project.
- minor — stale comment in `method/hooks/po-session.sh:241`: "update on an init project would lay the commands" is no longer true after this story; the reason now is that `polype init .` is the advised command and the one that repairs an inflated project.
- minor — stale header comment in `bin/polype:15-19`: it still says "Three [state files] … A project has a fourth"; a project now has a fifth, `.polype/mode`.
- minor — gap between the story text and the plan on pinned tests: criterion `hints_say_init` expects the pinning tests to change with the old phrase; the plan kept the full-install wording byte for byte, so they did not need to. The plan states this choice, and the behaviour the criterion asks for is delivered.

## Not verified
- **Running on a real pecten or nautile project inflated by #73.** Out of scope; a person runs `polype init .` there and checks the manifest drops back to 23 lines and `.polype/mode` reads `init`.
- **`bin/polype-dev-install .` on Polype's own repository.** Not run (it would change this repository's installed copies). The code supports recording `project`, not observed.
- **Bash older than 5, or on macOS.** Only this machine's bash.
- **The unit suite.** Taken from the record (`Verification mode: record`); only the focused test files ran during the bite.
- **No QA report.** None applies: `QA stage: —`.

Max severity: major
Ship allowed: yes
