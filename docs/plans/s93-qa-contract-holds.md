---
validated: yes
---
# Plan — s93-qa-contract-holds

Branch `story/s93-qa-contract-holds`. Read `docs/research/s93-qa-contract-holds.md` first. This plan builds on it without repeating it. It is a defect story (`Corrige`), and the root causes are written at the top of the research.

## Story
`qa` and the scenarios driver never conclude without proof, and never block on their own proof.
- `no_driver_row_blocks`: no row matches the surface and the platform, or `Platform` is missing or `—` → `QA status: blocked` with the cause, never `complete`.
- `own_evidence_never_blocks`:
  - the before/after comparison of `scenarios.md` sets `docs/qa/<id>/` aside;
  - a scratch script is written through Bash under the temp dir, and the driver says so;
  - a service that does not answer within the stated delay → `blocked`.
- `qa_declares_what_it_reads`: `Reads settings:` of `qa` lists `Install` and `Build`. `qa` keeps the `git status` from before the walk, and cites the story's plan among its sources.
- `scenario_rules_bite`: the blocking on a new path, the scratch folder, and the success code on bad input each have a test that fails when the rule disappears.

## Tasks
The sentences in quotes are the wording the tests pin. Keep them word for word, or change the test in the same task. Write everything else in your own words (`tests/overlap.test.sh`).

1. [x] **`method/agents/qa.md`: settings, baseline, sources.**
   - **Settings.** `:18` becomes ``Reads settings: `Target branch`, `Platform`, `Dev`, `Install`, `Build` ``.
   - **Baseline.** Walk step 1 (`:42`) adds: "Keep the output of `git -C <path> status --porcelain` as it stands before the walk: step 7 compares with it."
   - **Step 7.** `:48` keeps its pinned phrase `status --porcelain` again. It compares "with the output kept at step 1" instead of "what was there before the walk".
   - **Sources.** Scope (`:35-37`) becomes three sources. The first stays the diff plus `docs/designs/<id>/`, then the story's plan, `docs/plans/<id>.md`, "which a driver may read (the viewpoints of a scene)", then the criteria. "Two sources" becomes "Three sources".
   - Frontmatter untouched.
   - Test: `test_qa_declares_what_it_reads` (task 4). It fails if `Install` or `Build` leaves the settings line, if the baseline sentence goes, or if Scope stops naming `docs/plans/<id>.md`.

2. [x] **`qa.md` + `SKILL.md`: no driver row means blocked.**
   - **`qa.md` step 2.** After the pinned sentence at `:43` (keep it unchanged), add: "No row matches the story's surface on that platform, or `Platform` is missing from `AGENTS.local.md` or set to `—` → write the report with `QA status: blocked`, naming the surface and the platform as its cause."
   - **`qa.md` report rule.** `:51` adds: "A walk that followed no driver file is never `complete`."
   - **`SKILL.md`.** After `:21`, add a paragraph: "No row matches the story's surface on the project's platform, or `Platform` is missing or `—` → the QA ends with `QA status: blocked`, and the report names the surface and the platform. With no driver, nothing was checked."
   - Neither line mentions `Dev` (trap: `qa-drivers.test.sh:41-48`).
   - Test: `test_no_driver_row_blocks`. It fails if either rule or the "never `complete`" sentence goes.

3. [x] **`method/skills/qa-drivers/scenarios.md` and `SKILL.md:34`: own evidence never blocks.**
   - **Exception (`:12`).** The second sentence becomes: "After the walk, run it again: a path outside `docs/qa/<id>/` that the first output did not list → `QA status: blocked`, naming that path, and nothing is removed."
   - **Residual limit (s81 minor 4).** In the same paragraph, one sentence in your own words: an already-ignored directory shows as one line, so a write inside it goes unseen; the copy of ADR-0059 is the guard.
   - **Wait bound (`:14`).**
     - Replace "wait until it answers on that port" with: "wait until it answers on that port. Nothing answers there within 60 seconds → stop it and end with `QA status: blocked` and that cause."
     - Rephrase "It answers on another port" as something observable: "It prints that it listens on another port".
     - Keep the pinned `on which nothing answers before the start` and `setsid`.
   - **Scratch script (`:21`).** The `lib` clause becomes: "write a short script **through Bash** (a heredoc) under the temporary directory calling the public interface". Add: "The Write tool is refused there by `po-bounds`, so it is never the first try." Keep the pinned `calling the public interface`.
   - **`SKILL.md:34`.** Add that every file of that directory is written through Bash, since the Write tool reaches only `docs/qa/<id>/`.
   - Test: `test_own_evidence_never_blocks`. It fails if the exception, the Bash clause, or the 60-second `blocked` branch goes.

