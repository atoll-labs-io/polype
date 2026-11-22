# Review — s205-word-budget-is-linted

[Story](../stories.md) · [Plan](../plans/s205-word-budget-is-linted.md) · [Verification](../verif/s205-word-budget-is-linted.md)

Method version: 0.11.0
Recorded: 2026-11-22T23:36:44+01:00

Diff reviewed: `git diff main...story/s205-word-budget-is-linted`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 5972744118a95f0ae2ed0dea309c6936f1ae58c8

## Ownership
Diff listed with `git diff --name-only main...story/s205-word-budget-is-linted`, each path held against `Owns` (`bin/po-lint`, `method/word-budget`, `tests/`, `docs/harnais.md`, `docs/installation.md`, `bin/polype`).
- [x] Every path inside `Owns`. The only others are the story's own research, plan and record. `bin/polype` is not touched.
- [x] Nothing is inside another running story's `Owns`. `git worktree list` shows no other `story/` lane.

## Evidence reused
- [x] `po-gate verif-current s205-word-budget-is-linted` → exit 0. I reused the record (`bash tests/run.sh`, exit 0, 726 s) and did not rerun the full suite. The project has no `Typecheck` command (`—`). Its "Not proven here" says bash 3 was not run.
- [x] `po-gate qa-current`: not required (`QA stage: —`).

## Plan
- [x] All seven tasks are present, and I found nothing outside the plan. All three extra header trims (`answer-comes-back`, `decision-inbox`, `ship-files-open-findings`) only drop the clause about the removed ceiling. Task 4's "edit the file header where it announces the removed check" covers them.
- [x] Run interdicts, checked one by one:
  - `method/` changes only through `word-budget`.
  - These are untouched: `bin/polype`, `bin/polype-dev-install`, `po/`, `.claude/`, `.polype/`, `tests/lib.sh`, `tests/run.sh`, `tests/overlap.test.sh`, `docs/stories.md`, `AGENTS.local.md`, and the four documents.
  - `po-gate oracle-intact` exits 0, so the oracle's sum still holds.
  - No scratch file is left.

## References
- [x] Each line of `method/word-budget` matches `LC_ALL=C wc -w` on this tree. `po-lint --base origin/main` passes on the real tree. Total is 50158 (< 57589). The four documents are at 1598 / 1735 / 3816 / 1192, today's counts, at or under d-0055's figures.
- [x] `budget_is_not_installed`, by reading `bin/polype`:
  - The project poses lay only `method/{commands,agents,skills,templates,hooks}` (`bin/polype:170-173`), so `word-budget` reaches no project.
  - The global pose copies `method/` whole (`:157-158`), so the payload gets it.
  - Probe (temp `HOME`): after `install --global`, then a reinstall from the payload, `word-budget` was in both `manifest` and `payload.sums`. `polype check --global` reported "none modified", so there was no foreign-file refusal. The payload's `po-lint` passes because it skips the `../` lines.
- [x] The count is `LC_ALL=C wc -w`, and `$((n))` strips macOS's padded output. The exit codes and breach texts match the plan's table in every probe.
- [x] It runs on bash 3.2. The new code uses only `+=`, `$'…'`, `${x#…}` and `< <(…)`, all present in bash 3.1 and later. It has no associative array, no `mapfile`, no `${,,}` and no `&>>`. The awk uses `ENVIRON`, `split` and POSIX classes only.

## Rules
- [x] `AGENTS.md` conventions respected: English code and commit, tests in bash.
- [x] No accepted ADR contradicted. The `po-bounds` base pattern is reused as the plan's `## Reuse` says.

## Tests
- Oracle: `po-gate oracle-intact s205-word-budget-is-linted` → exit 0
- [x] Floor: `po-gate floor-guard s205-word-budget-is-linted main` → exit 1, four `test-file-deleted` flags, each graded below. The guard is right and the plan's expectation (task 7) was wrong. It counts a removed assertion only on `expect(` / `assert` (`.polype/hooks/po-gate.sh`, `assertion()`), and these bash tests assert with `fail`, so removed bash functions never flag. I read every unflagged weakening. Each one removes a word-ceiling function, or the header clause or variable that only it used. Each is named with its reason in plan tasks 3–5. The two heading `grep`s that left with `test_ship_words_go_down` are phrases that no script in `po/`, `bin/` or `method/hooks/` reads (checked).
- [x] Keep-list changes to the oracles of s201–s204 (logged under `## Oracle changes`):
  - Every entry that left names a word-ceiling function.
  - No line of `S203_KEPT_LINES` / `S204_KEPT_LINES` (the d-0052 security assertions) changed.
  - `decision-inbox.test.sh` and `answer-comes-back.test.sh` keep every security function.
  - `LOWERED_COUNTS` `po-gate.sh 136 135` is justified. `security-findings-stay-private.oracle:test_words_hold` only counted the hook's words, so it was a false launch. The allowance expires when s205 lands.
