---
track: flow
validated: yes
---
# Plan (short track) — s216-surface-read-as-written

[Story](../stories.md)

Written by the planner. On the short track this one file stands in for both the research and the plan: there is no `docs/research/<id>.md`.

## Verified facts
- No story assumption proved false. Every `path:line` of the story's notes was opened and holds (`framing.rs:89` is the `no_story_has_a_screen` call, within the block `framing.rs:87-93`).
- **#355, Surface kept with its backticks.** `po/src/context/stories.rs:150` stores `value(line).trim().to_lowercase()`: for `- **Surface** : `` `—` `` the value is `` `—` ``, backticks included. `goes_to_qa` (`po/src/context/lanes.rs:298-308`) sets `has_surface` by `surface != "—"` (`:300`), so that story counts as having a surface: under `QA stage: surfaces` it goes to QA, and under `QA stage` missing it raises `MissingSetting` (`:302`).
- The same `goes_to_qa` decides the track: `plan()` in `po/src/next/lane.rs:28-35` forces `Track::Full` when the story goes to QA, so a backticked `—` story also loses the short track.
- Design routing reads `Story::has_screen` (`stories.rs:24-27`) through `says_screen` (`stories.rs:86-94`), the word `screen` on its own: a backtick is not a lowercase letter, so `` `—` `` never says screen and `` `screen` `` already does. Design routing at `lane.rs:81-93` and `lanes.rs:260-265` is unaffected by the bug.
- `backticked()` (`stories.rs:75-78`) returns the backticked entries only, so it gives nothing for a bare `command`; the fix uses `str::trim_matches('`')` instead.
- **#348, design system required with no screen.** `Stories::no_story_has_a_screen` (`stories.rs:170-173`) needs `story.surface.is_some()` on every story; `framing()` (`po/src/context/framing.rs:54-60`) already takes `&Settings` and calls it at `:89`. `Settings::optional` (`po/src/context/mod.rs:75-80`) returns a setting without a warning; `Project::setting` (`po/src/project.rs:55-67`) reads the first non-empty `Name:` line of `AGENTS.local.md`.
- `po` never reads `Platform` today (`grep -rn Platform po/src` → nothing). `Platform` is a comma-separated lowercase list (ADR-0055); `screen` goes with `web` and `mobile` only (ADR-0055; `method/skills/agentic-stories/SKILL.md:43`); the template's default is `web` (`method/templates/agents-local.md:21`).
- Reproduced: `po state` (installed 0.13.0) in this worktree, `Platform: cli`, 219 stories of which 142 carry a Surface line → `{"item":"design-system","state":"missing"}`.
- Existing tests that pin the current rule build projects **without a `Platform` line** and with a Surface line on every story: `tests/state-carries-session-lines.oracle.test.sh:74-78`, `tests/state-as-json.test.sh:69-73`, `tests/session-shows-what-waits.oracle.test.sh:26,125`. The rule below keeps their outcomes.
- **Version.** 0.13.0 at `po/Cargo.toml:3`, `po/Cargo.lock:165` (the line after `name = "po"`), `bin/polype:28` (`POLYPE_VERSION`), compared by `bin/po-version-check:33-49`. `PO_SUMS` (`bin/polype:34-38`) holds the 0.13.0 sums and is replaced only by `bin/po-release --sums` after a release (`docs/ci.md:37-40`); an installer finding no sum for the new version builds from sources.
- Rust code has no unit tests (`grep -rn "cfg(test)" po/src` → nothing): `po` is tested from bash through its binary, built by `tests/run.sh`.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text | absent — no stored data, only parsing in `po/src/context/` |
| New screen | absent — `Surface: command` | absent — CLI only |
| Authorization or tenant scope | absent — story text | absent — routing and framing state only |
| API contract | absent — story text | absent — `po next` / `po state` JSON keep their shape and values set; only which value is computed changes |
| New dependency | absent — story text | absent — std `trim_matches`, `split` |
| Technical choice that deserves an ADR | absent — story text | absent — the screen/platform pairing is already settled by ADR-0055 |
| Defect to fix (`Fixes` or `Corrige` line) | absent — no `Corrige` line | absent |

