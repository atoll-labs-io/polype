# Research — s79-qa-drivers

## Structuring facts
- No assumption of the story is false. Every file it names exists; `method/skills/qa-drivers/` does not yet and is created here.
- `bin/po-lint` already requires every `## ` heading and every command name of the profile template (`bin/po-lint:242-257`): adding `## QA driver` and `Dev:` to `method/templates/profile.md` makes the lint demand them with no new code. Only a check of the *value* of a `- QA driver:` line would be new code.
- The QA contract is fixed by tests outside `Owns` that must stay green: `tests/platform-setting.test.sh:23-24` (two phrases of the `Dev` sentence), `tests/qa-gate.test.sh:104-108` (po-qa tools, evidence commit), `tests/bounds.test.sh:175-189` (qa frontmatter hook and `disallowedTools`), `tests/model-routing.test.sh:43`.
- `/po-drive` passes the `/po-qa` delegation prompt "word for word" (`method/commands/po-drive.md:96`): that prompt (`method/commands/po-qa.md:33`) must not change, and the driver choice belongs inside `qa.md`, not in the prompt.
- One choice the ADRs leave open: which driver a `screen` story gets when `Platform` names both `web` and `mobile` (ADR-0054 table, ADR-0055 lets a project declare several). Settled in ADR-0057.

## Story
`qa` picks its driver from the story's `Surface` and the project's `Platform`, so a CLI, a scene or a robot gets a QA before review the way a screen does. Criteria: `qa_picks_the_driver_of_the_surface` (qa preloads `qa-drivers`, whose `SKILL.md` maps surface and platform to a driver file; a missing driver file → `QA status: blocked` with its cause), `qa_runs_without_a_screen` (no stop on `Dev: —`, "no screen" or no browser tool for a non-`screen` surface; criteria a user observes, not only on screen; tree clean after QA; driver output outside its evidence goes under the temp dir; the `Dev` definition no longer says `/po-qa` stops on `—`), `browser_driver_is_the_first_one` (`browser.md` points to the `design-doctrine` section, no copy), `qa_report_names_its_driver` (template names driver and evidence form; `## Not seen` names what only real hardware, an iOS simulator or a headset would show), `profiles_declare_their_driver` (template `## QA driver` and `Dev` in `## Commands`, required by `po-lint`, filled by next-forge).

## Current code
- `method/agents/qa.md` — browser-only. Frontmatter preloads only `design-doctrine` (`:6-7`), hook `po-bounds.sh qa` (`:8-13`), `disallowedTools: Edit` (`:4`). Reads `Target branch`, `Dev` (`:17`). Checks stop on `Dev` at `—` (`:29`) and on no page-capturing tool (`:30`). Scope: diff screens + criteria "a person can see on a screen" (`:33-37`). Walk: tree (`:40`), start `Dev` (`:41`), drive the browser by `## Driving a browser` (`:42`), captures only under `docs/qa/<id>/` (`:44`), stop server (`:45`). Limits: nothing written outside `docs/qa/<id>/` (`:54`).
- `method/commands/po-qa.md` — preconditions stop on `Dev` `—` (`:26`) and "story shows no screen" (`:27`); delegation prompt (`:33`); evidence commit pathspec `docs/qa/<id>/` (`:42-43`). Description says "walks them in a browser" (`:2`), body "walks the story's screens" (`:17`).
- `method/templates/qa.md` — header `Scope:` screen-only (`:3`), `Browser tool:` (`:4`), `Origin:` (`:5`); coverage column "Screen or criterion" (`:8`); finding `Capture:` (`:21`), `Observed: <what the page did>` (`:23`); `## Not seen` reasons all web (`:26`); ends `Tree:` then `QA status:` (`:28-29`).
- `method/templates/agents-local.md:83` — `Dev` sentence ends "`/po-qa` needs it and stops on `—`." Rows `Platform` (`:53`), `QA stage` (`:54`).
- `method/templates/profile.md` — intro lists what `po-lint` checks (`:3`); `## Platform` with `- Platform: web` (`:12-16`); `## Commands` fence Install..Build, no `Dev` (`:18-28`).
- `boilerplates/next-forge/profile.md` — `## Platform` `- Platform: web` (`:12-14`); `## Commands` fence without `Dev` (`:16-24`), prose (`:26`); `apps/app/` on port 3000 (`:30`).
- `method/skills/design-doctrine/SKILL.md:31-37` — `## Driving a browser`: four bold leads, the browser contract.

