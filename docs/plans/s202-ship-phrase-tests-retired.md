---
track: flow
validated: yes
---
# Plan (short track) — s202-ship-phrase-tests-retired

[Story](../stories.md)

Written by the planner. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s202-ship-phrase-tests-retired.md`. Line numbers are those of `70f6425`. Validated under `Plan validation: autonomous`, after the owner's decision d-0052: no human reviewed this plan.

## Verified facts
**Story assumption partly false.** "s192 to s196 already retired the phrases the ship command replaced; what is left reads `po-intake.md`, `po-retro.md`, `po-setup.md` and Law 7." Phrases of `po-ship.md` and `po-drive.md` remain: `tests/ship.test.sh:15-25`, `tests/ship-through-pr.test.sh:8-10`, `tests/ship-follows-forge.test.sh:49-84`, `tests/ship-and-fleet-cleanup.test.sh:10-16`, `tests/everything-in-issues.test.sh:34-43`. They join this family's removal. Not a blocker.

- Two files of `Owns` no longer exist: `tests/forge-token-host.test.sh` and `tests/ship-resumes-cleanly.test.sh` (deleted by `e3cdba8` s192 and `a826ada` s194). They are skipped. The token rule lives in `tests/ship-reads-the-forge.oracle.test.sh:287` (`test_token_never_travels`).
- The suite has 180 files and 825 test functions, counted as `tests/run.sh:33-36` lists them. `grep -c '^test_'` says 833 because it also counts heredoc lines.
- The count (`tests/routing-phrase-tests-retired.oracle.test.sh:123-190`) shows the launches of this family. Only these functions launch a script, and every one of them stays:
  - `short-subject-shipped` ×3 launch `po-session`;
  - `intake-follow-ups.oracle:test_redact_follows_the_scan_rule` launches `po-gate`;
  - six `failing-check-files-an-issue.oracle` tests launch `po-intake`/`po-gate`;
  - `session-and-gate-checks` ×3 launch `po-gate`/`po-session`.
  So no count goes down, and no `LOWERED_COUNTS` line is needed (s201's oracle stays untouched).
- `po` now holds the ship:
  - the gate comes first: `po/src/ship/land.rs:196`;
  - the remote rule for `local`: `land.rs:239-253`;
  - pushes only to the leased ref: `push.rs:177-182`;
  - `(forge)`/`(chosen)` and the rewrite: `po/src/ship/mod.rs:33-55`, `push.rs:369-512`;
  - filing never takes a `[security]` item and always goes through a file: `file.rs:245-250,505,436-440`;
  - cleanup waits for proof: `clean.rs:2,114`.
- `bin/polype:608-631` prints each template default it finds missing. `bin/po-lint:85-113` checks only that the names on a `Reads settings:` line exist. `:117-121` checks the tools against the stated contract (AskUserQuestion, no write tools).
- `/po-intake` (`method/commands/po-intake.md`) is prose only: no script runs its checks, its security hold or its landing.
- `floor-guard` (`method/hooks/po-gate.sh:425-555`):
  - a deleted test file gives `test-file-deleted`;
  - `assertions-dropped` counts only removed lines matching `expect\(|assert`, and none of the lines removed here matches;
  - no threshold pattern matches either;
  - its suppression patterns cover only JS/TS and Python.

## Escalation signals
| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text | absent — only `tests/` changes |
| New screen | absent — `Surface: command` | absent |
| Authorization or tenant scope | absent — story text | absent — no `po/`, no `method/` |
| API contract | absent — story text | absent — no script output changes |
| New dependency | absent — story text | absent — bash and s201's helpers |
| Technical choice that deserves an ADR | absent — story text | absent. The one choice was the owner's, on model-read rules, settled by d-0052. |
| Defect to fix (`Fixes`/`Corrige`) | absent — `docs/stories.md:3296-3302` | absent |

## Story
The ship, intake and tracker tests keep only what a script reads (#207, second family), except the security tests the owner keeps. Criteria:
- `kept_assertions_have_a_reader` and `journey_covers_what_left`: read by a model, judged in review on `## Classification`;
- `contract_tests_stay`, `no_script_lost_its_tests`, `suite_still_runs_clean`: read by a script.

## Reuse
The one piece of new code is the oracle's list of what must stay. It reuses `tests_defined` and the count of `tests/routing-phrase-tests-retired.oracle.test.sh:221-225,123-190`, sourced unchanged as `docs/harnais.md:154` says. Everything else is deletion, plus one assertion moved word for word (task 3).

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/ship-phrase-tests-retired.oracle.test.sh` | `223123017 2463` |

| Criterion | Test |
| --- | --- |
| `kept_assertions_have_a_reader` | — model-read (owner rule of 2026-11-13). The reviewer samples `## Classification` and opens each cited reader. The four security tests of d-0052 have no reader, and that is the exception the owner decided. Candidate `po-eval` arm (#208). |
| `contract_tests_stay` | `test_contract_tests_stay`. It checks that each function of `S202_KEPT` is still defined: the word cap `test_intake_holds_in_its_words`, and the three kept security functions. It also checks that each phrase of `S202_KEPT_PHRASES` is still in its file. `po-lint` is already run by s201's test of the same name. |
| `no_script_lost_its_tests` | s201's `test_no_script_lost_its_tests`, which runs on this tree against `origin/main` in every suite run. A copy would test the same rule twice (testing-doctrine, cut 3). |
| `suite_still_runs_clean` | s201's `test_suite_still_runs_clean`, plus the full suite once through `po-run`. |
| `journey_covers_what_left` | — model-read: the "proven after" column. Rows marked **M** are candidates for s206 and #208. |

## Classification
- **J** = journey test (`journey-runs-to-a-landed-commit.oracle`: `full`, `pr`, `order`, `gates`; `journey-reaches-every-stop.oracle`: `merge`, `inbox`).
- **D** = `driver-next-action.oracle` with `fixtures/driver-cases/`.
- **M** = a rule only a model reads.
- **P** = read by a person only (help, ADR registry, `docs/`).
- **H** = settled by d-0052, see `## Rules the owner decides`.

| File | Function removed | Rule it pinned | Read by | Where the rule still lives / proven after |
| --- | --- | --- | --- | --- |
| `ship` | `test_ship_gate_is_mechanical` | gate before Step 1 | script | `land.rs:196`; `ship-builds-the-landing-commit.oracle:test_gate_comes_first`, J `gates` |
| `ship` | `test_ship_cleans_up_only_on_proven_merge` | cleanup after proof | script | `clean.rs`; `ship-cleans-the-lane.oracle:test_nothing_is_removed_before_the_proof` |
| `ship` | `test_ship_runs_expensive_checks_once` | one failure stops | model | `po-ship.md:35`, **M** |
| `ship` | `test_rules_and_ship_describe_the_bound_verdict` | Law 3 row names `Reviewed tree:` | person | **P**; `po-gate` behaviour in `review-tree-gate` |
| `ship-through-pr` | `test_ship_opens_a_pr_and_fast_forwards` | PR, no squash | script | `push.rs`; J `pr` |
| `ship-through-pr` | `test_one_commit_per_story` | one commit, no merge commit | script | `ship-builds-the-landing-commit.oracle:test_one_commit_no_merge`, J `full` |
| `ship-through-pr` | `test_no_agent_pushes_target_branch` | only `story/<id>` pushed | script | `ship-lands-through-a-pull-request.oracle:test_pr_mode_never_pushes_target`; `po-bounds.sh:37` |
| `ship-through-pr` | `test_local_only_without_remote` | `local` only without remote | script | `land.rs:239-253`, `ship-builds-the-landing-commit.test.sh` (`remote-check`) |
| `ship-through-pr` | `test_ship_gate_unchanged` | ADR-0015 `superseded-by` | person | **P**, #442 |
| `ship-follows-forge` | `test_setup_reads_review_rules_from_the_forge` | setup asks the follow-up | model | `po-setup.md` Step 2, **M** |
| `ship-follows-forge` | `test_setting_records_its_origin` | `(forge)`/`(chosen)` reading | script | `mod.rs:33-55`; `ship-reads-the-forge.oracle` |
| `ship-follows-forge` | `test_forge_tightening_switches_to_human` | section order | script | `mod.rs:50-52`; `ship-lands-through-a-pull-request.oracle:test_forge_line_is_rewritten_by_the_command` |
| `ship-follows-forge` | `test_chosen_value_never_moves` | `(chosen)` never rewritten | script | `ship-reads-the-forge.oracle:test_chosen_is_never_rewritten` |
| `ship-follows-forge` | `test_pr_wait_does_not_block_the_fleet` | PR open is not the landing | script | J `merge`; D `ships.cases:33` |
| `ship-follows-forge` | `test_ship_gate_unchanged` | gate before any merge | script | `land.rs:196`; `test_gate_comes_first` |
| `ship-and-fleet-cleanup` | `test_fleet_rules_agree` | ships serial in review order | script | J `order`; D `test_ships_stay_serial_in_review_order` |
| `everything-in-issues` | `test_law_files_everything_to_handle` | Law 7, what goes to the person | model | **H1**, s206 |
| `everything-in-issues` | `test_ship_files_open_findings` | proof, then filing, then clean | script | `ship-files-open-findings.oracle:test_nothing_before_the_proof`; D `ships.cases:60` (`landed`) |
| `everything-in-issues` | `test_readers_list_issue_tracker` | a file that mentions `Issue tracker` lists it under `Reads settings:` | model | **P**; candidate rule for `po-lint`, for the lead to file |
| `everything-in-issues` | `test_setup_proposes_the_forge` | setup proposes `github`; template text; this repository's value | model | **M**/**P** |
| `everything-in-issues` | `test_adr_records_the_rule` | ADR-0090 body | person | **P** |
| `intake-issue-becomes-a-story` | `test_root_brought_level_before_reading`, `test_no_tracker_or_failed_listing_stops` | `/po-intake` stops | model | **H4**, s206 |
| `intake-issue-becomes-a-story` | `test_refused_review_puts_the_copy_back`, `test_pending_framing_branches_cite_too` | copy put back; pending branches cite | model | **M** |
| `intake-issue-becomes-a-story.oracle` (s152, shipped) | `test_intake_writes_defect_stories` | story shape | model | **M**. Its security phrase moves to `test_security_issue_goes_to_the_person` (**H5**, kept). |
| `intake-…oracle` | `test_intake_stories_reviewed_first` | intake review, `Model strong`, refusal goes to the person | model | **H6**, s206 |
| `intake-…oracle` | `test_intake_lands_as_framing` | framing landing; effective `Ship confirmation` | model | **H7**, s206 |
| `intake-…oracle` | `test_law_7_names_the_exception` | Law 7 and its exception; help; harnais line | model | **H1**, s206; help and harnais **P** |
| `intake-…oracle` | `test_adr_records_the_intake_loop` | ADR-0099 frontmatter and body; ADR-0090 `superseded-by` and body sum | person | **P**, see below |
| `failing-check-files-an-issue.oracle` (s151, shipped) | `test_rules_name_po_intake` | `## Installed files`, Law 7, harnais phrases | person/model | **P**/**M**; `po-intake` behaviour stays in the six kept tests |
| `po-retro` | `test_retro_reads_only_recorded_facts` | what the retro reads | model | **M** |
| `po-retro` | `test_help_lists_the_retro` | help lists it | person | **P**, #442 |
| `po-retro` | in `test_retro_writes_nothing`, the two `contains` and the Output checks (`:31-36`) | wording | model | **M**; the `lacks_tool` loop stays (reader: `po-lint:117-121`) |
| `framing-second-landing` | all 3 functions | framing merge proof, stacking, realignment | model | `po-setup.md` `## Landing the framing`, **M** |
| `session-and-gate-checks` | line `:36` of `test_ship_gate_needs_review_status` (the function stays) | Law 3 wording | person | **P**; the `po-gate` assertions above it stay |

What stays, and what reads it:
- `ship:test_ship_can_ask_before_merging`: frontmatter, `po-lint`.
- `ship-follows-forge:test_template_defaults_trust_the_gates`: `bin/polype:608-631`.
- `short-subject-shipped`, all 3: `po-session`.
- `intake-follow-ups.oracle`: `po-gate`, and the word cap, which stays until s205.
- six `failing-check-…oracle` tests: `po-intake`, `po-gate`. Its `:162-163,191` read the scripts' own source.
- `po-retro:test_retro_writes_nothing` (the `lacks_tool` loop only).
- `session-and-gate-checks`, all 3.
- **Kept by the owner's exception (d-0052), with no script reader:**
  - `everything-in-issues:test_security_goes_to_the_person`;
  - `everything-in-issues:test_finding_text_never_enters_a_command`;
  - `intake-issue-becomes-a-story.oracle:test_security_issue_goes_to_the_person`, together with the security phrase moved into it;
  - `failing-check-…oracle:105-108`.
  These are phrase tests kept on purpose until a script or the real run of s206 holds their rules. The reviewer does not report them as phrase tests without a reader.

**The `superseded-by` assertions** of `intake-issue-becomes-a-story.oracle.test.sh:139,151-157` go. No script reads them, and the registry check is already filed as #442. The sum of the ADR-0090 body (`:158-159`, "an accepted ADR is never rewritten") goes too. #442 does not list that check: the lead files it as an addition to #442.

## Rules the owner decides
**Answered: d-0052, option c.** The owner's choice:
- **Removed**, as in d-0051; s206 names them, in a framing the lead lands:
  - **H1** `everything-in-issues:test_law_files_everything_to_handle` and `intake-issue-becomes-a-story.oracle:test_law_7_names_the_exception`;
  - **H4** `intake-issue-becomes-a-story:test_root_brought_level_before_reading` and `:test_no_tracker_or_failed_listing_stops`;
  - **H6** `intake-…oracle:test_intake_stories_reviewed_first`;
  - **H7** `intake-…oracle:test_intake_lands_as_framing`.
- **Kept as they are**, a named exception until a script or the real run of s206 holds them:
  - **H2** `everything-in-issues:test_security_goes_to_the_person`;
  - **H3** `everything-in-issues:test_finding_text_never_enters_a_command`;
  - **H5** `intake-…oracle:test_security_issue_goes_to_the_person`, and the one security phrase of `:test_intake_writes_defect_stories`. That phrase's assertion is kept alone, in the smallest function that still reads well: it moves word for word into `test_security_issue_goes_to_the_person`, which already holds the flattened text `t` of the same file;
  - **H8** `failing-check-…oracle:test_sensitive_failure_goes_to_the_person`, lines `:105-108`.

## Tasks
1. [x] Delete `tests/ship-through-pr.test.sh`, `ship-and-fleet-cleanup.test.sh`, `intake-issue-becomes-a-story.test.sh` and `framing-second-landing.test.sh`. Test: s201's `test_suite_still_runs_clean`.
2. [x] Edit two ship files.
   - `ship.test.sh`: delete `:6-18` and `:23-33`; keep `:1-5` and `:19-22`.
   - `ship-follows-forge.test.sh`: keep `:1-3`, `:8`, `:42-47`; delete `:4-7`, `:9-41`, `:48-84`.
   - Test: `test_contract_tests_stay`.
3. [x] Edit the two security files.
   - `everything-in-issues.test.sh`:
     - keep `:1-5` (`LAW`, `SHIP`), `:9-15` (`section_of`, `has`, `holds`), `:45-52` and `:93-96`;
     - delete `:6-8` (`DRIVE`, `SETUP`, `TEMPLATE`), `:16-44` and `:53-92`;
     - result: 2 functions.
   - `intake-issue-becomes-a-story.oracle.test.sh`:
     - keep `:1-5` (`INTAKE`), `:14-16` (`flat`), `:18` (`holds`), `:20` and `:77-83`;
     - delete `:6-13`, `:17` (`section_of`), `:19` (`reads`), `:21-76` and `:84-125`;
     - insert, right after `:82`, `  holds "$t" 'no issue text enters a shell argument' "po-intake.md"`, the phrase of `:31` and the message of `:32` unchanged;
     - result: 1 function.
   - Test: those two files, focused; `test_contract_tests_stay`, which checks the moved phrase.
4. [x] Edit three more files.
   - `failing-check-files-an-issue.oracle.test.sh`: delete `:10-11` (`RULES`, `HARNAIS`), `:13` (`flat_section`) and `:212-224`. Keep `DOCTRINE` (`:9`), `:94` and `:105-108` as they are.
   - `po-retro.test.sh`: delete `:5`, `:7`, `:9-27`, `:31-36`, `:38-41`.
   - `session-and-gate-checks.test.sh`: delete `:35-36`.
   - Test: those files, focused.
5. [x] Checks.
   - Run `bash tests/run.sh ship-phrase-tests-retired.oracle.test.sh routing-phrase-tests-retired.oracle.test.sh ship.test.sh ship-follows-forge.test.sh everything-in-issues.test.sh intake-issue-becomes-a-story.oracle.test.sh failing-check-files-an-issue.oracle.test.sh po-retro.test.sh session-and-gate-checks.test.sh`.
   - Then run the full suite once through `po-run --story s202-ship-phrase-tests-retired --label 'Unit suite' -- 'bash tests/run.sh'`. Then run `bin/po-lint method`.
   - Expect 180 → 177 files (4 deleted, the oracle added) and 825 → 790 functions (36 removed, 1 added), as `tests/run.sh` loads them.
   - Expect `po-gate floor-guard s202-ship-phrase-tests-retired origin/main` to give exactly four `test-file-deleted` flags, for the files of task 1, and nothing else.
   - Test: the oracle, and s201's count.

## Scene viewpoints
—

## Run interdicts
- Empty diff:
  - `method/`, `po/`, `bin/`, `docs/` except this plan and the record;
  - `tests/lib.sh`, `tests/run.sh`, `tests/journey/`, `tests/fixtures/`;
  - `tests/routing-phrase-tests-retired.oracle.test.sh`, and every test file outside `Owns`.
- No assertion is added or reworded. The single exception is the move in task 3, word for word. Every kept assertion keeps its text, the four security tests of d-0052 included.
- `tests/ship-phrase-tests-retired.oracle.test.sh` keeps `223123017 2463`. `tests/ship-phrase-tests-retired.test.sh` is not created.
- Nothing is left in `/tmp` or `${TMPDIR}` (no `polype-journey.*`, no new `tmp.*`). No version bump.

## Files touched
- Deleted (4): `ship-through-pr`, `ship-and-fleet-cleanup`, `intake-issue-becomes-a-story`, `framing-second-landing` (`tests/<name>.test.sh`).
- Edited (7): `ship`, `ship-follows-forge`, `everything-in-issues`, `intake-issue-becomes-a-story.oracle`, `failing-check-files-an-issue.oracle`, `po-retro`, `session-and-gate-checks`.
- Unchanged: `short-subject-shipped`, `intake-follow-ups.oracle`.
- Written: the oracle and this plan.

## Test strategy
One oracle test, within `Test budget` 25. The other three criteria are held by s201's tests, which run on this tree. Every other change removes assertions, or moves one.

## Done when
- The focused files and the oracle pass. The full suite passes once through `po-run`. `po-lint` is clean.
- The reviewer samples `## Classification`, checks that floor-guard gives only the four expected flags, and accepts the d-0052 exception.
- The implementer makes one commit with this plan.
