---
validated: yes
---
# Plan — s158-review-header-recorded

[Story](../stories.md) · [Research](../research/s158-review-header-recorded.md)

Branch `story/s158-review-header-recorded`. Read `docs/research/s158-review-header-recorded.md` first; this plan builds on it without repeating it.

## Story
Defect #169: a review's header is whatever the reviewer copied, so s147's review landed without its link line and turned main red. Fix at the cause: whoever records a review (`/po-review`, `/po-drive`; `/po-orchestrator` and `/po-flow` through "as `/po-review` says") writes the template's title and link line, then the body; the reviewer answers below them. Criteria: `recorder_writes_the_header`, `drive_writes_the_header`, `reviewer_answers_below_the_header`, `template_marks_the_header`, `adr_records_the_header_rule`.

## Reuse
The plan writes no new code: text in four method files and one ADR. The rule for dropping a missing link is the one `bin/po-link-artifacts:20-31` already applies, restated, not reimplemented.

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| — | — | — |

## Acceptance tests
Written by the planner before any code. Each test reads the section of the method file the tasks below fix, whitespace collapsed; `test_template_marks_the_header` also records a review the way the rule says (the template's two header lines, then an answer with no title) and runs `bin/po-link-artifacts` on it.

| Oracle file | cksum |
| --- | --- |
| `tests/review-header-recorded.oracle.test.sh` | `2523056994 6685` |

| Criterion | Test |
| --- | --- |
| `recorder_writes_the_header` | `test_recorder_writes_the_header` |
| `drive_writes_the_header` | `test_drive_writes_the_header` |
| `reviewer_answers_below_the_header` | `test_reviewer_answers_below_the_header` |
| `template_marks_the_header` | `test_template_marks_the_header` |
| `adr_records_the_header_rule` | `test_adr_records_the_header_rule` |

## Tasks
Every phrase quoted below is what the oracle reads; write it exactly, on one line per paragraph as the files already do.

1. [x] **`/po-review` `## Recording` (`method/commands/po-review.md:36-41`).** Insert, as the first paragraph of the section, before `:37`:
   > The file's header is this context's, never the reviewer's. The first write of `docs/reviews/<id>.md` starts with the title line and the link line of `templates/review.md`, `<id>` replaced, then one blank line, then the body, whatever it is: the subagent's answer, whole and word for word, or the blocked report this context composes when the subagent fails, times out or answers without both verdict lines. A link whose target does not exist in the worktree is dropped from the line, never invented. A file that already exists — a fix loop, a new answer after `findings-shape`, a blocked report this context composed — keeps its header and receives only the new block after what it holds.

   In `:37`, the opening "Write the subagent's answer, whole, to `docs/reviews/<id>.md` in the worktree. It must contain" becomes "The file lives in the worktree. The answer must contain"; the rest of `:37` unchanged. In `:41`, "write the file yourself:" becomes "write the file yourself, under the header above:". `:39` unchanged word for word (its phrases are frozen by `tests/review-findings-shape.test.sh:77-83,136-139`). Test: `test_recorder_writes_the_header`.
2. [x] **`/po-review` prompt (`po-review.md:32`).** "Shape your answer like templates/review.md with `Fix loop: <n>`." becomes "Shape your answer like templates/review.md with `Fix loop: <n>`, starting below its header: no `# Review` title and no link line, which this context writes itself." Rest of the prompt unchanged. Test: `test_reviewer_answers_below_the_header`.
3. [x] **`/po-drive` verdict section (`method/commands/po-drive.md:136`).** The two first sentences become:
   > A reviewer's answer is recorded **verbatim** into `docs/reviews/<id>.md` in that lane's worktree, through Bash, under the header `/po-review` describes in `## Recording`: the first write of the file starts with the title line and the link line of `templates/review.md`, `<id>` replaced and any link whose target is missing dropped, then one blank line, then the transcribed answer — or the blocked report you compose yourself when that is the first thing written; a file that already exists keeps its header and receives only the new block after it. You transcribe it, you do not author it: the header comes from the template, never from the reviewer, and no severity is yours to choose, no finding yours to soften or drop.

   The third sentence (`/po-review` already puts this recording…) and `:138-142` unchanged. Test: `test_drive_writes_the_header`; `tests/drive.test.sh:62-69` and `tests/qa-fleet.test.sh:120-142` must stay green.
4. [x] **`reviewer.md` `## Your answer` (`method/agents/reviewer.md:53`).** Its first sentence "Structured like `templates/review.md`, with the `Reviewed tree:` line in its header." becomes three:
   > Structured like `templates/review.md`, with the `Reviewed tree:` line among its status lines. Your answer starts below the file's header: no `# Review` title and no link line, since the context that records your answer writes those two lines itself. Everything else in `templates/review.md`, except the note under its link line, is the shape of your answer.

   The rest of `:53` unchanged (`in the shape \`templates/review.md\` shows, never a heading: \`po-gate findings-shape\` checks it` is frozen by `tests/review-findings-shape.test.sh:69`). Test: `test_reviewer_answers_below_the_header`.
5. [x] **`templates/review.md` note.** After the link line (`:3`) insert a blank line, then the line
   > `<These two lines are written by whoever records the review, not by the reviewer: the reviewer's answer starts below this note.>`

   so that `Diff reviewed:` follows after one more blank line. Title and link line byte for byte unchanged (`bin/po-link-artifacts:15` and `tests/artifact-link-templates.test.sh:24-28` read the link line as the first non-blank line after the title). Test: `test_template_marks_the_header`; `tests/review.test.sh`, `tests/artifact-link-templates.test.sh`, `tests/artifact-links-backfill.test.sh` stay green.
6. [x] **ADR-0104** `docs/decisions/ADR-0104-celui-qui-consigne-une-revue-en-ecrit-l-en-tete.md`, in French, from `templates/adr.md`: `adr: 0104`, title "Celui qui consigne une revue en écrit l'en-tête", `status: accepted`, `date: 2026-11-11`, `scope: story s158-review-header-recorded`, `supersedes: []`, `superseded-by: []`, no comment on those lines.
   - Context: #169; s147's review landed without its link line (`f71ba00`), repaired by hand (`2f98528`, #168); the record's `Tree:` and the ship gate exclude `docs/`, and `po-gate findings-shape` reads the findings block only (ADR-0094, ADR-0096).
   - `## Considered Options`, in this order: the chosen one (**Celui qui consigne la revue écrit l'en-tête**); **Insérer la ligne de liens seulement quand elle manque** — "une exception conditionnelle de plus à la transcription", which depends on what the reviewer copied; **Faire refuser la revue par `po-gate` et arrêter la voie** — "chaque oubli du relecteur devient un arrêt pour la personne", and a new answer appended after it "ne répare pas la ligne sous le premier titre".
   - `## Decision Outcome`: "Chosen option: **Celui qui consigne la revue écrit l'en-tête**", then the rule (title and link line of `templates/review.md`, `<id>` replaced, a missing target dropped, then the body; an existing file keeps its header and only receives the new block), and its place in the transcription rule, holding the exact phrases "le verdict, les constats et les lignes de statut restent mot pour mot" and "seul l'en-tête du fichier vient du gabarit". Say `/po-orchestrator` and `/po-flow` inherit it through "as `/po-review` says", and that a review recorded before it is repaired by a person with `bin/po-link-artifacts`, never by a conditional insertion.
   - `### Consequences`: good, bad, neutral, one line each.
   Test: `test_adr_records_the_header_rule`.
7. [x] Focused runs: `bash tests/run.sh review-header-recorded.oracle.test.sh review.test.sh review-findings-shape.test.sh review-tree-gate.test.sh drive.test.sh qa-fleet.test.sh artifact-links-backfill.test.sh artifact-link-templates.test.sh hooks-installer-docs-cleanup.test.sh overlap.test.sh lint.test.sh`. Then the full suite once: `po-run --story s158-review-header-recorded --label test -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `method/hooks/po-gate.sh`, `method/hooks/po-bounds.sh`, `bin/po-link-artifacts`, `method/commands/po-orchestrator.md`, `method/commands/po-flow.md`, `method/commands/po-ship.md`, `method/commands/po-qa.md`, `method/agents/qa.md`, `method/templates/qa.md`, `method/AGENTS.md`, `.claude/`, `.polype/`.
- `tests/review-header-recorded.oracle.test.sh` keeps the sum above (`po-gate oracle-intact s158-review-header-recorded`); no existing test file changes; `tests/review-header-recorded.test.sh` is not created (no test beyond the oracle).
- `po-review.md` frontmatter `allowed-tools` unchanged; `:39` unchanged byte for byte.
- `method/templates/review.md`: `git diff main -- method/templates/review.md` shows two added lines (blank and note) and no removed line.
- No existing `docs/reviews/*.md` edited; no ADR other than ADR-0104 created or touched.
- No conditional insertion anywhere ("add the line when it is missing"): the header is written on every first write, whatever the answer holds.

## The pivot
The fix rests on **moving the header out of the reviewer's answer and into the recorder's first write**, while everything after it stays verbatim. Ways it could be wrong:
- The template note could slide above the link line and become what `bin/po-link-artifacts:15` reads as the link line; compare the first non-blank line after the title with `tests/artifact-link-templates.test.sh:14`.
- `po-drive.md:136` could lose a frozen phrase while being rewritten; compare with `tests/drive.test.sh:64-66`.
- A reviewer that still copies `# Review` and the link line gives a doubled header. The verbatim rule keeps it and the backfill test reads only the first title, so it passes; check no task asks the recorder to strip it (that would break verbatim).

## Files touched
`method/commands/po-review.md`, `method/commands/po-drive.md`, `method/agents/reviewer.md`, `method/templates/review.md`, `docs/decisions/ADR-0104-celui-qui-consigne-une-revue-en-ecrit-l-en-tete.md` (new), `tests/review-header-recorded.oracle.test.sh` (written by the planner), plus `docs/research/` and `docs/plans/` of this story.

## Test strategy
Automated: the five oracle tests, one per criterion, all text contracts plus one behavioural check (a review recorded under the rule is one `bin/po-link-artifacts` counts as linked, and the script must run). Each quotes a phrase only the new rule carries, so restoring the old text of any task turns its test red. 5 tests, within `Test budget` 25. No test runs a real recording: the recorder is a model following text, not code in this repository. Visual checks: none.

## Done when
One commit on `story/s158-review-header-recorded` with the method changes, ADR-0104, research, plan and oracle; full suite green through `po-run`; a review with no open critical finding, itself recorded under the new rule and passing `tests/artifact-links-backfill.test.sh`; #169 closed at ship.
