---
validated: yes
---
# Plan — s150-oracle-intact-gate

[Story](../stories.md) · [Research](../research/s150-oracle-intact-gate.md)

Branch `story/s150-oracle-intact-gate`. Read `docs/research/s150-oracle-intact-gate.md` first; this plan builds on it without repeating it.

## Story
`po-gate oracle-intact <id>` compares, on `story/<id>`, each oracle file the plan lists with its recorded `cksum`; `review-antihallu` runs it first in step 4, grades its exits, and *Bite* starts with the rules the oracle holds. Criteria: `gate_compares_oracle_sums`, `gate_without_oracle_says_so`, `review_runs_the_oracle_gate`, `bite_starts_with_the_oracle` (text in `docs/stories.md`, story s150).

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `oracle_unreadable` (exit-2 helper) | new code, one line on the pattern of `unverifiable` (`method/hooks/po-gate.sh:372`) and `shape_unreadable` (`:89`) | both exist but print "cannot verify the floor of" / "cannot check the findings of", which `tests/floor-guard.test.sh:43` and the review read; reusing one would print a wrong message |
| Sum of a file on the branch | platform: `git cat-file blob story/<id>:<path> \| cksum`, the same `cksum` as `bin/polype:144` | — (lowest rung below "already in this repo" that holds; no helper reads a blob's sum) |
| Table reader `table_rows <section> <first header cell>` for the plan's oracle table and the record's `## Oracle changes` | new code, one small awk | `record_rows` (`:144`) reads only `## Checks` and `## Runs`, with run-row logic (`:166-171`); widening it would touch `verif-current`'s parser for no gain |
| `oracle_intact` | new code on the model of `floor_guard` (`:375`): branch resolved like `:381`, flags on stdout, count on stderr like `:510-514` | no existing check compares sums |

No option, setting or abstraction beyond these.

## Acceptance tests
Written by the planner before any code. The gate tests run from `main` in a throwaway repository, so only what `story/<id>` holds can answer; they go through `po-gate oracle-intact <id>` and its exit code, stdout and stderr, as fixed by task 1 and task 2.

| Oracle file | cksum |
| --- | --- |
| `tests/oracle-intact-gate.oracle.test.sh` | `1293718647 7539` |

| Criterion | Test |
| --- | --- |
| `gate_compares_oracle_sums` | `test_gate_compares_oracle_sums` |
| `gate_without_oracle_says_so` | `test_gate_without_oracle_says_so` |
| `review_runs_the_oracle_gate` | `test_review_runs_the_oracle_gate` |
| `bite_starts_with_the_oracle` | `test_bite_starts_with_the_oracle` |

## Tasks
1. [x] **`po-gate oracle-intact`: inputs, exit 2 and the no-oracle case** — in `method/hooks/po-gate.sh`, after `floor_guard` and before the `case` (`:517`), add a `# --- oracle intact ---` section:
   - `oracle_unreadable() { echo "po-gate: cannot check the oracle of ${1:-<id>}: $2" >&2; exit 2; }`.
   - `table_rows <file> <section heading> <first header cell>`: one awk printing, for the first table inside `## <section>` (up to the next `## `) whose header row's first cell (trimmed) equals the given text, each data row as cells trimmed, enclosing backticks removed, joined by `\037`; the separator row skipped; the table ends at the first line not starting with `|`. Other tables of the section (the plan's `| Criterion | Test |`) are never read.
   - `oracle_intact()`: no id → `oracle_unreadable "" "usage: po-gate oracle-intact <id>"`; `story/<id>^{commit}` not resolving (`git rev-parse --verify --quiet`, as `:381`) → exit 2; `docs/plans/<id>.md` read **from `story/<id>`** (`git cat-file blob story/<id>:docs/plans/<id>.md` into a temp file or a variable), absent → exit 2. No `## Acceptance tests` line in the plan → stdout `po-gate: <id> has no oracle: its plan has no ## Acceptance tests section`, exit 0. The section holding no row of the `Oracle file` table and a line that starts with `—` → stdout `po-gate: <id> has no oracle: its plan writes — under ## Acceptance tests`, exit 0. The section holding neither → exit 2 ("names no oracle file and writes no —"). A row whose path cell is empty or whose sum cell is not `<digits> <digits>` → exit 2, naming the row. Every failing git read goes through `oracle_unreadable`, never through `set -e`.
   - Dispatch line `oracle-intact)  oracle_intact "${2:-}" ;;` in the `case`.
   - Usage entry in the header, after the `floor-guard` one (`:20-21`), saying: compares each oracle file that `## Acceptance tests` of the plan names, on story/<id>, with its cksum: 0 all equal, each logged change listed, or no oracle (a line says so); 1 one line per file changed or missing that `## Oracle changes` of the record does not name; 2 cannot run. Then, verbatim in substance: "It guards against mistakes, not against an implementer who also rewrites the sum, which lives in the plan they commit (ADR-0052, ADR-0098)." Line wraps are free; the test joins the header.
   Test that fails if wrong: `test_gate_without_oracle_says_so`.
2. [x] **`po-gate oracle-intact`: the comparison** — for each oracle row, in plan order: the file absent from `story/<id>` (`git cat-file -e`) → "missing"; else `git cat-file blob story/<id>:<path> | cksum` compared with the recorded sum, whitespace-normalised → "changed" when different. When at least one file is changed or missing, read `docs/verif/<id>.md` from `story/<id>` (absent → exit 2) and its `## Oracle changes` rows with `table_rows`; a missing `## Oracle changes` section reads as no row. All equal → exit 0, stdout empty, the record never read. Output on stdout, one line per case:
   - unlogged: `<path>: changed without a row in ## Oracle changes` or `<path>: missing on story/<id>, without a row in ## Oracle changes`;
   - logged: `<path>: changed, logged in ## Oracle changes — <what changes> — <why>`, one line per matching row (a file with two rows gets two lines). A row naming a file whose sum still matches, or a file the plan does not list, prints nothing.
   Any unlogged line → stderr `po-gate: <n> oracle file(s) of <id> changed without a row in ## Oracle changes`, exit 1; else, when logged lines exist, stderr `po-gate: <n> logged oracle change(s) of <id> to judge`, exit 0.
   Test that fails if wrong: `test_gate_compares_oracle_sums`.
