---
track: flow
validated: yes
---
# Plan (short track) — s128-artifact-link-templates

[Story](../stories.md)

Written by the `planner` subagent on the short track. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s128-artifact-link-templates.md`.

## Verified facts
- **No assumption of the story proved false.** Every reader of the six artefacts reads by pattern or by section, except two positional reads, and both survive a line placed under the title: the frontmatter must open line 1 (`method/hooks/po-gate.sh:29`, `tests/lib.sh:14`, `method/hooks/po-session.sh:48`), and the research's first `## ` heading must be `## Structuring facts` (`tests/research.test.sh:31`). A link line is neither `---` nor a `## ` heading.
- `po-gate`: `plan_validated` reads the frontmatter only (`po-gate.sh:31-36`); `ship_allowed` greps `^([-*] )?Ship allowed:` / `Review status:` and pairs `Reviewed tree:` (`:40-48`, `:65-79`); `verif_current` greps `^Verification status:`, pairs `Tree:`, needs `^## Checks$` (`:81-96`) and `record_rows` reads only the `## Checks` and `## Runs` sections (`:100-129`); `qa_current` greps `^QA status:` and pairs `Tree:` (`:158-182`). A line starting with `[` matches none of these.
- `po-run` appends under `## Runs`, creating it when absent, and never rewrites the head (`method/hooks/po-run.sh:56-63`); `tests/run-ledger.test.sh:40` already holds that the head survives.
- `po-session` reads `Root cause: not found`, `Technical choice: waiting for a human`, `validated: yes` with `grep -qx`, and `QA status` / `Ship allowed` / `Review status` / `Fix loop` as the last `^<label>:` line (`po-session.sh:44`, `:208-224`). `/po-status` (`method/commands/po-status.md:24-35`), `/po-ship` (`method/commands/po-ship.md:18`) and `/po-review` (`method/commands/po-review.md:26`, `:36`) read the same labels or call `po-gate`. `/po-execute` reads "the first line of `## Complexity`" (`method/commands/po-execute.md:34`): section-relative, unaffected.
- Template tests that pin positions: `tests/qa.test.sh:16-18` (last two non-blank lines `Tree:` then `QA status:`), `tests/execute.test.sh:54-57` (record has `Tree:`, the status line, `## Checks`, `## Runs` last), `tests/review.test.sh:58-62` (`Reviewed tree:` before `Max severity:`), `tests/reuse-ladder.test.sh:18-27` (heading order). None reads the line under the title.
- Who fills each template: research and plans by the planner / `/po-flow` (`method/agents/planner.md:38-41`); the record by the implementer, who "edits only its own lines" (`method/agents/implementer.md:41`, `method/templates/verification-record.md:3`); the QA report by the `qa` agent (`method/agents/qa.md:52`); the review is the reviewer's answer "structured like `templates/review.md`" (`method/agents/reviewer.md:51`), written whole by the coordinator (`po-review.md:36`, `method/commands/po-drive.md:135`). So the link line reaches every artefact through its template alone.
- Paths: research, plans, reviews, verif sit one level under `docs/` (`../stories.md`); the QA report is `docs/qa/<id>/report.md` (`po-gate.sh:159`), two levels (`../../stories.md`). The record always exists before review (`implementer.md:41`, no `Verification mode` skips it), so review → verif resolves on both tracks; a full-track plan always has its research; a flow plan never does (`method/templates/plan-flow.md:7`).
- No relative Markdown link to an artefact exists in `method/` (`method/templates/architecture.md:10,29` hold only placeholder ADR links), no wikilink either: no convention to follow, none to break.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, `docs/stories.md:1984-2000` | absent — six markdown templates and one bash test |
| New screen | absent — `Surface: —` | absent — no UI |
| Authorization or tenant scope | absent — story text | absent — `po-bounds.sh` untouched, out of `Owns` |
| API contract | absent — story text says no Law 3 gate changes | absent — every gate reads by label or section (facts above); no hook or command changes |
| New dependency | absent — story text | absent — bash and markdown only |
| Technical choice that deserves an ADR (library, pattern, data model) | absent — the story fixes the form: relative Markdown links, no wikilinks, no anchors | absent — the line's wording is an implementation detail inside these bounds |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no such line on s128 | absent |

