# Research — s120-session-and-gate-checks

[Story](../stories.md)

## Structuring facts
- **False assumption: the `Owns` line is too narrow.** `tests/review-tree-gate.test.sh:24` and `:34` expect `po-gate ship-allowed` to **pass** on reviews that have no `Review status:` line. Criterion `ship_gate_needs_review_status` makes them fail, and five of the refusals in that file (`:26`, `:28`, `:36-44`) would then pass for the wrong reason. That file is not in `Owns`, and `po-bounds` refuses any Write/Edit outside the `Owns` read at the fork point (`method/hooks/po-bounds.sh:152-178`, ADR-0038). So the story as written cannot be implemented with a green suite. Fix: add `tests/review-tree-gate.test.sh` to `Owns` on `main`, then fork the lane again from that commit (or fast-forward `story/s120-…` onto it).
- Root cause 1: `ship_allowed` (`method/hooks/po-gate.sh:55-65`) reads only `Ship allowed:` and `Reviewed tree:`. `grep -c "Review status" method/hooks/po-gate.sh` → 0. When a review has a valid tree and `Ship allowed: yes` but no `Review status:`, the gate exits 0 (reproduced, see Diagnostic).
- Root cause 2: `waiting_for_a_human` (`method/hooks/po-session.sh:189-228`) reads the research, the QA report and the review of each lane. It opens the plan only to look for `validated: yes` (`:196`) and never looks for `Technical choice: waiting for a human`.
- Root cause 3: `framing` (`method/hooks/po-session.sh:76`, `:83`) decides that `/po-design-system` is next from the absence of `docs/design-system.md` alone. It never reads a `Surface` line, so a project with no screen (nautile: 35 stories, 35 `Surface` lines, `command`/`endpoint` only) still gets `Framing next: /po-design-system`.

## Diagnostic
Reproduced on the code as it stands, in a throwaway repository under `mktemp -d`, outside the worktree:
1. Review file `Reviewed tree: <HEAD tree>\nMax severity: minor\nShip allowed: yes`, no status line → `bash method/hooks/po-gate.sh ship-allowed s01-a` exits **0**.
2. A lane `s05-x` whose plan holds `validated: no` and the line `Technical choice: waiting for a human` → `po-session` prints `Waiting for a human: nothing`.
3. `CLAUDE_PROJECT_DIR=~/dev/atoll/nautile bash method/hooks/po-session.sh` (read-only by design, `po-session.sh:2-4`) prints `Framing: … design system missing` then `Framing next: /po-design-system`.

Hypotheses, one per defect:
| # | Hypothesis | Refuting observation | Result |
| --- | --- | --- | --- |
| 1a | The gate reads `Review status:` but its pattern misses the lines it should match | some read of the label in `po-gate.sh` | discarded: no such read exists (`grep -c` → 0, `:55-65`) |
| 1b | The gate never reads `Review status:` | a missing status line still gets refused | kept: repro 1 exits 0 |
| 2a | The marker is read but its line is filtered out | any read of the plan other than `validated: yes` | discarded: the only plan read is `:196` |
| 2b | Nothing reads the marker | the marker gets listed | kept: repro 2 prints `nothing` |
| 3a | `framing` reads `Surface` but parses it wrongly | any `Surface`/`screen` in `po-session.sh` | discarded: `grep -n "Surface\|screen"` → nothing |
| 3b | Only the presence of the file decides `next` | a project with no screen gets another `next` | kept: repro 3 |

## Story
As project owner I want `po-gate` to refuse a review that has no `Review status:`, and `po-session` to flag a plan that waits for a technical choice without pushing a design system nobody needs.
- `ship_gate_needs_review_status`: `po-gate ship-allowed <id>` refuses a review whose last `Review status:` line is missing or does not say `complete`, and the message names the line. A complete review with `Ship allowed: yes` and a current `Reviewed tree:` passes as before.
- `session_flags_a_technical_choice`: under "Waiting for a human", `po-session` lists each lane whose plan holds `Technical choice: waiting for a human`, with `/po-plan <id>`.
- `design_system_only_with_a_screen`: `/po-design-system` is the next framing step only if at least one story has a screen (Law 1). Otherwise a missing design system is no step, and the framing line says `design system not needed`.

## Current code
- `method/hooks/po-gate.sh:37-47` `paired_hash label verdict_ERE file`: an awk that reads away a leading `- `/`* `. It keeps the last `<label>:` value since the previous verdict line and prints it only when it is a 40-hex hash. `ship_allowed` uses it with `'Reviewed tree'` (`:61`). `qa_current` and `verif_current` use the same pairing.
- `po-gate.sh:58-60`: the verdict is the last `^([-*] )?Ship allowed:` line, which must match exactly `Ship allowed: yes` plus optional spaces. Refusals go through `refuse` (`:23`), on stderr with exit 1.
- `po-gate.sh:4-6`: the header documents `ship-allowed`. It has to change with the rule.
- `method/hooks/po-session.sh:53-87` `framing`: reads files on `Target branch` with `on_target`/`on_target_exists` (`:38-39`) and prints `Framing: scope … · design system $ds`, then `Framing next: $next`.
- `po-session.sh:156-168`: an awk over `on_target docs/stories.md` that already walks the `##+ <id>` headings and reads a `- **Depends on**/Dépend de` line in each. The `Surface` line has the same shape: `- **Surface**: \`command\`` (English) or `- **Surface** : —` (French).
- `po-session.sh:189-228` `waiting_for_a_human`: loops over `lane_order`, builds `lines+=("<id>: <reason> (<file>)")` and prints them as `- …`. Shipped stories and orphan worktrees join the same list.

