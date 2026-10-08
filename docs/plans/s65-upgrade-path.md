---
validated: yes
---
# Plan — s65-upgrade-path

Branch `story/s65-upgrade-path`. Read `docs/research/s65-upgrade-path.md` first; this plan builds on it without repeating it. The structural choice is settled in `docs/decisions/ADR-0043-l-installeur-signale-les-reglages-manquants-sans-les-ecrire.md` (written by the planner, on this branch).

## Story
An upgrade of Polype must say which settings the template gained and the project lacks, instead of letting commands stop in silence. Criteria:
- `update_lists_missing_settings` — `polype update` and `polype check` on a project list each template setting absent from its `AGENTS.local.md`, with the proposed default, never modifying that file.
- `installation_doc_has_an_upgrade_section` — `docs/installation.md` says what to do after an upgrade: read that list, add the settings.
- `installation_doc_lists_the_hook_refusals` — the bounds-hook section lists the git commands `po-bounds` refuses since s62 and what it does not see (ADR-0039).
- `standalone_commands_state_the_session_model` — `/po-plan`, `/po-design`, `/po-research` say they run on the session's model, to be started on `Model strong` (ADR-0036).
- `model_refusal_stops_everywhere` — tests pin, for each dispatching command, the stop sentence on a model refusal and the direction of the implementer rule.

Corrections carried from research: the listing also runs on `install`/`init` (the global path refreshes a project with `init`); `/po-flow` and `/po-orchestrator` hold no refusal sentence of their own and are outside `Owns`, so their test pins the reference they make.

## Tasks
1. [x] **`bin/polype` — list missing settings.** Add a function `missing_settings` next to `ignore_worktrees_and_env` (`bin/polype:182`), per ADR-0043:
   - returns at once in global mode, or when `$project/AGENTS.local.md` does not exist;
   - reads the template from `$method/templates/agents-local.md` (the shipped method, never `.polype/templates/`);
   - one `awk` over both files (no `grep` in a pipeline under `set -euo pipefail`): template settings = non-empty lines inside the fenced blocks (same rule as `tests/lib.sh:32-34`), name = text before the first `:` trimmed, value = text after it trimmed; a project line counts when its text before the first `:`, trimmed, **equals** the name (`Test budget:` never satisfies `Test`);
   - prints, in template order, one line per absent setting: `missing setting: <Name>: <value>` (e.g. `missing setting: Model strong: opus`), to stdout; writes nothing.
   Call it from `wire_the_project` after `set_hooks_path` as `missing_settings >&2` (covers `install`, `init`, `update` on a project), and from `cmd_check`, project mode only, to stdout, after the `modified:`/`missing:` lines and before `exit "$status"`. `status` is not changed by it. Add one comment only if the why is not obvious (ADR-0043 reference is enough).
   Test that fails if wrong: `test_update_lists_missing_settings` (task 6).
2. [x] **`docs/installation.md` — upgrade section.** Insert `## Après une mise à jour` after `## \`install\` ou \`update\`` (`:162-175`). In French, it must contain these exact phrases: `missing setting: <Nom>: <valeur>`; `ajoute chaque ligne à \`AGENTS.local.md\``; `\`polype check <projet>\``; `relance \`polype init <projet>\` ou \`polype update <projet>\``. Content: `install`, `init` and `update` on a project name each template setting the project's `AGENTS.local.md` lacks, on `stderr`, with the template's value; the installer never writes that file; a project served by the global install sees the list when `polype init <projet>` runs after `polype install --global`; read the values table of `.polype/templates/agents-local.md` before keeping the proposed value; after adding, rerun the installer so `AGENTS.md` carries the new lines, and commit `AGENTS.local.md` and `AGENTS.md` on the target branch; until then a command reading a missing setting stops and names it (the model settings of s59 stop every dispatching command). Also add to `## Lire un rapport \`check\`` (`:177-185`) one sentence: `check` lists the same `missing setting:` lines, which do not change its exit code. Add the `update`/`check` lines of the commands table (`:18-19`) only if wording still fits; no other section changes.
   Test: `test_installation_doc_has_an_upgrade_section` (task 6).
