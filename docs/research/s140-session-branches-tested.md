# Research — s140-session-branches-tested

[Story](../stories.md)

## Structuring facts
- Root cause (#107): `tests/update-keeps-mode.test.sh:103-112` (`test_hints_say_init`) runs on a project laid by `init`, whose manifest holds no `.claude/commands/` entry, so the inference half of the condition at `method/hooks/po-session.sh:245-246` gives `polype init .` too. The other session test removes `.polype/mode` (`tests/update-keeps-mode.test.sh:129,137`). No fixture has `.polype/mode` set to `init` **and** command copies in the manifest. Proof: with `[ "$recorded" = init ]` disabled, all 9 tests of the file and the 52 tests of every file naming `po-session` still pass (the one failure is caused by the copy having no git, see Diagnostic).
- Root cause (#108): the comment at `method/hooks/po-session.sh:241-242` reads "advise polype init ., the advised command and the one that repairs an inflated project.": "advise" twice (once as `advised`), and the bare `.` of `polype init .` reads like the end of a sentence.
- Every assumption of the story holds: the condition is at `:245`, and `recorded` is read at `:244`. `absorbed_settings` (`tests/update-keeps-mode.test.sh:29-32`) and `mode_is` (`:27`) exist.
- #107 is already **closed** on GitHub (2026-10-16, "completed", no comment), but the defect still reproduces on this code. #108 is open.

## Diagnostic
**Reproduction** (run in a copy of the worktree in `/tmp`, deleted afterwards; nothing written in the worktree):
1. `bash tests/run.sh update-keeps-mode.test.sh` → 9 passed.
2. Line 245 rewritten to `if false && [ "$recorded" = init ] || { …`, then the same run → 9 passed. The gap is reproduced.
3. Same mutation, every test file naming `po-session` → 51 passed, 1 failed (`readme-onboarding.test.sh` `quickstart_runs_as_written`). It fails the same way on the unmutated hook, because it clones `$ROOT` and the copy had no `.git`. So the mutation is not what breaks it.
4. Candidate scenario (a scratch test sourced from `/tmp`): `fresh_project`, `absorbed_settings`, `install "$P"` (the manifest gets `.claude/commands/`), `printf 'init\n' > .polype/mode`, commit, `CLAUDE.local.md` written, hook run. Original hook → `- CLAUDE.local.md: … → polype init . moves it into AGENTS.local.md`; mutated hook → `… → polype update . moves it …`. The scenario tells the two branches apart.

**Hypotheses**
- H1: no fixture reaches a state where the recorded branch and the inference branch disagree. Would be refuted by a test that fails under the mutation. **Kept**: steps 2 and 3.
- H2: another test file (`claude-md-setting`, `no-claude-md`, `project-lead`, …) covers the recorded branch. Would be refuted by a failure under the mutation in those files. **Discarded**: step 3, the only failure does not depend on the mutation.

## Story
A test separates the "recorded mode" branch of `po-session`'s hint from the "inferred mode" branch, and the comment above the choice reads in one go.
- `session_hint_trusts_recorded_mode`: on an inflated project (laid by `install`, the manifest lists `.claude/commands/`) with `.polype/mode` set to `init`, `po-session` gives, for a `CLAUDE.local.md` under `Project CLAUDE file: absorbed`, the line `… → polype init . moves it into AGENTS.local.md`. The test fails when `[ "$recorded" = init ]` is disabled.
- `session_comment_reads_once`: the comment above the choice holds the word `advise` (`grep -w`) once and writes `` `polype init .` `` in backticks. `test_session_comment_says_why` still passes. No code line of the hook changes.

## Current code
- `method/hooks/po-session.sh:241-248`: the comment, then `again="polype update ."` (`:243`), `recorded` read from the first line of `.polype/mode` (`:244`), and the condition (`:245-246`): recorded `init`, or (recorded not `project`, a manifest exists, and it lists no `.claude/commands/`) → `again="polype init ."` (`:247`).
- `:249-256`: for `CLAUDE.md` / `CLAUDE.local.md` with `claude_md=absorbed`, the line `$name: Claude Code reads it instead of AGENTS.md → $again moves it into AGENTS.local.md` (`:252`), printed as `- …` (`:261`).
- `bin/polype:95-102` `recorded_mode`: the installer's rule, which the comment names.
- `tests/update-keeps-mode.test.sh`: `fresh_project` (`:9-18`, throwaway home plus a global install), `run_polype` (`:20-23`), `mode_is` (`:27`), `absorbed_settings` (`:29-32`), session tests `:103-141`, comment test `:153-158`, helper test `:160-168`.

## Attachment points
- New test function in `tests/update-keeps-mode.test.sh`, next to `test_session_hint_infers_init_without_mode` (`:124`).
- Comment lines `method/hooks/po-session.sh:241-242` only.
- The new comment test also goes in `tests/update-keeps-mode.test.sh`, next to `test_session_comment_says_why` (`:153`).

## Verified interfaces
- How the hook is called in tests: `out="$(cd "$P" && CLAUDE_PROJECT_DIR="$P" bash "$HOOK")"` (`tests/update-keeps-mode.test.sh:110,132`); `HOOK="$METHOD/hooks/po-session.sh"` (`:5`).
- `run_polype install "$P"` lays command copies: checked by `grep -q '^\.claude/commands/' "$P/.polype/manifest"` (`:136`), and it writes `project` into `.polype/mode` (`:63`).
- The project must be committed before the hook runs (`:108`, `:128`), so the uncommitted `CLAUDE.local.md` is the only thing left.
- `test_session_comment_says_why` (`:153-158`): no comment holds `would lay the commands`, and some comment holds `recorded_mode` and `polype init .` (`grep -F`, so `` `polype init .` `` matches).
- `test_absorbed_settings_helper` (`:160-168`): the `printf … Project CLAUDE file: absorbed` line stays the only one in the file. A new test must call `absorbed_settings`, never repeat the printf.

## Traps
- Writing `init` into `.polype/mode` after `install` is a hand-made state (#107's "inflated init project"), but it is the only way to make the two branches disagree with the mode file present. The hook only reads files, so the fixture is not one the caller could never send: a project activated by `init`, then inflated by hand or by an older installer, carries exactly that.
- If `CLAUDE.local.md` were written before `install`, the installer would absorb it under `absorbed`: write it after the commit, as `:109` does.
- Whole-word count: `grep -ow advise` does not count `advised`. Today's comment already holds the word `advise` once under `-w`. The comment test therefore also needs its backtick clause to fail on today's text, and the new wording should drop `advised` (the second "advise" of #108).
- No test pins the hook's comment text or its line numbers (grep of `tests/` and `method/` for `advise`, `repairs an inflated`, `po-session.sh:2NN`: nothing).
- `tests/readme-onboarding.test.sh` `quickstart_runs_as_written` needs a real git checkout: it passes in the worktree, but it fails in a copy without `.git`.
- No migration. No other story owns these two files.

## Open questions
- #107 is closed while its defect stands: should it be reopened, or does the ship's "Fixes" reference suffice? This is the lead's call, not this plan's.

## Complexity
1 → 1. One new test with a fixture, one test that pins the comment, two comment lines.

## Split
—
