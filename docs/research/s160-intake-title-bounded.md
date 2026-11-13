# Research — s160-intake-title-bounded

[Story](../stories.md)

## Structuring facts
- **False assumption (criterion `unreadable_review_exits_2`)**: today an unreadable review already exits **2**, not 1, but with the wrong message. `grep -qE '^([-*] )?Ship allowed:'` (`method/hooks/po-gate.sh:104`) fails on the unreadable file and its `||` calls `shape_unreadable` with "the review has no verdict block" (`:105`), so the person is told the review is malformed. The path issue #134 describes (awk fatal exit 2 read as "no `## Findings`", then `refuse` → exit 1, `:123`, `:127`) is still in the code but is now reachable only if the file turns unreadable between the `grep` and the `awk`. The criterion stays right in its outcome; what changes is the message, and the awk code map. The story text "et non en 1" describes #134, not today's code.
- Root cause, defect #197 (length): the title is `<label>: ` + the fingerprint (`po-intake.sh:127`), and the fingerprint is the rest of the first failing line, unbounded (`:116`, `:120`); only trailing blanks are trimmed (`:139`). A 400-character `FAILED` line gave a 446-character title, the stub rejecting > 256 like GitHub made `gh issue create` fail, and `not_filed` ran (`:186`).
- Root cause, defect #197 (stability): the `FAILED` branch keeps everything after `FAILED ` (`po-intake.sh:116`), assertion message included; two runs differing only in `assert 41`/`assert 42` gave two titles, and dedup is an exact compare of titles (`:167-168`), so the second run cannot match.
- Root cause, defect #134 (message): `po-gate.sh:103-105` checks `-f` but never `-r`, so a read failure is first seen by `grep` and reported as a missing verdict block.
- The repository already cuts a title at 80 characters, character-safe: `LC_ALL=C.UTF-8 sed -E '…; s/^(.{80}).*/\1/; s/ +$//'` (`method/commands/po-ship.md:90`, reason `:92`). Same rule, applied in the script.

## Diagnostic
Reproduced on the worktree's code (403bc2c), in a throwaway repository under `/tmp`, `gh` a stub on PATH that rejects titles over 256 characters, `Issue tracker: github`:
- `po-intake --label nightly -- "echo 'FAILED tests/t.py::test_a - AssertionError: <400 x>'; exit 1"` → stub logged `TITLE(446)`, stderr `po-intake: gh issue create failed — nothing filed; the report follows`.
- Same check with `assert 41 == 7` then `assert 42 == 7` → two distinct titles `nightly: tests/t.py::test_a - assert 4x == 7`.
- `po-gate findings-shape s1-x` on a mode-000 review (uid 1000) → `grep: …: Permission non accordée`, `po-gate: cannot check the findings of s1-x: the review has no verdict block (no 'Ship allowed:' line)`, exit 2. Same file at 644 → exit 0.