3. [x] **`docs/installation.md` — hook refusals.** Rewrite `:84-87` of `### Le hook des bornes de l'implementer`. It must list: `git switch`, `checkout`, `stash`, `push`, `worktree add` (always); since s62, `git update-ref`, and `git branch` with `-f`, `--force`, `-D`, `-M` or `-C`, alone or grouped; `commit`, `reset`, `merge`, `rebase`, `cherry-pick`, `revert`, `am` and `pull` outside a worktree on `story/*` (source `method/hooks/po-bounds.sh:516-535`). Then what it does not see, citing `ADR-0039`: text in quotes or in a quoted heredoc is not read as a command; not read either: a `$VAR` holding `git`, a git alias, `GIT_DIR=… git reset`, `git --git-dir=… reset`, `git fetch . HEAD:main`; plus the existing shell redirections and `cp`, which the review's ownership check covers. Keep verbatim the three phrases `tests/bounds.test.sh:225-227` pins (`relance \`polype init <projet>\``, `le hook fermé refuse toute écriture de l'implementer`, `` `jq` ``) and the trust-limit paragraph `:96-100`.
   Test: `test_installation_doc_lists_the_hook_refusals` (task 6).
4. [x] **Standalone commands state the session model.** One sentence each, own words, after `method/commands/po-research.md:17`, `po-plan.md:18`, `po-design.md:11`, of this form (noun adapted: research / plan / design; dispatched role: planner / planner / designer):
   `Run as a command, this plan is written in this context on the session's model, which no command can choose (ADR-0036); start the session on \`Model strong\`. \`/po-drive\` passes \`Model strong\` to the planner it dispatches instead.`
   No change to their `Reads settings:` lines (they read no model setting) and no stop added.
   Test: `test_standalone_commands_state_the_session_model` (task 5).
5. [x] **`tests/model-routing.test.sh`.**
   - `test_standalone_commands_state_the_session_model`: for each of `po-research`, `po-plan`, `po-design`, `contains` `which no command can choose (ADR-0036); start the session on \`Model strong\``.
   - `test_model_refusal_stops_everywhere`, using a section extractor (`awk '/^## <name>$/ {on=1; next} /^## / {on=0} on'`, as `:71` does):
     - `## Model` of `po-execute.md` holds `If the Agent tool rejects the model name, stop and report the setting and its value.`;
     - `## Delegation` of `po-review.md`, `po-qa.md`, `po-stories-review.md` each holds `If the Agent tool rejects the model name, stop and report the setting and its value`;
     - `po-drive.md` holds `If the Agent tool rejects a model name, that lane stops, named in the report with the setting and its value`;
     - `po-flow.md` and `po-orchestrator.md` inherit it: their implementer line names `` `/po-execute`'s `## Model` ``, and their reviewer line names `/po-review` (`delegate as \`/po-review\` does` / `Delegate to \`reviewer\` the way \`/po-review\` does`);
     - direction: `implementer_adapts_in` is tightened to require, on the implementer line, the exact phrase `` `Model light` up to `Light up to`, `Model strong` above ``; called for `po-drive`, `po-flow`, `po-orchestrator`, plus the drive `fix-run sentence` line (`po-drive.md:127`).
   - **Existing test changed, said here:** the loop and the fix-run check at `:62-63` move out of `test_only_the_implementer_adapts` into the new test (same rule, one test), and the helper `:13-17` is tightened. The po-execute sentences at `:55-61` stay.
   Bites the reviewer can reproduce: s59 review mutation 2 (swap strong/light in `po-drive.md:93`) and mutation 3 ("stop and report" → redispatch in `po-execute.md:37`) must each fail this test.
6. [x] **`tests/installer.test.sh`.**
   - `test_update_lists_missing_settings`: scratch project; `AGENTS.local.md` = `$METHOD/templates/agents-local.md` with the `Model strong:` and `Test:` lines deleted; `install`, then `update` with stdout+stderr captured: exactly two `missing setting:` lines, `missing setting: Model strong: opus` and `missing setting: Test: —`; then `check` (stdout): the same two lines and exit 0; `cksum` of `AGENTS.local.md` identical before install and after check.
   - `test_installation_doc_has_an_upgrade_section`: inside the `## Après une mise à jour` section of `docs/installation.md`, the four phrases of task 2.
   - `test_installation_doc_lists_the_hook_refusals`: inside `### Le hook des bornes de l'implementer` (until the next `## `), `git update-ref`, `-D`, `--force`, `cherry-pick`, `pull`, `story/*`, `ADR-0039`, `git fetch . HEAD:main`, `GIT_DIR=`.
   Run: `bash tests/run.sh installer.test.sh model-routing.test.sh bounds.test.sh`.
