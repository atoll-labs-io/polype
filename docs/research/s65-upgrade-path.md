# Research — s65-upgrade-path

[Story](../stories.md)

## Structuring facts
- **False assumption 1 — `update` is not the only upgrade path.** A project served by the global install is refreshed with `polype init <projet>` (`docs/installation.md:91-94`, `:122-123`), and `init` runs `cmd_install`, not `cmd_update` (`bin/polype:281-284`). A listing hooked into `cmd_update` alone would never reach those projects: it must run on every project-mode pose (`wire_the_project`, `bin/polype:206-211`) and in `check`.
- **False assumption 2 — not every dispatching command carries its own model-refusal sentence.** `/po-flow` and `/po-orchestrator` have none (`grep -n reject method/commands/*.md` hits only po-execute:37, po-review:33, po-qa:37, po-stories-review:33, po-drive:101); they delegate by reference to `/po-execute`'s `## Model` (`po-flow.md:75`, `po-orchestrator.md:57`) and to `/po-review` (`po-flow.md:77`, `po-orchestrator.md:68`). Both files are outside `Owns`: the test pins the reference plus the referenced sentence, it cannot add text there.
- The settings template declares its settings as every non-empty line inside its two fenced blocks (`method/templates/agents-local.md:9-37`, `:71-79`); `tests/lib.sh:32-34` already parses it that way. Line 5 (`Format: …`) is outside the fences and is not a setting.
- `check` exits 0 on a clean install of a project with no `AGENTS.local.md` (`tests/installer.test.sh:44`): the listing must not change the exit status, and stays silent without `AGENTS.local.md`.
- `tests/bounds.test.sh:223-228` (outside `Owns`) pins three phrases of `docs/installation.md:89-94`; the hook section can be rewritten around them, never without them.

## Story
`polype update` and `polype check` list each setting of the template absent from the project's `AGENTS.local.md`, with the proposed default, never writing that file. Criteria: `update_lists_missing_settings`, `installation_doc_has_an_upgrade_section`, `installation_doc_lists_the_hook_refusals`, `standalone_commands_state_the_session_model`, `model_refusal_stops_everywhere`. Fixes the two majors and the minors of `docs/reviews/s59-model-by-complexity.md:66-85`.

## Current code
- `bin/polype` (415 lines, `set -euo pipefail`, `:17`). `$method` = `$base/method`, the shipped method, in every mode (`:28-29`). Project mode: `project`, `root`, `state_dir=.polype` (`:93-105`); global mode has no project (`:79-91`).
- `cmd_install` (`:249-279`) and `cmd_update` (`:286-327`) both end with `wire_the_project` (`:277`, `:320`), which returns at once in global mode (`:207`). `cmd_update` names modified files on stderr (`:323-325`) then prints its summary on stdout (`:326`). `cmd_update` on a project without manifest delegates to `cmd_install` (`:287`).
- `cmd_check` (`:329-359`): stdout lines `modified: <path>` / `missing: <path>` (`:351-352`), `N installed files, none modified` (`:354`), `exit "$status"` (`:358`); status 1 only for drift, missing files or no version stamp.
- The installer reads `AGENTS.local.md` once today, for `Worktree root`, with a `sed` anchored at column 0 (`:184-187`). It never writes it (`docs/installation.md:3-5`, `:199`).
- `docs/installation.md` (201 lines, French): commands table `:11-22`; hook section `### Le hook des bornes de l'implementer` `:80-100`, whose refusal list (`:84-87`) predates s62 (switch, checkout, stash, push, worktree add, commit outside story); `## Lire un rapport check` `:177-185`. No upgrade section.
- `method/hooks/po-bounds.sh:516-535` (implementer mode, since s62): refuses `switch|checkout|stash|push`, `worktree add`, `update-ref`, `branch` with `-f|--force|-D|-M|-C` alone or grouped (`:521-528`), and `commit|reset|merge|rebase|cherry-pick|revert|am|pull` outside a `story/*` worktree (`:530-535`). Header `:9-12` says the same. ADR-0039 lists what stays unread: `$VAR` holding `git`, a git alias, `GIT_DIR=… git reset`, `git --git-dir=… reset`, `git fetch . HEAD:main`; quoted text and quoted-heredoc bodies are not read as commands. Doc `:86-87` already says shell redirections and `cp` are not seen.
- `method/commands/po-plan.md`, `po-design.md`, `po-research.md`: none mentions a model or ADR-0036 (grep). None dispatches a subagent (review s59 `:58`). Reads-settings lines: `po-plan.md:14`, `po-design.md:7`, `po-research.md:13`.
- `tests/model-routing.test.sh` (85 lines): `implementer_adapts_in` (`:14-17`) only checks that `Light up to` sits on the implementer line, so swapping strong/light passes (review s59 mutation 2). `test_only_the_implementer_adapts` pins po-execute's rule sentence (`:55`) and "Never retry" (`:60`) but not "stop and report" (mutation 3). The refusal sentences of po-review/po-qa/po-stories-review/po-drive are not asserted at all; `:49` checks only "`Model strong` missing → stop and name it."
- `tests/installer.test.sh` (148 lines): `polype()` wrapper swallows output (`:7`); `copy_of_the_method` (`:11-16`); scratch project via `scratch_repo` (`tests/lib.sh:46-53`).

