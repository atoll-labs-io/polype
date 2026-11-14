---
validated: yes
---
# Plan — s179-ship-files-the-other-findings

[Story](../stories.md) · [Research](../research/s179-ship-files-the-other-findings.md)

Branch `story/s179-ship-files-the-other-findings`. Read `docs/research/s179-ship-files-the-other-findings.md` first; this plan builds on it without repeating it.

[ADR-0124](../decisions/ADR-0124-les-constats-ordinaires-d-une-revue-de-securite-sont-deposes.md) is `accepted`: the owner chose option A on 2026-11-14 (decision d-0023). Only security findings stay held, meaning those marked `[security]` and those whose text bears on security; the others are filed. ADR-0124 supersedes accepted ADR-0090 on the lens hold, which ADR-0123 had left standing. `Owns` now lists `docs/decisions/`, for ADR-0124 and the `superseded-by` line of ADR-0090 only, and `tests/intake-issue-becomes-a-story.oracle.test.sh`, for its assertion at `:122` only (commit cdf8e7b).

## Story
`/po-ship` files the open findings of a recorded review even when the security lens ran. It cites the security findings by the `Security findings:` line alone. Nothing private reaches a PR body, an issue, `docs/decisions-log.md` or the `/po-drive` report. `/po-retro` counts security findings from that line and says it does not know their severities. Criteria: `other_findings_are_filed_again`, `nothing_private_in_what_ship_writes`, `retro_counts_what_it_cannot_read` (all three model-read) and `words_hold` (script).

## Reuse
No new code: the story rewrites prose in three method files, removes two assertions and adds one word-count oracle modelled on `tests/security-findings-stay-private.oracle.test.sh:159-167`.

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/ship-files-the-other-findings.oracle.test.sh` | `776457501 769` |

| Criterion | Test |
| --- | --- |
| `words_hold` | `test_words_hold`. Baselines: po-ship 3302, po-drive 2483, po-retro 976, AGENTS.md 3739 (`LC_ALL=C wc -w`). The existing ceilings stay in their own tests, which this story does not edit. |
| `other_findings_are_filed_again` | — model-read. No oracle and no phrase test (owner's rule, `AGENTS.local.md` `## Direction`). Judged in review; `po-eval` candidate (#208). |
| `nothing_private_in_what_ship_writes` | — same regime. |
| `retro_counts_what_it_cannot_read` | — same regime. |

## Tasks
1. [x] **`method/commands/po-ship.md:99`.** Replace the whole bullet with this text (66 words, from 71):
   `   - **Security stays with the person.** A finding marked `[security]`, or whose text bears on security — a secret or a token, an authorization or tenant check, an injection — is not filed, whatever lens ran: it goes to the person in the finish, marked "not filed: security (ADR-0077)". The `Security findings:` line is no finding: the finish quotes it as written, never opening its decision.`
   - The test that fails if this is wrong: `test_security_goes_to_the_person` (task 4) and `test_words_hold`. The rest is judged in review.
2. [x] **`method/commands/po-ship.md:75` (Step 2, PR body).** Replace `(max severity and a summary of the findings)` with `(max severity, a summary of the findings, and any `Security findings:` line as written)`. That is 13 words, from 8, so the file stays at 3302 or fewer after task 1.
   - Test: `test_words_hold`.
3. [x] **`method/commands/po-drive.md`.**
   - `:110`: replace `and the security findings held for the person.` with `and each `Security findings:` line as written.`
   - `:103`: replace `and carry their reason;` with `and carry their reason, a security finding as its decision id alone;`
   - `:74`: cut `, and the wave report says that no human read it (`## Report`)`. `:112` already says it, and `tests/grouped-validation.test.sh:45` pins it there.
   - Net −6, to 2477.
   - Tests: `test_words_hold`, `tests/drive.test.sh`, `tests/grouped-validation.test.sh` and `tests/drive-executes-next.oracle.test.sh` (≤ 2500) stay green.
4. [x] **`method/commands/po-retro.md`.**
   - `:37`, row **severities per story**: after `counts as unrated`, add `; a `Security findings: <n>` line counts n security findings, their severities unknown and said so`.
   - `:49`: `findings critical/major/minor of the last review` becomes `findings critical/major/minor/security of the last review`.
   - `:25`: cut `; an exact title such as `Correctifs hors jalon` wins over a longer heading that starts with it`, and end the sentence after `exists`. Step (a) states that rule already.
   - Net −2, to 974.
   - Tests: `test_words_hold`, `tests/commands-read-po-state.test.sh:36` (`-lt 977`), `tests/po-retro.test.sh` and `tests/commands-and-texts.test.sh:10-24` stay green.
