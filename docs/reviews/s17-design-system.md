# Review: s17-design-system

Diff reviewed: `git diff m2-cadrage...story/s17-design-system` (one commit, e5dbc57). I did not write this code. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s17-design-system` passes (exit 0). I checked it by hand too: `git diff --quiet 9cb84c2… HEAD -- . ':(exclude)docs'` returns 0. `Verification mode: record`, so I reused the record and did not rerun the full suite. The record: `/home/lecrabe/dev/atoll/polype/.claude/worktrees/m1-cycle/.worktrees/s17-design-system/docs/verif/s17-design-system.md`.
  - Full suite `bash tests/run.sh`: exit 0, 109 passed, 0 failed.
  - The focused run included `overlap.test.sh` against the Killer SaaS sources.
  - Typecheck, E2E and Build are all `—`: the project has none of them.
  - Its "Not proven here" section says the tests only check structure, and that the WCAG formula was checked by reading only.

## Plan
- [x] Tasks 1–7 are all present and match the plan's decision table:
  - template sections, in order;
  - the skill phrases;
  - command sections, in order, with the exact sentences;
  - one French help line after `/po-architect`;
  - the C09 status cell;
  - the verification record.

  Nothing outside the plan.
- [x] Each run interdict checked, one by one:
  - The diff touches only the 4 new owned files, one line of `method/commands/po-help.md`, the C09 line of `docs/parite-killer-saas.md`, and the story's research, plan and verif docs.
  - Nothing in `.claude/`, `.polype/`, `AGENTS*.md`, `docs/stories.md`, `docs/decisions/`, `bin/`, `tests/lib.sh`, existing tests, `method/agents/`, or existing templates and skills.
  - No new setting.
  - No `po-design.md` and no s18 templates.
  - No mention of `docs/references/`, `~/dev/vault`, `/spec` or ADR numbers (grep came back empty).
  - Overlap is green according to the record.

## References
- [x] Every referenced file exists:
  - `codebase-analysis` skill;
  - `boilerplates/<name>/profile.md`, the same convention as `po-architect.md:26` and `templates/architecture.md:9`;
  - the « UI components » row of `docs/architecture.md`;
  - `templates/design-system.md`.
- [x] Test helpers confirmed: `$METHOD`, `frontmatter`, `contains`, `needs_tool` and `require_file` exist in `tests/lib.sh`. `section_of` is the same idiom as `tests/architect.test.sh:8`.
- [x] The frontmatter tool list matches `po-architect.md` and the plan's decision.
- [x] Values checked against WCAG 2:
  - linearisation threshold 0.04045 (the WCAG 2.1 value), divisors 12.92 and 1.055, exponent 2.4;
  - weights 0.2126 / 0.7152 / 0.0722;
  - ratio (L1+0.05)/(L2+0.05) with L1 the lighter;
  - AA thresholds 4.5:1 for text and 3:1 for large text and non-text UI.

  All correct. "Large text" is not defined (see findings).

## Rules
- [x] `AGENTS.md` conventions respected:
  - method files are in English, `po-help` in French;
  - the `Reads settings:` line lists only `Target branch`, which is a template setting;
  - templates are referred to as `templates/<name>.md`;
  - the command commits with an env-file check.
- [x] No accepted ADR contradicted. The command edits no product source and hands corrected values to a person, consistent with Law 1 and Law 5. ADR-0006 is covered by the overlap test in the record.

## Tests
- [x] There is one test per criterion. Each quotes the clause it guards and pins it to its section. None of them has any of the six shapes of a test that proves nothing (these are text files: no fixtures, mocks or catch blocks).
- [x] 4 tests, within `Test budget: 25`.
- [x] Bite, mutation M1: in the Step 1 stop clause, I replaced "stop and ask for the source, in one AskUserQuestion" with "draft a palette".
  - `bash tests/run.sh design-system.test.sh`: 1 failing test (`design_system_never_invents_an_identity`).
  - Undone; `git diff --exit-code` clean.
- [x] Bite, mutation M2: I deleted "This is the only stage that measures." from Step 3.
  - 1 failing test (`design_system_measures_contrast_once`).
  - Undone; `git diff --exit-code` clean.
- [x] Bite, mutation M3: I replaced the rule "The command edits no source file: the corrected values are handed to the person…" with "Write the corrected values into the theme files."
  - `bash tests/run.sh design-system.test.sh structure.test.sh`: 0 failing tests (13 passed).
  - Undone; `git diff --exit-code` clean.
  - This rule is untested; see findings.
- [x] No existing test was made useless by this story.
- The worktree is clean after the review (`git status --porcelain` is empty).

## Neighbours
- [x] Readers of the changed code:
  - `tests/pilot.test.sh` (every command listed in help);
  - `tests/structure.test.sh` (settings exist in the template);
  - install tests: the installer copies nested skill folders, so there is nothing to register;
  - `tests/overlap.test.sh`.

  All of them are part of the recorded green full suite.
- [x] `docs/design-system.md` has no reader yet; s18 will read it at this path. Nothing is broken.

## Findings
- major — `method/commands/po-design-system.md:58`: the rule that decides how far this story reaches is covered by no test (M3 left the whole suite green). That rule is "The command edits no source file: the corrected values are handed to the person". The plan names it the pivot (a), and it keeps the command within Law 1 and Law 5. If a later edit removes it, nothing stops the command from rewriting product theme files outside a story. A single `contains` on that clause inside `## Step 3 — Measure contrast` would pin it.
- minor — `method/commands/po-design-system.md:32-37`: the command does not say what to do when the user gives a visual direction (a brand guide or palette) but the base has no system. Step 2 only inventories code, so the `## Tokens` table has no `path:line` and no dark values. Following the gaps rule, everything should become a gap. Saying so would stop an agent from turning a palette into invented tokens.
- minor — `method/commands/po-design-system.md:32,34`: the user is asked about a visual direction, then asked for the source again in a second AskUserQuestion when neither exists. It reads as two questions where one would do.
- minor — `method/commands/po-design-system.md:54`: "large text" has no definition (WCAG: at least 18pt, or 14pt bold). Without it, an agent has to guess which pairs get the 3:1 threshold.
- minor — `method/templates/design-system.md:18`: the `## Contrast` table's first column is headed `Text`, but Step 3 also measures borders, focus rings and icons against their surfaces. Calling it `Foreground` would cover those pairs.
- minor — `method/commands/po-design-system.md:49`: converting `oklch()` or `hsl()` colours says nothing about colours outside the sRGB gamut (they need clipping or gamut mapping). The ratios could differ slightly depending on which tool is used.

## Not verified
- **Running the command on a real project.** I did not run `/po-design-system` on a real base. The tests check that the prose is there, not that an agent detects tokens (Tailwind v4 `@theme`, shadcn CSS variables), picks the right text/surface pairs, or computes correct ratios. A person should run it once on the target stack (Tailwind + shadcn/ui, light and dark) and check two or three ratios with an independent contrast checker.
- **The formula.** I checked the WCAG formula by reading only, with no numeric run. A person could compute the ratio for a known pair: #767676 on #FFFFFF should give about 4.54:1.
- **The overlap check.** I did not rerun the check against the Killer SaaS sources; I relied on the record. It is current (tree matches HEAD).
- **The AskUserQuestion checkpoint and the commit on `Target branch`.** I never exercised these; they are only seen when the command runs for real.
- **Screens.** No screen ships in this story, so there was nothing to look at in a browser.

Max severity: major
Ship allowed: yes
