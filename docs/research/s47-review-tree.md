# Research — s47-review-tree

[Story](../stories.md)

## Structuring facts
- **Assumption corrected (who writes the line):** `/po-review` cannot read a tree: it has no Bash (`method/commands/po-review.md:4-9`), and `tests/review.test.sh:38` pins `lacks_tool "$CMD" Bash`. The hash can only come from the `reviewer` subagent, which has Bash (`method/agents/reviewer.md:4`), and reaches the file because `/po-review` and `/po-drive` record its answer whole (`po-review.md:33`, `po-drive.md:110`).
- `ship_allowed` reads only the last `Ship allowed:` line (`method/hooks/po-gate.sh:24-31`); `verif_current` already holds the tree comparison the story wants shared: `git diff --quiet "$tree" HEAD -- . ':(exclude)docs'` (`po-gate.sh:43`), after a 40-hex extraction (`:39`) and an existence check (`:41`).
- The comparison is against `HEAD` of the directory `po-gate` runs in (`top()`, `po-gate.sh:12`). `/po-ship` runs it "from the worktree" (`po-ship.md:18`), where `HEAD` is `story/<id>` — so it works there; anywhere else (repo root on `main`, a CI merge ref) it compares against the wrong commit.
- Existing gate fixtures write reviews with no tree line (`tests/gate.test.sh:31,33,39,47`): the positive one (`:31-32`) will fail once the tree is required, and must be updated with the clause.
- `docs/` is excluded from the comparison, so `/po-ship` Step 1 committing `docs/reviews/<id>.md` (`po-ship.md:25`) after the gate does not reopen the review.

## Story
A review verdict must only count for the code it judged: a commit added on `story/<id>` after `Ship allowed: yes` must not reach the ship unreviewed. Complexity 3, depends on nothing, fixes defect 32.

Criteria (each is a test name):
1. `review_template_records_the_reviewed_tree` — the review template carries `Reviewed tree: <40 hex>`, the tree of `story/<id>` taken before the review starts.
2. `ship_allowed_fails_when_code_changed_after_review` — `po-gate ship-allowed` refuses when code outside `docs/` differs from `Reviewed tree:`, naming `/po-review <id>`.
3. `ship_allowed_ignores_docs_changes_after_review` — a `docs/`-only change after the verdict does not reopen the review.
4. `ship_allowed_fails_without_reviewed_tree` — a review without a usable `Reviewed tree:` line is refused like a missing review.
5. `rules_and_ship_describe_the_bound_verdict` — Law 3, `/po-ship` (manual check without the hook) and `/po-status` describe the tree-bound verdict.
6. `drive_sends_a_stale_review_back_to_review` — in `/po-drive`'s resume table a favourable review whose tree no longer matches sends the lane to review, not ship.

## Current code
- `method/hooks/po-gate.sh` (68 lines): header usage `:4-9`; `refuse` prints `po-gate: …` to stderr and returns 1 (`:13`); `ship_allowed` `:25-31` (file present, last verdict exactly `yes`); `verif_current` `:34-45` (record present, `complete`, first `Tree:` 40-hex `:39` via `head -n 1`, `cat-file -e "${tree}^{tree}"` `:41`, diff `:43`); dispatcher `:62-68`.
- `method/templates/review.md`: header `Review status:` `:5`, `Fix loop:` `:6`; ends with `Max severity:` `:51` and `Ship allowed:` `:52`.
- `method/commands/po-review.md`: tools Read, Glob, Grep, Agent, Write (`:4-9`); the reviewer prompt `:30`, reused "word for word" by `/po-drive` (`po-drive.md:86`); recording requirements `:33`; blocked fallback written by the command `:35` (it cannot carry a tree; it says `Ship allowed: no` anyway).
- `method/agents/reviewer.md`: inputs `:17-18` (diff `git diff <Target branch>...story/<id>`), limits `:23-24` (no file written, bite undone with `git diff --exit-code`), answer shape `:37-45`.
- `method/commands/po-ship.md:17-18`: Step 0 = `po-gate ship-allowed <id>` from the worktree, or by hand "the **last** line starting with `Ship allowed:` … must be `Ship allowed: yes`", stop message names `/po-review <id>`.
- `method/commands/po-drive.md`: resume table `:44-54`, first match wins (`:42`); `review … is yes | the ship` `:53`; the stale-review prose based on commit counting `:58`; ship sentence `:119`.
- `method/commands/po-status.md:29`: review column = last `Ship allowed:` + `Fix loop:`; `:28` already runs `po-gate verif-current` read-only.
- `method/AGENTS.md:62`: Law 3 row "the last `Ship allowed:` line … says `yes`"; `:64` "A review without its two verdict lines counts as blocked."
- `docs/defauts.md:67`: defect 32, status `ouvert — s47`.

