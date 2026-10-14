---
validated: yes
---
# Plan — s120-session-and-gate-checks

[Story](../stories.md) · [Research](../research/s120-session-and-gate-checks.md)

Branch `story/s120-session-and-gate-checks`. Read `docs/research/s120-session-and-gate-checks.md` first; this plan builds on it without repeating it.

## Story
As project owner I want `po-gate` to refuse a review that has no `Review status:`, and `po-session` to flag a plan that waits for a technical choice without pushing a design system nobody needs.
- `ship_gate_needs_review_status`: `po-gate ship-allowed <id>` refuses a review whose last `Review status:` line is missing or does not say `complete`, and the message names the line. A complete review with `Ship allowed: yes` and a current `Reviewed tree:` passes as before.
- `session_flags_a_technical_choice`: under "Waiting for a human", `po-session` lists each lane whose plan holds `Technical choice: waiting for a human`, with `/po-plan <id>`.
- `design_system_only_with_a_screen`: `/po-design-system` is the next framing step only if at least one story has a screen (Law 1). Otherwise a missing design system is no step, and the framing line says `design system not needed`.

Root causes (research): `ship_allowed` never reads `Review status:` (`method/hooks/po-gate.sh:55-65`); `waiting_for_a_human` opens the plan only for `validated: yes` (`method/hooks/po-session.sh:195-198`); `framing` decides `/po-design-system` from the file's absence alone (`po-session.sh:76`, `:83`).

The research's blocking question is settled: `Owns` now holds `tests/review-tree-gate.test.sh`, `method/AGENTS.md` and `method/commands/po-ship.md` (`docs/stories.md:1855`), and this branch starts from that commit (`9404c10`).

