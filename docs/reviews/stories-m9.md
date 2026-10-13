# Stories review: Polype, milestone "M9 — L'autonomie" (s101–s104)

This is a one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). It was done on 2026-10-13, in a context that did not write the stories, against `docs/stories.md` lines 1540–1610 of the first M9 draft.

- **Scope source:** the four accepted ADRs `docs/decisions/ADR-0074-le-cadrage-se-valide-en-conversation-un-element-a-la-fois.md`, `ADR-0075-le-ship-suit-le-processus-de-revue-du-depot.md`, `ADR-0076-la-session-principale-est-le-chef-de-projet.md` and `ADR-0077-le-chef-escalade-peu-et-ne-tranche-jamais-seul-un-choix-technique.md`.
- **Platform:** `cli`.
- **Shape:** follows `docs/reviews/stories-m8bis.md`.

Review status: complete

## Coverage
| Scope item (ADR decision bullet) | Covered by | Covered |
| --- | --- | --- |
| 0074: each story, ADR and brief or PRD section is put to the person on its own: what, why, options turned down or criteria, then Approve / Modify / Discard | s101 `one_item_per_question`, `summary_short_but_complete` | yes |
| 0074: the summary aims short but grows when the subject needs it | s101 `summary_short_but_complete` | yes |
| 0074: files are written after approval, with no request to reread them | s101 `one_item_per_question`, `framing_never_asks_to_read_a_file` | yes |
| 0074: the stories-reviewer stays automatic and brings up only its criticals, one at a time | s101 `stories_review_surfaces_criticals_only` | yes (answers unstated, minor) |
| 0074 Neutral: existing guards are kept | s101 note | yes |
| 0075: `/po-setup` reads the forge and proposes `Ship confirmation`; the person can change it | s102 `setup_reads_review_rules_from_the_forge` | yes |
| 0075: the value carries its origin | s102 `setting_records_its_origin` | partly: the suffix is read as part of the value (major) |
| 0075: the forge is reread at each ship; tightening → `human (forge)`; a `(forge)` value goes back to `automatic` | s102 `forge_tightening_switches_to_human` | yes |
| 0075: a chosen value never moves; the settings rule is loosened only for `(forge)` | s102 `chosen_value_never_moves` | yes |
| 0075: under `human` in `pr` mode, open the PR and move on; clean up once the merge is proven | s102 `pr_wait_does_not_block_the_fleet` | yes (conflicts with "Ships stay serial", major) |
| 0075: the `ship-allowed` gate is unchanged | s102 `ship_gate_unchanged` | yes |
| 0075 Neutral: a forge with no readable API keeps the setup value | s102 note only | partly (minor) |
| 0076: `AGENTS.md` names the main session as project lead | s103 `rules_name_the_project_lead`, `lead_answers_before_driving` | yes |
| 0076: a `SessionStart` hook gives the state, pending escalations included | s103 `session_hook_reports_state_read_only`, `installer_wires_the_session_hook` | partly: pending escalations undefined on disk (major) |
| 0076: the `/po-*` commands are the lead's tools | nothing to deliver | yes |
| 0076: Law 2 holds; a subagent is not the lead | s103 `rules_name_the_project_lead` | yes |
| 0077: three escalation reasons | s104 `rules_list_the_three_escalation_motives` | yes (inconsistency undefined, minor) |
| 0077: every technical choice deserving an ADR is discussed first; options ranked by four criteria | s104 `tech_choices_are_never_settled_alone`, `options_ranked_by_owner_criteria` | **partly: the plan stage is not covered (critical)** |
| 0077: an implementation detail inside a validated plan stays with the lead | s104 `tech_choices_are_never_settled_alone` | yes |
| 0077: existing stops go to the person at once, the fleet keeps running | s104 `human_stops_do_not_halt_the_fleet` | yes |
| 0077: decisions taken alone go to `docs/decisions-log.md` | s104 `lead_logs_what_it_decides_alone` | yes (commit timing unstated, major) |
| 0077: no gate opens differently | s104 note, s102 `ship_gate_unchanged` | yes |
| 0077 Neutral: `capability-bricks` takes on the criteria | s104 `options_ranked_by_owner_criteria` | yes |

## Exclusions
None of the options turned down by ADR-0074 to ADR-0077 is revived.

## Findings
- **critical — s104, technical choices are still made alone at the plan stage.** `method/commands/po-plan.md:45` and `method/agents/planner.md:53` have a lane settle a library or data-model ADR alone, and `po-flow.md` plans in its own context; under `Plan validation: autonomous` the lane validates itself. Fix: own those three files and add a criterion that such a plan never validates itself and goes to a person.
- **major — s102, the origin suffix changes the value every reader sees** ("value is the text after the first colon, trimmed"). Fix: "Reading settings" treats a trailing suffix as the origin; one language for the suffix.
- **major — s102, waiting on a PR conflicts with "Ships stay serial".** Fix: say whether the next PR may open before the earlier one merges; keep the phrases pinned by `tests/fleet-wiring.test.sh`.
- **major — s103, "escalades en attente" has no definition on disk.** Fix: the cases `/po-drive status` lists for a human, plus a PR waiting under s102; conversational escalations not shown.
- **major — s104, when the decisions log is committed.** An uncommitted line would dirty the root and stop every local ship. Fix: commit timing and branch; list it among framing files.
- **minor** — s102: the `Plan validation: autonomous` default traces to no decision bullet; unowned tests pin `po-setup.md`; the no-API case is only a note. s101: unowned tests pin the framing texts; `/po-stories-review` lacks AskUserQuestion; answers to a critical, approval of `docs/architecture.md` and the unit of `/po-design-system` are unstated; `codebase-analysis/SKILL.md` is owned for nothing. s103: `install <project>` and `update` missing; unowned installer tests; `jq` would become a hard dependency of `init`; close to a 4; `lead_answers_before_driving` names no file; nothing says what changes in `po-help.md` and `docs/installation.md`. s104: "inconsistency" undefined; unowned tests pin `capability-bricks`. Milestone: no note names the tests pinning `method/AGENTS.md`.

## Not verified
Every test pinning `po-drive.md` and `po-orchestrator.md`; whether `/po-drive` already keeps lanes running after a human stop; how `bin/polype` would handle `.claude/settings.json`; whether a main session can launch `/po-drive` by itself; Owns against stories outside M9; the suite, `bin/po-lint` and `tests/overlap.test.sh`; every older ADR.

Max severity: critical
Stories ready: no

> Answered at the next commit, 2026-10-13. The critical was put to the person, who approved the fix: s104 owns `po-plan.md`, `po-flow.md` and `planner.md` and gains `plan_with_a_tech_choice_waits_for_a_human`. Majors: s102 reads a trailing `(forge)`/`(chosen)` as the origin in "Reading settings" and says opening a PR is not landing, keeping the "Ships stay serial" phrases; s103 defines pending escalations as the `/po-drive status` human cases plus a waiting PR; s104 commits the log alone on `Target branch` after each wave and lists it among framing files. Minors: answered in the criteria and notes (s102 owns `po-flow.md`, `template_defaults_trust_the_gates` traces to ADR-0077; s101 drops `codebase-analysis`, states the critical answers and the units; s103 names every pose, skips only the hook without `jq`, adds `help_says_no_command_needed`; s104 defines inconsistency; pinned tests are named in notes). Stories ready: yes.
