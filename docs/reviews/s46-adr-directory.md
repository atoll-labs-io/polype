# Review: s46-adr-directory

[Story](../stories.md) · [Plan](../plans/s46-adr-directory.md) · [Verification](../verif/s46-adr-directory.md)

Diff reviewed: `git diff m4-catalogue...story/s46-adr-directory` (one commit, 505681f), read in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## When blocked
Not applicable.

## Ownership
I listed the diff with `git diff --name-only m4-catalogue...story/s46-adr-directory`: 20 paths.
- [x] Every path is inside the `Owns` line that the story branch carries. That line was widened by this same diff (task 6, `docs/stories.md:686`).
- [x] Outside the `Owns` declared on `m4-catalogue` when the lane started: `method/templates/architecture.md`, `method/commands/po-brief.md`, `method/commands/po-drive.md`, `method/commands/po-status.md`, `method/agents/designer.md`, `method/agents/stories-reviewer.md`, `AGENTS.local.md`, `tests/architect.test.sh`, `docs/stories.md`, `docs/parite-killer-saas.md`. The original line listed only 8 paths. See finding 1.
  - Two of these are required by a written rule. `docs/parite-killer-saas.md` follows the Conventions rule "When a story implements lines of the parity matrix, it updates their status cell". `AGENTS.local.md` follows "Reading settings": a missing setting means the command stops. The skill rates those two as minor gaps in `Owns`.
- [x] Inside another running story's `Owns`: none. `git worktree list` shows only main, m4-catalogue and this lane, and `git branch --no-merged m4-catalogue` lists only `story/s46-adr-directory`.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s46-adr-directory` exits 0, and the record is reused. I also checked by hand: `git diff --quiet a28fdde… HEAD -- . ':(exclude)docs'` exits 0.
  - `docs/verif/s46-adr-directory.md` is marked complete. It records the full suite (`bash tests/run.sh`, exit 0, 234 passed) and `bin/po-lint method` (exit 0).
  - The project has no type check (`Typecheck: —`), no E2E and no build command, and I did not substitute any.
  - I read its "Not proven here" section: installed copies not refreshed, and agent runtime resolution not exercised. Both carry into "Not verified" below.

## Plan
- [x] All six tasks are present and ticked. Nothing appears outside the plan's "Files touched".
- [x] Each run interdict holds, checked with `git diff --name-only` on:
  - `docs/decisions/`: empty
  - `.claude/`: empty
  - `.polype/`: empty
  - root `AGENTS.md`: empty
  - `bin/`: empty
  - `method/skills/`: empty
  - `method/templates/adr.md`: empty
  - `docs/parite-killer-saas.md`: only row G04 changed

## References
- [x] Lint's `settings` rule (`bin/po-lint:86-114`) reads setting names from the fenced block of `method/templates/agents-local.md`. The new `ADR directory:` line sits inside that block, and the error text `reads unknown setting '<name>'` matches the test.
- [x] `settings_read_by`, `template_settings`, `$METHOD` and `$ROOT` come from `tests/lib.sh`. The test file loads and runs.
- [x] After the change, `grep -rn decisions method/ bin/` finds no fixed ADR path anywhere in `method/`.
- [x] The default `docs/decisions/` matches the real folder of this repository. The story notes say it is not renamed.
- [x] The trailing `/` that `<ADR directory>NNNN-<slug>.md` relies on is documented in the values table ("ends with `/`"). It is not enforced, which is the same convention as `Worktree root`.

## Rules
- [x] `AGENTS.md` conventions are respected:
  - method text is in English;
  - every setting read is declared on the `Reads settings:` line and exists in the template;
  - the changed clause of `tests/architect.test.sh` is stated in the plan;
  - the parity matrix cell was updated;
  - no installed copy was edited.
- [x] No accepted ADR is contradicted. ADR-0002 (project ADRs in the repository) still holds, since only the folder becomes configurable.

