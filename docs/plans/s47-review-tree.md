---
validated: yes
---
# Plan — s47-review-tree

[Story](../stories.md) · [Research](../research/s47-review-tree.md)

Branch `story/s47-review-tree`. Read `docs/research/s47-review-tree.md` first; this plan builds on it without repeating it.

## Story
A review verdict counts only for the code it judged. The review records `Reviewed tree: <40 hex>`, the tree of `story/<id>` taken before the review starts, and `po-gate ship-allowed` refuses once the committed code outside `docs/` differs from it. Fixes defect 32.

Acceptance criteria (test names): `review_template_records_the_reviewed_tree`, `ship_allowed_fails_when_code_changed_after_review`, `ship_allowed_ignores_docs_changes_after_review`, `ship_allowed_fails_without_reviewed_tree`, `rules_and_ship_describe_the_bound_verdict`, `drive_sends_a_stale_review_back_to_review`.

## Decisions
| Question | Decision | Why |
| --- | --- | --- |
| Who takes the tree | The `reviewer` subagent, first thing, with `git -C <worktree> rev-parse 'story/<id>^{tree}'`; `/po-review` and `/po-drive` record it inside the verbatim answer | `/po-review` has no Bash and a test pins that (`tests/review.test.sh:38`); the reviewer has Bash (`reviewer.md:4`) |
| Compared against | `HEAD` of the directory the gate runs in, excluding `docs/`, through the same helper as `verif_current` | Story note; `/po-ship` runs the gate from the worktree (`po-ship.md:18`) where `HEAD` is `story/<id>` |
| Which line when several | The **first** `Reviewed tree:` line holding exactly 40 lowercase hex | The template puts it in the header, so the review's own line comes before anything it quotes; same extraction as `Tree:` (`po-gate.sh:39`) |
| Check order in `ship_allowed` | file → last verdict `yes` → usable tree → tree exists → code matches | A `no` verdict keeps its existing message; tree problems only surface on a `yes` |
| Re-review loop number | The one `/po-review` already computes, `Fix loop:` + 1 | Changing `/po-review`'s counting is out of scope; a late commit spending one attempt is accepted and stated |
| ADR | None — ADR-0023 left unused | The mechanism is settled by `docs/references/gstack-agent-skills.md:22` and the story note; the only open choice (who captures) is forced by an existing tool restriction |

## Tasks
1. [x] **Shared tree comparison in `method/hooks/po-gate.sh`.** Extract from `verif_current` (`:39-44`) two helpers: one printing the first 40-hex hash of a `<label>:` line of a file (the `sed … | head -n 1` of `:39`, label as parameter), one failing unless `<tree>^{tree}` exists and `git diff --quiet "$tree" HEAD -- . ':(exclude)docs'` holds from `top()`. `verif_current` calls them and keeps its two current refusal messages and behaviour. The pathspec `':(exclude)docs'` must appear exactly once in the file afterwards. Keep the comment that explains why `docs/` is excluded, on the helper. Tests that fail if wrong: the existing `test_verif_current_*` (five) in `tests/gate.test.sh`.
2. [x] **`ship_allowed` binds the verdict to the tree.** After the existing last-verdict check (`:28-30`, unchanged), read `Reviewed tree:` with the helper; empty → `refuse "the review of $1 has no usable 'Reviewed tree:' hash — /po-review $1"`; missing tree object or code differs → refuse with a message that says the code changed after the review and ends with `/po-review $1`. Update the header lines `:5` (what `ship-allowed` checks now) and `:9` (in CI, run it on a checkout of the story branch tip, not on a merge ref, since it compares against `HEAD`). In `tests/gate.test.sh` add a fixture helper writing a review whose first line is `Reviewed tree: $(git rev-parse 'HEAD^{tree}')` followed by the given verdict lines, and use it in `test_ship_allowed_passes_only_on_exact_line`, `test_ship_allowed_fails_on_no` and `test_ship_allowed_reads_the_last_verdict`, so each refuses for its own clause and not for a missing tree (changed because the story changes the clause they check). New tests:
   - `test_ship_allowed_fails_when_code_changed_after_review` — review on the current tree passes; commit a change to `src/app.txt`; the gate refuses and its stderr contains `/po-review s01-a`.
   - `test_ship_allowed_ignores_docs_changes_after_review` — review on the current tree, then commit a change under `docs/` only (commit the review file itself too, as `/po-ship` Step 1 does); the gate passes.
   - `test_ship_allowed_fails_without_reviewed_tree` — with `Ship allowed: yes` and the code unchanged, three cases each refused: no `Reviewed tree:` line; the real tree abbreviated to 12 hex (it resolves in git, so only the 40-hex rule rejects it); 40 hex naming no object.
