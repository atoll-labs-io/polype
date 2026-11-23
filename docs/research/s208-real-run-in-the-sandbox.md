# Research — s208-real-run-in-the-sandbox

[Story](../stories.md)

## Structuring facts
- Track raised from `flow` to `full`: the story requires a new ADR replacing accepted ADR-0136 (an escalation signal), as s207 did for ADR-0136 (`docs/decisions-log.md:452`). ADR-0137 is written `accepted`: the choice is the owner's (2026-11-23), not an open one.
- No assumption of the story is false. One omission: `real_governing` is prune-based in **two** places, the config dir (`evals/real/lib.sh:190-194`) and the run's `HOME` (`:197-198`); the rest (`:200-216`) already selects by name. Listing must cover both, or a new housekeeping file in `HOME` still invalidates a run.
- The Bash allowlist is `real_permissions` (`evals/real/lib.sh:109-117`), written to `$J/config/settings.json` by `real_config` (`:125`). Claude Code 2.1.331 knows `sandbox.enabled`, `autoAllowBashIfSandboxed`, `failIfUnavailable` and `sandbox.filesystem.allowWrite`, and treats Edit allow rules as write roots (strings of the installed binary).
- The record name is fixed `docs/evals/real-$(date +%Y-%m-%d)-v$version.md` and written with `>` (`evals/real/lib.sh:681,704`): the cause of #486.
- The second run's invalidation was `config/plugins/store/cc-plugin-agents-md_builtin-b049b47b3618.json` (`/tmp/po-eval-results.Siq95u/runs.txt`); since `real_session_held` names the first changed path in sorted order (`:303`), nothing under `config/` sorting before it changed in that session: not `plugins/cache`, `plugins/data`, `plugins/installed_plugins.json`, `plugins/known_marketplaces.json`, `plugins/marketplaces`.

## Story
The run confines Bash by Claude Code's native sandbox instead of a command list; it compares only what governs a session; it never rewrites a record. Criteria: `sandbox_governs_bash`, `sandbox_mounts_do_not_dirty_lanes`, `governing_is_listed_not_ignored`, `record_never_overwrites`.

## Current code
- `real_env` (`evals/real/lib.sh:54-69`): run folder `$J`, `HOME=$J/home`, `XDG_CONFIG_HOME=$J/home/.config`, `GIT_CONFIG_GLOBAL=$J/home/.gitconfig` (truncated empty at `:63`), `GIT_CONFIG_NOSYSTEM=1`. Nothing writes `$J/home/.config/git/ignore` today.
- `real_path_without_claude` / `real_path_spares` (`:73-91`): drops each PATH folder holding a `claude` unless a needed tool (list at `:88`) would then be found elsewhere; `bwrap` and `socat` are not in that list.
- `real_permissions` (`:109-117`): `autoMemoryEnabled: false`; allow = 18 `Bash(...)` rules + `Read(//$J/**)`, `Edit(//$J/**)`, `Agent`; deny = `WebFetch`, `WebSearch`, `Bash(curl:*)`, `Bash(claude:*)`.
- `real_governing` (`:188-217`): `real_sigs config "$J/config" … -prune` with a 17-path ignore list (`:190-194`); `config/projects/*/memory` (`:195`); `.claude.json` keys (`:196,199`); `home` with a 6-path ignore list (`:197-198`); then bin, gh, git config and hooks, run and `.worktrees` parents, folders above, project and worktrees (`:200-216`).
- `real_session_held` (`:300-309`) diffs `REAL_GOVERNING` against a fresh `real_governing`, names the first path.
- `real_main` (`:790-911`): login check (`:838-841`), `REAL_CLAUDE` (`:845-846`), `REAL_RUN_PATH` (`:847`), announce and confirmation (`:849-871`); prints `permissions: allowlist, prompts denied` (`:859`). `real_record` (`:677-706`) after the summary (`:909`).
- `evals/real/claude-print:23` passes `--permission-prompts none`; settings come only from `$J/config/settings.json`. Nothing to change there.
- The run's config after a build holds `agents/ commands/ polype/ settings.json skills/` (built `--build journey` in `/tmp`, 2026-11-23). `polype/` holds `po` and the installed method: `po` reads only `CLAUDE_CONFIG_DIR/agents` (`po/src/run/bounds.rs:16-24,55-62`) and writes nothing in the config.
- Claude Code's own config (`~/.claude/plugins/`, checked on this machine): `installed_plugins.json` (version 2, each plugin's `installPath` under `plugins/cache/`), `known_marketplaces.json`, `marketplaces/`, `cache/`, and housekeeping `store/` (builtin plugin queues), `data/`, `synced/`, `.last_inuse_sweep`, `plugin-directory-cache-v2.json`. "Installed plugins" = `installed_plugins.json`, `known_marketplaces.json`, `cache/`, `marketplaces/`.

