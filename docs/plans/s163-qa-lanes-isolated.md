---
validated: yes
---
# Plan — s163-qa-lanes-isolated

[Story](../stories.md) · [Research](../research/s163-qa-lanes-isolated.md)

Branch `story/s163-qa-lanes-isolated`. Read `docs/research/s163-qa-lanes-isolated.md` first; this plan builds on it without repeating it.

## Story
Each lane in QA owns its browser, its dev port and a deadline on every driver action, so two QA started together never block each other. Criteria: `each_lane_drives_its_own_browser`, `each_lane_serves_on_its_own_port`, `a_stuck_driver_ends_blocked`, `no_file_grows`. Fixes #149. ADR-0114 (written by the planner, `accepted`, scope this story) records the rule and the options turned down; it complements ADR-0026 without superseding it.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Lane marker | already here: the `mktemp -d` scratch directory of `qa-drivers` (`SKILL.md:36`), given a fixed prefix | — |
| Free-port check, passing the port, blocked when it listens elsewhere | already here: the shape of `scenarios.md:14` | — |
| Private headless browser | a dependency the project already installs (Playwright, Puppeteer) | nothing in this repository launches a browser; the platform has none |
| Port formula | platform: `cksum` of the worktree path | no helper in this repository derives a number from a path |

No script, setting or option is added: the plan writes prose only.

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/qa-lanes-isolated.oracle.test.sh` | `3363789556 662` |

Owner's rule of 2026-11-13 (Objectif of M20), criterion by criterion. The oracle gate admits a criterion with no test (research, Structuring facts, last line).

| Criterion | Case | Test |
| --- | --- | --- |
| `each_lane_drives_its_own_browser` | 3 | No oracle test, no phrase test: the rule speaks to the `qa` model; the reviewer reads `SKILL.md`. **Candidate for a `po-eval` control arm (#208)**: two `screen` lanes started together, one with the project's package, must not touch the session's browser. Case 2 was possible for the marker check, but a script path lies outside `Owns` (research, Open questions): gap reported to the lead. |
| `each_lane_serves_on_its_own_port` | 3 | No oracle test, no phrase test; the reviewer reads `SKILL.md`. **`po-eval` candidate (#208)**: two lanes, two ports, a pre-occupied port ends `blocked`. Case 2 was possible for the port formula (deterministic), same `Owns` gap; the plan writes the formula exactly so the model has nothing to judge. |
| `a_stuck_driver_ends_blocked` | 3 | No oracle test, no phrase test; the reviewer reads `SKILL.md`. **`po-eval` candidate (#208)**: a page action that never returns must end in `QA status: blocked` naming it. |
| `no_file_grows` | 1 — `wc -w` reads the count | `test_no_file_grows`: `SKILL.md` ≤ 554 words and `qa.md` ≤ 1013 words, the counts on main 89ecf0d. |

On today's code the oracle passes (counts equal): it is a guard against growth, as in s161.

## Tasks
1. [x] **Lanes side by side.** In `method/skills/qa-drivers/SKILL.md`, add a section `## Lanes side by side` after `## Where a driver file is read`, holding four rules, in the method's own words:
   - **Marker.** Before starting anything, every lane creates its directory with `mktemp -d "${TMPDIR:-/tmp}/polype-qa-<id>.XXXXXX"`; another `polype-qa-*` directory there means another lane is in QA.
   - **Browser.** A `screen` driver runs its own headless browser, launched by a script in that directory with `TMPDIR` pointing there, from the browser-automation package the project already installs (Playwright, Puppeteer); it installs nothing, browsers included. Without such a package, the session's browser tool serves only while no other lane is in QA; otherwise `QA status: blocked`, naming the missing package and the marker found.
   - **Port.** `Dev` listens on port 20000 plus the `cksum` of the worktree's absolute path modulo 10000, passed through `PORT` and the option its command documents. Something already answers there before the start, or `Dev` prints another port → `QA status: blocked`; a server already running is never reused.
   - **Deadline.** Each driver action — a start, a page action, a capture — gets 120 seconds: `timeout 120` in Bash, the script's own timeout in the browser. Past it → stop what the lane started, end with `QA status: blocked`, naming the action.
   Then make `## Outside the evidence` (`:35-36`) point to that directory instead of creating its own, keeping the phrase `mktemp -d` and the single-exception sentence. Add "how lanes in QA together stay apart" to the frontmatter `description` only if the word budget allows. — test: none (case 3); keeps passing: `tests/qa-drivers.test.sh`, `tests/qa-contract-holds.test.sh`.
