---
validated: yes
---
# Plan — s62-bounds-scan

[Story](../stories.md) · [Research](../research/s62-bounds-scan.md)

Branch `story/s62-bounds-scan`. Read `docs/research/s62-bounds-scan.md` first; this plan builds on it without repeating it. The design is fixed by `docs/decisions/ADR-0039-po-bounds-lit-les-commandes-hors-guillemets-et-heredocs.md`, which the planner wrote and the implementer commits with the code.

## Story
`po-bounds` must stop treating text as a git command when a command only writes or cites it: heredoc bodies and quoted arguments. Real verbs stay refused. Mode qa refuses the writing forms of its allowlist. Mode implementer refuses moves of a branch other than `story/<id>`.

Acceptance criteria:
- `bounds_ignore_heredoc_bodies`
- `bounds_ignore_quoted_arguments`
- `bounds_still_catch_real_verbs`
- `qa_allowlist_refuses_writing_forms`
- `bounds_refuse_moving_a_branch`

## Tasks
1. [x] **Lexer.** Add to `method/hooks/po-bounds.sh` one function that runs a POSIX awk program on the command (fed on stdin) and prints one simple command per line.
   - **Output format.** Words are separated by `\037`. Each word is prefixed with `u` (no quoted part) or `q` (some part was quoted). A line `!<reason>` means the command is unreadable. Newlines inside a word become spaces, and any `\037` in the input is replaced by a space.
   - **Rules, as ADR-0039 lists them:**
     - separators: `;` `&` `|` `(` `)`, newline;
     - `$(`, backticks, `<(` and `>(` open nested commands. They are read wherever they appear: unquoted, inside `"…"`, or in an unquoted-delimiter heredoc body;
     - `'…'` is literal. `$'…'` is literal with backslash escapes. `"…"` is literal except `\`-escapes and substitutions;
     - a backslash outside quotes escapes the next character, and a backslash-newline joins the two lines;
     - `#` at the start of an unquoted word starts a comment that runs to the end of the line;
     - `<<` / `<<-` (not `<<<`) queues a heredoc. Its body is skipped from the next newline to the delimiter line (with leading tabs stripped for `<<-`). With an unquoted delimiter, only the body's substitutions are lexed. Inside `$((…))`, `<<` is a shift;
     - a simple command holding an unquoted word whose basename is `sh`, `bash`, `zsh`, `dash`, `ksh` or `eval` gets each of its `q` words re-lexed as commands. Use a worklist, not awk recursion with local arrays;
     - an unterminated quote or an unterminated heredoc → `!` line.
   - **Portability.** No gawk extensions, as listed in the research traps.
   - **Test that fails if it is wrong:** `test_bounds_ignore_heredoc_bodies` and `test_bounds_ignore_quoted_arguments` (task 6).
2. [x] **Scan per simple command.** Rewrite `check_bash` (`:221-275`) to deny on a `!` line (`po-bounds cannot read this command: <reason>: $cmd`), then loop over the simple commands in order, keeping `cur` across them.
   - Inside a simple command, `cd <word>` updates `cur` as today (`:233-236`).
   - A word is a git call when its value is `git` or `*/git` and it is either `u`, or `q` in first position.
   - The option skipping of `:238-246` is unchanged, applied to the word values.
   - The git call's arguments end at the end of its simple command.
   - Today's implementer and qa verb rules (`:248-268`) are kept as they are.
   - **Test that fails if it is wrong:** `test_bounds_still_catch_real_verbs`, plus the existing `test_bounds_deny_forbidden_git_verbs` and the qa Bash cases (`:167-172`).
3. [x] **Branch moves (implementer).**
   - `update-ref` → deny.
   - `branch` with any argument among `-f`, `--force`, `-D`, `-M` or `-C`, or a short-option cluster `-[A-Za-z]*` containing `f`, `D`, `M` or `C` → deny.
   - `commit|reset|merge|rebase|cherry-pick|revert|am|pull` → the existing `commit` dir resolution and `story_of_dir` check (`:262-267`), with a message naming the verb: `git <verb> outside a story/<id> branch: $cmd`.
   - **Test that fails if it is wrong:** `test_bounds_refuse_moving_a_branch`.
