# Review — s179-ship-files-the-other-findings

[Story](../stories.md) · [Plan](../plans/s179-ship-files-the-other-findings.md) · [Verification](../verif/s179-ship-files-the-other-findings.md)

Method version: 0.2.0

Review status: complete
Reviewed tree: 8452878e24d31519d756c8d5f7cb8b2b6ac25c31
Fix loop: 0
Lenses run: none

## Scope
Changed paths per `git diff --name-status main...story/s179-ship-files-the-other-findings`:
- `method/commands/po-ship.md`, `po-drive.md` and `po-retro.md`, `tests/ship-files-the-other-findings.oracle.test.sh`, `tests/everything-in-issues.test.sh`, `tests/intake-issue-becomes-a-story.oracle.test.sh`, and the `superseded-by` line of `docs/decisions/ADR-0090-…`: all inside `Owns` (`docs/decisions/` is owned).
- `docs/decisions/ADR-0124-…` (status A) is named by the plan.
- Research, plan and verif are pipeline evidence for this story.

Nothing is outside `Owns`. No other story worktree is running: `git worktree list` shows main and s179 only.

## Evidence relied on
- `po-gate verif-current` exit 0. The record is complete, and the unit suite `bash tests/run.sh` exited 0 on code equal to `Tree:` outside `docs/`. Typecheck is `—`. I did not rerun the suite (`Verification mode: record`).
- `po-gate oracle-intact` exit 0. The one oracle change, the ADR-0090 line at `intake-issue-becomes-a-story.oracle.test.sh:122`, is declared in `## Oracle changes`. It does not weaken the criterion, and the body checksum assertion at `:124` is kept.
- `po-gate floor-guard … main` exit 0. Two `holds` were removed from `test_security_goes_to_the_person`. Plan task 5 justifies this: the clause they pinned is deleted on purpose.
- Bite 1: I appended 3 words to `method/commands/po-ship.md` and ran `ship-files-the-other-findings.oracle.test.sh`. 1 test of 1 failed (`words_hold`). Restored, `git diff --exit-code` clean.
- Bite 2: I reverted the `superseded-by` line of ADR-0090 to `[ADR-0099, ADR-0123]` and ran `intake-issue-becomes-a-story.oracle.test.sh`. 1 test of 6 failed. Restored, `git diff --exit-code` clean.

## Model-read criteria, judged by reading
- **`other_findings_are_filed_again`: holds.**
  - `po-ship.md:99` no longer holds a whole review because its `Lenses run:` names security.
  - Pivot case: an item `- major — [security] — …` is first picked up by "Which findings" (`:88`). The bullet at `:99` then excludes it explicitly: "A finding marked `[security]` … is not filed, whatever lens ran". This override comes after the tracker bullets, the same structure `main` already had.
  - A finding with no mark whose text bears on security ("a secret or a token, an authorization or tenant check, an injection") is still held.
  - The `Security findings:` line is quoted as written and its decision is never opened. No `po inbox` call was added to `po-ship.md`, `po-drive.md` or `po-retro.md`.
  - The count line (`po/src/record/mod.rs:250,268`) opens with no severity word, so the net at `:89` does not catch it.
- **`nothing_private_in_what_ship_writes`: partly.** Issues never receive a held finding. The decisions log and the drive report gained the decision-id wording. The PR body summary carries no exclusion (finding 1).
- **`retro_counts_what_it_cannot_read`: holds.** `po-retro.md:37` counts n security findings from the line and says their severities are unknown; the output column at `:49` adds `security`.

## Words cut, checked line by line against `main`
- `po-drive.md:74`, cut "the wave report says that no human read it": still stated at `po-drive.md:112` ("the plans were approved without a human reading them").
- `po-retro.md:25`, cut the `Correctifs hors jalon` example: the rule survives in step (a), exact whole-title match, together with "the first step that matches anything decides".
- `po-ship.md:99`: the only rule removed is the lens hold, on purpose, per ADR-0124.

No other rule was lost. Word counts: po-ship 3301 (main 3302), po-drive 2478 (2483), po-retro 974 (976), AGENTS.md 3739 (3739).

## ADR
- ADR-0124 is `accepted`, records option A and d-0023, and has `supersedes: [ADR-0090]`.
- ADR-0090's diff is one frontmatter line. Its body is byte-identical: the cksum assertion at `intake-issue-becomes-a-story.oracle.test.sh:124` passes in the record and failed only on my deliberate mutation of the frontmatter line, not the body.

## Tests
- Oracle: `po-gate oracle-intact s179-ship-files-the-other-findings` → exit 0

