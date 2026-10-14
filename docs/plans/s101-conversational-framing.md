---
validated: yes
---
# Plan — s101-conversational-framing

[Story](../stories.md) · [Research](../research/s101-conversational-framing.md)

Branch `story/s101-conversational-framing`. Read `docs/research/s101-conversational-framing.md` first. This plan builds on it and does not repeat it.

## Story
The framing is approved in conversation, one item per question, each from a summary, so nobody opens a file to approve it (ADR-0074). Criteria: `framing_never_asks_to_read_a_file`, `one_item_per_question`, `summary_short_but_complete`, `stories_review_surfaces_criticals_only`.

## Shared phrases (exact, written in English, each as one unbroken line)
The tests quote these phrases. Write them verbatim, each on a single line of the command; a phrase split across a line break does not count.
- **A** — `answers Approve / Change / Set aside`: in po-brief, po-prd, po-stories, po-architect and po-design-system.
- **S** — `The summary aims short and grows when the subject needs it: no fact needed to decide is cut to keep it short.`: in the same five files and in po-stories-review.
- **W** — `Each item is written only once approved, and the commit asks for no rereading.`: in the same five files.
- **Units**, one per file:
  - po-brief and po-prd: `one section per question`;
  - po-stories: `one story per question`;
  - po-architect: ``one ADR per question, then the conventions as one item, then `docs/architecture.md` summarised as one item``;
  - po-design-system: `one token group, one contrast fix or one gap per question`;
  - po-stories-review: `one critical finding per question`.
- **Summary contents**:
  - po-brief and po-prd: `what the section settles and why`;
  - po-stories: `what the story delivers, why, and its acceptance criteria`;
  - po-architect: `what the ADR decides, why, and the options turned down`.
- **Change** always sends the item back to the step it belongs to and asks about it again. **Set aside** is defined per command below.

## Tasks
1. [x] **`method/commands/po-brief.md`.**
   - Add a short `## Approval` section after `## Persistence`. Before a theme is written, its section goes to the user alone, `one section per question`, with **A**: a summary of `what the section settles and why`, then **S** and **W**.
   - Set aside drops the draft and leaves that theme unsettled: the interview comes back to it.
   - The section adds this sentence: `The interrogation skill's last exit criterion, agreement after reading the whole brief, is met here by these one-section approvals: never ask for the file to be read.` That sentence is the bridge to the unowned skill (research, fact 1).
   - Exit criteria `:41` becomes `- every section has the user's explicit agreement, given on its own question.` (it keeps the word `agreement`).
   - Finish step 2 becomes: `Every section was approved on its own question during the interview; nothing is shown again for reading. Set \`status: approved\`.` Steps 1, 3 and 4 do not change.
   - Test: `framing_never_asks_to_read_a_file`, `one_item_per_question` and `summary_short_but_complete`, plus `tests/brief.test.sh`, which stays green.
2. [x] **`method/commands/po-prd.md`.**
   - In the Interview rules, `:30` "Each section is shown in full, validated, and only then written" becomes: each section goes to the user alone, `one section per question`, as a summary of `what the section settles and why`, with **A**; then **S** and **W**. Keep `:28-29` and the sentence "Nothing enters …".
   - Set aside drops the draft and the section stays empty, so the interview comes back to it.
   - Finish step 1 becomes: `Every section was approved on its own question; nothing is shown again for reading. Set \`status: approved\`.` Step 2 does not change.
   - The resume at `:25` says to recap the approved sections in a few lines instead of showing them.
   - Test: the same three criteria, plus `tests/prd.test.sh`.
3. [x] **`method/commands/po-stories.md`, writing the stories.**
   - Sequence steps 4 and 5 become: draft each story in full from `templates/stories.md`, then put them to the user in order, `one story per question`, each summarised as `what the story delivers, why, and its acceptance criteria`, with **A**, **S** and **W**.
   - Change → back to "Before writing" for that story. Set aside → the story leaves the draft, and "Before writing" runs again on what remains, since a dependency may now be broken.
   - Finish step 1 becomes: `Every story was approved on its own question; nothing is shown again for reading.` Step 2 does not change.
   - Keep `:33` (append, never renumber).
   - Test: the same three criteria, plus `tests/stories.test.sh` and `tests/owns-overlap.test.sh`.
