---
validated: yes
---
# Plan — s76-bounds-guard-against-mistakes

Branch `story/s76-bounds-guard-against-mistakes`. Read `docs/research/s76-bounds-guard-against-mistakes.md` first. This plan builds on it and does not repeat it. ADR-0052 (`docs/decisions/ADR-0052-po-bounds-est-un-garde-fou-contre-les-erreurs.md`) is already written by the planner and settles every rule below. The implementer commits it with the code and does not rewrite its body.

## Story
`po-bounds` is a guard against an agent's mistakes, not a barrier against deliberate bypass (option A). The story names the accepted bypasses instead of closing them. It stops reading redirections as git paths, and brings `docs/installation.md` up to date with the hook.

The ACs are `bounds_threat_model_is_written`, `redirections_are_not_git_paths`, `installation_matches_the_hook` and `test_variables_are_local` (see `docs/stories.md`, s76).

## Tasks
1. [x] **ADR links (frontmatter only).** Change these lines:
   - ADR-0047 `:9` → `superseded-by: [ADR-0051, ADR-0052]`;
   - ADR-0051 `superseded-by: []` → `superseded-by: [ADR-0052]`;
   - ADR-0034 `superseded-by: []` → `superseded-by: [ADR-0041]`;
   - ADR-0041 `supersedes: [ADR-0037]` → `supersedes: [ADR-0037, ADR-0034]`.

   No other line of these four files changes. Then update the two pins this breaks, because the story changes the clause they check:
   - `tests/bounds.test.sh:589` expects `superseded-by: \[ADR-0051, ADR-0052\]`. Keep the exact-line `grep -qx`.
   - In `tests/post-m7-texts.test.sh:36`, replace the exact `grep -qxF "supersedes: [ADR-$pred]"` with `grep -E '^supersedes:' | grep -qF "ADR-$pred"`, the same form as `:37`.

   Failing test: `test_bounds_threat_model_is_written` (task 6) for the new links; `test_partial_supersession_is_written_and_linked` keeps covering 0041→0037.

2. [x] **Lexer marks redirections** (`lex_command`, `method/hooks/po-bounds.sh`).
   - Per-frame state `rd[f]`: 0 none, 1 file target, 2 dup target. Reset it in `push` and at the end of `endcmd`.
   - Per-word flag `R[f, k]`.
   - In `endword(f)`, when `rd[f] == 2` and the word is unquoted, without substitution, and matches `^([0-9]+-?|-)$`, drop the word (clear it and reset `rd`); it is not stored. Otherwise store `R[f, nw[f]] = (rd[f] > 0)` and reset `rd[f]`.
   - Replace the generic branch at `:523` as follows:
     - if the word in progress is unquoted, holds no substitution and matches `^[0-9]+$`, discard it (it is an fd number); otherwise `endword(sp)`;
     - then consume `>>`, `>|` or `<>` (2 chars, `rd=1`), `>&` or `<&` (2 chars, `rd=2`), or a single `<`/`>` (`rd=1`).
   - Add, just before the `;`/`&` branch at `:486`: `c2 == "&>"` → `endword(sp)`, `rd[sp] = 1`, `i += (c3 == "&>>") ? 3 : 2`.
   - `endcmd`: the type letter becomes `r` when `R[f, k]`, ahead of `c`/`q`/`u`.
   - `cmdpos` skips `R` words.
   - The `ip`/`si` detection and the `work[]` queuing of quoted interpreter words skip `R` words. Keep `sb` as it is (fail-closed).
   - The ordering after `:516-522` (ar, `<(`/`>(`, `<<<`, `<<`) is unchanged. Update the output comment at `:305-308` to list `c`, `q`, `u` and `r`.
   - POSIX awk only.

   Failing test: `test_redirections_are_not_git_paths` (cases `2>/dev/null`, qa `symbolic-ref HEAD 2>/dev/null`). The heredoc tests at `bounds.test.sh:310-316,446-450,479` must stay green.

3. [x] **`check_bash` splits out the redirections.**
   - At `:640-643`, after `read -ra`, move every word whose type is `r` into a `redirs` array (its value without the prefix). `words`/`vals`/`n` then hold only the other words, so every index below is unchanged.
   - Add `check_redirects` next to `check_temp_paths`, taking the shell dir `$1`. For each `redirs` entry:
     - `/dev/null`, `/dev/stdout` and `/dev/stderr` pass;
     - a value holding `\036` or `$`, or starting with `~`, is denied as unreadable;
     - a relative value when `$1` is empty is denied as an unknown dir;
     - otherwise `resolve_path "$(join_dir "$1" "$r")"` and `under_temp`, or deny ``git <verb> redirects to <r>, which lies outside the temp dir``.
   - Call `check_redirects "$cur"` right after `check_temp_paths "$dir" "$j"` (`:704`), and only there.
   - Declare `redirs` local in `check_bash`.

   Failing test: `test_redirections_are_not_git_paths` (cases `> $SCRATCH/out.txt` and `> out.txt` from cwd `$SCRATCH`).

