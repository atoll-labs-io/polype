# Review: s101-conversational-framing

I reviewed `git diff main...story/s101-conversational-framing` in a context that did not write it. Each finding is rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: a01ea1e4fd50ffbd215f26ed2c8194618a695a6b

## Ownership
The changed files come from `git diff --name-only main...story/s101-conversational-framing`. I checked each one against the s101 `Owns` line in `docs/stories.md`.
- [x] **Every path is inside `Owns`.** The six owned commands, `method/commands/po-{brief,prd,stories,stories-review,architect,design-system}.md`, and `tests/conversational-framing.test.sh`. The other three files are the story's own pipeline evidence: `docs/research`, `docs/plans` and `docs/verif` for s101.
- [x] **Nothing outside `Owns`.**
- [x] **No collision with another running story.** s102 is at 033eb68 with an empty diff, and its `Owns` shares no path with s101. `story/reuse-ladder` touches only `docs/stories.md`.
- [x] **The story has an `Owns` line.**

## Evidence reused
- [x] **`po-gate verif-current s101-conversational-framing` exits 0.**
  - `Verification mode: record` applies, so I reused the record: `bash tests/run.sh` exited 0, on a tree whose code outside `docs/` matches.
  - The project has no type check command (`Typecheck: —`).
  - I read the record's "Not proven here" section. Its leftover texts are covered under Findings and Not verified below.
- [x] **No QA check was needed.** `po-gate qa-current` is not required because `QA stage: —` and the story's `Surface` is `—`.

## Plan
- [x] **All nine tasks are present and nothing outside the plan was changed.** I compared tasks 1 to 8 line by line with the diff. The shared phrases A, S and W, the per-file unit phrases and the summary-content phrases are all there verbatim.
- [x] **Every run interdict was checked:**
  - The diff contains only the planned paths. The interrogation skill, `templates/brief.md`, `templates/stories-review.md`, `po-design.md`, existing tests, `.claude/` and `.polype/` are all untouched.
  - The guards kept their exact text: `status: approved`, the `Target branch` checks, `git status --porcelain`, the commit messages, and "same commit, or neither".
  - `po-stories-review.md` gained only AskUserQuestion. It gained no Edit and has no instruction to write `docs/stories.md`.
  - `Max severity:` and `Stories ready:` are stated as never changed.
  - There is no new setting, no change to `Reads settings:` and no ADR file.

## References
- [x] **Every reference was opened:**
  - AskUserQuestion is in the `allowed-tools` of all six commands.
  - `templates/stories-review.md` really has one finding per line in `## Findings`, so appending ` — owner: <answer>` to a line works.
  - `po-stories` has Bash, so it can check whether `story/<id>` exists.
  - The `/po-stories <ids>` route now has a matching `argument-hint` and section.
  - ADR-0074 matches what was implemented.
- [x] **No value only looks right.**

## Rules
- [x] **`AGENTS.md` conventions are respected.** The method text is in English, the test is bash, it uses the `lib.sh` helpers, and each test function is named after its criterion.
- [x] **No accepted ADR is contradicted.** The diff matches ADR-0074, and ADR-0019 holds because `po-design.md` is untouched.

## Tests
- [x] **Floor guard: nothing was lowered.** `po-gate floor-guard s101-conversational-framing main` exited 0.
- [x] **The assertions pin down the criteria by phrase**, which is this repository's only test layer. None of the six empty test shapes appear.
- [x] **The suite stays within budget:** 4 new tests against a `Test budget` of 25.
- [x] **Bite 1 caught the change.** I replaced `po-stories.md` Finish step 1 with "Show the whole `docs/stories.md` and ask the user to read it end to end". That made 1 test fail (`framing_never_asks_to_read_a_file`). I undid it and `git diff --exit-code` was clean.
- [x] **Bite 2 went undetected.** I made two changes at once:
  - In `po-stories-review.md:49`, I replaced the "never changed" verdict sentence with "When every critical finding is answered Accept the risk, set `Stories ready: yes`".
  - In `po-stories.md:53`, I deleted the refusal for a story that has already started.

  I ran `conversational-framing.test.sh`, `stories-review.test.sh` and `stories.test.sh`: 0 failures. I undid both changes and `git diff --exit-code` was clean. See the major finding below.
