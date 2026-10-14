# Research — s101-conversational-framing

[Story](../stories.md)

## Structuring facts
- **False assumption — the six commands are not the only texts asking to read the whole brief.** `method/skills/interrogation/SKILL.md:86` ("the user's explicit agreement after reading the whole brief"), which `po-brief.md:26` makes the agent read first, and `method/templates/brief.md:8` ("the user has read the whole brief") both say it. Neither is in `Owns`, and `po-bounds` keeps the implementer's writes inside the `Owns` read at the fork point (`method/hooks/po-bounds.sh:5`, `:152-172`). The story should list both files in `Owns`; until a story does, `po-brief.md` has to say outright that its one-section approvals take the place of that line of the skill.
- **False assumption — `/po-stories` can take a story back from the review.** It has no argument and no fix path, and it forbids rewriting an existing story: "Existing ids and stories are never renumbered or rewritten" (`method/commands/po-stories.md:33`). The answer `Fix` of `stories_review_surfaces_criticals_only` sends a story back to `/po-stories`, so that command needs a narrow way in: a story the review sent back that has no `story/<id>` branch yet may be rewritten in place, or set aside, and it keeps its id.
- Four commands currently ask for one approval of the whole file: `po-brief.md:41,47`, `po-prd.md:52`, `po-stories.md:48`, `po-architect.md:64` (a single grouped AskUserQuestion), `po-design-system.md:67` (the same). `po-architect.md:53` refers to that grouped question.
- `po-stories-review.md` has no AskUserQuestion (`:3-9`). `bin/po-lint:131-133` reports any body that names it without declaring it, and `tests/lint.test.sh` uses `reports_one` (exactly one breach on a mutant copy of `method/`), so a single undeclared mention would make every lint test fail.
- No gate, no hook and no setting changes. The change is to the prose of six markdown commands plus one new bash test file.

## Story
As the project owner, I want to approve each section of the brief or PRD, each story and each ADR one at a time, from a summary shown in the terminal, so that I never open a file to approve the framing (ADR-0074). Criteria (test names):
- `framing_never_asks_to_read_a_file`: none of the six owned commands asks for a file to be read end to end, and none puts its items in one grouped approval.
- `one_item_per_question`: each item is put to the user alone, with Approve / Change / Set aside. The item is a section for `/po-brief` and `/po-prd`, a story for `/po-stories`, and for `/po-architect` each ADR, then the conventions, then `docs/architecture.md` as one summary. For `/po-design-system` it is a token group, a contrast fix or a gap. The file is written after approval, and the commit asks for no rereading.
- `summary_short_but_complete`: the summary gives what, why, and either the options turned down (ADR) or the criteria (story). It aims to be short and grows when the subject needs it.
- `stories_review_surfaces_criticals_only`: critical findings are put one at a time, with Fix (sent back to `/po-stories`; the review never edits stories), Accept the risk (the finding stays open in the report) and Set the story aside. Majors and minors stay in the report.

## Current code
- `method/commands/po-brief.md` (51 lines). The interview writes each settled theme to the file at `status: interviewing` (`:29-30`). Exit criteria are at `:33-43`; the last one is "the user has read the whole brief and given explicit agreement" (`:41`). Finish is at `:45-49`: step 1 runs the blocking checks (branch, env files), step 2 says "Show the whole brief and ask the user to read it end to end" and sets `status: approved` (`:47`), step 3 writes the first ADR, step 4 commits the brief and the ADR in one commit.
- `method/commands/po-prd.md` (55 lines). Interview rules at `:27-30`: "One question per message", "Nothing enters `docs/prd.md` before the user validates it", and "Each section is shown in full, validated, and only then written" (`:30`). Resume at `:25`. Finish step 1: "Show the whole PRD and ask the user to read it end to end" (`:52`).
- `method/commands/po-stories.md` (51 lines). Sequence at `:27-33`: draft the list, run "Before writing", show the list and get agreement (`:31`), write each story in full (`:32`), append without rewriting (`:33`). Finish step 1 asks for the whole file to be read end to end (`:48`). No `argument-hint`.
- `method/commands/po-stories-review.md` (48 lines). Delegates to `stories-reviewer` (`:29-34`), writes the answer in full (`:37`), falls back to a blocked report (`:39`), commits (`:42`). On `Stories ready: no` it lists the critical findings and tells the person to fix the stories by hand (`:46`). States "It never edits the stories." (`:15`).
- `method/commands/po-architect.md` (68 lines). Step 3 writes the ADRs (`:40-48`) and step 4 the conventions (`:50-57`). Approval and commit is at `:62-66`: draft `docs/architecture.md`, one grouped AskUserQuestion that also shows on a rerun "what the new conventions would remove or contradict" (`:64`), write, install, commit.
- `method/commands/po-design-system.md` (71 lines). Steps 1-4 produce sources, tokens with their roles (`:38`), contrast fixes (`:58`), gaps and patterns. Approval at `:65-69` is one grouped AskUserQuestion (`:67`).
- `method/templates/stories-review.md:32-39`: `## Findings` holds one finding per line (`severity — story id — the problem`), and the file ends with `Max severity:` then `Stories ready:`. This template is not owned and must not change.

