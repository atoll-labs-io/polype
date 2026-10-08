# Research — s82-mobile-web-driver

## Structuring facts
- No assumption of the story is false. The driver file is already routed: `qa-drivers` maps `screen` on `mobile` to `mobile-web.md` (`method/skills/qa-drivers/SKILL.md:13`), and `tests/qa-drivers.test.sh:25` already checks that row; only the file is missing, so a `mobile` project's screen QA ends `blocked` today (`SKILL.md:24`, ADR-0057 "Bad").
- "Le rapport QA le reporte comme non vu" needs no template change: `## Not seen` exists (`method/templates/qa.md:27-28`), `qa-drivers` sends out-of-reach items there (`SKILL.md:36-37`), and the review carries every `## Not seen` item into `## Not verified` (`method/skills/review-antihallu/SKILL.md:28`, `method/agents/reviewer.md:51`).
- Two of the four doctrine rules (safe areas, on-screen keyboard) cannot be *seen* in a web render in a desktop browser: no notch, no gesture bar, no virtual keyboard. They are rules for the designer and the reviewer reading the code; the driver must list them under what it cannot show, not claim to check them.
- The four lead phrases of `## Driving a browser` must exist in exactly one file of `method/` (`tests/qa.test.sh:23-31`): `mobile-web.md` points to that section, it never copies it.

## Story
QA of a `screen` story on a `mobile` project goes through the stack's web render, served by `Dev`, in a browser at phone width, so clout is checkable without an emulator.
- `mobile_web_driver_sets_a_phone_viewport` — `qa-drivers/mobile-web.md` serves the web render with `Dev`, opens the screen at phone width (at least 360 and 412 px wide) and in portrait, and captures each state.
- `mobile_rules_are_in_the_doctrine` — `design-doctrine` gives the mobile rules a screen holds: touch targets at least 44 by 44 points, safe areas (notch, gesture bar), keyboard not hiding the active field, no hover as the only way to act.
- `native_only_behaviour_is_named` — the driver lists what the web render does not show (native permissions, notifications, camera, system gestures) and the QA report records it as not seen.
Owns: `method/skills/qa-drivers/mobile-web.md`, `method/skills/design-doctrine/`, `tests/mobile-web-driver.test.sh`.

## Current code
- `method/skills/qa-drivers/SKILL.md` — driver table (`:9-17`); `web, mobile` runs `browser.md` then `mobile-web.md`, each in full (`:21`); driver file read from the skill's announced base directory, missing → `QA status: blocked` (`:23-24`); the five things every driver file says (`:26-31`); by-products only under `mktemp -d` (`:33-34`); out-of-reach items to `## Not seen` (`:36-37`).
- `method/skills/qa-drivers/browser.md` (19 lines) — the model to follow: `## Needs` (`Dev` not `—`, a tool that opens and captures a page, `:5-7`), `## Start and stop` (start `Dev` in the background, read its origin, blocked if none answers, stop it at the end, `:9-10`), `## Exercising a criterion` (drive by `design-doctrine`'s `## Driving a browser`, not repeated, `:12-13`), `## Evidence` (captures under `docs/qa/<id>/`, `:15-16`), `## Cannot show` (`:18-19`).
- `method/skills/qa-drivers/scenarios.md` — second driver, same five headings (`:5,9,20,29,36`), a bulleted `## Cannot show` list (`:36-41`).
- `method/skills/design-doctrine/SKILL.md` (37 lines) — sections: truth, derived/new screens, no invention, gaps, mockups, measuring, dark mode, `## Driving a browser` (`:31-37`, last section). No mobile rule anywhere in `method/` (grep for viewport, touch, safe area, hover, 44: nothing).
- `method/agents/qa.md` — preloads `qa-drivers` and `design-doctrine` (`:8`, `:20`); stops when the surface is `screen` and no tool can open and capture a page (`:32`) or `Dev` is `—` (`:31`); picks and follows driver files (`:43-46`).
- `method/templates/agents-local.md:83` — `Dev` already defined as what serves "the web render of a mobile app".

## Attachment points
- New file `method/skills/qa-drivers/mobile-web.md`, same five headings as `browser.md`/`scenarios.md`.
- New section in `method/skills/design-doctrine/SKILL.md`, after `## Driving a browser`; frontmatter `description` (`:3`) lists the doctrine's contents and should name the new rules.
- `bin/po-lint:189-217,283` accepts `- QA driver: <name>` when `method/skills/qa-drivers/<name>.md` exists: the new file makes `mobile-web` a valid profile driver, which s83 and s84 rely on. Nothing to edit there.

## Verified interfaces
- Driver-file contract: `SKILL.md:26-31` (needs; start/stop; one criterion; evidence form and names; cannot show).
- Section extraction in tests: `awk '/^## / {on = ($0 == "## Driving a browser")} on'` (`tests/qa.test.sh:25`) — a following `## ` heading ends the section, so a new section after it does not disturb it.
- Test helpers: `contains`, `require_file`, `fail` in `tests/lib.sh`; `$METHOD` is `method/`; runner `bash tests/run.sh <file>`.

## Traps
- `tests/qa.test.sh:23-34` — the four leads of `## Driving a browser` must stay verbatim, in that section, in one file only. Do not reword the section's intro line either (the story's note).
- `tests/qa-drivers.test.sh:57-65` checks `browser.md` copies no lead; the new test should apply the same check to `mobile-web.md`, and the same "written once" check to the mobile rules.
- `tests/design-system.test.sh:43-55` quotes several phrases of the doctrine and its `name:`; leave those sections untouched.
- `tests/overlap.test.sh` — no 8-word run shared with Killer SaaS; write in own words.
- `po-bounds` mode `qa` lets the agent write only `docs/qa/<id>/` and the `mktemp -d` dir; captures go through the browser tool's save option or a Bash copy, as in `browser.md:16`.
- Not every browser tool of a session can set a viewport size. A driver that silently captures at desktop width would produce evidence of the wrong screen.
- No migration, no dependency, no API contract, no screen, no auth scope: none of the five escalation signals.

## Open questions
- What happens when the session's browser tool can open a page but cannot set its viewport? (Plan: `QA status: blocked` naming the cause; ADR-0060.)
- Are the native-only items listed in every report, or only when a criterion relies on them? (Plan: one standing line in every report plus one line per criterion that relies on one; ADR-0060.)
- Do the doctrine's mobile rules also bind web screens at mobile width? (Plan: no; they bind screens of a project whose `Platform` holds `mobile`, so the designer's web contract does not change silently.)
- Points versus CSS pixels: at default zoom a CSS pixel stands for one iOS point or Android dp, so 44 points is measured as 44 CSS px in the web render. Settled in the doctrine text.

## Complexity
3 → 3. Two prose files and one test file, but the driver must be honest about what a web render cannot show, and three existing tests freeze the doctrine and the driver contract.

## Split
— (not at 5)