## Attachment points
- `bin/polype`: a new function next to `ignore_worktrees_and_env` (`:182`), called from `wire_the_project` (`:206-211`, so install, init and update in project mode) and from `cmd_check` before `exit` (`:358`), in project mode only.
- `docs/installation.md`: a new `##` section after `## install ou update` (`:162-175`); rewrite of `:84-87`; one sentence in `## Lire un rapport check` (`:177-185`).
- `po-research.md` after `:17`, `po-plan.md` after `:18`, `po-design.md` after `:11`: one sentence each.
- `tests/installer.test.sh`, `tests/model-routing.test.sh`: one `test_<criterion>` each per criterion.

## Verified interfaces
- Directional phrase present verbatim on every implementer dispatch line: `` `Model light` up to `Light up to`, `Model strong` above `` — `po-drive.md:93`, `:127`, `po-flow.md:75`, `po-orchestrator.md:57`.
- Refusal sentences: po-execute `## Model` (`:30-37`) "If the Agent tool rejects the model name, stop and report the setting and its value."; po-review `## Delegation` `:33`, po-qa `## Delegation` `:37`, po-stories-review `## Delegation` `:33`: "If the Agent tool rejects the model name, stop and report the setting and its value"; po-drive `:101`: "If the Agent tool rejects a model name, that lane stops, named in the report with the setting and its value".
- References: "`/po-execute`'s `## Model`" on `po-flow.md:75` and `po-orchestrator.md:57`; "delegate as `/po-review` does" `po-flow.md:77`; "Delegate to `reviewer` the way `/po-review` does" `po-orchestrator.md:68`.
- ADR-0036 phrase already used: "run on the session's model, which no command can choose (ADR-0036); start the session on `Model strong`" (`po-flow.md:21`, `po-orchestrator.md:21`), pinned by `tests/model-routing.test.sh:65`.
- Template names that prefix other names: `Test` / `Test budget`, `E2E` / `E2E stage|scope|browsers`, `Design source|skill|tool`. A prefix match would hide a missing `Test` or `E2E`.

## Traps
- Exact-name matching: a line counts as present only when its text before the first colon, trimmed, equals the template name.
- `set -euo pipefail` (`bin/polype:17`): a `grep` with no match inside a pipeline kills the script; parse with one `awk` reading both files.
- `—` is UTF-8 and must pass through untouched.
- `bin/po-lint` settings rule (`:85-112`) only checks names on `Reads settings:` lines; naming `Model strong` in prose of po-plan/po-design/po-research needs no change there. Adding it to their `Reads settings:` would claim a read they do not do.
- The planner and designer subagents are bound by po-plan/po-research/po-design text: the new sentence must not tell a drive-dispatched subagent to restart anything.
- `tests/overlap.test.sh`: new method text in own words.
- Polype's own `AGENTS.local.md` lacks `QA stage` and `Dev`: a correct `polype check .` will list them. Not this story's to add.
- No migration, no screen, no auth, no API contract, no new dependency (awk and cksum already used).

## Open questions
- Should missing settings turn `check`'s exit status to 1? The plan decides (ADR-0043).
- Should `update --global` hint that projects need `init`? Not asked; the doc covers it.

## Complexity
Story 3 → 3. One bash function in two call sites, two doc sections, three sentences and test hardening; the init path adds a call site, not a level.

## Split
Not needed below 5.
