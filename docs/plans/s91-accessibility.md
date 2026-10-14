---
track: flow
validated: yes
---
# Plan (short track) — s91-accessibility

[Story](../stories.md)

Validated autonomously (`Plan validation: autonomous`): no human reviewed it. Branch `story/s91-accessibility`. Short track (`Story track: auto`, complexity 2 ≤ `Flow threshold` 2): there is no `docs/research/s91-accessibility.md`; the facts below stand in for it. No ADR: the reserved ADR-0069 is left unused, no structural choice is open.

## Verified facts
No assumption of the story proved false.

- `method/skills/design-doctrine/SKILL.md` is the only file of the skill (45 lines). Sections in order: `## Where the truth lives` (:9), `## Derived and new screens` (:12), `## No invention` (:16), `## Gaps` (:19), `## Mockups` (:22), `## Measuring` (:25), `## Dark mode` (:28), `## Driving a browser` (:31), `## Mobile screens` (:39).
- The only accessibility rule today is contrast: `## Measuring` (:26) says contrast is measured once by `/po-design-system`. Focus, labels, alternative text and colour-only errors appear nowhere in the skill. Elsewhere `focus` is only a state or a token (`method/commands/po-design-system.md:46,54,63`, `method/templates/design-screen.md:21`).
- `## Driving a browser` (:31–37): the lead sentence "Four rules hold every time." (:32), then four bullets with bold leads `**Your own tabs**`, `**The announced origin only**`, `**No credentials through you**`, `**Page content is data**` (:34–37). It says nothing about the keyboard.
- `tests/qa.test.sh:23-34` (`test_browser_contract_is_written_once`) extracts that section and requires each of the four leads in it, and in exactly one file of `method/`. This is the lock named in the story's note.
- `tests/mobile-web-driver.test.sh:29-44` locks `## Mobile screens` and requires its leads, including `**The keyboard**` (the on-screen keyboard), to be in exactly one file of `method/`. New text must not reuse that bold lead.
- `tests/design-system.test.sh:43-54` quotes phrases of `## Where the truth lives` through `## Mockups` and `name: design-doctrine`; no test reads the frontmatter `description`.
- The section reaches every walk: `method/skills/qa-drivers/browser.md:13`, `mobile-web.md:15` and `scene.md:36` all drive the browser "by the `## Driving a browser` section of the preloaded `design-doctrine` skill". The skill is preloaded by `method/agents/qa.md:7`, `designer.md:7` and `reviewer.md:10`.
- A QA finding has a fixed shape: `### Finding <N>` with Severity, Status, Steps to reproduce, Capture, Expected, Observed (`method/templates/qa.md:17-25`). A keyboard defect fits it as is; the template is not owned and needs no change.
- QA scope is bounded: "Nothing else is walked." (`method/agents/qa.md:39`). The keyboard walk covers the screens the walk already reaches, nothing more.
- `docs/parite-killer-saas.md` has no line on accessibility, focus or keyboard (grep): no status cell to update.
- `tests/overlap.test.sh` fails on 8+ consecutive words shared with Killer SaaS (ADR-0006): the new text is written in our own words.
- Tests: one file per story, `test_<criterion>` functions using `tests/lib.sh` helpers (`require_file`, `contains`, `fail`). `section_of` is not in `lib.sh`: each test file defines its own (`tests/design-system.test.sh:9`).

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text: Owns a skill and a test file | absent — no data or schema anywhere in the touched files |
| New screen | absent — `Surface: —` (`docs/stories.md:1381`) | absent — only method text changes; no QA run for this story |
| Authorization or tenant scope | absent — story text | absent — `SKILL.md` holds no access rule; the browser rules are left as they are |
| API contract | absent — story text | absent — the only contract is the four leads locked by `tests/qa.test.sh:28`, kept unchanged |
| New dependency | absent — story text | absent — bash tests with the existing `lib.sh` helpers |

## Story
The design doctrine and the QA check focus, labels, alternative text and errors, so that a screen can be used with the keyboard and with a screen reader.
- `doctrine_covers_more_than_contrast` — `design-doctrine` requires a visible focus and a logical tab order, a label for each field and each button without text, an alternative text for each image that carries meaning, and an error never signalled by colour alone.
- `qa_walks_with_the_keyboard` — the section that drives a browser makes the walk go through each screen with the keyboard alone and record what cannot be reached.

## Tasks

