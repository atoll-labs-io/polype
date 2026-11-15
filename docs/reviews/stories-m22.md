# Stories review (second pass): Polype, M22 « La preuve par le comportement » (s181 to s206)

**Verdict: ready.** The first pass ended `Stories ready: no` with one critical finding and thirteen majors; the section was reworked and this pass finds no critical. Seven new majors and seven minors, listed below with what the lead did about each.

Stories reviewed: `docs/stories.md` § `## M22`, re-read from disk, in a context that did not write them. There is no PRD or brief (`Entry mode: —`): the scope source is the owner's decisions d-0026 b, d-0027 c and d-0028 b of 2026-11-15, recorded in the section's first paragraph. `Platform: cli`.

Review status: complete

## Coverage
| Scope item | Source | Covered by | Covered |
| --- | --- | --- | --- |
| #254, #221 — the suite replaces the working `po`; detached HEAD | d-0026 | s181 | yes |
| ADR-0122, #296 — a `po/` diff without a version bump is refused | d-0026 | s182, then `version_goes_up` in s183-s187, s190, s192-s196 | yes |
| #297, #299 — untested cleanup guards, release rerun | d-0026 | s189 | yes |
| #306 — a lane waits on an unshipped dependency | d-0026 | s183 | yes |
| #315, #244 — session shows what waits; framing held per milestone | d-0026 | s184 | yes |
| #278, #286 — ship order from a written date; closed pull request | d-0026 | s185 | yes |
| #331, #279 — stale decisions; held until consumed | d-0026 | s186 | yes |
| #290, #328, #329 — dead `not_built`, path message, path parity | d-0026 | s187 | yes |
| ADR-0109, #210 — one command drives the work; stage commands reduced | d-0026 | s190, s191, s197, s198 | yes |
| #211, #84 — ship as a script | d-0026 | s192, s193, s194, s195, s196 | yes |
| #206 — replayable end-to-end journey | d-0026 | s199, s200 | yes |
| #207, #136, #164 — phrase tests retired | d-0026 | s201, s202, s203, s204 | yes, less the files of finding 6 |
| #208 — word budget in `po-lint` | d-0026 | s205 | yes |
| #208, #332 — control arms | d-0026 | s206 | yes |
| Journey walked by a script on every pull request | d-0027 | s199 (`journey_runs_in_the_suite`), s200 | yes |
| Journey walked by a real model before each release | d-0027 | s206 | yes |
| #225 — orphan copy survives | d-0028 | s188 | yes |
| #260, #263 — outside-worktree path; exclusive lock | d-0028 | s187 | yes |

No story traces to nothing.