4. [x] **New `tests/qa-contract-holds.test.sh`.** One `test_<criterion>` per acceptance criterion, with the helpers of `tests/lib.sh`.
   - `test_no_driver_row_blocks`
     - `qa.md` and `SKILL.md` each hold a line with `No row matches` that also holds `` `Platform` is missing `` and `QA status: blocked`. Check this with `grep -F 'No row matches' | grep -F …` on the same line, so a stray phrase elsewhere does not satisfy it.
     - `qa.md` says `A walk that followed no driver file is never \`complete\``.
   - `test_own_evidence_never_blocks`
     - The `scenarios.md` line holding `the first output did not list` also holds `` outside `docs/qa/<id>/` ``.
     - `scenarios.md` holds `through Bash` on the line holding `calling the public interface`.
     - A line holds both `within 60 seconds` and `QA status: blocked`.
   - `test_qa_declares_what_it_reads`
     - `settings_read_by "$QA_AGENT"` lists `Install` and `Build`.
     - `qa.md` says `status --porcelain\` as it stands before the walk`.
     - The `## Scope` section of `qa.md` (awk section extract, as `gate_section` in `qa-drivers.test.sh:13`, redefined locally) holds `docs/plans/<id>.md`.
   - `test_scenario_rules_bite`, in `scenarios.md`, three separate assertions:
     - the line holding `the first output did not list` also holds `` → `QA status: blocked`, naming that path ``;
     - `Each scenario then works from a scratch folder under the same directory`;
     - `a success code on bad input` on the line holding `is a finding`.
   - Run: `bash tests/run.sh qa-contract-holds.test.sh qa.test.sh qa-drivers.test.sh scenario-driver.test.sh`.
   - The tests are the deliverable here. Each must fail when its clause is deleted, which the reviewer checks (ADR-0012).

5. [x] **Full suite and record.**
   - Run `po-run --story s93-qa-contract-holds --label 'Unit suite' -- 'bash tests/run.sh'`.
   - Run `po-run --story s93-qa-contract-holds --label Lint -- 'bash bin/po-lint'`. The lint checks that every `Reads settings` entry exists in the template.
   - No type check, E2E or build (`—`).

## Scene viewpoints
—

## Run interdicts
- **Empty diff on these files.** Out of `Owns`, or owned by s94, s95 or s96:
  - `method/commands/po-qa.md`, `method/templates/qa.md`, `method/hooks/po-bounds.sh`;
  - `method/skills/qa-drivers/browser.md`, `mobile-web.md`, `scene.md`, `simulation.md`;
  - `bin/po-lint`, `tests/run.sh`, `tests/lib.sh`, `docs/parite-killer-saas.md`;
  - every file under `.claude/` and `.polype/`.
- **qa.md frontmatter.** Its diff is empty (`tests/bounds.test.sh:175-178` reads it).
- **Pinned sentences.** These stay byte-identical:
  - the pinned sentence `qa.md:43` ("A driver file is missing → …");
  - the phrases pinned by `tests/scenario-driver.test.sh`, `tests/qa.test.sh` and `tests/qa-drivers.test.sh`.
  - `git diff main -- tests/qa.test.sh tests/qa-drivers.test.sh tests/scenario-driver.test.sh` is empty. All new assertions go in the new file.
- **No edit to an accepted ADR.** This lane writes no ADR (ADR-0069 stays unused, see the pivot).
- **No `po-bounds` widening.** The scratch-script fix is wording, not a new permission.
- **No lint case for `- QA driver: —`.** It belongs to s95 (s79 minor 3).

## The pivot
**The fail-closed rule is prose that a model follows, placed in two files that must agree.** `qa.md` (step 2 and the report rule) and `SKILL.md` both state the zero-row rule. ADR-0057 already makes a missing driver *file* `blocked`, and this extends the same choice to a missing driver *row*. That is why no new ADR is written. Ways it could be wrong:
1. **The two statements drift apart.** Compare the causes named in `qa.md` step 2 and `SKILL.md`: both must name the surface and the platform, and both `—` and a missing `Platform`.
2. **A test pins a phrase that survives the rule's removal**, which is the very defect fixed here. Delete each rule sentence and check that the matching test of `tests/qa-contract-holds.test.sh` fails. The same-line checks exist so that a lone surviving phrase does not answer for the rule.
3. **The 60-second bound is an arbitrary value.** It applies after `Install` and `Build` have already run in the copy (`scenarios.md:10`), so it covers only the start. A slow service would end `blocked` with a stated cause, never a false `complete`. That failure is visible and cheap to retune.

Not addressed: whether a real `qa` subagent obeys the text. Only a real `/po-qa` run on a CLI or API story shows it (both reviews' "Not verified").

## Files touched
- `method/agents/qa.md`
- `method/skills/qa-drivers/SKILL.md`
- `method/skills/qa-drivers/scenarios.md`
- `tests/qa-contract-holds.test.sh` (new)
- `docs/research/s93-qa-contract-holds.md`, `docs/plans/s93-qa-contract-holds.md`, `docs/verif/s93-qa-contract-holds.md` (pipeline evidence)

## Test strategy
The only layer this repository has for method prose is the bash phrase test. There are 4 new tests, one per criterion, against a `Test budget` of 25, and no existing test changes.
- Each assertion ties a consequence to its condition on the same line, so deleting the rule (not just a keyword) turns it red.
- The bite on the three `scenario_rules_bite` rules is the reviewer's to run (ADR-0012), as is the bite on the zero-row branch.
- Before the fix, the defect showed in the reproduction of the research: the three deletions left `scenario-driver.test.sh` green.

Visual checks: none. There is no screen.

## Done when
- The four acceptance-criterion tests pass, and `bash tests/run.sh` and `bash bin/po-lint` pass through `po-run`.
- The interdicts hold: empty diff outside the files above.
- The work is in one commit on `story/s93-qa-contract-holds`, carrying research, plan and record.
- The review has no open critical finding, then one squash commit lands on `main`.