## Attachment points
- `real_permissions` (`evals/real/lib.sh:109`) — the sandbox block, the Bash rules out.
- `real_env` (`:54`) — the run's global git ignore, next to `:63`.
- `real_path_spares` tool list (`:88`) and `real_main` after `:847` — the `bwrap`/`socat` refusal, before the announce.
- `real_governing` (`:190-199`) — config and home selected by name.
- `real_record` (`:681`) — the free name, written without clobbering.
- `real_main:859` — the announced confinement.
- `docs/evals/real-run.md:15,28,35` — record name, settings line, the governing paragraph.

## Verified interfaces
- `real_sigs <label> <dir> <find expression>` (`:130-141`): prints `<label>/<path> L|F …`; a find expression with `-prune -o … -type f` selects.
- `real_record` (`:677`): reads `POLYPE_ROOT`, `REAL_RESULTS/{summary,runs}.txt`, `REAL_MODEL(S)`, `REAL_LOGIN`, `REAL_SELECTED`, `REAL_REPEAT`, `REAL_SESSIONS`, `REAL_BUDGET`, `ARMS_NAME`; prints `record: <path relative to POLYPE_ROOT>`.
- Git under bwrap (probe in `/tmp` with `/usr/bin/bwrap`): a file masked with `--ro-bind /dev/null <repo>/.zshrc` shows `?? .zshrc` in `git status --porcelain`; anchored patterns (`/.zshrc`, `/.idea/`) in `$XDG_CONFIG_HOME/git/ignore`, with `GIT_CONFIG_GLOBAL` an empty file, hide the masks at the root and in a linked worktree. A read-only `.git/config` makes `git worktree add -b x <path> origin/main` print two `could not write config` errors and exit 0, the worktree created.
- Mandatory sandbox write protections named by Claude Code 2.1.331: files `.gitconfig .gitmodules .bashrc .bash_profile .zshrc .zprofile .profile .ripgreprc .mcp.json`, folders `.vscode .idea`, plus `.claude/commands`, `.claude/agents`, `.git/hooks`, `.git/config`.

## Traps
- **Tests that assert the allowlist** must change with it, both in this story's `Owns`: `test_law4_commands_are_allowed` (`tests/real-run-is-usable.oracle.test.sh:56-69`, equality of the allow list) and `test_gh_is_allowed_for_a_lead_that_follows_the_method` (`tests/real-run-before-a-release.test.sh:432-441`, `Bash(gh:*)` in allow). The deny checks of `test_build_holds_no_login` (`:69-70`) stay true.
- **CI has no bwrap/socat** (`ubuntu-latest`, `.github/workflows/ci.yml:13-21` installs only jq): every test that launches `po-eval real` past the refusal would fail on CI. Presence stubs must reach every such test's PATH. They cannot go in `$RTMP/bin` next to the claude double: with `bwrap` in `real_path_spares`, that folder would be kept on the run PATH and `test_lead_cannot_name_the_paid_claude` (`tests/real-run-before-a-release.test.sh:206-221`) would find the paid claude double. A separate folder exported on PATH by the s206 oracle preamble reaches every test that sources it.
- `test_a_session_cannot_widen_the_next` (`tests/real-run-before-a-release.test.sh:272-347`) plays governing changes one at a time, among them `config/rules/x.md`, `config/CLAUDE.md`, `config/.claude.json`, `home/.bashrc`, `home/.gitconfig`, `home/.claude.json`: the listed sets must still see all of them, and must keep ignoring `home/.cache`, `home/private`, `config/projects/*/*.jsonl`.
- `test_suite_never_pays` (`tests/real-run-before-a-release.oracle.test.sh:160-164`) requires `/bin/claude"` in any test file that launches `po-eval` past `--build`: the new oracle has it.
- `docs/ci.md:20` names `real-<date>-v<version>.md`; it is outside `Owns` and stays true for the first record of a day.
- `docs/evals/real-2026-11-23-v0.12.0.md` must not change (s207 criterion).
- Inside the sandbox `.git/config` is read-only: a lead's `git config` or `git push -u` will print errors. Not in this story's reach; the next real run shows it.

## Open questions
- Whether Claude Code honours `Edit(//$J/**)` as a write root from the user settings of `CLAUDE_CONFIG_DIR`; the plan adds `sandbox.filesystem.allowWrite: [$J]` so the origin (`$J/origin.git`), the forge double (`$J/prs`, `$J/calls`) and `TMPDIR` stay writable either way.
- Whether `deny: Bash(curl:*)` still applies to an auto-allowed sandboxed command: kept; the network is closed in any case.
- On macOS the sandbox needs neither tool; the plan checks `bwrap`/`socat` only where `uname -s` is `Linux`.

## Complexity
3 → 3. Four criteria in one file (`evals/real/lib.sh`), one ADR, one doc, three existing test files adjusted; no `po/`, no `method/`.

## Split
—