## Attachment points
- `po-gate.sh`: a shared helper extracted from `verif_current:39-44`, called by `verif_current` and `ship_allowed`.
- `templates/review.md` header block (`:5-6`).
- `reviewer.md` inputs/answer sections — the step that takes the tree first.
- `po-review.md:33` recording list; `po-ship.md:18`; `po-drive.md:44-54` and `:119`; `po-status.md:29`; `AGENTS.md:62,64`.

## Verified interfaces
- `refuse <msg>` → stderr `po-gate: <msg>`, status 1 (`po-gate.sh:13`). Callers chain `|| return 1` because of `set -e` (`:10`).
- `git diff --quiet <tree-ish> HEAD -- . ':(exclude)docs'` from `top()` compares against the whole repo even from a subdirectory (`tests/gate.test.sh:71-79` proves it for verif).
- `git rev-parse 'story/<id>^{tree}'` inside the worktree prints the 40-hex tree of the committed branch tip; `git cat-file -e "<abbrev>^{tree}"` accepts an abbreviated hash, so only the 40-hex regex (`po-gate.sh:39`) rejects short ones.
- Test helpers: `scratch_repo`, `contains`, `fail` (`tests/lib.sh:41-53`); gate tests call `bash "$GATE"` via `passes` (`tests/gate.test.sh:15`) and silence stderr.
- `section_of` / `holds` in `tests/drive.test.sh:8-10`; ship gate test reads `po-ship.md` lines (`tests/ship.test.sh:8-14`).

## Traps
- Tests quoting text this story changes: `tests/drive.test.sh:84` (ship sentence, update with it — the story says so); `tests/ship.test.sh:13` (`the **last** line starting with \`Ship allowed:\`` — keep the phrase); `tests/drive.test.sh:204` greps the row `review whose last \`Ship allowed:\` is \`no\`` and `:202` the row `record current, review blocked` — leave both rows' text intact; `tests/resume.test.sh:22,26,27` quote other rows; `tests/flow.test.sh:27` quotes `Ship allowed: yes` in `po-flow.md` (not owned).
- `tests/review.test.sh:21-25`: the template must still end with `Max severity` then `Ship allowed`; the new line goes in the header, not at the end. `:38` keeps `/po-review` without Bash.
- Row order in the resume table: a commit added after a favourable review usually also stales `docs/verif/<id>.md`, so the earlier row `no record or po-gate verif-current fails → the code stage` (`po-drive.md:49`) wins first. The new row is reached when the record is current (e.g. a fix run re-recorded and nobody re-reviewed). It must sit above `:53`.
- Loop number of a re-review: `/po-review` sets it to previous `Fix loop:` + 1 itself (`po-review.md:25`), and `/po-drive` counts attempts from that line (`po-drive.md:62`). A stale-yes re-review therefore spends one `Max attempts` unit.
- Pre-s47 reviews: any lane holding a review without `Reviewed tree:` is refused once the new gate is installed (criterion 4, deliberate). Shipped reviews under `docs/reviews/` are not rewritten (story note).
- This repository runs its pipeline on the **installed** copies (`.polype/hooks/po-gate.sh`, `.claude/`), regenerated from `method/` by `bin/polype-dev-install .`; s47's own ship and the parallel lane `s50-implementer-bounds` still use the old gate until reinstall. Do not touch `.polype/`, `.claude/` or the root `AGENTS.md`.
- `s50-implementer-bounds` runs in parallel; its story note (`docs/stories.md:830`) keeps it off `method/AGENTS.md`. `s48-floor-guard` depends on s47 and also owns `po-gate.sh` and `templates/review.md`.
- M6 asks every story to pass `bin/ks-overlap` against gstack (`28f1385`) and agent-skills (`1401c8b`) before its PR (`docs/stories.md:699`); `tests/overlap.test.sh` covers Killer SaaS only. Wording must be original.
- No migration, no screen, no auth, no new dependency.

## Open questions
- Which `Reviewed tree:` line counts when a report holds several (quoted earlier review)? Verdict uses the last, record uses the first. → plan decides.
- CI: the header advises running `ship-allowed` in CI (`po-gate.sh:9`); CI checkouts of a pull request often sit on a merge ref, whose tree differs from the story tip. → plan states the constraint in the header rather than changing the comparison.
- `/po-drive` never `cd`s (`po-drive.md:68`) yet `po-gate` derives its repo from the cwd (`po-gate.sh:12`): how the driver runs any gate inside a lane is unspecified today, for all three gates. Pre-existing, outside this story; flagged, not fixed.

## Complexity
Story: 3 → after reading: 3. One function in a shell script plus a shared helper, one template line, and wording in six method files; the only subtlety is the resume-table order and who can capture the tree.

## Split
Not needed (score 3).
