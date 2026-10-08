---
validated: yes
---
# Plan — s56-evidence-runner

Branch `story/s56-evidence-runner`. Read `docs/research/s56-evidence-runner.md` first; this plan builds on it without repeating it. Decision: `docs/decisions/ADR-0035-le-releve-tient-un-registre-ecrit-par-po-run.md` (settles research Q1–Q5).

## Story
Every check of the record goes through `po-run`, which writes its own row; `po-gate verif-current` accepts a record only when each declared check has a passing run on the recorded code. Criteria: `po_run_passes_the_exit_code_through`, `po_run_appends_a_row`, `verif_current_requires_a_passing_run_per_check`, `implementer_runs_checks_through_po_run`, `po_run_refuses_outside_a_story_worktree`, `eval_recipes_follow_the_new_record`.

## The record format (shared by tasks 1–6)
```
## Checks
| Check | Command | Note |
| --- | --- | --- |
| Unit suite | `bash tests/run.sh` | |
| Type check | — | no such command in this project |
…
## Runs
<one sentence: written by po-run, one row per launch, never edit, reorder or delete a row>

| Check | Command | Exit | Tree | Time (UTC) |
| --- | --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | 0 | <40-hex> | 2026-10-08T09:12:03Z |
```
- **Declared check**: a body row of the table under `## Checks` (up to the next `## `), header and `| --- |` separator excluded, whose command cell — trimmed, one surrounding pair of backticks removed — is not `—`. Cells: first = label, last = note, everything between (rejoined with `|`) = command.
- **Run row**: a body row under `## Runs` (to the next `## ` or end of file). Parsed from both ends: first = label, last = time, second-to-last = tree (40 lowercase hex), third-to-last = exit (integer), the middle rejoined = command (backticks stripped as above). A row not matching that shape is ignored.

## Tasks
1. [x] **`method/hooks/po-run.sh`** (new, mode 100755, style of `po-gate.sh`: usage header comment, `set -euo pipefail`, messages prefixed `po-run:` on stderr).
   - Usage `po-run --story <id> --label <check> -- <command…>`. Refusals happen **before** the command runs and exit **125** (the `env` convention for "the runner itself failed", so it cannot be mistaken for most command codes): missing `--story`/`--label`/`--`/command; id not matching `^s[0-9]+-[a-z0-9][a-z0-9-]*$`; label empty or holding `|`, a backtick or a newline; command holding a newline; not inside a git work tree; `git symbolic-ref --short -q HEAD` ≠ `story/<id>` (detached HEAD included).
   - Before running: `top=$(git rev-parse --show-toplevel)`; tree = `git add -A` then `git write-tree` with `GIT_INDEX_FILE` pointing at a `mktemp` copy of `$(git rev-parse --path-format=absolute --git-path index)` (copied when it exists), removed on exit; `mkdir -p "$top/docs/verif"`. A failure here → 125, nothing run.
   - Command: exactly one argument after `--` → `bash -c "$1"`, recorded as given; several → run as argv, recorded joined by single spaces. Run in the caller's directory, stdin/stdout/stderr untouched (no capture), exit code captured with `set +e` around it.
   - Append to `$top/docs/verif/<id>.md`: if the file lacks a `^## Runs$` line, first append (after a newline if the file does not end with one) `## Runs`, a blank line, the header and the separator; then `| <label> | \`<command>\` | <exit> | <tree> | <date -u +%Y-%m-%dT%H:%M:%SZ> |`. Never the command's output. Append failure → message and 125; otherwise exit with the command's code unchanged.
   - Fails if wrong: `test_po_run_passes_the_exit_code_through`, `test_po_run_appends_a_row`, `test_po_run_refuses_outside_a_story_worktree` (task 7).
