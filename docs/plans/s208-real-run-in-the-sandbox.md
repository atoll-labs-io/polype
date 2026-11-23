---
validated: yes
---
# Plan — s208-real-run-in-the-sandbox

[Story](../stories.md) · [Research](../research/s208-real-run-in-the-sandbox.md)

Branch `story/s208-real-run-in-the-sandbox`. Read `docs/research/s208-real-run-in-the-sandbox.md` first; this plan builds on it without repeating it.

Track: full (raised from `flow`: the story needs a new ADR replacing accepted ADR-0136). [ADR-0137](../decisions/ADR-0137-un-passage-reel-confine-ses-commandes-par-le-bac-a-sable-de-claude-code.md) is written `accepted`: the sandbox and the listing are the owner's choices of 2026-11-23, not open ones.

## Story
A real run confines Bash by Claude Code's native sandbox instead of a command list (ADR-0137), compares before and after each session only the files that govern one, and never rewrites a record.
- `sandbox_governs_bash` — sandbox on, auto-allowed, required; no Bash command list; without `bwrap` or `socat` nothing paid starts and the command names them.
- `sandbox_mounts_do_not_dirty_lanes` — the sandbox's masks at a repository root (`.zshrc`, `.profile`, `.gitconfig`, `.mcp.json`, `.idea`…) are absent from `git status --porcelain` of the root and of a lane.
- `governing_is_listed_not_ignored` — only settings, commands, agents, skills, hooks, instructions and installed plugins are compared; a new housekeeping file does not invalidate, a change to one of those does.
- `record_never_overwrites` — a second record of the same day and version takes its own name; no existing record is rewritten.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Sandbox block in the run's settings | the platform: Claude Code's `sandbox` settings | — (first rung that exists; replaces the hand-kept list) |
| Masks hidden from git | the platform: git's `core.excludesFile` default, `$XDG_CONFIG_HOME/git/ignore`, which `real_env` already points at the run's `HOME` (`evals/real/lib.sh:65`) | nothing in the repository hides untracked paths per run |
| `bwrap`/`socat` refusal | this repository: the refusal shape of `real_main` (`evals/real/lib.sh:845-846`), `command -v` on `REAL_RUN_PATH` | — |
| Listed governing sets | this repository: `real_sigs` with a selecting find expression, as `real_project_sigs` does (`:144-148`) | — |
| Free record name | the platform: a counter loop and bash `noclobber` (`set -C`) | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/real-run-in-the-sandbox.oracle.test.sh` | `987626575 7130` |

| Criterion | Test |
| --- | --- |
| `sandbox_governs_bash` | `test_sandbox_governs_bash` — the built settings, then a launch on a PATH with no `bwrap`/`socat` refused (exit 2) before `Continue?`, both named, 0 calls. The ADR half is judged in review (no script reads ADRs). |
| `sandbox_mounts_do_not_dirty_lanes` | `test_sandbox_mounts_do_not_dirty_lanes` — masks created at the root and in a lane; `git status --porcelain` empty in the environment `real_env` sets |
| `governing_is_listed_not_ignored` | `test_governing_is_listed_not_ignored` — four housekeeping files (config and `HOME`) leave `real_governing` unchanged; nine governing changes move it |
| `record_never_overwrites` | `test_record_never_overwrites` — a pre-existing record of the day kept byte for byte, two more `real_record` calls take two new names |

All four fail on the code as it stands (run 2026-11-23, each for its own reason).

## Tasks
1. [x] **ADR links.** `docs/decisions/ADR-0136-…md` frontmatter only: `status: superseded`, `superseded-by: [ADR-0137]`; its body unchanged. ADR-0137 stays as written. — Judged in review (no script reads it).
2. [x] **Sandbox in the run's settings.** In `real_permissions` (`evals/real/lib.sh:109-117`) drop every `Bash(...)` allow rule; keep `autoMemoryEnabled: false`, `Read(//$J/**)`, `Edit(//$J/**)`, `Agent` and the whole `deny` list; add `sandbox: {enabled: true, autoAllowBashIfSandboxed: true, failIfUnavailable: true, filesystem: {allowWrite: [$J]}}` (`allowWrite` keeps the origin, the forge double and `TMPDIR`, all under `$J`, writable whether or not Edit rules count as write roots). Rewrite the comment at `:103-108` to cite ADR-0137. Update the announce at `:859` to `permissions: Claude Code sandbox, prompts denied — …`. — Fails: `test_sandbox_governs_bash` (settings half).
3. [x] **Masks hidden from git.** In `real_env`, after `:63`, write `$J/home/.config/git/ignore` with one anchored pattern per mask Claude Code 2.1.331 names (research, `## Verified interfaces`): `/.gitconfig /.gitmodules /.bashrc /.bash_profile /.zshrc /.zprofile /.profile /.ripgreprc /.mcp.json /.vscode/ /.idea/`, plus `.zshenv`, which the binary's longer lists of the same files add. Do not add `.claude/` paths, and do not touch the throwaway project's `.gitignore`. — Fails: `test_sandbox_mounts_do_not_dirty_lanes`.
4. [x] **No sandbox, no run.** Add `bwrap socat` to the tool list of `real_path_spares` (`:88`). In `real_main`, right after `REAL_RUN_PATH` (`:847`) and before the announce, when `uname -s` is `Linux`: each of `bwrap`, `socat` not found by `PATH="$REAL_RUN_PATH" command -v` is named in `po-eval: a real run needs Claude Code's sandbox: <missing> not found on PATH; nothing run`, exit 2. In the preamble of `tests/real-run-before-a-release.oracle.test.sh`, create presence stubs `bwrap` and `socat` in `$RTMP/sandbox-tools` (never in `$RTMP/bin`, see research `## Traps`) and `export PATH="$RTMP/sandbox-tools:$PATH"`, so every launching test passes on a CI runner without them. — Fails: `test_sandbox_governs_bash` (refusal half); `test_real_run_drives_the_journey_repository` and `test_lead_cannot_name_the_paid_claude` fail if the stubs are missing or misplaced.
5. [x] **Governing listed.** In `real_governing` replace the two prune lists by selections:
   - config (`:190-194`): `settings.json`, `settings.local.json`, `CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md`, and every file under `rules/`, `commands/`, `agents/`, `skills/`, `hooks/`, `output-styles/`, `polype/` (po and the installed method), `plugins/cache/`, `plugins/marketplaces/`, plus `plugins/installed_plugins.json` and `plugins/known_marketplaces.json`;
   - home (`:197-198`): `.bashrc .bash_profile .bash_login .bash_logout .bash_aliases .profile .zshrc .zshenv .zprofile .zlogin .zlogout .envrc .inputrc .gitconfig .mcp.json CLAUDE.md AGENTS.md`, and every file under `.config/git/` and `.claude/`.
   Keep `:195-196,199-216` as they are. Rewrite the comment at `:181-187`: it lists what governs, not what is left out. — Fails: `test_governing_is_listed_not_ignored`; `test_a_session_cannot_widen_the_next` fails if a listed set misses one of its forms.
6. [x] **Record never overwrites.** In `real_record` (`:681`): `real-<date>-v<version>.md` when free, else the first free `real-<date>-v<version>-<n>.md` from `n=2`; write it under `set -C` (in a subshell) so an existing file is never truncated, and fail rather than overwrite. — Fails: `test_record_never_overwrites`; `test_record_holds_no_transcript` still finds `real-*-v*.md`.
7. [x] **Tests and docs that named the list.** `tests/real-run-is-usable.oracle.test.sh` `test_law4_commands_are_allowed`: drop the allow-list equality (the list is gone by ADR-0137), keep the check that `curl` and `claude` are denied. `tests/real-run-before-a-release.test.sh` `test_gh_is_allowed_for_a_lead_that_follows_the_method`: replace "gh in allow" by "gh not denied", keep the intake run. Record both under `## Oracle changes` of the verification record. `docs/evals/real-run.md`: line 15 (a second record of a day takes `-2`, `-3`…; none rewritten), line 28 (the sandbox replaces the list, ADR-0137; writes held to the run folder, network closed; `bwrap` and `socat` required on Linux; the git ignore of the run's `HOME`), line 35 (what is compared is listed by name, config and `HOME`; drop `.last-cleanup` from the examples; housekeeping outside the lists is not compared). — Full suite green.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `po/`, `method/`, `evals/real/claude-print`, `evals/real/grade.sh`, `docs/ci.md`, `docs/evals/real-2026-11-23-v0.12.0.md`, the body of `docs/decisions/ADR-0136-…md` (frontmatter only), `tests/real-run-in-the-sandbox.oracle.test.sh` (cksum above).
- No `Bash(...)` rule in `permissions.allow` of the run's settings; `deny` keeps `WebFetch`, `WebSearch`, `Bash(curl:*)`, `Bash(claude:*)`; no `bypassPermissions`, no `--dangerously-skip-permissions`, no `allowUnsandboxedCommands: true`, no `ignoreViolations`.
- No command beyond the owner's choices: nothing in `sandbox.network`, no `excludedCommands`.
- Never run `bin/po-eval real` past its confirmation with a real `claude` on PATH; the suite and every check use the doubles.
- The throwaway project (`tests/journey/project/`) is not touched.

## The pivot
The listed sets of task 5 are exactly what governs a session in Claude Code's config and the run's `HOME`. Ways it could be wrong:
- **A governing file outside the lists** (a key Claude Code loads from a new file, e.g. `keybindings`, a managed-settings file in the config dir, a plugin layout that moved): a session could widen the next one unseen. Compare the config list with the `## Settings files` and plugin pages of the Claude Code docs and with what `strings` of the installed binary names next to `installed_plugins.json`.
- **Housekeeping inside a listed folder** (Claude Code refreshing `plugins/marketplaces/` or rewriting `installed_plugins.json` at start, as it does on the owner's own config): the run is invalid again, on a path that governs. Evidence against it today: in the second run nothing sorting before `plugins/store` changed (research, `## Structuring facts`); only a real run settles it.
- **The sandbox keys ignored** by the Claude Code in use: with no Bash list left, every command would prompt and be refused, which the stream shows as `permission_denied`; `failIfUnavailable` makes a missing sandbox stop the session instead. Compare the keys with the docs' `sandbox` section before a real run.

## Files touched
`evals/real/lib.sh`, `docs/decisions/ADR-0136-…md` (frontmatter), `docs/decisions/ADR-0137-…md` (written by the planner), `docs/evals/real-run.md`, `tests/real-run-before-a-release.oracle.test.sh` (preamble), `tests/real-run-before-a-release.test.sh`, `tests/real-run-is-usable.oracle.test.sh`, `tests/real-run-in-the-sandbox.oracle.test.sh` (planner), `docs/research/s208-…md`, `docs/plans/s208-…md`.

## Test strategy
Automated, bash, no paid call (`Test budget` 25): the four oracle tests, which cover tasks 2 to 6 through the command (`po-eval real`, `--build`) or the functions the existing tests already call (`real_governing`, `real_env`, `real_record`). No new task test: tasks 4, 5 and 7 are also held by existing tests that would fail if done wrong (`test_real_run_drives_the_journey_repository`, `test_lead_cannot_name_the_paid_claude`, `test_a_session_cannot_widen_the_next`, `test_record_holds_no_transcript`). Two existing tests change because their clause changes (task 7). Tests of a task run alone: `bash tests/run.sh real-run-in-the-sandbox.oracle.test.sh` and the two files of task 7; the full suite once at the end through `po-run`.

Model-read rules: none. ADR-0137 and the doc are judged in review.

Visual checks: none.

## Done when
The four oracle tests and the full suite pass; ADR-0136 points at ADR-0137; `docs/evals/real-run.md` describes the sandbox, the listed sets and the record naming; one commit on `story/s208-real-run-in-the-sandbox`; a review with no open critical finding. The next real run, which the lead proposes to the owner once shipped, is what shows the sandbox and the lists hold.
