---
validated: yes
---
# Plan — s52-qa-wiring

Branch `story/s52-qa-wiring`. Read `docs/research/s52-qa-wiring.md` first; this plan builds on it without repeating it.

Track: full — the story is rated 3, above `Flow threshold: 2`; none of the five full-track signals is present (no migration, screen, authorization, API contract or dependency). The research's blocking question (who commits `docs/qa/<id>/`) was settled by the story revision 9ab575a: `/po-qa` gets Bash for that one commit, and `tests/qa.test.sh` joined `Owns`. ADR-0029 records the choice and the options turned down. Plan validated autonomously: no human reviewed it.

## Story
Bind the QA report to the code, commit it with the story, and make the review require it, so that a story with a screen cannot ship without proof its screens work. A story without a screen, or a project with `QA stage: —`, sees no difference.

- `rules_list_qa_in_the_story_cycle` — Law 1's per-story table places `/po-qa` between Execute and Review, for a story with a screen when `QA stage` is `screens`.
- `po_gate_qa_current` — `po-gate qa-current <id>` passes only when `docs/qa/<id>/` holds a report with `QA status: complete` whose `Tree:` matches the code outside `docs/`. A `blocked` report fails.
- `po_qa_commits_its_evidence` — `/po-qa` gets Bash for one use: commit `docs/qa/<id>/` alone on `story/<id>` once the report is written; still no Write nor Edit; its description no longer says it cannot run a shell; Law 6 names this commit next to the implementer's.
- `review_requires_a_current_qa_report` — for a story with a screen under `QA stage: screens`, the reviewer runs `po-gate qa-current` in step 1 of `review-antihallu`, next to `verif-current`; a failure blocks the review; a verified, unfixed QA finding becomes a finding. The reviewer declares `QA stage` in `Reads settings:`.
- `implementer_hands_the_screen_to_qa` — the implementer's "open it in a browser" instruction points to the QA stage when `QA stage` is `screens`, and stays as it is otherwise.

## Tasks
1. [x] **Gate `qa-current`** in `method/hooks/po-gate.sh`. Add `qa_current()` right after `verif_current` (`:51-62`), same shape: report `"$(top)/docs/qa/$1/report.md"`; missing → `refuse "... — /po-qa $1"`; the **last** line starting `QA status:` (as `ship_allowed` reads its verdict, `:42`) must match `^QA status:[[:space:]]*complete[[:space:]]*$`, so a template placeholder or a quoted earlier status cannot open it; `first_hash 'Tree'` (`:31`) non-empty; `tree_exists` (`:33`); `code_matches` (`:36`). Every refusal names `/po-qa <id>`. Add `qa-current)     qa_current "${2:?story id required}" ;;` to the `case` (`:319-326`) and a usage line `po-gate qa-current <id>` to the header (`:4-13`). The function reads no setting (ADR-0029).
   Test that fails if wrong: `test_po_gate_qa_current` and `test_qa_current_reads_the_last_status` in `tests/qa-gate.test.sh` (task 7).
