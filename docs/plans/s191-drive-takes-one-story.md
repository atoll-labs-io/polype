---
validated: yes
---
# Plan — s191-drive-takes-one-story

[Story](../stories.md) · [Research](../research/s191-drive-takes-one-story.md)

Branch `story/s191-drive-takes-one-story`. Read `docs/research/s191-drive-takes-one-story.md` first; this plan builds on it without repeating it.

## Story
One command moves work: `/po-drive` for every ready story, `/po-drive <id>` for one (ADR-0109, #210). `/po-orchestrator` and `/po-flow` are deleted from `method/`.
- `two_commands_are_gone` · `update_removes_them_from_a_project` · `words_go_down` — checked by the oracle.
- `drive_takes_an_id` · `nothing_only_they_said_is_lost` — read by a model: no oracle test, no phrase test; judged in review, and candidates for a `po-eval` control arm (#208).

## Reuse
No new code: the story deletes two files, rewrites prose and removes test assertions. `polype update` already drops intact files the new payload no longer ships (`bin/polype:1126-1129`), so the installer is not touched.

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| — | — | — |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/drive-takes-one-story.oracle.test.sh` | `2268829433 3512` |

| Criterion | Test |
| --- | --- |
| `two_commands_are_gone` | `test_two_commands_are_gone` — both files absent, `grep -rlE 'po-orchestrator\|po-flow'` over `method/` and `README.md` empty, `bin/po-lint method` exits 0 |
| `update_removes_them_from_a_project` | `test_update_removes_them_from_a_project` — a copy of `bin/` and `method/` holding both commands installs a throwaway project; `bin/polype update` from this tree leaves neither file, no `.before-polype`, no state line, no "modified, kept" line |
| `drive_takes_an_id` | — read by a model, judged in review |
| `nothing_only_they_said_is_lost` | — read by a model; the table under `## Rules the two commands carried` is what the reviewer checks |
| `words_go_down` | `test_words_go_down` — `method/` ≤ 72 702 − 3 000 words, and each non-test file of `Owns` at or under its count on `fb21c56` |

All three fail on the tree as it is (checked); a copy of the tree with both files removed and their names replaced passes all three (checked).

## Tasks
1. [x] **Delete** `method/commands/po-orchestrator.md` and `method/commands/po-flow.md` (`git rm`). Test: `test_two_commands_are_gone`, `test_update_removes_them_from_a_project`.
2. [x] **`method/commands/po-drive.md` takes an id.** `argument-hint: [status | <id>]`; the argument line (`:16`) says: `status` reports, empty runs a wave, anything else is a story. In `## Checks`, one line: an argument other than `status` is matched against `docs/stories.md` as `AGENTS.md` (`## Ids and branches`) says, zero or several matches → list them and stop. One sentence under `## The next action`: with an id, the run keeps only the entries of that story — its `actions` entry, or its `held` reason and `ref`, reported with nothing launched; no entry at all (shipped, or not in `po next`) → say so and stop. Lane preparation, ADR numbers, ships and the log apply to that one lane, with no extra prose. Add to the list of `## The decisions log` (`:103`): each track a planner raised to `full`. The file must end at or under 2 450 words: make room by cutting sentences **no test reads** (`grep -rF -- '<phrase>' tests/` before each cut; 23 test files read this file, most outside `Owns`). Leave the `ask` row (`:41`) as it is. Test: `test_words_go_down`; the rest is judged in review.
3. [x] **`method/commands/po-execute.md` carries the short-track sentence** that only `po-flow.md:88` carried: under `## Delegation`, "When the plan's frontmatter holds `track: flow`, append:" then the quoted sentence of `po-flow.md:88` word for word. Drop ", even when no orchestrator runs it" from check 7 (`:36`), keeping its start up to "**has a design**" (`design-handoff.test.sh:23`). The file must end at or under 850 words; cut only sentences no test reads. Test: `test_words_go_down`, `test_two_commands_are_gone`.
4. [x] **The other mentions.** `method/AGENTS.md:45` — the short track becomes the `track` `po next` gives the planner, research and plan in one file, same execute, review and ship, every gate in place; `:47` — `/po-drive <id>` walks one story through its cycle, the rest of the paragraph kept. `po-help.md:35` — `/po-drive` launches the QA (drop `/po-orchestrator`, keep "un agent vérifie sa surface avec le pilote qui lui va"); `:40` and `:46` go; a sub-bullet under `/po-drive` gives `/po-drive <story>`, keeping the `/po-drive` line `fleet-wiring.test.sh:48` quotes. `po-status.md:28` — a story in `ready` gets `/po-drive <id>`, the expected-track branch goes (`:25` stays). `templates/plan-flow.md:9` — "Written by the planner"; `:15` — the technical-choice exception points to `## Limits` of the planner instead of `## Approval` of `/po-flow`, keeping the marker line and the phrase "A signal present sends the story to the full track and no short plan is written". `skills/diagnostic/SKILL.md:3` — "by the planner and `/po-research`". `README.md:45` — `/po-drive <id>` for one story, `/po-status`; keep "une revue bloquée par la QA repart vers `/po-qa` sans consommer de fix run". `docs/migration.md:139` — "`/po-drive` a de quoi travailler". `docs/parite-killer-saas.md:64-65` — D15 cell `fait — \`method/agents/planner.md\`, \`method/templates/plan-flow.md\``; D16 cell `fait — \`method/commands/po-drive.md\``, its Polype column saying `/po-drive <id>` leads one story, no more words. `docs/direction.md:37` — "Pas avant s168." becomes "Fait par s191." `planner.md` and `po-research.md` need no change (research, row 3 and false assumption). No touched file grows. Test: `test_two_commands_are_gone`, `test_words_go_down`.
5. [x] **Tests that read the two commands**, file by file as `## Test triage` says: each assertion listed there is removed, nothing replaces it, every other assertion stays. Test: each edited file passes alone (`bash tests/run.sh <file>`), and the mutation tests of `plan-and-defect-paths-cleanup.test.sh` and `tech-choice-backstop.test.sh` still bite.
6. [x] **Close.** `bin/po-lint` clean; full suite through `po-run --story s191-drive-takes-one-story --label suite -- 'bash tests/run.sh'`; Test: the suite.

## Rules the two commands carried
Rows of `## Rules only the two commands carry` in the research, where each lives after the story. O = orchestrator, F = flow.

| # | Rule | After |
| --- | --- | --- |
| 1 | settings, stories file, id, model settings (O:24, F:24-25,34) | `po-drive.md` Checks; id matching added (task 2) |
| 2 | scope approved per `Entry mode` (O:26-29) | goes: `/po-stories` refuses an unapproved scope (`po-stories.md:21-24`); `po state` reads it |
| 3 | stories review not passed → warn (O:31) | `po-research.md:24`, read by the planner |
| 4 | screen story needs design system and `Design source` (O:33) | `po next` asks at the design stage; "before any worktree" goes |
| 5 | a human stop ends the run (O:35) | `po-drive.md:67`; one lane, so the run ends |
| 6 | track from `Story track`/`Flow threshold` (O:38-41, F:29-32) | `po next` (`lane.rs:19-46`) |
| 7 | screen or QA story → full; `QA stage` missing stops only QA stories (O:43, F:34,52) | `po next` (`lane.rs:28-35`) |
| 8 | flow escalation continues on the full track in the same worktree (O:45, F:48) | `planner.md:30` |
| 9 | escalation signals, before and after reading the code (F:37-46,50) | `planner.md:30`; "before any worktree" goes |
| 10 | research reused, diagnostic, `Root cause: not found` (O:48) | `planner.md:38,41`; `po next` `ask` |
| 11 | design only for a screen, reused (O:51) | `po next`; `po-drive.md:35,62` |
| 12 | plan reads `design.md` (O:54) | `po-plan.md:45` |
| 13 | technical choice first, then `Plan validation` (O:54-56, F:70-80) | `po next` `ask`, `po-plan.md` Approval, `po-drive.md:71-86`; F's "next free number" goes for the reserved number (`po-drive.md:56`, `planner.md:56`) |
| 14 | implementer model, fix runs, none on a QA or shape block (O:59, F:87,90) | `po-drive.md:36`, `po-execute.md` `## Model`, `po next` |
| 15 | design and oracle sentences (O:61-65) | `po-execute.md:56-62` |
| 16 | short-track sentence (F:88-89) | implementer: `po-execute.md` (task 3); reviewer: `reviewer.md:25` |
| 17 | QA after each execution, blocked, re-record (O:68-70) | `po-drive.md:37,64`; `po next` |
| 18 | review recorded, failure blocked (O:73, F:89) | `po-drive.md:65,88-93` |
| 19 | QA returns spend no fix run; two evidence commits → human (O:75-79, F:90) | `po next` (`lane.rs:187-192`) |
| 20 | findings-shape block → human (O:81, F:90) | `po next` (`lane.rs:194-196`) |
| 21 | two fix runs then human; no softened verdict (O:83, F:90) | `po next` (`Max attempts`); `po-drive.md:89` |
| 22 | ship, effective confirmation, cleanup after proof (O:86, F:91) | `po-drive.md:39,95-100` |
| 23 | decisions log rows and landing (O:89-93) | `po-drive.md:102-105` |
| 24 | log the track chosen and a flow escalation (O:89) | track: goes (computed, not decided); escalation: `po-drive.md` log list (task 2) |
| 25 | log written after ship or stop, `pr` at "Pull request ready" (O:93) | `po-drive.md:96,103` |
| 26 | no decision, no row (O:95) | `po-drive.md:103`, one row per decision |
| 27 | in-context work on the session model (O:21, F:21) | goes with its two commands; ADR-0036 still binds `/po-research`, `/po-plan` and `/po-design`, which carry its sentence (`po-research.md:19`, `po-plan.md:20`, `po-design.md:13`) |
| 28 | no Agent tool → stop (F:26) | `po-drive.md:22` |
| 29 | short-track plan content (F:65-67) | `planner.md:40,43` |
| 30 | "Nothing is relaxed", three contexts (F:19,94-99) | goes: Law 2 and Law 3 of `AGENTS.md`, ADR-0109 |
| 31 | finish lines (O:97, F:101) | `po-drive.md` `## Report` |
| 32 | human design approval on the single-story path (O:51, ADR-0019) | goes (d-0040, owner, 2026-11-18): one journey for the fleet and one story (ADR-0109); a person who wants to approve a screen runs `/po-design <id>` first, which keeps its approval (ADR-0019), as `po-help.md` says; the wave report names every unapproved design (`po-drive.md:113`) |

## Test triage
Removed assertions, by file and test function; a file not named here keeps every assertion. Variables and helpers left unused go with them.

| File | Removed | Stays |
| --- | --- | --- |
| `flow.test.sh` | `test_flow_keeps_every_gate`, `test_flow_checks_escalation_signals_twice`, `test_flow_respects_story_track` (all read `po-flow.md`) | `test_plan_flow_template_carries_verified_facts` |
| `wiring.test.sh` | `holds "$per_story" '`/po-flow`'` (`:31`); `contains "$STATUS" '`/po-flow <id>`'` (`:43`); `test_orchestrator_picks_the_track_and_runs_design`; `test_orchestrator_stops_without_approved_scope`; the two `ORCH` lines of `test_design_files_reach_the_implementer` | the rest |
| `escalation-contract.test.sh` | `$FLOW` from the loop (`:46`); the po-flow signals line (`:57`); the orchestrator stage 4 line (`:59`); the two orchestrator lines of `test_human_stops_do_not_halt_the_fleet` (`:67-68`) | the rest |
| `defect-and-routing-paths.test.sh` | the `$ORCH` pair of `test_every_path_runs_the_diagnostic`; `test_flow_names_the_qa_stage_exception` | the rest |
| `diagnostic-skill.test.sh` | the two po-flow signal lines (`:47-48`); `$FLOW` from the five-signals loop | the rest |
| `drive-guards.test.sh` | in `test_lone_decisions_are_all_logged`: `require_file "$ORCH"` and every orchestrator assertion after the two drive ones | the drive assertions |
| `framing-realign-and-orchestrator-log.test.sh` | `test_orchestrator_logs_every_lone_decision` | `test_every_landing_realigns_the_root` |
| `pilot.test.sh` | `test_orchestrator_has_two_real_checkpoints`, `test_orchestrator_never_codes` | the rest |
| `model-routing.test.sh` | po-flow reviewer line and the two orchestrator lines of `test_deciders_always_run_on_the_strong_model`; the ADR-0036 loop of `test_only_the_implementer_adapts`; in `test_model_refusal_stops_everywhere`, the po-flow/orchestrator loop and the two lines after it, and both names in the last loop (po-drive stays) | the rest |
| `qa-fleet.test.sh` | `test_orchestrator_runs_qa_for_a_screen`; the two `HELP` lines of `test_help_and_readme_show_qa`; the `ORCH` lines of `test_qa_blocked_review_goes_back_to_qa` and `test_qa_blocked_needs_a_blocked_status`, and both names from the latter's loop; `test_flow_and_execute_send_qa_blocks_to_qa` | README and po-review assertions, the loop over the other commands |
| `plan-and-defect-paths-cleanup.test.sh` | stage 2 lines of `test_defect_stops_agree` and `$ORCH` from its grep; the `'## Approval'` line and the po-flow Approval lines of `test_tech_choice_paths_agree`; the two po-orchestrator/po-flow `bites` lines | the `bites` on `plan-flow.md:15`, its phrase updated to the rewritten sentence (a mutation test: it stays) |
| `planner-writes-the-oracle.test.sh` | the po-flow lines of `test_planner_writes_oracle_files`; the `orch_line` lines of `test_oracle_files_are_expected_work` | the rest |
| `resume-shape-stop.test.sh` | both tests: the file is deleted | — |
| `reuse-ladder.test.sh` | the po-flow lines of `test_planner_requires_the_ladder` | the rest |
| `surface-routing.test.sh` | the `ORCH` line of `test_design_follows_a_screen_surface`; `ORCH`/`FLOW` from its loop and `ORCH` from the loop of `test_qa_follows_the_qa_stage`; `test_flow_escalates_a_surface_with_qa` | the rest |
| `tech-choice-backstop.test.sh` | every po-flow line of `test_flow_plan_sent_back_keeps_the_marker`; the function keeps its last line, renamed `test_plan_checks_stop_on_the_marker` | the two mutation tests |
| `ship-through-pr.test.sh` | `commands/po-flow.md` and `commands/po-orchestrator.md` from the squash loop | the rest |
| `record-writes-reports.test.sh` | `po-orchestrator:1908` and `po-flow:1572` from `test_commands_lose_words` (`:22`) | the rest |
| `fleet-wiring.test.sh`, `planner.test.sh`, `drive.test.sh`, `decision-inbox.test.sh`, `answer-comes-back.test.sh`, `ship-files-the-other-findings.oracle.test.sh` | nothing: their phrases and ceilings hold if tasks 2 and 4 keep the quoted lines | all |

## Scene viewpoints
—

## Run interdicts
- `po/`, `bin/` (installer included), `.claude/`, `.polype/`, every file under `docs/` but the four of `Owns`, and every test file outside `Owns`: empty diff.
- No shipped story, plan, review or ADR rewritten (`docs/stories.md`, `docs/plans/`, `docs/reviews/`, `docs/decisions/`).
- No new phrase test anywhere, and no test file added except the oracle; `drive_takes_an_id` gets no test.
- `po-drive.md` `ask` row unchanged (#381 stays open: this plan does not rewrite that line).
- No file named by `test_words_go_down` holds more words than its pinned count; no word ceiling of another test is raised.
- No version bump: `po/Cargo.toml`, `po/Cargo.lock`, `POLYPE_VERSION` untouched.

## The pivot
That `po next` plus the planner already carry every routing rule of the two commands, so deleting them loses nothing but rows 2, 4 (in part), 9 (in part), 24 (track), 27, 30 and 32. Ways it could be wrong:
- A rule only one of the two files carries is missing from the table: compare the table line by line with `git show fb21c56:method/commands/po-orchestrator.md` and `…/po-flow.md`.
- `/po-drive <id>` cannot open a story `po next` holds for `parallel` (`wave.rs:65-66`), which `/po-orchestrator` could always run: the plan accepts it (held → reported, nothing launched) rather than letting the driver route; compare with the old Stage 0, which never read `Parallel`.
- The pinned word counts become a ratchet on these files for later stories, as `record-writes-reports.test.sh:22` already is.

## Files touched
Deleted: `method/commands/po-orchestrator.md`, `method/commands/po-flow.md`, `tests/resume-shape-stop.test.sh`. Edited: `method/commands/po-drive.md`, `po-execute.md`, `po-help.md`, `po-status.md`, `method/AGENTS.md`, `method/templates/plan-flow.md`, `method/skills/diagnostic/SKILL.md`, `README.md`, `docs/migration.md`, `docs/parite-killer-saas.md`, `docs/direction.md`, and the 17 test files of `## Test triage` with removals. Added: `tests/drive-takes-one-story.oracle.test.sh` (oracle), this plan and its research.

## Test strategy
- Automated: the three oracle tests (3 of `Test budget: 25`), nothing else added. The installer test runs `bin/polype` itself on a throwaway project with a throwaway `HOME`, no mock. Every removed assertion read a phrase of a deleted file: their rules are now `po next` behaviour, which `tests/driver-next-action.oracle.test.sh` and `tests/next-names-the-track.oracle.test.sh` already exercise.
- By the reviewer: `drive_takes_an_id` (po-drive's argument line, check and filter sentence) and `nothing_only_they_said_is_lost` (the table against the two deleted files); both are candidates for a `po-eval` control arm (#208).
- Visual checks: none.

## Done when
Both commands gone from `method/` and `README.md`, `polype update` removes them from a project, `method/` 3 000 words lighter with no touched file grown, `bin/po-lint` clean, the full suite green through `po-run`, one commit `s191-drive-takes-one-story: …` on the story branch, a review with no open critical finding.
