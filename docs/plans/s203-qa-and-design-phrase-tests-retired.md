---
track: flow
validated: yes
---
# Plan (short track) — s203-qa-and-design-phrase-tests-retired

[Story](../stories.md)

Written by the planner. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s203-qa-and-design-phrase-tests-retired.md`. Line numbers are those of `5b79bfd`. Validated under `Plan validation: autonomous`, applying the owner's standing answers d-0051 and d-0052: no human reviewed this plan.

## Verified facts
**Story assumption partly false.** "The profile tests run `po-lint` on mutated profiles: they stay." The functions that run `po-lint` stay. But they also pin profile values that no script reads (`Licence`, `- Platform: xr`, the `Dev`/`Test`/`Build` commands, `Simulation command:`). Those lines go (task 5). Not a blocker.

- All 32 test files of `Owns` exist. Before: 177 files and 790 functions, counted as `tests/run.sh:33-36` loads them.
- The launch count (`tests/routing-phrase-tests-retired.oracle.test.sh:123-145`) finds 24 launching functions in this family:
  - `po-lint`: the 7 profile `*_pass_the_lint` functions, plus `qa-drivers:test_profiles_declare_their_driver`, `platform-setting:test_profiles_declare_their_platform`, `profile:test_lint_checks_profiles` and `profiles-hold:test_lint_holds_its_profile_rules`;
  - `po-gate.sh`: 5 `qa-gate` functions and `qa-report-returned-as-text:test_qa_report_path_stays`;
  - `po-bounds.sh`: 3 `qa-reads-ignore-rules` functions and 2 `throwaway-zone-holds` functions;
  - `polype`: `platform-setting:test_polype_declares_its_platform`;
  - `po`: `design-handoff:test_execute_mentions_the_design_when_present`, from the tools string at `:26`.
  All 24 stay. On a copy with every edit applied, every count is unchanged (`po` 178, `po-gate.sh` 136, `po-lint` 26, `po-bounds.sh` 48, `polype` 143). No `LOWERED_COUNTS` line is needed.
- `po` holds the routing of this family:
  - design before plan, and its stops: `po/src/next/lane.rs:86-94`, driver cases `a-wave.cases:6,17,28,56` and `resuming.cases:62`;
  - QA before review: `lane.rs:105-114`, `resuming.cases:91,101,111`;
  - a QA return is not a fix run: `lane.rs:179-193` (`review waited for QA`, `QA evidence committed twice`), `resuming.cases:139`;
  - `po record qa` writes the report and refuses an answer with no `QA status:` line: `po/src/record/mod.rs:175-181`;
  - `po` reads the `- **Surface**` line of stories: `po/src/context/stories.rs:149`;
  - `po` reads the `is current but` refusal of `po-gate`: `lane.rs:110`.
  - The journey `journey-reaches-every-stop.oracle:test_screen_story_goes_through_design_and_qa` walks design, QA, `po record qa` and the evidence commit.
- `po-gate` `qa_current` (`method/hooks/po-gate.sh:211`) reads `docs/qa/$1/report.md`, its last `QA status:` and its `Tree:`.
- `po-bounds` mode `qa` writes only in `docs/qa/<id>/` (`po-bounds.sh:280-287`) and runs reading git verbs only (`:581-607`). Its Bash commands are not bounded otherwise. The designer has no `po-bounds` mode (`:825-827`).
- `bin/po-lint` reads:
  - the template's `## ` headings, required in every profile (`:273,283-285`);
  - the `| Platform |` row (`:276`) and the `- Platform:` line (`:300-312`);
  - the `- QA driver:` value against `qa-drivers/` (`:315-326`);
  - the `| Capability |` table (`:254-262`);
  - a frontmatter saying `cannot edit files or run a shell` (`:144`).
  It reads no `Licence`, no `Origin` and no command value.
- The grounding tests (`*_is_grounded_in_*`) compare a profile with its upstream repository at `Commit profiled`. They read `Origin` and `Commit profiled`, and they bite on a made-up path. They are not phrase tests: they stay, together with the `Origin` and `Commit profiled` assertions their lint function holds.
- `floor-guard`, run on a copy with every edit applied, gives exactly 7 `test-file-deleted` flags, for the files of task 1, and nothing else. No removed line matches `expect\(|assert`.
- After: 171 files (7 deleted, the oracle added) and 727 functions (64 removed, 1 added). Every edited file passed `tests/run.sh` on that copy: 59 passed, the grounding tests included.

