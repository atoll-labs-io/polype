---
validated: yes
---
# Plan — s205-word-budget-is-linted

[Story](../stories.md) · [Research](../research/s205-word-budget-is-linted.md)

Branch `story/s205-word-budget-is-linted`. Read `docs/research/s205-word-budget-is-linted.md` first; this plan builds on it without repeating it. Line numbers are those of `4d42324`. `main` has since moved (`29301a6`, the lead's framing pull request that corrects the story); the lead brings the lane level before the implementer starts, and every count below is generated again on the levelled tree.

**Track.** `po next` gave `flow` (complexity 3 = `Flow threshold`). The planner took the full track: the work needs seven tasks over two dozen test files (four of them shipped oracles) and the launch count, past the six tasks of the short track. No other escalation signal is present: no migration, screen, authorization, API contract or dependency, no `Fixes` line, and no choice that deserves an ADR (below).

**Validated under `Plan validation: autonomous`**: the planner checked each criterion against the tasks (table under `## Acceptance tests`). No human reviewed this plan.

## Story
One file, `method/word-budget`, gives the word ceiling of each `.md` file of `method/`, of their total, and of four documents outside `method/`, and `bin/po-lint` holds it (#208). Corrected assumptions (research, facts 1-2), confirmed by the lead and carried into the story by its framing pull request:
- the budget covers the **`.md` files** of `method/`, the set the 2026-11-15 count of 57 589 measured; hooks are code;
- **18** test files hold a hard-coded ceiling today, not 12;
- by the owner's decision **d-0055** (option a), the budget also holds the four document ceilings of `tests/drive-takes-one-story.oracle.test.sh:13` (`README.md`, `docs/migration.md`, `docs/parite-killer-saas.md`, `docs/direction.md`), checked the same way, raises included, so that one file holds every word ceiling of the repository.

The five criteria are all read by a script (case 1 of `docs/direction.md`). Each has an oracle test running `bin/po-lint` or `bin/polype` on throwaway trees. No test looks for a phrase.

## Settled here (implementation details, one reason each)
- **Line format**: `<path under method/> <ceiling>`, an optional third field `d-NNNN`, and one line `total <ceiling>`. Blank lines and lines starting with `#` are skipped, and lines may come in any order. Reason: whitespace-separated fields are what awk splits by default, and a person edits them in any editor. No path under `method/` holds a space (`find method -name '* *'` is empty).
- **Paths of the documents**: every key is a path relative to the directory of `word-budget`, so a document outside `method/` is written `../README.md`, `../docs/direction.md`; a key starting with `../` is a document, any other key but `total` a file of `method/`. Reason: one rule for every line (read the path from where the file sits), the 60 lines of `method/` stay short, and `git show <commit>:./word-budget` reads the same file at a base.
- **When documents are checked**: only when the parent of the method directory is the top of a git work tree (`git -C <parent> rev-parse --show-toplevel` is that parent, both sides taken with `pwd -P`). Then a listed document is counted against its ceiling, and one that is absent is a breach. Otherwise (the payload `~/.claude/polype/method/`, a copy of `method/` in a test, any tree with no repository around it) every `../` line is skipped, present or not, and no breach names it. Reason: one predictable test, "is `method/` at the root of a repository", decides whether the repository's documents can be expected; the real tree and every story worktree pass it, the payload and the suite's copies (all under `mktemp -d`, none a git top) do not.
- **Documents and the other rules**: their lines are listed by choice. No other file outside `method/` needs a line, the "every `.md` has a line" rule stays for `method/` alone, and documents are not in the total: the 57 589 bound is about `method/`. **No second total**: four documents, each with its own ceiling, gain nothing from a sum that only repeats them. Raises are judged as for any line.
- **Base option**: `po-lint --base <ref> [method directory]`, only that spelling. Reason: "base ref" is the word of s201's count and of `po-bounds`. One option, no `=` form to parse.
- **Base commit**: `git merge-base HEAD <ref>`, in the repository that holds the method directory, as `method/hooks/po-bounds.sh:131-152` does. Reason: a branch is judged on what it changed since it forked, never on what the ref did since. A ref that does not resolve, or shares no commit with `HEAD`, fails the run.
- **Citation**: a raised ceiling's line must carry, as third field, a `d-NNNN` other than the one the same line carried at the base. Reason: `method/AGENTS.md` already has the lead cite the decision's id, and a second raise on an old decision would otherwise pass. The lint does not open the decision inbox, which may be private: the reviewer checks that the id exists and says what the line claims.
- **What counts as raised**: a line whose key had a line at the base with a smaller ceiling, `total` included. A line new since the base is no raise: the total ceiling bounds it. A budget file absent at the base means nothing to compare, which is the case of this story's own pull request.
- **Section ceilings** (`## What goes to the person` 378, `## Installed files` 516) are **not taken over**. The budget is per file, and the ceiling of `method/AGENTS.md` (3 732 today, under both old totals 3 741 and 3 743) holds its sections together.
- **No ADR**: the scope is forced by the criterion (fact 1), no second place for ceilings remains, and the rest is the format of one file.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Budget rule in `bin/po-lint` | new code. It reuses `report` (`bin/po-lint:16-19`) and the summary (`:350-355`), and parses with awk like the other rules (`:23-70`) | No script reads ceilings today. awk and `git` (platform) do the counting and the base. |
| Base resolution | platform (`git rev-parse --verify`, `git merge-base`, `git show <commit>:./word-budget`), on the pattern of `po-bounds.sh:131-152` | `po-bounds` cannot be sourced: it answers a hook with JSON and denies. |
| `method/word-budget` | generated once by the shell command of task 2, kept nowhere | A kept generator would be a second script to test, for a file generated once. |
| Oracle helpers | `story_landed` of s201 (`tests/routing-phrase-tests-retired.oracle.test.sh:155-157`), sourced unchanged | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/word-budget-is-linted.oracle.test.sh` | `1729079487 11205` |

| Criterion | Test |
| --- | --- |
| `budget_is_one_file` | `test_budget_is_one_file`. A small tree at its budget, a hook with no line → exit 0. Then, one breach each: a file past its own ceiling, the total past its ceiling, a `.md` file with no line, no budget file. A document `../docs/guide.md` beside `method/`, in a repository: at its ceiling → exit 0; one word over → one breach at its line; removed → one breach at its line. Outside any repository, lines `../README.md` and `../docs/direction.md` naming absent files → exit 0. |
| `budget_starts_at_todays_counts` | `test_budget_starts_at_todays_counts`. The total ceiling is under 57 589, and the four documents of d-0055 have a line, always. Until `origin/main` holds the landing commit `s205-word-budget-is-linted: …`, every ceiling of `method/` and of the four documents equals its file's count, and the total equals the sum over `method/`. |
| `raising_a_ceiling_is_visible` | `test_raising_a_ceiling_is_visible`, in a throwaway repository:<br>• compared with the fork point: a budget unchanged since then passes, though `main` lowered a ceiling after it;<br>• refused, one breach each: a raise with no citation, a raise on the citation the line already carried, a raised total, a document's ceiling (`../README.md`) raised with no citation;<br>• passes: a raise citing a new decision, a lowered ceiling, a raise when no base is given;<br>• fails naming it: `--base nowhere/branch`. |
| `scattered_ceilings_are_gone` | `test_scattered_ceilings_are_gone`: no line of `tests/*.sh` but the oracle holds `wc -w`, except on a here-string or git's output (`evals:70`, `ship-lands-through-a-pull-request.oracle:250`, `journey-runs-to-a-landed-commit.oracle:82`). |
| `budget_is_not_installed` | `test_budget_is_not_installed`. `polype install <project>`, then `install --global` followed by the payload's `polype init <project>`. No file `word-budget` lies in either project. |

The oracle's helpers create everything under one `mktemp -d` that its `EXIT` trap removes. The planner ran the loading and the small tree against the base: it loads, five functions, the tree lints clean, and the scan lists the 18 files.

## po-lint's contract (task 1)
Breaches use the existing `report`, rule `budget`. The exact texts:

| Case | Line printed |
| --- | --- |
| no `word-budget` file | `word-budget:1: [budget] no word budget` |
| line not `<key> <integer>` or `<key> <integer> d-<digits>` | `word-budget:<n>: [budget] malformed line: <line>` |
| key on two lines | `word-budget:<n>: [budget] <key> is listed twice` (second line) |
| key neither `total`, nor `../…`, nor a `.md` file of `method/` | `word-budget:<n>: [budget] <key> is no .md file of method/` |
| `../` key whose rest is empty, absolute or holds a `..` part | `word-budget:<n>: [budget] malformed line: <line>` |
| `../` key, repository around `method/`, file absent | `word-budget:<n>: [budget] <key> names no file of the repository` |
| `.md` file with no line | `<path>:1: [budget] no line in word-budget` |
| file or checked document over its ceiling | `word-budget:<n>: [budget] <key> holds <w> words, over its ceiling of <c>` |
| no `total` line | `word-budget:1: [budget] no total line` |
| sum over the total | `word-budget:<n>: [budget] the .md files of method/ hold <w> words, over the total ceiling of <c>` |
| raised with no new decision (`--base` only) | `word-budget:<n>: [budget] <key> raised from <old> to <new> with no new decision of the owner` |
| `--base` with no value | stderr `po-lint: --base needs a git ref`, exit 2 |
| `--base` anywhere but first, or more than one directory | stderr `usage: po-lint [--base <ref>] [method directory]`, exit 2 (fix run 1) |
| base absent or unrelated | stderr `po-lint: no base to compare the word budget with: <ref>`, exit 2, before any check runs |

The `.md` files are `find "$METHOD" \( -type f -o -type l \) -name '*.md'`, recursive, a symlink counted through the file it leads to and skipped when it leads to none (fix run 1: the other rules read symlinks through). **A word** is a run of characters between blanks, tabs and newlines, counted by awk in the C locale, `LC_ALL=C awk '{n += NF} END {print n + 0}'` (fix run 1: `LC_ALL=C wc -w` reads the byte 0xA0 as a blank on coreutils 9.12 and not on the forge's older one, so the suite went red there). The total is the sum of those counts; documents never enter it. The summary line and its file count (commands and agents) do not change.

## Tasks
1. [x] **`bin/po-lint`**, the only script changed.
   - Usage comment (`:8`): `po-lint [--base <ref>] [method directory]`.
   - Before `:11`: parse `--base <ref>` and leave the positional argument as it is.
   - After `:13`, when a base is given, the base commit is `git -C "$METHOD" rev-parse --verify -q "<ref>^{commit}"`, then `git -C "$METHOD" merge-base HEAD <that>`. Either failing → the stderr line and exit 2 of the table. Its budget is read with `git -C "$METHOD" show "<commit>:./word-budget"`; when that fails, the base has no budget.
   - Decide once whether documents are checked: `parent="$(cd "$METHOD/.." && pwd -P)"`, checked when `git -C "$parent" rev-parse --show-toplevel` succeeds and prints a path whose `pwd -P` is `$parent`. When they are, count each `../` key that names a regular file with the awk count above, and hand those counts to awk with the others, marking absent ones.
   - Add a `# --- rule: budget` section with a header comment of at most four lines, and a function `check_budget` that applies the table. Hand awk the counts and the base budget through `ENVIRON`, not `-v`: `-v` reads escapes and newlines unevenly across awks. Feed the breaches back as tab-separated lines read by `while … done < <(…)`, so `report` counts them, as `check_fail_closed` does (`:169-189`).
   - Call it after `check_fail_closed` (`:348`).
   - Test: `test_budget_is_one_file` and `test_raising_a_ceiling_is_visible`, each run alone until task 2 exists: `bash -c 'set -eu; cd tests; source ./lib.sh; source ./word-budget-is-linted.oracle.test.sh; test_budget_is_one_file'`.
2. [x] **`method/word-budget`**. Write these four comment lines with the file tool, in English and in your own words, keeping their content:
   - one line per `.md` file, `<path under method/> <ceiling>`, plus `total <ceiling>`, counted by awk in the C locale (`{n += NF}`);
   - four documents outside `method/`, by the owner's decision d-0055, as `../<path> <ceiling>`: checked only when `method/` sits at the root of a repository, and not in the total;
   - `bin/po-lint` fails on a file or the total past its ceiling, and on a `.md` file with no line;
   - a raised ceiling carries the owner's decision as third field `d-NNNN`, a new one, and `po-lint --base <ref>` refuses a raise without one;
   - written by s205.

   Then append the lines once, from the worktree root:
   ```
   bash -c 'set -eu; cd method; words() { LC_ALL=C awk "{n += NF} END {print n + 0}" < "$1"; }; lines="$(find . -type f -name "*.md" | sed "s|^\./||" | LC_ALL=C sort | while IFS= read -r f; do printf "%s %s\n" "$f" "$(words "$f")"; done)"; printf "total %s\n%s\n" "$(awk "{s += \$2} END {print s}" <<< "$lines")" "$lines" >> word-budget; for d in README.md docs/migration.md docs/parite-killer-saas.md docs/direction.md; do printf "../%s %s\n" "$d" "$(words "../$d")"; done >> word-budget'
   ```
   On `4d42324` this gives 60 file lines, `total 50158`, then `../README.md 1598`, `../docs/migration.md 1735`, `../docs/parite-killer-saas.md 3815` (3816 by the `wc -w` of coreutils 9.12, before fix run 1), `../docs/direction.md 1192`, each at or under the figure of d-0055 (1611, 1737, 3816, 1192), so the budget starts at the truth. If `main` has moved and the lane was rebased, delete the generated lines and run it again. No other file changes `method/`.
   Test: `test_budget_starts_at_todays_counts`; `bash bin/po-lint` says no breach.
3. [x] **Mutation helpers and the suite's base run.**
   - In `tests/lint.test.sh:mutant()` and `tests/drive-executes-next.oracle.test.sh:execute_mutant()`, right after `cp -r`, lift every ceiling of the copy out of reach. Add one comment line saying the budget is not what these mutants test, and run `sed -i -E 's/^([^#[:space:]]+[[:space:]]+)[0-9]+/\1999999/' "$dir/method/word-budget"`. Reason: research fact 4. Without it, `:71,:76,:81` and the negative control `:112-118` gain a budget breach.
   - In `test_lint_is_part_of_the_suite` (`lint.test.sh:45-49`), read `Target branch` from `AGENTS.local.md` as s201 does (`routing…oracle:314`) and add `lint_on --base "origin/$target"` with its exit-0 assertion. That puts raise detection in every CI run.
   - In `drive-executes-next.oracle.test.sh`, delete `DRIVE=` (`:6`) and `test_drive_holds_in_2500_words` (`:10-14`). Rewrite the header (`:2-4`) so it no longer announces a word cap.
   - Test: `bash tests/run.sh lint.test.sh drive-executes-next.oracle.test.sh profile.test.sh qa-drivers.test.sh platform-setting.test.sh profiles-hold.test.sh strict-checks-by-default.test.sh adr-directory.test.sh godot-scene-driver.test.sh ros-simulation-driver.test.sh`.
4. [x] **Remove every other hard-coded ceiling.** None reads the budget: every ceiling it would read is already held by the real-tree `po-lint` runs of the suite (`lint.test.sh:45-49` and s201's `test_contract_tests_stay`), so a test reading the budget would only repeat them. Delete each function together with its `wc -w` comment line and the variables only it uses. Edit the file header where it announces the removed check.
   - **Delete the file** (its only test goes): `defects-seen-on-products.oracle.test.sh`, `drive-executes-next.test.sh`, `qa-lanes-isolated.oracle.test.sh`, `ship-files-the-other-findings.oracle.test.sh`.
   - **Delete the function**:
     - `answer-comes-back.test.sh:130-134`; `commands-read-po-state.test.sh:34-37`, plus the header clause on shorter commands (`:2-3`); `decision-inbox.test.sh:99-107`;
     - `intake-follow-ups.oracle.test.sh:44-48`, plus `INTAKE_CMD` (`:7`) and the header clause "and /po-intake does not grow";
     - `record-writes-reports.test.sh:19-28`, plus the header clause on shorter commands;
     - `installer-leftovers.oracle.test.sh:115-122`: its `-gt 0` only guarded the cap;
     - `security-findings-stay-private.oracle.test.sh:158-167`; `ship-lands-through-a-pull-request.test.sh:233-237`; `ship-cleans-the-lane.oracle.test.sh:216-222`;
     - `ship-files-open-findings.test.sh:228-234`: its two heading `grep`s are phrases no script reads (research);
     - `own-context-commands-are-briefs.oracle.test.sh:25-39` with `:6-9`; `delegating-commands-are-briefs.oracle.test.sh:33-45` with `:9-11`;
     - `drive-takes-one-story.oracle.test.sh:57-70` with `:8-13`, plus "and the method loses words" in `:2-3`. Its four document ceilings move to the budget (d-0055), at today's lower counts.
   - Test: `test_scattered_ceilings_are_gone`; `bash tests/run.sh` on the 13 edited files.
5. [x] **Keep lists of the shipped oracles, changed on purpose** (s201 to s204 pinned these functions "until s205"). Record each edit under `## Oracle changes` of `docs/verif/s205-word-budget-is-linted.md`, as `docs/harnais.md:156` asks.
   - `routing-phrase-tests-retired.oracle.test.sh`:
     - delete the line `drive-executes-next.test.sh test_execute_does_not_grow` (`:195`);
     - make `LOWERED_COUNTS` (`:150-151`) hold the line `po-gate.sh 136 135 s205-word-budget-is-linted`.
   - `ship-phrase-tests-retired.oracle.test.sh:13` → `intake-follow-ups.oracle.test.sh test_redact_follows_the_scan_rule`.
   - `qa-and-design-phrase-tests-retired.oracle.test.sh`: delete the line `:17`.
   - `framing-and-installer-phrase-tests-retired.oracle.test.sh`:
     - `:24`: drop `test_docs_describe_the_kept_copy_stops`;
     - delete the line `:37`;
     - `:38` → `commands-read-po-state.test.sh test_session_hook_reports_a_failing_po`;
     - `:39` → `record-writes-reports.test.sh test_composed_report_is_not_checked test_missing_link_is_dropped`;
     - `:41`: drop `test_rules_stay_under_their_word_ceilings`;
     - `:42`: drop `test_rules_stay_under_the_story_ceiling`.
   - Test: `bash tests/run.sh routing-phrase-tests-retired.oracle.test.sh ship-phrase-tests-retired.oracle.test.sh qa-and-design-phrase-tests-retired.oracle.test.sh framing-and-installer-phrase-tests-retired.oracle.test.sh`. `test_no_script_lost_its_tests` must print `po-gate.sh: launched by 136 test functions on origin/main, 135 here, lowered by s205-word-budget-is-linted`.
6. [x] **Documentation** (French).
   - `docs/harnais.md:166`: replace "les plafonds de mots, jusqu'à s205" with the budget of `method/word-budget`, held by `po-lint` (s205).
   - `:170`: say that `decision-inbox.test.sh` and `answer-comes-back.test.sh` stay whole except their word ceiling, handed to the budget by s205.
   - Add a section `## Le budget de mots`, at most 12 lines, covering:
     - what the file holds, and why only the `.md` files (fact 1);
     - what `po-lint` refuses, and raising a ceiling: a new `d-NNNN`, an implementer able to write `method/word-budget` only when the story's `Owns` lists it;
     - `--base` and its run in `lint.test.sh`;
     - the four documents of d-0055 (`../` lines, checked only when `method/` sits at the root of a repository, outside the total);
     - what it does not prove: that the cited decision exists; a ceiling is no shrink; section ceilings, hooks and the other files of `docs/` hold none.
   - `docs/installation.md`, after the table at `:54`: one sentence saying `method/word-budget` travels in the payload with `method/` and no project pose lays it.
   - Check: the reviewer reads.
7. [x] **Whole run.**
   - `bash tests/run.sh word-budget-is-linted.oracle.test.sh`: five passing.
   - Then the full suite once, through `po-run --story s205-word-budget-is-linted --label full-suite -- 'bash tests/run.sh'`.
   - `po-gate floor-guard` is expected to flag the 4 deleted files (`test-file-deleted`) and, as weakened, the files of tasks 3-5 that lose a function or a keep-list entry, and nothing else. The four documents moving to the budget changes no flag: `drive-takes-one-story.oracle` loses its function either way.
8. [x] **Fix run 1** (forge `suite` red on the landing commit, review minors): count words with awk everywhere the story counts, regenerate the budget, refuse misplaced arguments, count symlinked `.md` files, test the refusal rules, correct `docs/harnais.md`.

## Scene viewpoints
—

## Run interdicts
- `git diff 4d42324 -- method/ ':(exclude)method/word-budget'` is empty. So is the diff of `bin/polype`, `bin/polype-dev-install`, `po/`, `.claude/`, `.polype/`, `tests/lib.sh`, `tests/run.sh`, `tests/overlap.test.sh`, `docs/stories.md` and `AGENTS.local.md`.
- The oracle's sum stays `1729079487 11205` (fix run 1 changed only how it counts, recorded under `## Oracle changes`).
- `README.md`, `docs/migration.md`, `docs/parite-killer-saas.md` and `docs/direction.md` end with an empty diff: the story lists their ceilings and never edits them.
- No test function is removed outside tasks 3-4, and no kept function loses an assertion other than those listed.
- No budget generator and no scratch file are left in the repository or in `/tmp`. Helper commands run under `bash`.
- Out of scope: the other `po-lint` candidates (#442, #449, #455, #460, #461) and the launch counter (#462, #447). No section ceiling comes back anywhere.
- `.polype/inbox/` and `Private folder` are never read.

## The pivot
Everything rests on **ceilings at exactly today's counts, over the `.md` files of `method/` and the four documents, checked on the real tree in every suite run**. Four ways it could be wrong:
1. **Scope.** If the owner meant every file, the total criterion cannot be met. Compare: `git show e14413b` counts 57 589 for `.md` files and 72 707 for all files (research fact 1).
2. **Collateral breaches.** Exact ceilings turn any test that adds words to a copy of `method/` red. The planner found two (task 3) by reading each `po-lint` test on a copy. Compare: the run list of task 3, and `grep -l 'bin/po-lint' tests/*.sh`.
3. **Where documents are checked.** If the "root of a repository" rule misfires, the real tree skips its documents silently, or a copy in a test fails on absent ones. Compare: `test_budget_is_one_file` holds both sides, and on the real tree `po-lint` with `README.md`'s line lowered by one must report it.
4. **Launch count.** Removed functions might hold more launches than the one named. Compare: s201's `script_counts` on the base (research, `## Traps`) and the line `test_no_script_lost_its_tests` prints after task 5. Every other count stays equal, or rises: `po-lint` 26→28, `polype` 143→144.

The installer side (`bin/polype` unchanged) is checked by `test_budget_is_not_installed`. The payload's `~/.claude/polype/method/word-budget` is expected.

## Files touched
- New: `method/word-budget`, `tests/word-budget-is-linted.oracle.test.sh` (written), `tests/word-budget-is-linted.test.sh` (fix run 1).
- Changed: `bin/po-lint`, `tests/lint.test.sh`, `tests/drive-executes-next.oracle.test.sh`, the 13 files of task 4 that are not deleted, the 4 shipped oracles of task 5, `docs/harnais.md`, `docs/installation.md`.
- Deleted: the 4 files of task 4.
- Also committed: this plan, the research, `docs/verif/s205-word-budget-is-linted.md`.

## Test strategy
- Five oracle tests, one per criterion, all on throwaway trees through `bin/po-lint` or `bin/polype` (script layer). Five of the `Test budget` of 25.
- Fix run 1 adds `tests/word-budget-is-linted.test.sh`, four tests on throwaway trees: a word holding the bytes C3 A0 counts once, the refusal rules (duplicate key, malformed line, unknown key, `../` path with a `..` part), a symlinked `.md`, and `--base` misplaced or unrelated. Nine of 25.
- One assertion is added to an existing function (`lint.test.sh`, the `--base` run on the real tree). The other existing tests change only by removal.
- Each removed function's rule is still held by `po-lint`: the ceilings of `method/`, and those of the four documents through their `../` lines (d-0055). Section ceilings and the hook ceiling of `security-findings-stay-private.oracle` have no successor, as the plan says.
- No visual check.

## Done when
- The five oracle tests and the full suite pass through `po-run`, and `po-lint` with `--base origin/main` reports no breach.
- One commit on `story/s205-word-budget-is-linted` carries the code, the tests, the research, this plan and the record.
- A review has no open critical finding, then the story lands through a pull request.