3. [x] **Template line.** In `method/templates/review.md`, right after `Fix loop:` (`:6`), add `Reviewed tree: <40 hex — git rev-parse 'story/<id>^{tree}', taken before the review starts>`. The file still ends with `Max severity:` then `Ship allowed:` (`tests/review.test.sh:21-25` keeps passing).
4. [x] **Reviewer and `/po-review` carry it.** `method/agents/reviewer.md`: before reading the diff, take the tree with the command above and put it on the `Reviewed tree:` line of the answer; add in "Your answer" that a review whose tree changed while it ran (re-take it at the end) is answered as blocked. `method/commands/po-review.md:33`: the recorded file must also contain `Reviewed tree:`, and `/po-ship` refuses a verdict whose tree no longer matches the code; do not add Bash, do not change the prompt at `:30` (the driver reuses it word for word, and the reviewer's own file carries the step). New test in `tests/review.test.sh`, `test_review_template_records_the_reviewed_tree`: the template has a line starting `Reviewed tree:` placed before the `Max severity:` line, and both the template and `reviewer.md` contain `rev-parse 'story/<id>^{tree}'`; `po-review.md` contains `Reviewed tree:`.
5. [x] **Law 3, `/po-ship`, `/po-status`.** `method/AGENTS.md:62` Ship allowed row: opens when the last `Ship allowed:` line says `yes` **and** the review's `Reviewed tree:` matches the committed code outside `docs/`; `:64`, add that a review without a usable `Reviewed tree:` counts as blocked too (keep `A review without its two verdict lines counts as blocked.` verbatim). `method/commands/po-ship.md:18` manual check: keep the sentence `the **last** line starting with \`Ship allowed:\`` and add that `git diff --quiet <Reviewed tree> HEAD -- . ':(exclude)docs'` must succeed from the worktree; a review missing the line or failing it stops with the existing message naming `/po-review <id>`. `method/commands/po-status.md:29`: the review column also says whether `po-gate ship-allowed <id>` passes, a `yes` whose `Reviewed tree:` no longer matches shown as stale with next `/po-review <id>`. New test in `tests/ship.test.sh`, `test_rules_and_ship_describe_the_bound_verdict`: the Law 3 `| Ship allowed |` row of `method/AGENTS.md`, `po-ship.md` Step 0 (text between `## Step 0` and `## Step 1`) and the review bullet of `po-status.md` each contain `Reviewed tree:`; `po-ship.md` Step 0 contains `':(exclude)docs'`.
6. [x] **`/po-drive` resume table and ship sentence.** Insert above `| review whose last \`Ship allowed:\` is \`yes\` | the ship |` (`:53`) the row `| review whose last \`Ship allowed:\` is \`yes\` but \`po-gate ship-allowed <id>\` refuses its \`Reviewed tree:\` | the review stage, at loop \`Fix loop:\` + 1 |`, and one sentence after the table explaining it (the code moved after a favourable verdict; when the record is stale too, the code-stage row wins first, which is right). Rewrite `:119` so the ship check says the last `Ship allowed:` must be `yes` **and** its `Reviewed tree:` must still match the code outside `docs/`; update `tests/drive.test.sh:84` to the new phrase (story note). New test in `tests/drive.test.sh`, `test_drive_sends_a_stale_review_back_to_review`: in the `## Resuming` table, a row containing `Reviewed tree:` and naming `the review stage` exists and its index is lower than the `is \`yes\` | the ship` row's.
7. [x] **Defect and suite.** `docs/defauts.md:67` status → `corrigé par s47`. Then `bash tests/run.sh` once (Full suite: execute-end), and `bin/ks-overlap` against the gstack and agent-skills sources if available — otherwise say so in the record.

## Run interdicts
- `.polype/`, `.claude/` and the root `AGENTS.md` end with an empty diff (installed copies; `method/` is the source).
- No file outside the story's `Owns` plus `docs/research/`, `docs/plans/`, `docs/verif/` of this story changes; in particular `method/commands/po-flow.md`, `po-orchestrator.md`, `po-execute.md` and `method/skills/review-antihallu/` stay untouched.
- No review under `docs/reviews/` other than this story's own is created or edited.
- `method/commands/po-review.md` keeps its frontmatter tools unchanged (no Bash) and its prompt paragraph `:30` unchanged.
- `po-drive.md` rows `record current, review blocked…`, `review whose last \`Ship allowed:\` is \`no\`…` and the prose `:58` keep their text (quoted by `tests/drive.test.sh:202-209`, `tests/resume.test.sh`).
- `verif_current` keeps its refusal messages and behaviour; `grep -c "':(exclude)docs'" method/hooks/po-gate.sh` prints `1`.
- No existing test is changed except the three ship-allowed fixtures of `tests/gate.test.sh` and line 84 of `tests/drive.test.sh`.
- ADR-0023 is not written.

## The pivot
The gate compares `Reviewed tree:` with `HEAD` of the directory it runs in. Ways it could be wrong:
- **Run from the wrong place.** From the repository root on `main` or from a CI merge ref, `HEAD` is not the story tip and every ship is refused. Compare against `po-ship.md:18` ("from the worktree") and the new header note; `/po-drive`'s "no `cd`" rule (`po-drive.md:68`) leaves how the driver runs a gate inside a lane unspecified — pre-existing for all gates, not fixed here.
- **The hash is not the reviewed code.** The reviewer takes `story/<id>^{tree}`, i.e. committed code; uncommitted edits in the worktree are neither reviewed nor shipped, and committing them later changes the tree and reopens the review. Check that the reviewer takes it before reading and re-takes it at the end.
- **The first-line rule.** A report that quotes an older `Reviewed tree:` above its own header line would bind the verdict to the quoted tree. The template puts the line in the header, so this needs a malformed report; the reviewer should check the recorded file's header against `git rev-parse`.

## Files touched
`method/hooks/po-gate.sh`, `method/templates/review.md`, `method/agents/reviewer.md`, `method/commands/po-review.md`, `method/commands/po-ship.md`, `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/AGENTS.md`, `tests/gate.test.sh`, `tests/review.test.sh`, `tests/ship.test.sh`, `tests/drive.test.sh`, `docs/defauts.md`; plus this story's `docs/research/`, `docs/plans/`, `docs/verif/`.

## Test strategy
Six new tests, one per criterion, plus three existing fixtures adjusted: within the budget of 25.
- **Behaviour (the rule lives in `po-gate.sh`, tested by running it on scratch repos):** criteria 2, 3, 4. Bite points for the reviewer: delete the diff call in `ship_allowed` → criterion 2 fails; drop `':(exclude)docs'` from the helper → criterion 3 and `test_verif_current_ignores_docs_changes` fail; relax the 40-hex regex → the abbreviated-hash case of criterion 4 fails.
- **Method text (contains-style, exact short phrases):** criteria 1, 5, 6 — the text is the product for commands and agents; each test checks the location as well as the phrase (header vs end of template, Step 0 section, table row order).
- No visual checks. Run per task only the test file it touches; full suite once at the end.

## Done when
All six criteria have their test, `bash tests/run.sh` is green, the interdicts hold, defect 32 says `corrigé par s47`, one commit on `story/s47-review-tree` carries code, tests, research, plan and record, and the review allows the ship.