4. [x] **qa writing forms.** In mode qa, before the allowlist check:
   - any argument of the git call equal to `--output` or starting with `--output=` → deny;
   - for `symbolic-ref`, any option other than `-q`, `--quiet`, `--short`, `--recurse` or `--no-recurse`, or more than one non-option argument → deny.
   - `QA_GIT_VERBS` (`:219`) is unchanged.
   - **Test that fails if it is wrong:** `test_qa_allowlist_refuses_writing_forms`.
5. [x] **Header.** Rewrite `:9-14` of `po-bounds.sh` to say:
   - text quoted or in a heredoc body is not read;
   - the implementer's branch-moving refusals;
   - the qa `symbolic-ref` / `--output` limits.
   - Cite ADR-0039 there, as `:7` cites ADR-0038.
   - Check: read it against ADR-0039. No test.
6. [x] **Tests.** Append the five functions below to `tests/bounds.test.sh`, after the s61 block, under a `# s62 —` comment, using `lane`, `bash_status`, `qa_status` and `expect`. Each heredoc command is built with `$'…'` or a variable that holds real newlines.
   - `test_bounds_ignore_heredoc_bodies`:
     - → 0: `cat > $WT/docs/x.md <<'EOF'` with body `git checkout main` / `git push` / `EOF`;
     - → 0: the same with an unquoted `EOF` and plain text;
     - → 0: `cd $WT && git commit -F - <<'EOF'` whose body says `then git push`;
     - → 2: `git -C $SCRATCH commit -F - <<'EOF'` (the opener is read);
     - → 2: a command line `git push` after the `EOF` line;
     - → 2: an unquoted heredoc whose body holds `$(git push)`;
     - → 2: an unterminated heredoc followed by `git stash`.
   - `test_bounds_ignore_quoted_arguments`:
     - → 0: `grep -rn "git checkout" docs`, `printf 'run git commit then git push'`, `echo "git stash" | wc -l`, `cd $WT && git commit -m "fix; git push"`;
     - → 2: `bash -c "git push"`, `sh -c 'git checkout x'`, `eval 'git stash'`, `grep "unclosed`.
   - `test_bounds_still_catch_real_verbs`:
     - → 2: `true && git checkout x`, `true; git stash`, `echo $(git push)`, `echo "$(git checkout x)"`, `` echo `git stash` ``, `env git push`, `cd $WT && true && git -C $SCRATCH commit -m x`;
     - → 0: `cd $WT && echo ok && git commit -m x`.
   - `test_qa_allowlist_refuses_writing_forms`:
     - → 2: `git -C $WT symbolic-ref HEAD refs/heads/main`, `git -C $WT symbolic-ref -d HEAD`, `git -C $WT diff --output=src/x`, `git -C $WT log --output x`;
     - → 0: `git -C $WT symbolic-ref --short HEAD`, `git -C $WT diff main...story/s01-demo`.
   - `test_bounds_refuse_moving_a_branch`:
     - → 2: `git -C $WT branch -f main HEAD`, `git -C $WT branch -D story/s03-en`, `git -C $WT update-ref refs/heads/main HEAD`, `git -C $SCRATCH reset --hard HEAD`, `git -C $SCRATCH merge story/s01-demo`;
     - → 0: `cd $WT && git reset --soft HEAD`, `git -C $WT branch`.
   - Run with `bash tests/run.sh bounds.test.sh`.
7. [x] **Full suite and record.** Run `.polype/hooks/po-run.sh --story s62-bounds-scan --label "Unit suite" -- "bash tests/run.sh"`. In `docs/verif/s62-bounds-scan.md`, list under "Not verified": BWK awk (macOS) and mawk, and macOS bash 3.2. Commit the code with `docs/research/`, `docs/plans/` and ADR-0039.