5. [x] **`tests/everything-in-issues.test.sh:75-83`, `test_security_goes_to_the_person`.** Remove the two `holds` at `:78-79` ('A review whose `Lenses run:` line names the security lens', 'a line that starts with `none` does not'): the story deletes that clause. Keep `:80` and `:81-82`. No phrase replaces them (owner's rule: a model-read rule gets no phrase test).
   - Add ADR-0124 to `superseded-by` of ADR-0090, giving `superseded-by: [ADR-0099, ADR-0123, ADR-0124]`, body untouched. Update the expected line in `tests/intake-issue-becomes-a-story.oracle.test.sh:121-122` to match, and change nothing else in that file.
   - Tests: the edited tests themselves.
6. [x] **Full suite**, once, through `po-run --story s179-ship-files-the-other-findings --label 'Unit suite' -- 'bash tests/run.sh'`. `Typecheck` is `—`.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `po/`, `bin/`, `method/AGENTS.md`, `method/agents/`, `method/templates/`, `method/skills/`, `method/hooks/`, every other `method/commands/*.md`, `docs/reviews/`, `docs/decisions/ADR-0123-*`.
- Empty diff for every test outside `Owns`. In `docs/decisions/`, only ADR-0124 (already written) and ADR-0090's `superseded-by` line change; in `tests/intake-issue-becomes-a-story.oracle.test.sh`, only the `:121-122` expectation. In particular, no ceiling number moves in `tests/drive-executes-next.oracle.test.sh`, `tests/commands-read-po-state.test.sh`, `tests/answer-comes-back.test.sh` or `tests/decision-inbox.test.sh`.
- `po-ship.md:87-98` unchanged. Its net, title/body commands and tracker rules are pinned by `tests/review-findings-shape.test.sh:91-94` and run by `cut_finding`.
- No `po inbox`, `po inbox <id>` or decision file read added to `po-ship.md`, `po-drive.md` or `po-retro.md`. They cite the count line, never the decision's context.
- No witness or security text in any file. ADR-0090's body is unchanged, and its sum is checked by `tests/intake-issue-becomes-a-story.oracle.test.sh:124`.
- `po-ship.md`, `po-drive.md`, `po-retro.md` and `method/AGENTS.md` stay at or under their baselines.

## The pivot
Everything rests on this: once the reviewer marks every security finding (`method/agents/reviewer.md:55`) and `po record review` takes the marked text out, a review's ordinary findings no longer reveal anything, so holding the whole review is no longer needed. It could be wrong three ways:
1. **A `po` that does not split.** The one installed on this machine does not. The marked text then stays in the public review. Task 1 holds every `[security]` item by its mark, and the reviewer checks that an item `- major — [security] — …` falls under the hold, not under "Which findings".
2. **A security finding the reviewer did not mark.** It is held only if its text shows it. ADR-0124 writes this cost down. Compare it with s177's two lens-review findings (`docs/reviews/s177-intake-follow-ups.md:65`, `:71`): neither bears on security, so both would now be filed.
3. **The count line read as a finding, or missed.** It does not open with a severity and holds none of the three words, so the net of `:88` skips it. Task 1 makes the finish quote it. Check that no sentence makes ship open its decision.

## Files touched
`method/commands/po-ship.md`, `method/commands/po-drive.md`, `method/commands/po-retro.md`, `tests/everything-in-issues.test.sh`, `tests/ship-files-the-other-findings.oracle.test.sh` (written, sum above), `docs/decisions/ADR-0124-…md` (written by the planner, accepted), `docs/decisions/ADR-0090-…md` (`superseded-by` only), `tests/intake-issue-becomes-a-story.oracle.test.sh` (`:121-122` only). `method/AGENTS.md` stays unchanged: Law 7's sentence (`:129`) remains true.

## Test strategy
- Automated:
  - One oracle test, `test_words_hold`. It would fail if any of the four files grew.
  - One existing test edited, `test_security_goes_to_the_person`, because its clause is deleted.
  - The ADR-0090 line assertion is updated.
  - That is 1 new test, well within `Test budget` 25.
- No phrase test for the three model-read criteria: owner's rule of 2026-11-13. The reviewer judges them by reading, and all three are `po-eval` candidates (#208). The `diagnostic` skill's "test that would have caught the defect" would be a phrase test here, and that rule wins over it.
- The full suite runs once, at task 6.
- Visual checks: none.

## Done when
- One commit `s179-ship-files-the-other-findings: …` landed through a pull request.
- `bash tests/run.sh` green.
- A review with no open critical finding.
- ADR-0090's `superseded-by` names ADR-0124.
