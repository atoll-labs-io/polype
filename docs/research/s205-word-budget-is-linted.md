# Research — s205-word-budget-is-linted

[Story](../stories.md)

Line numbers are those of `4d42324`, the lane's start point. Counts were taken with `LC_ALL=C wc -w`. Fix run 1 replaced it with `LC_ALL=C awk '{n += NF} END {print n + 0}'`: coreutils 9.12 counts the byte 0xA0 (in « à ») as a blank in the C locale and older ones do not, so `docs/parite-killer-saas.md` was 3816 here and 3815 on the forge; awk gives 3815 on gawk, mawk and busybox. Every other count below is the same either way.

## Structuring facts
1. **Story assumption false: "each file of `method/`" and "a total under 57 589" cannot both hold.** 57 589 is the count of the **`.md` files** of `method/` on 2026-11-15 (`e14413b`: `.md` files 57 589; all files 72 707). Today the `.md` files hold 50 158 words in 60 files, and all files 65 318, the six hooks of `method/hooks/` making the difference. With the hooks in it, the total cannot fall under 57 589. The budget covers the `.md` files of `method/`, as the 2026-11-15 count did. Hooks are code: their growth is a code review matter, and no ceiling covers them. **Owner's decision d-0055 (option a)**, taken after the first draft: the budget also holds the four document ceilings of `tests/drive-takes-one-story.oracle.test.sh:13`. Their counts today: `README.md` 1598 (ceiling there 1611), `docs/migration.md` 1735 (1737), `docs/parite-killer-saas.md` 3815 by awk (3816), `docs/direction.md` 1192 (1192). The lead confirmed fact 1 and corrects the story text through a framing pull request (`origin/main` is now `29301a6`).
2. **Story assumption stale: 18 test files, not 12, hold a hard-coded word ceiling** (list under `## Current code`). It matches the list of s204's plan (`docs/plans/s204-framing-and-installer-phrase-tests-retired.md:120`) plus the story's own list. Ten functions sit in the keep lists of the oracles of s201 to s204, which pin them "until s205".
3. **`bin/polype` needs no change.** Both project poses (`install <project>`, `init`) lay only `commands/`, `agents/`, `skills/`, `templates/`, `hooks/` (`bin/polype:170-173`), never a file at the root of `method/`. The global pose copies `method/` whole into the payload `~/.claude/polype/method/` (`bin/polype:157-158`, `docs/installation.md:54`). The payload is one copy per machine, not a project, and its `bin/po-lint` needs the budget next to it.
4. **Ceilings at today's counts break the mutation tests that add words.** `tests/lint.test.sh` mutates a copy of `method/`, then counts exactly one breach (`reports_one`, `:35-43`). It also has a negative control that must exit 0 (`:112-118`). Three mutations add words: `  - Edit` (`:71`), `  - Bash` (`:76`) and `, Write` (`:81`). `tests/drive-executes-next.oracle.test.sh` does the same (`lint_refuses`, `:31-40`; tool lines added at `:58-62`).
5. **The launch count of s201 moves for one script.** The reader counts `security-findings-stay-private.oracle.test.sh:test_words_hold` as a launch of `po-gate.sh`: its `for` list names `hooks/po-gate.sh:5843`. Removing it lowers `po-gate.sh` from 136 to 135. No other word-ceiling function counts.