4. [x] **Hook header comment** `:19-33`.
   - Add to the reviewer paragraph: a redirection's target, read from the shell's dir, stays under the temp dir too, or is `/dev/null`, `/dev/stdout` or `/dev/stderr`.
   - After the lexer paragraph (`:35-41`), one sentence: redirections and their fd numbers are not words of the command.
   - One sentence: the hook guards against an agent's mistakes, not against deliberate bypass (ADR-0052).

   Keep each new line under 8 words shared with any outside text (overlap test). Failing test: none of its own (comment); `tests/overlap.test.sh` in the full suite.

5. [x] **`docs/installation.md`.**
   - (a) Lines `:94-96`: rewrite the « et … ni » sentence into two plain sentences. The implementer section must keep `ADR-0050`, `git fetch . HEAD:main`, `GIT_DIR=`, and its heading:
     « Il ne lit pas non plus une variable `$VAR` qui contient `git`, ni un alias git. Pour `implementer` et `qa`, il ne refuse pas `GIT_DIR=… git reset`, `git --git-dir=… reset` ou `git fetch . HEAD:main`. »
   - (b) Rewrite `### Le mode reviewer` `:112-119`, keeping the upgrade paragraph `:121-123` as it is. It must contain these exact phrases:
     - `(ADR-0047, précisée par ADR-0051 et ADR-0052)`;
     - `garde-fou contre les erreurs`;
     - `tout verbe sauf \`push\` et \`send-pack\``;
     - `se résolve sous le répertoire temporaire`;
     - `` `file://<chemin>` ``;
     - `Une redirection n'est pas un chemin de git`;
     - `` `core.worktree` ``;
     - `` `GIT_CONFIG_PARAMETERS=` ``.
   - Content: what the hook is for, and that ADR-0052 lists the accepted deliberate bypasses. The two zones. In the throwaway repo, every path named after the verb (a word, `--opt=valeur`, `-o<valeur>`) resolves under the temp dir, and `file://` is the form for reading outside it. Redirections: `2>/dev/null` and `2>&1` pass, and a file target, read from the shell's dir, stays under the temp dir. Everywhere: `push`, `send-pack`, `--git-dir`, `--work-tree`, `GIT_DIR=`, `GIT_WORK_TREE=`, `core.worktree` by `-c`/`--config-env` in any case, `GIT_CONFIG_PARAMETERS=` and `GIT_CONFIG_COUNT=` are refused, and so is git outside both zones or in an unknown dir.
   - Keep `ADR-0047`, `po-bounds.sh reviewer`, `d'avant s70` and `polype init <projet>`.

   Failing test: `test_installation_matches_the_hook` (task 6).

6. [x] **Tests** (4 new, see the strategy below). Declare `p` local at `tests/post-m7-texts.test.sh:5`, then run `bash tests/run.sh bounds.test.sh installer.test.sh post-m7-texts.test.sh`.

## Run interdicts
- `git diff main...story/s76-bounds-guard-against-mistakes -- docs/decisions/` shows ADR-0052 added, plus exactly one changed frontmatter line in each of ADR-0034, 0041, 0047 and 0051. No body or `status:` line changes.
- In `po-bounds.sh`, `step_dir`, `check_temp_paths`, `check_config_key`, `check_git_read`, `check_restore`, `QA_GIT_VERBS` and the implementer branch are unchanged. **No new deliberate bypass is closed**: `config -zf<path>`, a substitution-built `-c` key, `GIT_CONFIG_GLOBAL`, `pushd` and aliases still pass as before.
- `method/agents/reviewer.md`, `method/AGENTS.md`, `.claude/`, `.polype/` and root `AGENTS.md` have an empty diff.
- `tests/leftovers.test.sh` and `tests/global-install.test.sh` have an empty diff. Existing test lines change only at `bounds.test.sh:589`, `post-m7-texts.test.sh:5` and `post-m7-texts.test.sh:36`.
- No new test file: the Owns has none.
- The headings `### Le hook des bornes de l'implementer` and `### Le mode reviewer` stay as they are.

