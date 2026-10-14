---
track: flow
validated: yes
---
# Plan (short track) — s67-record-text

[Story](../stories.md)

Written by the planner on the short track (`Story track: auto`, complexity 1 ≤ `Flow threshold` 2). This one file stands in for both the research and the plan: there is no `docs/research/s67-record-text.md`. Validated autonomously (`Plan validation: autonomous`): no human reviewed it.

## Verified facts
**Story assumption corrected first.** The story's `Owns` leaves out `docs/decisions/`, but dropping `--ignored` reverses a clause of the accepted ADR-0037 ("y compris les fichiers ignorés", `docs/decisions/ADR-0037-qa-current-exige-une-preuve-qa-committee.md`, Decision Outcome). An accepted ADR is never edited, so the planner wrote `docs/decisions/ADR-0044-qa-current-ne-compte-plus-les-fichiers-ignores.md` (reserved number), `supersedes: [ADR-0037]`. Same `Owns` gap as s60's m1; the implementer commits that file with the story and does not change it.

Fix-run record (s56 m3):
- `method/agents/implementer.md:41` says "Write `docs/verif/<id>.md` from `templates/verification-record.md`" then "never rewrite the file, never touch a row under `## Runs`": silent about a record that already exists on a fix run.
- `method/agents/implementer.md:29-30` (`## Fix runs`) and `:47` (fix-run commit) say nothing about the record either.
- `method/templates/verification-record.md:3` lists what the implementer edits: `Tree:`, `## Checks`, "Not proven here", the status line; `:25` says no one edits `## Runs` rows. Outside `Owns`, unchanged.
- The gate counts only runs whose tree matches `Tree:` outside `docs/`, last one deciding (`method/hooks/po-gate.sh:113-124`), so keeping earlier rows never makes a fix run pass wrongly.

Quoting (s56 m4):
- `method/agents/implementer.md:42`: `.polype/hooks/po-run.sh --story <id> --label "Unit suite" -- "<Test>"`, "passed as one quoted argument". Step 3 (`:43`) says "the same way".
- `method/hooks/po-gate.sh:122`: refusal hint `po-run --story $id --label \"$label\" -- \"$command\"`, `$command` coming from the `## Checks` row with its backticks removed (`:76`, `:91`).
- `method/hooks/po-run.sh:33` records a single argument exactly as received; `po-gate.sh:117` compares it character for character with the declared command. Double quotes let the caller's shell expand `$`, `` ` ``, `"`, so the recorded command differs and the gate refuses.
- Checked in bash: with `q="'\\''"`, `"'${command//\'/$q}'"` gives `'echo '\''a'\'' "$X"'`, and `eval "set -- $s"` returns the original command exactly. (`\'\\\'\'` straight in the replacement does not: it keeps the backslashes.)
- `method/skills/testing-doctrine/SKILL.md:62` also writes `-- "<command>"`. Outside `Owns`: left as is, reported.

QA gate (s60 M1, m3):
- `method/hooks/po-gate.sh:141-144`: `git cat-file -e HEAD:docs/qa/$1/report.md` and then `git status --porcelain --untracked-files=all --ignored -- docs/qa/$1/` must be empty, otherwise the refusal "is current but docs/qa/$1/ is not committed — commit it alone: …".
- `/po-qa` commits with `git add -- docs/qa/<id>/` + `git commit … -- docs/qa/<id>/` (`method/commands/po-qa.md:42-43`), which never stages ignored files.
- Checked in a scratch repo, `.gitignore` holding `*.png` and `report.md`, both files untracked: `git status --porcelain --untracked-files=all` (no `--ignored`) prints nothing, `git cat-file -e HEAD:…/report.md` exits 128, and `git check-ignore -q …/report.md` exits 0. Once `--ignored` is gone, `cat-file` is the only clause that refuses an ignored report (m3).
- `tests/qa-gate.test.sh:63-75` (`test_qa_current_requires_a_committed_report`) uses only untracked or staged files, which the status clause alone already refuses. That is why removing `cat-file` left 0 failures (s60 review, mutation table).
- Phrases other tests rely on: `tests/qa-fleet.test.sh:185` needs `is current but docs/qa/$1/ is not committed` in `po-gate.sh`; `tests/qa-gate.test.sh:68` needs `not committed`; `tests/ownership.test.sh:107` checks the review skill (untouched).
- Implementer phrases tested elsewhere that must survive: `tests/execute.test.sh:37-49` (`**one commit**`, `git write-tree`, …), `tests/run-ledger.test.sh:142` (`po-run.sh --story`), `tests/design-handoff.test.sh:12-18`, `tests/qa-gate.test.sh:110-111`, `tests/bounds.test.sh:63`.

## Escalation signals
| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, no data | absent — bash + markdown only (`po-gate.sh`, `implementer.md`) |
| New screen | absent — story text | absent — no UI in Polype |
| Authorization or tenant scope | absent — story text | absent — `qa_current` only reads git status (`po-gate.sh:129-145`) |
| API contract | absent — story text | absent — refusal texts change wording only; the phrase consumers grep stays (`qa-fleet.test.sh:185`) |
| New dependency | absent — story text | absent — only `git check-ignore`, part of git already in use |

## Story
s67-record-text: the implementer knows what to do with a record that already exists, and the `po-run` command it runs and the one the gate suggests can be copied verbatim. Criteria: `fix_run_keeps_the_runs`, `suggested_command_is_single_quoted`, `qa_current_ignores_ignored_files`.

