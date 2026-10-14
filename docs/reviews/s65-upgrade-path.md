# Review — s65-upgrade-path

[Story](../stories.md) · [Plan](../plans/s65-upgrade-path.md) · [Verification](../verif/s65-upgrade-path.md)

Reviewed tree: e517ed65e15ccaa47e0a49a83dd0f299acc72de7
Fix loop: 0
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s65-upgrade-path (branch `story/s65-upgrade-path`, commit 87d19a7)
Scope: `git diff main...story/s65-upgrade-path`
Lenses run: none. The diff has no auth or route paths, no migrations, no lockfile or manifest and no server-side code. `bin/polype` is a local CLI installer.

## Scope (Owns)
All changed paths are within the story's `Owns`, except two cases that count as in scope:
- The pipeline evidence (`docs/research|plans|verif/s65-upgrade-path.md`) is in scope by construction.
- `docs/decisions/ADR-0043-l-installeur-signale-les-reglages-manquants-sans-les-ecrire.md` was added (status `A`) and the plan names it, so it is in scope by construction.

No overlap with the other running lane (`s67-record-text`, which owns `method/agents/implementer.md`, `method/hooks/po-gate.sh` and two tests). All plan run interdicts are respected: none of the forbidden paths appears in the diff, and the `Reads settings:` lines are untouched.

## Evidence relied on
- `po-gate verif-current s65-upgrade-path` exited 0. The record's `Tree: bd658cc…` and the run tree `dfc47eb…` both equal HEAD outside `docs/` (checked with `git diff --quiet`). The unit suite `bash tests/run.sh` exited 0 on that code.
- Verification mode is `record`, so I did not rerun the full suite.
- The project has no type check, E2E or build command (`Typecheck: —`, `E2E: —`, `Build: —`).
- The record's "Not proven here" section was read: the `init` listing and real model refusals are not exercised.
- `po-gate floor-guard s65-upgrade-path main` exited 0: no check was lowered. One existing test changed (the `test_only_the_implementer_adapts` lines moved out and the helper was tightened). The plan announces this, and the change makes the test stricter.
- No screen, so QA does not apply.

## Plan conformity
I went through tasks 1 to 7 one by one. Everything is present and nothing was added beyond the plan.
- **Task 1.** `missing_settings` sits in `wire_the_project` and covers install, init and update. It reads `$method/templates/agents-local.md`, uses a single awk pass and matches names exactly. It writes no file. Its output goes to stderr on project poses and to stdout in `cmd_check`, and `status` is untouched.
- **Docs.** The `docs/installation.md` sections match `method/hooks/po-bounds.sh:516-535` (including the regex `^-[A-Za-z]*[fDMC][A-Za-z]*$` behind "groupés (`-fD`)") and the "Bad" line of ADR-0039.
- **Wording.** The sentences added to `/po-drive` match its lines 91-92: the planner and designer are dispatched on `Model strong`.
- **Live run.** `polype check .` on this repo lists `QA stage` and `Dev` and exits 0, as the plan expects.

## Bite (mutations; I ran only the touched test file each time and restored with `git diff --exit-code`)
1. Name matching changed to prefix matching (`index(h, name[k]) == 1`): `installer.test.sh` 1 failing test (`update_lists_missing_settings`). Restored.
2. `check` made to exit 1 when settings are missing: 1 failing test. Restored.
3. The `missing_settings >&2` call removed from `wire_the_project`: 1 failing test. Restored.
4. Template read from `$project/.polype/templates/…` instead of `$method/…`: **0 failing tests**. See m1. Restored.
5. s59 mutation 2 (strong and light swapped on the implementer line of `po-drive.md`, line 93): `model-routing.test.sh` 1 failing test (`model_refusal_stops_everywhere`). Restored.
6. s59 mutation 3 (the stop in `po-execute.md:37` replaced by a redispatch): 1 failing test. Restored.

The final `git diff --exit-code` is clean and `git status --porcelain` is empty.

## Findings
- **m1 (minor): one of the plan's three pivot risks has no test.** Reading the installed `.polype/templates/agents-local.md` instead of `$method/templates/agents-local.md` fails no test (mutation 4). The scratch project is installed from the same method just before `update` and `check`, so both copies are identical. The code uses the correct path today, and the plan left this risk to the reviewer's reading. Still, the rule has no test. A test that runs `check` after the installed template was edited (or on a stale copy) would cover it. File: `/home/lecrabe/dev/atoll/polype/.worktrees/s65-upgrade-path/tests/installer.test.sh`.
- **m2 (minor): the bounds-hook paragraph is slightly too broad.** In `/home/lecrabe/dev/atoll/polype/.worktrees/s65-upgrade-path/docs/installation.md` it says "un texte entre guillemets … n'est pas lu comme une commande". ADR-0039 (line 25) says a `$(…)` substitution inside double quotes is read, and so are the substitutions in a heredoc whose delimiter is not quoted. A reader could think `"$(git push)"` gets through. One clause naming the substitution exception would fix it.
- **m3 (minor): the project side counts any line holding a colon as a declared setting.** That includes prose lines outside the fences, and an empty value such as `Model strong:` counts as present. This matches the reading rule in `AGENTS.md` and ADR-0043's wording, but a setting declared with an empty value is never reported. File: `/home/lecrabe/dev/atoll/polype/.worktrees/s65-upgrade-path/bin/polype` (the `missing_settings` awk).

There are no critical or major findings.

## Not verified
- **`polype init <project>` printing the list.** Checked by reading only: it goes through the same `wire_the_project` call. To cover it, run `polype install --global` into a scratch `CLAUDE_CONFIG_DIR`, then `polype init` on a project whose `AGENTS.local.md` lacks a setting, and look at stderr.
- **Real Agent-tool refusals of a model name.** No dispatch happens in the tests; only the command texts are pinned. To cover it, launch `/po-review` with `Model strong` set to an invalid name and confirm it stops and names the setting.
- **The French docs and ADR-0043.** Read for accuracy against the code, not proofread. A French-speaking maintainer should skim `## Après une mise à jour`.
- **The full suite.** Not rerun: I relied on the record (Verification mode `record`). Only `installer.test.sh` and `model-routing.test.sh` ran, for the mutations.

Review status: complete

Max severity: minor
Ship allowed: yes
