---
validated: yes
---
# Plan — s82-mobile-web-driver

[Story](../stories.md) · [Research](../research/s82-mobile-web-driver.md)

Branch `story/s82-mobile-web-driver`. Read `docs/research/s82-mobile-web-driver.md` first; this plan builds on it without repeating it. Decisions left open by ADR-0054 and ADR-0057 are settled in ADR-0060 (`docs/decisions/ADR-0060-le-pilote-mobile-web-bloque-sans-largeur-de-telephone-et-nomme-le-natif-non-vu.md`), written with this plan.

## Story
QA of a `screen` story on a `mobile` project goes through the stack's web render, served by `Dev`, in a browser at phone width.
- `mobile_web_driver_sets_a_phone_viewport` — `qa-drivers/mobile-web.md` serves the web render with `Dev`, opens the screen at phone width (at least 360 and 412 px) in portrait, and captures each state.
- `mobile_rules_are_in_the_doctrine` — `design-doctrine` gives the mobile rules: touch targets at least 44 by 44 points, safe areas (notch, gesture bar), keyboard not hiding the active field, no hover as the only way to act.
- `native_only_behaviour_is_named` — the driver lists what the web render does not show (native permissions, notifications, camera, system gestures) and the QA report records it as not seen.

## Tasks
1. [x] **Mobile rules in the doctrine.** In `method/skills/design-doctrine/SKILL.md`, add a section `## Mobile screens` **after** `## Driving a browser` (the last section today, `:31-37`), leaving every existing line unchanged. Intro sentence: the rules hold for every screen of a project whose `Platform` holds `mobile` (ADR-0060), and the designer, the QA and the reviewer hold a screen to them. Four bullets, each opening with a bold lead written nowhere else in `method/`:
   - `**Touch targets**` — every control a finger acts on is at least 44 by 44 points; in a web render, at default zoom, one CSS pixel stands for one point (iOS) or dp (Android), so it measures at least 44 by 44 CSS pixels. A smaller visible icon keeps a hit area of that size.
   - `**Safe areas**` — content and controls stay clear of the notch or camera cut-out, the status bar and the gesture bar at the bottom; backgrounds may run under them, actions never.
   - `**The keyboard**` — when the on-screen keyboard opens, the field being typed in and its submit action stay visible: the screen scrolls or resizes, it never leaves the active field under the keyboard.
   - `**No hover**` — no action, label or piece of information is reachable only by hovering: a finger has no hover, so everything is reached by a tap, a long press with a visible alternative, or is shown outright.
   Extend the frontmatter `description` (`:3`) to name "the rules a phone screen holds"; keep `name: design-doctrine`.
   Fails if wrong: `test_mobile_rules_are_in_the_doctrine`; `tests/qa.test.sh` `browser_contract_is_written_once` and `tests/design-system.test.sh` guard the untouched sections.
2. [x] **The driver.** Create `method/skills/qa-drivers/mobile-web.md`, title `# Driver — mobile web`, following the five points of `qa-drivers/SKILL.md:26-31` with the headings `browser.md` and `scenarios.md` use:
   - intro: checks a `screen` surface on the `mobile` platform through the stack's web render in a browser at phone width (ADR-0054). Evidence: captures.
   - `## Needs` — `Dev` not `—`, serving the web render of the app (`agents-local.md:83`); a tool of the session that opens a page, **sets its viewport width and height**, and captures it. A tool that opens pages but cannot set their size → `QA status: blocked` with that cause; never capture at whatever width the window has, never emulate the width by zooming (ADR-0060).
   - `## Start and stop` — written in full here (a `mobile`-only project reads no other driver): start `Dev` from the worktree in the background, read the origin it prints; none, or nothing answers there → `QA status: blocked` with the reason; stop the server you started when the walk ends, whatever its outcome.
   - `## Exercising a criterion` — drive the browser by the `## Driving a browser` section of `design-doctrine`, not repeated here. Each screen in scope is opened in portrait (height greater than width) at **360** and at **412** CSS pixels wide (e.g. 360×800 and 412×915), and each criterion is walked at both widths. Act by click or tap only, never by hovering. Hold the screen to the `## Mobile screens` section of `design-doctrine`, not repeated here: measure the box of each control the criterion uses against the touch-target size, and a control that appears or works only on hover is a finding. Compare with the story and the design note as `browser.md` does.
   - `## Evidence` — one capture **per state and per width** under `docs/qa/<id>/`, named `<screen-or-criterion>-<state>-360.png` and `…-412.png`, through the browser tool's save option or a copy in Bash; by-products only in the `mktemp -d` directory of `qa-drivers`.
   - `## Cannot show` — a bulleted list of what the web render does not show: native permission prompts; notifications; the camera (and other device sensors); system gestures (back swipe, home and app-switch gestures); the on-screen keyboard; the safe areas of a real device (notch, gesture bar); screens behind a sign-in. Then the rule of ADR-0060: every report of this driver carries **one standing line** in `## Not seen` saying that native behaviour — the items above — was not seen because only the web render was, and **one more line per criterion in scope that relies on one of them**, naming the criterion and the item. A driver never reports one of them as seen.
   Leads of `## Driving a browser` and of `## Mobile screens` appear nowhere in this file.
   Fails if wrong: `test_mobile_web_driver_sets_a_phone_viewport`, `test_native_only_behaviour_is_named`; `tests/qa-drivers.test.sh` `qa_picks_the_driver_of_the_surface` keeps the table row.