4. [x] **`method/commands/po-stories.md`, taking a story back from the review.**
   - Add an `argument-hint: [story ids sent back by /po-stories-review]` and a section `## A story sent back by the review`.
   - With ids from `/po-stories-review`, the command rewrites (Fix) or removes (Set the story aside) only those stories. It keeps each id, and it works only on a story with no `story/<id>` branch and no `docs/research/<id>.md`; otherwise it stops and says that the story has already started. The rewritten story goes through "Before writing" and the one-story question, then it is committed as `docs: stories fixed after review`.
   - Add a sentence saying this section is the one exception to `:33`.
   - Test: the stories_review clauses in the next task check `sent back by \`/po-stories-review\`` and `keeps its id` in this file.
5. [x] **`method/commands/po-stories-review.md`.**
   - Add `  - AskUserQuestion` to `allowed-tools` (required by po-lint; never add Edit).
   - New section `## Critical findings` between "Recording" and "Commit". After the report is written, the command puts each critical finding to the user, `one critical finding per question`: a summary of the story, the problem and why it is critical, then **S**, with `answers Fix / Accept the risk / Set the story aside`.
     - Fix: the finding stays open, and the Outcome sends its story id to `/po-stories <ids>`.
     - Accept the risk: `the finding stays open in the report`.
     - Set the story aside: the Outcome sends the id to `/po-stories <ids>` to be removed.
     - Each answer is appended to that finding's own line in `## Findings` as ` — owner: <answer>`. The `Max severity:` and `Stories ready:` lines are never changed: a verdict is the subagent's, not the owner's.
   - Add `Majors and minors stay in the report and are not asked.` and keep "It never edits the stories." (`:15`).
   - With no critical finding, or a blocked review, nothing is asked.
   - Outcome `:46` becomes: list the ids marked Fix or Set aside, then "Run /po-stories <ids>, then /po-stories-review again."; on accepted risks only, say that the risks stay open.
   - Test: `stories_review_surfaces_criticals_only`, plus `tests/stories-review.test.sh`, `tests/lint.test.sh`, `tests/model-routing.test.sh` and `tests/platform-setting.test.sh`.
6. [x] **`method/commands/po-architect.md`.**
   - `:53`: "in the grouped AskUserQuestion of "Approval and commit"" becomes "in the question on the conventions in "Approval and commit"".
   - Approval step 2 becomes `one ADR per question, then the conventions as one item, then \`docs/architecture.md\` summarised as one item`, with **A**. Each ADR is summarised as `what the ADR decides, why, and the options turned down`, and gap ADRs also give the switch condition. The conventions item shows, on a rerun, "what the new conventions would remove or contradict" (keep the phrase inside `## Approval and commit`). Then **S** and **W**.
   - Set aside: an ADR is not written, and its capability goes back to step 3, or is marked not needed in `docs/architecture.md` if the user says so. On the conventions, no new rule is written. On `docs/architecture.md`, the command ends with nothing written.
   - Steps 3 and 4 do not change.
   - Test: the three criteria, plus `tests/architect.test.sh`, `tests/capability-bricks.test.sh` and `tests/post-m7-texts.test.sh`.
7. [x] **`method/commands/po-design-system.md`.**
   - Approval step 2 becomes `one token group, one contrast fix or one gap per question`, with **A**. A token group is the tokens of one role (text, surface, border, accent, focus …), with their light and dark values and the measured ratios of their pairs. Then one last item for the state patterns and do / don't lists. Then **S** and **W**.
   - Set aside: a token group or a gap is left out of the file and named in the final message; a contrast fix that is set aside leaves its pair recorded as failing, with no fix.
   - Test: the three criteria, plus `tests/design-system.test.sh`.
