# Research — s163-qa-lanes-isolated

[Story](../stories.md)

## Structuring facts
- Root cause: nothing in the QA contract gives a lane anything of its own. The `qa` subagent drives the session's one browser tool (`method/agents/qa.md:22`, ADR-0026), `browser.md` starts `Dev` with no port of the lane's (`method/skills/qa-drivers/browser.md:10`), and no QA file sets a deadline on a driver action (`method/skills/qa-drivers/SKILL.md:1-39`); meanwhile `/po-drive` starts every `qa` of a wave together (`method/commands/po-drive.md:101`, `:107`). Input reaching it: two stories of one wave going to QA on a `screen` surface (clione, #149).
- A prose rule already tried to keep lanes apart and cannot: "Your own tabs" (`method/skills/design-doctrine/SKILL.md:42`) assumes a browser where each agent opens its own tab; #149 shows a navigation landing in the other lane's tab. Isolation has to come from a separate browser process, not a sentence.
- The story's assumption holds: `po-bounds` mode `qa` checks only Write paths and git verbs (`method/hooks/po-bounds.sh:18-23`, `:760-761`), so a `node` script in the lane's `mktemp -d` directory and a `timeout` wrapper are not refused.
- Owns limit: the driver files that start `Dev` (`browser.md:10`, `mobile-web.md:12`) and `design-doctrine:40` ("a browser shared with the session") are outside `Owns`; the new rule lives in `qa-drivers/SKILL.md`, which every driver is read under.
- The oracle gate admits a criterion with no test: `po-gate oracle-intact` reads only the `Oracle file` table (`method/hooks/po-gate.sh:608`, `:616-629`), never the criterion table, and the reviewer runs only that gate on the oracle (`method/skills/review-antihallu/SKILL.md:41`). The lane can go on.

## Diagnostic
**Reproduction.** Not reproduced live: it needs two QA lanes on a `screen` project with a browser tool in one session; this repository has no screen (`Platform: cli`), and the research stage creates no file to build one. What was run instead, on the code as it stands:
- `grep -rni 'port\|timeout\|deadline\|headless' method/skills/qa-drivers/SKILL.md method/skills/qa-drivers/browser.md method/agents/qa.md method/commands/po-qa.md` → no line gives a lane a port, a browser of its own or a deadline; the only hits are viewport and `## Not seen` lines of `mobile-web.md`.
- `grep -rni 'reuseExistingServer\|playwright' method/` → nothing: the reuse seen on clione came from that project's Playwright config, reached because nothing told the lane to start its own server on its own port.
- `bash tests/run.sh qa.test.sh qa-drivers.test.sh qa-contract-holds.test.sh qa-evidence-set-aside.test.sh qa-report-returned-as-text.test.sh mobile-web-driver.test.sh bounds.test.sh` → 59 passed: the suite pins the shared-browser contract and nothing about isolation.

**Hypotheses.**
| # | Hypothesis | Observation that would refute it | Result |
| --- | --- | --- | --- |
| H1 | Lanes share a browser because the method sends every `qa` to the session's single browser tool | A line telling each lane to open a browser instance of its own | **Kept**: `qa.md:22` inherits "its browser tool included", `design-doctrine:40` says "a browser shared with the session", `browser.md:13` drives through that skill; nothing else |
| H2 | Lanes collide on a port because the method lets `Dev` take its default | A line giving the lane a port, or checking that the port is free before start | **Kept**: `browser.md:10` "Start `Dev` … read the origin it prints"; `mobile-web.md:12` the same. Contrast `scenarios.md:14`, which does pick a free port for an API, so the pattern exists but not for screens |
| H3 | `/po-drive` ran two QA together against its own rule (QA meant to be serial) | No line making QA lanes concurrent | **Discarded**: `po-drive.md:101` "every qa of a wave leaves before any of them is waited on", `:107` repeats it; concurrency is intended |
| H4 | A stuck call ran unbounded because no deadline exists for driver actions | A deadline in `qa-drivers` or a screen driver | **Kept**: none in `SKILL.md`, `browser.md`, `mobile-web.md`; deadlines exist only in other drivers (`scenarios.md:14` 60 s, `simulation.md:30` 30 s) |

## Story
Each lane in QA gets its own browser and its own dev port, so two QA started together never block each other all night. Criteria: `each_lane_drives_its_own_browser` (private headless browser from the project's package; shared browser forbidden when another lane is in QA; the skill says how the lane knows), `each_lane_serves_on_its_own_port` (port derived from the worktree, never the default, no reuse of a running server), `a_stuck_driver_ends_blocked` (deadline fixed by the skill → `QA status: blocked` with the reason), `no_file_grows` (`SKILL.md` and `qa.md` no longer in words). Fixes #149.

## Current code
- `method/skills/qa-drivers/SKILL.md` (39 lines, **554 words** by `wc -w` on main 89ecf0d): intro `:7`, driver table `:9-17`, routing `:19-23`, where a driver file is read `:25-26`, what a driver file says `:28-33`, the `mktemp -d` scratch directory `:35-36`, `## Not seen` `:38-39`.
- `method/agents/qa.md` (61 lines, **1013 words**): checks `:24-32`, walk `:42-49` (step 5 uses the `mktemp -d` directory, step 6 stops everything started), report `:51-52`, limits `:54-58`.
- `browser.md:5-10` and `mobile-web.md:5-12`: "Needs … a tool of the session that opens a page", then start `Dev` from the worktree in the background and read the origin it prints. Not in `Owns`.

## Attachment points
- A new section of `qa-drivers/SKILL.md`, read before any driver file (`qa.md:44` picks driver files from that skill), so its rules precede `browser.md:10`.
- The existing scratch directory (`SKILL.md:36`): giving it a fixed prefix makes it the marker other lanes see; every driver already creates it (`scenarios.md:10`, `scene.md:17`).
- `qa.md:20`, the line that says what `qa-drivers` covers.

## Verified interfaces
- `po-bounds qa`: Write only under `docs/qa/<id>/` (`po-bounds.sh:280-287`); Bash checked on git calls only (`:760-761`, `check_git_read`); `temp_root` not applied in qa mode (`:694`).
- `qa-drivers` is preloaded by `qa` (`qa.md:8`); driver files read from the announced base directory (`SKILL.md:26`).
- `scenarios.md:14-16`: picks a port on which nothing answers, passes it "through the variable or option that command documents", 60 s to answer, blocked if it listens elsewhere. The screen rule can reuse this shape.
- `po-lint` reads only driver file names of `qa-drivers/` (`bin/po-lint:315`), never `SKILL.md` text.

## Traps
- **Pinned phrases, tests outside `Owns`** (must keep passing, unchanged): in `SKILL.md` — the six table rows (`tests/qa-drivers.test.sh:19-30`), `QA status: blocked`, `base directory`, `mktemp -d` (`:32-33`, `:53`), one line holding `No row matches`, `` `Platform` is missing `` and `QA status: blocked` (`tests/qa-contract-holds.test.sh:18-23`). In `qa.md` — phrases at `tests/qa.test.sh:38-40,51-52`, `tests/qa-drivers.test.sh:34,41-42,50-52`, `tests/qa-contract-holds.test.sh:24,38-42`, `tests/qa-evidence-set-aside.test.sh:8,22`, `tests/qa-report-returned-as-text.test.sh:27-33`, frontmatter at `tests/bounds.test.sh:179-182`.
- `qa.md:32` stops when "no tool in your session can open a page and capture it", pinned word for word (`tests/qa.test.sh:51`); Bash plus the project's package is such a tool, but the line cannot be reworded.
- Word budget: the new rule must be paid for inside the same file (`no_file_grows`, and the M20 rule). A draft written outside the worktree held the four rules in 556 words after cutting the intro (`:7`), the `Platform` example (`:21`), the second sentence of `:26` and the `## What each driver file says` list (`:28-33`); two more words must go.
- A lane on the session's browser tool cannot be timed out by itself: a hung tool call holds the agent. The deadline binds Bash and scripts only.
- Playwright writes a temporary profile under `TMPDIR`; pointing `TMPDIR` at the lane's directory keeps it inside what is removed at the end.
- No migration, no new dependency of Polype: the package is the project's own.

## Open questions
- Can the port and the marker check leave prose for a small script (case 2 of the M20 rule)? The rule is deterministic, but any script path (`method/hooks/`, a file beside `SKILL.md`) is outside `Owns`; the plan takes case 3 and reports the gap.
- Do subagents of one session share `TMPDIR`? Assumed yes (same process environment); if a sandbox gave each its own, lanes would not see each other's marker and a lane without a package would wrongly use the shared browser.
- Is 120 seconds right for a dev server's first page on a large app? Chosen above `scenarios.md`'s 60 s for cold compiles; the reviewer may weigh it.

## Complexity
3 → 3. Two method files and prose only, but three rules (browser, port, deadline) must fit in a word budget that forbids growth, around pinned phrases.

## Split
—
