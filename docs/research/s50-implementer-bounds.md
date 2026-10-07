# Research — s50-implementer-bounds

## Structuring facts
- **False assumption: `bin/polype` needs no change.** The installer already ships every file of `method/hooks/` to `.polype/hooks/` for both `init` and `install <project>` (`bin/polype:98`, `bin/polype:101`) and marks anything under `*/hooks/*` executable (`bin/polype:143`, `bin/polype:157`). Adding `method/hooks/po-bounds.sh` is enough; `installer_ships_the_bounds_hook` is a test, not a code change.
- **False assumption: the hook can say `.polype/hooks/po-bounds.sh` as a relative path.** A command hook runs "in the current directory" of the session (hooks reference, `code.claude.com/docs/en/hooks.md:414`), and a subagent's shell does not keep its `cd`. The path must be anchored on `$CLAUDE_PROJECT_DIR`, which Claude Code exports to every command hook (`hooks.md:495`, `hooks.md:603`).
- **The script is not told which story it guards.** The hook input carries `tool_name`, `tool_input` (`file_path` for Write/Edit, `command` for Bash), `cwd`, `agent_type` (`hooks.md:733-747`) — no story id. The id has to be derived from where the write or the git command lands (ADR-0024).
- **Verified: subagent frontmatter accepts `hooks:`** with `PreToolUse` (`code.claude.com/docs/en/sub-agents.md:312`, `:735-773`), and only exit 2 blocks: any other code, a missing script (127) or a non-executable one (126) is a non-blocking error and the tool call proceeds (`hooks.md:824-842`, `:837`). A timed-out hook does not block either (`hooks.md:843-851`).
- **Gap the story did not see: project-level agent hooks need workspace trust.** Frontmatter hooks of an agent in `.claude/agents/` are skipped until the folder's trust dialog is accepted, and a `-p` session never counts as trusted; agents in `~/.claude/agents/` run their hooks without it (`sub-agents.md:743-745`, `hooks.md:696`). So under `polype install <project>` the bounds silently fail open in `claude -p` runs.

## Story
The implementer must only be able to write inside its story's paths. A PreToolUse hook declared in `method/agents/implementer.md` on Edit, Write and Bash calls `po-bounds.sh implementer`; any launch failure becomes exit 2; writes outside `Owns` and `docs/` are refused with the path and the `Owns` line; `git switch|checkout|stash|worktree add|push` are refused, even inside a compound command, as is `git commit` off `story/<id>`; unknown story, missing `Owns` or unreadable input → 2. The installer lays the script under `.polype/hooks/`; `docs/installation.md` names the upgrade path (`polype init <projet>` after a global update). Criteria: `implementer_declares_a_pretooluse_hook`, `bounds_hook_blocks_when_the_script_cannot_run`, `bounds_deny_writes_outside_owns`, `bounds_deny_forbidden_git_verbs`, `bounds_fail_closed`, `installer_ships_the_bounds_hook`, `installation_doc_names_the_upgrade_path`.

## Current code
- `method/agents/implementer.md:1-8` — frontmatter: `name`, `description`, `tools: Read, Write, Edit, Bash, Grep, Glob` (`:4`), `model: opus`, `skills:` list with `  - testing-doctrine` (`:6-7`). No `hooks:`. The Law 4 prohibitions are prose only (`:17`): "never checkout, switch or stash, never commit to the target branch". `## Limits` at `:42-46`.
- `method/hooks/po-gate.sh` — style reference for a new hook script: `#!/usr/bin/env bash`, header comment listing subcommands (`:2-9`), `set -euo pipefail` (`:10`), `refuse()` printing `po-gate: …` to stderr (`:13`), one `case` dispatch on `$1` with unknown → exit 2 (`:62-68`). Reads no setting (story s48 note confirms the rule).
- `method/hooks/pre-commit:4` — the only other hook, an `exec` of `po-gate.sh pre-commit`.
- `bin/polype` — `target_is_a_project` (`:93-105`): `init` ships `method/templates` and `method/hooks`; `install <project>` adds commands, agents, skills. Global install ships agents to `~/.claude/agents/` and the whole `method/` to `~/.claude/polype/method` (`:86-87`), never to a project's `.polype/`.
- `docs/installation.md` (French) — `## Activer un projet` (`:62-77`) and `## Ce qui est posé dans un projet` table (`:103-123`) list `method/hooks/ → .polype/hooks/ (rendus exécutables)`. `:100-101` already says "Chaque projet suit avec `polype init <projet>`" in the chezmoi section, without any consequence attached. No mention of `jq`, of trust, or of a Claude Code hook.
- `method/skills/review-antihallu/SKILL.md:9-20` — the review's own `Owns` check (outside → major, another lane's → critical). Stays as is (story note).

