---
validated: yes
---
# Plan — s160-intake-title-bounded

[Story](../stories.md) · [Research](../research/s160-intake-title-bounded.md)

Branch `story/s160-intake-title-bounded`. Read `docs/research/s160-intake-title-bounded.md` first; this plan builds on it without repeating it.

## Story
Fixes #197 and #134. `po-intake` files its issue whatever the failing line holds:
- `title_is_cut_at_80_characters` — the title `<label>: <fingerprint>` is at most 80 characters, cut without splitting a multibyte character; a 400-character failing line is filed, not `not_filed`.
- `fingerprint_drops_the_assertion_message` — for `FAILED <path>::<test> - <message>`, the fingerprint stops before ` - `: two runs differing only by the message give one title, and the second comments the first issue.
- `existing_fingerprints_unchanged` — TAP, cargo, `tests/run.sh` and the exit-code fallback give the same title as before while it fits in 80 characters.
- `unreadable_review_exits_2` — `po-gate findings-shape` on a review that exists but cannot be read exits 2 with a message that says so, not as a malformed review (ADR-0096).

Correction to the story (research, first fact): today that review already exits 2, through the grep at `po-gate.sh:104`, but reports "no verdict block"; "et non en 1" describes issue #134's path, now reachable only by a race. The criterion's outcome stands; the fix is the message and the awk exit map.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| 80-character, character-safe cut of the title | Already in this repository: the `LC_ALL=C.UTF-8 sed -E 's/^(.{80}).*/\1/; s/ +$//'` recipe of `method/commands/po-ship.md:90` (reason `:92`) | — (first rung) |
| Fingerprint stops before ` - ` | Already in this repository: one `sub()` inside the existing fingerprint awk, `po-intake.sh:116` | — |
| Readable check on the review | Already in this repository: `shape_unreadable` (`po-gate.sh:98`) with a `-r` test, as `redact` does (`po-gate.sh:276`) | — |
| gh stub in the oracle file | Copied in shape from `tests/failing-check-files-an-issue.oracle.test.sh:23-66` | Sourcing that file would import its `test_` functions into this one and run them twice |

## Acceptance tests
Written by the planner before any code. All four criteria fall in **case 1** of the M20 rule (a script already reads what the criterion fixes: the title `po-intake` passes to `gh`, the exit code and stderr of `po-gate`), so each has one oracle test on that behaviour and no phrase test. No criterion is case 2 or case 3; nothing goes to `po-eval`. A throwaway prototype of tasks 1-3 outside the worktree made all four pass, then was deleted; on the unchanged scripts three fail and `existing_fingerprints_unchanged` passes, as a regression guard should.

| Oracle file | cksum |
| --- | --- |
| `tests/intake-title-bounded.oracle.test.sh` | `1150097721 5270` |

| Criterion | Test |
| --- | --- |
| `title_is_cut_at_80_characters` | `test_title_is_cut_at_80_characters` — 10 ASCII + 390 `é` test name → title exactly `nightly: ` + 10 `a` + 61 `é`; an 80th character that is a space is trimmed |
| `fingerprint_drops_the_assertion_message` | `test_fingerprint_drops_the_assertion_message` — title `nightly: tests/test_a.py::test_b`; second run with another message → `gh issue comment 101`, no create |
| `existing_fingerprints_unchanged` | `test_existing_fingerprints_unchanged` — TAP, TAP `not ok 3 - …` (keeps its `- `), pytest without message, cargo, `tests/run.sh`, exit code, and an exactly-80-character title, each unchanged |
| `unreadable_review_exits_2` | `test_unreadable_review_exits_2` — mode-000 review → exit 2, stderr holds `cannot be read`, neither `no verdict block` nor `## Findings`; returns without asserting when run as root |

