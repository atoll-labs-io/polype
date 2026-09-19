---
validated: yes
---
# Plan — s15-stories-review

Branch `story/s15-stories-review`. Read `docs/research/s15-stories-review.md` first; this plan builds on it without repeating it.

## Story
`/po-stories-review` sends `docs/stories.md` to a read-only `stories-reviewer` subagent that did not write it, records its answer in `docs/reviews/stories.md` on `Target branch`, and `/po-research` warns when that verdict is missing or negative, without blocking. Criteria (each the name of one test in `tests/stories-review.test.sh`): `stories_reviewer_is_read_only_without_shell`, `stories_review_checks_coverage_first`, `stories_review_checks_owns_overlap`, `stories_review_template_ends_with_stories_ready`, `stories_review_is_a_soft_gate`.

## Decisions

| Question | Decision | Why |
| --- | --- | --- |
| Split agent / skill / command | Skill `stories-review` holds the procedure (ordered checks) and the severity scale; agent `stories-reviewer` sets inputs, limits and answer shape and preloads `stories-review` and `agentic-stories`; command handles checks, delegation, recording, commit | Same split as `reviewer` / `review-antihallu` / `/po-review`; the rules stories were written with stay in one place (`agentic-stories`) |
| Agent tools | `Read, Grep, Glob` only; `model: inherit` | Criterion 1; judges get no Write (conventions); no shell means no git — every input is a file |
| Scope source | Same mapping as `/po-stories`: `replace`/`adapt` → `docs/prd.md` (`## Core loop`, `## Angle`, `## Graveyard`); `new` → `docs/brief.md` (`## Wedge & non-goals`, `## Premises`); `—` or missing source → the command stops | One mapping across the framing commands; coverage needs a scope |
| Severity scale | **critical**: a scope item no story covers, a graveyard feature revived, a dependency on a later or unknown story, an `Owns` path shared by two stories with no dependency between them. **major**: a technical layer dressed as a story, an untestable criterion, an unsplit 5, a 4 without its risk. **minor**: id format, thin notes, wording | Criticals are the defects that waste whole cycles; an Owns collision breaks parallel runs, and fixing it costs one `Depends on` line |
| Verdict | Template ends `Max severity: <critical \| major \| minor \| none>` then `Stories ready: <yes \| no>`; `no` means a critical finding or a blocked review, nothing else | Mirrors `Ship allowed` |
| Subagent failure | The command writes a blocked report itself, `Max severity: critical`, `Stories ready: no` | Same as `/po-review` |
| Re-run | Overwrites `docs/reviews/stories.md`; no fix-loop counter | The stories are fixed by hand; git keeps history |
| Soft gate in research | One bullet in `po-research.md` "Checks first": missing file or last `Stories ready:` not `yes` → warn and suggest `/po-stories-review`, then carry on | Allowed by the story's notes; the gate is soft by design |
| Lines outside Owns | That bullet, one French line in `po-help.md` after `/po-stories`, the C06 status cell | `pilot.test.sh:38` forces the help line; the story's notes allow the research line; conventions require the matrix cell |

## Tasks
1. [x] `method/skills/stories-review/SKILL.md` — frontmatter `name: stories-review`, `description:` (…preloaded in the stories-reviewer). Own wording (ADR-0006). A short intro, then `## Checks, in this order`, numbered steps written `**1. Coverage …**` etc.:
   1. **Coverage** — first, table in hand: one row per scope item (each core-loop line and the angle, or the wedge and each premise) with the stories that cover it; exact sentence `An item of the scope that no story covers is critical.`
   2. Graveyard (replace/adapt): a story reviving a buried feature, even renamed.
   3. Technical layers dressed as stories (points to `agentic-stories`; contract stories as it defines them are allowed).
   4. Criteria a test cannot check.
   5. Dependency order: no dependency on a later or unknown id.
   6. Complexity: 5 unsplit, 4 without its risk.
   7. Ids: `s<number>-<slug>`, unique, numbered in file order.
   8. **Owns overlap** — exact sentence `Two stories with no dependency between them that share an \`Owns\` path are flagged as critical: run side by side, they would edit the same files.` Also a story without Owns.
   Then `## Severity` with the scale of the decisions table and `Stories ready: no` meaning a critical or a blocked review.
   — Tests: `stories_review_checks_coverage_first`, `stories_review_checks_owns_overlap`.