- [x] `scattered_ceilings_are_gone`, checked across all of `tests/`: I grepped for `wc -w`, `wc` in any form, `NF` sums, `ceiling`, and `-le` / `-lt` against numbers of three or more digits. What remains is three `wc -w` on a here-string or on git output, plus time and HTTP-status limits. No word ceiling is left.
- [x] Within `Test budget`: 5 oracle tests plus one assertion. File count is 165, as reported. A plain grep finds 670 `test_` definitions against the reported 662 "as run.sh loads them". The gap comes from definitions in sourced helpers, and I did not chase it.
- [x] Bite (each mutation undone, `git diff --exit-code bin/po-lint` clean):
  - Raise check made to ignore the citation the line already carried → 1 failing (`raising_a_ceiling_is_visible`).
  - `documents_checked` forced to return 1 → 2 failing.
  - "listed twice" rule disabled → 0 failing in the oracle and `lint.test.sh` (finding below).
- [x] Unguarded by the plan's choice, with no successor:
  - The `po-gate.sh` ceiling (5843): no hook under `method/hooks/` has any word ceiling now.
  - `## What goes to the person` (378) and `## Installed files` (516): either can grow as long as `method/AGENTS.md` stays within 3732. Words can move from one section of `AGENTS.md` into another unseen.
  - `docs/harnais.md` (`## Le budget de mots`) says this.

## Neighbours
- [x] Callers of `po-lint`: `tests/lint.test.sh`, the mutant helpers (which lift every ceiling with `sed`), `drive-executes-next.oracle`, and the profile tests in the suite run. `test_lint_fails_when_it_reads_nothing` still holds because `po-lint` stops at 0 files, before `check_budget` runs. CI checks out with `fetch-depth: 0`, so `origin/main` exists for `--base`.

## Lenses
Lenses run: security — asked by the brief (`bin/po-lint` runs git on a caller-given ref and reads paths from a file). No path or content trigger of the table matched.
- [x] What I probed (all failed closed, with `po-lint: no base … : <ref>` and exit 2):
  - Refs `--show-toplevel`, `--output=<tmp>` (no file was written), `-h`, `main;touch …`, `$(touch …)`, `a b`, and a newline.
  - The `^{commit}` suffix keeps a dash ref from being read as an option.
  - `merge-base` and `show` receive only a resolved hash.
- [x] Budget keys reach the shell only quoted, inside `$METHOD/…`. Keys `../../etc/passwd`, `../`, `..//etc/passwd` and `../a/../b` are refused as malformed. A method path holding a space, a leading dash and `$(x)` linted correctly. awk takes its data through `ENVIRON` and calls no `system()` and no pipe.

## Findings
- minor — tests/defects-seen-on-products.oracle.test.sh:0 — `test-file-deleted` flag. Plan task 4 names the file with its reason: its only test was a word ceiling.
- minor — tests/drive-executes-next.test.sh:0 — `test-file-deleted` flag. Plan task 4 names the file with its reason: its only test was a word ceiling.
- minor — tests/qa-lanes-isolated.oracle.test.sh:0 — `test-file-deleted` flag. Plan task 4 names the file with its reason: its only test was a word ceiling.
- minor — tests/ship-files-the-other-findings.oracle.test.sh:0 — `test-file-deleted` flag. Plan task 4 names the file with its reason: its only test was a word ceiling.
- minor — bin/po-lint:12 — `--base` is read only as the first argument. `po-lint method --base nowhere/x` exits 0 with "no breach": the asked-for raise check silently does not run, and the bad ref is never named. The only caller uses the right order. Refusing extra arguments would close it.
- minor — bin/po-lint:386 — `find -type f` skips a symlinked `.md` under `method/`. Such a file escapes the budget: it is not counted, needs no line, and a line written for it is refused as "is no .md file of method/". The other rules do read it.
- minor — bin/po-lint:434 — No test covers these rules: duplicate key, malformed line, unknown key, `../` path with a `..` part, and unrelated base. Disabling "listed twice" fails 0 tests. Without that rule, a second `total` line overrides the first when no `--base` is given. Each behaves as the table says in my probes.
- minor — docs/harnais.md:174 — "`README.md` et `docs/` ne sont plus lus par aucun test" is now untrue. `po-lint`, through `lint.test.sh` and the oracle, counts the four documents of d-0055. The file is in `Owns`; the sentence was left.