## Findings
- major — method/commands/po-ship.md:75 — The PR body still asks for "a findings summary" with no exclusion. A `[security]` item left in the review by a `po` that does not split them (the installed 0.2.0), or an unmarked finding whose text bears on security, can be summarised into the public PR body. Criterion `nothing_private_in_what_ship_writes` and ADR-0124 ("la pull request … ne portent d'un constat de sécurité que son compte et l'identifiant de sa décision") require that only the count line reach it. Today this exposes nothing the committed review does not already show, so it is contained. The fix: say the summary leaves out every finding the `:99` hold covers.
- minor — method/commands/po-drive.md:103 — "a security finding as its decision id alone" assumes every security finding has a decision id. A finding held by its text alone, or one marked `[security]` under a `po` that does not split, has none, and the sentence does not say what such a row carries. The same gap is at `:110`, where "the findings not filed and why" can relay the text of such a held finding into the drive report.
- minor — method/commands/po-ship.md:75 — The wording differs from the replacement text plan task 2 gave ("a findings summary" for "a summary of the findings"), one word shorter. The meaning is unchanged and it stays under the ceiling.

## Not verified
- How a model actually applies `po-ship.md:99` and its ordering against `:88`, on a live ship with a `[security]` item and with a `Security findings:` line. Nothing executes this prose; the three criteria are `po-eval` candidates (#208). A person should run `/po-ship` on a throwaway review holding both shapes, or wait for the control arm.
- The full suite was not rerun: I relied on the record. Only the two oracle files touched by the bite proofs were run.
- No QA, E2E or build stage applies (`QA stage: —`, `E2E stage: —`, `Build stage: —`).

## Other remarks
I judged none of the findings above to be a security finding in the sense of `po-ship.md:99`. They concern where the method routes text and name no secret, token, authorization check or injection. So they are written in full, and there is no private section.

Max severity: major
Ship allowed: yes

Method version: 0.2.0

Review status: complete
Reviewed tree: 529cb484d509cfa26be95d109214278c09dfd220
Fix loop: 1
Lenses run: none

## Scope
I listed the changed paths with `git diff --name-status main...story/s179-ship-files-the-other-findings`:
- `method/commands/po-ship.md`, `po-drive.md` and `po-retro.md` are inside `Owns`.
- `tests/ship-files-the-other-findings.oracle.test.sh`, `tests/everything-in-issues.test.sh` and `tests/intake-issue-becomes-a-story.oracle.test.sh` are inside `Owns`.
- ADR-0090's `superseded-by` line is inside `Owns`, which lists `docs/decisions/`.
- ADR-0124 (status A) is named by the plan.
- The research, plan and verification record are this story's own evidence.

Nothing is outside `Owns`. Since fix loop 0 the diff has grown by one commit, `3ea48f0`, which touches only `po-ship.md`, `po-drive.md` and the record. Another story's worktree is running, `story/s180-record-review-loose-ends`, which is not merged into `main`. Its `Owns` (`po/src/record/`, `po/Cargo.*`, `bin/polype`, three of its own test files) does not overlap this diff.

## Evidence relied on
- **`po-gate verif-current`: exit 0.** The record is complete. The `Unit suite` row on tree `ac645eb…` exited 0. Typecheck is `—`. I did not rerun the full suite (`Verification mode: record`).
- **`po-gate oracle-intact`: exit 0.** The only oracle change is still the declared ADR-0090 line expectation.
- **`po-gate floor-guard … main`: exit 0.**
- **Bite.** I appended 3 words to `method/commands/po-ship.md`, which sits at its 3302 baseline after the fix. `ship-files-the-other-findings.oracle.test.sh` then failed 1 of 1 (`words_hold`: "holds 3305 words, more than the 3302"). I restored the file and `git diff --exit-code` was clean. A one-word append to `po-drive.md` (2482 ≤ 2483) correctly passed, and that file was also restored and checked clean.
- **Neighbour tests.** `drive.test.sh`, `grouped-validation.test.sh`, `everything-in-issues.test.sh` and `review-findings-shape.test.sh` ran: 29 passed, 0 failed.
- **Word counts with `LC_ALL=C wc -w`:**

| File | Now | `main` | Before the fix |
| --- | --- | --- | --- |
| `po-ship.md` | 3302 | 3302 | 3301 |
| `po-drive.md` | 2481 | 2483 | 2478 |
| `po-retro.md` | 974 | 976 | 974 |
| `method/AGENTS.md` | 3739 | 3739 | 3739 |

All four are at or under baseline. `po-drive.md` stays under the 2500 ceiling of `drive-executes-next`.

## Findings from fix loop 0
- **major, `po-ship.md:75`: resolved.** The PR body now asks for "a findings summary without any finding Step 3 holds, and any `Security findings:` line as written". "Step 3 holds" points to the "Security stays with the person" bullet at `:99`, which is in Step 3 item 2, so the reference resolves. It covers `[security]` items left in place by a `po` that does not split them, and unmarked findings whose text bears on security. It also leaves out the other held items (shape not recognised, critical not marked fixed). That is more cautious and loses nothing that may be published.
- **minor, `po-drive.md:103` / `:110`: mostly resolved.**
  - `:110` now says "(a security one never by its text)", which closes the path by which held text could be relayed into the drive report.
  - `:103` now says "a security finding as its decision id, never its text", so no text can leak into the log.
  - What remains: `:103` still assumes a decision id exists. That is re-listed below as a narrower minor.
- **minor, `po-ship.md:75`, wording differs from plan task 2: superseded, not re-listed.** The fix for the major rewrote that clause on purpose. The gap from the plan's text now comes from a review finding, not from drift.

## Words cut by the fix, checked line by line against `669057e`
- **`po-ship.md:69`**, "listing the conflicting paths it printed" became "listing the conflicting paths". The paths can only come from the `merge-tree` output named in the same sentence. No rule was lost.
- **`po-ship.md:74`**, "already has" became "has". The three-way condition for skipping the push (parent, tree, message) is unchanged. "already" carried no condition.
- **`po-ship.md:74`**, "that differs" became "differing". Same meaning.
- **`po-ship.md:82`**, "Then `git merge --ff-only <sha>`" became "`git merge --ff-only <sha>`". The preceding sentence still ends "otherwise stop", so the merge still follows the check. The order is kept by sentence order.
- **`po-drive.md:103`**, ", and leaves none of them out" was cut. This clause sat in `## The decisions log`. It was about the list of kinds of lone decision covering every kind that `AGENTS.md` names, not about the report listing held findings. Its completeness survives in "follows every kind of lone decision". No test pins either phrase.
- **The report's own rule on held findings is intact.** `po-drive.md:110` still lists "the findings not filed and why" per shipped story. `po-ship.md`'s finish (Step 3, closing paragraph) still names "the findings held for the person, with why".

No rule was lost.

## Model-read criteria, judged by reading
- **`other_findings_are_filed_again`: holds**, unchanged since fix loop 0.
  - The lens-wide hold is gone.
  - `:99` holds `[security]` items and items whose text bears on security "whatever lens ran", and quotes the `Security findings:` line without opening its decision.
  - No `po inbox` call is added to `po-ship.md`, `po-drive.md` or `po-retro.md`.
- **`nothing_private_in_what_ship_writes`: holds now.**
  - PR body: `po-ship.md:75`.
  - Issues: `:99`.
  - Decisions log: `po-drive.md:103`.
  - Drive report: `po-drive.md:110`.
  - Each now excludes the text of a security finding.
- **`retro_counts_what_it_cannot_read`: holds.** The fix did not touch `po-retro.md`.

## ADR
The fix did not touch ADR-0124 or ADR-0090. ADR-0090's body checksum assertion still passes in the record.

## Tests
- Oracle: `po-gate oracle-intact s179-ship-files-the-other-findings` → exit 0

## Findings
- minor — method/commands/po-drive.md:103 — "a security finding as its decision id, never its text" still assumes every security finding has a decision id. A finding held for its text alone, or one marked `[security]` under a `po` that does not split them, has none, and the sentence does not say what such a row carries. No text can leak (the fix forbids that), so this is only an unspecified case.

## Not verified
- How a model actually applies `po-ship.md:75` and `:99`: whether it leaves held items out of the PR summary, and whether it quotes the `Security findings:` line without opening the decision. The same goes for `po-drive.md:103`/`:110` in a real wave report. Nothing runs this prose, and all three criteria are `po-eval` candidates (#208). To cover it, a person should run `/po-ship` and one `/po-drive` wave on a throwaway review that holds a `[security]` item, an unmarked security-flavoured item and a `Security findings:` line.
- I did not rerun the full suite and relied on the record. I ran only the oracle file used for the bite and four neighbour test files.
- No QA, E2E or build stage applies (`QA stage: —`, `E2E stage: —`, `Build stage: —`).

## Other remarks
None of the findings above is a security finding in the sense of `po-ship.md:99`. They are about where the method routes text and name no secret, token, authorization check or injection. So nothing is held privately. I re-took the tree just before answering and it is unchanged (`529cb484…`).

Max severity: minor
Ship allowed: yes
