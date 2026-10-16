---
validated: yes
---
# Plan — s140-session-branches-tested

[Story](../stories.md) · [Research](../research/s140-session-branches-tested.md)

Branch `story/s140-session-branches-tested`. Read `docs/research/s140-session-branches-tested.md` first: this plan builds on it and does not repeat it.

## Story
Fixes #107 and #108. `po-session`'s hint must have a test that fails when its "recorded mode" branch breaks, and the comment above the choice must read in one go.
- `session_hint_trusts_recorded_mode`: inflated project (laid by `install`) with `.polype/mode` set to `init` → `- CLAUDE.local.md: Claude Code reads it instead of AGENTS.md → polype init . moves it into AGENTS.local.md`. The test fails when `[ "$recorded" = init ]` (`method/hooks/po-session.sh:245`) is disabled.
- `session_comment_reads_once`: the comment above the choice holds `advise` once (`grep -w`) and `` `polype init .` `` in backticks. `test_session_comment_says_why` still passes. No code line of the hook changes.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Fixture of the new session test | already in this repository: `fresh_project`, `run_polype`, `absorbed_settings`, `mode_is` (`tests/update-keeps-mode.test.sh:9-32`), and the hook call of `:110` | — |
| Extracting the comment block | standard tools (`awk`, `grep -ow`), already used in this file (`:165`) | nothing in this repository extracts the comment block that sits just above a given code line |

## Tasks
1. [x] Add `test_session_hint_trusts_recorded_mode` to `tests/update-keeps-mode.test.sh`, after `test_session_hint_infers_init_without_mode`. Steps: `fresh_project`; `absorbed_settings`; `run_polype install "$P" >/dev/null`; check that the manifest lists `^\.claude/commands/` (or fail "install laid no command copies"); `printf 'init\n' > "$P/.polype/mode"`; `mode_is init "inflated init project"`; `git -C "$P" add -A && git -C "$P" commit -qm activate`; then write `CLAUDE.local.md`; run the hook as `:110` does; `grep -qxF --` the exact line `- CLAUDE.local.md: Claude Code reads it instead of AGENTS.md → polype init . moves it into AGENTS.local.md`, and fail with the output otherwise. Call `absorbed_settings`, never a new printf of the settings (`test_absorbed_settings_helper`, `:160-168`), and add the new test to that helper's loop list (`:164`) so it keeps using the helper. Test that would fail: this one, when `[ "$recorded" = init ]` is disabled. The research reproduced it on a scratch copy (original hook gives `polype init .`, mutated hook gives `polype update .`).
2. [x] Rewrite the comment `method/hooks/po-session.sh:241-242` and touch only those comment lines. Required: `recorded_mode` stays, the command is written `` `polype init .` ``, the word `advise` appears once, and `advised` is gone. Suggested wording (two lines, under 100 characters each): `# Same rule as the installer's recorded_mode: on an init project, advise \`polype init .\`, which` / `# also repairs an inflated one; elsewhere \`polype update .\`.` Test that would fail: task 3, and `test_session_comment_says_why` (`:153-158`) if `recorded_mode` or `polype init .` were dropped.
3. [x] Add `test_session_comment_reads_once` to `tests/update-keeps-mode.test.sh`, after `test_session_comment_says_why`. With awk on `$HOOK`, collect the run of `#` lines just above the line that matches `local again=`, and fail if that run is empty. Then require: `grep -ow 'advise'` counts exactly 1; the block holds `` `polype init .` `` (`grep -F`). Test that would fail: this one, on today's comment, which has no backticks (it already counts one whole-word `advise`, so the backtick clause is what bites), and on any comment that says `advise` twice.
4. [x] Run `bash tests/run.sh update-keeps-mode.test.sh` (task tests), then the full suite once through `po-run --story s140-session-branches-tested --label test -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- `git diff main...story/s140-session-branches-tested -- method/hooks/po-session.sh` shows only lines that start with `#` (after leading spaces): no code line changes.
- No file outside `method/hooks/po-session.sh`, `tests/update-keeps-mode.test.sh`, `docs/research/s140-session-branches-tested.md`, `docs/plans/s140-session-branches-tested.md` and `docs/verif/s140-session-branches-tested.md` changes. In particular, `bin/polype` (`recorded_mode` keeps its name), `.claude/` and `.polype/` stay untouched.
- The existing tests of `tests/update-keeps-mode.test.sh` keep their bodies. The only exception is the loop list of `test_absorbed_settings_helper` (`:164`), which gains the new test's name.
- No reopening or closing of GitHub issues from this lane.

## The pivot
The fixture: `install`, then `.polype/mode` forced to `init`. It is the only on-disk state where the two halves of the condition at `:245-246` disagree while the mode file is present. Ways it could be wrong:
- The forced `init` gets overwritten before the hook runs (for instance, by a polype call placed after it): check that `mode_is init` passes right before the hook call, with no `run_polype` in between.
- The manifest lacks `.claude/commands/`, so the inference branch also says `init` and the test stops biting: the explicit manifest check of task 1 guards this. The reviewer's bite check (disable `[ "$recorded" = init ]`, rerun `update-keeps-mode.test.sh` alone) is the proof.
- The comment test reads the wrong block: if the awk anchor `local again=` moved or got renamed, the block would come out empty. Task 3 fails on an empty block rather than passing.

## Files touched
- `tests/update-keeps-mode.test.sh`: two new tests, and one name added to the helper test's loop.
- `method/hooks/po-session.sh`: comment lines 241-242.

## Test strategy
2 new tests, within the `Test budget` of 25, both in `tests/update-keeps-mode.test.sh`:
- `test_session_hint_trusts_recorded_mode`: behaviour of the hook on the inflated init project (the only layer is the hook run as a process).
- `test_session_comment_reads_once`: pins the comment's wording.
`test_session_comment_says_why` is kept as is. No visual check.

## Done when
Both criteria hold. `bash tests/run.sh` passes as a whole through `po-run`. The reviewer's bite check on `:245` turns `test_session_hint_trusts_recorded_mode` red. One commit by the implementer, then review and ship, which reference #107 and #108.