2. [x] **`/po-qa` commits its evidence** — `method/commands/po-qa.md`.
   - Frontmatter: add `  - Bash` to `allowed-tools` (keep Read, Glob, Grep, Agent; no Write, no Edit). Rewrite the description so it no longer contains "cannot edit files or run a shell" (`bin/po-lint:142-146` would flag Bash otherwise): e.g. "…walks them in a browser and reports with captures, then commits that evidence alone. This command cannot edit files; its shell serves that one commit."
   - Body `:16`: replace "This command has no Write, Edit or Bash tool." with a sentence saying it has no Write or Edit, and that Bash serves exactly one use, the commit below; any other shell command is out of bounds. Keep `:16`'s remaining sentences and `:36` verbatim ("This command never writes a report: when the agent stops, there is none." is pinned by `tests/qa.test.sh:47`).
   - New section `## The evidence commit` between `## Delegation` and `## Report`, **not** named Checks/Preconditions (the fail-closed lint scans those, `bin/po-lint` `/^## (Checks|Preconditions|Step 0)/`): only when `docs/qa/<id>/report.md` exists in the worktree and holds a `QA status:` line (complete **or** blocked — a blocked walk is evidence too); confirm `git -C <path> rev-parse --abbrev-ref HEAD` prints `story/<id>`, otherwise stop without committing; then `git -C <path> add -- docs/qa/<id>/` and `git -C <path> commit -m "<id>: QA evidence" -- docs/qa/<id>/`. The pathspec keeps any other staged or modified file out of the commit. No report → nothing to commit, say so. Never `--no-verify` (the pre-commit's secret scan applies; a docs-only commit passes the plan check, `po-gate.sh:156-158`). Report the commit hash in `## Report`.
   - `Reads settings:` stays `Worktree root`, `Dev`: the command still does not read `QA stage` (research, s51 kept it runnable by hand).
   Test: `test_po_qa_commits_its_evidence` (task 7); `tests/lint.test.sh` mutants stay one-breach, which needs the real tree lint-clean.
3. [x] **Update `tests/qa.test.sh:49`**: `lacks_tool "$PO_QA" Bash` → `lacks_tool "$PO_QA" Edit` (story note: the clause changed with the text). Line 48 (`Write`) and the rest stay.
4. [x] **Rules** — `method/AGENTS.md`, adding text and never rewording a pinned phrase:
   - Law 1 per-story table (`:36-37`): new row between Execute and Review — `| QA (stories with a screen, when \`QA stage\` is \`screens\`) | \`/po-qa\` | \`docs/qa/<id>/\`, report and captures, committed alone |`.
   - Law 3 (`:58-64`): row `| QA current | the last \`QA status:\` line of \`docs/qa/<id>/report.md\` says \`complete\` **and** its \`Tree:\` matches the committed code outside \`docs/\` | the review of a story with a screen, when \`QA stage\` is \`screens\` |`; "checks all three" → "checks all four" (no test pins it).
   - Law 4 (`:79`): add the QA evidence (`docs/qa/<id>/`) between the walk and `/po-qa`'s commit to the list, keeping "legitimately holds uncommitted work under `docs/`" and "the design of a story with a screen (`docs/designs/<id>/`)" intact (`tests/structure.test.sh:59`, `tests/wiring.test.sh:82`).
   - Law 6: `:90` add "QA evidence (`docs/qa/<id>/`)" to what travels on `story/<id>`; `:93` after the implementer sentence, add "`/po-qa` commits `docs/qa/<id>/` alone, in a commit of its own, once its report is written."
   - Do not touch `:40` (`/po-flow` sentence, `tests/flow.test.sh:29`) nor the fleet, framing and "Installed files" text.
   Test: `test_rules_list_qa_in_the_story_cycle`, and the Law 6 clause inside `test_po_qa_commits_its_evidence`.
5. [x] **Reviewer wiring** — `method/agents/reviewer.md`, `method/skills/review-antihallu/SKILL.md`, `method/templates/review.md`.
   - `reviewer.md:13`: add `` `QA stage` `` to `Reads settings:` (it exists in `method/templates/agents-local.md:21,49`). `:18` Inputs: for a story with a screen when `QA stage` is `screens`, also `docs/qa/<id>/report.md` and its captures.
   - `SKILL.md:18`: add `docs/qa/<id>/` to the story's own pipeline evidence in scope by construction.
   - `SKILL.md` step 1 (`:24-28`): a bullet after the record bullets, inside step 1 (before `**2.`): "For a story with a screen, when `QA stage` is `screens`: run `po-gate qa-current <id>` as well. It fails — no report, `QA status: blocked`, or a `Tree:` the code has moved away from — → the review is blocked, the gate's message as `Failure cause:` and `/po-qa <id>` as `Next action:`. It passes → the code is the one walked, so each **verified** finding of the report is still open and becomes a finding of this review, graded on this skill's scale; probable and unverified ones go to `## Not verified` unless you confirm them. With `QA stage: —`, or no screen, there is no QA to require." Keep `**1. Reuse what is already proven.**` and the six-step count (`tests/review.test.sh` counts `^\*\*[1-6]\. `).
   - `review.md` under `## Evidence reused` (`:22-23`), after the `verif-current` box, never above `## Ownership` (`tests/ownership.test.sh:73-76`): `- [ ] \`po-gate qa-current <id>\` (screen, \`QA stage: screens\`) → <passes, verified QA findings carried to Findings | fails → review blocked | not required: no screen or \`QA stage: —\`>`.
   Test: `test_review_requires_a_current_qa_report`.
6. [x] **Implementer hand-off** — `method/agents/implementer.md`. `:17` add `` `QA stage` `` to `Reads settings:`. `:37`: keep the bold sentence "**If a task produces a screen, open it in a browser before you finish**" and its reason word for word as the `QA stage: —` branch, and add: when `QA stage` is `screens`, the walk of the screen is the QA stage's (`/po-qa`, after your commit, against the committed tree): do not stand in for it, and name in your final message the screens it should walk. Fix runs are unchanged (`:24`): `docs/qa/<id>/` is committed by `/po-qa`, so it is not expected uncommitted work.
   Test: `test_implementer_hands_the_screen_to_qa`.
7. [x] **`tests/qa-gate.test.sh`** (new, in `Owns`), shape of `tests/gate.test.sh` (`GATE="$METHOD/hooks/po-gate.sh"`, `scratch_repo`, `passes`), one function per criterion plus two gate edge tests — see Test strategy. Then the full suite once (`bash tests/run.sh`, `Full suite: execute-end`) and `bash bin/po-lint` clean; record both in `docs/verif/s52-qa-wiring.md`.

## Run interdicts
- Empty diff on `method/hooks/po-bounds.sh`, `tests/bounds.test.sh`, `method/agents/qa.md`, `method/templates/qa.md`, `method/commands/po-ship.md`, `method/commands/po-review.md`, `method/templates/agents-local.md`: the qa agent and its hook stay as s51 shipped them (ADR-0026, ADR-0029).
- Empty diff on `.claude/`, `.polype/` and the root `AGENTS.md`: installed copies, refreshed by a separate commit after ship.
- Empty diff on `method/commands/po-orchestrator.md`, `po-drive.md`, `po-status.md`, `po-help.md`, `README.md`: that wiring is s57's.
- `/po-qa` frontmatter declares no Write and no Edit; its new shell text names only `git -C <path> rev-parse`, `add -- docs/qa/<id>/` and `commit … -- docs/qa/<id>/`.
- `qa_current` reads no setting; the `QA stage` condition lives in the reviewer and the skill only.
- No pinned phrase of `method/AGENTS.md` reworded (list in task 4 and research Traps); no existing test changed except `tests/qa.test.sh:49`.
- The six-step numbering of `review-antihallu` stays six (`tests/review.test.sh`).

## The pivot
The QA report's `Tree:` (taken by `git rev-parse 'story/<id>^{tree}'`, `method/agents/qa.md:40`) is compared by `code_matches` exactly like `Reviewed tree:`, and `/po-qa`'s docs-only commit leaves that comparison green. Ways it could be wrong:
- The pre-commit hook could refuse `/po-qa`'s commit: check `pre_commit` (`po-gate.sh:150-160`) — docs-only paths skip the plan check; the secret scan reads binary captures as "Binary files differ" lines, which match no pattern. The reviewer can replay it in a scratch repo with a PNG under `docs/`.
- Reading the last `QA status:` line instead of any line: a report quoting `QA status: complete` before its final `blocked` must fail — `test_qa_current_reads_the_last_status`.
- Making the requirement depend on `QA stage` in the reviewer rather than in the gate: compare with the story note "un projet avec `QA stage: —` ne voit aucune différence" and ADR-0029.

## Files touched
`method/hooks/po-gate.sh`, `method/commands/po-qa.md`, `method/AGENTS.md`, `method/agents/reviewer.md`, `method/agents/implementer.md`, `method/skills/review-antihallu/SKILL.md`, `method/templates/review.md`, `tests/qa.test.sh`, `tests/qa-gate.test.sh` (new); pipeline evidence `docs/research/s52-qa-wiring.md`, `docs/plans/s52-qa-wiring.md`, `docs/verif/s52-qa-wiring.md`, `docs/decisions/ADR-0029-po-qa-committe-les-preuves-qa.md` (written by the planner, reserved number; not in `Owns`, as an ADR from `/po-plan` never is — the reviewer may report it minor under the "rule of `AGENTS.md`" case).

## Test strategy
Seven new tests in `tests/qa-gate.test.sh`, one line changed in `tests/qa.test.sh`; well within `Test budget: 25`. Each names the rule whose removal turns it red.

Behaviour (script run on a throwaway repo — the one layer where the gate lives):
- `test_po_gate_qa_current` — sandbox with `src/app.txt`; helper `qa_report <status>` writes `docs/qa/s01-a/report.md` ending `Tree: $(git rev-parse 'HEAD^{tree}')` then `QA status: <status>` and commits it. Asserts: `complete` on the current code passes; `blocked` fails; no report fails; a code commit after the report fails and the refusal names `/po-qa s01-a`; a docs-only commit after it (e.g. a capture file under `docs/qa/s01-a/`) still passes.
- `test_qa_current_reads_the_last_status` — a report holding `QA status: complete` then a final `QA status: blocked` fails; `QA status: complete, mostly` fails.
- `test_qa_current_needs_a_full_tree_hash` — no `Tree:`, a 12-hex abbreviation, and 40 `f`s all fail.

Text clauses (exact phrases, the repository's convention):
- `test_rules_list_qa_in_the_story_cycle` — in Law 1's `### Per story` table, the `/po-qa` row sits after the `/po-execute` row and before the `/po-review` row, and names `QA stage` and `screens`.
- `test_po_qa_commits_its_evidence` — `needs_tool Bash`, `lacks_tool Write`, `lacks_tool Edit` on `po-qa.md`; its frontmatter does not contain `run a shell`; it contains `commit -m "<id>: QA evidence" -- docs/qa/<id>/`; `method/AGENTS.md` contains "`/po-qa` commits `docs/qa/<id>/` alone".
- `test_review_requires_a_current_qa_report` — `settings_read_by reviewer.md` lists `QA stage`; in `SKILL.md`, `po-gate qa-current <id>` appears between the `**1.` and `**2.` lines; the skill says the failure blocks the review and that each **verified** finding becomes a finding; `docs/qa/<id>/` is in the evidence-in-scope sentence; `review.md`'s `## Evidence reused` section holds `po-gate qa-current <id>`.
- `test_implementer_hands_the_screen_to_qa` — `settings_read_by implementer.md` lists `QA stage`; it still contains the bold browser sentence; it contains `/po-qa` and `` `QA stage` is `screens` ``.

Changed: `tests/qa.test.sh` `test_qa_stops_without_a_browser_or_a_dev_command` checks `lacks_tool Edit` instead of `lacks_tool Bash` (the story changes that clause).

Visual checks: none — no screen.

## Done when
All tasks ticked; `bash tests/run.sh` green once at the end and `bash bin/po-lint` clean, both recorded in `docs/verif/s52-qa-wiring.md` with `Tree:` and `Verification status: complete`; one commit on `story/s52-qa-wiring` with the research, this plan, ADR-0029, the record and the code; a review with no open critical finding; squash on `main` by `/po-ship`.