2. [x] `method/agents/stories-reviewer.md` — frontmatter `name: stories-reviewer`, `description`, `tools: Read, Grep, Glob`, `model: inherit`, `skills:` list `- stories-review`, `- agentic-stories`. Body: fresh-context stance; `Reads settings: \`Entry mode\``; `## Inputs` (`docs/stories.md`, the scope source named in the message, `AGENTS.md`, accepted ADRs); `## Limits` (no file written, no shell; the command writes the report); `## When you cannot finish` (blocked report: `Review status: blocked`, cause, missing, next action); `## Your answer` shaped like `templates/stories-review.md`, "Not verified" before the verdict, ending with the two lines. — Test: `stories_reviewer_is_read_only_without_shell`.
3. [x] `method/templates/stories-review.md` — `# Stories review — <product>`; line "Stories reviewed: `docs/stories.md`, against `<docs/prd.md | docs/brief.md>`, in a context that did not write them."; `Review status: <complete | blocked>`; `## When blocked`; `## Coverage` as a table `| Scope item | Source section | Covered by | Covered |`; `## Checks` (one checkbox per step 2–8); `## Findings`; `## Not verified`; last two lines exactly `Max severity: <critical | major | minor | none>` then `Stories ready: <yes | no>`. — Test: `stories_review_template_ends_with_stories_ready`.
4. [x] `method/commands/po-stories-review.md` — frontmatter `description`, no `argument-hint`, `allowed-tools` Read, Glob, Grep, Agent, Write, Bash. `# /po-stories-review`, `Reads settings: \`Entry mode\`, \`Target branch\``. Sections:
   - `## Checks`: no Agent tool → stop; no `AGENTS.local.md` → `/po-setup`; no `docs/stories.md` → `/po-stories`; scope source by `Entry mode` as in the decisions (missing → stop naming `/po-prd` or `/po-brief`; `—` → stop); run from the repository root on `Target branch`, another branch → stop.
   - `## Delegation`: Agent tool, `subagent_type: stories-reviewer`, quoted prompt naming `docs/stories.md`, the source, and the answer shape.
   - `## Recording`: write the answer whole to `docs/reviews/stories.md`; failure or missing verdict lines → blocked report written here with `Max severity: critical` / `Stories ready: no`.
   - `## Commit`: `git status --porcelain` lists an environment file → stop; commit `docs/reviews/stories.md` alone on `Target branch` as `docs: stories review`. Exact phrase `writes \`docs/reviews/stories.md\` on \`Target branch\``.
   - `## Outcome`: `Stories ready: yes` → "Stories reviewed. Next: /po-research <first story id>"; `no` → list critical findings, fix `docs/stories.md` (by hand or `/po-stories`), run `/po-stories-review` again. State that `/po-research` warns but does not stop on a missing or negative verdict.
   — Test: `stories_review_is_a_soft_gate` (command part).
5. [x] `method/commands/po-research.md` "Checks first": one bullet, exact phrase `\`docs/reviews/stories.md\` missing on \`Target branch\`, or its last \`Stories ready:\` line not \`yes\` → warn` … `suggest /po-stories-review`, and `carry on: this check never blocks.` No other change to this file. — Test: `stories_review_is_a_soft_gate` (research part).
6. [x] `method/commands/po-help.md`: one line after `/po-stories`: `` - `/po-stories-review` — fait relire les stories par un subagent en contexte frais, périmètre en main ; verdict dans `docs/reviews/stories.md`. `` — Test: existing `every_command_listed_in_help`.
7. [x] `tests/stories-review.test.sh`, header `# s15 — stories review: command, subagent, skill and template.`, local `section_of` (copy of `tests/stories.test.sh:8`):
   - `test_stories_reviewer_is_read_only_without_shell`: `needs_tool` Read; `lacks_tool` Write, Edit, Bash; frontmatter has a line `  - stories-review`.
   - `test_stories_review_checks_coverage_first`: in `## Checks, in this order`, the first line starting `**1.` contains `Coverage`; skill holds the critical-gap sentence; template has a `## Coverage` section with a table header line starting `| Scope item`.
   - `test_stories_review_checks_owns_overlap`: skill holds the Owns sentence; template's `## Checks` mentions `Owns`.
   - `test_stories_review_template_ends_with_stories_ready`: last two non-empty lines equal `Max severity: <critical | major | minor | none>` and `Stories ready: <yes | no>`.
   - `test_stories_review_is_a_soft_gate`: command contains the writes-on-Target-branch phrase; `po-research.md` `## Checks first` section contains `docs/reviews/stories.md`, `Stories ready:` and `this check never blocks`.
8. [x] `docs/parite-killer-saas.md`: C06 status → `fait — \`method/commands/po-stories-review.md\`, \`method/agents/stories-reviewer.md\`, \`method/skills/stories-review/SKILL.md\`, \`method/templates/stories-review.md\``; no other line (A02 stays).
9. [x] Full suite `bash tests/run.sh` (`Full suite: execute-end`); record in `docs/verif/s15-stories-review.md`.

## Run interdicts
- Empty diff for `.claude/`, `.polype/`, `AGENTS.md`, `AGENTS.local.md`, `docs/stories.md`, `tests/lib.sh`, every existing test file, `method/AGENTS.md`, every existing `method/templates/`, `method/agents/`, `method/skills/` file, and every existing `method/commands/` file except the single bullet of `po-research.md` and the single line of `po-help.md`.
- `docs/parite-killer-saas.md`: only the C06 line changes.
- `po-research.md` never says `stop` about the stories review.
- The new files do not mention `docs/references/`, `~/dev/vault` or `/spec`.
- No sentence from Killer SaaS (`tests/overlap.test.sh` green with its sources present); never open the Killer SaaS files of the same name.

## The pivot
Coverage is checked first and is the only check that needs the scope source; everything else reads `docs/stories.md` alone. Ways it could be wrong: (a) the scope items are not enumerable — compare the coverage rows with the sections the PRD and brief templates really have (`method/templates/prd.md:20,34`, `brief.md:21,30`); (b) the review restates `agentic-stories` and drifts from it — the skill should name each rule and point to it; (c) the soft gate hardens by wording — read the research bullet for any stop.

## Files touched
New: `method/commands/po-stories-review.md`, `method/agents/stories-reviewer.md`, `method/skills/stories-review/SKILL.md`, `method/templates/stories-review.md`, `tests/stories-review.test.sh`. Edited: one bullet of `method/commands/po-research.md`, one line of `method/commands/po-help.md`, the C06 line of `docs/parite-killer-saas.md`. Plus `docs/research/`, `docs/plans/`, `docs/verif/` for this story.

## Test strategy
Five structural tests in `tests/stories-review.test.sh`, one per criterion (budget 25). Each quotes the clause it guards, so removing the clause fails it. Existing `every_command_listed_in_help`, `every_setting_read_by_a_command_exists_in_template`, the install test and `method_does_not_reuse_killer_saas_text` cover the rest. No visual checks.

## Done when
Full suite green, one commit `s15-stories-review: …` on `story/s15-stories-review` holding code, tests and docs, verification record complete, review with no open critical finding.
