---
validated: yes
---
# Plan — s201-routing-phrase-tests-retired

[Story](../stories.md) · [Research](../research/s201-routing-phrase-tests-retired.md)

Branch `story/s201-routing-phrase-tests-retired`. Read `docs/research/s201-routing-phrase-tests-retired.md` first; this plan builds on it without repeating it.

## Story
The routing, fleet, plan, execute and review tests keep only what a script reads, so that rewording the method breaks no test (#207, first family; fixes #136, #164).

| Criterion | Read by |
| --- | --- |
| `kept_assertions_have_a_reader` | a model: the reviewer samples `## Classification` |
| `contract_tests_stay` | a script |
| `no_script_lost_its_tests` | a script |
| `suite_still_runs_clean` | a script, plus the full suite through `po-run` |
| `journey_covers_what_left` | a model: the "proven after" column of `## Classification` |

**Two corrections to the story**, both now in `docs/stories.md` (framing commit `8e2a5ad`).
1. The note "a mutation test of a `method/` file (`tech-choice-backstop`, `plan-and-defect-paths-cleanup`…) proves a script bites: it stays" is false. Both mutate `method/` to make a *phrase test* fail, and run no script. They go with their targets. A mutation test that runs a script stays: `strict-checks-by-default.test.sh` runs `po-lint` on mutated profiles.
2. **Gap in `Owns`.** `tests/ship-and-fleet-cleanup.test.sh:49` uses `escalation-contract.test.sh:test_human_stops_do_not_halt_the_fleet`, which goes, as its mutation target. Task 5 deletes that use, `test_fleet_tests_bite`; `Owns` now lists `tests/ship-and-fleet-cleanup.test.sh` for it. s202 owns it too and depends on s201, so the two never run together.

## Reuse
The one piece of new code is the launch count. It goes on a new rung because the rungs above all fail.
- `tests/run.sh:32-48` already sources each file to list its tests. The count does the same, but `run.sh` prints names only and is outside `Owns`.
- `bin/po-version-check:11-29` already takes `origin/<Target branch>` and a merge base. The count copies that form, but that check reads `po/`, not `tests/`.
- No installed tool parses bash.

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `script_launches`, `script_counts`, `scripts_kept_their_tests` in the oracle | new code: bash plus `python3 -I`, already used by the suite (`tech-choice-backstop.test.sh:36`) | the repository has no static reader of test bodies; the standard library has no bash parser |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/routing-phrase-tests-retired.oracle.test.sh` | `802676634 15112` |

| Criterion | Test |
| --- | --- |
| `kept_assertions_have_a_reader` | — model-read (owner rule of 2026-11-13). The reviewer picks rows of `## Classification` and checks that each kept assertion's reader is real, by opening the cited `path:line`. Candidate `po-eval` arm (#208): a model asked to classify the same file reaches the same split. |
| `contract_tests_stay` | `test_contract_tests_stay`. `bin/po-lint` exits 0, and each function of `KEPT_CONTRACTS` is still defined in its file. That list is the "Stays" column below. |
| `no_script_lost_its_tests` | `test_no_script_lost_its_tests`. It first proves on a throwaway repository that the count bites: a dropped launch through a helper is named, a dropped phrase is not, an absent base ref is named, and the base itself compares nothing. Then it compares this tree with `origin/<Target branch>`. |
| `suite_still_runs_clean` | `test_suite_still_runs_clean`: every `tests/*.test.sh` defines a `test_`. The full suite runs once through `po-run`. |
| `journey_covers_what_left` | — model-read. The reviewer opens the named journey or fixture for the rows it samples and checks that it covers every path the retired assertion covered. Rows marked **M** are candidates for s206 and for a `po-eval` arm (#208). |

## Classification
Proofs after the story:
- **J** = a journey test. In `journey-runs-to-a-landed-commit.oracle.test.sh`: `follow` (`test_journey_follows_po_next`), `full`, `pr`, `order` (`test_two_lanes_ship_in_order`), `gates` (`test_real_gates_are_crossed`). In `journey-reaches-every-stop.oracle.test.sh`: `flow`, `screen` (`…design_and_qa`), `loop` (`…loops_then_asks`), `inbox`, `merge` (`…waits_for_the_merge`), `ask` (`test_every_ask_reason_is_reached`).
- **D** = `driver-next-action.oracle.test.sh` over `fixtures/driver-cases/`.

Kinds of rule:
- **M** = a rule that speaks to a model: s206, and a `po-eval` arm candidate.
- **P** = read by a person only (help, matrix, ADR registry, `docs/`), so no reader and no arm; it goes. The three checks that leave nothing guarding them — every command listed in `po-help`, the ADR `superseded-by` registry, the parity matrix — are filed as #442, candidates for `po-lint`.
- **H** = a human checkpoint, a stop that goes to a person, or something kept private.

"Stays" names the script that reads what the kept assertion pins.

| File | Goes → proven after | Stays → reader |
| --- | --- | --- |
| `drive` | Wave order, overlap, absolute paths, ADR numbers, report windows → **M**; order of subagents → J `screen`, D. "A plan without that line never reaches an implementer" → J `gates`, `gate.test.sh` pre-commit tests. The verdict transcribed verbatim → `po record review` (J `gates`, `record-writes-reports.test.sh`). Serial ships → J `order`, D `test_ships_stay_serial_in_review_order`. Root clean and on target → `ship-builds-the-landing-commit.test.sh` (`dirty-worktree`). **H** `Ship confirmation: human`: J `merge` under `pr`; under `local`, one AskUserQuestion per merge is **M**. Planner limits → **M**. `Tracker: github` row and phrase, documented rows → **P** | `test_drive_never_writes_code_or_verdicts`, its four tool checks → Claude Code frontmatter, `po-lint` (Agent ⇒ no Edit/Write). `test_settings_template_declares_fleet_settings`, its names and defaults → installer `missing setting:` (`bin/polype:607-631`) |
| `drive-guards` | Whole file: framing-PR waiters and lone decisions logged → **M** | — (deleted) |
| `drive-executes-next` | — | the word cap: kept until s205 |
| `fleet-wiring` | Law 1 fleet → J `order`, D; Owns overlap → `ready-set.cases:38-47`, `held-says-what-collides.oracle`. Help and matrix → **P** (#442) | — (deleted) |
| `pilot` | The `po-status` phrase → **M**. `test_every_command_listed_in_help` → **P**, #442. The ADR template → **P** | tools of `po-status`; `disable-model-invocation` → Claude Code frontmatter |
| `wiring` | Law 1 table order → `po state` framing (`state-as-json.test.sh:test_framing_next_follows_the_stage`). `track: flow` → J `flow`. Design files reach the implementer, design conformity → **M** | the reviewer preloads `design-doctrine` → frontmatter |
| `model-routing` | Model per role and lane, refusal stop, session model → **M** (`po` reads no model setting). Template rows, `po-setup` phrases → **P**/**M** | setting names → `po-lint`, installer; `model: inherit` → frontmatter; template defaults → installer |
| `surface-routing` | Screen and QA routing → `po` (`stories.rs` Surface), J `screen`, `resuming.cases:92-140` (`surfaces`). Review needs QA → `po next` `qa-current` (J `screen`). Scene viewpoints, README, help → **M**/**P** | — (deleted) |
| `escalation-contract` | Three motives, ranking, log, fleet carries on → **M**; **H** "goes to the person at once" → `po inbox` (J `inbox`), `po-session` waiting list (`project-lead`). Approval wording → **H**: no script can tell who writes `validated: yes` (`docs/harnais.md`, "Le pivot"), so **M** | in `test_plan_with_a_tech_choice_waits_for_a_human`, the marker in `planner.md` and in `## Writing the plan` of `po-plan.md` → `po` reads it from the plan (`lanes.rs:326`, J `ask`) |
| `tech-choice-backstop` | Both mutation tests drive phrase tests (correction 1) | — (deleted) |
| `defect-and-routing-paths` | `/po-research` names the diagnostic → **M**; defect track → `next-names-the-track.oracle`. "write no plan" → **M**. ADR-0068/0070 links → **P**. Checkout only in a throwaway clone → `po-bounds` (`bounds-messages.test.sh:59-69`) | in `test_no_root_cause_goes_to_a_human`, the **H** marker `Root cause: not found` in the skill and in the planner → `po` reads it from the research (`lanes.rs:323`, J `ask`) |
| `plan-and-defect-paths-cleanup` | Stops agree, tech-choice paths, bites → **M**, or mutations of phrase tests | — (deleted) |
| `planner` | Contract phrases, line caps, track report → **M** | preloads; tools → frontmatter |
| `planner-writes-the-oracle` | Section order, budget and `—` wording, planner and implementer limits, doctrine, ADR-0098 → **M**/**P** | `## Acceptance tests` and `\| Oracle file \| cksum \|` in both templates → `po-gate oracle-intact` (`:579-623`). `## Oracle changes` before `## Runs`, with its header → `po-gate` (`:646-667`) and `po-run`, which appends at the end |
| `plan` | Interdicts and pivot headings, doctrine → **M**. **H** "`validated: yes` … on Approve and on nothing else" → **M**: the gate reads the line, not who wrote it | `validated: no` in the template → `po`, `po-gate plan-validated`; no Edit → frontmatter |
| `research` | Worktree steps, fresh base, `.env` copy, premise, cap, template headings, skill → **M**; the lane path → `lanes.rs:216-226` (J `follow`) | no Edit → frontmatter; `**Owns**` in the stories template → `po` (`stories.rs:153`), `po-bounds` |
| `execute` | Unapproved-plan message → `po next` `validate-plan` (D); one commit, write-tree, expected docs, `cd` → **M**, with J `gates` for the record; secrets → `gate.test.sh` secret tests | tools, preload → frontmatter; record `Tree:`, status, `## Checks`, `## Runs` → `po-gate verif-current`, `po-run` |
| `review` | Six steps, critical-only, `rev-parse` wording, `subagent_type` → **M** | tools, preloads → frontmatter; verdict lines, `Reviewed tree:` before `Max severity:`, `Fix loop:` → `po-gate`, `po`; `Review status: blocked` and `Max severity: critical` in `po-review.md` → `po`, `po-gate` read them |
| `review-lenses` | Lens triggers and contents, `Lenses run:`, section order → **M** | the review-lenses preload and its absence elsewhere, no Write → frontmatter; one `Max severity:` and one `Ship allowed:` in the template → `po-gate` |
| `review-findings-shape` | Template wording, reviewer sections, recording phrases, ADR-0094/0096 → **M**/**P**; re-ask and blocked report → J `ask` (`findings-shape refused`), D `test_blocked_on_shape_asks_and_never_fixes` | three `po-gate findings-shape` tests; the template's finding line → `po-gate`, `po ship file`; the narrowed Bash and no Bash → frontmatter; the two `Next action:` texts → `po` reads `findings-shape` (`lane.rs:194`) |
| `review-header-recorded.oracle` (s158, shipped) | Reviewer answer wording, note order, ADR-0104 → **M**/**P** | the first two lines of the template → `po record` (`compose.rs:7-15`); the `po-link-artifacts` run |
| `review-tree-gate` | — | all: `po-gate`, `po-eval grade` |
| `resume` | Orphan worktree **H** → `po next` warning, `po-session` (`project-lead`, `state-as-json.test.sh:test_blocked_by_names_each_stop_and_orphans_warn`) | — (deleted) |
| `reuse-ladder` | Reuse section, planner bullets, step 3 → **M** | — (deleted) |
| `grouped-validation` | **H** grouped approval under `Plan validation: human` → **M**; ADR-0014/0017 → **P** | — (deleted) |
| `ownership` | Scope check, ordering, Ownership box, ADR scope, manual record → **M**; implementer writes stay in `Owns` → `po-bounds` (`bounds.test.sh:85-92`) | `git commit -m "<id>: QA evidence"` in step 1 → `po` matches `QA evidence` (`lane.rs:187`) |
| `owns-overlap` | Rule wording, examples → **M**; overlap → `po` `overlap.rs` (`ready-set.cases`, `held-says-what-collides.oracle`) | — (deleted) |
| `diagnostic-skill` | Skill sections, three hypotheses, the `Fixes` wording elsewhere → **M** | `diagnostic` preload → frontmatter; `- **Fixes**:` … `Corrige` in the stories template → `po` (`stories.rs:159`) |
| `tests-beyond-examples` | Doctrine → **M** | — (deleted) |
| `oracle-intact-gate.oracle` (s150, shipped) | Usage header comment of `po-gate` (never printed) → **P**; review step 4 → **M** | the two `po-gate oracle-intact` tests |
| `floor-guard` | `test_review_runs_the_floor_guard` → **M** | the six `po-gate floor-guard` tests |
| `gate` | `test_rules_point_at_the_secret_gate` → `gate.test.sh` pre-commit tests | 22 `po-gate`/pre-commit tests |
| `project-lead` | The three text tests → **M**/**P** | eight `po-session`/installer tests |
| `commands-and-texts` | Retro, setup, help, matrix, stories, accessibility meta → **M**/**P** | — (deleted) |
| `structure` | Setup and Law phrases, tool output, hook list → **M** (secrets → `gate.test.sh`) | the template fence, M1 names, `Reads settings:` names → `po-lint`, installer; `<!-- Assembled by Polype.` → `bin/polype` |
| `post-m7-texts` | `docs/installation.md`, Law 6, overlap, ADR registry (#442); the loop-variable lint of this one file falls with it → **P**/**M** | — (deleted) |
| `leftovers` | Doctrine quoting (`po-run` behaviour → `run-ledger.test.sh`), ADR registry → **P** (#442) | `test_polype_declares_every_template_setting` → `polype check` |
| `final-leftovers` | Reviewer hook note, ADR link rule, overlap wording → **M**/**P** | — (deleted) |
| `docs-and-eval-cleanup` | `installation.md`, eval case text, Law 3 row and `po-gate` comments → **P**/**M** | `test_drift_message_fits_the_mode` → `po-eval` |
| `strict-checks-by-default` | Template sentence, `/po-architect` steps, architecture template, ADR-0097, values and the count of nine (#164) → **M**/**P** | `po-lint` on mutated and real profiles; no `Strict`/`Lint` setting in the template or in `/po-architect` → `po-lint`, installer |
| `drop-keeps-modified` | `bin/polype` header comment, ADR-0092/0088 registry with `:184` (#136, #442) and `installation.md` → **P** | the six installer tests |
| `ship-and-fleet-cleanup` (correction 2, in `Owns` since `8e2a5ad`) | `test_fleet_tests_bite` and its helpers, a mutation of a phrase test | `test_fleet_rules_agree`, left to s202 |

Note of 2026-11-21 (review, fix loop 1), on the `drive` row. "Root clean and on target" is guarded by `root-not-clean` (`po/src/ship/land.rs:275-295`, `ship-builds-the-landing-commit.oracle.test.sh:180`), not by `dirty-worktree`, which is the lane cleanup. Under `local`, `po ship land` refuses with `confirmation-required` (`ship-builds-the-landing-commit.test.sh:244`); only the wording of the question stays **M**.

## Tasks
Line numbers are those of `e322b00`. Delete each helper, variable or header comment a deletion leaves unused.
1. [x] Delete the 13 files: `drive-guards`, `fleet-wiring`, `surface-routing`, `tech-choice-backstop`, `plan-and-defect-paths-cleanup`, `resume`, `reuse-ladder`, `grouped-validation`, `owns-overlap`, `tests-beyond-examples`, `commands-and-texts`, `post-m7-texts`, `final-leftovers` (`tests/<name>.test.sh`). Test: `test_suite_still_runs_clean`, `test_no_script_lost_its_tests`.
2. [x] Routing and fleet files, keeping exactly the "Stays" assertions:
   - `drive`: keep the tool checks of `test_drive_never_writes_code_or_verdicts` (`:34-38`), and the name loop without its `^| $name |` line plus the three defaults in `test_settings_template_declares_fleet_settings`; delete the other seven functions.
   - `pilot`: delete `:11`, `:19-34`.
   - `wiring`: keep the frontmatter line of `:48-56`; delete `:18-46`.
   - `model-routing`: in `:15-26` keep the `template_settings` check; delete `:34-59`, `:73-91`, and the `contains` loop of `:61-69`.
   - `escalation-contract`: in `:42-54` keep `contains "$PLANNER" "$MARKER"` and the `## Writing the plan` marker hold; delete the other five functions.
   - `defect-and-routing-paths`: in `:25-35` keep the two marker checks; delete `'write no plan'`, the ADR lines, `:14-23` and `:37-44`.
   - Test: `test_contract_tests_stay`.
3. [x] Plan and execute files:
   - `planner`: delete `:11-31`, `:49-52`, and the three `contains` of `:39-47`.
   - `planner-writes-the-oracle`: `:23-42` keeps, for both templates, `require_file`, the heading check and `\| Oracle file \| cksum \|`; `:77-87` keeps the record lines; delete the other five functions.
   - `plan`: delete `:13-24`, `:28`, `:31-46`.
   - `research`: keep the `lacks_tool` of `:35-38` and `require_file` with `'**Owns**'` of `:40-46`; delete the rest.
   - `execute`: delete `:15-18`, `:25-39`.
   - `diagnostic-skill`: in `:37-50` keep the `diagnostic` preload and the stories-template `Fixes` line; delete `:14-35`.
   - Test: `test_contract_tests_stay`, then the six files.
4. [x] Review and gate files:
   - `review`: delete `:27-33`, `:49-52`, `'git diff --exit-code'`, `'\`subagent_type: reviewer\`'`, the `po-review` fix-loop phrase, and the `rev-parse` and `Reviewed tree:` `contains` of `:56-65`.
   - `review-lenses`: keep in `:70-96` the preload loop, `lacks_tool` and the two template counts; delete the rest.
   - `review-findings-shape`: delete `:87-94`, `:125-131`, `ADR96`, `ADR`; `:63-71` keeps only the template line; `:73-85` keeps the frontmatter, `lacks_tool` and the `Next action` hold; `:111-123` drops `'Any other exit'` and `'is not a malformed review…'`.
   - `review-header-recorded.oracle`: delete `:16-24`, `:54-73`, and the note-order check in `:26-52`.
   - `ownership`: in `:105-110` keep the `QA evidence` hold; delete the rest.
   - `oracle-intact-gate.oracle`: delete the `usage` lines (`:152-157`) and `:160-184`.
   - `floor-guard`: delete `:189-199`. `gate`: delete `:238-243`.
   - Test: those files, focused.
5. [x] The rest:
   - `project-lead`: delete `:271-294`.
   - `structure`: delete `:36-60`, `:66-84`.
   - `leftovers`: delete `:4-18`.
   - `docs-and-eval-cleanup`: delete `:10-21`, `:37-56`.
   - `strict-checks-by-default`: delete `:24`, `:84-92`, `:108-134`; `:59-82` keeps only the `po-lint` run (#164); `:94-106` keeps `require_file` and the two `Strict|Lint` checks.
   - `drop-keeps-modified`: delete `:165-188` (#136).
   - `ship-and-fleet-cleanup`: delete `:48-50`, `bites` (`:33-46`), `mutant`, `run_against` and `MUTANTS`.
   - Test: those files, focused; `ship-and-fleet-cleanup.test.sh`.
6. [x] Docs, then checks.
   - `docs/harnais.md`: a `## Le compte des lancements` section of at most 12 lines. It says what a launch is, how s202–s204 source the count, the base `origin/<Target branch>`, that it runs on every PR (a story that rightly removes a script's test lightens this oracle and says so), and what it does not prove.
   - `docs/defauts.md`: one sentence after `**Motif récurrent**`, saying M22 removes these tests family by family (s201: routing).
   - Run `bash tests/run.sh routing-phrase-tests-retired.oracle.test.sh` and the edited files. Then run the full suite once through `po-run`. Then confirm that `po-lint` is clean.
   - Test: the oracle and the suite.

## Scene viewpoints
—

## Run interdicts
- Empty diff:
  - `method/`, `po/`, `bin/`, `.claude/`, `.polype/`, `evals/`;
  - `tests/lib.sh`, `tests/run.sh`, `tests/journey/`, `tests/fixtures/`;
  - every test file outside `Owns`, except `ship-and-fleet-cleanup.test.sh` (task 5).
- No phrase assertion is added or reworded. A kept assertion keeps its text. Every function of `KEPT_CONTRACTS` keeps its name.
- `tests/routing-phrase-tests-retired.oracle.test.sh` keeps its sum `802676634 15112`. `tests/routing-phrase-tests-retired.test.sh` is not created.
- No version bump: the story does not touch `po/`.
- The full suite leaves no `polype-journey.*` nor a new `tmp.*` folder in `${TMPDIR:-/tmp}`.

## The pivot
The keep rule: an assertion stays only when it pins a literal that a named script parses out of a file. That literal can be a field, a line key, a marker, a template header or a frontmatter tool. Instructions, reasons and ordering go. Ways it could be wrong:
- **A kept literal no script reads.** For a sample of "Stays" rows, grep the literal in `po/src`, `method/hooks` and `bin` against the cited line.
- **A "proven after" that covers less.** For example, J `merge` covers `Ship confirmation: human` only under `pr`, and the row says so. Open the cited test for each sampled row.
- **The launch count lies.** It reads bash statically. Disable `launched` (return `True`) or its reader exclusion and the bite in `test_no_script_lost_its_tests` must fail. Then check the counts in the research against a run.
- **The count stays after M22** (settled by the lead). The comparison runs on every later PR. A story that rightly removes a script's test lightens this oracle and says so in its plan and its `## Oracle changes`; `docs/harnais.md` says it too (task 6).

## Files touched
- Deleted: the 13 files of task 1.
- Edited: `drive`, `pilot`, `wiring`, `model-routing`, `escalation-contract`, `defect-and-routing-paths`, `planner`, `planner-writes-the-oracle`, `plan`, `research`, `execute`, `diagnostic-skill`, `review`, `review-lenses`, `review-findings-shape`, `review-header-recorded.oracle`, `ownership`, `oracle-intact-gate.oracle`, `floor-guard`, `gate`, `project-lead`, `structure`, `leftovers`, `docs-and-eval-cleanup`, `strict-checks-by-default`, `drop-keeps-modified` (`tests/<name>.test.sh`). `ship-and-fleet-cleanup`.
- Unchanged: `drive-executes-next`, `review-tree-gate`.
- Written: the oracle, `docs/harnais.md`, `docs/defauts.md`, this research and this plan.

## Test strategy
Three oracle tests within `Test budget` 25. The count's own bite sits inside `test_no_script_lost_its_tests`, because `tests/routing-phrase-tests-retired.test.sh` is not in `Owns`. Every other change removes assertions; none is added.

Effect on the suite:
- 193 → 181 files, 960 → 828 functions (task 5 included).
- Duration: about 3 s fewer greps, about 10 s for the oracle, so net about +7 s on 8–13 min. s202–s204, sourcing the count, add about 7 s each.

Visual checks: none.

## Done when
- The oracle and the edited files pass. The full suite passes once through `po-run`. `po-lint` is clean.
- The reviewer samples `## Classification`, opening the cited readers and journeys, and makes the count bite.
- The implementer makes one commit with the research, the plan and the docs. The commit names #136 and #164.