7. [x] **Full suite, once**, through `po-run --story s65-upgrade-path --label full-suite -- 'bash tests/run.sh'` (no type check: `Typecheck: —`). `tests/overlap.test.sh` and `tests/structure.test.sh` are in it.

## Run interdicts
- Empty diff: `AGENTS.local.md`, `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.polype/`, `method/templates/agents-local.md`, `method/hooks/po-bounds.sh`, `tests/lib.sh`, `tests/bounds.test.sh`, `docs/parite-killer-saas.md` (s68 owns it).
- Empty diff: `method/commands/po-execute.md`, `po-review.md`, `po-qa.md`, `po-stories-review.md`, `po-drive.md`, `po-flow.md`, `po-orchestrator.md` — outside `Owns`; their sentences are tested, not rewritten.
- The `Reads settings:` lines of `po-plan.md`, `po-design.md`, `po-research.md` stay byte-identical.
- `bin/polype` never opens `AGENTS.local.md` for writing (no `>`, `>>`, `sed -i`, `mv` onto it), and `cmd_check`'s exit status depends only on drift, missing files and the version stamp, as before.
- No new tool in `bin/polype` (no `jq`, `python`, `perl`); only `awk` for the parse.
- Only ADR file on the branch: `ADR-0043-…`, already written; the implementer does not edit it nor create another.
- Do not add `QA stage` or `Dev` to Polype's own `AGENTS.local.md`, even though the new `check` lists them.

## The pivot
**A setting is the line `Name:` inside the template's fences, matched by exact name in `AGENTS.local.md`, listed on every project pose and in `check` without touching the exit code (ADR-0043).** Ways it could be wrong:
- Name matching by prefix or regex would hide `Test` behind `Test budget` or `E2E` behind `E2E stage`: compare the test's exact count of two lines against a mutation using `index()`/prefix.
- Hooking only `cmd_update` would leave global-install projects (refreshed by `init`, `bin/polype:281-284`) uninformed: check the call sits in `wire_the_project`, not in `cmd_update`.
- Reading the installed `.polype/templates/agents-local.md` instead of `$method/…` would list against the *old* template during `check` of a stale project, and be absent in a global-mode first `init`: check the path used.
Secondary: `/po-flow` and `/po-orchestrator` inherit the refusal by reference only; if a later story drops "`/po-execute`'s `## Model`" from them, the test catches it, but a reworded refusal inside those two files would not be seen (none exists today).

## Files touched
`bin/polype`, `docs/installation.md`, `method/commands/po-research.md`, `method/commands/po-plan.md`, `method/commands/po-design.md`, `tests/installer.test.sh`, `tests/model-routing.test.sh`; pipeline evidence `docs/research/s65-upgrade-path.md`, `docs/plans/s65-upgrade-path.md`, `docs/verif/s65-upgrade-path.md`, and `docs/decisions/ADR-0043-…` (outside `Owns`, required by Law 6 for the choice ADR-0043 settles — same situation as ADR-0036 in s59).

## Test strategy
Five new test functions, one per criterion, named after it; one helper tightened. Within `Test budget` 25.
- Behaviour (installer, end to end on a scratch repo — the installer *is* the adapter and the rule): `test_update_lists_missing_settings` — bites on exact-name matching (count), on the value proposed, on writing the file (cksum), on `check`'s status.
- Text contracts (method files and doc, quoting exact phrases per repository convention): `test_installation_doc_has_an_upgrade_section`, `test_installation_doc_lists_the_hook_refusals`, `test_standalone_commands_state_the_session_model`, `test_model_refusal_stops_everywhere` (section-scoped, so a refusal moved out of `## Model`/`## Delegation` fails).
- Not tested here: `init` printing the list (same `wire_the_project` call as `update`, verified by reading); real Agent-tool refusals (no dispatch in tests).
- No visual checks: no screen.

## Done when
All seven tasks ticked; the five criteria tests green; `bash tests/run.sh` green through `po-run`, recorded in `docs/verif/s65-upgrade-path.md`; one commit on `story/s65-upgrade-path` carrying code, tests, research, plan, ADR-0043 and the record; a review with no open critical finding.
