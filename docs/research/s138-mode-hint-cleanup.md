# Research — s138-mode-hint-cleanup

[Story](../stories.md)

## Structuring facts
- Root cause (#95): the comment at `method/hooks/po-session.sh:241` says "update on an init project would lay the commands"; since s135, `update` reads the mode through `recorded_mode` (`bin/polype:83`, `bin/polype:94-101`) and keeps an init project init, so the reason given is false. The code below it (`:242-247`) is right; only the comment is stale.
- Root cause (#102): `tests/update-keeps-mode.test.sh:100-101` and `:121-122` hold the same `printf` of `AGENTS.local.md`, byte for byte (checked with `diff`); s136 copied it instead of factoring it.
- No story assumption turned out false. The hook's code must not change: the fix is one comment and one test helper.

## Diagnostic
Reproduction (no file written): `grep -n "would lay" method/hooks/po-session.sh` prints line 241;
`diff <(sed -n 100,101p tests/update-keeps-mode.test.sh) <(sed -n 121,122p …)` prints nothing (identical).
`bash tests/run.sh update-keeps-mode.test.sh` → 7 passed: the defects are not test failures, they are a misleading
comment and a duplication.

| # | Hypothesis | Refuting observation | Verdict |
| --- | --- | --- | --- |
| H1 | The comment is still true: `update` on an init project lays the commands | `update` would lay `.claude/commands/` on an init project | Discarded as a description of the code: `bin/polype:83` sets `mode` from `recorded_mode` for `update`, and `test_init_then_update_stays_init` (`tests/update-keeps-mode.test.sh:37-44`) proves no command copy is laid — so the comment is stale (kept as root cause of #95) |
| H2 | The hint `polype init .` has some other reason than the comment says | ADR-0091 giving no reason for `init .` | Kept: ADR-0091 (`docs/decisions/ADR-0091-…md:32,38`) says `polype init .` repairs an inflated ("gonflé") project by recording `init`; it is also the command `/po-setup` step 3 advises (`tests/update-keeps-mode.test.sh:109-112`) |
| H3 | The two `printf` differ on purpose | A byte difference between `:100-101` and `:121-122` | Discarded: `diff` prints nothing; both tests need the same settings (`Project CLAUDE file: absorbed` triggers the hint line, `po-session.sh:251`) |

## Story
`po-session`'s comment gives the real reason for the `polype init .` hint, and the two session-hint tests share
their settings through one helper.
- `session_comment_says_why` — the comment above the hint choice no longer says `update` would lay the commands;
  it says `polype init .` is the advised command and the one that repairs an inflated project, and points to the
  installer's `recorded_mode` rule. No code line of the hook changes. Test: no "would lay the commands", `recorded_mode` present.
- `absorbed_settings_helper` — `test_hints_say_init` and `test_session_hint_infers_init_without_mode` write their
  `AGENTS.local.md` through one helper; both pass; the second still fails when the deduction branch of `po-session`
  is disabled, and the first still holds the recorded-mode path (`.polype/mode` at `init`).

## Current code
- `method/hooks/po-session.sh:240-247` — inside `waiting_for_a_human()` (`:207`): line 241 is the stale comment;
  `:242-247` choose `again` = `polype init .` when `.polype/mode` reads `init`, or when it is not `project` and the
  manifest lists no `.claude/commands/` (the deduction branch, `:244-245`). Used at `:251`.
- `bin/polype:92-101` — `recorded_mode()`, preceded by its own comment; same rule as the hook (mode file first,
  then manifest without command copies → `init`). s137 does not rename it (story note, `docs/stories.md:2160`).
- `tests/update-keeps-mode.test.sh` — s135's file, extended by s136. Helpers at the top (`fresh_project` `:9`,
  `run_polype` `:20`, `laid` `:25`, `mode_is` `:27`, `no_command_copies` `:29`). `test_hints_say_init` `:98-117`
  runs `init` (which writes `.polype/mode` via `stamp_mode`, `bin/polype:520`) and keeps the mode file;
  `test_session_hint_infers_init_without_mode` `:119-137` removes `.polype/mode` (`:125`, `:133`) so only the
  deduction branch can answer.

## Attachment points
- Comment: `method/hooks/po-session.sh:241`, one line (or two) replacing it, same indentation.
- Helper: next to the other helpers of `tests/update-keeps-mode.test.sh` (`:25-35`), writing `$P/AGENTS.local.md`.
- New tests: in `tests/update-keeps-mode.test.sh`, the only test file the story `Owns`.

## Verified interfaces
- `HOOK="$METHOD/hooks/po-session.sh"` (`tests/update-keeps-mode.test.sh:5`) — the new comment test reads this path.
- `fail` (`tests/lib.sh:11`) exits the test subshell; `contains file text` (`tests/lib.sh:43`) is `grep -qF`.
- `tests/run.sh` runs each `test_*` in `bash -c "set -eu; source ./lib.sh; source <file>; <name>"` (`tests/run.sh:17`):
  a helper defined at file top level is visible to every test of the file.
- `mode_is init <label>` (`tests/update-keeps-mode.test.sh:27`) asserts the content of `.polype/mode`.

## Traps
- `.polype/hooks/po-session.sh` is an installed copy: never edit it (`AGENTS.local.md`, Conventions).
- `tests/update-keeps-mode.test.sh:115` contains "would lay the commands" in a `fail` message: a comment test
  must grep the hook file, not the test file.
- The hook comment must stay a comment: `tests/project-lead.test.sh` and `tests/ship-and-fleet-cleanup.test.sh:95`
  run or mutate the hook; no code line may move in meaning.
- A self-reading structural test (the helper criterion) must count the settings `printf` in its own file; the
  settings text appears nowhere else in that file.
- Convention "one test file per story" vs `Owns`: the story owns only `tests/update-keeps-mode.test.sh`, so its tests
  go there; the header line `:2` may name s138 too.
- Bite: disabling `:244-245` of the hook must still turn `test_session_hint_infers_init_without_mode` red; the helper
  must not write `.polype/mode` nor touch the manifest.

## Open questions
- None blocking. Wording of the comment is the implementer's, within the criterion's three clauses.

## Complexity
Story 1 → 1 after reading: one comment line and one test-file refactor; no code path, no dependency, no ADR.

## Split
—