## Exclusions
| Excluded item | Source | Revived by | Revived |
| --- | --- | --- | --- |
| Framing order (ADR-0110, #212) | d-0026 | none | no |
| Versioning discipline of projects built with Polype | d-0026 | none (s182 and s189 concern `po` only) | no |
| #230 — `/po-setup` and a chosen `Ship confirmation` | d-0028 | none | no |
| #234 (quick fix), #233 (closed) | d-0028 | none | no |

## Checks
- [x] Exclusions: no story revives an excluded item
- [x] No technical layer dressed as a story
- [ ] Every criterion can be checked by one test — s182 `workflow_brings_the_base` (finding 7)
- [x] Dependency order: one linear chain, s181 (none), then each of s182 to s206 depends on the story just before it
- [x] Complexity: no 5; the seven 4s (s191, s192, s194, s195, s197, s199, s206) each name their risk
- [x] Ids: `s<number>-<slug>`, unique, growing in file order
- [ ] Owns: no unordered pair shares a path, since the chain orders every pair; but s202, s203 and s204 own no oracle file (finding 5)
- [x] Surface: every story says `command`, which `cli` admits
- [x] Owned records: `Corrige` lines name tracker issues or review findings; s201 owns `docs/defauts.md`; s188 owns `docs/decisions/` for the partial supersession of ADR-0112

Test-file accounting: 161 test files exist. 126 are in exactly one of s201 (42), s202 (15), s203 (32) and s204 (37), none in two. Of the 35 others, 33 are behaviour tests of `po`, the installer, a hook, `po-lint`, `po-eval` or CI, plus `overlap` and the files that hold only word ceilings or lint mutations. Two carry phrase assertions (finding 6).

## Findings
1. major — s193 — `Owns` lacks `tests/ship-through-pr.test.sh` (`:8-11,54,70`) and `tests/ship-and-fleet-cleanup.test.sh` (`:31`), which pin the `po-ship.md` prose it removes.
2. major — s196 — `Owns` lacks `tests/ship.test.sh` (`:19`) and `tests/everything-in-issues.test.sh` (`:45-48`), which pin the cleanup prose it replaces; `tests/drive.test.sh:56-66` and `tests/ship-follows-forge.test.sh:94,109` pin the lines of `po-drive.md` it owns.
3. major — s197 — its notes list `po-drive.md:52` and `:71-86` as repeats to remove, but `tests/drive.test.sh:22-23`, `tests/drive-guards.test.sh:16-18`, `tests/grouped-validation.test.sh:15-37` and `tests/resume.test.sh:13-19`, which pin them, are not owned.
4. major — s192 — `tests/ship-resumes-cleanly.test.sh:24-33` pins `po-ship.md:27,29`, inside the forge section s192 reduces; the file is not in its `Owns`.
5. major — s202, s203, s204 — each has script-read criteria and owns no oracle file.
6. major — s204 — `tests/run-ledger.test.sh:140-157` and `tests/readme-onboarding.test.sh:62-69,127-155` hold phrase assertions and sit in no family, so `no_phrase_test_is_left` cannot be reached.
7. major — s182 — `workflow_brings_the_base` is judged "on the first pull request that touches `po/`", which neither a test nor this story's reviewer can check: s182 does not touch `po/`.
8. minor — s195, s202 — `Owns` names `tests/ship-files-the-other-findings.test.sh`, which does not exist.
9. minor — s195 — eight criteria; past seven a story is probably two.
10. minor — s201 — the oracle name does not follow `tests/<story-slug>.oracle.test.sh`; `no_script_lost_its_tests` does not say what the count does on `Target branch` itself, or when the base ref is absent.
11. minor — s184, s186, s206 — each poses `Technical choice: waiting for a human` without `docs/decisions/` in `Owns`.
12. minor — s193 — `method/commands/po-setup.md:67,81` cite the remote check and the commit "as in `/po-ship`", which s193 removes; no note keeps them citable.
13. minor — s206 — `tests/rebuilt-helper-single-defect.test.sh` reads `evals/cases/` and builds through `bin/po-eval`, both owned by s206; the file is not in its `Owns`.
14. minor — s190, s189 — `design_comes_before_plan` and `sums_are_written_by_a_command` name no item of the d-0026 list; both trace to ADR-0109 and ADR-0122.

## Not verified
- Stories before M22: whether any is still unshipped and overlaps s181 cannot be told without git history.
- The issues and d-0026 to d-0028 are not in the repository; coverage rests on each story's own `Corrige` summary.
- Line numbers in the notes: only those into `po-ship.md` and `po-drive.md` were checked.
- Pinning tests were found by literal file name; a test that reaches a method file through a loop or a glob was not traced.
- Two possible pins that depend on the plan: `tests/framing-commands-cleanup.test.sh:28` (a forge sentence of `po-setup.md`, s192) and `tests/drive.test.sh:152-176` (sections of `planner.md`, s190 and s197).
- Word counts (2 521, 2 707, 57 589, 556) were not recounted.

Max severity: major
Stories ready: yes

## After the review
The lead applied findings 1 to 8 and 10 to 14 to `docs/stories.md` before landing. The four `Owns` lines of findings 1 to 4 hold the tests named. s202, s203 and s204 each own an oracle file of their own, which sources the count of s201's oracle, renamed `tests/routing-phrase-tests-retired.oracle.test.sh`; that count takes a base ref and fails naming it when it is absent. s204 owns `tests/run-ledger.test.sh` and `tests/readme-onboarding.test.sh` for their phrase assertions. `workflow_brings_the_base` is now an oracle test that reads `.github/workflows/ci.yml`, the live proof moving to the pull request of s183. The file that does not exist is out of both `Owns` lines; `docs/decisions/` is in the `Owns` of s184, s186 and s206; s193's notes keep the two citations of `po-setup.md` true; s206 owns `tests/rebuilt-helper-single-defect.test.sh`; s190 and s189 name their ADR. Finding 9 stays open: s195 keeps its eight criteria, each of them one behaviour of the same filing command. The two possible pins of `## Not verified` are left to the plans of s190, s192 and s197, whose planner stops and names a test outside its `Owns`.

The first pass is not recorded in a file of its own. Its critical finding: s184 overlapped a dozen later stories with no dependency tying them; the stories now form one chain. Its majors: three `Owns` gaps (s190, s185, the ship stories), five criteria no single test could check (s186, s184, s182, s187, the journey's duration), and four oversized stories, now split (the ship in s192 to s196, the stage commands in s197 and s198, the phrase tests in s201 to s204).