## Story
One file holds the word ceiling of each `method/` file and of the total; `po-lint` checks it (#208). Criteria:
- `budget_is_one_file`: the lint fails on a file over its ceiling, on the total over its ceiling, and on a file with no line;
- `budget_starts_at_todays_counts`: each ceiling is the day's count, and the total is under 57 589;
- `raising_a_ceiling_is_visible`: with a base ref, the lint refuses a raised ceiling whose line cites no owner's decision. A lowered one passes. An absent base fails, named. Without a base, only the ceilings are checked;
- `scattered_ceilings_are_gone`: no test carries a hard-coded word ceiling;
- `budget_is_not_installed`: the installer lays the file in no project.

## Current code
- `bin/po-lint` (355 lines):
  - usage `po-lint [method directory]` (`:8`), default `../method` (`:11`), exit 2 on no directory (`:12`);
  - `report <file> <line> <rule> <message>` prints `<file>:<line>: [<rule>] <message>` and counts the breach (`:16-19`);
  - lists `commands/*.md` and `agents/*.md` once and exits 2 on zero files (`:76-83`);
  - four rules, run at `:345-348`; summary `po-lint: <n> breach(es) in <m> file(s) of method/`, exit 1 on any breach (`:350-355`);
  - no git, no word count, no option.
- How a base is computed: `method/hooks/po-bounds.sh:131-152` takes `git merge-base HEAD <refs>` and denies when there is none.
- Hard-coded ceilings, with what each function also checks:

| File | Function (lines) | Ceiling | Else in it | Pinned by |
| --- | --- | --- | --- | --- |
| `answer-comes-back.test.sh` | `test_rules_stay_under_the_story_ceiling` (130-134) | AGENTS.md 3741 | — | s204 `:42` |
| `commands-read-po-state.test.sh` | `test_status_and_retro_shrink` (34-37) | po-status <1101, po-retro <977 | — | s204 `:38` |
| `decision-inbox.test.sh` | `test_rules_stay_under_their_word_ceilings` (99-107) | two sections 378 and 516, AGENTS.md 3743 | — | s204 `:41` |
| `defects-seen-on-products.oracle.test.sh` | `test_no_file_grows` (5-20, only test) | six files | — | s204 `:37` |
| `drive-executes-next.test.sh` | `test_execute_does_not_grow` (4-9, only test) | po-execute 854 | — | s201 `:195` |
| `drive-executes-next.oracle.test.sh` | `test_drive_holds_in_2500_words` (10-14) | po-drive 2500 | — | — |
| `intake-follow-ups.oracle.test.sh` | `test_intake_holds_in_its_words` (44-48) | po-intake 1550 | — | s202 `:13` |
| `qa-lanes-isolated.oracle.test.sh` | `test_no_file_grows` (4-18, only test) | two files | — | s203 `:17` |
| `record-writes-reports.test.sh` | `test_commands_lose_words` (19-28) | three commands, review.md 558 | — | s204 `:39` |
| `installer-leftovers.oracle.test.sh` | `test_docs_describe_the_kept_copy_stops` (115-122) | `## Installed files` 516 | section exists | s204 `:24` |
| `security-findings-stay-private.oracle.test.sh` | `test_words_hold` (158-167) | nine files, **po-gate.sh 5843** | — | — |
| `ship-files-the-other-findings.oracle.test.sh` | `test_words_hold` (only test) | four files | — | — |
| `ship-lands-through-a-pull-request.test.sh` | `test_ship_words_go_down` (233-237) | po-ship 1998 | — | — |
| `ship-cleans-the-lane.oracle.test.sh` | `test_ship_is_a_short_command` (216-222) | po-ship <1000, po-drive 2449 | — | — |
| `ship-files-open-findings.test.sh` | `test_ship_words_go_down` (228-234) | po-ship 1593 | two heading phrases | — |
| `own-context-commands-are-briefs.oracle.test.sh` | `test_words_go_down` (25-39), vars 6-9 | three files −700, six files | — | — |
| `delegating-commands-are-briefs.oracle.test.sh` | `test_words_go_down` (33-45), vars 9-11 | three files −650, five files | — | — |
| `drive-takes-one-story.oracle.test.sh` | `test_words_go_down` (57-70), vars 8-13 | method/ −3000, **README.md, docs/migration.md, docs/parite-killer-saas.md, docs/direction.md** (taken over by the budget, d-0055) | — | — |

The two heading phrases of `ship-files-open-findings.test.sh:232-233` (`## Step 3 — Cleanup, only after proof`, `^2\. File the open findings`) are read by no script: `grep` over `po/src`, `bin/` and `method/hooks/` finds neither. `readme-onboarding.test.sh:135` measures `AGENTS.md` in KiB to check a figure of `README.md`. It is no ceiling.

## Attachment points
- `bin/po-lint`: argument parsing before `:11`, a base resolved after `:13`, a fifth rule beside the four and called after `check_fail_closed` (`:348`). The `report` and summary lines stay as they are.
- `method/word-budget`: new, at the root of `method/`, beside `AGENTS.md`.
- Mutation helpers: `tests/lint.test.sh:11-16` (`mutant`), `tests/drive-executes-next.oracle.test.sh:21-28` (`execute_mutant`).
- Real-tree lint run: `tests/lint.test.sh:45-49` (`test_lint_is_part_of_the_suite`).
- Keep lists:
  - `KEPT_CONTRACTS` (`tests/routing-phrase-tests-retired.oracle.test.sh:193-219`), `LOWERED_COUNTS` (`:150-151`);
  - `S202_KEPT` (`tests/ship-phrase-tests-retired.oracle.test.sh:9-19`);
  - `S203_KEPT` (`tests/qa-and-design-phrase-tests-retired.oracle.test.sh:9-34`);
  - `S204_KEPT` (`tests/framing-and-installer-phrase-tests-retired.oracle.test.sh:9-46`).
- `docs/harnais.md:160-175` (`## Ce que la suite prouve depuis #207`; `:166` names the word ceilings "jusqu'à s205"; `:170`, the d-0052 exception, keeps `decision-inbox.test.sh` and `answer-comes-back.test.sh` "entiers").

## Verified interfaces
- Every test that runs `po-lint` on a copy of `method/` takes it with `cp -r "$METHOD"`, so the copy carries the budget. Those that only change a profile under `boilerplates/` move no count of `method/`. Examples: `profile.test.sh:42-48`, `qa-drivers.test.sh:24-30`, `platform-setting.test.sh:23-29`, `profiles-hold.test.sh:33-39`, `strict-checks-by-default.test.sh:22-28`.
- Copies that change a `.md` of `method/` and accept any extra breach (`[ "$status" -ne 0 ]` and `grep`):
  - `adr-directory.test.sh:18-23` (fewer words);
  - `profiles-hold.test.sh:95` (same count);
  - `godot-scene-driver.test.sh:52` and `ros-simulation-driver.test.sh:52`: they delete a driver `.md`, so its budget line names no file, one more breach. Their assertions still hold.
- Of the `lint.test.sh` mutations, only `:71,:76,:81` and the negative control at `:113-114` add words. The settings swap at `:58` keeps the count (2 words for 2). The fail-closed swaps remove words.
- s201 helpers, sourced unchanged by any oracle (`docs/harnais.md:154`):
  - `story_landed <repo> <commit> <id>` (`:155-157`);
  - `scripts_kept_their_tests` compares the merge base with `origin/<Target branch>` to the working tree, and lets a drop through when it is listed in `LOWERED_COUNTS` and its story has not landed (`:163-190`);
  - `tests_defined` (`:222-225`).
- `tests/lib.sh` exports `GIT_CONFIG_GLOBAL=/dev/null`, `scratch_repo` sets its own `EXIT` trap (`:47-54`). A file with a file-level trap must not call it.
- Owner's decisions are cited as `d-NNNN` (`docs/decisions-log.md:403-411`; `method/AGENTS.md` asks the lead to cite "the decision's id").
- CI runs the suite with full history (`.github/workflows/ci.yml:15-18`), so `origin/main` exists there. s201's oracle already relies on it (`:313-316`).

## Traps
- The launch counts on the base (`script_counts`, all scripts): `po` 178, `polype` 143, `po-gate.sh` 136, `po-run.sh` 52, `po-bounds.sh` 49, `pre-commit` 32, `po-lint` 26, `po-session.sh` 25, `po-eval` 20, `po-intake.sh` 13, `polype-dev-install` 12, `po-release` 12, `po-version-check` 5, `po-link-artifacts` 4, `po-ci` 2, `ks-overlap` 1. Of the functions to remove, only `security-findings-stay-private.oracle:test_words_hold` counts (`po-gate.sh`). The oracle adds `po-lint` ×2 and `polype` ×1 (read by the same reader on a copy).
- Comment lines that name `wc -w` sit above several functions to remove (`record-writes-reports:19`, `security-findings-stay-private.oracle:158`, `own-context…:6`, `delegating…:9`, `drive-takes-one-story.oracle:8`). The oracle's scan counts comments too, so they must go with their functions.
- Four files are left with no test and must be deleted (`tests/run.sh` fails a file with no `test_`). `po-gate floor-guard` will flag them, plus the weakened files. This is expected and named in the plan.
- `docs/harnais.md:170` says two security files "restent entiers". Removing their word-ceiling function contradicts it unless the sentence changes.
- Section ceilings (`## What goes to the person` 378, `## Installed files` 516) have no place in a one-line-per-file budget. The file ceiling of `AGENTS.md` (3732 today) holds them together.
- The four documents of d-0055 sit outside `method/`. No test runs `po-lint` on a copy that sits at the root of a git work tree: copies live under `mktemp -d` (`lint.test.sh:11-16`, the profile tests), and `drive-takes-one-story.oracle:32` copies `method/` into a sub-folder of its scratch repository without linting it. The payload `~/.claude/polype/method/` has `bin/` beside it, no `README.md`. So "is `method/` at the root of a repository" separates the real tree from every other tree `po-lint` is run on.
- `docs/parite-killer-saas.md` gets a status cell updated by stories that implement parity lines (`AGENTS.local.md`, conventions), and `docs/direction.md` is the lead's. Under d-0055, either one growing needs a new owner's decision on its line.
- Nothing else is in flight (the lead). If `main` moves before ship, the counts must be generated again.
- No migration, no `po/`, no `method/` file other than the new one.

## Open questions
- Format of the budget line, how it names a document outside `method/`, when documents are checked, name of the base option, how a line cites a decision: implementation details, settled in the plan.
- Whether a line absent at the base counts as "raised": settled in the plan.

## Complexity
3 → 3. The code change is one rule in one script and a generated file. The breadth (18 test files, 4 shipped oracles, the launch count) is mechanical, but it pushes the plan past six tasks, hence the full track.

## Split
—