Hypotheses:
1. *GitHub refuses the title by length* — refuted if a 446-character title went through the stub's 256 limit or if nothing bounds the title in the script. Kept: no cut anywhere between `:111` and `:183`; the reproduction fails at `gh issue create`.
2. *The varying message changes the title* — refuted if the fingerprint stopped before ` - `. Kept: `:116` keeps the whole rest; reproduction shows two titles.
3. *An unreadable review exits 1 (issue #134)* — refuted by any exit other than 1. Discarded: it exits 2 via `:104-105`; the message is the defect left.

## Story
`po-intake` must always file its issue whatever the failing line holds: the title `<label>: <fingerprint>` is at most 80 characters, cut without splitting a multibyte character (a 400-character line is filed, not `not_filed`); for `FAILED <path>::<test> - <message>` the fingerprint stops before ` - `, so a second run differing only by its message comments the first issue; TAP, cargo, `tests/run.sh` and the exit-code fallback keep their title when it fits in 80; `po-gate findings-shape` on an existing unreadable review exits 2 with a message saying so (ADR-0096).

## Current code
- `method/hooks/po-intake.sh:111-123` — awk over the scrubbed capture: first line matching `^not ok N `, `^FAILED `, `^test .+ ... FAILED$`, `^  FAIL  ` gives the fingerprint, trimmed; none → the exit code.
- `:125-139` — `title.raw` = label + fingerprint, scrubbed again with the body (`:135`) because the label may hold a secret, then the first line, trailing blanks trimmed, written without newline to `$d/title` (`:139`).
- `$d/title` is read by: the dedup compare `:167-168` (github), `gh issue create --title "$(cat "$d/title")"` `:183`, the taskwarrior compare `:208` and `task add` `:218`, and `report()` `:141` (`cat title; echo; echo; cat body`).
- `method/hooks/po-gate.sh:98-132` — `findings_shape`: `-f` check `:103`, grep for a verdict `:104`, awk exit codes 0 kept / 1 refused / 2 no `## Findings` (`:97`, `:123-124`); rc 2 → `refuse` (exit 1 at dispatch, `:127`); any rc other than 0, 1, 2 → `shape_unreadable` exit 2 (`:129`). gawk and mawk exit 2 on a fatal read error, which collides with the "no Findings" code.
- `docs/harnais.md:15` — describes the title and the fingerprint forms, nothing about length or the pytest message.

## Attachment points
- Fingerprint: the `FAILED` branch, `po-intake.sh:116`.
- Cut: replace the single-line extraction `po-intake.sh:139`, **after** the scrub of `:135`.
- `po-gate.sh:103-105`: a `-r` check between `-f` and the grep; awk "no Findings" code `2 → 3` at `:123` and `:127`, its comment `:97`; header `:17-19`.
- `docs/harnais.md:15`.

## Verified interfaces
- `shape_unreadable <id> <message>` → stderr `po-gate: cannot check the findings of <id>: <message>`, exit 2 (`po-gate.sh:98`).
- `refuse` returns 1 (`po-gate.sh:40`); the dispatcher `:671` passes it through as the script's exit.
- Locales here: `C.utf8` present (`locale -a`); awk is gawk 5.4.1.
- `po-gate oracle-intact` checks each oracle file's sum, never a test per criterion (`po-gate.sh:594-630`); a `—` table is admitted (`:611-612`). The gate thus admits a criterion with no test (M20 rule) — not needed here, all four criteria are case 1.
- `/po-intake` reads titles as `<label>: <fingerprint>` (`method/commands/po-intake.md:47`): the shape is kept, only the length changes.

## Traps
- **Order of cut and scrub.** Cutting before `scrub` (`:135`) could leave half a token that `po-gate redact` no longer recognises, and file it. The cut runs on the scrubbed first line.
- **Trailing space after the cut**: GitHub trims titles; a kept space breaks the exact compare `:168` on the next run (`po-ship.md:92` gives the same reason).
- **Newline**: `$d/title` is written without a trailing newline today; `report()` adds its own blank lines. `$(cat …)` and the awk compare tolerate one either way, but `report` would print an extra blank line.
- **Locale**: `LC_ALL=C.UTF-8` missing on the host → sed counts bytes and may split a character (same residual as `po-ship`). Invalid UTF-8 in the line → `.` stops matching at the bad byte and `.{80}` may not cut; see Open questions.
- **TAP form `not ok 1 - desc`**: its fingerprint is `- desc` today (`:115`); the ` - ` cut must stay inside the `FAILED` branch or this title changes (criterion 3).
- Tests that run and pin these scripts: `tests/failing-check-files-an-issue.oracle.test.sh` (s151 oracle — its title table `:117-123` must stay green, never edited), `tests/failing-check-files-an-issue.test.sh`, `tests/review-findings-shape.test.sh` (`test_other_gate_failures_stop` `:128-143`: no id and missing review exit 2). No test pins the messages or comments changed here (grep of `tests/`).
- M20 rule: a story that adds words to a `method/` file removes at least as many from it. `wc -w` on main: `po-intake.sh` 1623, `po-gate.sh` 5767.
- Mode-000 files stay readable to root: the oracle test of criterion 4 cannot assert under uid 0.
- No migration, no dependency, no ADR: ADR-0096 already says a failed read exits 2.

## Open questions
- Invalid UTF-8 inside the first 80 characters: should the title fall back to something bounded (the plan keeps po-ship's recipe and does not cover it; a check's output with invalid bytes in its failing line seems rare)?
- A pytest parametrised id holding ` - ` (`test_x[a - b]`) loses its tail too: the criterion says "before ` - `" and the plan takes the first one.

## Complexity
Story: 2 → after reading: 2. Two short edits in two scripts, one doc line, a ready recipe to reuse; the risk is ordering (scrub first) and keeping the s151 titles.

## Split
—
