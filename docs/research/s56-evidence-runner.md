# Research — s56-evidence-runner

## Structuring facts
- No false assumption found. One silent gap: the story's literal rule for `verif-current` ("a row on the same code" **or** "last row non-zero") accepts a check whose run on the final code failed and whose later passing run was on other code; the plan narrows it (see Open questions, Q1).
- Today the record is pure prose written by the implementer: `method/agents/implementer.md:42` asks it to "list each command you ran with its exit code", and `verif_current` (`method/hooks/po-gate.sh:52-63`) only reads `Verification status:` and `Tree:` — no table is parsed anywhere.
- `bin/polype` needs no change: it ships the whole `method/hooks/` directory (`bin/polype:98`, `bin/polype:100`) and makes every `*/hooks/*` file executable (`bin/polype:142-157`). A new `method/hooks/po-run.sh` lands as `.polype/hooks/po-run.sh` in both poses.
- `tests/structure.test.sh:73-84` fails unless the "Installed files" section of `method/AGENTS.md` names **every** file of `method/hooks/` — adding `po-run.sh` without the rules text turns the suite red.
- Order problem the story leaves open: `po-run` appends to `docs/verif/<id>.md`, but today the implementer writes that file last from the template (`implementer.md:42`) and the evals write it with `cat >` (`evals/lib.sh:222`). Either writer would erase the rows.

## Story
A runner `po-run --story <id> --label <check> -- <command>` runs a check, passes its output and exit code through, and appends one row (label, command, exit code, code tree, UTC time) to `docs/verif/<id>.md`; `po-gate verif-current` then requires, for every check the record declares with a command, a passing `po-run` row on the code of `Tree:` outside `docs/`. Criteria: `po_run_passes_the_exit_code_through`, `po_run_appends_a_row`, `verif_current_requires_a_passing_run_per_check`, `implementer_runs_checks_through_po_run`, `po_run_refuses_outside_a_story_worktree`, `eval_recipes_follow_the_new_record`. Notes: compare code outside `docs/`, never hash equality; never write command output into the record; record stays in git; "Installed files" cites `po-run`.

## Current code
- `method/hooks/po-gate.sh:52-63` `verif_current <id>`: file exists, a `Verification status: complete` line, first 40-hex `Tree:` (`first_hash`, `:32`), `tree_exists` (`:34`), `code_matches` = `git -C top diff --quiet <tree> HEAD -- . ':(exclude)docs'` (`:37`). Header comment lists subcommands (`:4-13`); dispatcher at `:335-343`. Script runs `set -euo pipefail` (`:17`), refusals via `refuse` → stderr + return 1 (`:20`).
- `method/templates/verification-record.md:1-21`: intro, `Tree:` line (`:7`), one 4-column table Check | Command | Outcome | Time (`:9-14`), "Not proven here", ends on `Verification status: <complete | incomplete>` (`:21`).
- `method/agents/implementer.md:32-46`: loop runs task tests (`:34`); after the last task: full suite (`:40`), type check (`:41`), record with `git add -A` + `git write-tree` (`:42`), commit (`:43-46`). Frontmatter wires `po-bounds.sh implementer` on `Edit|Write|Bash` (`:8-13`).
- `method/skills/testing-doctrine/SKILL.md:49-62` "When does each check run?" table: task tests, full suite (`Full suite`), type check, e2e, build, formatting.
- `method/AGENTS.md:62` Law 3 row "Record current"; `:119-125` "Installed files" names `po-gate` and `po-bounds` only.
- `evals/lib.sh:207-241` `eval_record`: `git add -A`, `write-tree`, runs `Test` with `bash -c`, parses unittest counts from the captured output, writes the whole record with `cat >`, commits it. Called once per built case (`evals/lib.sh:172`).
- Real records in `docs/verif/` carry extra free rows (e.g. `docs/verif/s58-designer-browser.md`: a "Lint" row with a command and "not run separately"). Under the new rule such a row would be a declared check needing a run.

## Attachment points
- New file `method/hooks/po-run.sh` (executable, `#!/usr/bin/env bash`, same style as `po-gate.sh`: header usage comment, `set -euo pipefail`, one-line refusal messages prefixed `po-run:`).
- `verif_current` in `po-gate.sh:52-63`: add the per-check run check after `code_matches`; update header line `:7`.
- Template `method/templates/verification-record.md`: table structure the gate parses.
- `implementer.md:42` (record step) and `:40-41` (suite, type check); doctrine table `SKILL.md:55-57`.
- `method/AGENTS.md:62` and `:123`.
- `evals/lib.sh:207-241`.
- Tests: new `tests/run-ledger.test.sh`; `tests/gate.test.sh:82-86` helper `record()`; `tests/execute.test.sh:53-58`.

