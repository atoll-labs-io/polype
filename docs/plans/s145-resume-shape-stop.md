---
validated: yes
---
# Plan — s145-resume-shape-stop

[Story](../stories.md) · [Research](../research/s145-resume-shape-stop.md)

Branch `story/s145-resume-shape-stop`. Read `docs/research/s145-resume-shape-stop.md` first; this plan builds on it without repeating it.

## Story
`/po-orchestrator` and `/po-flow` hand a review blocked on its findings' shape to the person, with the cause its `Next action:` gives, and spend no fix run (#123, #125).
- `orchestrator_stops_on_shape_block` — Stage 7 records "as `/po-review` says". The delegation phrase stays. Before "Any other blocked review → back to stage 5 as a fix run", a shape-blocked review goes to the person.
- `flow_stops_on_shape_block` — the same in `/po-flow`'s "Fix loops", before "Any other `Ship allowed: no` → a fix run", that line kept whole.

Correction carried from the research: a rerun of `/po-orchestrator` decides the fix run at Stage 5 (`po-orchestrator.md:59`) before Stage 7 is reached. Task 2 closes that path too, inside `Owns`.

## Reuse
No new code: four sentences added to two method files, plus one bash test file built on the helpers already used by `tests/qa-fleet.test.sh:12-14` and `tests/lib.sh`.

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `section_of` / `holds` in the new test | already in this repository, copied as `tests/qa-fleet.test.sh:12-14` and `tests/review-findings-shape.test.sh:10-11` already do | — (first rung) |

## Tasks
1. [x] **Orchestrator Stage 7** (`method/commands/po-orchestrator.md`).
   - In `:70`, keep "Delegate to `reviewer` the way `/po-review` does, `model:` set to `Model strong`," unchanged. Turn the recording clause into: "and record `docs/reviews/<id>.md` with its `Fix loop:` as `/po-review` says, its findings-shape check and that check's stop included."
   - Insert a new paragraph after the `:76` paragraph and before `:78`, on one line: "Blocked on findings shape — `Review status: blocked` and a `Next action:` naming `po-gate findings-shape` → stop for a human with the cause that `Next action:` gives, the way `## Outcome` of `/po-review` words it: the reviewer's findings failed their shape twice, or the check could not run (exit <n>). No fix run is spent, since nobody faulted the code (ADR-0094, ADR-0096)."
   - Leave `:78` byte for byte.
   - Test: `test_orchestrator_stops_on_shape_block` fails if the paragraph is missing, comes after "Any other blocked review", or drops "as `/po-review` says".
2. [x] **Orchestrator Stage 5 and the stop list.**
   - In `:59`, after "nor does one blocked on QA evidence", add ", nor one blocked on findings shape, which stops for a human as stage 7 says". The phrase "a review blocked on QA never triggers the fix run" stays whole.
   - In `:35`, add "a review blocked on findings shape at stage 7" to the list of human stops, before "the fix runs spent at stage 7".
   - Test: the same function asserts "nor one blocked on findings shape" inside `## Stage 5 — Execute`.
3. [x] **`/po-flow` Fix loops** (`method/commands/po-flow.md:90`, one line).
   - Right after "since `/po-flow` runs no QA itself (ADR-0041)." and before "Any other `Ship allowed: no`", insert: "A review with `Review status: blocked` and a `Next action:` naming `po-gate findings-shape` → stop and hand the story to a person with the cause that `Next action:` gives, the way `## Outcome` of `/po-review` words it: the reviewer's findings failed their shape twice, or the check could not run (exit <n>); no fix run is spent."
   - Everything else on the line stays byte for byte, the QA stops and "neither spends a fix run" included.
   - Test: `test_flow_stops_on_shape_block` fails if the clause is missing from the Fix loops line or comes after "Any other `Ship allowed: no` → a fix run of the implementer".
