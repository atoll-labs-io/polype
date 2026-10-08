# Review: s79-qa-drivers

Reviewed tree: e661b87faecab13b1b36868fcc2aeb439e1e20d5
Fix loop: 0
Scope: `git diff main...story/s79-qa-drivers` (commit 9ac38da)
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s79-qa-drivers

## Scope check (Owns)
All 16 changed paths are inside the story's `Owns`, or are in scope by construction:
- `docs/research|plans|verif/s79-qa-drivers.md` are the story's own pipeline evidence.
- `docs/decisions/ADR-0057-…md` is a new file (status `A`), and the plan names it.

No accepted ADR is modified. `git worktree list` shows no other story lane, so there is no overlap with another story. `tests/next-forge-profile.test.sh` is owned but left unchanged, which is fine.

## Step 1: evidence reused
- `po-gate verif-current s79-qa-drivers` exits 0. `Verification mode: record` applies, so I relied on the recorded passing runs and did not rerun them: Unit suite `bash tests/run.sh` (exit 0) and Lint `bash bin/po-lint` (exit 0).
- The project has no Typecheck, E2E or Build command (all set to `—`).
- I read the record's "Not proven here" section.
- The story has no screen (`Surface: —`), so no QA gate is required.

## Step 2: references
I opened every target the diff points to. All exist:
- `design-doctrine` § `## Driving a browser` (SKILL.md:31)
- the `Platform` setting in `method/templates/agents-local.md:21,53`
- the `Surface` line in `method/templates/stories.md:12`
- the admission table in `method/skills/agentic-stories/SKILL.md`, which matches the new driver table row for row

`bin/polype` copies skill folders recursively (`find . -type f`), so `browser.md` will be installed next to `SKILL.md`. The `qa` mode of `po-bounds` limits only Write and git verbs, so `mktemp -d` and `rm` through Bash are allowed, which the SKILL relies on.

## Step 3: plan conformity
- Tasks 1 to 7 are all present and match the plan.
- Run interdicts are respected:
  - no diff on po-bounds, po-drive, po-orchestrator, po-flow, po-status, po-review, design-doctrine, AGENTS.md, `.claude/` or `.polype/`;
  - the delegation prompt, model paragraph, evidence commit and Report sections of `po-qa.md` are untouched;
  - `browser.md` is the only driver file written;
  - no `QA stage` reading was added;
  - the template still ends with `Tree:` then `QA status:`.
- Existing test changes are limited to the clauses the story changes (`tests/qa.test.sh` two lines, `tests/profile.test.sh`), as the plan announced.

## Step 4: tests
- **Floor:** `po-gate floor-guard s79-qa-drivers main` exits 0. Nothing was lowered.
- **Budget:** 5 new tests and 3 changed ones, within the budget of 25.
- **Bite 1:** I neutralised the driver-value check in `bin/po-lint` (`|| [ ! -f …/qa-drivers/$value.md ]` replaced by `|| false`) and ran `qa-drivers.test.sh`. 1 test failed (`profiles_declare_their_driver`: "lint accepts the driver browsr"). Restored; `git diff --exit-code bin/po-lint` is clean.
- **Bite 2:** I removed the `screen` scope from the `Dev` stop in `method/agents/qa.md` and ran `qa-drivers.test.sh` and `qa.test.sh`. 1 test failed (`qa_runs_without_a_screen`). Restored; `git diff --exit-code method/agents/qa.md` is clean.
- **Proves-nothing patterns:** none found. The lint tests work on a copied `method/` tree and check the exact breach line.

## Step 5: values
- The driver table rows match ADR-0054, ADR-0057 and the agentic-stories admission table.
- The next-forge `Dev: bun run dev` is backed by the plan and the research (a root `dev` script). The grounding test is in the green suite.

## Step 6: neighbours
- The `po-setup.md` QA stage text (from s78) agrees with "QA of a `screen` surface needs `Dev`".
- `reviewer.md` still speaks of "captures"; routing by surface belongs to s80.
- The `boilerplates/bricks` folder has no profile, and the lint passed.

Lenses run: none (no security, migration, dependency or server-side path or content in the diff).

## Findings

### 1. major: no stop when no driver row matches the surface and platform
Files: `method/agents/qa.md` (The walk, step 2) and `method/skills/qa-drivers/SKILL.md`.

The contract stops only when a driver file is *missing*. It says nothing for the case where *no table row matches*:
- a surface the project's `Platform` does not admit (for example `command` on `web`);
- `Platform` absent from `AGENTS.local.md`, which is likely in a project set up before s78, while `qa.md` now lists `Platform` under `Reads settings`;
- `Platform` set to `—`.

In those cases step 2 selects zero drivers. Under the `## The report` rule ("`complete` means every item in scope was reached or listed in `## Not seen`"), the subagent can then write `QA status: complete` with nothing exercised. That is a QA pass with no driver behind it, and it breaks the fail-closed intent of ADR-0057. `stories-review` flags a mismatched surface upstream, but only as major, so such a story can still reach `/po-qa`.

Fix: add a stop or `blocked` cause for "no row of the table matches surface X on platform Y, or `Platform` is missing", in both `qa.md` and `SKILL.md`.

### 2. minor: the "before the walk" baseline in step 7 is never recorded
File: `method/agents/qa.md`, The walk step 7.

Step 7 compares `git status --porcelain` with what was "there before the walk", but no step records that earlier listing. The Checks section only asserts that nothing is uncommitted outside `docs/`. The legitimately uncommitted research, plan and design files under `docs/` are left to the agent's memory. Fix: make step 1 also keep the porcelain listing.

### 3. minor: the lint test does not cover the `—` value
File: `tests/qa-drivers.test.sh`.

`profiles_declare_their_driver` covers `browsr`, `SKILL`, a missing section and a missing `Dev`, but never `- QA driver: —`, the value ADR-0057 explicitly admits for future native profiles. Removing the `!= "—"` branch of the lint would fail no test.

## Not verified
- **A real `/po-qa` run on this tree.** The record says no run was made. Whether a `qa` subagent is actually told the base directory of a preloaded skill, so it can find `browser.md`, is the plan's own pivot risk and is not proven by the text tests. To cover it, a person should install (`bin/polype-dev-install .` or the global pose) and run `/po-qa` on a web story with a screen, checking that `browser.md` is found and the report fills `Driver:` and `Evidence:`.
- **Non-screen drivers.** `scenarios.md`, `mobile-web.md`, `scene.md` and `simulation.md` do not exist yet (s81, s82, s87, s88). Every non-screen QA ends blocked until they land. This is by design, but no behaviour of those paths was observed.
- **The `mktemp -d` cleanup and the step 7 blocked path.** Both are prose a model follows and were never exercised.
- **The full suite and the lint.** I did not rerun them; I relied on the current record (`po-gate verif-current` passed). I ran only the two focused bite runs above.
- **The next-forge `bun run dev` port 3000 claim.** I did not run it. It rests on the research and the profile grounding test.

## Verdict
No critical finding. The story does what its plan says: all tasks are present, the two rules I disabled each fail a test, nothing outside `Owns` was touched, and the record is current. One major gap is left for a later cycle: no stop when no driver row matches.

Max severity: major
Ship allowed: yes
