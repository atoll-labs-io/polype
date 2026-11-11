# Stories review: Polype, milestone "M19 — Une revue consignée porte toujours son en-tête" (s158)

A one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). Done on 2026-11-11 by the `stories-reviewer` subagent, in a context that did not write the stories. The verdict is recorded verbatim.

- **Scope source:** the milestone's Objectif paragraph, plus issue #169, with the owner decision of 2026-11-11. The issue text reached the reviewer as the caller's quote.
- **Platform:** `cli`.
- **Folded after Loop 1 (by the lead, 2026-11-11):** the major (every first write, the blocked report included, starts with the header) and the three minors (`tests/review-header-recorded.test.sh` in `Owns`; the template note is not part of the answer's shape; no lane in flight with a header-less review, `bin/po-link-artifacts` as the person's fallback).

## Loop 1

Review status: complete

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| No recorded review breaks `main` for lack of its link line (`tests/artifact-links-backfill.test.sh`) | Objectif; issue #169 | s158 (`recorder_writes_the_header`, `drive_writes_the_header`) | yes, with one gap: the first blocked report that the command composes itself (see Findings) |
| The context that records the review writes the file header itself (the title and the link line of `templates/review.md`), then the reviewer's answer word for word underneath | Objectif (owner's decision of 2026-11-11) | s158 (`recorder_writes_the_header`, `drive_writes_the_header`, `reviewer_answers_below_the_header`) | yes |
| The header is not a judgment: the verdict, findings and status lines stay transcribed as they are | Objectif | s158 (`drive_writes_the_header`, `adr_records_the_header_rule`) | yes |
| Every path that records a review: `/po-review`, `/po-drive`, and `/po-orchestrator` and `/po-flow`, which record "as `/po-review` says" (`po-orchestrator.md:73`, `po-flow.md:89`) | issue #169 (the recorded review) | s158 (criteria 1 and 2; the notes name the two delegating commands) | yes |
| The template says who writes the two header lines, and the link line itself stays unchanged for `bin/po-link-artifacts` | Objectif (the header "comes from the template") | s158 (`template_marks_the_header`) | yes |
| The decision and the options turned down are recorded | Objectif | s158 (`adr_records_the_header_rule`, ADR-0104) | yes |
| M19 runs before s151 | Objectif | s158: no `Depends on`, and no `Owns` overlap with s151 to s155 (check 8 below), so it is ready at once | yes |

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| "Insert the line only if it is missing" | Objectif (option turned down) | none. For an existing file the story keeps the header in place and adds nothing conditionally. | no |
| "Refuse the review and stop the lane" (`po-gate` requiring the link line) | Objectif (option turned down) | none. The notes leave `po-gate.sh` and `findings-shape` untouched. | no |

## Checks
- [x] Exclusions: no story revives an excluded item, under any name
- [x] No technical layer dressed as a story. s158 is a behaviour change you can see in the commands, and it is not a contract story.
- [x] Every criterion can be checked by one test. Each one names a section and a clause that a bash test can quote: `## Recording`, `## The verdict, and the fix runs`, `## Your answer`, the template note, and the ADR.
- [x] Dependency order: no dependency on a later or unknown id. s158 depends on nothing. s149 (the planner writes the oracle) and s128/s129 (the link lines), which it relies on, have already shipped.
- [x] Complexity: no 5 left unsplit, and no 4 without its risk. s158 is a 2.
- [x] Ids: `s158-review-header-recorded` has the right form, appears once, and follows s157.
- [x] Owns: s158 declares one. Checked pairwise against s151, s152, s153, s154 and s155:
  - s158 owns `method/commands/po-review.md`, `method/commands/po-drive.md`, `method/agents/reviewer.md`, `method/templates/review.md`, ADR-0104 and `tests/review-header-recorded.oracle.test.sh`.
  - None of these is in s151 (`po-gate.sh`, `po-intake.sh`, `method/AGENTS.md`, testing-doctrine, `docs/harnais.md`), in s152, s153 or s154, or in s155 (`po-flow.md`, `po-orchestrator.md`, `plan-flow.md`, review-antihallu, `po-ship.md`, the stories template and skills).
  - No entry is a folder or a glob that could cover another story's path, so there is no overlap.
- [x] Surface: `—`, which the `cli` platform admits.
- [x] Owned records: the `Corrige` line names issue #169 on the GitHub tracker, which is not a file in the repo. ADR-0104 supersedes no ADR: no accepted ADR in `docs/decisions/` sets out the verbatim recording of a review or the link line, and ADR-0094 only says a blocked report is written into the review. ADR-0104 is free.

## Findings
- **major** — s158 — `recorder_writes_the_header` only makes the header mandatory when the file starts with "la réponse du relecteur" (the reviewer's answer). It names the "rapport blocked composé par la commande" (the blocked report the command composes) only as a case where the file *already exists*. It says nothing about the first write of such a report: when the subagent fails, times out or answers without its two verdict lines at the first review (`po-review.md:41`, `po-drive.md:140`). In that case the file is created without a header. Later fix-loop blocks are then appended to a file that "keeps its header" it never had, and the review that ships breaks `tests/artifact-links-backfill.test.sh` on `main` again. This is exactly the failure the Objectif wants to remove. `drive_writes_the_header` inherits the gap. Both criteria should say that every first write of `docs/reviews/<id>.md` starts with the header, whoever composes the body.
- **minor** — s158 — `recorder_writes_the_header` assumes every existing file already has a header. A review recorded before s158 lands, in a lane still in flight, would keep its missing link line. Under the decision, the only remedy would be the excluded conditional insertion. M19 runs before s151, and the M17 stories have not started, so the risk is small. The notes should say that no lane may be in flight with a header-less review when s158 lands, or name the person's fallback (`bin/po-link-artifacts`).
- **minor** — s158 — `Owns` lists `tests/review-header-recorded.oracle.test.sh` but not `tests/review-header-recorded.test.sh`. Any extra test the implementer adds outside the oracle would fall outside `Owns`, which the review flags as major. s150, s151 and later stories own both files.
- **minor** — s158 — `template_marks_the_header` adds a note under the link line. `reviewer_answers_below_the_header` says "tout le reste de `templates/review.md` reste la forme de la réponse" (all the rest of the template remains the shape of the answer), and that would include the note itself, which a reviewer could copy. The criterion should say the note is not part of the answer's shape.

## Not verified
- **The full text of issue #169 and of #168, #170 and #187.** I only had the excerpt quoted in the request and the Objectif paragraph. I had no shell, and my scope is limited to these files, not the git history. A person should check that the issue raises nothing beyond those lines.
- **The reviews of s147 and s156 that broke `main`.** I did not read them, so I could not confirm that the missing link line was their only defect.
- **How `bin/po-link-artifacts` and `tests/artifact-links-backfill.test.sh` behave on a line with a link removed.** I read the test: it requires at least one link, and every link must resolve. I did not read the script, and I did not run either one.
- **Whether a story lane is in flight right now with a review already recorded.** That needs `/po-drive status` or a look at the worktrees, which is outside what I may read.
- **Whether the sentences that s158 changes are frozen by tests outside its `Owns`.** I spot-checked `tests/review-findings-shape.test.sh:69,77-83,136-139` and `tests/drive.test.sh:64-65`. The phrases they quote can survive the change, but the research stage has to confirm this for every test the notes list.

Max severity: major
Stories ready: yes