## The pivot
**Redirections are cut out in the lexer and judged from the shell's dir, rather than whitelisting `/dev/null` in `check_temp_paths`.** Ways this could be wrong:
- **Operator ordering in the awk chain.** A `>` consumed before `>(`, `<<` or `<<<`, or `&>` matched inside the `ar` frame, changes how heredocs and process substitutions are read. Compare with the heredoc and s71 tests, which must stay green. A reviewer mutation that removes the `r` marking should turn `2>/dev/null` red.
- **Dropping the fd number.** `foo2>x` must keep `foo2`, and only an all-digit word is dropped. `2>&1` used to split the command at `&`. Now `&` is consumed, so words after it stay in the same command; check that nothing relied on the split (the implementer `branch` check, qa `--output`).
- **The shell dir `cur` instead of git's `dir`.** `cur` is unknown after a bare `cd` or a substitution, so a relative target is then refused. A legitimate probe writes `cd <tmp>/probe && git log > out.txt` or an absolute temp path, and both pass.

## Files touched
- `method/hooks/po-bounds.sh`
- `tests/bounds.test.sh`, `tests/installer.test.sh`, `tests/post-m7-texts.test.sh`
- `docs/installation.md`
- `docs/decisions/ADR-0034-…`, `ADR-0041-…`, `ADR-0047-…`, `ADR-0051-…` (frontmatter)
- `docs/decisions/ADR-0052-…` (new, written by the planner)
- `docs/research/s76-…`, `docs/plans/s76-…`, `docs/verif/s76-…`

## Test strategy
Policy layer: the hook is fed JSON through `rev_bash`/`qa_status`, never run as commands. There are 4 new tests, within the budget of 25.

1. `test_redirections_are_not_git_paths` in `tests/bounds.test.sh`, under a `# s76 —` header, using `reviewer_lane`.
   - Exit 0:
     - `git -C $TMPROOT/probe log 2>/dev/null`
     - `git -C $TMPROOT/probe log >/dev/null`
     - `git -C $TMPROOT/probe log &>/dev/null`
     - `git -C $TMPROOT/probe log 2>&1 | head`
     - `git -C $TMPROOT/probe log > $TMPROOT/out.txt`
     - `cd $TMPROOT/probe && git log > out.txt`
     - `qa_status Bash command "git -C $WT symbolic-ref HEAD 2>/dev/null"`
   - Exit 2:
     - `git -C $TMPROOT/probe log > $SCRATCH/out.txt`
     - `git -C $TMPROOT/probe log 2> $SCRATCH/err.txt`
     - `git -C $TMPROOT/probe log > out.txt` (cwd `$SCRATCH`, the main checkout)
   - It bites on task 2 (the `2>/dev/null` case) and on task 3 (the `$SCRATCH/out.txt` cases).
2. `test_bounds_threat_model_is_written` in `tests/bounds.test.sh`.
   - ADR-0052 (`ls …/ADR-0052-*.md`) exists. Its frontmatter has `supersedes: [ADR-0047, ADR-0051]` and `status: accepted`.
   - Its body contains: `garde-fou contre les erreurs`, `-zf<chemin>`, ``la portée d'un `cd` ``, `un alias git`, `les hooks d'un dépôt jetable`, `` `GIT_CONFIG_GLOBAL` ``, `une clé construite par substitution`, `bac à sable`.
   - The `superseded-by:` line of ADR-0047 and of ADR-0051 contains `ADR-0052`.
   - ADR-0034's `superseded-by:` contains `ADR-0041`, and ADR-0041's `supersedes:` contains `ADR-0034`.
   - ADR-0047, 0051 and 0034 still have `status: accepted`.
3. `test_installation_matches_the_hook` in `tests/installer.test.sh`.
   - It extracts the `### Le mode reviewer` subsection (same awk as `post-m7-texts.test.sh:6`) and checks that it holds the eight phrases of task 5b.
   - `! grep -qF 'un alias git, et, pour'` on the whole doc.
4. `test_test_variables_are_local` in `tests/post-m7-texts.test.sh` (the AC's name, prefixed as every test is).
   - Awk over the file itself: in each `test_*()` function, every `for <var> in` must have `<var>` among the names on that function's `local` lines.
   - It bites if `p` is removed from `:5`.

Changed pins (the story changes their clause): `bounds.test.sh:589` and `post-m7-texts.test.sh:36` (task 1).

Run: each task's test files only, then the full suite once at the end through `po-run --story s76-bounds-guard-against-mistakes --label test -- 'bash tests/run.sh'`. No type check, E2E or build exists (`—`).

## Done when
- Every AC test passes, and `bash tests/run.sh` is green through `po-run`, `tests/overlap.test.sh` included.
- `docs/verif/s76-bounds-guard-against-mistakes.md` is complete.
- One commit on `story/s76-bounds-guard-against-mistakes` holds code, tests, ADR-0052, research, plan and record.
- The review has no open critical finding.
- After ship, the installed copies are refreshed by the usual refresh commit.
