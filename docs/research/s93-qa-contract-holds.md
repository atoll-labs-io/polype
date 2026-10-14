# Research — s93-qa-contract-holds

[Story](../stories.md)

## Structuring facts
- **Root cause 1 (s79 major 1):** walk step 2 of `method/agents/qa.md:43` has one blocking branch only, "A driver file is missing". When no row of the table (`method/skills/qa-drivers/SKILL.md:10-17`) matches the surface and `Platform`, or `Platform` is missing or `—`, zero drivers are picked. Nothing stops the walk, and the report rule `qa.md:51` ("`complete` means every item in scope was reached or listed in `## Not seen`") then allows `complete` with nothing exercised. `SKILL.md:24` blocks only on a missing *file*. `method/commands/po-qa.md:21-28` has no platform precondition either.
- **Root cause 2 (s81 major 1):** `method/skills/qa-drivers/scenarios.md:12` blocks on "a path the first output did not list" with no exception. The transcripts the same driver writes to `docs/qa/<id>/` (`scenarios.md:30`) are such new paths, so every literal `command`/`endpoint` QA ends `blocked`. `qa.md:48` has the exception (`outside docs/qa/<id>/`); the driver dropped it.
- **Root cause 3 (s81 major 2):** `scenarios.md:21` says "write a short script under the temporary directory" without saying "through Bash". `po-bounds` mode `qa` refuses Write outside `docs/qa/<id>/`, the temp dir included (`method/hooks/po-bounds.sh:271-278`). `qa.md:56` makes a refusal a stop and forbids "another route", so an agent that tries Write first is stuck.
- **Root cause 4 (s81 major 3):** `tests/scenario-driver.test.sh:38-46` pins `status --porcelain --ignored` and `runs on a copy`. Both phrases survive deleting the blocking consequence, the scratch-folder sentence and the "success code on bad input" clause. All three deletions were reproduced (see Diagnostic).
- The story's assumptions hold. Every owned file exists and says what the reviews quote. No assumption is false.

## Diagnostic
**Reproduction.** I worked on a copy of `method/`, `tests/`, `bin/`, `boilerplates/` in a `mktemp -d` directory and created nothing in the worktree.
- Baseline `bash tests/run.sh scenario-driver.test.sh qa-drivers.test.sh qa.test.sh` → `15 passed, 0 failed`.
- Deleted only the sentence "After the walk, run it again: a path the first output did not list → `QA status: blocked`, naming that path, and nothing is removed." → `9 passed, 0 failed` (scenario-driver + qa-drivers).
- Deleted the sentence "Each scenario then works from a scratch folder under the same directory, …" → `4 passed, 0 failed`.
- Deleted ` a success code on bad input,` → `4 passed, 0 failed`.
- `grep -c 'docs/qa' scenarios.md` → 1, only at `:30`, the evidence line. There is no exception at `:12`.
- `grep -n '^Reads settings' qa.md` → `:18` lists `Target branch`, `Platform`, `Dev` only. `scenarios.md:10` reads `Install` and `Build`.
- `grep -n 'no row\|matches' qa.md SKILL.md` → only `SKILL.md:21`, which covers several values matching. Nothing covers zero matches.

**Hypotheses.**
| # | Hypothesis | Refuting observation | Result |
| --- | --- | --- | --- |
| H1 | The zero-row case is blocked somewhere else (po-qa precondition, SKILL, qa Checks) | a line in `po-qa.md:21-28`, `SKILL.md`, `qa.md:24-32` that ends a walk with no driver | none found → **kept** as cause 1 |
| H2 | Deleting the whole before/after paragraph goes unseen | some test fails when `scenarios.md:12` is removed whole | `scenarios_leave_the_tree_clean` fails (it pins `status --porcelain --ignored`) → **discarded**: only the consequence sentence is unguarded |
| H3 | Transcripts escape the comparison because `docs/qa/` is ignored by git | `.gitignore` ignores `docs/qa/` | `.gitignore` ignores only `node_modules/`, `.env*`, worktree dirs. And `--ignored` would list `!!` paths anyway → **discarded**: the transcripts do show up as new paths |
| H4 | The scratch-script stop comes from the driver's wording, not from po-bounds | `check_write_qa` accepts temp-dir paths | `po-bounds.sh:276-277` allows only `docs/qa/$STORY/` → **kept** as cause 3 |

## Story
`qa` and the scenarios driver must never conclude without proof, and must not block on their own proof.
- `no_driver_row_blocks`: no matching row, or `Platform` missing or `—` → `QA status: blocked` with the cause, never `complete`.
- `own_evidence_never_blocks`: the before/after comparison of `scenarios.md` sets `docs/qa/<id>/` aside. A scratch script is created through Bash under the temp dir, and the driver says so. A service that does not answer within a stated delay → `blocked`.
- `qa_declares_what_it_reads`: `Reads settings:` of `qa` lists `Install` and `Build`. `qa` keeps the `git status` from before the walk, and cites the story's plan among its sources.
- `scenario_rules_bite`: the blocking on a new path, the scratch folder and the success code on bad input each have a test that fails when the rule disappears.

## Current code
- `method/agents/qa.md` (60 lines):
  - frontmatter `:1-15`: hook `po-bounds.sh qa`, `disallowedTools: Edit`;
  - `Reads settings` `:18`;
  - Checks `:24-32`: `:29` runs `status --porcelain` but keeps nothing;
  - Scope `:34-39`: "Two sources", the diff plus `docs/designs/<id>/`, and the criteria;
  - Walk `:41-48`: step 2 picks the driver at `:43`, step 7 compares "with what was there before the walk" at `:48`;
  - Report `:50-51`; Limits `:53-57`.