4. [x] **`tests/resume-shape-stop.test.sh`** — header comment `# s145 — …`, local `section_of`/`holds` as in `tests/qa-fleet.test.sh:12-14`, and two functions.
   - `test_orchestrator_stops_on_shape_block`: `S7=$(section_of "$ORCH" 'Stage 7 — Review')`. Then:
     - holds "Delegate to `reviewer` the way `/po-review` does";
     - holds "as `/po-review` says";
     - holds the marker "`Review status: blocked` and a `Next action:` naming `po-gate findings-shape` → stop for a human";
     - holds "the check could not run (exit <n>)";
     - order: the line number of the marker in the file (`grep -nF`) is less than the line number of "Any other blocked review → back to stage 5 as a fix run";
     - holds "nor one blocked on findings shape" in `section_of "$ORCH" 'Stage 5 — Execute'`.
   - `test_flow_stops_on_shape_block`: `line=$(grep -F '3. **Fix loops**' "$FLOW")`. Then:
     - holds the marker "`Next action:` naming `po-gate findings-shape` → stop";
     - holds "the check could not run (exit <n>)";
     - holds "Any other `Ship allowed: no` → a fix run of the implementer";
     - order inside the line: `${line%%Any other \`Ship allowed: no\`*}` (the prefix before the catch-all) holds the marker.
   - Run `bash tests/run.sh resume-shape-stop.test.sh`.
5. [x] **Full suite** once, through `po-run --story s145-resume-shape-stop --label test -- 'bash tests/run.sh'`. The files pinned in the research's Traps (pilot, model-routing, qa-fleet, flow, resume) must stay green with no edit.

## Scene viewpoints
—

## Run interdicts
- `git diff main...story/s145-resume-shape-stop --stat` lists only these files:
  - `method/commands/po-orchestrator.md`
  - `method/commands/po-flow.md`
  - `tests/resume-shape-stop.test.sh`
  - `docs/research/s145-resume-shape-stop.md`, `docs/plans/s145-resume-shape-stop.md`, `docs/verif/s145-resume-shape-stop.md`
- These files are not touched: `method/commands/po-review.md`, `po-drive.md`, `po-execute.md` (its `:26` gap goes to an issue, not here), `method/hooks/po-gate.sh`, `.claude/`, `.polype/`, every ADR, every existing test file.
- The blocked report and its `Next action:` lines are cited by reference to `/po-review`, never copied as a new report format. No new `Next action:` wording appears in either file.
- `po-orchestrator.md:78` and the catch-all sentence of `po-flow.md:90` stay byte for byte. The QA sentences of both files stay byte for byte too (`tests/qa-fleet.test.sh` pins them).
- No line pairs `Next action:` with `/po-qa` without `Review status: blocked` (`tests/qa-fleet.test.sh:146-151`).
- No ADR is written: the rule is ADR-0094/ADR-0096's, applied to two more commands. Reserved ADR-0098 stays unused.

## The pivot
The plan treats the stop as a **routing rule in each command**, placed before its catch-all, and does not rely on `po-review.md:39`'s inheritance sentence. It could be wrong in three ways:
- **Stage 5 left uncovered.** A rerun reaches `:59` before Stage 7. Compare with #123's title ("on resume"); task 2 handles it.
- **`/po-execute` precondition 6** (`po-execute.md:26`) still starts a fix run when `/po-execute` is run alone on a shape-blocked review. Stage 5 and `/po-flow` Execute apply those preconditions. The orchestrator is protected by its own Stage 5 clause. `/po-flow` reruns its Execute only after its own Fix loops decide. A direct `/po-execute` stays exposed, outside `Owns` → issue.
- **Wording drift.** A message that paraphrases the cause instead of naming `## Outcome` of `/po-review` would let the two diverge later. The reviewer compares the new sentences with `po-review.md:46`.

## Files touched
- `method/commands/po-orchestrator.md` (lines 35, 59, 70, new paragraph before 78)
- `method/commands/po-flow.md` (line 90)
- `tests/resume-shape-stop.test.sh` (new)

## Test strategy
Two tests, one per criterion, named after them; budget 25.
- `test_orchestrator_stops_on_shape_block` pins the Stage 7 clause, its order before the catch-all, the recording phrase, and the Stage 5 exemption. Bites: removing the paragraph, moving it below `:78`, or removing "as `/po-review` says" turns it red.
- `test_flow_stops_on_shape_block` pins the clause and its position before the catch-all on the same line. Bite: removing the clause or moving it after "Any other" turns it red.
- No behavioural test is possible: these are prompts that no harness executes. The gate's own exits are already tested by `tests/review-findings-shape.test.sh:128`.
- No visual check.

## Done when
- Both criteria tested and green, the full suite green through `po-run`.
- One commit on `story/s145-resume-shape-stop` carrying the code, the research and the plan.
- A review with no open critical finding, then the ship through a pull request.