## Not verified
- I did not run bash 3.2 or the BSD awk of macOS. My verdict comes from reading the code, and a run on macOS would confirm it.
- I did not check d-0055 and the other `d-NNNN` ids against the inbox, which this review must not read. The owner confirms them.
- I relied on the record for the full-suite pass and the launch counts (`po-lint` 26→28, `polype` 143→144, `po-gate.sh` 136→135). I did not print `test_no_script_lost_its_tests`'s line myself.
- `po missing` in the temp global install is environmental (`po` not built there). I did not exercise `po` from the payload.
- A `../` document line deleted from the budget lifts that ceiling with no decision, and `po-lint --base` does not see it. On this repository, only the oracle's "the four documents have a line" guards that.

Max severity: minor
Ship allowed: yes

Method version: 0.11.0
Recorded: 2026-11-23T00:10:56+01:00

Diff reviewed: `git diff main...story/s205-word-budget-is-linted`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: f970cea91b328c45aeb7d2f961dffaddd6535aba

## Ownership
Listed with `git diff --name-only main...story/s205-word-budget-is-linted` and held against `Owns` (`bin/po-lint`, `method/word-budget`, `tests/`, `docs/harnais.md`, `docs/installation.md`, `bin/polype`).
- [x] Every path is inside `Owns`, apart from the story's own research, plan, record and review. Fix run 1 (6f09800) touched only `bin/po-lint`, `method/word-budget`, two `tests/word-budget-is-linted*` files, `docs/harnais.md` and pipeline evidence.
- [x] No other running lane: `git worktree list` shows only this `story/` worktree.

## Evidence reused
- [x] `po-gate verif-current s205-word-budget-is-linted` → exit 0. I reused the record: `bash tests/run.sh`, exit 0, on tree f026090 (716 s), and did not rerun the full suite. The project has no `Typecheck` command (`—`). "Not proven here" says bash 3 and BSD awk were not run.
- [x] `po-gate qa-current`: not required (`QA stage: —`).

## Plan
- [x] Task 8 (fix run 1) is present and nothing outside it changed. The interdict diff against 4d42324 differs only on `docs/stories.md`, which comes from main's own commits after the rebase (merge base 0e876cb), not from the story.
- [x] The story's note says "Le compte se fait comme `wc -w`". The lead chose awk instead, as an implementation detail. On the real files, awk gives the same counts the forge's older `wc -w` gave (3815 for `../docs/parite-killer-saas.md`). `docs/stories.md` is outside `Owns`, so I raise no finding.

