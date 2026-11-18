---
validated: yes
---
# Plan — s190-next-names-the-track

[Story](../stories.md) · [Research](../research/s190-next-names-the-track.md)

Branch `story/s190-next-names-the-track`. Read `docs/research/s190-next-names-the-track.md` first; this plan builds on it without repeating it.

Track: full. Escalation signal found on the story text: an API contract (`po next`'s JSON, documented in `docs/interface-agent.md`, gains a field). No defect line, no migration, no new dependency, no ADR needed: the order comes from ADR-0109, the extra field under `contract: 1` from d-0012.

## Story
`po next` gives the track of every `plan` action and routes `design` before `plan`, so the short track is a value the automaton reads and the order of the stages lives in one place (ADR-0109, #184). Criteria: `plan_action_names_its_track`, `unreadable_track_settings_ask`, `design_comes_before_plan`, `stories_file_reads_both_languages`, `planner_follows_the_track_it_is_given` (model-read), `version_goes_up`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Reading complexity and the fix line | this repository: `value()` `po/src/context/stories.rs:77-79` and the line branches `:137-143`; leading digits with the standard library | — |
| `goes_to_qa` outside `stage()` | this repository: moved, not rewritten, from `po/src/context/lanes.rs:279-292` | — |
| Reading `Story track`, `Flow threshold` | this repository: `setting()` `po/src/next/lane.rs:90-95`, `number()` `:119-121` | — |
| `track` in the JSON | dependency already installed: `serde`, `rename_all = "lowercase"` as `Stage` (`lanes.rs:14-15`), `skip_serializing_if` | nothing in the repository serializes an optional field this way yet |
| The track rule (`plan()` in `lane.rs`) | new code | `po` holds no track logic: the prose of `planner.md:27-33` is the only one |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/next-names-the-track.oracle.test.sh` | `3511875094 8020` |

| Criterion | Test |
| --- | --- |
| `plan_action_names_its_track` | `test_plan_action_names_its_track` |
| `unreadable_track_settings_ask` | `test_unreadable_track_settings_ask` |
| `design_comes_before_plan` | `test_design_comes_before_plan` |
| `stories_file_reads_both_languages` | `test_stories_file_reads_both_languages` |
| `planner_follows_the_track_it_is_given` | — model-read rule: no oracle test, judged in review (task 7, 8); candidate for a `po-eval` control arm (#208) |
| `version_goes_up` | `test_version_goes_up` |

The oracle sources the helpers of `tests/driver-next-action.oracle.test.sh` inside a subshell, writes its own stories (`card`) and its own `Story track`/`Flow threshold` lines (`track_settings`), and reads `po next` and `po state` only. It fixes these values, which the tasks must produce: the field `track` (`full`/`flow`) present on every `plan` entry and absent on every other; ask reasons `setting unreadable: Story track`, `setting unreadable: Flow threshold`, `no complexity`; a ready screen story gets `plan`/`ready`/`full` (its research), a lane with research and no design gets `design`/`no design`.

## Tasks
1. [x] **Stories carry complexity and fix line** — `po/src/context/stories.rs`: `Story` gains `complexity: Option<u32>` (leading ASCII digits of the trimmed `value()` of `- **Complexity**` or `- **Complexité**`; none or no digits → `None`) and `fixes: bool` (a `- **Fixes**` or `- **Corrige**` line with a non-empty value). Update the struct literal at `:117` and the module comment. Test: `test_stories_file_reads_both_languages`.
2. [x] **`goes_to_qa` extracted** — `po/src/context/lanes.rs`: `pub fn goes_to_qa(story: Option<&Story>, qa_stage: Option<&str>) -> Result<bool, Warning>` holding exactly the rule of `:279-292` (missing with a screen or a surface → `Err(MissingSetting)`, unknown value → `Err(UnreadableSetting)`); `stage()` calls it, pushes the `Err` warning and returns `None` as today. Re-export it in `po/src/context/mod.rs:17`. Test: the QA routing cases of `tests/fixtures/driver-cases/` and the `QA stage surfaces` run of `test_plan_action_names_its_track`.
3. [x] **The track on every `plan` action** — `po/src/next/mod.rs`: `#[derive(Serialize, Clone, Copy, Debug, PartialEq)] #[serde(rename_all = "lowercase")] pub enum Track { Full, Flow }`; `NextAction` and `Entry` gain `#[serde(skip_serializing_if = "Option::is_none")] track: Option<Track>`; `act()` sets `None`. In `po/src/next/lane.rs`, one `pub(super) fn plan(context: &Context, id: &str, reason: &str) -> NextAction`, first rule wins:
   1. `Story track` not exactly `full`, `flow` or `auto` (missing, `—`, other) → `act("ask", "setting unreadable: Story track")`;
   2. `full` → `Full`;
   3. the story `fixes`, `has_screen()`, or `goes_to_qa(story, lane_settings.qa_stage)` is `Ok(true)` → `Full`; `Err` → `act("ask", "setting unreadable: QA stage")`;
   4. `flow` → `Flow`;
   5. `auto`: `Flow threshold` not all digits (missing, `—`, other) → `act("ask", "setting unreadable: Flow threshold")`; no complexity → `act("ask", "no complexity")`; complexity ≤ threshold → `Flow`, else `Full`.
   Every `ask` reason stays a literal `act("ask", "...")` in `po/src/next/` (s200 reads them there). Call `plan()` at the three lane sites (`lane.rs:43`, `:51`, `:56`) and for each ready entry (`mod.rs:80-86`, reason `ready`). No warning is pushed: settings are read through `setting()`. `po state` carries the same through `lane_next`. Tests: `test_plan_action_names_its_track`, `test_unreadable_track_settings_ask`.
4. [x] **Design before plan** — `po/src/next/lane.rs`: move the screen-without-design block (`:60-73`, its two asks included) to just after the root-cause and technical-choice asks (`:45-49`), before `research, no plan` (`:50-52`). A lane with neither research nor plan still gets `plan`/`no research` (the research comes first, Law 1). Update the module comment if it names the order. Add one routing case to `tests/fixtures/driver-cases/a-wave.cases`: a screen story with research, no plan, `docs/design-system.md` removed → `ask`/`no docs/design-system.md` (the design's asks also come before the plan). Tests: `test_design_comes_before_plan`, `test_every_routing_case_is_a_fixture` (existing screen cases unchanged).
5. [x] **Fixture and pinned shape** — `tests/driver-next-action.oracle.test.sh` `project()` (`:38-53`): add `Story track:       auto` and `Flow threshold:    2` to the settings block; no case expectation changes. `tests/driver-next-action.test.sh:70`: the expected entry gains `"track": "flow"`. Test: `bash tests/run.sh driver-next-action.oracle.test.sh driver-next-action.test.sh held-says-what-collides.oracle.test.sh ship-order-and-closed-pr.test.sh ship-order-and-closed-pr.oracle.test.sh next-waits-on-dependencies.oracle.test.sh state-as-json.oracle.test.sh verbs-read-project-context.oracle.test.sh` — the last six unchanged.
6. [x] **Version 0.6.1 → 0.7.0** — `po/Cargo.toml:3`, the `po` entry of `po/Cargo.lock` (`:164-165`), `POLYPE_VERSION` at `bin/polype:28`. Test: `test_version_goes_up`, `bin/po-version-check`.
7. [x] **Planner takes the track** — `method/agents/planner.md`: `Reads settings:` (`:13`) drops `Story track` and `Flow threshold`; `## Which track` (`:27-33`) becomes, near this wording: take the `track` the driver gave, from the `plan` action of `po next` (`full` — a research file, then a plan built on it; `flow` — the short track); none given → stop and report; raise `flow` to `full` when the code shows a signal the story files do not, keeping the signal list with the exact phrase `, a defect to fix — a story carrying a \`Fixes\` line (\`Corrige\` in a French stories file)` once, the six-tasks rule and "say which one you found"; a story with a screen and no `docs/designs/<id>/design.md` gets its research only — the designer comes next, then the planner again for the plan. No `lines at most` in this section. `tests/planner.test.sh:52-54` go (the clause they pinned is rewritten); no phrase test replaces them. Check: `LC_ALL=C wc -w method/agents/planner.md` ≤ 1353; `bash tests/run.sh planner.test.sh diagnostic-skill.test.sh plan-and-defect-paths-cleanup.test.sh defect-and-routing-paths.test.sh escalation-contract.test.sh drive.test.sh planner-writes-the-oracle.test.sh reuse-ladder.test.sh`.
8. [x] **The driver hands the track over** — `method/commands/po-drive.md:61`, step 1: the planner gets the story id, the absolute worktree path and the `track` of its `plan` action, e.g. "the story id, the absolute worktree path and the action's `track`, under its own contract." Check: `LC_ALL=C wc -w method/commands/po-drive.md` ≤ 2452; `bash tests/run.sh drive.test.sh fleet-design.test.sh drive-executes-next.oracle.test.sh ship-files-the-other-findings.oracle.test.sh`.
9. [x] **The contract says it** — `docs/interface-agent.md`: at `:104`, a `plan` action carries `track` (`full`, `flow`) by the rule of task 3, absent on every other action, `contract` staying `1` (d-0012); the three new `ask` reasons; a story with a screen gets `design` once its research is on disk, before `plan`. At `:270`, the `next` row names the track. `:125` (trust signal from the plan's frontmatter) unchanged.
10. [x] **Whole suite** — `po-run --story s190-next-names-the-track --label 'Unit suite' -- 'bash tests/run.sh'`; `bin/po-version-check`; `bin/po-lint` if it reads `Reads settings:` lines.

## Scene viewpoints
—

## Run interdicts
- `tests/next-names-the-track.oracle.test.sh` keeps cksum `3511875094 8020`, or is changed only through `## Oracle changes` of the record.
- Empty diff outside `Owns`, in particular: `po/src/trust/` (the trust signal still reads `track:` from the plan's frontmatter), `po/src/state/`, `method/commands/po-flow.md`, `method/commands/po-orchestrator.md` (s191), `tests/diagnostic-skill.test.sh`, `tests/plan-and-defect-paths-cleanup.test.sh`, `tests/held-says-what-collides.oracle.test.sh`, `tests/ship-order-and-closed-pr*.sh`, `tests/next-waits-on-dependencies.oracle.test.sh`, `.claude/`, `.polype/`.
- No new `Warning` variant and no warning pushed for `Story track`, `Flow threshold` or a complexity.
- `"contract": 1` unchanged; the action list of `ACTIONS` (`driver-next-action.oracle.test.sh:9`) unchanged: no new action value.
- No existing routing case's `expect_*` line edited; cases are only added.
- No `ask` reason built with `format!`.
- `LC_ALL=C wc -w`: `method/agents/planner.md` ≤ 1353, `method/commands/po-drive.md` ≤ 2452.

## The pivot
"Design before plan" is read as Law 1 and ADR-0109 write it: research, design, plan. So `po next` still sends a screen story with no research to the planner (`plan`/`no research`, `full`), the planner writes the research only, and `design` comes once the research is on disk. Ways it could be wrong:
- The story wanted `design` as the first action, before any research: compare the ADR-0109 decision text ("recherche, design, plan") and the stage machine `lanes.rs:256-264`, which already puts `Research` before `Design`.
- A planner ignores the research-only rule and writes its plan: the design check now precedes the `plan` stage checks, so the lane still gets `design` before its plan is validated or executed; the reviewer reads task 7's sentence.
- Rule order of task 3: an unreadable `Story track` asks even for a story a forced signal would send to `full`, and `Flow threshold` is read under `auto` only (`method/templates/agents-local.md:67`); compare the criterion's "jamais une voie devinée".

## Files touched
`po/src/context/stories.rs`, `po/src/context/lanes.rs`, `po/src/context/mod.rs`, `po/src/next/mod.rs`, `po/src/next/lane.rs`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `method/agents/planner.md`, `method/commands/po-drive.md`, `docs/interface-agent.md`, `tests/driver-next-action.oracle.test.sh`, `tests/driver-next-action.test.sh`, `tests/fixtures/driver-cases/a-wave.cases`, `tests/planner.test.sh`, `tests/next-names-the-track.oracle.test.sh` (oracle), `docs/research/s190-next-names-the-track.md`, `docs/plans/s190-next-names-the-track.md`.

## Test strategy
Automated, all through the built `po` binary (bash, as the project's tests are; `po` has no Rust tests):
- Oracle, 5 tests: the track rules (each forced signal bites alone: the QA run is repeated with `QA stage: —`), the asks, the order, both languages, the version.
- Implementer: 1 routing case added (design asks before the plan); `driver-next-action.test.sh:70` adjusted; `planner.test.sh:52-54` removed. Total new tests 6, within `Test budget` 25.
- Regression: the four test files outside `Owns` that source the driver fixture must pass unchanged.
No visual check. The planner and driver prose (criterion 5) is judged by the reviewer by reading.

## Done when
One commit `s190-next-names-the-track: …` with research, plan, oracle and code; full suite green; `bin/po-version-check` passes; the review has no open critical finding; landed through a pull request.