## Attachment points
- New `method/skills/qa-drivers/SKILL.md` (frontmatter `name`, `description` like `method/skills/design-doctrine/SKILL.md:1-4`) and `method/skills/qa-drivers/browser.md`.
- `qa.md` frontmatter `skills:` list (`:6-7`): add `  - qa-drivers`.
- `bin/po-lint` `check_profiles` (`:225-280`): the place to read a `- QA driver:` line, modelled on `profile_platform_line` (`:205-210`) and the platform loop (`:259-272`).
- Installer copies every file of a skill folder (`bin/polype` find `-type f` at the `PAIRS` loop, proven by `tests/install.test.sh:22-25`): `browser.md` and later drivers ship with no installer change.

## Verified interfaces
- Skill base directory: a preloaded skill arrives with a header `Base directory for this skill: <absolute path>` (observed in this planner's own preloaded `codebase-analysis` and `testing-doctrine`). That is the folder a driver file is read from, in a global (`~/.claude/skills/`) or project (`.claude/skills/`) pose alike.
- `po-bounds.sh qa` (`method/hooks/po-bounds.sh:13-18`): Write only under `docs/qa/<id>/`; Bash: git reading verbs only, other commands are not path-checked. A driver's by-products in `${TMPDIR:-/tmp}` therefore go through Bash (`mktemp -d`), never the Write tool.
- Story surface: line `- **Surface**: …` (`method/templates/stories.md:12`); no line → "it has a screen when its text shows one" (`method/skills/agentic-stories/SKILL.md:37`). Surface-to-platform table (`method/skills/agentic-stories/SKILL.md:39-48`).
- next-forge at `f189de7…` (fetched read-only for this research): root script `"dev": "turbo dev"` (`NF:package.json:20`); `apps/app` `"dev": "bun --bun next dev -p 3000"` (`NF:apps/app/package.json:5`). So `Dev: bun run dev` is grounded.
- `tests/lib.sh`: `contains`, `require_file`, `fail`, `frontmatter`, `settings_read_by`, `template_settings`.

## Traps
- **Frozen phrases (in `Owns`, change with their clause)**: `tests/qa.test.sh:46` (`` `Dev` is `—` → stop: the project has no command to start it ``), `:51` (`No tool in your session can open a page and capture it → stop and report it`), `:52` (`write no report`), `:38-40` (`git diff <Target branch>...story/<id>`, `each acceptance criterion`, `Nothing else is walked.`), `:13` (`Steps to reproduce:`, `Capture:`, …), `:17-18` (last two lines `Tree:` then `QA status: <complete | blocked>`), `:62` (`` `Dev` starts the development server ``), `:32` qa preloads `design-doctrine`.
- `tests/qa.test.sh:23-31`: the four bold leads of `## Driving a browser` must sit in exactly one file of `method/` — `browser.md` copying them breaks it, which is the criterion's own guard.
- **Frozen phrases (outside `Owns`)**: `tests/platform-setting.test.sh:23-24` — keep "or whatever serves what a person looks at" and "`—` when the project has nothing to serve" verbatim.
- `tests/profile.test.sh:31` fixes the template commands to exactly `Install Test Typecheck E2E Build ` — must become `… Build Dev ` (in `Owns`).
- `tests/next-forge-profile.test.sh:44-52` grounding: each command value must be `bun install` or `bun run <root script>`. `Dev: bun run dev` passes; `bun run dev -- --filter=app` would not.
- `bin/po-lint` fail-closed rule (`:164-182`): in a `## Checks` / `## Preconditions` section, a line whose part before `→` holds `No `, `no `, `not `, `` `—` `` … must say `stop`, `ask`, `carry on` or `never blocks` after it. Every new arrow line in `qa.md` Checks and `po-qa.md` Preconditions must obey it.
- `Reads settings:` of `qa.md` gains `Platform` (exists, `agents-local.md:21`); `po-lint` checks names (`bin/po-lint:98-115`).
- `tests/overlap.test.sh`: new method text must be original wording (ADR-0006).
- Routing (which stories go to QA under `QA stage`) is s80's: `po-drive.md:96`, `po-orchestrator.md:65` stay untouched here.

## Open questions
- `web` and `mobile` both declared, `screen` story: which driver? → plan decides (ADR-0057).
- Should `po-lint` check the driver *value* or only the section? Presence alone repeats the gap ADR-0055 closed for `Platform` → plan decides (ADR-0057).
- A dirty tree after QA (untracked file outside `docs/qa/<id>/`): blocked, or cleaned by qa? → plan decides.
- Does every Claude Code version announce the base directory of a skill preloaded in a subagent? Observed here, not documented in the repo; the plan makes its absence a blocked cause rather than a guess.
- `docs/` (French docs, e.g. `docs/installation.md`) are not in `Owns`; any mention of the browser-only QA there stays stale until s80 or a later story.

## Complexity
Story 4 → 4. Text work across five method files plus one lint rule, but held by many frozen phrases and the fail-closed lint; one structural choice needs an ADR.

## Split
Not needed at 4.
