# Stories review: Polype, M21 bis, story s180 only

I reviewed `s180-record-review-loose-ends` in `docs/stories.md` (working tree). I did not write it.

There is no PRD or brief. The scope sources are the owner's answer to d-0022, as the caller summarises it, and `## Findings` of the last review block (Fix loop: 1) of `docs/reviews/s178-security-findings-stay-private.md`. I rated each finding critical, major or minor.

Review status: complete

## When blocked
- Failure cause: —
- Missing: —
- Required adaptation: —
- Next action: —

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| Minor security finding at `po/src/record/security.rs:151`. Its text lives only in d-0022. | s178 review, loop 1, `## Findings`; d-0022 | s180 (`security_finding_of_d_0022_is_closed`, plus notes pointing to `po inbox d-0022`) | yes |
| Minor at `mod.rs:261`: the rollback after a failed `keep()` has no test, for a new review or an existing one | s178 review, loop 1, `## Findings` | s180 (`failed_keep_rolls_the_review_back`) | yes |
| Minor at `mod.rs:268`: when `keep()` succeeds and the rewrite of the count line then fails, both `written: false` and the temporary `none kept` line are untrue | s178 review, loop 1, `## Findings` | s180 (`reply_is_true_when_the_last_write_fails`). The criterion covers the item, but no test can trigger it today (see Findings). | yes |
| A small fix story after s178, closing all three findings in a single `po` version | d-0022 (owner, 2026-11-14) | s180 (sits after s178, complexity 2, `version_goes_up` 0.3.0 → 0.3.1) | yes |

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| The security finding's text stays out of the repository (no description in a file, test, test name or commit) | ADR-0123; the brief of this review | none. The notes forbid it, and the story only cites the file, the line and the decision id. | no |
| No change to `method/` or to the `po` contract | s180 notes; the `## Direction` rules | none. The notes say to stop if a new error code seems needed. | no |
| `/po-ship` and the retro belong to s179 | s179 | none | no |

## Checks
- [x] Exclusions: no story revives an excluded item, under any name.
- [x] No technical layer dressed as a story. Surface is `command`, which Platform `cli` admits.
- [ ] Every criterion can be checked by one test. `reply_is_true_when_the_last_write_fails` cannot be triggered today (major, below).
- [x] Dependency order. `Dépend de : aucune` is sound: s178 is shipped, and s179 does not touch `po/`.
- [x] Complexity. It is a 2, so the score asks for no named risk.
- [x] Ids. `s180-record-review-loose-ends` is well formed, unique, and follows s179.
- [x] Owns. The story declares one, and it covers its oracle. It does not overlap s179, the only story in flight.
- [x] Check 10. The `Corrige` line names review findings, which need no `Owns` entry (Law 7). No ADR is superseded.
- [x] Version. `0.3.0` appears only in `po/Cargo.toml:3`, `po/Cargo.lock:165` and `bin/polype:27`, and all three are in `Owns`. No test pins `0.3.0`: every test reads `POLYPE_VERSION` from `bin/polype`. `tests/run.sh` builds with `--locked`, so the lock file has to move with `Cargo.toml`, and it is owned.
- [x] `docs/interface-agent.md`. Line 265 describes `written` and the codes `no-private-folder-setting` and `private-folder-unusable`. The criteria change neither a code nor the meaning of `written`. Keeping the doc out of `Owns` is consistent.

## Findings
- **major** — s180 — `reply_is_true_when_the_last_write_fails` names a trigger that no test can produce. The count-line rewrite at `mod.rs:268` writes the same path, through the same temp file name, in the same process, a moment after the identical first write at `mod.rs:250` succeeded. `po/src` has no `#[test]` and no fault-injection seam. To be testable, the story should say how a test triggers the failure (a test-only seam inside `po/src/record/`, which is owned), restructure the code so the failure becomes reachable, or downgrade the criterion to "judged in review".
- **minor** — s180 — `reply_is_true_when_the_last_write_fails` does not say what happens to the decision already posted when the review is restored.
- **minor** — s180 — `failed_keep_rolls_the_review_back` does not require that the private text be gone from disk after the failure.
- **minor** — s180 — `failed_keep_rolls_the_review_back` ends with "dans les deux cas", which can be read as the two failure modes or as the two prior states. The s178 finding asks for the second.
- **minor** — s180 — `security_finding_of_d_0022_is_closed`: the rules for `Private folder` are set out in accepted ADR-0123, and `docs/decisions/` is not in `Owns`. The notes ask for a stop on a new error code, but not on a fix that would change a rule of ADR-0123.
- **minor** — s180 — `tests/security-findings-stay-private.oracle.test.sh` is not in `Owns`. If the fix changes what its fixture is allowed to do, the planner would hit a file outside `Owns`. The notes should say "stop and say so" for this case.

## Not verified
- **The text of d-0022 and of the security finding.** I deliberately did not read them (ADR-0123). So I cannot judge whether `private-folder-unusable` before any write is the right outcome, whether the fix stays inside ADR-0123's rules, or whether s178's oracle or `docs/interface-agent.md:265` would become wrong. A person, or the planner, should confirm these against d-0022.
- **The owner's d-0022 answer itself.** I took its scope from the caller's summary.
- **Whether the 0500 probes hold in CI.** Mode-0500 fixtures do nothing under root.
- **Whether the s180 reviewer can read d-0022.** This depends on `po-bounds` letting the reviewer run `po inbox <id>`.
- **The other stories in the file.** Out of scope; I compared only ids, order and `Owns` against s179.

Max severity: major
Stories ready: yes

## After the review
The lead applied the major and the five minors to `docs/stories.md` before landing: the third criterion says the decision stays and tells the plan to name its trigger or to class it "judged in review"; the second names the two prior states and requires the private text gone; the notes add the stops on ADR-0123 and on the oracle of s178, and the root case of a 0500 probe.
