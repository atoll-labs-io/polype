# Research — s145-resume-shape-stop

[Story](../stories.md)

## Structuring facts
- **Root cause (#123, #125).** Neither command has a branch for a review whose `Next action:` names `po-gate findings-shape`, so their catch-alls take it: `method/commands/po-orchestrator.md:78` ("Any other blocked review → back to stage 5 as a fix run") and `method/commands/po-flow.md:90` ("Any other `Ship allowed: no` → a fix run of the implementer"). Input: the blocked report `po-review.md:39` appends after a second exit 1, or after any other exit (s144). Proof: `grep -n findings-shape` on both files prints nothing; only `po-drive.md:63` routes that report to a human.
- **Incomplete story assumption: Stage 7 is not the only place the orchestrator decides a fix run.** On a rerun, the orchestrator walks the stages again (research reused at `:48`, validated plan skipped at `:54`) and reaches Stage 5 first. There, `po-orchestrator.md:59` starts "a fix run when the latest review blocks the story on findings" and exempts only reviews blocked on QA and on QA evidence. A shape-blocked review on disk therefore still gets a fix run before Stage 7 is ever read. That is #123's own title ("on resume"). The story's criterion names only Stage 7; the plan also covers `:59`, which is inside `Owns`. The lead should add Stage 5 to the criterion in `docs/stories.md`.
- Stage 7 records "with its `Fix loop:`" (`po-orchestrator.md:70`), not "as `/po-review` says". So `po-review.md:39`'s last sentence ("Any command that records a review "as `/po-review` says" applies this check and its stop before its own fix-loop rules") does not clearly bind the orchestrator, and the shape check may never run there. `/po-flow` already says it (`po-flow.md:89`).
- The two causes and their wording already exist and are not to be rewritten here. The report: `po-review.md:39` (`Next action: a person settles the findings shape — po-gate findings-shape <id> refused the reviewer twice`, or `Next action: a person runs po-gate findings-shape <id> — the check could not run (exit <n>)`). The message to the person: `po-review.md:46`.
- Gap outside `Owns`: `method/commands/po-execute.md:26` still starts a fix run on a shape-blocked review (it exempts only the two QA blocks). Stage 5 and `/po-flow`'s Execute both delegate "the way `/po-execute` does". Nothing files it yet; the lead files it (Law 7).

## Diagnostic
**Reproduction.** These are method text files, so the defect is reproduced by reading the routing each command applies to the blocked report, on the tree at `48eb6fe` (s144 included):
- `grep -n "findings-shape" method/commands/po-orchestrator.md method/commands/po-flow.md` → no line.
- `grep -n "findings-shape" method/commands/po-drive.md` → `:63` (resume row, a human), `:138` (recording).
- Orchestrator Stage 7, read in order on a report with `Review status: blocked` and `Next action: a person settles the findings shape …`. `:72` does not match (no `/po-qa`). `:74` does not match (no QA evidence commit). `:76` does not match. `:78` matches ("Any other blocked review") → stage 5, fix run.
- `/po-flow` "Fix loops" (`:90`), read the same way: neither QA clause matches, so "Any other `Ship allowed: no`" sends it to a fix run.

**Hypotheses**
1. *The orchestrator's catch-all at `:78` takes the shape block.* Refuted if any clause of Stage 7 or Stage 0's stop list (`:35`) routes `po-gate findings-shape` elsewhere. None does → **kept**.
2. *`/po-flow` inherits the stop through "as `/po-review` says" (`:89`), so the defect only lives in the orchestrator.* Refuted if `/po-flow`'s own rule still routes the report to a fix run. `po-review.md:39` says the inherited check runs "before its own fix-loop rules", but it puts no exception into those rules. The blocked report then lands on `:90`'s "Any other `Ship allowed: no`", the very next rule `/po-flow` reads → **discarded**. `/po-flow` needs its own clause, as #125 says.
3. *The orchestrator only goes wrong at Stage 7.* Refuted if a rerun reaches a fix run before Stage 7. `:59` does exactly that, and so do `po-execute.md:26`'s preconditions, which Stage 5 applies → **discarded**. Stage 5 needs the exemption too.

Root cause: shown above; the plan targets `:59`, `:70`, `:78` of the orchestrator and `:90` of `/po-flow`.

## Story
`/po-orchestrator` and `/po-flow` send a review blocked on its findings' shape to the person, with the cause the report gives, and spend no fix run.
- `orchestrator_stops_on_shape_block` — Stage 7 records "as `/po-review` says". The phrase "Delegate to `reviewer` the way `/po-review` does" stays as it is. Before "Any other blocked review → back to stage 5 as a fix run", a review with `Review status: blocked` and a `Next action:` naming `po-gate findings-shape` goes to the person, with no fix run.
- `flow_stops_on_shape_block` — the same in `/po-flow`'s "Fix loops", before "Any other `Ship allowed: no` → a fix run", the existing line left whole.

## Current code
- `method/commands/po-orchestrator.md:35` — the list of human stops that end the run (root cause, technical choice, QA blocked, fix runs spent). It has no shape stop.
- `:59` — Stage 5, the fix-run trigger and its QA exemptions.
- `:69-78` — Stage 7: delegation and recording (`:70`), the QA return (`:72`), the QA evidence return (`:74`), a second QA block (`:76`), the catch-all fix run (`:78`).
- `method/commands/po-flow.md:89` — Review, recorded "as `/po-review` says".
- `:90` — Fix loops: two QA stops, "neither spends a fix run …", then the catch-all, all on one line.
- Both files have `Bash` and `Agent` in `allowed-tools` (`po-orchestrator.md:4-11`, `po-flow.md:4-11`), so the gate call `po-review.md:39` asks for is possible from both.

## Attachment points
- Orchestrator `:70`: add "as `/po-review` says" to the recording clause; the delegation sentence before it stays.
- Orchestrator: a new paragraph between `:76` and `:78`, in the style of `:72`/`:74` ("Blocked on …  — `Review status: blocked` and a `Next action:` naming …").
- Orchestrator `:59`: one more exemption after "nor does one blocked on QA evidence".
- Orchestrator `:35`: the shape stop added to the list of stops.
- `/po-flow` `:90`: one clause inserted after "(ADR-0041)." and before "Any other `Ship allowed: no`", on the same line.

## Verified interfaces
- Report marker: `` `Review status: blocked` and a `Next action:` naming `po-gate findings-shape` `` — exact wording of `po-review.md:46` and `po-drive.md:63`.
- Causes: "the reviewer's findings failed their shape twice, or the check could not run (exit <n>)" — `po-review.md:46`, `po-drive.md:63`.
- Test helpers: `section_of` and `holds`, defined locally in `tests/qa-fleet.test.sh:12-14` and `tests/review-findings-shape.test.sh:10-11`. `holds` is grep -F on the section text, so it matches one line at a time. `contains`, `require_file` and `fail` come from `tests/lib.sh:11,41,43`. `$METHOD` and `$ROOT` are set by `lib.sh`.

## Traps
- Pinned phrases that must stay byte for byte, each on one line:
  - `tests/pilot.test.sh:19` and `tests/model-routing.test.sh:113`: "Delegate to `reviewer` the way `/po-review` does".
  - `tests/qa-fleet.test.sh:115-117`: "back to stage 6, then stage 7 again at the same `Fix loop:`", "spends none of the two", "two `<id>: QA evidence` commits since the last implementer commit → stop for a human".
  - `tests/qa-fleet.test.sh:118`: "a review blocked on QA never triggers the fix run" (Stage 5).
  - `tests/qa-fleet.test.sh:135-136`: "Blocked on QA — … → back to stage 6", "Blocked on QA evidence — … → that evidence commit as stage 6 makes it, without a walk".
  - `tests/qa-fleet.test.sh:159-162`: in `/po-flow`'s `## Execute, review, ship`, the two QA stops with their messages, "neither spends a fix run", and "Any other `Ship allowed: no` → a fix run of the implementer".
- `tests/qa-fleet.test.sh:146-151`: any line holding `Next action:` and `/po-qa` must also hold `Review status: blocked`. New lines must not pair `Next action:` with `/po-qa`.
- `tests/review-findings-shape.test.sh` covers `po-review`/`po-drive` only; this story does not touch them.
- No migration and no new dependency. Baseline: the seven related test files are green, 42 passed.

## Open questions
- Should `po-execute.md:26` get the same exemption? It is outside `Owns`, so it is left to a later story via an issue.

## Complexity
Story 2 → 2. Four textual insertions across two files, plus one test file. Stage 5 adds one clause, not a new mechanism.

## Split
—