- `method/skills/qa-drivers/SKILL.md` (37 lines):
  - table `:10-17`;
  - surface and platform `:19`, several values `:21`;
  - missing file → blocked `:24`;
  - temp dir created "through Bash with `mktemp -d`" `:34`, which does not say its files are written through Bash.
- `method/skills/qa-drivers/scenarios.md` (41 lines):
  - copy, Install, Build `:10`;
  - before/after `:12`;
  - API start `:14`, which has no bound on the wait. "It answers on another port" there is undetectable unless the program prints it;
  - stop `:16`; lib script `:21`; invalid input `:23`; evidence `:30`.
- `method/commands/po-qa.md` is outside `Owns`. Preconditions `:21-28`, delegation `:31-33`.

## Attachment points
- `qa.md:18` (settings), `:29` or walk step 1 `:42` (the baseline), `:35-37` (sources), `:43` (zero-row branch), `:48` (compare with the kept baseline), `:51` (when `complete` is allowed).
- `SKILL.md`, after `:21` (zero-row rule), and `:34` (files of the temp dir written through Bash).
- `scenarios.md:12` (the exception), `:14` (wait bound), `:21` (Bash heredoc), plus a residual-limit sentence near `:12` for s81 minor 4.
- New `tests/qa-contract-holds.test.sh`, one `test_<criterion>` per acceptance criterion (convention, `AGENTS.local.md`).

## Verified interfaces
- `tests/lib.sh`: `contains file phrase` (`:43`, exact, `grep -F`), `require_file` (`:41`), `settings_read_by` (`:37`), `template_settings` (`:32`), `fail` (`:11`).
- `tests/run.sh:17` runs each `test_*` in `bash -c "set -eu; source ./lib.sh; source ./<file>; <name>"`. It accepts file names relative to `tests/`.
- `Install` and `Build` are settings of `method/templates/agents-local.md:75,79`, so `po-lint`'s settings check (`bin/po-lint:87-104`) accepts them.
- `po-bounds` mode `qa`: Write only inside `docs/qa/$STORY/` (`po-bounds.sh:271-278`). The git read verbs are at `:310`. Bash is otherwise free, so `mktemp -d`, a heredoc and `rm` are allowed.
- ADR-0057 (accepted) makes a missing driver file `blocked` and a dirty tree `blocked` with nothing removed (`docs/decisions/ADR-0057-…md:25,31`). ADR-0059 (accepted) has the scenarios run on a copy in the temp dir.
- `method/skills/qa-drivers/scene.md:6` reads `## Scene viewpoints` from `docs/plans/<id>.md`. This is why `qa` must name the plan among its sources.

## Traps
- **Pinned phrases to keep, word for word:**
  - `tests/qa-drivers.test.sh:34` pins the whole sentence "A driver file is missing → write the report with `QA status: blocked`, naming the missing file as its cause." The new branch must be added next to it, never merged into it.
  - `qa-drivers.test.sh:50-53` pins `observe through the surface`, `status --porcelain` again and `mktemp -d` in qa.md and SKILL.md.
  - `tests/qa.test.sh:38-41,51-52` pins `git diff <Target branch>...story/<id>`, `each acceptance criterion`, `Nothing else is walked.`, and the screen-scoped browser stop.
  - `qa-drivers.test.sh:41-48` requires every `→` line that mentions `Dev` or "open a page" to be scoped to `surface is \`screen\``. The new lines must not mention `Dev`.
  - `tests/scenario-driver.test.sh` pins `on which nothing answers before the start`, `and only that one`, `status --porcelain --ignored`, `cannot build one`, `ADR-0059`, `the request with \`curl\``, `calling the public interface`.
  - `tests/bounds.test.sh:175-178` reads qa.md's frontmatter. Leave the frontmatter untouched.
- `tests/overlap.test.sh` fails on 8+ consecutive words shared with Killer SaaS. Write new prose in your own words.
- **Parallel lanes:**
  - s94 owns `scene.md`, `simulation.md` and the plan templates. It needs the same `docs/qa/<id>/` exception in its own drivers. Do not touch its files.
  - s95 owns `bin/po-lint`, `tests/run.sh`, `tests/lib.sh`, and the `—` lint case of s79 minor 3 (story note of s95). Leave those to it.
  - s96 owns the commands, so `po-qa.md` stays out of reach.
- No migration, no dependency, no screen.
- `docs/parite-killer-saas.md` has no line for s79/s81, so there is nothing to update.

## Open questions
- **Wait bound for an API start.** The story says "within the given delay" and names no value. The plan sets a fixed bound and the driver states it.
- **s81 minor 4** (`--ignored` folds an already-ignored directory into one line). No criterion covers it. The plan decides whether one honest sentence naming the limit is enough, with the copy of ADR-0059 as the real guard.
- **s81 minor 1, second half** ("how the agent detects 'answers on another port'"). The plan decides whether to rephrase it as something the agent can observe: the program prints a different port.

## Complexity
Story 3 → 3. Three prose files and one new test file, four tests. It stays at 3 rather than 2 because three of the clauses must read the same way in `qa.md` and `SKILL.md`, and existing pinned phrases constrain the wording.

## Split
Not needed.