## Verified interfaces
- `tests/lib.sh`: `scratch_repo` (`:46-53`, repo on `main`, sets `$SCRATCH`, cleans on EXIT), `contains` (`:43`), `fail` (`:11`), `$METHOD`/`$ROOT` (`:5-6`); `GIT_CONFIG_GLOBAL=/dev/null` exported (`:9`). Runner `tests/run.sh` runs each `test_*` in its own `bash -c "set -eu; …"`.
- `tests/gate.test.sh:4` `GATE="$METHOD/hooks/po-gate.sh"`; `sandbox()` (`:6-12`) commits on `main`; `record()` (`:82-86`) writes only `Tree:` and status — every `verif_current_*` test (`:88-123`) uses it.
- `tests/execute.test.sh:37-41` requires the implementer to say `**one commit**`, `No commit at this point.`, `git write-tree`; `:53-58` requires a `Tree: ` line and the template's last non-blank line to be exactly `Verification status: <complete | incomplete>`.
- `tests/evals.test.sh:71-88` builds the four defect cases with `bin/po-eval --build` and asserts `po-gate.sh verif-current` passes in each built worktree (`:77`) — this is the behavioural proof for the evals criterion. Each built repo gets `.polype/hooks/` from this checkout via `bin/polype install` (`evals/lib.sh:149`), and its worktree is on `story/<id>` (`evals/lib.sh:164`).
- `tests/plan.test.sh:32-45` freezes doctrine headings and two phrases; no test freezes the doctrine table rows.
- git 2.56 here; `--path-format=absolute` is already relied on by `po-bounds.sh:28`.

## Traps
- **The installed copy is not this story's code.** This worktree's `.claude/` and `.polype/` are the old method: the s56 implementer and reviewer will run the old implementer and old `po-gate`, so s56's own record is in the old format. Running `bin/polype-dev-install` here would rewrite installed files (forbidden by AGENTS.local conventions).
- **Lanes in flight at ship time** (records in the old format) will fail the new `verif-current` and be sent back to the code stage by `/po-drive` (`method/commands/po-drive.md:50,62`). Intended, but worth saying in the ship message.
- **`method/skills/review-antihallu/SKILL.md:24`** says that without the hook `git diff --quiet <Tree> HEAD …` "does the same comparison" — no longer true after this story. Not in `Owns`; leave it, report it.
- `po-bounds.sh implementer` parses Bash command strings for `git` verbs (`po-bounds.sh:115-150`); `po-run.sh` calls git inside the script, invisible to it — no refusal expected.
- `tests/evals.test.sh` builds 4 repos: slow-ish but already in the suite.
- Overlap rule (ADR-0006): new method prose in own words.
- No migration, no dependency, no screen.

## Open questions
- Q1. Which rows count for a declared check? Literal story text has the hole above. Proposal: among the rows of that check (same label **and** same command) whose tree matches `Tree:` outside `docs/`, there is at least one and the **last** of them exits 0.
- Q2. Match runs to declared checks by label only, or label + command? Label only lets a focused run (`bash tests/run.sh plan.test.sh`) stand in for the full suite. Proposal: both.
- Q3. How to pass a setting verbatim when it contains quotes? Proposal: a single argument after `--` runs through `bash -c` and is recorded as given; several arguments run as argv and are recorded joined by spaces.
- Q4. Who creates the record file? Proposal: the implementer writes it from the template **before** the final runs and only edits its own lines afterwards; `po-run` creates it (with just the runs section) if missing. A rewrite that drops rows makes the gate refuse — self-revealing.
- Q5. `git add -A` on the real index (story wording) or on a temporary copy? Proposal: a temporary copy of the index, same tree, no side effect on what the developer staged.
- Q6. Rows are still in a file the agent can write: a forged row is possible. Out of reach without signing; the reviewer can spot it. Stated in the ADR.

## Complexity
Story 3 → 3. One new ~80-line script, one gate function extended with an awk parse, a template reshaped, two text files, the eval builder, three test files. The risk is the parse and the ordering, not the size.

## Split
Not needed.