## Attachment points
- Gate: `ship_allowed`, between the verdict check (`:60`) and the tree check (`:61`). Read the status with the same pairing as the tree. `paired_hash`'s awk becomes `paired_value`, which prints the raw paired value; `paired_hash` keeps its hash check on top of it, so `verif_current`/`qa_current` do not change behaviour.
- Session, marker: one more `if` in the per-lane loop of `waiting_for_a_human`, beside the root-cause one (`:195-198`). It mirrors the `/po-drive` resume row (`method/commands/po-drive.md:53`: marker "without `validated: yes`").
- Session, screen: `framing`, decided before `:77`. Scan `on_target docs/stories.md` once: does any story have a screen, and does any story lack a `Surface` line?

## Verified interfaces
- Law 1 definition (`method/AGENTS.md`, "Design and QA, by surface"): a story has a screen when its `Surface` says `screen`, or when it has no `Surface` line and its text shows a screen (ADR-0054). A shell hook cannot judge text, and ADR-0054 rejects guessing ("Deviner la plateforme… fragile").
- Template order (`method/templates/review.md:5-7`, `:58-59`): `Review status:` sits above `Reviewed tree:`, in the same block that `Ship allowed:` closes. So pairing the status with the last verdict uses the same block as the tree.
- `po-review.md:36`: the review must contain `Review status:`. Every review M9 ter wrote has it (`docs/reviews/s107…s119`). Shipped reviews s51–s106 lack it, but they are never gated again.
- `po-bounds` story base: `merge-base HEAD <main branch> [upstream]` (`po-bounds.sh:126-149`). A framing fix landed on `main` after the fork does not widen this lane until `story/s120-…` contains it.

## Traps
- `tests/gate.test.sh:30`: the helper `review()` writes no status. Every positive ship test (`:34`, `:56`, `:66`) fails until the helper writes `Review status: complete`. The three refusals of `test_ship_allowed_fails_without_reviewed_tree` (`:74-78`) would pass vacuously on the new rule: each needs the status line so that it still refuses for the tree.
- `tests/review-tree-gate.test.sh:19-44`: same issue for every `review "…"` string. See the top of this file: outside `Owns`.
- `tests/project-lead.test.sh:84`, `:99`: these assert the framing line verbatim. `:84` has stories with no `Surface` line and `:99` has no stories, so under the rule proposed below both keep `design system missing`. They must stay green unchanged.
- `tests/short-subject-shipped.test.sh` and `tests/no-claude-md.test.sh` run `po-session` but assert only the `Ready stories` and `Waiting for a human` lines. The new rule does not affect them.
- `method/AGENTS.md:87` (Law 3 row) and `method/commands/po-ship.md:18` (the check without the hook) describe `Ship allowed` without the status. Both are outside `Owns`, so the gate becomes stricter than its written rule. That is a minor for the review to log, or an `Owns` widening for the lead to decide.
- `.polype/hooks/` and `.claude/` are installed copies. Change `method/hooks/` only (`AGENTS.local.md`, Conventions).
- No migration and no dependency. `po-session` must stay read-only and fast (`po-session.sh:2-4`), and the read-only test `project-lead.test.sh:79-89` checks that.

## Open questions
- **Owns** (blocking): add `tests/review-tree-gate.test.sh`. Should `method/AGENTS.md` and `method/commands/po-ship.md` be added too, so the written rule follows the gate? Neither is owned by s121 or s122.
- Status pairing: proposed rule = the `Review status:` paired with the last verdict, like the tree. It must equal `complete` exactly (plus spaces), like `Ship allowed: yes`. A review appended without its own status line then refuses, even if an earlier block had one. A status line written *after* the last verdict is ignored, as a trailing `Reviewed tree:` is today. Keep that, or also refuse when the file's very last `Review status:` is not `complete`?
- No `Surface` line: proposed = such a story *may* have a screen, so `/po-design-system` stays the next step (the conservative side). With no `docs/stories.md`, nothing can be decided and the line keeps `missing`. `design system not needed` only when stories exist, every story has a `Surface` line, and none says `screen`. A screen story wrongly counted as screenless would still be stopped later, at `/po-design` (`po-drive.md:104`), but the conservative reading avoids that detour.
- Proposed marker line: `- <id>: technical choice waiting for a human (docs/plans/<id>.md) → /po-plan <id>`, printed when the plan holds the marker as an exact line (`grep -qx`) and not `validated: yes`.

## Complexity
Story 2 → 2. The change is three small blocks in two scripts plus their tests. The `Owns` gap makes no more work, but the story can only proceed once its framing is corrected.

## Split
Not needed.