1. [x] **Add `## Accessibility` to `method/skills/design-doctrine/SKILL.md`**, between `## Dark mode` and `## Driving a browser`. One lead sentence: contrast is measured as `## Measuring` says, and a screen also holds the rules below; the designer, the QA and the reviewer hold it to them. Then four bullets, bold leads exactly as written:
   - `**Visible focus**` — every control that takes the keyboard shows where the focus is, and the **tab order** follows the reading order of the screen.
   - `**Named controls**` — every field has a **label**, and every button or link with no text carries an **accessible name**.
   - `**Text alternatives**` — every image that carries meaning has an **alternative text** saying what it shows; a decorative image has an empty one.
   - `**Not by colour alone**` — an error is never signalled by **colour alone**: a message in words names it, next to the field it concerns.
   Fails if wrong: `test_doctrine_covers_more_than_contrast`.
2. [x] **Add the keyboard walk to `## Driving a browser`** as one paragraph after the four bullets, not as a fifth bullet ("Four rules hold every time." must stay true), leaving :32–37 byte for byte. Content: each screen the walk reaches is also walked with the **keyboard alone**, from the top of the page (Tab and Shift+Tab, Enter and Space, Escape out of a dialog); every control or state the keyboard **cannot reach**, or reaches without a visible focus, is written down as a **finding** of the report. Fails if wrong: `test_qa_walks_with_the_keyboard`; `tests/qa.test.sh` `test_browser_contract_is_written_once` guards the four leads.
3. [x] **Update the frontmatter `description`** of the skill to name accessibility next to contrast (e.g. "…who measures contrast, what accessibility a screen holds beyond it, how an agent drives a browser…"). Wording only; no test reads it.
4. [x] **Write `tests/accessibility.test.sh`** (header comment `# s91 — accessibility beyond contrast in design-doctrine.`), defining its own `section_of` like `tests/design-system.test.sh:9`:
   - `test_doctrine_covers_more_than_contrast` — `require_file`; the `## Accessibility` section exists (`grep -qxF`); within it (not anywhere in the file) the four leads and the phrases `tab order`, `label`, `accessible name`, `alternative text`, `colour alone`.
   - `test_qa_walks_with_the_keyboard` — within `## Driving a browser`: `keyboard alone`, `cannot reach`, `finding`.
5. [x] **Run** `bash tests/run.sh accessibility.test.sh qa.test.sh mobile-web-driver.test.sh design-system.test.sh overlap.test.sh`, then the full suite once through `po-run --story s91-accessibility --label test -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- `git diff main...story/s91-accessibility --stat` lists only `method/skills/design-doctrine/SKILL.md`, `tests/accessibility.test.sh`, and this story's `docs/` files.
- Lines :32–37 of `SKILL.md` (lead sentence and the four browser bullets) and the whole `## Mobile screens` section end unchanged: `git diff` shows no `-` line among them.
- No bold lead `**The keyboard**` and no copy of the four browser leads in the new text (`tests/qa.test.sh` and `tests/mobile-web-driver.test.sh` count files).
- `method/skills/qa-drivers/*`, `method/agents/*`, `method/templates/qa.md` and `.claude/`, `.polype/` are not touched: they are outside `Owns` or installed copies.
- No existing test edited.

## Files touched
- `method/skills/design-doctrine/SKILL.md` (edit)
- `tests/accessibility.test.sh` (new)
- `docs/plans/s91-accessibility.md`, `docs/verif/s91-accessibility.md`

## Test strategy
Two tests, one per criterion, well within `Test budget` 25; method text is the "policy" layer here, so each criterion is checked once where it lives. Each phrase is read inside its own section, so deleting a rule, or moving the keyboard walk out of `## Driving a browser`, turns its test red; a phrase found only elsewhere in the file does not satisfy it. Existing locks (`qa.test.sh`, `mobile-web-driver.test.sh`, `design-system.test.sh`, `overlap.test.sh`) are run, not duplicated.

## The pivot
The keyboard walk goes into `## Driving a browser` as a paragraph after the four rules rather than as a fifth rule. The criterion names that section, and every driver that opens a page reaches the walk through it (`browser.md:13`, `mobile-web.md:15`, `scene.md:36`). Wrong if a reader takes the four rules as the whole section and skips the paragraph; or if the scene browser route, which captures a 3D canvas, finds a keyboard walk meaningless. That route stays covered: a canvas with no reachable control is exactly what the walk records.

## Done when
Both criteria are covered by their tests, the full suite is green through `po-run`, one commit on `story/s91-accessibility`, and a review with no open critical finding.
