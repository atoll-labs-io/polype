---
validated: yes
---
# Plan — s136-session-hint-infers-init

[Story](../stories.md) · [Research](../research/s136-session-hint-infers-init.md)

Branch `story/s136-session-hint-infers-init`. Read `docs/research/s136-session-hint-infers-init.md` first; this plan builds on it without repeating it.

## Story
Fixes #94. One criterion, `session_hint_infers_init_without_mode`: po-session prints `polype init . moves it into AGENTS.local.md` on an init project whose `.polype/mode` was removed, and `polype update . moves it…` on a full install without it; the test fails when the inference branch (`method/hooks/po-session.sh:244-245`) is disabled.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| One test function | Repository: `fresh_project`, `run_polype`, `$HOOK` and the `AGENTS.local.md` line of `test_hints_say_init` (`tests/update-keeps-mode.test.sh:9-23,98-107`) | — |

## Tasks
1. [x] Add `test_session_hint_infers_init_without_mode` to `tests/update-keeps-mode.test.sh`, after `test_hints_say_init`: `fresh_project`; write the same `AGENTS.local.md` as `test_hints_say_init` (with `Project CLAUDE file: absorbed`); `run_polype init "$P"`; commit; `rm -f "$P/.polype/mode"`; add `CLAUDE.local.md`; run the hook; assert the exact line `- CLAUDE.local.md: Claude Code reads it instead of AGENTS.md → polype init . moves it into AGENTS.local.md` (`grep -qxF`). Then, in the same project, `run_polype install "$P"` (a full install, which records `project`), `rm -f "$P/.polype/mode"`, run the hook again, assert the same line with `polype update .`. The test that can fail: this one, under mutation (d).
2. [x] Full suite `bash tests/run.sh` green through `po-run`; record in `docs/verif/s136-session-hint-infers-init.md`, noting that mutation (d) (`&& false` appended to `po-session.sh:245`) makes the new test fail, file restored afterwards.

## Scene viewpoints
—

## Run interdicts
- `method/hooks/po-session.sh`, `bin/polype` and every other file outside `tests/update-keeps-mode.test.sh` and `docs/` end with an empty diff.
- Existing tests of `tests/update-keeps-mode.test.sh` unchanged.
- No fix of #95/#96/#97.

## The pivot
That `install` over an init project records `project` and lays a manifest with `.claude/commands/` lines, so removing the mode file still leaves the hook to infer `project` from the manifest. Could be wrong if `install` after `init` keeps the init manifest — check the manifest holds a `.claude/commands/` line before removing the mode (compare with `test_init_then_update_stays_init`'s install branch).

## Files touched
`tests/update-keeps-mode.test.sh`, `docs/verif/s136-session-hint-infers-init.md`.

## Test strategy
One end-to-end test on the real installer and hook in a throwaway home (the hook's printed line is the contract). It fails on the mutated branch, passes on `main`. Budget: 1 of 25. No visual check.

## Done when
One commit on the story branch, full suite green, review with no open critical, landed on `main` through a pull request; #94 closes.