## Tests
- [x] There are four tests, one per acceptance criterion, named after it. None of them has one of the six empty shapes.
  - The lint test runs the real `bin/po-lint` on a real copy of `method/`.
  - It sets an EXIT trap inside a test function, which is safe because `tests/run.sh` runs each test in its own `bash -c`.
- [x] 4 tests against a `Test budget` of 25.
- [x] Bite 1: I removed `` `ADR directory` `` from `Reads settings:` in `method/commands/po-brief.md`. Running `adr-directory.test.sh` gave 1 failing test (`every_command_that_writes_an_adr_reads_the_setting`). Undone, and `git diff --exit-code` is clean.
- [x] Bite 2: I disabled the `reads unknown setting` report in `bin/po-lint`. Running `adr-directory.test.sh lint.test.sh` gave 2 failing tests (`lint_accepts_the_new_setting`, `lint_checks_every_command_declares_its_settings`). Undone, and `git diff --exit-code bin/po-lint` is clean.
- [x] No test is made useless by the story. The `tests/architect.test.sh:39` clause was updated to the new wording.
- `git status --porcelain` is empty at the end of the review.

## Neighbours
- [x] I read the other commands that refer to ADRs:
  - `po-research.md:38` and `po-flow.md:54` read "the accepted ADRs" without naming where they are (finding 2);
  - `po-execute`, `po-review` and `po-orchestrator` never named a path;
  - skills and other templates have no path.
- Nothing is broken. The installed copies under `.claude/` and `.polype/` still say `docs/decisions/` until the installer runs again.

## Findings
1. **major** — `docs/stories.md:686`: the lane widened its own `Owns` line, from 8 paths to 18. It added 10 paths (listed under Ownership) that the scope declared when the lane was dispatched did not cover.
   - The plan announced the change openly (Verified facts, task 6), and the added paths are the ones the criteria actually need.
   - But the plan was validated autonomously (`Plan validation: autonomous`), so nobody widened the scope on purpose, and `/po-drive` computes lane conflicts from the `Owns` on `Target branch` before launch.
   - No harm this time, because no other lane was running. A person should confirm the widened line, or tighten the rule on who may amend `Owns`.
2. **minor** — `method/commands/po-research.md:38`, `method/commands/po-flow.md:54`: both read "the accepted ADRs" but neither names `<ADR directory>` or declares the setting. Now that the location is configurable, these two readers have no stated way to find it. This is outside `Owns`, so it is for a later story.
3. **minor** — `method/commands/po-drive.md:77`, a line the diff touched: numbers are read as "the highest `ADR-NNNN`", while Law 6 names files `NNNN-<slug>.md`. This repository's ADRs are `ADR-NNNN-<slug>.md`. The mismatch existed before this story, but a project "with its own numbering" (the purpose of s46) makes it more visible.
4. **minor** — `docs/parite-killer-saas.md:95` and `AGENTS.local.md`: these are outside the original `Owns` but required by written rules (parity-matrix convention and "Reading settings"). They are gaps in `Owns`, not implementer breaches.

## Not verified
- **An agent at run time.** I did not check that an agent actually resolves `<ADR directory>` from `AGENTS.local.md` and writes an ADR at a non-default path such as `docs/adr/`. The tests check the text and the lint, not agent behaviour. A person should run `/po-plan` or `/po-architect` on nautile (`ADR directory: docs/adr/`) and confirm the ADR lands there.
- **Installed copies.** I did not check that `.claude/`, `.polype/` and the root `AGENTS.md` pick up the new wording. They refresh on the next `polype update` or install, after ship. A person should run the installer and then `polype check`.
- **Links in the architecture template.** Links built from `templates/architecture.md` with an ADR folder outside `docs/` need a `../` prefix. I did not render one. A person should check the first `docs/architecture.md` produced for a project whose ADRs are not under `docs/`.
- **Suite and lint.** I did not rerun them: I relied on the current record, as `Verification mode: record` allows. There is no type check, E2E or build command in this project.

Max severity: major
Ship allowed: yes
