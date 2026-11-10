# Stories review: Polype, milestone "M18 — La QA va jusqu'au bout de sa marche" (s156–s157)

A one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). Done on 2026-11-10 by the `stories-reviewer` subagent, in a context that did not write the stories. The verdict is recorded verbatim; the `Not verified` list is shortened.

- **Scope source:** the milestone's Objectif paragraph, plus issues #148 (duplicate #88) and #167, with the owner decision of 2026-11-10. The issue texts reached the reviewer as the caller's summaries.
- **Platform:** `cli`.

## Loop 1

Review status: complete

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| A QA walk started by `/po-qa`, `/po-drive` or `/po-orchestrator` ends in a committed report | Objectif | s156 (`/po-qa`, `/po-drive`). `/po-orchestrator` is covered indirectly: it "applies `/po-qa` as written" (`method/commands/po-orchestrator.md:67`). Also s157 | yes (orchestrator only by reference, see minor 3) |
| `qa` returns its report as text and no longer writes `report.md` | #148, Objectif | s156 `qa_returns_its_report` | yes |
| The coordinating context writes `docs/qa/<id>/report.md` word for word, before the evidence commit | #148, Objectif | s156 `po_qa_records_the_report`, `drive_records_the_report`; orchestrator through `/po-qa` | yes |
| `qa` keeps writing its evidence files | #148, Objectif | s156 `qa_returns_its_report` | yes |
| The report path, the evidence commit and `po-gate qa-current` stay as they are | #148 (gate needs the report) | s156 `qa_report_path_stays` | yes |
| Close #88 as a duplicate when shipping | #148 | s156 (`Corrige` line and notes) | yes |
| `po-bounds` lets read-only git verbs such as `check-ignore` through in qa mode | #167, Objectif | s157 `qa_allows_check_ignore`, `qa_allows_check_attr`, `qa_still_refuses_writing_verbs` | yes |
| No overlap with s149's `Owns` (in flight) | Constraint | s156, s157 | yes |

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| Any path owned by s149 (`method/commands/po-orchestrator.md`, `method/AGENTS.md`, and the rest of its `Owns`) | Constraint / Objectif | none | no |

## Checks
- [x] Exclusions: no story revives an excluded item.
- [x] No technical layer dressed as a story.
- [x] Every criterion can be checked by one test.
- [x] Dependency order: neither story has a dependency.
- [x] Complexity: s156 is a 3 and names its risk; s157 is a 1.
- [x] Ids: unique and following s155.
- [x] Owns: s156 and s157 are disjoint, and neither overlaps any M17 story, s149 included.
- [x] Surface: both `—`, which `cli` admits.
- [ ] Owned records: superseded ADR fails, see majors 1 and 2.

## Findings
- **major — s156: ADR-0102 replaces part of ADR-0029, but the story says it "complète … sans les remplacer" and does not own ADR-0029.** ADR-0029's chosen option gives `/po-qa` Bash for one use only (`docs/decisions/ADR-0029-po-qa-committe-les-preuves-qa.md:18`, `:26`); `po_qa_records_the_report` gives it a second. Fix: ADR-0102 replaces ADR-0029 on that one point, and s156 owns ADR-0029's file to add `superseded-by`.
- **major — s157: the qa allowlist is a decision of accepted ADR-0026 (`:22`, consequence at `:33`), widened with no ADR; `qa_still_refuses_writing_verbs` states something that will be false; the reviewer shares `QA_GIT_VERBS`.** Fix: ADR-0103 adds the two verbs, says the reviewer gets them too, replaces ADR-0026 on that point; s157 owns both files.
- **major — s156 and s157: no `.oracle.test.sh` in `Owns`, though s149 is in flight.** Fix: add `tests/qa-report-returned-as-text.oracle.test.sh` and `tests/qa-reads-ignore-rules.oracle.test.sh`.
- **minor — s156 `po_qa_records_the_report`: does not say how the text gets through Bash word for word** (quotes, `$(…)`, a line equal to a heredoc delimiter; Law 7). Fix: a quoted heredoc whose delimiter is absent from the text, in `/po-drive` too.
- **minor — s156 Objectif and notes: "comme `/po-review`" is half right**: `/po-review` records through Write (`po-review.md:9`, `:37`); only `/po-drive` records through Bash (`po-drive.md:136`).
- **minor — s156: `/po-orchestrator` covered only by reference** (`po-orchestrator.md:67` lists `/po-qa`'s steps without the transcription). Fix: file the follow-up now, or state that `/po-qa`'s `## The evidence commit` holds the transcription.
- **minor — s156 `qa_returns_its_report`: the final-message sections are not named** (`method/agents/qa.md:60-61`, `po-qa.md:47-49`).
- **minor — s156 `Owns` takes the whole of `method/skills/qa-drivers/` with no reason given.**

## Not verified
- The issue texts and reproductions (summaries only, no shell).
- Whether the harness refusal also hits Write of evidence `.txt` transcripts (`qa-drivers/scenarios.md:30`).
- Test runs; `tests/drive.test.sh`, `tests/qa-fleet.test.sh`, `tests/ownership.test.sh`, `tests/bounds.test.sh` not read whole.
- Whether `git check-attr` and `git check-ignore` have no writing option in every git version.
- How `/po-drive` resumes when the driver dies between the `qa` answer and the transcription (`po-drive.md:59`: the lane walks again).

Max severity: major
Stories ready: yes

> Answered at the next revision, 2026-11-10, without a second loop. Majors: s156's ADR-0102 replaces ADR-0029 on the scope of `/po-qa`'s Bash alone and s156 owns ADR-0029; s157 gains `adr_widens_the_qa_allowlist` (ADR-0103, replacing ADR-0026 on the list alone, reviewer included) and owns both ADRs; both stories own their `.oracle.test.sh`, the notes saying which file holds the criteria depending on whether s149 has landed. Minors: the transcription goes through a quoted heredoc whose delimiter is absent from the report, in `/po-qa` and `/po-drive`; the Objectif names `/po-drive` as the model and the ADR argues against `/po-review`'s Write; the notes say `## The evidence commit` holds the transcription and the `po-orchestrator.md:67` rewording is filed as an issue for after s149; the two final-message sections are named; `Owns` narrows to `method/skills/qa-drivers/SKILL.md`. The `.txt` transcript question goes to s156's research. Stories ready: yes.
