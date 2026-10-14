# Research — s136-session-hint-infers-init

[Story](../stories.md)

## Structuring facts
- Root cause: no test reaches the inference branch of `method/hooks/po-session.sh:244-245` (no `.polype/mode`, manifest without `^\.claude/commands/` → `polype init .`). `test_hints_say_init` (`tests/update-keeps-mode.test.sh:98-107`) keeps the mode file written by `init`, so `recorded=init` short-circuits the `||` at `:244`. Proof: with `&& false` appended to the branch (`:245`), `bash tests/run.sh update-keeps-mode.test.sh no-claude-md.test.sh claude-md-setting.test.sh` → 14 passed, 0 failed.
- The code itself is right: on a real init project with `.polype/mode` removed, the hook prints `polype init . moves it into AGENTS.local.md`; on a full install without it, `polype update . moves it…` (reproduction below). The story is test-only, as its notes expect.
- `test_mode_inferred_without_state` (`tests/update-keeps-mode.test.sh:64`) covers the installer's inference, not the hook's.

## Diagnostic
**Reproduction.** (1) Mutation (d) in place on `po-session.sh:245`, focused suites run, file restored with `git restore` (worktree clean after): 14 passed. (2) Script outside the worktree (throwaway HOME under the job tmp): `install --global`, then `init` / `install` on a scratch repo with `Project CLAUDE file: absorbed`, `.polype/mode` removed, `CLAUDE.local.md` added, hook run → init: `… → polype init . moves it into AGENTS.local.md`; install: `… → polype update . moves it into AGENTS.local.md`.

**Hypotheses**
1. *The branch is wrong and the tests hide it.* Refuted if the real hook prints `polype init .` without a mode file on an init project. It does → discarded.
2. *No test exercises the branch.* Refuted if mutation (d) makes a test fail. None fails → kept: root cause.

## Story
One criterion, `session_hint_infers_init_without_mode`: init project without `.polype/mode` → `polype init .` line; full install without it → `polype update .` line; fails when the branch is disabled.

## Current code
- `method/hooks/po-session.sh:241-252`: `again` computed from `.polype/mode`, else manifest; printed in the `absorbed` case at `:251`.
- `tests/update-keeps-mode.test.sh`: helpers `fresh_project`, `run_polype`, `HOOK` (top of file); `test_hints_say_init` at `:98`.

## Attachment points
A new `test_session_hint_infers_init_without_mode` in `tests/update-keeps-mode.test.sh`, reusing `fresh_project` and the `AGENTS.local.md` line of `test_hints_say_init`.

## Verified interfaces
- Hook run: `(cd "$P" && CLAUDE_PROJECT_DIR="$P" bash "$HOOK")` (`tests/update-keeps-mode.test.sh:105`).
- The hook reads the file tree, not git, for `.polype/mode` and the manifest (`po-session.sh:243-245`): an uncommitted deletion is enough.

## Traps
- The hook exits early without `AGENTS.local.md` or `.polype/version` (`po-session.sh:12`) — both exist after a pose.
- `fresh_project` is called once per test; the full-install side needs a second scratch project or a second pose in a sub-folder.
- Test budget 25; this adds one test.

## Open questions
None.

## Complexity
Story 1 → 1.

## Split
Not needed.