3. [x] **The test file.** Create `tests/mobile-web-driver.test.sh` (header comment `# s82 — …`), three functions named after the criteria, each quoting short exact phrases of the files above:
   - `test_mobile_web_driver_sets_a_phone_viewport` — `require_file`; the five headings with `grep -qxF` (as `tests/scenario-driver.test.sh:9-11`); the file names `` `Dev` ``, `360`, `412`, `portrait`, the per-state-and-width capture phrase, `docs/qa/<id>/`, `` `## Driving a browser` `` and `design-doctrine`; the blocked phrase for a tool that cannot set the viewport, and `ADR-0060`.
   - `test_mobile_rules_are_in_the_doctrine` — the doctrine has `## Mobile screens` exactly; the section body (extracted with the awk of `tests/qa.test.sh:25`) holds the four leads, `44 by 44 points` and `CSS pixels`, `notch`, `gesture bar`, `active field`, `hover`; each lead is written in exactly one file of `method/` (as `tests/qa.test.sh:28-29`), so `mobile-web.md` points to it rather than copying.
   - `test_native_only_behaviour_is_named` — the `## Cannot show` body of `mobile-web.md` names `permission`, `notifications`, `camera`, `system gestures`; the file names `## Not seen`, the standing-line phrase and the per-criterion phrase.
   Fails if wrong: each function goes red when its clause is removed from the method file (that is the check the reviewer will run).
4. [x] **Run.** Focused: `bash tests/run.sh mobile-web-driver.test.sh qa.test.sh qa-drivers.test.sh design-system.test.sh overlap.test.sh`. Then the full suite once, through `po-run --story s82-mobile-web-driver --label test -- 'bash tests/run.sh'` (`Full suite: execute-end`). No type check (`Typecheck: —`).

## Scene viewpoints
—

## Run interdicts
- `method/skills/qa-drivers/SKILL.md`, `browser.md`, `scenarios.md`, `method/agents/qa.md`, `method/commands/po-qa.md`, `method/templates/qa.md`, `bin/po-lint` end with an empty diff: the routing, the report template and the lint already serve this driver (research, "Structuring facts").
- In `method/skills/design-doctrine/SKILL.md`, every line present on `main` other than the frontmatter `description` is unchanged (`git diff main...story/s82-mobile-web-driver -- method/skills/design-doctrine/` shows only that line and added lines).
- No existing test file is edited; `tests/qa.test.sh`, `tests/qa-drivers.test.sh`, `tests/design-system.test.sh` pass unchanged.
- No file under `.claude/` or `.polype/` is touched (installed copies).
- No boilerplate profile is written or edited (`boilerplates/` belongs to s83–s85).
- No text copied from any Killer SaaS source (`tests/overlap.test.sh`).
- The diff stays inside `Owns` plus `docs/` (research, plan, ADR-0060, verification record).

## The pivot
The driver must never let a report say more than a web render in a desktop browser can show. Everything hangs on two choices of ADR-0060: blocking when the browser tool cannot set the viewport, and the standing `## Not seen` line. Ways it could be wrong:
- The browser tools sessions actually have may all set the viewport, making the blocked branch dead text — harmless; or none of them may, making every mobile QA blocked. Compare with the tools a session of `/po-qa` really inherits (Playwright-style MCP tools do expose a resize); if none can, ADR-0060 needs revisiting, not a silent fallback.
- The standing line goes to the review's `## Not verified` on every mobile story (`review-antihallu/SKILL.md:28`). If that proves to be noise, the fix is a new ADR, not trimming the line in the driver.
- Measuring touch targets in CSS pixels assumes default zoom and a web render whose layout units map to points or dp (true for React Native Web and Flutter web at device-pixel-ratio scaling). A stack that scales its web render otherwise would mislead the measurement; the driver should then report the size it measured, not assume conformity.

## Files touched
- `method/skills/design-doctrine/SKILL.md` (section added, description extended)
- `method/skills/qa-drivers/mobile-web.md` (new)
- `tests/mobile-web-driver.test.sh` (new)
- `docs/research/s82-mobile-web-driver.md`, `docs/plans/s82-mobile-web-driver.md`, `docs/decisions/ADR-0060-…md`, `docs/verif/s82-mobile-web-driver.md`

## Test strategy
Automated (3 of a budget of 25), bash, one per criterion, at the only layer this repository has — the method text itself:
- `mobile_web_driver_sets_a_phone_viewport`, `mobile_rules_are_in_the_doctrine`, `native_only_behaviour_is_named` as in task 3. Each quotes the clause its criterion names, so deleting that clause turns it red; the "written once" check in the second makes copying the rules into the driver a failure too.
Existing tests guarding the same files, run unchanged: `qa.test.sh` (doctrine browser leads), `qa-drivers.test.sh` (table row, browser driver), `design-system.test.sh` (doctrine phrases), `overlap.test.sh`.
Visual checks: none — the story ships no screen.

## Done when
- The three new tests and the four guarding test files pass; the full suite passes once through `po-run`.
- `bash bin/po-lint method` exits 0 (it does on `main` today; `polype check .` in this worktree already reports missing `.claude/skills/` copies before the story, so it is not a criterion here).
- One commit on `story/s82-mobile-web-driver` carrying the method files, the test, the research, the plan, ADR-0060 and the verification record; a review with no open critical finding.
