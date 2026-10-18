# Review — s145-resume-shape-stop

[Story](../stories.md) · [Plan](../plans/s145-resume-shape-stop.md) · [Verification](../verif/s145-resume-shape-stop.md)

Diff reviewed: `git diff main...story/s145-resume-shape-stop`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 9bd912e30bccee998d07131eae0710daea9f1209

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Ownership
Diff listed with `git diff --name-only main...story/s145-resume-shape-stop`, each path held against the story's `Owns` by the overlap rule of the `review-antihallu` skill.
- [x] Every path inside `Owns`: `method/commands/po-orchestrator.md`, `method/commands/po-flow.md` and `tests/resume-shape-stop.test.sh` are each a file entry of `Owns`. `docs/research|plans|verif/s145-resume-shape-stop.md` are the story's own pipeline evidence.
- [x] Outside `Owns`: none
- [x] Inside another running story's `Owns`: none. The only other running worktree is s143-payload-edit-not-spread, which owns `bin/polype`, `docs/installation.md` and `tests/payload-edit-not-spread.test.sh`. None of them overlaps this diff.
- [x] The story has an `Owns` line

## Evidence reused
- [x] `po-gate verif-current s145-resume-shape-stop` → exit 0, record reused. The record is complete and its unit suite `bash tests/run.sh` exited 0, on a tree whose code outside `docs/` equals the reviewed code. The project has no type check (`Typecheck: —`), no end-to-end command and no build. Its "Not proven here" section says no harness runs the method text, so the stop itself is checked by reading. It also says a direct `/po-execute` is out of scope; that point is carried to Not verified.
- [x] `po-gate qa-current`: not required. `QA stage: —`, so the story does not go to QA.

## Plan
- [x] Tasks 1–4 are present as written:
  - Stage 7 recording clause, at `po-orchestrator.md:70`.
  - New "Blocked on findings shape" paragraph, placed before the catch-all at `po-orchestrator.md:78`.
  - Stage 5 exemption, at `po-orchestrator.md:59`.
  - Stop-list entry, at `po-orchestrator.md:35`.
  - `/po-flow` Fix loops clause, placed before "Any other `Ship allowed: no`" at `po-flow.md:90`.
  - The test file.

  Task 5 (full suite through `po-run`) is recorded. Nothing outside the plan.
- [x] Run interdicts, checked one by one:
  - Only the listed files changed.
  - `po-review.md`, `po-drive.md`, `po-execute.md`, `po-gate.sh`, `.claude/`, `.polype/`, the ADRs and the existing tests are untouched.
  - No new `Next action:` wording: both files cite `## Outcome` of `/po-review` by reference.
  - The catch-all sentences are byte for byte: the diff leaves orchestrator "Any other blocked review → back to stage 5 as a fix run…" and the `/po-flow` "Any other `Ship allowed: no` → a fix run…" span intact.
  - The QA sentences are unchanged.
  - No `Next action:` + `/po-qa` pairing was added.
  - No ADR was written.

## References
- [x] Every reference opened and confirmed:
  - `po-review.md:39` defines both blocked reports. Their `Next action:` lines contain "po-gate findings-shape", so the marker the new routing keys on matches both the twice-failed case and the could-not-run case.
  - `po-review.md:39` ends with "Any command that records a review 'as `/po-review` says' applies this check and its stop before its own fix-loop rules". Stage 7 now uses that phrase.
  - `po-review.md:46` (`## Outcome`) gives the cause wording "the reviewer's findings failed their shape twice, or the check could not run (exit <n>)". Both new sentences match it word for word, which answers the plan's pivot on wording drift.
  - ADR-0094 and ADR-0096 exist under `docs/decisions/`.
  - `po-drive.md:63` holds the same routing, so the three drivers agree.
  - Both commands' frontmatter grants unrestricted `Bash`, so the `findings-shape` call the inherited recording needs is allowed.
- [x] No value that only looks right: the marker string and the cause wording both trace to `po-review.md`.

## Rules
- [x] `AGENTS.md` conventions respected:
  - Method text is in English.
  - The test is in bash, named after the criteria, and uses `fail` from `tests/lib.sh`.
  - The local `section_of`/`holds` helpers follow the existing pattern in `tests/qa-fleet.test.sh:12-14`.
- [x] No accepted ADR contradicted: the change applies the ADR-0094/ADR-0096 stop to two more commands.

## Tests
- [x] Floor: `po-gate floor-guard s145-resume-shape-stop main` → 0, nothing lowered.
- [x] Assertions pin the acceptance criteria: the clause, its order before the catch-all, the delegation phrase, the recording phrase and the Stage 5 exemption. None of the six empty test shapes appears. The tests read the real method files, with no fixture or mock.
- [x] Within `Test budget`: 2 tests, budget 25.
- [x] Bite 1: deleted the "Blocked on findings shape —" paragraph of `po-orchestrator.md`, then ran `resume-shape-stop.test.sh` → 1 failing test (`orchestrator_stops_on_shape_block`). Undone with `git checkout --`; `git diff --exit-code` is clean.
- [x] Bite 2: removed the findings-shape clause from the `/po-flow` Fix loops line, then ran `resume-shape-stop.test.sh` → 1 failing test (`flow_stops_on_shape_block`). Undone; `git diff --exit-code` is clean.
- [x] No test made useless by the story.

## Neighbours
- [x] Other places that route a shape-blocked review were read:
  - `po-drive.md:63` and `:138` already stop on it.
  - `po-review.md:46` holds the outcome wording.
  - `po-execute.md:26` (precondition 6) still treats any `Ship allowed: no` other than the QA cases as a fix run. Both commands in this story are protected by their own clauses: orchestrator Stage 5, and `/po-flow` reaches Execute again only after its Fix loops decide. A direct `/po-execute` stays exposed. That gap is outside this story's `Owns`, and the plan defers it to an issue, so it is not a finding on this diff.

## Lenses
Lenses run: none. The diff touches markdown method files and a bash test only; no security, migration, dependency or performance trigger.

## Findings
- none

## Not verified
- What an agent actually does: no harness executes `/po-orchestrator` or `/po-flow`, so the stop was checked by reading and by string tests, not by watching an agent hit a shape-blocked review. To cover it, a person can run `/po-orchestrator` on a throwaway story whose recorded review ends with the `po-review.md:39` blocked report (Next action naming `po-gate findings-shape`), and confirm it stops with no implementer dispatch.
- A direct `/po-execute <id>` on a shape-blocked review still starts a fix run (`method/commands/po-execute.md:26`), outside `Owns`. The plan says it goes to an issue. I did not confirm the issue was filed in `Issue tracker: github`; the lead should check and file it if it is missing.

Max severity: none
Ship allowed: yes