## Escalation signals
| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text | absent — only `tests/` changes |
| New screen | absent — `Surface: command` | absent |
| Authorization or tenant scope | absent — story text | absent — no `po/`, no `method/` |
| API contract | absent — story text | absent — no script output changes |
| New dependency | absent — story text | absent — bash and s201's helpers |
| Technical choice that deserves an ADR | absent — story text | absent. Every case falls under d-0051 or d-0052 (see `## Rules the owner decides`). |
| Defect to fix (`Fixes`/`Corrige`) | absent — `docs/stories.md:3313-3319` | absent |

## Story
The QA, design, driver and profile tests keep only what a script reads (#207, third family), except the security tests the owner keeps. Criteria:
- `kept_assertions_have_a_reader` and `what_only_a_product_proves_is_listed`: read by a model, judged in review;
- `contract_tests_stay`, `no_script_lost_its_tests`, `suite_still_runs_clean`: read by a script.

## Reuse
The one piece of new code is the oracle's list of what must stay. It reuses `tests_defined` and the count of `tests/routing-phrase-tests-retired.oracle.test.sh:221-225,123-190`, sourced unchanged as `docs/harnais.md:154` says, in the shape of `tests/ship-phrase-tests-retired.oracle.test.sh`. Everything else is deletion, plus one assertion unrolled from a loop (task 4).

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/qa-and-design-phrase-tests-retired.oracle.test.sh` | `3547054909 6749` |

| Criterion | Test |
| --- | --- |
| `kept_assertions_have_a_reader` | — model-read (owner rule of 2026-11-13). The reviewer samples `## Classification` and opens each cited reader. The S rows have no reader: that is the exception the owner decided (d-0052). Candidate `po-eval` arm (#208). |
| `contract_tests_stay` | `test_contract_tests_stay`. It checks two things: each function of `S203_KEPT` is still defined, and each line of `S203_KEPT_LINES` is still in its file. Those lines are what a script reads in a trimmed function, and every security assertion kept. It fails on the base until task 4 unrolls the simulation line. `po-lint` is already run by s201's test of the same name. |
| `no_script_lost_its_tests` | s201's `test_no_script_lost_its_tests`, which runs on this tree against `origin/main` in every suite run. |
| `suite_still_runs_clean` | s201's `test_suite_still_runs_clean`, plus the full suite once through `po-run`. |
| `what_only_a_product_proves_is_listed` | — model-read: `## What only a product proves`. The reviewer repeats that list in the review. |

## Classification
- **J** = `journey-reaches-every-stop.oracle:test_screen_story_goes_through_design_and_qa`.
- **D** = `driver-next-action.oracle` cases.
- **M** = a rule only a model reads.
- **P** = read by a person only (help, README, ADR registry, `docs/`).
- **H** = a stop or checkpoint, removed and named for s206.
- **S** = security, kept.
- **X** = listed under `## What only a product proves`.

| File | Removed (functions, or lines of a kept one) | Rule it pinned | Read by | Where the rule still lives / proven after |
| --- | --- | --- | --- | --- |
| `qa` | `test_qa_scope_comes_from_the_diff_and_the_criteria`, `test_help_lists_po_qa` | QA scope; help | model, person | `qa.md` Scope, **M**; **P** |
| `qa` | in `test_qa_report_has_steps_evidence_and_status`: `:13-15` | report fields, verdict words | model | `templates/qa.md`, **M**/**X**. The `Tree:`/`QA status:` ending stays (reader `po-gate` `qa_current`) |
| `qa` | in `test_qa_stops_without_a_browser_or_a_dev_command`: `:46-47,51-52` | `Dev` `—` stop; no browser, no report | model | **H1**, **H2**. The tool lines stay (Claude Code, `po-lint:144`) |
| `qa` | in `test_setup_asks_for_dev_and_qa_stage`: `:59-66` | QA stage values; setup step 2 | model | `po-setup.md`, **M**. Setting names stay (`bin/polype:608-631`) |
| `qa-gate` | `test_rules_list_qa_in_the_story_cycle`; `:109` | Law 1 row; Law 6 wording | person | **P**; D `resuming.cases:111` |
| `qa-gate` | `test_review_requires_a_current_qa_report` | review blocked without current QA; verified QA findings become review findings; the `qa-current` box of `templates/review.md` | script, model | `lane.rs:105-114`, D, J; the reviewer-side rules, **M** |
| `qa-gate` | `test_implementer_hands_the_screen_to_qa` | implementer leaves the screen to QA | model | **M** |
| `qa-drivers` | `test_qa_picks_the_driver_of_the_surface` | surface×platform table; missing driver → blocked | model | `qa-drivers/SKILL.md`, **M**, **H3** |
| `qa-drivers` | in `test_qa_runs_without_a_screen`: `:38-48,52` | Dev/browser checks scoped to screen | model | **M**. The porcelain/`mktemp` lines stay, **S2** |
| `qa-drivers` | `test_browser_driver_is_the_first_one` | `browser.md` points to the browser contract | model | the contract itself stays, **S1** |
| `qa-drivers` | `test_qa_report_names_its_driver` | `Driver:`, `Evidence:`, `## Not seen` | model | **M**/**X** |
| `qa-drivers` | in `test_profiles_declare_their_driver`: `:84-85` | next-forge's driver and `Dev` value | model | **M**; the template lines (mutant inputs) stay |
| `qa-fleet` | `test_drive_wave_includes_qa`, `test_status_reports_qa` | dispatch order; status column | script, model | `lane.rs:105-114`, D, J; **M** |
| `qa-fleet` | `test_help_and_readme_show_qa` | help and README rows | person | **P** |
| `qa-fleet` | `test_qa_blocked_review_goes_back_to_qa`, `test_qa_blocked_needs_a_blocked_status` | QA return keeps the fix loop; `Review status: blocked` with `/po-qa` | script | `lane.rs:179-193`; D `resuming.cases:139` |
| `qa-contract-holds` | `test_no_driver_row_blocks` | no row / no `Platform` → blocked; never `complete` | model | **H3** |
| `qa-contract-holds` | `test_own_evidence_never_blocks` | evidence set aside; lib through Bash; 60 s wait | model | **M**, **H4**; the new-path line stays in `test_scenario_rules_bite`, **S2** |
| `qa-contract-holds` | in `test_qa_declares_what_it_reads`: `:38-40,42`; in `test_scenario_rules_bite`: `:50-51` | declared settings; plan in scope; bad input is a finding | model | **M** |
| `qa-evidence-set-aside` | all 3 | first QA sets `?? docs/qa/` aside; waits; process groups | model | **M**, **H3**, **H4** |
| `qa-reads-ignore-rules` | `test_adr_widens_the_qa_allowlist` | ADR-0103/0026 frontmatter | person | **P**; the allowlist is held by the 3 kept `po-bounds` tests |
| `qa-report-returned-as-text` | in `test_qa_returns_its_report`: `:21-23,25-27`; `test_po_qa_records_the_report` | QA returns text; `/po-qa` pipes it word for word | script | `po record qa` (`record/mod.rs:175`); the `po-qa` tool lines stay in `qa`/`qa-gate`; `:24` stays, **S8** |
| `qa-report-returned-as-text` | `test_drive_records_the_report`, `test_adr_records_report_as_text`; `:53` | one qa line per wave; ADR-0102; `complete or blocked alike` | model, person | **M**, **P** |
| `design` | all 3 | new vs derived; render and look; design in the worktree | model, script | **M**/**X**; `lane.rs:86` reads `docs/designs/<id>/design.md`, D `a-wave.cases:28` |
| `design-system` | `:15-18` of `test_design_system_never_invents_an_identity` | no identity → ask the source | model | **H7** |
| `design-system` | `:32,35-40`; `:46-54`; `test_design_system_template_has_tokens_components_patterns` | contrast once; doctrine; template | model | **M**/**X**; the frontmatter lines stay |
| `design-handoff` | `test_implementer_expects_the_design_folder` | expected uncommitted files; stop on others; design committed | model | **H10**, **M** |
| `design-handoff` | `:23`; `test_plan_reads_the_design_when_present`, `test_setup_asks_design_details_after_the_source` | handoff wording | model | **M** |
| `design-handoff` | `test_defects_one_to_three_marked_fixed` | `docs/defauts.md` rows | person | **P** |
| `designer-browser` | `:23-24` | no browser tool named in `method/` | person | **P** |
| `fleet-design` | `:21-42` of `test_designer_agent_carries_the_design_contract` | designer contract; skill read from disk | model | **M**, **H8**; name and preload stay |
| `fleet-design` | `test_drive_inserts_design_between_plan_and_execute`, `test_drive_stops_a_screen_lane_without_a_design_system` | design between plan and code; stop without design system; report | script, model | `lane.rs:86-94`, D `a-wave.cases:6,17,56`, J; **H9** |
| `fleet-design` | `:108-120` of `test_designer_asks_no_one` | tie-breaks settled, no approval | model | **H9**; the `disallowedTools` line stays |
| `accessibility` | both | accessibility, keyboard walk | model | **X** |
| `scenario-driver` | `test_scenarios_cover_failure_paths`; `:8-17,32-33,44-45` | transcripts, failure paths, start/stop, `ADR-0059` | model | **M**/**X**, **H4**; the S lines stay, `:31,34` as **S9** |
| `mobile-web-driver` | all 3 | phone viewport; mobile rules; native never seen | model | **X**, **H5** |
| `godot-scene-driver` | `test_scene_driver_captures_without_a_window`; `:42,44,46-49` | scene driver; `Licence`, `Platform`, commands | model | **X**, **H6**; **M** |
| `ros-simulation-driver` | `test_simulation_driver_records_behaviour`; `:42,44,46-51` | simulation driver; profile values | model | **X**; **M** |
| `scene-and-simulation-drivers` | `test_viewpoint_lines_match_the_plan`; `:37-38,40-42,47-58` | viewpoint lines; capture; process groups | model | **M**/**X**; the set-aside lines stay, **S2** |
| `platform-setting` | `:18-24`, `:30-32`, `:88-112`; `test_setup_asks_the_platform` | QA stage row text; next-forge `web`; Surface admission and severities; setup | model | **M**. The Platform row (`po-lint:276`) and `**Surface**` (`stories.rs:149`) stay |
| `profile` | `:23`; `test_catalogue_doc_explains_the_three_levels` | `Licence:`; `docs/catalogue.md` | person | **P** |
| `profiles-hold` | `test_test_commands_fail_on_red`, `test_profile_slips_are_fixed` | iOS/Expo `Test` values, ADR-0069; profile prose | model, person | **X**, **P** |
| `cli-api`, `expo`, `flutter`, `native` profiles | the `*_use_scenarios`/`*_names_its_web_render`/`*_say_what_qa_cannot_do` function; the `Licence` lines (`:62`, `:48`, `:66`, `:71-72`) | platform, driver, commands; licence | model, person | **M**/**X**, **H3**; **P** |
| `next-forge-profile` | `test_..._states_its_gaps_against_adr_0020`, `test_..._declares_ownership_granularity` | gaps; ownership | model | **M** |
| `throwaway-zone-holds` | `test_implementer_knows_the_file_url` | `file://<path>` hint | model | **M** |
| `bricks` | all 4 | brick-note shape, host gaps, no code | person, model | **P**; a lint candidate, for the lead |
| `capability-bricks` | all 4 | default bricks, contract tests, architect, no payment brick | model | `capability-bricks` skill, **M**; a lint candidate, for the lead |
| `catalogue-wiring` | all 4 | setup offer, Law 1 text, help, parity matrix | model, person | **M**/**P** |

Unchanged: `qa-lanes-isolated.oracle` (word cap, until s205).

## Rules the owner decides
**No new decision.** Every case falls under d-0051 or d-0052. A rule that is both a stop and a security rule is kept, as s202 kept H5 and H8 under d-0052.
- **Removed, named for s206** (the rule itself):
  - **H1** On a screen story whose project sets `Dev` to `—`, the QA stops and writes nothing, and `/po-qa` asks for `Dev` (`qa.md:31`, `po-qa.md:20`).
  - **H2** On a screen story with no tool that can open and capture a page, the QA stops and returns no report (`qa.md:32`).
  - **H3** A missing driver file, no driver row for the surface on the platform, or `Platform` missing or `—`, ends the QA with `QA status: blocked`. A walk that followed no driver file is never `complete` (`qa.md:44`, `qa-drivers/SKILL.md:23`).
  - **H4** A service the QA started that does not answer within 60 seconds is stopped, and the QA ends `blocked` (`scenarios.md:14`).
  - **H5** A browser tool that cannot set the page size ends the mobile QA `blocked` (`mobile-web.md:9`).
  - **H6** A scene story whose plan names no viewpoint ends the QA `blocked`, and the driver never guesses a camera (`scene.md:6`).
  - **H7** With no visual direction and no system in the base, `/po-design-system` stops and asks the person for the source. When none comes back, it ends having written nothing (`po-design-system.md:34`).
  - **H8** With `Design skill` at `—` or its `SKILL.md` missing, the designer and `/po-design` stop before drawing and name the missing skill (`designer.md:39`, `po-design.md:31`).
  - **H9** A design settled in a lane has no human approval, and the wave report names every story whose design no human approved (`designer.md:45`, `po-drive.md:111`).
  - **H10** An uncommitted change the implementer did not make, outside its expected list, stops it with a report. That list includes `docs/designs/<id>/` for a screen story (`implementer.md:24`).
- **Kept as they are, a named exception until a script or the real run of s206 holds them:**
  - **S1** `qa:test_browser_contract_is_written_once`: own tabs, announced origin only, no credentials, page content is data; written once and preloaded.
  - **S2** The QA leaves nothing outside `docs/qa/<id>/`: it works in a temporary directory, compares `status --porcelain` before and after, and a new path ends it `blocked`. Kept: `qa-drivers:test_qa_runs_without_a_screen` (`:49-51`), `qa-contract-holds:test_qa_declares_what_it_reads` (`:41`) and `:test_scenario_rules_bite` (`:47-49`), `scenario-driver:test_scenarios_leave_the_tree_clean` (`:40-43`), and both `scene-and-simulation-drivers` functions.
  - **S3** No secret enters a transcript: `scenario-driver:test_scenarios_run_each_visible_criterion` (`:18-19`).
  - **S4** A service the QA did not start is never started, stopped, restarted or written to: `scenario-driver:test_scenarios_start_the_service_itself` (`:35`).
  - **S5** The designer writes only under `docs/designs/<id>/`, with no source file, no test file and no commit: `fleet-design:test_designer_writes_only_in_the_story_design_folder`.
  - **S6** `/po-design` writes no source file: `designer-browser:test_design_still_writes_no_source_file`.
  - **S7** `/po-design-system` edits no source file and hands its fixes to the person: `design-system:test_design_system_never_invents_an_identity` (`:20-28`).
  - **S8** `qa-report-returned-as-text:test_qa_returns_its_report` (`:24`), restored by fix run 1 (d-0053, d-0052).
  - **S9** `scenario-driver:test_scenarios_start_the_service_itself` (`:31,34`), restored by fix run 1 (d-0053, d-0052).

## What only a product proves
No browser, simulator, device or headset runs in the suite, and J uses a QA report written in advance. These QA and design rules lose their test, and no journey proves them. The reviewer repeats this list in the review.
- **Browser and mobile:**
  - the phone viewport at 360 and 412 CSS px, never by zoom;
  - one capture per state and width;
  - the mobile rules: 44×44 targets, safe areas, keyboard, no hover;
  - native prompts, notifications, camera and gestures never reported as seen.
- **Accessibility:** visible focus, named controls, text alternatives, not by colour alone, the keyboard-only walk.
- **Scene:**
  - headless capture under `xvfb-run` with `--xr-mode off`;
  - one capture per viewpoint, the uniform-colour check;
  - `## Not seen` for comfort, scale and hand tracking;
  - processes stopped.
- **Simulation:**
  - ROS and Gazebo isolation variables, `/clock` advancing;
  - bag record and extract, `ros2 daemon stop`, no node left;
  - `## Not seen` for noise, friction and emergency stop.
- **Scenarios:**
  - one invalid input per criterion, the error transcript, one transcript per scenario;
  - the service started on a free port in its own process group, then checked silent after the stop.
- **QA drivers:**
  - the first QA sets `?? docs/qa/` aside when its parent holds nothing else;
  - the surface×platform driver mapping itself (H3 covers only the stop).
- **Design:**
  - the mockup rendered over local HTTP in light and dark, desktop and mobile, nothing measured;
  - contrast measured once on every text/surface pair;
  - deltas only for a derived screen, one artefact for a new one.
- **QA report:** steps, capture, severity and `verified`/`probable`/`unverified`; the `Driver:` and `Evidence:` lines.
- **Profiles:** the iOS and Expo `Test` commands fail on red; Expo and Flutter `Dev` serve the web render.

## Tasks
1. [x] Delete `tests/qa-evidence-set-aside.test.sh`, `design.test.sh`, `accessibility.test.sh`, `mobile-web-driver.test.sh`, `bricks.test.sh`, `capability-bricks.test.sh` and `catalogue-wiring.test.sh`. Test: s201's `test_suite_still_runs_clean`.
2. [x] Edit the QA files by deleting lines:
   - `qa.test.sh`: `:13-15,36-43,46-47,51-52,59-66,68-71`;
   - `qa-gate.test.sh`: `:6,8-11,92-102,109,111-127`;
   - `qa-drivers.test.sh`: `:5-6,8,10-11,15-36,38-48,52,55-79,84-85`;
   - `qa-fleet.test.sh`: `:5-72`;
   - `qa-contract-holds.test.sh`: `:5,8-9,18-36,38-40,42,50-51`;
   - `qa-reads-ignore-rules.test.sh`: `:6,56-66`;
   - `qa-report-returned-as-text.test.sh`: `:4,6,8-9,11-12,14-15,17-48,53,56-73`.
   - Test: those files, focused, and `test_contract_tests_stay`.
3. [x] Edit the design files by deleting lines:
   - `design-system.test.sh`: `:6,15-18,32,35-40,46-54,56-64`;
   - `design-handoff.test.sh`: `:4,6-8,10-21,23,29-72`;
   - `designer-browser.test.sh`: `:23-24`;
   - `fleet-design.test.sh`: `:4,21-42,45-89,108-120`.
   - Test: those files, focused.
4. [x] Edit the driver files by deleting lines:
   - `scenario-driver.test.sh`: `:8-17,22-28,31-34,44-45`;
   - `godot-scene-driver.test.sh`: `:5,8,42,44,46-49,67-97`;
   - `ros-simulation-driver.test.sh`: `:5,8,42,44,46-51,69-101`;
   - `scene-and-simulation-drivers.test.sh`: `:4-5,8,10-12,15-34,37-38,40-42,47-58`, and insert `  contains "$SIMULATION" "$SET_ASIDE"` right after `:46`. That is the loop's assertion for `$SET_ASIDE`, unrolled, written as `:39` writes it for the scene.
   - Test: those files, focused; `test_contract_tests_stay`.
5. [x] Edit the profile files by deleting lines:
   - `platform-setting.test.sh`: `:6,8-9,18-24,30-32,70-85,88-112`;
   - `profile.test.sh`: `:23,82-93`;
   - `profiles-hold.test.sh`: `:4-7,10-37,142-153`;
   - `cli-api-profiles.test.sh`: `:62,77-92`;
   - `expo-profile.test.sh`: `:48,60-72`;
   - `flutter-profile.test.sh`: `:8,66,78-88`;
   - `native-profiles.test.sh`: `:9,71-72,88-104`;
   - `next-forge-profile.test.sh`: `:106-130`;
   - `throwaway-zone-holds.test.sh`: `:62-65`.
   - Test: those files, focused.
6. [x] Checks.
   - Run the oracle, `routing-phrase-tests-retired.oracle.test.sh` and the 24 edited files, focused.
   - Then run the full suite once through `po-run --story s203-qa-and-design-phrase-tests-retired --label 'Unit suite' -- 'bash tests/run.sh'`. Then run `bin/po-lint method`.
   - Expect 177 → 171 files and 790 → 727 functions.
   - Expect `po-gate floor-guard s203-qa-and-design-phrase-tests-retired origin/main` to give exactly the 7 `test-file-deleted` flags of task 1.

## Scene viewpoints
—

## Run interdicts
- Empty diff:
  - `method/`, `po/`, `bin/`, `boilerplates/`, `docs/` except this plan and the record;
  - `tests/lib.sh`, `tests/run.sh`, `tests/journey/`, `tests/fixtures/`;
  - `tests/routing-phrase-tests-retired.oracle.test.sh`, `qa-lanes-isolated.oracle.test.sh`, and every test file outside `Owns`.
- No assertion is added or reworded, except the unrolled line of task 4. Every kept line keeps its text, the S lines included. Stale header comments stay, as at s202.
- The oracle keeps `3547054909 6749`. No `tests/qa-and-design-phrase-tests-retired.test.sh` is created. No version bump. Nothing is left in `/tmp` or `${TMPDIR}`.

## Files touched
- Deleted (7): task 1.
- Edited (24): tasks 2 to 5.
- Unchanged in `Owns`: `qa-lanes-isolated.oracle`.
- Written: the oracle and this plan.

## Test strategy
One oracle test, within `Test budget` 25. The other three criteria that a script reads are held by s201's tests, on this tree. Everything else removes assertions.

## Done when
- The focused files and the oracle pass. The full suite passes once through `po-run`. `po-lint` is clean.
- The reviewer samples `## Classification`, checks that floor-guard gives only the 7 expected flags, accepts the d-0052 exception and repeats `## What only a product proves`.
- The implementer makes one commit with this plan.