## Decisions on the research's open questions
| Question | Decision | Why |
| --- | --- | --- |
| Which `Review status:` counts | Both must say `complete`: the status **paired with the last verdict** (the last `Review status:` since the previous `Ship allowed:` line, as the tree is paired), **and** the last `Review status:` line of the whole file | The pairing refuses an appended review that has no status of its own (an earlier block's `complete` is not borrowed). The second check is the literal wording of the criterion ("whose last `Review status:` line"): a `Review status: blocked` written after the last verdict refuses too. |
| Exact value | `complete` plus optional trailing blanks, a leading `- ` or `* ` read away, like the tree and the verdict | Same tolerance as `Ship allowed: yes` (`po-gate.sh:58-59`) and `paired_hash` (`:39`). |
| Story without a `Surface` line | Counts as "may have a screen": `/po-design-system` stays next | Law 1 says such a story has a screen when its text shows one; a shell hook cannot judge text and ADR-0054 rejects guessing. Conservative side. |
| `design system not needed` | Only when `docs/design-system.md` is missing on `Target branch`, `docs/stories.md` holds at least one story, every story has a `Surface` line, and none says `screen` | With no story, nothing can be decided: the line keeps `missing`. |
| Marker line | `- <id>: technical choice waiting for a human (docs/plans/<id>.md) → /po-plan <id>`, when the plan holds the exact line (`grep -qx`) and no `validated: yes` line | Mirrors the `/po-drive` resume row (`method/commands/po-drive.md:53`) and the root-cause `if` beside it. |

No ADR: these apply Law 1, ADR-0054 and ADR-0077 as written; nothing structural is left open.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Reading the status paired with the last verdict | already in this repository: the awk of `paired_hash` (`po-gate.sh:37-47`), split into `paired_value` (raw paired value) with `paired_hash` keeping its 40-hex check on top | No function returns a raw paired value today; copying the awk would fork the pairing rule. |
| File's last `Review status:` line | already in this repository: the `grep -E … \| tail -n 1 \| sed` idiom of the verdict (`po-gate.sh:58`) | — |
| Refusal | `refuse` (`po-gate.sh:23`) | — |
| Marker check in `po-session` | already in this repository: the root-cause `if` (`po-session.sh:195-198`), one more `if` in the same loop | — |
| Surface scan | new code: one awk over `on_target docs/stories.md`, shaped like `ready_stories`' awk (`po-session.sh:156-168`) | That awk prints id and deps for the ready list and runs after `framing`; widening its output would tangle two reports. A second small pass over the same `git show` is cheap. |
| Test helpers in `tests/session-and-gate-checks.test.sh` | `scratch_repo`, `contains`, `fail` of `tests/lib.sh`; a few local one-liners (`session_in`, `review`) modelled on `tests/project-lead.test.sh:15-36` and `tests/review-tree-gate.test.sh:19` | Test files are sourced alone by `tests/run.sh:11-17`; another file's helpers cannot be sourced without its `test_` functions. |

## Tasks
1. [x] **Gate: pair and require the review status.** In `method/hooks/po-gate.sh`:
   - Rename the awk of `paired_hash` to `paired_value label verdict_ERE file`: same pairing, prints the raw `final` value when `closed`, nothing otherwise. `paired_hash` becomes a wrapper that keeps today's 40-hex rule exactly (`:43-44`) on that value. **Trap**: the callers assign under `set -euo pipefail` (`:20`, `:61`, `:72`); `paired_hash` must still exit 0 when it prints nothing, or the script dies before `refuse` speaks.
   - In `ship_allowed`, after the verdict check (`:60`) and before the tree (`:61`): read `paired_value 'Review status' '^([-*] )?Ship allowed:'` and the file's last `^([-*] )?Review status:` line (leading bullet read away); both must match `^complete[[:space:]]*$` after the label. Otherwise `refuse "the review of $1 has no 'Review status: complete' line for its last verdict — /po-review $1"` — the message names `Review status:`.
   - Update the header (`:5-6`): ship-allowed is 0 when the last verdict says yes, the `Review status:` of that same review and the file's last one say `complete`, and its `Reviewed tree:` still matches HEAD.
   Tests that fail if wrong: `test_ship_gate_needs_review_status` (new), and `tests/qa-gate.test.sh`, `tests/run-ledger.test.sh`, `tests/review-tree-gate.test.sh` `test_other_tree_lines_read_the_same_way` for the `paired_hash` refactor.
2. [x] **Existing gate tests write a status.** The clause they check now requires it (allowed by the conventions of `AGENTS.local.md`):
   - `tests/gate.test.sh:30` `review()`: write `Review status: complete` before `Reviewed tree:`. In `test_ship_allowed_fails_without_reviewed_tree` (`:71-79`), each `printf` gets `Review status: complete` too, so the three refusals still refuse for the tree, not for the status.
   - `tests/review-tree-gate.test.sh:19-44`: add `Review status: complete\n` inside each review block that must pass **and** each block whose refusal is about something else (`:23`, `:25`, `:27`, `:33`, `:35`, `:37`, `:39`, `:41`, `:43`) — for `:23`, one status in each of the two blocks; for `:25`, the status goes in the second block (after `Ship allowed: no`), so the refusal stays about the missing tree; for `:37`/`:39`, the status unindented and unbulleted so only the tree line is malformed. Comment line 2 unchanged.
   Focused run: `bash tests/run.sh gate.test.sh review-tree-gate.test.sh qa-gate.test.sh run-ledger.test.sh`.
3. [x] **Session: flag the technical-choice marker.** In `waiting_for_a_human` (`method/hooks/po-session.sh:195-198`), add beside the root-cause `if`: when `$plan` exists, `grep -qx 'Technical choice: waiting for a human'` matches, and `grep -qx 'validated: yes'` does not → `lines+=("$id: technical choice waiting for a human (docs/plans/$id.md) → /po-plan $id")`. Test that fails if wrong: `test_session_flags_a_technical_choice`.
4. [x] **Session: design system only with a screen.** In `framing` (`po-session.sh:53-87`), when `docs/design-system.md` is missing on `Target branch` and `stories=present`: one awk over `on_target docs/stories.md` counting, among `##+ <id>` headings matching `$id_re`, the stories, those with a `^- \*\*Surface\*\*` line, and those whose value after the first colon holds the word `screen` (`(^|[^a-z])screen([^a-z]|$)`; matches both `- **Surface**: \`screen\`` and `- **Surface** : —` shapes). Stories > 0, all with a Surface, none `screen` → `ds="not needed"`. The framing line then reads `design system not needed`, and the `next` chain (`:83`) only stops at `/po-design-system` when `ds=missing`, so it falls to `none — framing done`. Read-only: no file, no lock (`:2-6`). Test that fails if wrong: `test_design_system_only_with_a_screen`; `tests/project-lead.test.sh:84`, `:99` must stay green unchanged.
5. [x] **Written rules follow the gate.**
   - `method/AGENTS.md:87` (Law 3, row Ship allowed): add that the `Review status:` of that review says `complete`. `:90`: "A review without its two verdict lines counts as blocked" gains "or without `Review status: complete`".
   - `method/commands/po-ship.md:18` (Step 0, without the hook): add that the last `Review status:` between that verdict and the previous one, and the file's last `Review status:` line, must read `Review status: complete`. Keep verbatim the phrase `between that verdict and the verdict line before it` (pinned by `tests/review-tree-gate.test.sh:62`) and the stop sentence.
   Test that fails if wrong: `test_ship_gate_needs_review_status` asserts one exact phrase in each file (task 6).
6. [x] **Acceptance tests** in the new `tests/session-and-gate-checks.test.sh` (header `# s120 — …`), one function per criterion:
   - `test_ship_gate_needs_review_status` (scratch repo with `docs/reviews`, `src/app.txt`, one commit; `T` = HEAD tree):
     - `Review status: complete` + tree + `Ship allowed: yes` → passes; same with `- Review status: complete` → passes;
     - no status line → refused, and stderr holds `Review status:`;
     - `Review status: blocked` → refused;
     - stacked: block 1 `Review status: complete`, tree, `Ship allowed: no`; block 2 tree, `Ship allowed: yes`, no status → refused;
     - `Review status: blocked` after a complete block's `Ship allowed: yes` → refused;
     - `contains` on `method/AGENTS.md` and `method/commands/po-ship.md` for the exact phrases task 5 writes.
   - `test_session_flags_a_technical_choice`: a Polype repo (settings as `tests/project-lead.test.sh:17-26`, approved brief), lane `s05-x` whose plan holds `validated: no` and the marker → the exact line `- s05-x: technical choice waiting for a human (docs/plans/s05-x.md) → /po-plan s05-x`; lane `s06-y` with the marker and `validated: yes` → no `s06-y` line.
   - `test_design_system_only_with_a_screen`: framing done but the design system (approved brief, `docs/reviews/stories.md` with `Stories ready: yes`, `docs/architecture.md`), stories `s01-a` `- **Surface**: \`command\`` and `s02-b` `- **Surface** : —` → lines `… · design system not needed` and `Framing next: none — framing done`; then `s02-b` set to `` `screen` `` → `design system missing` and `Framing next: /po-design-system`; then `s02-b` without a Surface line → `design system missing` again.
   Focused run: `bash tests/run.sh session-and-gate-checks.test.sh project-lead.test.sh short-subject-shipped.test.sh no-claude-md.test.sh`.
7. [x] **Full suite** once all tasks are done: `po-run --story s120-session-and-gate-checks --label 'Unit suite' -- 'bash tests/run.sh'`. `Typecheck` is `—`.

## Scene viewpoints
—

## Run interdicts
- `.polype/`, `.claude/` and the root `AGENTS.md` end with an empty diff (installed copies, `AGENTS.local.md` conventions).
- `tests/project-lead.test.sh`, `tests/qa-gate.test.sh`, `tests/run-ledger.test.sh`, `tests/floor-guard.test.sh` end with an empty diff and stay green.
- In `po-gate.sh`, `plan_validated`, `verif_current`, `qa_current`, `runs_cover_checks`, `pre-commit` and `floor-guard` keep their behaviour; only `paired_hash`'s body moves into `paired_value`.
- `po-session.sh` stays read-only: no write, no `git` command that takes a lock or asks a remote (`:2-6`); `test_session_hook_reports_state_read_only` proves it.
- No other `method/` file, no `docs/stories.md`, no `docs/parite-killer-saas.md` (this story implements no new parity line).
- The phrase `between that verdict and the verdict line before it` stays in `method/commands/po-ship.md`.

## The pivot
The gate's status rule: paired with the last verdict **and** read on the file's last `Review status:` line. Ways it could be wrong:
- Too strict for real reviews: compare with `method/templates/review.md:5-7`, `:58-59` (status above the tree, in the block the verdict closes) and the reviews `docs/reviews/s107…s119`, which all carry it. A `po-review` fallback review (`method/commands/po-review.md:38`) writes `Review status: blocked` — refused, which is right since it also says `Ship allowed: no`.
- The refactor breaks hash reading: `paired_hash` must print exactly what it printed before and exit 0; `review-tree-gate.test.sh`, `qa-gate.test.sh` and `run-ledger.test.sh` cover the list-item, short-hash and punctuation cases.
- The Surface scan reads a heading or a Surface line outside a story: it must only count lines under a heading whose text starts with an id (`$id_re`), as `ready_stories` does (`po-session.sh:158-162`).

## Files touched
`method/hooks/po-gate.sh`, `method/hooks/po-session.sh`, `method/AGENTS.md`, `method/commands/po-ship.md`, `tests/gate.test.sh`, `tests/review-tree-gate.test.sh`, `tests/session-and-gate-checks.test.sh` (new); `docs/research/…`, `docs/plans/…`, `docs/verif/…` of this story.

## Test strategy
- Three new tests, one per criterion, in `tests/session-and-gate-checks.test.sh`, each on a throwaway repository running the real hook (no mock): well within `Test budget: 25`.
- Each would fail if its rule were removed: without the status read, the "no status line" case passes; without the marker `if`, the exact line is absent; without the Surface scan, `design system not needed` is never printed. The `screen` and no-Surface cases catch a rule that skips the step unconditionally.
- Existing tests changed only where the clause changed (task 2); their refusals keep refusing for their own reason, not for the missing status.
- No visual check.

## Done when
Every task ticked; focused runs and the full suite green through `po-run`; the record complete; one commit `s120-session-and-gate-checks: …` by the implementer; a review with no open critical finding.
