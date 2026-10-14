---
validated: yes
---
# Plan — s71-bounds-heredoc-expansion

[Story](../stories.md) · [Research](../research/s71-bounds-heredoc-expansion.md)

Branch `story/s71-bounds-heredoc-expansion`. Read `docs/research/s71-bounds-heredoc-expansion.md` first; this plan builds on it without repeating it.

Validation: autonomous (`Plan validation: autonomous`), checked against each acceptance criterion below by the planner; no human reviewed it.

## Story
`po-bounds` reads the body of an unquoted heredoc handed to a shell after the expansion bash applies, and counts a quoted `git` placed after a wrapper's option. Fixes M1 and m1 of `docs/reviews/s62-bounds-scan.md`.
- `unquoted_heredoc_is_expanded_before_reading` — `` \` ``, `\$`, `\\` rendered as bash renders them before the body is re-read; `` echo \`git push\` `` refused.
- `quoted_git_after_a_wrapper_option_is_caught` — `env -u X "git" push` and `sudo -u x "git" push` refused.
- `accepted_gaps_are_written_in_an_adr` — an ADR superseding ADR-0039 describes what the reader does and lists the accepted gaps.

Story correction (research, first fact): `bash <(…)` is refused today (`po-bounds.sh:336`, `:479`), so it is not an accepted gap; ADR-0050 says so and lists `source <(…)` among the gaps instead. Research also found a gap the story missed: `bash <<EOF` + `echo '$(git push)'` passes because the outer substitutions of a shell-read body are skipped (`:390`). Task 2 closes it.

ADR-0050 (`docs/decisions/ADR-0050-po-bounds-lit-un-heredoc-comme-bash-le-lira.md`) is already written by the planner, under the number the driver reserved. It fixes the behaviour every task below implements.

## Tasks
1. [x] **Unescape a shell-read unquoted body before queuing it.** In the awk program of `lex_command`, add a function (e.g. `unesc(b)`) placed before `lex()`, that renders an unquoted heredoc body as bash does: `\\` → `\`, `\$` → `$`, `` \` `` → `` ` ``, `\<newline>` → nothing, any other `\` kept. Resolve `\\` first: `gsub` it to `US` (`\037`, never present in a body, `:397`), then `gsub` the three others, then `split` on `US` and rejoin with a literal `"\\"`. No character-by-character concatenation loop (quadratic in BWK awk and mawk) and no backslash in a `gsub` replacement string (differs between awks). At `:388`, queue `qq[qh] ? body : unesc(body)`. Test that fails if wrong: `test_unquoted_heredoc_is_expanded_before_reading`, cases `bash <<EOF` + `` echo \`git push\` `` → 2 and `` echo \\\`git push\\\` `` → 0.
2. [x] **Also read the outer substitutions of a shell-read unquoted body.** At `:390`, skip the body only when `qq[qh - 1] || m == k`; a shell-read unquoted body then gets the `hd` frame too, which reads the `$(`, `$((` and backquotes the outer bash runs. Test: same function, case `bash <<EOF` + `echo '$(git push)'` + `EOF` → 2 (exit 0 today).
3. [x] **Command-word candidates past a wrapper's option.** Rewrite `cmdpos(f)` (`:310-317`) to fill an array `CP` of candidate positions and return the first one (0 when none): skip assignments, options, counts and `WRAP` words as now; remember once a `WRAP` word was seen; when a word that is not skippable directly follows an option word without `=` seen after a wrapper, mark it a candidate and keep scanning (it may be the option's value); otherwise mark it and stop. Assignments are never candidates. In `endcmd()`: type `c` for every `k in CP` (`:328`), `(k in CP)` instead of `k == cp` in the interpreter test (`:330`) and the shell test (`:331`); keep `k > cp` (first candidate) for the `-c` test (`:332`). Test: `test_quoted_git_after_a_wrapper_option_is_caught`.
4. [x] **Header comment.** In `po-bounds.sh`, cite ADR-0050 instead of ADR-0039 at `:30` and `:290`, and say in the header (`:30-34`) that an unquoted heredoc a shell reads is rendered as bash renders it and also read for its outer substitutions, and that a quoted command word counts past a wrapper's option. Keep the lines short; no test (comment only), checked by the reviewer.
5. [x] **ADR-0039 frontmatter.** In `docs/decisions/ADR-0039-po-bounds-lit-les-commandes-hors-guillemets-et-heredocs.md`, set `status: superseded` and `superseded-by: [ADR-0050]` (habit of ADR-0003 → ADR-0018); body untouched. Do not edit ADR-0050: if the code must depart from it, stop and report. Test: `test_accepted_gaps_are_written_in_an_adr`.
6. [x] **Tests.** Append a section `# s71 — a heredoc read as bash will read it; a quoted git past a wrapper's option (ADR-0050).` after the last test of `tests/bounds.test.sh` (`:468`), with the three functions of the test strategy, using `lane`, `bash_status`, `expect`, `require_file`, `contains`. Run `bash tests/run.sh bounds.test.sh`, then the full suite once through `po-run`.

## Run interdicts
- The 21 existing test functions of `tests/bounds.test.sh` end with an empty diff; new tests are appended after `:468`.
- Untouched in `po-bounds.sh`: `QA_GIT_VERBS`, `check_git_read`, `check_restore`, `check_write*`, `story_base`, `owns_line`, `parse_owns`, `check_entry`, `entry_matches`, `check_bash`, the mode dispatch (`:658-689`), and the `BEGIN` lists `SHELLS`, `INTERP`, `WRAP` (`:498-505`).
- No gawk-only construct (`gensub`, `length(array)`, `\y`, `IGNORECASE`, `asort`) and no bash-4-only construct.
- `docs/installation.md` and `tests/installer.test.sh` end with an empty diff: both are outside Owns and `installer.test.sh:186` requires `ADR-0039` in the installation doc.
- ADR-0039: only its `status:` and `superseded-by:` lines change. ADR-0050: empty diff after the planner's version.
- `.claude/`, `.polype/`, `docs/stories.md`, `docs/parite-killer-saas.md`: empty diff.
- Never run a probe whose text contains `git push` outside a hook input built as data (`jq --arg`): the s62 review ran real pushes from a closing heredoc.

## The pivot
Two readings of a heredoc a shell reads with an unquoted delimiter — the outer bash's substitutions on the raw body, and the inner shell's commands on the body rendered as bash renders it — and two readings of the word after a wrapper's option. Both stay fail-closed: a reading that cannot be made refuses. Ways it could be wrong:
- **The rendering differs from bash.** Compare against bash itself on throwaway data: `printf` the body through `cat <<EOF` in a scratch shell for `\\$X`, `` \\\` ``, `a\<newline>b`, `\n` (kept), and check the work string matches. The `\\`-first order is the usual mistake.
- **The `hd` frame on a shell-read body breaks a form that passed** — e.g. a nested heredoc or a backquote in a shell-read body now read by both frames. Compare: the s62 tests at `:308-347` stay green, and `bash <<EOF` + `echo ok` still passes.
- **Candidates leak beyond the git check.** Several `c` words change `si`/`ip`: a candidate that is a shell turns on the pipe refusal (`echo x | sudo -u bash ls` now refused — accepted), and an assignment wrongly marked `c` would escape the reviewer's `[uq]:GIT_DIR=*` check (`:578-579`). Compare: `rev_bash 'sudo -E "GIT_DIR=/x" git log'` must stay refused, and `sudo -u x grep "git" docs` must stay allowed in mode `qa`.

## Files touched
- `method/hooks/po-bounds.sh` (tasks 1–4)
- `tests/bounds.test.sh` (task 6)
- `docs/decisions/ADR-0039-po-bounds-lit-les-commandes-hors-guillemets-et-heredocs.md` (frontmatter, task 5)
- `docs/decisions/ADR-0050-po-bounds-lit-un-heredoc-comme-bash-le-lira.md` (written by the planner)
- `docs/research/s71-bounds-heredoc-expansion.md`, `docs/plans/s71-bounds-heredoc-expansion.md`, `docs/verif/s71-bounds-heredoc-expansion.md`

## Test strategy
Three new test functions in `tests/bounds.test.sh`, one per criterion, each calling the real hook with real JSON (`bash_status`, implementer mode, unless stated). Within `Test budget` (25). Names are the criteria's names.

| Test | Cases (expected exit) | Fails when |
| --- | --- | --- |
| `test_unquoted_heredoc_is_expanded_before_reading` | `bash <<EOF` + `` echo \`git push\` `` → 2; `sh -s <<EOF` + `` x=\$(git stash) `` → 2; `bash <<EOF` + `echo '$(git push)'` → 2; `bash <<EOF` + `` echo \\\`git push\\\` `` → 0; `bash <<'EOF'` + `` echo \`git push\` `` → 0; `cat > $WT/docs/x.md <<EOF` + `` see \`git push\` `` → 0 | task 1 removed (case 1); task 2 removed (case 3); unescape that drops every backslash or resolves `\$` before `\\` (case 4); a quoted body unescaped (case 5); plain-text heredocs read as commands (case 6) |
| `test_quoted_git_after_a_wrapper_option_is_caught` | `env -u X "git" push`, `sudo -u x "git" push`, `nice -n 5 'git' push`, `sudo -u x "bash" -c "git push"` → 2; in mode `qa` (`qa_status Bash command`, `:156`), `sudo -u x grep "git" docs` and `env -u X grep -n "git" docs` → 0 | the keep-scanning rule removed (refusals); every word after a wrapper made a candidate (the `qa` cases: `git docs` is no reading verb) |
| `test_accepted_gaps_are_written_in_an_adr` | `require_file` ADR-0050; `contains` ADR-0050: `supersedes: [ADR-0039]`, `**Lecture des heredocs**`, `**Refus du pipe vers un shell**`, `**Interprètes reconnus**`, `un script écrit puis lancé`, `` `bash <(…)` ``, `un alias git`, `` `GIT_DIR=…` ``; `contains` ADR-0039: `superseded-by: [ADR-0050]`, `status: superseded` | the ADR or the supersession link missing |

Build each heredoc command with `$'…'` as the s62 tests do (`:310-319`). Bite is the reviewer's to prove (ADR-0012). No visual check: no screen.

Checks: `bash tests/run.sh bounds.test.sh` after task 6; the full suite (`bash tests/run.sh`) once at the end through `po-run --story s71-bounds-heredoc-expansion --label test -- 'bash tests/run.sh'`. No type check, e2e or build in this project.

## Done when
- The three criteria's tests pass and the full suite is green, recorded in `docs/verif/s71-bounds-heredoc-expansion.md`.
- One commit on `story/s71-bounds-heredoc-expansion` carrying the code, the tests, ADR-0050, the ADR-0039 frontmatter and this pipeline evidence.
- A review with no open critical finding, then one squash commit on `main`.