## Tasks
1. [x] **Fix-run record** — `method/agents/implementer.md`, step 1 of "After the last task" (`:41`): first run, write the record from the template; fix run, the record already exists: keep it, with every row under `## Runs`, and never start it again from the template. In both cases update only `Tree:` and your own lines (`## Checks`, "Not proven here", status line). Keep `never touch a row under \`## Runs\``. Test `test_fix_run_keeps_the_runs` (run-ledger) quotes the fix-run sentence and fails if it is removed.
2. [x] **Single quotes in the implementer** — `implementer.md:42`: `-- '<Test>'`, the command between single quotes exactly as written in the settings so the shell expands nothing, a single quote inside written `'\''`. Step 3 still says "the same way". Keep the substring `po-run.sh --story`. Test: first half of `test_suggested_command_is_single_quoted`. It requires `-- '<Test>'` and refuses `-- "<Test>"`.
3. [x] **Single quotes in the gate** — `po-gate.sh:122`: the hint becomes `po-run --story $id --label '<label>' -- '<command>'`, each value with every `'` replaced by `'\''` through a variable (`q="'\\''"; ${command//\'/$q}`, form checked above). Second half of `test_suggested_command_is_single_quoted` (run-ledger, real gate). Build a record whose declared command holds `'`, `$` and `"`, for example `test "$(echo 'a b')" = 'a b'`, with no run. Take the text after `po-run` in the refusal and run it as `eval "bash \"\$RUN\" $rest"`, then seal. The gate must accept. With double quotes or no escaping, the recorded command differs and the test fails.
4. [x] **qa-current ignores ignored files** — `po-gate.sh:142`: drop `--ignored`. Keep the `cat-file` clause and the refusal text `is current but docs/qa/$1/ is not committed — commit it alone: …` word for word. When `git check-ignore -q -- docs/qa/$1/report.md` matches, add to that refusal that the report is ignored by git and must be un-ignored first. Update the header comment (`:9-10`) to say ignored files do not count (ADR-0044). Test `test_qa_current_ignores_ignored_files` (qa-gate, task 5).
5. [x] **Tests that bite** — in `tests/qa-gate.test.sh`, add `test_qa_current_ignores_ignored_files`, in two parts:
   - (a) `.gitignore` with `*.log`, committed current report, an untracked `docs/qa/s01-a/walk.log` → the gate accepts. This fails while `--ignored` stays.
   - (b) `.gitignore` adding `docs/qa/s01-a/report.md`, current report on disk but never committed → the gate refuses, and stderr holds both `is ignored by git` and `not committed`. With `--ignored` gone, only the kept `cat-file` clause catches this, so removing it turns the test red (the second half of the criterion).
   - Keep `test_qa_current_requires_a_committed_report` unchanged. It still bites the status clause (untracked capture, line 73-74).
6. [x] **Run** — `bash tests/run.sh run-ledger.test.sh qa-gate.test.sh qa-fleet.test.sh execute.test.sh design-handoff.test.sh bounds.test.sh`, then the full suite once through `po-run` (`Test: bash tests/run.sh`), with the new single-quoted form.

## Run interdicts
- Empty diff on `method/skills/testing-doctrine/SKILL.md`, `method/templates/verification-record.md`, `method/hooks/po-run.sh`, `method/commands/po-qa.md`, `method/commands/po-drive.md`, `method/skills/review-antihallu/SKILL.md`, and everything under `.claude/` and `.polype/` (installed copies).
- `docs/decisions/ADR-0037-*.md` and `docs/decisions/ADR-0044-*.md` unchanged by the implementer. ADR-0044 is committed as the planner wrote it.
- `po-gate.sh` keeps the exact phrase `is current but docs/qa/$1/ is not committed` and the `git cat-file -e "HEAD:docs/qa/$1/report.md"` clause.
- No change to `qa_current` other than dropping `--ignored` and the ignored-report clause; no change to `runs_cover_checks` other than the hint at `:122`.
- Existing tests unchanged, apart from the new functions.

## Files touched
`method/agents/implementer.md`, `method/hooks/po-gate.sh`, `tests/run-ledger.test.sh`, `tests/qa-gate.test.sh`; plus, written by the planner: this plan and `docs/decisions/ADR-0044-qa-current-ne-compte-plus-les-fichiers-ignores.md`.

## Test strategy
Three new test functions, one per criterion and named after it, well within `Test budget` 25:
- `test_fix_run_keeps_the_runs`: text clause of `implementer.md`.
- `test_suggested_command_is_single_quoted`: the implementer text plus a gate run. Copying the hint and running it must give a record the gate accepts, the only check that proves "se copie telle quelle".
- `test_qa_current_ignores_ignored_files`: a gate run whose parts (a) and (b) each fail when their own clause is neutralised. Part (a) fails with `--ignored`; part (b) fails without `cat-file`.

No test of the refusal message's wording beyond the phrases already pinned.

## The pivot
Dropping `--ignored` (ADR-0044) means a capture the project ignores can pass the gate and still be missing from the squash. That is right only if the report is the evidence that matters. If reviewers depend on the captures, a quietly missing capture is worse than a loop. That would call for a distinct refusal that names ignored captures, the option ADR-0044 turned down.

## Done when
The three criteria hold, `bash tests/run.sh` is green through `po-run`, the record is complete, and there is one commit carrying the plan, the ADR, the record and the code.
