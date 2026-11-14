# Stories review (second pass): Polype, M21 bis (s177, s178, s179)

**Verdict: ready.** All ten findings from the first pass are fixed, including the critical one. This pass finds no critical. One new major: s179's `Owns` has no oracle file. There are also three new minors.

Stories reviewed: `docs/stories.md` § `## M21 bis`, re-read from disk, in a context that did not write them. It now holds s177-intake-follow-ups, s178-security-findings-stay-private and s179-ship-files-the-other-findings. There is no PRD or brief: the scope source is the owner's decisions D6 b and D7 b of 2026-11-14 and the `## Findings` sections of `docs/reviews/s151-failing-check-files-an-issue.md` and `docs/reviews/s152-intake-issue-becomes-a-story.md`. Platform: `cli`.

Review status: complete

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| s151 major: unbounded title, and a fingerprint that varies with pytest's ` - <message>` | s151 `## Findings` (D6 b) | s160, already shipped (`method/hooks/po-intake.sh:115`, `:138-139`) | yes |
| s151 minor: `redact` applies the boundary rule to the line it has already rewritten | s151 `## Findings` (D6 b) | s177 `redact_follows_the_scan_rule` | yes |
| s152 major (a): a pending intake PR blocks every later run (the root differs from origin, or holds a staged change), and the stop message gives the wrong reason | s152 `## Findings` (D6 b) | s177 `pending_intake_does_not_block`, which now names both cases | yes |
| s152 major (b): numbering ignores the ids taken on pending `framing/intake-*` branches | s152 `## Findings` (D6 b) | s177 `numbering_sees_pending_branches` | yes |
| s152 minor: any issue labelled `polype-intake` is taken in, whoever wrote it | s152 `## Findings` (D6 b) | s177 `only_the_hook_account_is_taken_in` | yes |
| D6 b form: one ordinary story, written from the two reviews only | D6 b | s177 (its notes keep it to those sources) | yes |
| A security finding goes to the local inbox as a `sensitive` decision | D7 b | s178 `security_findings_are_marked`, `recorded_review_holds_a_count_and_an_id` | yes |
| The public review keeps only a count and an id | D7 b | s178 `recorded_review_holds_a_count_and_an_id`, `nothing_reaches_git`; s179 `nothing_private_in_what_ship_writes` | yes |
| Reviews already shipped are not rewritten | D7 b | s178 `earlier_reviews_read_the_same` | yes |
| Ordinary findings of these reviews are filed in the tracker again | D7 b (now in the milestone objective; the lead's consequence) | s179 `other_findings_are_filed_again` | yes |

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| Rewriting reviews already shipped | D7 b | none (s178 criterion 5 forbids it) | no |
| Re-fixing the s151 title finding | caller / D6 b | none (s177 notes) | no |
| Settling a technical choice alone | `AGENTS.local.md` § Direction, "Do not" | none (s178 leaves ADR-0123 `proposed`, with `Technical choice: waiting for a human`) | no |
| Filing a security matter in the tracker | Direction, "Do not" | none (s179 cites the decision id only, and keeps the "text bears on security" hold) | no |
| A prose rule without removing words | Direction, "Do not" | none: each story has a `words_hold` / `intake_holds_in_its_words` criterion | no |
| s153–s155 (postponed) | `docs/stories-reportees.md` | none | no |

## Checks
- [x] Exclusions: no story brings back an excluded item, under any name.
- [x] No technical layer dressed as a story. All three have Surface `command`, which `Platform: cli` admits.
- [x] Every criterion can be checked by one test, or is declared "jugée en revue" for a rule a model reads, per the Direction's "Criteria and tests".
- [x] Dependency order: s178 depends on s177, and s179 on s178. Both point earlier in the file.
- [x] Complexity: s177 is 3, s178 is 4 with its risk named, s179 is 2. s178 has 7 criteria, s179 has 4.
- [x] Ids: s177, s178, s179 are unique (also absent from `stories-reportees.md`) and in file order.
- [ ] Owns: every overlap is now covered by a dependency (details below), but s179 has no oracle file (major, below).

How the overlaps are covered:
- s177 and s178 share `method/hooks/po-gate.sh` and `tests/intake-issue-becomes-a-story.oracle.test.sh`; s178 depends on s177.
- s178 and s179 are disjoint, and are chained anyway.
- s177 and s179 are disjoint.

## Earlier findings
| # | Earlier finding | Status |
| --- | --- | --- |
| C1 | s177 and s178 both own `po-gate.sh`, with no dependency | **Resolved**: s178 depends on s177 |
| M1 | s178 `Owns` lacks the fix-run hand-off files | **Resolved**: `implementer.md` and `po-execute.md` are owned. The criterion says the text is found through the decision id, which `po inbox <id>` serves (`docs/interface-agent.md:161`). The notes say the orchestrator and flow commands defer to these two files. |
| M2 | ADR-0090 `superseded-by` left out, and the test pinning it unowned | **Resolved**: s178 owns `tests/intake-issue-becomes-a-story.oracle.test.sh` for that one assertion, and its notes require adding ADR-0123 to the line without touching the checksummed body. The shared ownership with s177 is covered by the dependency. |
| m1 | s178 too large, split left to the planner | **Resolved**: split into s178 and s179 |
| m2 | Contract clause was a phrase test; word caps missed files | **Resolved**: the `interface-agent.md` clause is now in the notes as judged in review. `words_hold` covers every touched `method/` file in s178 and s179. |
| m3 | "se lit comme avant" named no reader | **Resolved**: `earlier_reviews_read_the_same` names `po-gate ship-allowed`, `po-gate findings-shape` and the `po state` trust signals |
| m4 | `/po-retro` would undercount security majors | **Resolved**: s179 `retro_counts_what_it_cannot_read`, with `po-retro.md` owned |
| m5 | Criterion 2 went past D7 b ("la sévérité la plus haute") | **Resolved**: removed |
| m6 | s177 left out the staged-index case | **Resolved** |
| m7 | s177 note contradicted the `Owns` line on `po-intake.sh` | **Resolved** |

## Findings

### Major
- **s179: no oracle file in `Owns`.** Its `words_hold` criterion is checkable by a script: word counts of `po-ship.md`, `po-drive.md`, `po-retro.md` and `method/AGENTS.md`. Under the repository convention, a criterion's test function goes in `tests/<slug>.oracle.test.sh`. `Owns` lists only `tests/ship-files-the-other-findings.test.sh`.
  - Fix: add `tests/ship-files-the-other-findings.oracle.test.sh`.

### Minor
- **s179: `review-findings-shape.test.sh:92` pins a step 3 phrase s179 cannot change.** That test pins `marked "not filed: shape not recognised"`, which sits in `po-ship.md` step 3 (`po-ship.md:88`), the section s179 rewrites. The test is owned by s178, not s179.
  - Fix: add to the notes "keep this phrase", as they already do for the "text bears on security" sentence. Otherwise the lane would need a test it does not own.
- **s178: `superseded-by` on ADR-0090 points to an ADR that is still `proposed`.** The notes ask to add ADR-0123 to that line while ADR-0123 is `proposed`, pending the owner's choice. Law 6 links supersession to an ADR that does supersede.
  - Fix: say the line is set when ADR-0123 is accepted, which happens before validation since the plan waits on a human anyway.
- **s179: `/po-drive le dit de son rapport` is loose.** In `nothing_private_in_what_ship_writes` it does not say what `/po-drive`'s report says. Name the expected content: only the decision id, never the text.

## Not verified
- **Word-count baselines.** I have no shell, so I did not check the 1,550-word baseline of `po-intake.md`, nor the current counts behind each `words_hold`. The planner should record each baseline with `LC_ALL=C wc -w`.
- **Unowned tests that pin phrases in owned files.**
  - For s179: `ship.test.sh`, `ship-through-pr.test.sh`, `drive.test.sh` and `commands-and-texts.test.sh` (it mentions po-retro) may pin phrases of `po-ship.md`, `po-drive.md` or `po-retro.md`.
  - For s178: the files its notes name, plus `drive-executes-next.oracle.test.sh` (it rewrites a line of `po-execute.md`).
  - I did not read every assertion, and which phrases change depends on the design.
- **Changing s152's oracle file inside s178.** I did not check whether `po-gate oracle-intact` or `floor-guard` would object to s178 editing an assertion in s152's oracle file.
- **A possible new setting.** If ADR-0123 introduces one, `po-setup.md`, `AGENTS.local.md` and the settings tests fall outside s178's `Owns`. The notes now say to state this before validation, and I could not judge further before the owner chooses.
- **Whether the implementer may run `po inbox <id>`.** I did not confirm it under `po-bounds`. Its header suggests bounds apply to writes and git commands only.
- **Whether every pre-M21-bis story has shipped.** I relied on the caller and the recent commits, not on git history.

Max severity: major
Stories ready: yes

## After the review
The lead applied the major and the three minors of this pass to `docs/stories.md` before landing: the oracle file of s179 is in its `Owns`, its notes keep the pinned phrase of step 3, its criterion names what the report of `/po-drive` cites, and s178 sets the `superseded-by` line of ADR-0090 only once ADR-0123 is accepted. The first pass ended `Stories ready: no` on the critical finding C1 above.