## References
- [x] One counting rule everywhere. `bin/po-lint:372`, the oracle's `words()` (`:23`), the generation command in the plan (task 2), the header of `method/word-budget` and `docs/harnais.md:209` all say `LC_ALL=C awk '{n += NF} END {print n + 0}'`. The new test file sources the oracle's helper. `wc -w` survives only in the comment of `po-lint:368`, the oracle's own `scattered_ceilings` grep, and three non-budget uses (here-string or git output).
- [x] Probes, with gawk 5.4.1 here and mawk 1.3.4 / busybox 1.37 in local containers (`--network=none`). Results are given as gawk / mawk / busybox, with `LC_ALL=C wc -w` 9.12 after the arrow:
  - CRLF `a b\r\nc\r\n\r\n`: 4/4/4 → 3 (a lone `\r` line counts as a word).
  - Form feed and vertical tab: 1/1/1 → 2.
  - NUL `a\0b c`: 2/2/**3** → 2.
  - 300 000-word single line: 300000 everywhere.
  - No final newline: 2 everywhere.
  - Empty file: 0 everywhere.
  - Invalid UTF-8 `\377\376 x`: 2 everywhere.
  - `C2 A0` and `C3 A0` inside a word: 1/1/1 → 2.
  - The real tree: total 50158, documents 1598 / 1735 / 3815 / 1192, the same on all three awks.
- [x] What could still diverge: only NUL (busybox, and probably BSD awk, which stores records as C strings). CR, FF and VT agree across the three awks. The real `.md` files of `method/` and the four documents hold no CR, FF, VT or NUL byte, and no Unicode space (C2 A0, E2 80 A8/A9/AF, E3 80 80). So I found no divergence on a real file.
- [x] Budget: every ceiling equals today's awk count (`test_budget_starts_at_todays_counts` passes). The total is 50158, under 57 589. The four documents (1598, 1735, 3815, 1192) are at or under d-0055. `bash bin/po-lint` reports no breach.
- [x] Arguments, all probed under bash:
  - Usage and exit 2 for: `--base` after the directory, an extra argument, two directories, `--base=x`, a doubled `--base`, and `--`.
  - `--base` with no value names the missing ref. `--base x` alone exits 2 and names `x`.
  - The suite's call is `lint_on --base "origin/$target"` (`tests/lint.test.sh:54`), in the right order. `docs/harnais.md` and `docs/installation.md` show no wrong order.
- [x] Symlinks:
  - A symlinked file inside or outside `method/` is counted, and needs its line.
  - A dangling symlink is skipped silently, and a line written for it is refused.
  - A `.md` under a symlinked directory is not counted (finding below).
- [x] `docs/harnais.md` and the plan:
  - The count rule and the breach table (new usage row) match the code.
  - The oracle's sum is `1729079487 11205`.
  - `tests/run.sh` loads 166 files and 666 `test_` functions.
  - The harnais sentence on `docs/` is now true.

## Rules
- [x] Code and commit are in English, tests are in bash, and no accepted ADR is contradicted.

## Tests
- Oracle: `po-gate oracle-intact s205-word-budget-is-linted` → exit 0
- Oracle: `po-gate oracle-intact s205-word-budget-is-linted` → exit 0. The one `## Oracle changes` row of fix run 1 replaces three `LC_ALL=C wc -w` calls with `words()`, and I confirmed this in the diff: no assertion, message or condition changed, so nothing is weakened.
- [x] `git diff bf7b8b2 HEAD -- tests/` touches only the two `word-budget-is-linted` files. The keep lists of s201–s204 and `LOWERED_COUNTS` are unchanged since fix loop 0.
- [x] Floor: `po-gate floor-guard s205-word-budget-is-linted main` → exit 1, the same four `test-file-deleted` flags. Each is justified in plan task 4, so each is minor (below).
- [x] Within `Test budget`: 9 of 25, as the plan states.
- [x] Bite. I ran only the two s205 files. Each mutation was undone, and `git diff --exit-code bin/po-lint` was clean after each one:
  - `words()` back to `wc -w` → 1 failing (C3 A0 test). It bites only on a coreutils that splits at A0, such as this machine's.
  - Usage check removed → 1 failing.
  - Find without `-type l` → 1 failing.
  - "listed twice" disabled → 1 failing.
  - `bad_path` `..` check disabled → 1 failing.
  - `merge-base` replaced by `rev-parse` → 1 failing (unrelated base).

## Neighbours
- [x] The other callers of `po-lint` (`adr-directory`, `cli-api-profiles`, `expo-profile`, `drive-executes-next.oracle`, `drive-takes-one-story.oracle`) pass zero or one positional argument, so the new usage check does not refuse any of them.

## Lenses
Lenses run: security — asked by the brief, on the changed part of `bin/po-lint`. No path or content trigger of the table matched.
- [x] `words()` reads its argument quoted, and awk gets no program text from input.
- [x] A symlink pointing outside `method/` leaks only a word count. The other rules already read through globbed symlinks and `$METHOD/../boilerplates`. A FIFO or device target fails `[ -f ]` and is skipped.
- [x] The new argument check cannot be bypassed into running the raise check silently.

## Findings
- minor — tests/defects-seen-on-products.oracle.test.sh:0 — `test-file-deleted` flag; plan task 4 names the file with its reason (its only test was a word ceiling).
- minor — tests/drive-executes-next.test.sh:0 — `test-file-deleted` flag; plan task 4 names the file with its reason.
- minor — tests/qa-lanes-isolated.oracle.test.sh:0 — `test-file-deleted` flag; plan task 4 names the file with its reason.
- minor — tests/ship-files-the-other-findings.oracle.test.sh:0 — `test-file-deleted` flag; plan task 4 names the file with its reason.
- minor — bin/po-lint:391 — `find` does not descend into a symlinked directory. A `.md` under `method/skills/<link>/` is not counted and needs no line, and a line written for it is refused as "is no .md file of method/" (probed). `docs/harnais.md:211` says a symlinked `.md` is counted "comme les autres règles le lisent", which holds only for a symlinked file. The oracle's `find -type f` (`:34`, `:143`) also leaves symlinks out of the count-of-day check. No symlink exists in `method/` today.
- minor — bin/po-lint:372 — An unreadable `.md` counts 0 words. Probed: with `chmod 000 method/AGENTS.md`, po-lint prints a permission error on stderr, then "no breach", exit 0. That is fail-open. It was the same with `wc -w` at fix loop 0.

## Not verified
- BSD awk (macOS) and bash 3.2 were not run; my judgement there comes from reading the code. Only NUL handling is expected to differ, and no real file holds NUL.
- On a coreutils that does not split at A0, `test_a_word_holding_a_non_breaking_byte_counts_once` would still pass with `wc -w`, so it guards the rule only on machines like this one.
- d-0055 and the other `d-NNNN` ids were not checked against the inbox, which this review must not read. The owner confirms them.
- I relied on the record for the full-suite pass on the fix tree and did not rerun it.

Max severity: minor
Ship allowed: yes
