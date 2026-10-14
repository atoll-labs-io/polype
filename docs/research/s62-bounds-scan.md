# Research — s62-bounds-scan

[Story](../stories.md)

## Structuring facts
- No false assumption in the story. Every claim was opened and confirmed: the word analysis (`method/hooks/po-bounds.sh:224-228`), the qa holes (`:248-257`) and the movable base (`:58-80`, ADR-0038 Neutral).
- `check_bash` removes every quote, turns `$(`, `;&|()`{}` and newlines into spaces, then reads the whole command as one list of words (`method/hooks/po-bounds.sh:224-228`). It does not know about quotes, heredocs or simple commands. So `grep -rn "git checkout" docs` and a heredoc body citing `git push` exit 2 (probed).
- `git branch -f main HEAD`, `git update-ref refs/heads/main HEAD` and `git -C <main worktree> reset --hard HEAD` exit 0 today (probed). They move the branch whose merge base gives the `Owns` (`story_base`, `:58-80`).
- Mode qa allows `git symbolic-ref HEAD refs/heads/x`, `git diff --output=src/x` and `git log --output x` (probed). The allowlist checks the verb only (`:219`, `:253-256`).
- The story asks for a structural replacement of ADR-0024's Bash analysis. The planner wrote ADR-0039 (reserved number): an awk lexer. Bash cannot do it, because a char loop on a long heredoc body is quadratic.

## Story
Text that a command writes into a file or cites in a quoted argument must no longer count as a git command. Real verbs stay refused, including after `&&` or `;` and inside `$(…)`. Mode qa refuses the writing forms of its allowlist. Mode implementer refuses the moves of a branch other than `story/<id>`.
AC: `bounds_ignore_heredoc_bodies`, `bounds_ignore_quoted_arguments`, `bounds_still_catch_real_verbs`, `qa_allowlist_refuses_writing_forms`, `bounds_refuse_moving_a_branch`.
Owns: `method/hooks/po-bounds.sh`, `tests/bounds.test.sh`.

## Current code
`method/hooks/po-bounds.sh` (304 lines):
- `:1-17` is the header comment, describing each mode. `:9-10` lists the implementer's forbidden Bash; `:13-14` describes the qa allowlist. Both must be updated.
- `:20` `deny` prints to stderr and exits 2. `:23` the EXIT trap turns any other status into 2 (fail closed).
- `:26-35` `story_of_dir <msg> <dir>` sets TOP and STORY, or denies unless `<dir>` is a linked worktree on `story/?*`.
- `:58-80` `story_base`: BASE = `merge-base HEAD <main worktree branch> [its upstream]` (ADR-0038).
- `:217` `join_dir <cur> <path>` returns an absolute path as is, otherwise joins it to `cur`.
- `:219` `QA_GIT_VERBS` lists the qa reading verbs, space-padded.
- `:221-275` `check_bash <cmd> <cwd> <mode>`:
  - `:224-228` strips quotes and separators, then `read -ra words`.
  - `:233-236` a word `cd` followed by a word updates `cur`, anywhere in the command.
  - `:237` `git` or `*/git` anywhere is a git call.
  - `:238-246` skips git options: `-C <dir>` sets `gdir`; `-c`, `--git-dir`, `--work-tree`, `--namespace` take 2 words; any other `-*` takes 1.
  - `:248-257` qa: `worktree` must be followed by `list`; otherwise the verb must be in `QA_GIT_VERBS`.
  - `:259-268` implementer: `switch|checkout|stash|push` and `worktree add` are denied. `commit` resolves its dir (`-C` joined to `cur`, else `cur`) and calls `story_of_dir`.
  - `:270` resumes the scan after the verb: the git call's arguments are rescanned as words of the whole command.
- `:297-300` the Bash dispatch: `cmd` comes from `.tool_input.command`, `cwd` from `.cwd`, then `check_bash "$cmd" "$cwd" "$mode"`.

`tests/bounds.test.sh` (304 lines, 12 tests, all green at the start):
- `:10-32` `lane` builds a scratch repo with stories s01-demo, s02-bare, s03-en and s99-ghost, each with a linked worktree. `WT` is the s01-demo worktree.
- `:34-37` `hook_input <tool> <field> <value>` builds the JSON with `cwd` = `$SCRATCH`, the main worktree. Through `jq --arg`, a multi-line command, heredocs included, travels intact.
- `:40-47` `status_with`, `bounds_status`, `bounds_stderr`, `bash_status`, `expect`. `:156` `qa_status`.
- `:103-121` `test_bounds_deny_forbidden_git_verbs` holds the current deny/allow cases. They must stay green unchanged.
- `:167-172` the qa Bash cases: `git -C $WT rev-parse 'story/s01-demo^{tree}'` must stay 0. Its verb follows an unquoted `git`, and its quoted argument is the refspec.

## Attachment points
- Replace the word split `:224-228` and the scan `:229-273` with a lexer that outputs simple commands, and a loop over them.
- `commit` (`:262-267`) is extended into a list of branch-moving verbs that share its dir resolution.
- qa: add `symbolic-ref` and `--output` checks next to the allowlist test (`:253-256`).
- Header `:9-14`.

## Verified interfaces
- Hook contract (`:16-17`): exit 0 allows, exit 2 denies with the reason on stderr; any other status is turned into 2 by the trap (`:23`).
- `story_of_dir` takes a message and a directory, and must receive an existing directory (`commit` checks `[ -d "$dir" ]` first, `:265`).
- `jq -er '.tool_input.command | strings'` (`:298`) returns the command with its embedded newlines.
- `tests/lib.sh`: `scratch_repo`, `fail`, `contains`. `tests/run.sh <file>` runs one file.
- Tooling here: `/usr/bin/awk` is gawk 5.4.1. There is no mawk, BWK awk or busybox awk on this machine, so macOS awk cannot be checked here.

## Traps
- **Portability.** The hook runs on the user's machine: macOS `/bin/bash` 3.2 and BWK awk. Do not use gawk extensions (`gensub`, `length(array)`, `\x` escapes, `printf "%c", 0`, `IGNORECASE`, `RT`). Do not use bash 4+ features (`mapfile`, `declare -n`, `${x,,}`, associative arrays). The s61 review already left "bash 3.2 not verified" open (`docs/reviews/s61-bounds-owns.md`, Not verified).
- **Word wrappers.** The current scan finds `git` anywhere, so `env git push`, `xargs git checkout`, `timeout 5 git push`, `{ git push; }` and `find -exec git checkout {} \;` are refused. A lexer that only looks at command position would lose that. ADR-0039 keeps "unquoted `git` anywhere in the simple command".
- **Quoted values still count inside a git call.** `git -C "$WT" commit` must use the path, and `git "checkout"` is a checkout. Quoting only decides whether a word *can be* the `git` word.
- **`sh -c '…'` / `bash -c` / `eval`.** Their quoted argument is a command. Not rereading it would let `bash -c "git push"` through, which is refused today.
- **Unquoted heredoc.** Bash runs `$(…)` and backticks in its body, so Markdown with backticks around `git push`, written through `<<EOF`, would really run. It must stay refused.
- **`$((1<<2))`.** Taken for a heredoc opener, it would swallow the following lines. That is a fail-open, hence the "shift inside `$((`" rule and the refusal of an unterminated heredoc.
- **Pre-existing exception.** `printf 'then git commit\n'` exits 0 today only because stripping `\` turns the word into `commitn`. The new lexer reaches 0 for the right reason.
- **Existing tests.** `test_bounds_deny_forbidden_git_verbs` (`:103-121`) and the qa cases (`:167-172`) pin today's behaviour on unquoted forms; they must pass untouched. `cd $WT && git commit -m x` (`:115`) must stay 0. The `cd` tracking across simple commands stays as it is.
- **Neighbouring docs not in Owns.**
  - `docs/installation.md:83-87` lists the implementer's forbidden git commands. It will miss the new branch-moving refusals.
  - s65 owns `docs/installation.md`.
  - `method/agents/implementer.md:55` (a po-bounds refusal is a stop) stays true.
- **ADR-0024 / ADR-0026** are accepted and are never edited. ADR-0039 replaces their points in its body, with `supersedes: []` as ADR-0038 did. The s61 review notes that frontmatter links then miss the partial supersession (`docs/reviews/s61-bounds-owns.md`, minor).
- No migration, no screen, no dependency (`jq` and `awk` are already required or universal), no API contract.

## Open questions
- Should `git branch -d` (non-forced delete) and `git branch -m` (rename) of the main branch also be refused? Renaming the main branch makes `story_base` deny (fail closed), so ADR-0039 leaves them allowed.
- `GIT_DIR=… git reset`, `git --git-dir=… reset` and `git fetch . HEAD:main` still move a branch unseen. ADR-0039 lists them as accepted gaps, within the error-not-hostility model. Should a later story close them?
- BWK awk / bash 3.2 behaviour cannot be run here. The record must list it under "Not verified".

## Complexity
Story 3 → **4**. The rule changes are small, but a shell lexer (quotes, `$'…'`, heredocs with quoted and unquoted delimiters, nested substitutions, interpreter re-lexing, fail-closed edges) is the riskiest code in the hook. It must also stay portable across three awks without a way to test two of them here.

## Split
Not required (score 4). If it ran long, the qa allowlist refinements (AC 4) are independent and could ship alone.