## Attachment points
- `method/agents/implementer.md` frontmatter: a `hooks:` block **after** the `skills:` list.
- `method/hooks/po-bounds.sh`: new file, mode as first argument (`implementer`; s51 adds `qa`).
- `tests/bounds.test.sh`: new, one function per criterion name.
- `docs/installation.md`: a subsection under `## Activer un projet`.

## Verified interfaces
- Hook input (stdin JSON): `.tool_name`, `.tool_input.file_path` (Write `hooks.md:1676`, Edit `:1685`), `.tool_input.command` (Bash `:1625`), `.cwd`. Exit 2 → the tool call is blocked and stderr is the reason shown to Claude (`hooks.md:800-810`).
- Shell-form command: run by `sh -c`, so `||` works; exec form (`args`) would not allow it (`hooks.md:464-480`).
- `docs/stories.md` story format in this repo: heading `### <id> — <title>` (`docs/stories.md:750`), Owns line `- **Owns** : \`a\`, \`b/\`` (`:755`) — French spacing before the colon; the method template writes `## <id> — <title>` and `- **Owns**: <paths>` (`method/templates/stories.md:7`, `:12`). Directories end in `/` (`evals/`, `method/skills/design-doctrine/`, `docs/stories.md:804`, `:766`); "a directory owned by one story covers every path beneath it" (`method/skills/review-antihallu/SKILL.md:11`).
- Linked vs main worktree: in a linked worktree `git rev-parse --git-dir` differs from `--git-common-dir`; equal in the main one.
- `tests/lib.sh`: `scratch_repo` (`:46-53`) sets `SCRATCH` and a cleanup trap; `frontmatter` (`:13-15`); `contains` (`:43`); `require_file` (`:41`). `tests/global-install.test.sh:9-31` gives the throwaway-HOME pattern (`global_home`, `guard_home`) for running `polype init`; `tests/install.test.sh:4-7` calls `bin/polype-dev-install` for `install <project>`.
- Tools on this machine: `jq`, `realpath` present (`/usr/bin`). Nothing in `method/`, `bin/` or `tests/` uses `jq` or `python3` today.

## Traps
- **Frontmatter parsers.** `tests/fleet-design.test.sh:13-15` and `bin/po-lint:52-61` read `skills:` as consecutive `^  - ` lines; `tests/execute.test.sh:33` greps `  - testing-doctrine` exactly; `tests/lib.sh:18-25` reads `tools:` inline. A `hooks:` block placed after `skills:` with entries indented by four spaces or more cannot be mistaken for a skill. Run `bin/po-lint` and the full suite after the edit (story note).
- **Fail-open paths that remain** (documented, not fixable in a script): Claude Code skipping project-level frontmatter hooks without trust / in `-p`; a hook timeout; Bash redirections (`>`), `sed -i`, `cp` writing outside `Owns` — the story excludes them on purpose; the review's ownership check still catches them.
- **Self-widening.** `docs/` is writable, so the implementer could edit `docs/stories.md` and widen its own `Owns`. Reading `Owns` from the committed `HEAD:docs/stories.md` of the worktree closes that during a run.
- **This repository.** Its pipeline uses the installed copies at the root (`.claude/agents/`, `.polype/hooks/`). They are refreshed by `bin/polype-dev-install .` on `main` after ship, not by this story; until then this repo's implementer has no hook. Once refreshed, `.claude/agents/implementer.md` is project-level → trust needed.
- **Text scan false positives.** A command like `grep -n "git checkout" method/…` would be refused by a scan that ignores quoting. Plausible in this very repo, where method files quote those verbs.
- `tests/gate.test.sh:126` copies every `method/hooks/*` into a scratch project: a new script there is harmless to it.
- Global install test counts files twice and compares (`tests/global-install.test.sh:70-74`): adding a file changes no assertion.
- No migration. New runtime dependency: `jq` (ADR-0024).

## Open questions
- Does Claude Code expand `$CLAUDE_PROJECT_DIR` to the repository root for a subagent launched from a driver session? The doc says "project root where the session started" (`hooks.md:603`); if a session starts in a subdirectory the path misses and the hook refuses everything — closed, but annoying. The plan accepts this.
- Should quoted text be parsed (quote-aware tokenizer) or scanned as plain words? Settled in ADR-0024: plain words after removing quote characters, false positives accepted.
- Only a live Claude Code session can prove the hook fires in a subagent; the tests prove the script and the wrapper, not Claude Code. The record must say so under "Not proven here".

## Complexity
Story: 4. After reading: **4**. The installer half is free (no change), but the Bash verb scan, the worktree-based story resolution and the fail-closed wrapper are real logic, and the trust gap adds documentation.

## Split
Not needed (4).