3. [x] **Review step 4 runs the check** — in `method/skills/review-antihallu/SKILL.md`, insert as the first bullet of step 4, before *Floor.* (`:41`), this text:
   ```markdown
   - *Oracle.* Run `po-gate oracle-intact <id>` from the worktree before reading any test: it compares each oracle file that `## Acceptance tests` of the plan names, on `story/<id>`, with the sum the planner left. Exit 0: the oracle is intact, the plan has none, or each change it lists from `## Oracle changes` is judged: one that weakens the criterion its test holds is **major** at least. Exit 1: an oracle changed without saying so counts as a test file deleted without a reason → **critical**, one finding per file printed. Exit 2: the check could not run, which is never clean: the review is blocked, with the check's message as `Failure cause:`.
   ```
   The six numbered steps, the heading and every other bullet keep their text.
   Test that fails if wrong: `test_review_runs_the_oracle_gate`; `tests/review.test.sh`, `tests/floor-guard.test.sh` and `tests/ownership.test.sh` stay green.
4. [x] **Bite starts with the oracle** — in the *Bite.* bullet (`:44`), right after "and disable each in turn: flip the condition, return the opposite, remove the filter.", add the sentence "When the plan names oracle files, choose first among the rules their tests hold." Nothing else in the bullet changes.
   Test that fails if wrong: `test_bite_starts_with_the_oracle`; `tests/review.test.sh:27-32` stays green.
5. [x] **Record and commit** — write `docs/verif/s150-oracle-intact-gate.md` from `templates/verification-record.md` (`## Checks`: Unit suite `bash tests/run.sh`, Type check `—`); run the full suite once through `po-run --story s150-oracle-intact-gate --label 'Unit suite' -- 'bash tests/run.sh'`; one commit with the research, the plan and its ticks, the oracle file, the record and the code.
   Test that fails if wrong: the full suite, including `tests/overlap.test.sh` (ADR-0006) on the new method text.

## Scene viewpoints
—

## Run interdicts
- `.polype/` and `.claude/` end with an empty diff (installed copies; `AGENTS.local.md`, Conventions).
- `method/templates/review.md`, `method/agents/reviewer.md`, `method/commands/po-review.md`, `method/AGENTS.md` end with an empty diff: outside `Owns`.
- `git diff main...story/s150-oracle-intact-gate -- method/hooks/po-gate.sh` removes no line (`grep '^-[^-]'` prints nothing): the existing gates and helpers stay as they are.
- In `method/skills/review-antihallu/SKILL.md`, the only removed line is the *Bite.* line being extended; still exactly six `**N. ` steps.
- `tests/oracle-intact-gate.oracle.test.sh` keeps the sum above, or the record carries its `## Oracle changes` row.
- No new setting, no new file under `method/` other than edits to the two owned files; `tests/oracle-intact-gate.test.sh` is created only if it holds at least one test.

## The pivot
Every input is read from the commit `story/<id>` points at — the plan, the record and the oracle files — never from the working tree, like `floor_guard` and unlike `verif-current`. Ways it could be wrong:
- A reviewer in a fix run with an uncommitted record row: the gate would not see it. Compare with `method/agents/implementer.md:46` (a fix run adds its own commit) and with `verif-current`, which already refuses a record whose tree moved; the review judges committed code.
- The record is read only when a sum differs: a lane whose record is missing passes when its oracle is intact. That matches the story ("toutes égales → sortie 0"); `verif-current` (step 1) catches a missing record anyway.
- Until the installed method is refreshed after ship, `.polype/hooks/po-gate.sh` lacks the subcommand ("unknown subcommand", exit 2): the review of s150 itself runs the installed skill, which does not call it, so this lane is unaffected; later lanes see it only after the refresh.

## Files touched
`method/hooks/po-gate.sh`, `method/skills/review-antihallu/SKILL.md`, `tests/oracle-intact-gate.oracle.test.sh` (written by the planner), `docs/research/s150-oracle-intact-gate.md`, `docs/plans/s150-oracle-intact-gate.md`, `docs/verif/s150-oracle-intact-gate.md`.

## Test strategy
- Automated: the four oracle tests, one per criterion, within `Test budget` (25). The two gate tests are behaviour tests on throwaway repositories (the layer of `tests/floor-guard.test.sh`), each exercising every exit the criterion names; the two skill tests quote the exact phrases tasks 3 and 4 fix. No implementer test is expected; one may be added in `tests/oracle-intact-gate.test.sh` for a case the oracle misses (e.g. two rows for one file), never by editing the oracle.
- Each task's tests run with that task: `bash tests/run.sh oracle-intact-gate.oracle.test.sh` (plus `review.test.sh floor-guard.test.sh ownership.test.sh` after tasks 3–4). The full suite runs once, task 5, through `po-run`. No type check (`Typecheck: —`).
- No visual check: no screen.

## Done when
The four oracle tests and the full suite pass on the committed tree, recorded by `po-run`; the record is complete; the review finds no critical; the story lands as one commit `s150-oracle-intact-gate: Un oracle modifié en silence bloque la revue` through a pull request.
