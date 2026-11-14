# Research — s172-commands-read-po-state

[Story](../stories.md)

## Structuring facts
- **False assumption 1 — `po state` does not hold what `po-session` prints.** Criterion `session_hook_prints_from_po_state` asks for an unchanged output on the existing test cases while `po-session` derives nothing. `po state` (`po/src/state/mod.rs:17-32`) has no per-item framing (only `stage`/`next`, `po/src/context/framing.rs:218-222`), no lane path (`Lane.path` is not serialised, `po/src/state/mod.rs:9-15`), only the **first** stop of a lane (`po/src/context/lanes.rs:278-330`) and not the `Fix loop:` value printed in `Max attempts reached (Fix loop: 2, Max attempts: 2)`, no `CLAUDE.md` hint, and `ready` is `null` without `Parallel` (`po/src/next/wave.rs:14-17`). Reproduced below. `po/` is not in `Owns`.
- **False assumption 2 — `Owns` lists the tests that pin this story.** Only `tests/session-and-gate-checks.test.sh` is in `Owns`; **16 test files outside `Owns`** assert something this story changes (table below), and the suite runs with an empty `CLAUDE_CONFIG_DIR` (`tests/run.sh:16-19`), where `po-session` would find no `po` at `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po` (`method/AGENTS.md:151`, `method/commands/po-drive.md:29`). Every session test would then print the missing-`po` line.
- **False assumption 3 — `/po-retro` can drop its review reading and keep its phrases.** `po state` gives, per shipped story of the current milestone (all with `--all`), `fix_loops` and `max_severity` of the last review (`po/src/trust/mod.rs:12-23`, `:51-60`). It gives no per-review severities, finding counts, blocked reviews and causes, blocked QA walks, open majors, recorded runs, nor any `path:line`, which `po-retro.md:49-51` requires for every figure, and nothing for a story still in flight. The notes keep `tests/po-retro.test.sh` and `tests/commands-and-texts.test.sh`, which pin exactly those measures (`tests/po-retro.test.sh:12-21`, `tests/commands-and-texts.test.sh:22-23`).
- **Root cause (#203, the part this story covers):** `method/hooks/po-session.sh:56-263` derives framing, lanes, shipped/ready and the human stops itself, a second copy of `po/src/context/framing.rs` and `lanes.rs`; the two already diverge (reproduction). `po-status.md:16-39` and `po-retro.md:28-41` hold a third reading in prose.
- **No plan is written.** The story contradicts itself against the code and its bounds; the lead corrects the story (Owns, and either criterion 1 or `po state`'s contract) on `main` before a plan. Options under Open questions.

## Story
`po-session`, `/po-status` and `/po-retro` take what they show from `po state`, so there is one reading of a project's state, the one an external agent also gets. Criteria: `session_hook_prints_from_po_state` (oracle), `session_hook_survives_a_missing_po` (oracle: a line naming the installer, exit 0; a `po` version warning shown as is), `status_and_retro_read_po_state` (model-read, judged in review; the test only checks each file has fewer words: `wc -w` gives 1101 for `po-status.md`, 977 for `po-retro.md` today). `po-session.sh` stays bash (ADR-0116). Complexity 2, depends on s170 (shipped). `Corrige : issue #203 en partie`.

## Diagnostic
- Track: full. The `Corrige` line is a defect signal; also an API contract signal after reading the code (assumption 1 needs `po state` fields).
- Reproduction 1 (fixture of `test_session_hook_reports_state_read_only`, `tests/project-lead.test.sh:60-90`, rebuilt in `/tmp`, `po` built with `CARGO_TARGET_DIR=/tmp/s172-target`): `po-session` prints `Framing: scope approved · stories present · stories review none · architecture missing · design system missing`, `Ready stories: s02-b (Owns not checked: /po-drive decides)`, `Lanes in flight: s04-d (.worktrees/s04-d)`. `po state` returns `"framing":{"stage":"stories-review","next":"/po-stories-review"}`, `"ready":null`, `"lanes":[{"story":"s04-d","stage":"research",...}]` (no path) and a `missing-setting` warning for `Decision inbox`. With `Parallel: 2` added, `ready` becomes `["s02-b"]`.
- Reproduction 2 (fixture of `test_session_hook_lists_human_escalations`, `tests/project-lead.test.sh:109-134`, plus a root `CLAUDE.md`): `po-session` lists six lines including `- s13-max: Max attempts reached (Fix loop: 2, Max attempts: 2)` and `- CLAUDE.md: Claude Code reads it instead of AGENTS.md → set Project CLAUDE file to absorbed or kept in AGENTS.local.md`. `po state` gives `blocked_by` codes for the four lanes, an `orphan-worktree` warning, a `no-gate` warning for `s11-root` (the fixture has no `.polype/hooks/po-gate.sh`), and nothing for `CLAUDE.md` nor the fix-loop count.
- H1 "the gap is only formatting: every printed value is in the JSON". Refuted by both reproductions (framing items, lane path, fix-loop count, CLAUDE hint, ready without `Parallel`).
- H2 "`po state` is a superset only missing optional settings". Refuted: `ready` checks `Owns`, `Parallel` and the start point (`po/src/next/wave.rs:42-71`), `po-session` none of them (`po-session.sh:165-194`, "Owns not checked"); a lane carries one stop, `po-session` lists every stop of a lane (`po-session.sh:207-239`).
- H3 kept: two derivations of one state, in bash and in Rust, with different rules (root cause above).

## Current code
- `method/hooks/po-session.sh` (280 lines): guards (:8-17, bash ≥ 4.2), header (:22), setup line (:24-27), settings (:29-39), framing (:56-105), worktrees and orphans (:107-142), shipped incl. bare `s<n>:` (:144-163), ready (:165-194), lanes (:196-203), stops + CLAUDE.md/install-mode hint (:205-263), report (:265-280). Prints `Unreadable setting: X` for an empty setting (:41, :267-271).
- `po state` (`po/src/state/mod.rs:34-88`): `project, commit, method_version, framing{stage,next}, milestone, session, bounds, waiting, lanes[{story,stage,next,blocked_by}], ready, held, shipped, warnings[{code,...}]`; exit 2 with `not-a-project` outside a project (:42-48). Warning codes (`po/src/context/mod.rs:21-30`): `method-version-mismatch`, `missing-setting`, `unreadable-setting`, `orphan-worktree`, `unreadable-decision`, `no-gate`. Contract: `docs/interface-agent.md:84-91`.
- `method/commands/po-status.md` (42 lines): setup (:15), framing rules (:16-21), per-story table rules (:22-32), fleet (:33-38), output and next chain (:39), ADRs (:40). `po state` covers framing, lanes, stops, ready/held with the Owns collision, shipped; it has no per-story complexity, track, research/design/plan/record/QA/review columns, plan ticks, nor a next for a story without a lane.
- `method/commands/po-retro.md` (53 lines): scope matching (:22-26), where files are read (:28-29), measures table (:34-41), output with `path:line` sources (:46-53).

## Attachment points
- `method/hooks/po-session.sh`: replace :19-280 by one call `cd "$top" && "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" state` and a formatter; `po-bounds.sh` already requires `jq` and refuses without it (`method/hooks/po-bounds.sh:55`, `:830`), `po-session.sh` uses none today.
- `method/commands/po-status.md`, `method/commands/po-retro.md`: prose rewrite pointing to `po state` (`--all` for a retro outside the current milestone).
- If `po state` must carry what `po-session` prints: `po/src/context/framing.rs` (framing items), `po/src/state/mod.rs` (lane `path`, stops), `po/src/context/lanes.rs` (all stops, fix-loop count), `docs/interface-agent.md:84-91`. All M21 stories that owned these paths have shipped (`git log main`: s164–s175), so widening `Owns` collides with no lane.

## Tests outside `Owns` that pin something this story changes (issue #241, m9)
| File:line | Assertion | Breaks because |
| --- | --- | --- |
| `tests/project-lead.test.sh:84,99` | `Framing: scope … · stories … · stories review … · architecture … · design system …` | no framing items in `po state` |
| `tests/project-lead.test.sh:86` | `Ready stories: s02-b (Owns not checked: /po-drive decides)` | fixture has no `Parallel` → `ready: null`; "Owns not checked" becomes false |
| `tests/project-lead.test.sh:87` | `Lanes in flight: s04-d (.worktrees/s04-d)` | no lane path |
| `tests/project-lead.test.sh:105` | exact two-line output without `AGENTS.local.md` | any added line (missing `po`, warnings) |
| `tests/project-lead.test.sh:131` | `Max attempts reached (Fix loop: 2, Max attempts: 2)` | no fix-loop count |
| `tests/project-lead.test.sh:88,155-170` | `Waiting for a human: nothing` | breaks if warnings (`missing-setting Decision inbox`, `no-gate`) are listed there |
| `tests/project-lead.test.sh:38-171` (all session tests) | run with the suite's empty `CLAUDE_CONFIG_DIR` | no `po` found |
| `tests/short-subject-shipped.test.sh:31,40,48` | `Ready stories: … (Owns not checked: /po-drive decides)` | no `Parallel` in fixture; suffix |
| `tests/short-subject-shipped.test.sh:26-28` | `po-status.md` holds the shipped sentence | criterion 3 removes it |
| `tests/ship-and-fleet-cleanup.test.sh:83-91` | mutates `SHORT_SHIPPED["${id%:}"]=1` in `po-session.sh`, asserts it occurs once | the line disappears |
| `tests/ship-and-fleet-cleanup.test.sh:48-58` | `po-status.md` steps 3–5 hold `Root cause: not found`, `waiting for a technical choice` | step structure removed |
| `tests/no-claude-md.test.sh:97-102` | `- CLAUDE.local.md: … polype update . moves it …` | hint not in `po state` |
| `tests/claude-md-setting.test.sh:69,112-113` | `Waiting for a human: nothing`; `set Project CLAUDE file to absorbed or kept` | same |
| `tests/update-keeps-mode.test.sh:110-154` | `… polype init . moves it …` hint lines | same |
| `tests/update-keeps-mode.test.sh:166-178` | comments of `po-session.sh` name `recorded_mode`, `` `polype init .` ``, one block above `local again=` | the block goes if the hint goes |
| `tests/state-as-json.test.sh:48-66` | parses `Framing next:` / `Framing: setup missing → ` from `po-session` | needs `po` reachable; becomes a tautology |
| `tests/readme-onboarding.test.sh:30-34` | bash guard line comes before the first `declare -`/`mapfile`/`readarray` | no such construct left → empty line number, `-lt` fails |
| `tests/docs-and-eval-cleanup.test.sh:50-70` | `po-status.md` shipped sentence, design-system bullet, `- review:` bullet phrases | bullets removed |
| `tests/pilot.test.sh:26,30` | `no commit, checkout, merge or file change`; `on \`Target branch\` or \`origin/<Target branch>\`` | may be removed |
| `tests/fleet-wiring.test.sh:56-75` | `po-status.md` reads `Parallel`, `Max attempts`; Fleet step phrases | Fleet step removed |
| `tests/final-leftovers.test.sh:22-24` | `po-status.md` overlap clause | removed |
| `tests/qa-fleet.test.sh:64-69,133-136` | `po-status.md` reads `QA stage`; QA phrases and next chain | removed |
| `tests/owns-overlap.test.sh:51-53` | `po-status.md` cites the overlap rule | removed |
| `tests/ship.test.sh:45-46` | `- review:` bullet of `po-status.md` names `Reviewed tree:` | removed |
| `tests/surface-routing.test.sh:33` | `po-status.md` holds `for a story that goes to QA:` | removed |
| `tests/wiring.test.sh:39-49` | `po-status.md` reads `Entry mode`, `Story track`, `Flow threshold`; names `docs/prd.md`, `Stories ready:`, `track: flow`, `/po-flow <id>` | removed |
| `tests/adr-directory.test.sh:5,25-27` | `po-status.md` reads `ADR directory`, never names `docs/decisions/` | holds if step 6 stays |
| `tests/po-retro.test.sh:12-36` | measure names, `open by the last review`, `docs/reviews/<id>.md`, Sources rule | the story's notes keep them; see assumption 3 |
| `tests/commands-and-texts.test.sh:10-23` | retro Scope precedence; majors row says `not blocked` | same |
Not affected: `tests/hooks-installer-docs-cleanup.test.sh:89` (installer text), the `lacks` checks of `tests/surface-routing.test.sh:26,35-39`, the loop of `tests/qa-fleet.test.sh:114-119` (vacuous when the pairing goes).

## Verified interfaces
- `po` path: `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po"` (`method/commands/po-drive.md:29`, `po-execute.md:9`). Tests: `$PO` = `${CARGO_TARGET_DIR:-$ROOT/po/target}/release/po` (`tests/lib.sh:7`), built once by `tests/run.sh:22-26`; nothing installs it into `CLAUDE_CONFIG_DIR`.
- Version warning: `{"code":"method-version-mismatch","po":…,"project":…}` (`po/src/context/mod.rs:124-131`).
- `po state` runs each lane's `po-gate.sh` in a subprocess (`po/src/context/lanes.rs:126-138`): read-only, but slower than today's hook at session start.

## Settled findings
- **s173 review finding** (`po-status.md:35`, `po-retro.md:37` read `Fix loop:` "the way `/po-drive` reads it"): confirmed; `po-drive.md` no longer says how (`po-drive.md:38` now points to `/po-review`). Both lines are in `Owns` and go with the rewrite whatever the correction; `po state` gives `shipped[].trust.fix_loops` (`po/src/trust/signals.rs:33`) for shipped stories only.
- **Issue #244** (per-milestone stories reviews read as `stories review none`): the reading lives in `po/src/context/framing.rs:272-277` (only `docs/reviews/stories.md`) and `docs/interface-agent.md:84` says the rules are `po-session`'s. Not settleable inside `Owns`, and the issue itself asks for a decision (recognise `stories-m<N>.md`, or change this repository's layout). Once `po-session` reads `po state`, the fix is in `po` alone. It stays an issue.

## Traps
- Keeping `po-session` silent outside a project and in a story worktree (`tests/project-lead.test.sh:38-58`) and the bash guard (`tests/readme-onboarding.test.sh`) means those checks stay in bash before the `po` call.
- `po state` prints warnings the hook never printed (`missing-setting` for `Decision inbox`, `no-gate` on lanes without hooks): where they are shown decides several `Waiting for a human: nothing` assertions.
- Word-count test: measure the same way before and after (`wc -w` on the whole file, frontmatter included: 1101 / 977).
- `po-status` today also fetches (`po-status.md:13`); `po state` never asks a remote except `--remote` (forge checks only).

## Open questions
1. Which correction? (a) Widen `Owns` to `po/src/context/framing.rs`, `po/src/context/lanes.rs`, `po/src/state/mod.rs`, `docs/interface-agent.md`, `tests/lib.sh` or `tests/run.sh` (to place `$PO` where the hook looks) and the test files above; `po state` gains framing items, lane `path`, every stop with its detail, and a `CLAUDE.md` warning. Keeps criterion 1 word for word; API contract change. (b) Relax criterion 1 to "the lines `po state` can give", accept new wording for the framing line, ready, lanes, Max attempts and the CLAUDE hint, and widen `Owns` to the test files above. (c) Split: one story for `po state`'s fields (contract), then this one.
2. Does the `CLAUDE.md` / install-mode hint (`po-session.sh:241-256`) count as state derivation? It is install health, not project state; keeping it in bash would keep `no-claude-md`, `claude-md-setting` and `update-keeps-mode` green.
3. `/po-retro`: shrink to what `po state --all` gives (fix loops, max severity, shipped only), or keep its review reading, which contradicts criterion 3 and the "lose their review reading" clause?
4. May `po-session` require `jq` to format the JSON, as `po-bounds.sh` does (ADR-0024), and what does it print without it? A missing `jq` must still exit 0 at session start.

## Complexity
Story: 2. After reading: 4 under correction (a) or (b) — about 16 test files outside `Owns` to touch, a `po state` contract change under (a), the test harness to make `po` reachable from the hook, three files rewritten. At 4, no split is required; (c) is the natural cut.

## Split
Not mandatory (score 4). If chosen: s172a — `po state` carries what `po-session` prints (framing items, lane path, all stops with fix-loop count, `CLAUDE.md` hint as a warning), contract updated, oracle on the binary; s172b — `po-session`, `/po-status`, `/po-retro` read it, with the test files above in its `Owns`.