## Tasks
1. [x] **Fingerprint** — in the `FAILED` branch of the fingerprint awk (`method/hooks/po-intake.sh:116`), drop everything from the first ` - ` on: `f = substr(s, 8); sub(/ - .*/, "", f)`. The other branches (`:115`, `:117`, `:118`) are untouched. Tests: `test_fingerprint_drops_the_assertion_message`, and `test_existing_fingerprints_unchanged` (TAP `- ` row) fails if the cut leaks into another branch.
2. [x] **Cut** — replace the title extraction `po-intake.sh:139` so `$d/title` is: first line of `$d/title.lines`, trailing blanks trimmed, then cut to its first 80 characters under `LC_ALL=C.UTF-8` with the `po-ship.md:90` recipe, then a trailing space trimmed; written without a trailing newline, as today (`report()` `:141` adds its own). It stays **after** the scrub at `:135`. Both trackers read `$d/title`, so both get the bound. Tests: `test_title_is_cut_at_80_characters`, and the exactly-80 row of `test_existing_fingerprints_unchanged` (fails on a cut at 79 or a byte cut).
3. [x] **Unreadable review** — in `findings_shape` (`method/hooks/po-gate.sh:103`), after the `-f` check, add `[ -r "$review" ] || shape_unreadable "$1" "$rel cannot be read"`. Move the awk's "no `## Findings`" exit from 2 to 3 (`:123`, `:127`, comment `:97`) so awk's own fatal exit 2 falls to `shape_unreadable` at `:129` (issue #134's path). Header `:17-19`: name the unreadable file among the exit-2 cases. Test: `test_unreadable_review_exits_2`; `tests/review-findings-shape.test.sh` (missing `## Findings` still refused, `:49-51`) guards the 2 → 3 move.
4. [x] **Words** — in each of `po-intake.sh` and `po-gate.sh`, end with `wc -w` not above main (1623 and 5767): trim header or comment words that restate the code or `docs/harnais.md` (e.g. `po-intake.sh:2-11`, `po-gate.sh:94-97`). Check: `git show main:<file> | wc -w` against `wc -w <file>`, written in the verification record.
5. [x] **Doc** — `docs/harnais.md:15`: the title is cut at its first 80 characters, a trailing space trimmed; the `FAILED …` fingerprint stops before ` - `, so a changing assertion message keeps one issue. French, a sentence or two, no other line touched. Visual check only (no phrase test: no script reads it).
6. [x] **Run** — focused: `bash tests/run.sh intake-title-bounded.oracle.test.sh failing-check-files-an-issue.oracle.test.sh failing-check-files-an-issue.test.sh review-findings-shape.test.sh`; then the full suite once through `po-run --story s160-intake-title-bounded --label test -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- `tests/intake-title-bounded.oracle.test.sh` ends with cksum `1150097721 5270`, or each change is logged under `## Oracle changes` of the record.
- Empty diff on `tests/failing-check-files-an-issue.oracle.test.sh`, `tests/failing-check-files-an-issue.test.sh`, `tests/review-findings-shape.test.sh` (other stories' tests, kept green unchanged).
- Empty diff in `po-gate.sh` outside `findings_shape`, its comment block `:94-98` and header `:17-19`: in particular `redact`, `SECRET_PATTERNS` and the scrub path are not touched (story note; D6 of `docs/a-trancher.md` waits for the owner).
- `po-intake.sh`: the `scrub` function `:82-104` and its calls `:106`, `:135` are unchanged; the cut never runs before the scrub.
- No file outside `Owns` plus `docs/research/`, `docs/plans/`, `docs/verif/` of this story; no `.claude/` or `.polype/` file (installed copies); no `tests/intake-title-bounded.test.sh` unless it holds a test.
- `wc -w` of `method/hooks/po-intake.sh` ≤ 1623 and of `method/hooks/po-gate.sh` ≤ 5767.

## The pivot
The title is bounded **after** the scrub, by the same `C.UTF-8` sed recipe `/po-ship` uses, and the ` - ` cut lives only in the `FAILED` branch. Ways it could be wrong:
- The cut placed before `scrub` would file half a secret that `redact` no longer matches — compare the order of `:135` and the cut.
- A host without `C.UTF-8` or a line with invalid UTF-8: sed falls back to bytes or does not cut. Accepted as `/po-ship` accepts it (`po-ship.md:92`); the research leaves it as an open question, not covered by a test.
- Taking the first ` - ` also cuts a parametrised id holding ` - `; the story's wording asks for it, and the title stays stable, which is the point.

## Files touched
- `method/hooks/po-intake.sh`, `method/hooks/po-gate.sh`, `docs/harnais.md`
- `tests/intake-title-bounded.oracle.test.sh` (written by the planner)
- `docs/research/s160-intake-title-bounded.md`, `docs/plans/s160-intake-title-bounded.md`, `docs/verif/s160-intake-title-bounded.md`

## Test strategy
Automated, 4 tests within `Test budget` (25), all in the oracle, all at the script layer (the only layer here): each calls `po-intake` or `po-gate` as a caller does, with `gh` a stub logging its arguments — a hand-written stand-in for a third-party CLI, not a service the project owns, so it cannot reach a real tracker. No other test file. Bite: deleting the `sub()` of task 1 fails `fingerprint_drops…`; deleting the cut of task 2 fails `title_is_cut…`; deleting the `-r` check fails `unreadable_review…`. The awk 2 → 3 move has no deterministic test (it needs a race); the reviewer judges it by reading.
Visual: `docs/harnais.md:15` reads right.

## Done when
The four oracle tests and the full suite pass through `po-run`, the `wc -w` bounds hold, the reviewer finds no critical, and the story lands as one commit `s160-intake-title-bounded: Le titre d'une issue déposée par le harnais est borné et stable` closing #197 and #134.