Five tasks; QA not applicable (`Surface: —`); complexity 2 → 2, as written.

## Story
As a project owner I want each story-artefact template to carry a line of links to its story and to the artefact before it, so that every new artefact is linked from the moment it is written.
- `templates_carry_links` — under each template's title, after the frontmatter when there is one, a line of relative Markdown links: the story (`../stories.md`) always, then the previous artefact when it exists on that track (research ← plan; plan or plan-flow ← review, verif, QA; verif ← review). No wikilinks; no anchor to a heading unless a test checks it.
- `gates_still_read_artifacts` — `po-gate`, `po-run`, `/po-review`, `/po-ship` and `/po-status` give the same result on an artefact with and without the line, held by a test; `templates/verification-record.md` says the line belongs to the template, not to an implementer edit.
- `links_resolve` — a test fails if a link of the line, in a template rendered for a throwaway story, points to a missing file.

## Reuse
No new code outside the test file; its fixtures follow the throwaway-repo pattern of `tests/lib.sh:47-55` (`scratch_repo`) and the record fixture of `tests/run-ledger.test.sh:77-86`, re-declared locally because each test file is sourced alone (`tests/run.sh:11-17`).

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `tests/artifact-link-templates.test.sh` | new code | the story asks for its own test file; `scratch_repo` and `contains` are reused from `tests/lib.sh` |

## Tasks
The link line, in every template: the title line, one blank line, the link line, one blank line, then the existing content unchanged. Links separated by ` · `, exactly as below, `<id>` left as the placeholder.

1. [x] **Planning templates.** `method/templates/research.md` after line 1: `[Story](../stories.md)`. `method/templates/plan.md` after line 4 (the frontmatter stays lines 1-3): `[Story](../stories.md) · [Research](../research/<id>.md)`. `method/templates/plan-flow.md` after line 5 (frontmatter lines 1-4): `[Story](../stories.md)` — no research link, there is none on this track. Tests: `test_templates_carry_links`, `test_links_resolve`; `research.test.sh`, `flow.test.sh`, `plan.test.sh`, `reuse-ladder.test.sh` stay green.
2. [x] **Evidence templates.** `method/templates/verification-record.md` after line 1: `[Story](../stories.md) · [Plan](../plans/<id>.md)`, and under it, as a paragraph of its own followed by a blank line, the sentence: "The link line under the title is part of this template: it is copied with it, never edited, and is not one of the implementer's lines." `method/templates/review.md` after line 1: `[Story](../stories.md) · [Plan](../plans/<id>.md) · [Verification](../verif/<id>.md)`. `method/templates/qa.md` after line 1: `[Story](../../stories.md) · [Plan](../../plans/<id>.md)`. Tests: the three below; `qa.test.sh`, `execute.test.sh`, `review.test.sh`, `ownership.test.sh`, `qa-gate.test.sh` stay green.
3. [x] **`tests/artifact-link-templates.test.sh`, `test_templates_carry_links`** (header `# s128 — story-artefact templates carry their links.`). For each of the six templates: the first non-blank line after the first `^# ` line equals the expected line of tasks 1-2 exactly (one table in the test, template → line); line 1 is still `---` for `plan.md` and `plan-flow.md`; no template holds `[[` or `.md#`. The record template holds the sentence of task 2. Fails if a line is missing, moved above the title, carries a wrong link or an anchor.
4. [x] **`test_gates_still_read_artifacts`.** In one `scratch_repo` on `story/s01-a`, build passing artefacts the way the existing gate tests do (plan with `validated: yes`; review with `Review status: complete`, `Reviewed tree:` = HEAD tree, `Ship allowed: yes`; record from the `run-ledger` fixture sealed with a `po-run` row; QA report with `Tree:` and `QA status: complete`, committed), each opening on its title. For each gate `plan-validated`, `ship-allowed`, `verif-current`, `qa-current`, record the exit code, insert the template's link line (read from the template, `<id>` → `s01-a`) under the title, commit, and assert the same exit code; repeat once with a refusing artefact (plan `validated: no`) to show a refusal stays a refusal. Then run `po-run` on the linked record and assert the link line is still line 3 and `verif-current` still passes. Last, assert the six link lines match none of the patterns the commands read: `^---$`, `^## `, `^([-*] )?(Ship allowed|Review status|Reviewed tree|Fix loop|Tree|Verification status|QA status|validated|track):`, `Root cause: not found`, `Technical choice: waiting for a human` (this covers `/po-review`, `/po-ship`, `/po-status`, which read those labels or call `po-gate`).
5. [x] **`test_links_resolve`**, then the full suite. Render the templates into a scratch tree holding `docs/stories.md`: full track `s01-a` (research, plan, record, review, `docs/qa/s01-a/report.md`) and short track `s02-b` (plan-flow as `docs/plans/s02-b.md`, record, review, no research), with `sed 's/<id>/<that id>/g'`. For each rendered file, extract every `](target)` of its link line and fail when `dirname(file)/target` is not a file. Bites: a QA link written `../stories.md`, or a research link added to plan-flow, fails it. Then `po-run --story s128-artifact-link-templates --label "Unit suite" -- 'bash tests/run.sh'`; `Typecheck: —`, so no type check.