2. [x] **`verif_current` in `method/hooks/po-gate.sh:52-63`**: after the existing `code_matches "$tree"` check, read the record once with awk (POSIX classes only, as the file's other awk) into declared `(label, command)` pairs and run rows; a record without a `^## Checks$` line → refuse ("…has no Checks table — rebuild it from templates/verification-record.md"). For each declared pair: keep the run rows with the same label **and** the same command whose tree satisfies `tree_exists` and `git -C "$(top)" diff --quiet <run tree> <Tree> -- . ':(exclude)docs'`; none → refuse naming the check and the exact `po-run --story <id> --label "<label>" -- "<command>"` to launch; the last of them with a non-zero exit → refuse naming the check and that exit. Update header line `:7` to say the declared checks must have a passing `po-run` row on the recorded code. No other subcommand changes.
   - Fails if wrong: `test_verif_current_requires_a_passing_run_per_check` (task 7); existing `verif_current_*` tests of `tests/gate.test.sh` after task 8.
3. [x] **`method/templates/verification-record.md`**: reshape to the format above — intro rewritten (the implementer writes this file before its final runs, then edits only `Tree:`, the `## Checks` table, "Not proven here" and the status; `po-run` writes `## Runs`; the gate compares each run's tree with `Tree:` outside `docs/`), `Tree:` line kept with its `git add -A` / `git write-tree` order, `## Checks` with Unit suite `<Test>`, Type check `<Typecheck>`, End to end and Build at `—`, the rule "a row with a command is a check you launch through `po-run`; a check not run at this stage, or absent from the project, gets `—` and says why in Note", then "Not proven here", `Verification status: <complete | incomplete>`, and `## Runs` last with its sentence, header and separator and no body row.
   - Fails if wrong: `test_verification_record_has_tree_and_unfilled_status` (task 8).
4. [x] **`method/agents/implementer.md` "After the last task"** (`:39-46`), rewritten in this order: (1) write `docs/verif/<id>.md` from the template, declaring each check with its command copied from `AGENTS.local.md`; after this only edit your own lines, never rewrite the file or touch a `## Runs` row; (2) full suite via `.polype/hooks/po-run.sh --story <id> --label "Unit suite" -- "<Test>"` — with `Full suite: ship` the row says `—`, deferred to ship; (3) type check the same way, after the final edit; a failing run is fixed and launched again, the new row is what counts; (4) `git add -A`, `git write-tree` → `Tree:`, fill "Not proven here", and set `Verification status: complete` only if every declared check's last run on this code exited 0 (not via `po-gate verif-current`, which also compares with a HEAD not committed yet); (5) commit as today (keep `**one commit**`, `git write-tree`, the `.env*` sentence). State that results are never copied by hand: `po-run` writes them. Task-test runs of the loop (`:34`) stay plain commands.
   - Fails if wrong: `test_implementer_runs_checks_through_po_run`; `tests/execute.test.sh:37-51` stays green.
5. [x] **`method/skills/testing-doctrine/SKILL.md:49-62`**: one sentence under the table: the full unit suite and the type check are launched through `po-run --story <id> --label <check> -- "<command>"`, which writes their row in the record; their result is never written by hand; task tests run without it. Headings and phrases frozen by `tests/plan.test.sh:32-45` unchanged.
   - Fails if wrong: `test_implementer_runs_checks_through_po_run`.
6. [x] **`method/AGENTS.md`**: Law 3 row "Record current" (`:62`) → also "every check its `## Checks` table declares has a passing `po-run` row on that same code"; "Installed files" (`:123`) gets one sentence: `.polype/hooks/po-run.sh`, called `po-run`, launches a check inside a story worktree, passes its output and exit code through and appends the check's row to `docs/verif/<id>.md`, never the output. Keep the two phrases `tests/structure.test.sh:81-83` freezes.
   - Fails if wrong: `test_rules_list_every_installed_hook` (fails as soon as task 1 exists without this).
7. [x] **`evals/lib.sh` `eval_record` (`:207-241`)**: same result, new order — run the suite through `bash .polype/hooks/po-run.sh --story "$id" --label "Unit suite" -- "$cmd"` from `$wt`, capturing its output for the counts as today; then compute `Tree:` (`git add -A`, `git write-tree`); then write the head of the record (title, `Tree:`, `## Checks` with Unit suite and `$cmd`, Type check/End to end/Build at `—`, "Not proven here", status) **in front of** the file `po-run` created (`{ head; cat record; } > tmp && mv`), so the run row survives; commit as today. Update the comment on `:206` (the record's rows now come from `po-run`). No case file changes.
   - Fails if wrong: `tests/evals.test.sh:77` (`verif-current` on each built repo) and `test_eval_recipes_follow_the_new_record`.
8. [x] **Tests.**
   - New `tests/run-ledger.test.sh` (`# s56 — …` header, helper `story_sandbox`: `scratch_repo`, a committed `src/app.txt`, `git checkout -qb story/s01-a`; `RUN="$METHOD/hooks/po-run.sh"`):
     - `test_po_run_passes_the_exit_code_through` — `-- bash -c 'echo visible; exit 7'` exits 7 and prints `visible`; single-argument form `-- 'exit 3'` exits 3; `-- true` exits 0.
     - `test_po_run_appends_a_row` — an existing record's head lines survive; two launches give two rows under `## Runs`, in order; the row's label, backticked command, exit, a tree equal to `git write-tree` of a fresh `git add -A` on the same files, a `…Z` UTC time; a string the command prints (`echo LEAK-1234`) is absent from the record; an untracked file is still untracked afterwards (`git status --porcelain` shows `??`).
     - `test_po_run_refuses_outside_a_story_worktree` — on `main`, and on `story/s02-b` with `--story s01-a`: exit 125, the command (`touch ran`) did not run, no record written; `--story ../x` refused the same way.
     - `test_verif_current_requires_a_passing_run_per_check` — record declaring `Unit suite` with a command, built through `po-run` then committed with `Tree:` = HEAD tree: no run → refused; failing then passing run on the same code → accepted; passing then failing → refused; a passing run with another command under the same label → refused; a passing run on earlier code only (code committed after it) → refused; a `—` row needs nothing; a record without `## Checks` → refused.
     - `test_implementer_runs_checks_through_po_run` — `contains` `po-run.sh --story` in `implementer.md` and `po-run --story` in the doctrine; `implementer.md` no longer holds `list each command you ran with its exit code`.
     - `test_eval_recipes_follow_the_new_record` — `bin/po-eval --build foreign-resource "$tmp"`: the committed record has a `## Runs` row labelled `Unit suite` whose command is the built repo's `Test:` and whose exit is 0, and `po-gate verif-current` passes there.
   - `tests/gate.test.sh:82-86` `record()`: add a `## Checks` table whose only row has command `—`, so the existing tree/status tests keep testing tree and status only (clause changed by this story).
   - `tests/execute.test.sh:53-58`: keep the `Tree: ` check; require a line exactly `Verification status: <complete | incomplete>`, the `## Checks` heading, and `## Runs` as the last heading followed by the header `| Check | Command | Exit | Tree | Time (UTC) |` (the template no longer ends on the status line — clause changed by this story).
9. [x] **Close**: this story's own record in the new format, built with the new script — `bash method/hooks/po-run.sh --story s56-evidence-runner --label "Unit suite" -- "bash tests/run.sh"` once, Type check `—` (`Typecheck: —`). The installed `.polype/hooks/po-gate.sh` the reviewer uses is still the old one; a new-format record passes it too.

## Run interdicts
- Empty diff on: `.claude/`, `.polype/`, `bin/polype`, `bin/po-eval`, `evals/cases/`, `tests/evals.test.sh`, `tests/structure.test.sh`, `tests/lib.sh`, `method/hooks/po-bounds.sh`, `method/hooks/pre-commit`, `method/skills/review-antihallu/`, `method/commands/`, `method/templates/review.md`, every existing `docs/verif/*.md` other than this story's, `docs/stories.md`, `docs/parite-killer-saas.md`.
- `po-gate.sh`: only `verif_current`, its header line and helpers it alone uses change; `ship_allowed`, `qa_current`, `pre_commit`, `floor_guard` and the pattern tables have an empty diff.
- Do not run `bin/polype-dev-install` or `bin/polype` on this repository: the installed copy is refreshed after ship, never by the story.
- `po-run` never writes command output anywhere; `grep -n 'tee\|>>.*out' method/hooks/po-run.sh` shows no capture of the command's streams.
- No new dependency: bash, git, awk, `date`, `mktemp`, `cp` only.

## The pivot
**A declared check counts only through rows with the same label and command whose tree matches `Tree:` outside `docs/`, and the last of those must exit 0.** Ways it could be wrong:
- Too strict on command equality: a setting with quotes or extra spaces fails to match if the implementer passes it as argv. Compare against task 1's single-argument rule and the implementer text; the refusal message prints the exact command to run.
- Too loose: rows are text the agent can write (ADR-0035, Bad). Compare the row's tree with `git cat-file -e` and its time with the commit time during review.
- The parse: a `|` inside a command, or a Note cell holding `|`, shifts cells. Runs are parsed from both ends; check the declared-table parse against a command like `pnpm test | cat`.

## Files touched
`method/hooks/po-run.sh` (new), `method/hooks/po-gate.sh`, `method/templates/verification-record.md`, `method/agents/implementer.md`, `method/skills/testing-doctrine/SKILL.md`, `method/AGENTS.md`, `evals/lib.sh`, `tests/run-ledger.test.sh` (new), `tests/gate.test.sh`, `tests/execute.test.sh`; docs: research, plan, ADR-0035, `docs/verif/s56-evidence-runner.md`.

## Test strategy
Six new tests in `tests/run-ledger.test.sh`, one per criterion, plus two existing tests adjusted (`gate.test.sh` helper, `execute.test.sh` template test) — well within `Test budget` (25). Layers: `po-run` and `verif-current` are exercised as their callers use them, on throwaway repositories (behaviour); the implementer/doctrine criterion is a text clause, checked by exact phrases as the repository's convention requires; the evals criterion builds one real case and also rides on `tests/evals.test.sh:77`, unchanged. Neutralization check for the reviewer: drop the command-equality condition → the "another command" assertion fails; drop the last-exit check → "passing then failing" fails; drop the tree filter → "earlier code only" fails. No visual check: no screen.

## Done when
All criteria's tests and the full suite green; `po-gate verif-current` behaviour proven on throwaway repos; ADR-0035 committed with the story; one story commit; a review with no open critical.