2. [x] **Pay for it in the same file.** Cut `SKILL.md` back to ≤ 554 words (`wc -w`), in this order until it holds: the intro (`:7`) to one sentence naming the four ways a user meets a surface; the example after "each one run in full" (`:21`); the second sentence of `:26` (machine or project, fixed path), keeping "base directory"; the `## What each driver file says` list (`:28-33`) to one sentence or nothing; then trims in the new section. Spare every phrase the research lists under Traps (table rows, `QA status: blocked`, `base directory`, `mktemp -d`, the `No row matches` line whole). — fails: `test_no_file_grows`; keeps passing: `tests/qa-drivers.test.sh`, `tests/qa-contract-holds.test.sh`.
3. [x] **Point `qa.md` to it.** In `method/agents/qa.md:20`, name the new rule among what `qa-drivers` covers ("…where its file is read, how lanes in QA together stay apart, and where its by-products may go…"), and remove at least as many words elsewhere in the same paragraph block (`:20-22`) — no pinned phrase lives there. No other line of `qa.md` changes; `:32` stays word for word. — fails: `test_no_file_grows`; keeps passing: `tests/qa.test.sh`, `tests/qa-drivers.test.sh`, `tests/qa-contract-holds.test.sh`, `tests/qa-evidence-set-aside.test.sh`, `tests/qa-report-returned-as-text.test.sh`, `tests/bounds.test.sh`.
4. [x] **Suite.** After the last edit, once: `po-run --story s163-qa-lanes-isolated --label suite -- 'bash tests/run.sh'`. `Typecheck: —`. Commit the research, this plan, ADR-0114 and the oracle with the code.

## Scene viewpoints
—

## Run interdicts
- `git diff main...story/s163-qa-lanes-isolated --name-only` lists only: `method/skills/qa-drivers/SKILL.md`, `method/agents/qa.md`, `docs/decisions/ADR-0114-*.md`, `docs/research/`, `docs/plans/`, `docs/verif/` of this story and `tests/qa-lanes-isolated.oracle.test.sh`. `docs/parite-killer-saas.md` stays untouched: no line of it covers QA lane isolation (`grep -n -i 'parall\|navigateur'` finds only fleet and implementer lines, `:17`, `:54`, `:55`). No `tests/qa-lanes-isolated.test.sh`: this story has no test outside its oracle.
- `method/skills/qa-drivers/{browser,mobile-web,scenarios,scene,simulation}.md`, `method/skills/design-doctrine/SKILL.md`, `method/commands/po-drive.md`, `method/commands/po-qa.md`, `method/hooks/` end with an empty diff (outside `Owns`).
- No existing test file changes (`git diff main... -- tests/ ':!tests/qa-lanes-isolated*'` empty); `.claude/` and `.polype/` untouched.
- The oracle keeps its sum, or carries a row under `## Oracle changes`.
- No phrase test anywhere: no new test reads a sentence of `SKILL.md` or `qa.md`.
- `wc -w`: `SKILL.md` ≤ 554, `qa.md` ≤ 1013.
- No text from Killer SaaS (`tests/overlap.test.sh` green).

## The pivot
The lane learns "another lane is in QA" from a marker directory under `${TMPDIR:-/tmp}`, and prefers a private browser whenever the project has a package. Ways it could be wrong:
- Subagents of one session might not share `TMPDIR` (a sandbox per agent): then no lane sees another's marker. Compare: ADR-0114 Consequences; ask whether a lane without a package would ever reach the shared browser beside another lane.
- A lane that falls back on the session's browser is not covered by the deadline: a hung tool call holds the agent. Compare the rule's wording with `a_stuck_driver_ends_blocked`: the skill must not claim the deadline binds that tool.
- The port rule must not contradict `browser.md:10` ("read the origin it prints"): the origin printed must carry the lane's port, else blocked. Read both together.

## Files touched
`method/skills/qa-drivers/SKILL.md`, `method/agents/qa.md`; already written by the planner: `docs/decisions/ADR-0114-deux-qa-en-parallele-ne-partagent-ni-navigateur-ni-port.md`, `tests/qa-lanes-isolated.oracle.test.sh`, the research and this plan.

## Test strategy
- Automated: one oracle test, `test_no_file_grows` (case 1, `wc -w`). 1 of `Test budget` 25.
- Read by the reviewer, no test (case 3): `each_lane_drives_its_own_browser`, `each_lane_serves_on_its_own_port`, `a_stuck_driver_ends_blocked` — all three candidates for a `po-eval` control arm (#208).
- Existing tests that pin the two files keep passing unchanged (research, Traps); the full suite runs once at the end.
- Visual: none (`Surface: —`, no QA stage for this story).

## Done when
One commit `s163-qa-lanes-isolated: Deux QA en parallèle ne partagent ni navigateur ni port` landed through a pull request; full suite green; `SKILL.md` and `qa.md` no longer than before; a review with no open critical finding; #149 closed by the ship.