8. [x] **`tests/conversational-framing.test.sh`.** Four functions, named after the criteria. Each one quotes the shared phrases from the shared-phrases section, file by file, with `contains`. Start the file with the comment line `# s101 — framing approved in conversation, one item per question (ADR-0074).`
   - `test_framing_never_asks_to_read_a_file`: for each of the six commands, none of `end to end`, `grouped AskUserQuestion`, `Show the whole` or `read the whole` appears, with one exception. `po-brief.md` may hold `read the whole` only on the bridge line, which also holds `never ask for the file to be read`: run `grep -F 'read the whole' | grep -vF 'never ask for the file to be read'` and expect nothing.
   - `test_one_item_per_question`: **A**, the unit phrase and **W** in each of the five; po-architect's unit phrase sits inside `## Approval and commit`.
   - `test_summary_short_but_complete`: **S** in the six files, and the summary contents in po-brief, po-prd, po-stories and po-architect.
   - `test_stories_review_surfaces_criticals_only`:
     - in po-stories-review: `needs_tool … AskUserQuestion`; `answers Fix / Accept the risk / Set the story aside`; `one critical finding per question`; `the finding stays open in the report`; `Majors and minors stay in the report and are not asked.`; `It never edits the stories.`; and `/po-stories <ids>`;
     - in po-stories: `` sent back by `/po-stories-review` `` and `keeps its id`.
9. [x] **Checks.**
   - During the tasks: `bash tests/run.sh conversational-framing.test.sh brief.test.sh prd.test.sh stories.test.sh stories-review.test.sh architect.test.sh design-system.test.sh lint.test.sh owns-overlap.test.sh overlap.test.sh`, then `bash bin/po-lint`.
   - At the end, once: `po-run --story s101-conversational-framing --label test -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- `git diff main...story/s101-conversational-framing --stat` lists only the six owned commands, `tests/conversational-framing.test.sh`, `docs/research/s101-conversational-framing.md`, `docs/plans/s101-conversational-framing.md` and `docs/verif/s101-conversational-framing.md`. That means an empty diff for:
  - `method/skills/interrogation/SKILL.md`, `method/templates/brief.md`, `method/templates/stories-review.md`;
  - `method/commands/po-design.md` (ADR-0019);
  - every existing `tests/*.test.sh`;
  - `.claude/` and `.polype/`.
- The guards do not change: the `status: approved` line, the `Target branch` checks, the `git status --porcelain` checks, the commit messages, and the shared commit of the brief and its ADR. The `Finish` and `Commit` sections keep every line that the `Approval` rewrites do not name.
- `po-stories-review.md` gains no Edit, and its body never tells it to write `docs/stories.md`.
- `po-stories-review.md` never rewrites `Max severity:` or `Stories ready:` from an owner's answer.
- No new setting, no `Reads settings:` change, no ADR file (ADR-0078 is not used).

## The pivot
The pivot is that adding a per-item question to each command is enough, with no shared skill: the six files each carry the same three phrases (**A**, **S**, **W**). It could be wrong in three ways.
1. **A leftover text.** An unowned text still asks for a whole-file reading: the interrogation skill `:86` and the brief template `:8`. The bridge sentence in po-brief covers the agent's behaviour, but the two texts remain. Check the bridge line in po-brief against `SKILL.md:86`. A follow-up story should own those two files.
2. **A broken fix path.** The `/po-stories` fix path could reopen a story that has already started. Check that task 4's refusal condition names both the `story/<id>` branch and `docs/research/<id>.md`.
3. **A frozen phrase lost.** A rewrite in Finish or Approval could drop a frozen phrase. Start from the trap list of the research, and from the order test in `tests/brief.test.sh:62-68`, where `git status --porcelain` must come before 'set `status: approved`'.

## Files touched
`method/commands/po-brief.md`, `po-prd.md`, `po-stories.md`, `po-stories-review.md`, `po-architect.md` and `po-design-system.md` (all under `method/commands/`); `tests/conversational-framing.test.sh`.

## Test strategy
- **Automated**: four functions in one new file, one per criterion, at the only layer this repository has (phrases of the method files, per its conventions). Each test bites when its rule is removed:
  - deleting **A**, **W**, a unit phrase or the stories-review answers fails it;
  - putting back a grouped question or an "end to end" fails `framing_never_asks_to_read_a_file`.
- Existing files rerun as regression: brief, prd, stories, stories-review, architect, design-system, lint, owns-overlap and overlap, then the full suite once through `po-run`. That is 4 new tests, within `Test budget: 25`.
- **Not provable by test**: that an agent really asks one item per question. That stays a behavioural check for a person, as `docs/defauts.md:21` notes.

## Done when
- All nine tasks are ticked.
- `bash bin/po-lint` is clean, the full suite passes through `po-run`, and `docs/verif/s101-conversational-framing.md` is complete.
- The implementer makes one commit on the story branch, and the review leaves no open critical finding.