## Scene viewpoints
—

## Run interdicts
- Empty diff outside `Owns` plus this plan: notably `method/hooks/` (`po-gate.sh`, `po-run.sh`, `po-session.sh`, `po-bounds.sh`), `method/commands/`, `method/agents/` (including `implementer.md`, `reviewer.md`), `.claude/`, `.polype/`, every existing `tests/*.test.sh`, and every artefact already under `docs/research|plans|reviews|verif|qa/` — the backfill is s129's.
- In each template, every line other than the inserted link line and its blank line is unchanged (`git diff` of each template shows added lines only); in `verification-record.md` the added sentence paragraph is the only other addition.
- No wikilink, no `#anchor` in a link, no absolute path.
- `tests/overlap.test.sh` stays green (no Killer SaaS text).

## The pivot
Everything rests on the claim that no reader of these artefacts reads by position below the frontmatter, so a line under the title shifts nothing. Ways it could be wrong: (a) a reader not listed above reads a fixed line number or "the second line" — compare against a `grep -rn 'sed -n\|head -n\|NR==' method bin` of the diff's neighbours; (b) the reviewer's answer is transcribed without the line, so reviews lose their links while the gate still passes — only the template is in this story's scope, check `reviewer.md:51` still points at the template; (c) a depth mistake in the QA report's links (`docs/qa/<id>/`), which `test_links_resolve` is there to catch.

## Files touched
`method/templates/research.md`, `method/templates/plan.md`, `method/templates/plan-flow.md`, `method/templates/review.md`, `method/templates/verification-record.md`, `method/templates/qa.md`, `tests/artifact-link-templates.test.sh` (new); plus this plan, committed with the code.

## Test strategy
Three tests in one new file, one per criterion, named after it — well under `Test budget` (25). `test_templates_carry_links` is a text check of the six templates; `test_gates_still_read_artifacts` runs the real `po-gate` and `po-run` on throwaway repositories, comparing exit codes with and without the line, and pins the label patterns the markdown commands read; `test_links_resolve` renders the templates for two throwaway stories and resolves each link on disk. Task tests: `bash tests/run.sh artifact-link-templates.test.sh`; the full suite once at the end through `po-run`. No visual check.

## Done when
The three criteria hold, `bash tests/run.sh` is green (including `qa`, `execute`, `review`, `research`, `flow`, `run-ledger`, `gate`, `overlap`), one commit on `story/s128-artifact-link-templates` with this plan and the record, and a review with no open critical finding.