## Attachment points
- The approval paragraph of each command: `po-brief.md` Exit criteria and Finish step 2, `po-prd.md` Interview rules and Finish step 1, `po-stories.md` Sequence steps 4-5 and Finish step 1, `po-architect.md` "Approval and commit" step 2 and `:53`, `po-design-system.md` "Approval and commit" step 2.
- `po-stories-review.md`: frontmatter `allowed-tools` (add `AskUserQuestion`), a new section between "Recording" and "Commit", and the "Outcome" section.
- `po-stories.md`: a new section for a story sent back by the review.
- New file `tests/conversational-framing.test.sh`.

## Verified interfaces
- `tests/lib.sh`: `contains FILE PHRASE` (exact `grep -F`, `:43`), `needs_tool FILE TOOL` (`:29`), `require_file` (`:41`), `fail` (`:11`). Each test file defines its own `section_of` (see `tests/brief.test.sh:9`).
- `tests/run.sh` takes file names relative to `tests/` (`:5-6`).
- `bin/po-lint` tool rule: `:119-139`. A body that mentions AskUserQuestion has to declare it, and a file declaring Agent must not declare Edit (`po-stories-review` declares Agent: never add Edit).

## Traps
Phrases frozen by tests outside `Owns`. Keep them verbatim:
- `tests/brief.test.sh`:
  - `:45-46`, "After each theme, write what it settled into docs/brief.md and keep status: interviewing." and "continue at the first theme not yet settled";
  - `:53-55`, Exit criteria holding "status: approved is written only when all of these hold:" and the words `one-liner`, `wedge`, `success metric`, `three non-goals`, `critical dimension`, `pre-mortem finding`, `agreement`;
  - `:62-70`, Finish holding `git status --porcelain` on a line **before** the first 'set `status: approved`', plus `` `Target branch` `` and 'leaves `docs/brief.md` at `status: interviewing`';
  - `:76-83`, a line with `docs: brief for <product>`, `docs/brief.md`, `the ADR` and `in one commit`, plus "The approval and its ADR go in the same commit, or neither".
- `tests/prd.test.sh:102-103`: "One question per message." and "Nothing enters `docs/prd.md` before the user validates it."; `:13`, `:127-128`.
- `tests/stories.test.sh`: Checks lines `:142-146`, `:193-199`; Before writing `:175-176`, `:183`.
- `tests/architect.test.sh:12`: AskUserQuestion declared. `:56-63`: Step 4 phrases. `:67`: "what the new conventions would remove or contradict" inside the `## Approval and commit` section, so the heading stays. `:76-82`.
- `tests/design-system.test.sh:100-126`: AskUserQuestion, "This command never invents an identity:", Step 1 and Step 3 phrases.
- `tests/stories-review.test.sh:199`: 'writes `docs/reviews/stories.md` on `Target branch`'. `tests/model-routing.test.sh:44,53`, `tests/platform-setting.test.sh:100-104` ("Platform: <value>").
- `tests/lint.test.sh:70`: the mutation looks for the exact line `  - Agent` in `po-brief.md`, so keep it.
- `tests/owns-overlap.test.sh:63-68`: `po-stories.md` keeps its citation of the overlap rule and must not say "sharing a path" or "no path shared".
- `tests/overlap.test.sh`: no line of `method/` may share 8 or more consecutive words with Killer SaaS. Write in our own words.
- `po-design.md:65` also has a grouped question. It is out of scope (ADR-0019) and not owned.
- s104 depends on s101 and will also own `po-architect.md`, so keep the change additive and local there.
- No migration, no dependency, no API.

## Open questions
- English labels for the answers. ADR-0074 says Approuver / Modifier / Écarter. `po-plan.md` already uses "Approve / Change / Stop". The plan picks **Approve / Change / Set aside** and, for the review, **Fix / Accept the risk / Set the story aside**.
- What Set aside does for each kind of item. ADR-0074 does not say; the plan decides it per command.
- Where a human answer to a critical finding is recorded. The template is not owned. The plan appends it to the finding's own line in `## Findings` and leaves the verdict lines unchanged.
- `/po-design-system` state patterns and do / don't. The criterion does not name them as items, but leaving them out would let unapproved content be written. The plan puts them to the user as one last item.

## Complexity
Story: 3. After reading the code: 3. There are six prose edits, one test file, and one extra path not in the story (the fix path of `/po-stories`). The work is small but spread across files with many frozen phrases.

## Split
—
