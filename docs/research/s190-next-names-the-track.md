# Research — s190-next-names-the-track

[Story](../stories.md)

## Structuring facts
- **False assumption of the story**: `goes_to_qa` is no function. It is a local of `stage()` at `po/src/context/lanes.rs:279-292` that pushes a warning and returns `None` from `stage()`; `has_screen` is the method `Story::has_screen` at `po/src/context/stories.rs:21-23`. The track needs `goes_to_qa` outside `stage()`, so it is extracted first. (The story's `lanes.rs:254-268` and `planner.md:26-31` have drifted: the lines are `lanes.rs:254-292` and `planner.md:27-33`.)
- **Unsaid by the story**: in the fleet one planner writes the research *and* the plan (`method/agents/planner.md:29`, `method/commands/po-drive.md:61`). Law 1 and ADR-0109 fix the order research, design, plan. So for a screen story, "design before plan" means the planner stops after the research when no `docs/designs/<id>/design.md` exists, and `po next` routes `design` once the research is on disk.
- **Unsaid by the story**: the fixture `project` of `tests/driver-next-action.oracle.test.sh:23-57` writes no `Story track` and no `Flow threshold`. Once a missing track asks, every `plan` expectation of the 56+ routing cases, and of the three test files outside `Owns` that source this helper, turns into `ask`, unless the fixture gains both lines.
- **Pinned phrases outside `Owns`**: the `## Which track` section of `planner.md` must keep, exactly once, `, a defect to fix — a story carrying a \`Fixes\` line (\`Corrige\` in a French stories file)` (`tests/diagnostic-skill.test.sh:45-46`, `tests/plan-and-defect-paths-cleanup.test.sh:79`), and must not add a `lines at most` before the research cap (`tests/planner.test.sh:9,24-31`).
- `po` reads settings without warnings through `context.project.setting()` (`po/src/context/mod.rs:100-101`, used for `Plan validation` at `po/src/next/lane.rs:90-95`). A new warning would break the exact `warnings` lists of `tests/verbs-read-project-context.oracle.test.sh:87-130`.

## Story
`po next` gives the track (`full` or `flow`) of every `plan` action, and routes `design` before `plan` (ADR-0109, #184), so the short track is a value the automaton reads and the order of the stages is written in one place.
- `plan_action_names_its_track` — every `plan` action carries its track: `flow` when `Story track` and `Flow threshold` admit the story's complexity, else `full`; a story with `Corrige`/`Fixes`, going to QA, or with a screen is `full`.
- `unreadable_track_settings_ask` — `Story track` or `Flow threshold` unreadable, or a story with no complexity under `auto`, gives `ask` with the reason.
- `design_comes_before_plan` — a story with a screen and no design gets `design` before `plan`.
- `stories_file_reads_both_languages` — complexity and fix line read in a French or English stories file.
- `planner_follows_the_track_it_is_given` — the planner takes the track; may raise it to `full` on a signal the files do not say, and says so; `planner.md` and `po-drive.md` hold no more words than before. Model-read: no oracle test.
- `version_goes_up` — minor step, three places.

## Current code
- `po/src/next/mod.rs:15-19` `NextAction { action, reason }`; `:39-44` `Entry { story, action, reason }`; `:72-88` builds `actions`: one per lane through `lane::next`, then `plan`/`ready` for each ready story (`:80-86`). `:101-103` `lane_next` feeds `po state`'s `lanes[].next` (`po/src/state/mod.rs:14,85`).
- `po/src/next/lane.rs:22-88` `next()`: landed → dependency → decision → no stage (`ask no po-gate` / `setting unreadable: QA stage`) → `:42-44` no research and no plan → `plan`/`no research` → `:45-49` root cause / technical choice asks → `:50-52` no plan → `plan`/`research, no plan` → `:53-59` stage `plan` → `validate-plan` / `plan`/`plan-validated refuses` / ask → `:60-73` screen without design → design asks / `design`/`no design` → stage match. So a screen story with research gets `plan` before `design` (#184).
- `po/src/context/lanes.rs:243-297` `stage()`: no plan → `Research` without research, `Design` for a screen without design, else `Plan` (`:256-264`): the stage machine already has the Law 1 order; `lane.rs` disagrees with it.
- `po/src/context/stories.rs:6-18` `Story { id, surface, depends_on, owns, milestone }`; `:100-146` `parse`: `- **Surface**`, `- **Depends on**`/`- **Dépend de**`, `- **Owns**` (`:137-143`); `value()` at `:77-79` takes what follows the first colon, so `- **Complexité** : 3` and `- **Complexity**: 3` both give ` 3`. No complexity, no fix line read today.
- `po/src/context/lanes.rs:175-198` `LaneSettings.qa_stage` from `settings.optional("QA stage")`; read only when stories and landed set are (`po/src/context/mod.rs:162-170`), which `ready_and_held` also requires (`po/src/next/wave.rs:9-13`).
- `method/agents/planner.md:13` reads `Story track`, `Flow threshold`; `:27-33` decides the track in prose. 1353 words (`LC_ALL=C wc -w`).
- `method/commands/po-drive.md:33` table row `plan`; `:61` step 1 passes "the story id and the absolute worktree path". 2452 words; caps 2481 (`tests/ship-files-the-other-findings.oracle.test.sh:9`) and 2500 (`tests/drive-executes-next.oracle.test.sh:10-13`).
- `docs/interface-agent.md:101` (stages), `:104` (`next.action` list), `:270` (`next` verb row). `:125` documents the `track` trust signal read from the plan's frontmatter: unchanged by this story.
- Version: `po/Cargo.toml:3`, `po/Cargo.lock:164-165`, `bin/polype:28`, all `0.6.1`; `PO_SUMS` is empty (`bin/polype:34-35`), so nothing else follows the version. `bin/po-version-check` compares against `origin/main`.

## Attachment points
- `NextAction` (`po/src/next/mod.rs:15`) gains an optional `track`, serialized only when set, so `wait`, `ask`, … keep `{action, reason}` (exact checks at `tests/next-waits-on-dependencies.oracle.test.sh:31-33`).
- One function in `po/src/next/lane.rs` builds every `plan` action: the three lane sites (`:43`, `:51`, `:56`) and the ready entries (`mod.rs:80-86`).
- `Story` (`stories.rs:6`) gains `complexity` and `fixes`; parsed beside `:137-143`.
- `goes_to_qa` extracted from `lanes.rs:279-292` to a `pub fn` of `lanes.rs`, re-exported at `po/src/context/mod.rs:17`.
- The design check of `lane.rs:60-73` moves before `:50-52`.
- `ask` reasons stay literal `act("ask", "...")` in `po/src/next/`: s200 reads that list from the sources (`docs/stories.md`, notes of s200).

## Verified interfaces
- `fn act(action: &str, reason: impl Into<String>) -> NextAction` — `po/src/next/lane.rs:13-15`.
- `fn setting(context: &Context, name: &str) -> Option<String>` — `lane.rs:90-95` (missing → `None`, `—` is a value).
- `Project::setting(&self, name) -> Setting` — `po/src/project.rs:55-67`: first line starting `Name:` with a non-empty value, anywhere in `AGENTS.local.md`.
- `Stories::find(&self, id) -> Option<&Story>` — `stories.rs:148-150`.
- `Warning::{MissingSetting, UnreadableSetting}` — `po/src/context/mod.rs:23-30`.
- Existing ask reason reused for an unreadable QA stage: `setting unreadable: QA stage` (`lane.rs:38`).
- Test helpers: `project`, `setting`, `story`, `lane`, `research_in`, `plan_in`, `design_in`, `po_in`, `next_shape`, `check_expectations` — `tests/driver-next-action.oracle.test.sh:12-208`; `story` always writes `- **Complexité** : 1` (`:69-77`).

## Traps
- **Fixture settings**: add `Story track` and `Flow threshold` to `project()` (`driver-next-action.oracle.test.sh:38-53`); `auto` and `2` keep every case's complexity 1 on `flow`. `tests/held-says-what-collides.oracle.test.sh`, `tests/ship-order-and-closed-pr.test.sh`, `tests/ship-order-and-closed-pr.oracle.test.sh` and `tests/next-waits-on-dependencies.oracle.test.sh` source that helper and are outside `Owns`: they must pass unchanged.
- `tests/driver-next-action.test.sh:70` compares `.actions` to an exact object without `track`: it changes with the story (in `Owns`).
- `tests/planner.test.sh:52-54` pins the settings and the `Flow threshold` sentence the story rewrites (in `Owns`).
- Pinned `planner.md` phrases outside `Owns` (see Structuring facts) and pinned `po-drive.md` phrases: `the story id and the absolute worktree path` in the wave section (`tests/fleet-design.test.sh:57`, still held by step 2 at `po-drive.md:62`), `No dispatch shape is imposed` (`tests/drive.test.sh:103`), `the number of messages the dispatch took is not evidence of anything` (`tests/drive.test.sh:120`).
- The routing cases count must stay ≥ 56 (`driver-next-action.oracle.test.sh` `test_every_routing_case_is_a_fixture`); existing screen cases (`a-wave.cases:6-36`, `resuming.cases:62-69`) carry a validated plan and keep their result once the design check moves up.
- `test_next_on_this_repository_is_fast_and_writes_nothing` runs `po next` on this repository (`Story track: auto`, `Flow threshold: 3` in `AGENTS.local.md`): fine.
- Version-bump oracles of earlier stories check "at least" (`tests/inbox-guards-bite.oracle.test.sh:153`, `tests/stale-decisions-are-flagged.oracle.test.sh:151`): 0.7.0 passes them.
- The repository's installed `.polype/version` stays 0.6.1: `po` 0.7.0 run here warns `method-version-mismatch`, as after every bump.
- No migration; no dependency.

## Open questions
- Is `Flow threshold` read outside `auto`? The settings template says it applies under `auto` only (`method/templates/agents-local.md:67`): the plan reads it under `auto` only, and the oracle pins that.
- Do forced signals beat an unreadable `Story track`? The plan asks first on an unreadable `Story track` (one rule, no partial reading), then `full`, then the forced signals.
- A screen story with an unvalidated plan and no design: with the design check moved up, it gets `design` while its stage reads `plan`. Kept: the Law 1 order wins; the case comes only from a lane planned before this story.

## Complexity
Story 3 → 3. Rust changes are local (one struct field, one parser branch, one extracted function, one reordered check); the weight is in the prose files (word caps, phrases pinned by tests outside `Owns`) and in the shared fixture that four test files outside `Owns` source.

## Split
—
