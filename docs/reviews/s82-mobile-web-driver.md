# Review — s82-mobile-web-driver

Story: s82-mobile-web-driver — Le mobile vérifié par son rendu web d'abord
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s82-mobile-web-driver
Reviewed tree: 7834a091dbbacedc72a272493e6dbafbd3442ae6
Fix loop: 0
Lenses run: none. The diff changes only method prose, one bash test and docs. No auth, route, migration, lockfile or server-side path or content is involved.

## Scope (Owns)
I checked every path from `git diff --name-status main...story/s82-mobile-web-driver`:
- `method/skills/qa-drivers/mobile-web.md` (A): matches an `Owns` file entry.
- `method/skills/design-doctrine/SKILL.md` (M): sits under the `method/skills/design-doctrine/` folder entry.
- `tests/mobile-web-driver.test.sh` (A): matches an `Owns` file entry.
- `docs/research/`, `docs/plans/` and `docs/verif/s82-mobile-web-driver.md`: the story's own pipeline evidence, in scope by construction.
- `docs/decisions/ADR-0060-…md` (A): an ADR the diff adds and the plan names by file name and number, so it is in scope by construction.

Nothing is outside `Owns`. No path falls in another running story's `Owns`: s83–s86 own only `boilerplates/…` and their own test files.

## Evidence reused
- `po-gate verif-current s82-mobile-web-driver` exits 0. The record is complete, and the `Unit suite` row (`bash tests/run.sh`) exited 0 on code equal to `Tree: 871abb88…` outside `docs/`. Under `Verification mode: record` I did not rerun the full suite.
- The project has no type check (`Typecheck: —`), no E2E and no build. That is reported as is, with nothing put in their place.
- The record's "Not proven here" section says three things. No real mobile QA was run. Whether the session's browser tools can set a viewport is unknown. `bin/po-lint method` was run by hand. I reran `bash bin/po-lint method` myself: "no breach in 25 file(s)", exit 0.
- No QA is required: the story's `Surface` is `—` and it ships no screen. No design conformity check applies.

## Steps
1. **Reuse:** see above.
2. **References:** all targets exist and match:
   - The `qa-drivers/SKILL.md` table row `screen` / `mobile` → `mobile-web.md` (line 13) and the five-point driver contract (lines 26–31).
   - The section `## Driving a browser` of `design-doctrine`.
   - `Dev` in `method/templates/agents-local.md:83` ("the web render of a mobile app").
   - `Platform` in `agents-local.md:53`.
   - `ADR-0054` and `ADR-0057`.
   - Test helpers `contains`, `require_file`, `fail` and `$METHOD` in `tests/lib.sh`.
3. **Plan:**
   - Tasks 1–4 are all present as specified: the four bold leads, the extended description, the five headings, 360/412 in portrait, captures per state and per width, the blocked branch, the `## Cannot show` list, and the standing line plus one line per criterion.
   - The last bullet of the plan's pivot (a stack scaling its web render) is written into the driver too.
   - Run interdicts hold. `design-doctrine` changes only its `description` line and gains appended lines; the four browser leads are untouched. `SKILL.md`, `browser.md`, `scenarios.md`, `qa.md`, `po-qa.md`, `templates/qa.md` and `bin/po-lint` are untouched. No existing test was edited, and nothing under `.claude/`, `.polype/` or `boilerplates/` changed.
   - The changes match ADR-0054, ADR-0057 and the new ADR-0060.
4. **Tests:**
   - *Floor:* `po-gate floor-guard s82-mobile-web-driver main` exits 0; nothing was lowered.
   - *Apparent coverage:* 3 tests, all quoting exact phrases of the files under test, with no fixtures or mocks. The "written in exactly one file of `method/`" check catches the mobile leads being copied into the driver. None of the six kinds of test that prove nothing is present.
   - *Excess:* 3 tests against a budget of 25.
   - *Bite:* three mutations. After each I restored the file with `git checkout --` and confirmed it with `git diff --exit-code`, and the final `git status --porcelain` is empty.

| Mutation | Tests run | Failed |
| --- | --- | --- |
| Removed the line in `mobile-web.md` that blocks when a tool cannot set the viewport (and forbids zoom) | `mobile-web-driver.test.sh`, `qa-drivers.test.sh` | 1 (`mobile_web_driver_sets_a_phone_viewport`) |
| Removed the standing `## Not seen` / per-criterion paragraph of `mobile-web.md` | same | 1 (`native_only_behaviour_is_named`) |
| Removed the `**No hover**` bullet from `design-doctrine` | `mobile-web-driver.test.sh`, `qa.test.sh`, `design-system.test.sh` | 1 (`mobile_rules_are_in_the_doctrine`) |

5. **Values:**
   - The 44×44 points figure and 360/412 widths come straight from the story's criteria.
   - "One CSS pixel stands for one point or dp at default zoom" is settled in ADR-0060, and the driver hedges it ("report the size you measured rather than assuming it conforms").
   - The capture naming `<screen-or-criterion>-<state>-360.png` is consistent with `browser.md` and stays under `docs/qa/<id>/`.
6. **Neighbours:**
   - `method/agents/qa.md` picks driver files from the table and stops before any report when no tool can open and capture a page. The driver's narrower case (a tool can open a page but cannot set its size) writes a `blocked` report instead. These are separate conditions, not a contradiction.
   - `bin/po-lint` now accepts `- QA driver: mobile-web`, which s83 and s84 rely on. Lint is clean.
   - On a `web, mobile` platform, `browser.md` then `mobile-web.md` each start and stop `Dev` in full, as `qa-drivers` requires.

## Findings
None of critical, major or minor grade.

Observation, not graded: ADR-0060 turns down the "whole list in every report" option because it would mean "six lignes répétées". The driver's `## Cannot show` lists seven items, sign-in included. The standing line covers only native behaviour, so the reasoning still holds.

## Not verified
- **A real mobile QA walk with this driver.** No mobile project in this repository has a web render. To cover it, a person runs `/po-qa` on the first clout screen story after s83/s84 and checks that captures come out at 360 and 412 wide in portrait.
- **Whether the browser tools a `/po-qa` session inherits can set viewport width and height.** If none can, every mobile QA ends `blocked`, which is the risk named in the plan's pivot. To cover it, a person checks the session's browser MCP for a resize or viewport call before the first mobile QA.
- **The equivalence of CSS pixels to points/dp for React Native Web and Flutter web.** It is taken from ADR-0060 and was not measured here. A person can check it during the first mobile QA by comparing a control's measured box with its native size.
- **The full suite and `tests/overlap.test.sh`.** I did not rerun them; I relied on the `po-run` row of the record, on the same code outside `docs/`.

Max severity: none
Ship allowed: yes