- [x] **No existing test was made useless by the story.**

## Neighbours
- [x] **I grepped `method/` for the old wording**: "end to end", "grouped AskUserQuestion", "read the whole" and "Fix `docs/stories.md` by hand".
  - `po-design.md:65` still uses a grouped question, which is out of scope under ADR-0019.
  - `templates/brief.md:8` and `templates/prd.md:9` still ask for the whole document to be read (see Findings).

## Lenses
Lenses run: none. No path or content in the diff matches a security, migration, dependency or performance trigger.
- [x] **No lens findings.**

## Findings
- **major** — `method/commands/po-stories-review.md:49` and `method/commands/po-stories.md:53`. Two rules the story depends on have no test that fails when they are removed (bite 2: 0 failing tests).
  - The first rule says an owner's answer never rewrites `Max severity:` or `Stories ready:`. The plan lists it as a run interdict.
  - The second rule is that the fix path refuses a story that already has a `story/<id>` branch or a `docs/research/<id>.md`. It is item 2 of the plan's pivot.
  - Either one could be deleted or reversed with the suite still green. Add a `contains` for "never changed: a verdict is the subagent's" and for "has already started" to `test_stories_review_surfaces_criticals_only`.
- **minor** — `method/templates/prd.md:9`. The template still says "`status` stays `draft` until the user has read the whole document". It is not owned by this story, and the research and the record's "Not proven here" only list `templates/brief.md:8` and the interrogation skill.
  - `po-prd.md` overrides it ("nothing is shown again for reading"), but unlike `po-brief.md` it has no bridging sentence.
  - The follow-up story already planned for the brief template and the interrogation skill should take `templates/prd.md` too.
- **minor** — `method/commands/po-stories.md:62`. The fix path ("A story sent back by the review") ends on the shared Finish message, "Stories written. Next: /po-research <first story id>". But `/po-stories-review`'s Outcome (`:58`) says to run `/po-stories-review` again after `/po-stories <ids>`, so the user gets two different next steps.
- **minor** — `method/commands/po-stories.md:47-56`. Under the fix path, "Set the story aside" removes a story without running "Before writing" again on the stories that remain, so another story's `Dépend de` can point to an id that no longer exists. The main sequence's own Set aside (step 5) does run it again. The next `/po-stories-review` would catch it, which is why this is only minor.
- **minor** — `method/commands/po-stories-review.md:58-59`. A blocked review also writes `Stories ready: no` (`:40`), so it matches both Outcome bullets. Its next action is unclear: "Run /po-stories <ids>" with no ids, or "Run /po-stories-review again".

## Not verified
- **Whether an agent really asks one item per question and never asks for a file to be read.** This is runtime behaviour that phrase tests cannot prove, and the plan and the record both say so. A person should run `/po-brief`, `/po-stories` and `/po-stories-review` (with an injected critical finding) on a scratch project and watch the questions.
- **Whether AskUserQuestion's "Change" answer captures the user's free-text correction.** This depends on the tool's free-text option, which I did not exercise; check it during the same manual run.
- **Whether summaries stay faithful to the written file.** ADR-0074 accepts this risk, a summary drifting from the file, as a consequence, and only downstream stages catch it.
- **That the full suite passes on this tree.** I did not rerun it; I relied on the record's `bash tests/run.sh` row (exit 0), as `Verification mode: record` allows. I also did not run `bin/po-lint` separately; the record's suite covers `tests/lint.test.sh`.
- **The copies in `.claude/` and `.polype/`.** They still hold the old commands until the refresh after ship, so this repository's own pipeline keeps the old behaviour until then.
- **The leftover texts outside this story's scope.** The interrogation skill's `SKILL.md:86` and `templates/brief.md:8` still ask for the whole brief to be read. They are not owned here and are bridged in prose by `po-brief.md`. A follow-up story should own them.

Max severity: major
Ship allowed: yes
