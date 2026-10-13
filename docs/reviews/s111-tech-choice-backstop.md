# Review — s111-tech-choice-backstop

Diff reviewed: `git diff main...story/s111-tech-choice-backstop`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 87047c8f19f4dce7f600f1bc0d00b30eb168c720

The tree has not changed since the first answer: it is still the same hash. The substance is unchanged; only the template layout and the `Review status:` line are new.

## When blocked
Not blocked.

## Ownership
Diff listed with `git diff --name-only main...story/s111-tech-choice-backstop`.
- [x] Every path inside `Owns`:
  - `method/commands/po-flow.md`
  - `tests/conversational-framing.test.sh`
  - `tests/escalation-contract.test.sh`
  - `tests/tech-choice-backstop.test.sh`
  - plus the story's own research, plan and verif files, which are in scope by construction.
- [x] `method/commands/po-plan.md` is owned and its diff is empty, as the plan's run interdict asks.
- [x] Outside `Owns`: none.
- [x] Inside another running story's `Owns`: none. s110 (worktree `.worktrees/s110-framing-second-landing`) owns `method/commands/po-setup.md` and `tests/framing-second-landing.test.sh`, and neither overlaps.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s111-tech-choice-backstop` passes (exit 0), so the record is reused under `Verification mode: record`. The `Unit suite` row (`bash tests/run.sh`) exited 0 on code equal to this tree.
- [x] The project has no type check, E2E or build command (`—`).
- [x] `po-gate qa-current`: not required, because the story does not go to QA (`QA stage: —`, `Surface: —`).

## Plan
- [x] Tasks 1–4 are present as written:
  - the po-flow clause now comes before the `human`/`autonomous` bullets, with its four steps (a)–(d) and the closing sentence;
  - `ADR directory` was added to `Reads settings:`;
  - the two existing tests were tightened only on the lines the plan allowed;
  - the new test file holds the three criterion tests.
- [x] Run interdicts, one by one:
  - po-plan.md diff empty;
  - plan-flow.md, po-orchestrator.md, po-drive.md, planner.md, po-stories.md, po-stories-review.md and adr-directory.test.sh all have an empty diff;
  - `.claude/`, `.polype/`, `AGENTS.md` and `AGENTS.local.md` untouched;
  - no ADR written;
  - po-flow's second signal check (:46-48) kept word for word;
  - mutants only under mktemp;
  - no new setting and no new gate.

## References
- [x] Headings `## Approval` (po-flow), `## Approval — per \`Plan validation\``, `## Checks first` and `## Writing the plan` (po-plan) exist.
- [x] `ADR directory` exists as a setting, and po-flow never writes the literal `docs/decisions/`.
- [x] po-flow has `Write` in its allowed tools, which it needs to draft the ADR.
- [x] The `templates/adr.md` reference and `## Ranking the options` of `capability-bricks` are consistent with po-plan.md:45.
- [x] No value that only looks right.

## Rules
- [x] `AGENTS.md` conventions respected: English method text, bash tests in the story's own file, and no settings name outside the template.
- [x] No accepted ADR contradicted. Drafting the ADR as `status: proposed` before the person decides matches po-plan.md:45 and the escalation rules.

## Tests
- [x] Floor: `po-gate floor-guard s111-tech-choice-backstop main` → 0, nothing lowered.
- [x] The assertions pin down the criteria, and none has one of the six empty test shapes. The mutants are proven to apply by line-count and phrase-absent assertions.
- [x] Within `Test budget` 25: three new tests and two tightened ones.
- [x] Bite, run only on the relevant test files. Each mutation was undone afterwards, and `git diff --exit-code` came back clean:

| Mutation | Failing tests |
| --- | --- |
| Removed the po-flow bullet that writes the marker | 1 (`flow_plan_sent_back_keeps_the_marker`) |
| Moved the po-flow clause back after the bullets | 1 (the ordering assertion) |
| Removed the po-flow bullet "name that ADR in the plan." | **0** (finding 1) |
| Removed the po-plan.md:50 Approval paragraph | 1 (`plan_with_a_tech_choice_waits_for_a_human`) |
| Removed the "has already started" refusal in po-stories.md | 1 (`stories_review_surfaces_criticals_only`) |

- [x] No test was made useless by the story.

## Neighbours
- [x] po-orchestrator.md:45 reuses the worktree on escalation, and :54 reads the marker before either validation bullet.
- [x] po-plan.md:30 skips to Approval when a plan exists, and :50 acts on the marker.
- [x] Nothing is broken.

## Lenses
Lenses run: none (the diff is method prose and bash tests only, so no trigger path or content)
- [x] No lens findings.

## Findings
- minor — `method/commands/po-flow.md` `## Approval`, the bullet "name that ADR in the plan." — deleting it fails no test (mutation 3, zero failures). The plan's own pivot names this as the first way the fix can go wrong ("The ADR is not findable"). The plan only asked for a check by reading, so this is not a breach of the plan, but the rule is untested.
- minor — `method/templates/plan-flow.md:13` — still says "Any signal present means this file should not exist", while po-flow now keeps the file, with the marker, on purpose. This is an inconsistency between two method files. It is outside `Owns` (s113 owns it next) and the research records it. Contained, because the command's clause is explicit.
- minor — `tests/tech-choice-backstop.test.sh`, `test_stories_review_rules_bite` — the guard that checks the review mutant did not lose "more than the sentence" uses `Stories ready:`. That phrase is inside the deleted sentence itself and survives only because it appears 7 times elsewhere in the file. A phrase from the text next to po-stories-review.md:49 would make a sharper guard.

## Not verified
- **Runtime behaviour.** I could not check whether an agent running `/po-flow` actually writes the marker, leaves `validated: no` and drafts and names the ADR, or whether `/po-plan` then asks with the ranked options. Phrase tests cannot show runtime behaviour; the plan and the verif record say the same. A person should escalate one flow plan on a sample project over a technical choice, then run `/po-plan` under `Plan validation: autonomous` and confirm the question is asked.
- **The escalated flow plan downstream.** After escalation, the plan that continues on the full track is still a `plan-flow.md` plan (`track: flow`, `## Verified facts`), now next to a research file. I did not check how `/po-execute` and the reviewer handle that mix. Someone should read po-execute.md and the reviewer inputs for how they treat `track: flow`.
- **ADR numbering.** "The next free number" might collide with a number `/po-drive` has reserved. The research leaves this open, and I did not exercise it.
- **Full suite and lint.** These come from the record and were not rerun here.

Max severity: minor
Ship allowed: yes
