---
validated: yes
---
# Plan — s138-mode-hint-cleanup

[Story](../stories.md) · [Research](../research/s138-mode-hint-cleanup.md)

Branch `story/s138-mode-hint-cleanup`. Read `docs/research/s138-mode-hint-cleanup.md` first; this plan builds on it without repeating it.

Validated by the planner under `Plan validation: autonomous`; no human reviewed it.

## Story
Fixes #95 and #102. The comment above `po-session`'s hint choice gives the real reason, and the two session-hint
tests share their settings through one helper. Criteria: `session_comment_says_why`, `absorbed_settings_helper`.

## Reuse
One test helper is the only new code; the comment is prose.

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `absorbed_settings` helper in `tests/update-keeps-mode.test.sh` | new code (three lines) | Already in the repository: no helper of `tests/lib.sh` or of this file writes `AGENTS.local.md` (helpers listed at `tests/update-keeps-mode.test.sh:9-35`); the other test files' settings writers are file-local and carry other settings. Platform/dependency: not applicable. |

## Tasks
1. [x] **Rewrite the comment** at `method/hooks/po-session.sh:241`, comment lines only, same indentation. It must
   (a) drop the claim that `update` would lay the commands, (b) say `polype init .` is the advised command for an init
   project and the one that repairs an inflated project, (c) say the mode is read by the same rule as the installer's
   `recorded_mode`. Lines under 100 characters. Example:
   `# init project (same rule as the installer's recorded_mode): advise polype init ., the advised command and the`
   `# one that repairs an inflated project.` — wording free within (a)-(c).
   Test able to fail: `test_session_comment_says_why` (task 3).
2. [x] **Add the helper** `absorbed_settings` next to `mode_is` (`tests/update-keeps-mode.test.sh:27`): it writes the
   exact settings now at `:100` (same seven lines, same order) to `$P/AGENTS.local.md`. Replace the `printf … >
   "$P/AGENTS.local.md"` of `test_hints_say_init` (`:100-101`) and of `test_session_hint_infers_init_without_mode`
   (`:121-122`) by a call to it. In `test_hints_say_init`, add `mode_is init "before the session hint"` right after
   the `init` run (`:102`), so the recorded-mode path is asserted, not assumed. The helper writes nothing else: no
   `.polype/mode`, no manifest. Tests able to fail: both existing tests, and `test_absorbed_settings_helper` (task 3).
3. [x] **Add two tests** to `tests/update-keeps-mode.test.sh`, named after the criteria:
   - `test_session_comment_says_why` — reads `$HOOK`: fails if it contains `would lay the commands`; takes the comment
     lines (`^[[:space:]]*#`) and fails unless one holds `recorded_mode` and one holds `polype init .`.
   - `test_absorbed_settings_helper` — reads its own file (`$ROOT/tests/update-keeps-mode.test.sh`): fails unless
     `Project CLAUDE file: absorbed` appears exactly once (inside the helper), and unless the bodies of
     `test_hints_say_init` and `test_session_hint_infers_init_without_mode` each call `absorbed_settings`
     (extract each body with `awk` between `^test_<name>()` and the next `^}`).
   Update the header line `:2` to name s138 beside s135. Test able to fail: each test against the pre-fix files
   (the comment test is red on `main`, the helper test sees two copies on `main`).
4. [x] **Run** `bash tests/run.sh update-keeps-mode.test.sh` (task tests), then the full suite once through
   `po-run --story s138-mode-hint-cleanup --label test -- 'bash tests/run.sh'` (`Full suite: execute-end`).

## Scene viewpoints
—

## Run interdicts
- `git diff main...story/s138-mode-hint-cleanup -- method/hooks/po-session.sh` changes only lines whose first
  non-blank character is `#`; lines `:242-247` and everything else of the hook are byte-identical.
- `bin/polype` ends with an empty diff (owned by s137; `recorded_mode` keeps its name).
- `.polype/` and `.claude/` (installed copies) end with an empty diff.
- No test file other than `tests/update-keeps-mode.test.sh` changes; no existing assertion of it is removed or
  weakened — only the two `printf` lines move into the helper and one `mode_is` line is added.
- `test_session_hint_infers_init_without_mode` keeps its two `rm -f "$P/.polype/mode"` (`:125`, `:133`).
- No ADR written; ADR-0093 stays unused.

## The pivot
That the helper refactor keeps each test on its own path: `test_hints_say_init` on the recorded mode,
`test_session_hint_infers_init_without_mode` on the deduction. Ways it could be wrong:
- the helper writes or deletes `.polype/mode`, so one test silently runs the other's path — compare the helper body
  with `mode_is init` now asserted in `test_hints_say_init` and the `rm -f` kept in the other;
- the settings text drifts from the original `:100` (e.g. `Project CLAUDE file` dropped), so the hint line never
  prints and the deduction bite turns red for the wrong reason — compare with `main`'s `:100`;
- the comment test matches the test file's own `fail` message (`:115`) instead of the hook — check it reads `$HOOK`.
Reviewer bite: disable `:244-245` of `method/hooks/po-session.sh` in a copy; `test_session_hint_infers_init_without_mode`
must go red, `test_hints_say_init` must stay green.

## Files touched
- `method/hooks/po-session.sh` (comment only)
- `tests/update-keeps-mode.test.sh`
- `docs/research/s138-mode-hint-cleanup.md`, `docs/plans/s138-mode-hint-cleanup.md`

## Test strategy
Two new tests, two existing tests reworked; 4 of `Test budget` 25. Both new tests are structural reads of a file,
the layer this repository uses for method text (`AGENTS.local.md`, Conventions). The behaviour tests stay the existing
`test_hints_say_init` (recorded mode) and `test_session_hint_infers_init_without_mode` (deduction), which run the hook.
- Would `test_session_comment_says_why` fail if the rule were gone? Yes: the old comment lacks `polype init .` in
  a comment line and holds `would lay the commands`.
- Would `test_absorbed_settings_helper` fail? Yes: a second copy of the settings, or a test not calling the helper.
No visual check (no screen).

## Done when
Both criteria hold, `bash tests/run.sh` green through `po-run`, the hook's code lines unchanged, one commit on
`story/s138-mode-hint-cleanup` carrying code, tests, research and plan; review with no open critical finding.