## Run interdicts
- In `method/hooks/po-bounds.sh`, these functions keep an empty diff: `story_of_dir`, `resolve_path`, `story_base`, `owns_line`, `check_write`, `unreadable`, `parse_owns`, `check_entry`, `entry_matches`, `check_write_qa`, `join_dir`. The same goes for the dispatch `:277-304`, `deny` and the EXIT trap (`:20-23`), and the `QA_GIT_VERBS` list.
- The 12 existing test functions of `tests/bounds.test.sh` (`:54-304`) and their helpers keep an empty diff; the new tests are appended.
- Files that keep an empty diff:
  - `docs/decisions/ADR-0024-*`, `ADR-0026-*` and `ADR-0038-*` (accepted ADRs);
  - `docs/installation.md` (owned by s65; the gap is reported, not fixed);
  - `method/agents/implementer.md`, `method/agents/qa.md`;
  - `.claude/`, `.polype/`, `AGENTS.md`.
- No new dependency: no `python3`, `perl` or `sed -E` in the hook, and no gawk-only construct (grep the diff for `gensub`, `length(` on an array, `IGNORECASE`, `RT`, `mapfile` and `declare -n`).
- The hook reads no setting.
- No `git switch`, `checkout`, `stash` or `push` by the implementer.

## The pivot
**Rewriting the lexer instead of patching the word scan.** Everything depends on the lexer telling text from command the way bash does, and failing closed where it cannot. Ways it could be wrong:
1. **Fail-open on a construct the lexer misreads.** For example, `$((1<<2))` treated as a heredoc swallows the following lines. Another example: an unbalanced `)` inside `"$(…)"`. Compare against the "→ 2" cases of task 6, and probe constructs the tests do not list, such as `case` inside `$(…)`, `<<<`, `$'it\'s'` and `${x:-$(git push)}`.
2. **Losing a refusal today's scan had.** Wrappers (`env`, `xargs`, `find -exec`), `{ …; }` groups and `bash -c` must still be refused. Compare the new scan with the old `check_bash` on `test_bounds_deny_forbidden_git_verbs` and on each wrapper.
3. **Portability.** gawk accepts constructs that BWK awk or mawk reject or read differently. With only gawk here, the defence is the interdict grep plus a person running the suite on macOS.

## Files touched
- `method/hooks/po-bounds.sh`
- `tests/bounds.test.sh`
- `docs/decisions/ADR-0039-po-bounds-lit-les-commandes-hors-guillemets-et-heredocs.md` (written by the planner)
- `docs/research/s62-bounds-scan.md`
- `docs/plans/s62-bounds-scan.md`
- `docs/verif/s62-bounds-scan.md`

## Test strategy
Five new tests, one per AC, all at the hook layer: the hook is both the policy and its own adapter. Total: 17 functions in the file, 5 for this story, within `Test budget` 25.
- Each test calls the real script through `bash_status` / `qa_status` with the JSON Claude Code sends; no mock.
- **Bite checks the reviewer can run:**
  - make the lexer ignore quotes → `test_bounds_ignore_quoted_arguments` turns red;
  - skip heredoc handling → `test_bounds_ignore_heredoc_bodies` turns red;
  - drop substitution lexing inside `"…"` → `test_bounds_still_catch_real_verbs` turns red;
  - remove the `update-ref` / `branch -f` cases → `test_bounds_refuse_moving_a_branch` turns red;
  - remove the `--output` check → `test_qa_allowlist_refuses_writing_forms` turns red.
- No test is written for the header comment.
- Visual checks: none.

## Done when
- The five AC tests and the 12 existing tests pass (`bash tests/run.sh bounds.test.sh`).
- The full suite is green through `po-run`.
- ADR-0039 is committed with the code in one commit on `story/s62-bounds-scan`.
- The record names what was not verified (other awks, bash 3.2).
- The review has no open critical finding.