## Story
The owner wants a story whose `Surface` is `` `—` `` routed neither to QA nor to design, exactly as a bare `—`, and a project with no screen not told `design-system: missing`, so `po next` and `po state` follow Law 1 on Lagon and on Polype (#355, #348). Criteria: `backticked_dash_is_no_surface`, `no_screen_needs_no_design_system`, `version_raised`. Complexity scored after reading: 2.

**Rule kept for #348**: the design system is not needed when stories exist, none has a Surface saying `screen`, and either every story carries a Surface line (today's rule, kept) or `Platform` is set and none of its entries is `web` or `mobile`. A missing `Platform` reads as the template's `web`: nothing changes for it.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Backticks stripped from the Surface value | standard library, `str::trim_matches('`')` | `backticked()` (`stories.rs:75-78`) drops a value written without backticks |
| "Platform holds a screen platform" | standard library `split(',')` + `trim`, on `Settings::optional` (`mod.rs:75`) | no reader of `Platform` exists in `po/` |
| Version raise | edit of three existing lines | — |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/surface-read-as-written.oracle.test.sh` | `926823093 3987` |

| Criterion | Test |
| --- | --- |
| `backticked_dash_is_no_surface` | `test_backticked_dash_is_no_surface`: under `QA stage: surfaces`, a recorded lane of a `` `—` `` story gets `review`/`no review` like a bare `—`; a researched one gets `plan`/`research, no plan` on the `flow` track (not `design`, not full); a ready one plans on `flow`; under `QA stage` missing, the `` `—` `` lane gets `review`, not `ask` |
| `no_screen_needs_no_design_system` | `test_no_screen_needs_no_design_system`: `Platform: cli` with one story lacking a Surface line → `not needed`; `Platform: web` → `missing`; `Platform: cli` with a `screen` story → `missing` |
| `version_raised` | `test_version_raised`: the three places agree and the version is above 0.13.0 |

Ran against the installed 0.13.0: each test fails at its first assertion (s01 goes to `qa`; design-system `missing`; version 0.13.0), the harness itself works. The test sources `tests/driver-next-action.oracle.test.sh` inside a subshell, as `tests/next-waits-on-dependencies.oracle.test.sh` does.

## Tasks

1. [x] **#355.** `po/src/context/stories.rs:150`: store the Surface as `value(line).trim().trim_matches('`').trim().to_lowercase()`. Nothing else changes in `goes_to_qa`. Fails if wrong: `test_backticked_dash_is_no_surface`.
2. [x] **#348.** Give `Stories::no_story_has_a_screen` (`stories.rs:170-173`) a `screen_platform: bool` parameter: true when stories exist and every story has `!has_screen()` and (`surface.is_some()` or `!screen_platform`); update its doc comment. In `framing()` (`framing.rs:87-93`), compute `screen_platform` from `settings.optional("Platform")`: `None` → true; `Some(list)` → any comma-separated entry, trimmed and lowercased, equals `web` or `mobile`. Fails if wrong: `test_no_screen_needs_no_design_system`, and `tests/state-carries-session-lines.oracle.test.sh` / `tests/state-as-json.test.sh` if the no-Platform case moves.
3. [x] **Version.** 0.13.0 → 0.13.1 in `po/Cargo.toml:3`, `po/Cargo.lock:165` and `bin/polype:28`, by hand (a `cargo build --locked` refuses a lock that disagrees). Fails if wrong: `test_version_raised`, `bin/po-version-check`.
4. [x] **Suite.** `bash tests/run.sh surface-read-as-written.oracle.test.sh state-carries-session-lines.oracle.test.sh state-as-json.test.sh driver-next-action.oracle.test.sh session-shows-what-waits.oracle.test.sh next-names-the-track.oracle.test.sh`, then the full suite once through `po-run` at the end (`Full suite: execute-end`).

## Scene viewpoints
—

## Run interdicts
- `method/` ends with an empty diff: the routing rule's prose (Law 1, ADR-0058) already says this.
- The `PO_SUMS` block of `bin/polype` (`:34-38`) ends unchanged; only the `POLYPE_VERSION` line moves in that file.
- No fallback "the story text shows a screen" is added to `po` (#419 stays open); `says_screen` and `has_screen` keep their bodies.
- `goes_to_qa`'s signature and the `po next` / `po state` JSON shapes are unchanged.
- No existing test file changes; no new crate in `po/Cargo.toml`; `tests/fixtures/driver-cases/` unchanged.
- `tests/surface-read-as-written.test.sh` is created only if it holds at least one test (`tests/run.sh` fails an empty file).

## Files touched
`po/src/context/stories.rs`, `po/src/context/framing.rs`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, plus the oracle `tests/surface-read-as-written.oracle.test.sh` and this plan.

## Test strategy
Three oracle tests, all through the `po` binary (the adapter layer is the only one this crate tests): one per criterion, 3 of the 25 of `Test budget`. No task test is needed: the existing framing tests guard the no-`Platform` case, the driver cases guard the bare `—`. Neutralising task 1 turns s01's action back to `qa`; neutralising the `Platform` branch of task 2 turns `not needed` back to `missing`; dropping the `screen` check makes the third case of that test fail.

## Done when
One commit on `story/s216-surface-read-as-written` holding code, oracle and plan; full suite green through `po-run`; `bin/po-version-check` passes; a review with no open critical finding; shipped as `s216-surface-read-as-written: po lit la ligne Surface telle qu'on l'écrit`.
