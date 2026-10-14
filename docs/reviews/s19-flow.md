# Review — s19-flow

[Story](../stories.md) · [Plan](../plans/s19-flow.md) · [Verification](../verif/s19-flow.md)

Diff reviewed: `git diff m2-cadrage...story/s19-flow` (commit 608ed34), in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s19-flow` passes (exit 0). With `Verification mode: record` I reused `docs/verif/s19-flow.md`: status complete, Tree ae1b2bc…, `bash tests/run.sh` exit 0 with 117 passed. The project has no Typecheck, E2E or Build command (all `—`), so none was run. The record's "Not proven here" section is read and repeated below.

## Plan
- [x] Tasks 1–6 are all present in the diff and nothing sits outside the plan. The diff touches 8 files: the 3 new files the story owns, one line of `po-help.md`, the D15 line of `docs/parite-killer-saas.md`, and the research, plan and verification record.
- [x] Run interdicts, checked one by one:
  - The diff under `.claude/`, `.polype/`, `AGENTS*.md`, `docs/stories.md`, `docs/decisions/`, `bin/`, `tests/lib.sh`, the existing tests, `method/AGENTS.md`, `method/agents/`, `method/skills/`, `method/hooks/` and the existing templates is empty.
  - `po-help.md` changes by exactly one line.
  - `parite-killer-saas.md` changes only on the D15 line.
  - No new setting was added.
  - The orchestrator, status and rules are not wired to the track (that is s20).
  - The overlap test is green in the record.

## References
- [x] Opened and confirmed:
  - In `tests/lib.sh`: `frontmatter`, `settings_read_by`, `needs_tool`, `contains`, `require_file`, `fail`, `$METHOD`.
  - The `codebase-analysis` and `testing-doctrine` skills.
  - `po-ship.md` "Step 0".
  - The `/po-execute` and `/po-review` prompts and their preconditions.
  - `Story track` / `Flow threshold` in `method/templates/agents-local.md:27-28,50-51`, including the allowed values `full` / `flow` / `auto`.
  - The Complexity field in `method/templates/stories.md:10`.
  - The worktree steps of `/po-research`, which `po-flow.md:49` reproduces faithfully.
  - The tools: Read, Glob, Grep, Write, Bash, Agent and AskUserQuestion cover research, plan, review recording and ship (`po-ship` needs Read, Bash and AskUserQuestion; `po-review` needs Write). This follows the `po-orchestrator` precedent.
- [x] Values: the 150-line ceiling, the limit of six tasks and the five signals all match D15 and the story.

## Rules
- [ ] One conventions gap: the `Reads settings:` list is incomplete (finding 2).
- [x] No accepted ADR is contradicted.

## Tests
- [ ] The assertions check that phrases are present, not what the rule says to do. Four of the rules the plan's pivot names are covered by no test (finding 1).
- [x] 4 tests, within `Test budget` 25.
- [x] Bite: I ran `bash tests/run.sh flow.test.sh` only (baseline 4 passed). Each change was undone with `git checkout -- method/commands/po-flow.md`, and `git diff --exit-code` came back clean every time. The final `git status --porcelain` is empty.
  - M1, `po-flow.md:30`: a story with no complexity is now **accepted** under `auto` → **0 failing**.
  - M2, `po-flow.md:28`: `Story track` is `full` now **accepts** the short track → **0 failing**.
  - M3, `po-flow.md:73-75`: the short-track sentence is removed from both delegation prompts → **0 failing**.
  - M4, `po-flow.md:44`: a signal found after reading the code is ignored ("note it in the plan and carry on") → **0 failing**.
  - M5, `po-flow.md:64`: approval is skipped and `validated: yes` is written at once → **0 failing**.
- [x] The story makes no existing test useless.

## Neighbours
- [x] `po-status.md`, `po-orchestrator.md` and `agents/reviewer.md` still assume there is a `docs/research/<id>.md`:
  - `po-status` would show a short-track story as "research missing".
  - The prompts work around the reviewer's missing input through the appended sentence.
  - Wiring these is explicitly s20's scope (`docs/stories.md:298`), so this is not a finding here.

## Findings
- **major** — `tests/flow.test.sh:34-70`. The tests check that the triggering phrases exist but never check what the rule then does, so the rules the plan's pivot names can all be reversed without any test failing (M1–M5 above):
  - (d) `auto` accepting a story with no complexity;
  - `full` refusing the short track, which acceptance criterion 3 names directly ("`Story track: full` refuse la voie courte");
  - (c) the short-track sentence in both prompts;
  - (b) stopping when a signal is found after reading the code;
  - the approval step.

  The plan's task 2 even calls for "the missing-complexity refusal" in `## Which track`, but task 4 never pins it. Fix: pin the consequence phrases, for example `refuse` inside `## Which track`, `cannot be compared with the threshold`, `there is no docs/research/<id>.md` counted twice in `## Execute, review, ship`, `write no plan`, and `The rule of \`/po-plan\``.
- **minor** — `method/commands/po-flow.md:15`. `Reads settings:` leaves out `E2E stage`, `E2E scope`, `E2E browsers` and `Build stage`, which the command reads when it "applies `/po-ship` from its Step 0" (`po-ship.md` lists them). The convention says to list every setting read. `po-orchestrator` has the same gap, which is a precedent but no excuse.
- **minor** — `method/commands/po-flow.md:76`. The fix-loop step does not say whether a fix-run delegation also gets the short-track sentence. It only says so for the first run (line 73), so a literal reader could send a fix run to an implementer that looks for a research file that does not exist.
- **minor** — `method/commands/po-flow.md:27`. "Read `Story track` before anything else" conflicts with `## Checks`, which comes first (the `AGENTS.local.md` existence check and the id match). The intended order is clear, but the wording is off.
- **minor** — `method/commands/po-flow.md:20-24`. `/po-research` warns when `docs/reviews/stories.md` is missing or not `Stories ready: yes`; `## Checks` drops that warning. It is non-blocking there, but the short track silently loses it.
- **minor** — `method/commands/po-flow.md:52-56`. There is no re-scoring of complexity after reading the code, which `/po-research` step 6 does. Under `auto`, a story that turns out harder than stated stays on the short track unless one of the five signals or the six-task limit catches it.

## Not verified
- **How an agent actually behaves when it runs `/po-flow`.** No story was run through the short track (the record says so too). A person should run `/po-flow` on a real complexity-1 story in a test project, then do the same with a story that carries a signal, and check two things: the worktree is kept, and `/po-research <id>` then reuses it.
- **Whether the gate accepts the `track: flow` frontmatter.** I only read `po-gate.sh:18-22` indirectly, through the research. I did not run `po-gate plan-validated` against a `track: flow` plan. A person should fill `templates/plan-flow.md` with `validated: yes` in a scratch worktree and make a commit, to confirm the pre-commit hook lets it through.
- **Whether the delegated prompts match `/po-execute` and `/po-review` word for word.** `po-flow.md` only refers to them, so this is untested by design; I compared the text by reading only.
- **The installed copy.** `.claude/commands/po-flow.md` does not exist in this worktree (installed files are off limits), so the command cannot be invoked here until someone reinstalls. That is `bin/polype-dev-install .` after merge.
- **Browser, type check, end-to-end and build.** The project has no Typecheck, E2E or Build command (`—`), and the story ships prose only.

Max severity: major
Ship allowed: yes
