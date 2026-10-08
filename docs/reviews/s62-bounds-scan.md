# Review: s62-bounds-scan

I reviewed `git diff main...story/s62-bounds-scan` in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 1
Reviewed tree: f20ae8457b8ce128a9b8c4fe682430f8a130f74d

## When blocked
Not blocked. I took the tree again just before answering and it had not changed (f20ae845…). The worktree is clean, and every mutation I made was undone and confirmed with `git diff --exit-code method/hooks/po-bounds.sh`.

**Incident to report.** My first probe script had an outer heredoc whose delimiter (`EOF`) also appeared inside the probe cases. It closed early, and the rest of the probe text ran as real commands in my session shell, in `/home/lecrabe/dev/atoll/polype` on `main`:
- `git push` ran six times (directly, and through `zsh -c`, `bash -lc` and `sh -c`). Each printed "Everything up-to-date".
- A few harmless `cat` and `echo` commands ran, plus `bash script.sh`, which failed because the file does not exist.
- An `xargs` blocked on stdin. I killed the parent shell first and then the `xargs`, so the lines after it never ran. Those included `git --no-pager checkout x`, `GIT_DIR=x git push` and `cat f | bash`.

Afterwards I checked: `main` is still `28bcaf6`, `## main...origin/main` shows it level with its remote, and the reflog has no new entry. Nothing was pushed or changed. I redid every probe afterwards with the cases stored as data only.

## Ownership
`git diff --name-only main...story/s62-bounds-scan`:
- [x] `method/hooks/po-bounds.sh` and `tests/bounds.test.sh` are inside `Owns`.
- [x] The research, plan, verif and review files are this story's own pipeline evidence.
- [x] `docs/decisions/ADR-0039-…md` is added (status `A`) and named by the plan, so it is in scope by construction.
- [x] One other lane is running: s64-qa-routing. It owns `method/commands/*` and `tests/qa-fleet.test.sh`, so there is no overlap.

## Evidence reused
- [x] `po-gate verif-current s62-bounds-scan` exits 0. The record is complete, and its unit suite (`bash tests/run.sh`) exited 0 on this code, so I did not rerun the full suite.
  - Type check, e2e and build: the project has none (`Typecheck: —`, `E2E: —`, `Build: —`).
- [x] I read "Not proven here": BWK awk and mawk, bash 3.2, the installed copy on a real lane, the qa mode under the C1/M1 forms, and the gaps listed for script files, `bash <(…)` and a quoted `git` behind a wrapper option.
- [x] As a baseline before the mutations, I ran `bash tests/run.sh bounds.test.sh`: 17 passed, 0 failed.
- [x] There is no screen, so no QA was required.

## Plan
- [x] Tasks 1–7 are present.
- [x] The fix commit `a54a0dd` handles the earlier findings:
  - C1: a heredoc fed to a shell is now read as commands, and a shell reading a pipe without `-c` is refused.
  - M1: a quoted command word now counts past wrappers and assignments; nested backquotes are refused; `watch` and `su` are treated as interpreters.
  - M2: the quoted `git` forms are now tested.
- [x] The run interdicts still hold:
  - The protected functions, the dispatch and `QA_GIT_VERBS` are untouched.
  - The 12 earlier tests are unchanged; the new tests are appended after them.
  - The other ADRs and the installed copies are untouched.
  - There is no gawk-only construct and no bash 4-only construct.
- [ ] Some of the new behaviour is not in ADR-0039: the shell-heredoc reading, the pipe refusal, the nested-backquote refusal, the extra interpreters, and a quoted command word past wrappers where the ADR says "cité seulement en première place". The hook header documents the real behaviour (m1).

## References
- [x] `join_dir`, `story_of_dir`, `deny` and `QA_GIT_VERBS` exist with the signatures used. `lex_command` is defined before `check_bash`.

## Tests
- [x] Floor: `po-gate floor-guard s62-bounds-scan main` exits 0.
- [x] Every test calls the real hook with real JSON. There are no mocks and none of the six kinds of test that prove nothing.
- [x] 5 new test functions, 17 in the file, within the budget of 25.
- [x] Bite. Each mutation ran against `bounds.test.sh` only, and each was undone and confirmed:

| Mutation (`method/hooks/po-bounds.sh`) | Failing tests |
| --- | --- |
| `:282` a shell's heredocs are never marked to be read | 1 (`bounds_ignore_heredoc_bodies`) |
| `:280` the pipe-to-shell refusal is removed | 1 (`bounds_ignore_quoted_arguments`) |
| `:271` a quoted command word is typed `q`, not `c` | 1 (`bounds_still_catch_real_verbs`) |
| `:356` a nested backquote is read as a literal | 1 (`bounds_ignore_quoted_arguments`) |
| `:279` a substitution handed to an interpreter is allowed | 1 (`bounds_ignore_quoted_arguments`) |

Every rule I disabled is caught by at least one test.

## Probes (implementer mode, new hook vs the old installed hook)
- **Still refused, as before:** `$((1<<2)); git push`, `case` inside `$(…)`, `${x:-$(git push)}`, `{ …; }`, `xargs`, `find -exec`, `timeout`, `sudo`, `nice`, `if`/`for`/`while`, function bodies, `!`, `&`, `coproc`, `/usr/bin/git`, `git pu"sh"`, `"g"it push`, `env FOO=1 bash -c`, `source <(…)`, `eval "$(…)"`, and both orders of `bash <<A && cat <<B`.
- **Now allowed, correctly:** comments (`echo # git push`), quoted and unquoted heredocs written to files, Markdown with escaped backticks, `cat << 'E O F'`, and a heredoc nested inside a quoted `bash` heredoc.

## Neighbours
- [x] `method/agents/implementer.md` and `method/agents/qa.md` invoke the hook. Their rule "a refusal is a stop" still holds.
- [x] `docs/installation.md` still lacks the new refusals. s65 owns that file and depends on s62, so it is not a finding here.

## Lenses
Lenses run: Security. The diff changes a guard that decides which git commands an agent may run (the content trigger "a check on who may … change a record"). No migration, dependency or performance trigger is present.

## Findings
- **major (M1)** — `method/hooks/po-bounds.sh:302-305` (`heredocs()` queues the raw body): when a shell reads an unquoted-delimiter heredoc, the body is lexed as typed, not as bash expands it first.
  - Bash would turn `` \` `` into `` ` `` before the inner shell runs. Probed: `bash <<EOF` + `` echo \`git push\` `` + `EOF` exits **0**, and the old hook refused it. So the inner shell would run `git push`.
  - `\$(…)` is caught only because `(` happens to be a separator.
  - Same class, also exit 0 where the old hook refused:
    - `env -u X "git" push` and `sudo -u x "git" push` (a quoted `git` after a wrapper's option argument);
    - `cat <<'EOF' > f.sh` + `git push` + `EOF` followed by `bash f.sh` in the same command.
  - The record lists the last two as known, but ADR-0039's accepted gaps list none of the three. The plan's pivot 2 forbids losing refusals.
  - Most of these need deliberate quoting, or are the trade-off the story itself chose, so this is major, not critical.
  - Fix: unescape `` \` ``, `\$` and `\\` in an unquoted body before re-lexing it, and record the remaining cases as accepted gaps in a superseding ADR.
- **minor (m1)** — `docs/decisions/ADR-0039-po-bounds-lit-les-commandes-hors-guillemets-et-heredocs.md` no longer matches the code after the fix run.
  - It says a quoted `git` counts "seulement en première place" and lists only `sh bash zsh dash ksh eval`.
  - The code counts a quoted command word after wrappers, re-reads `watch`/`su`/`mksh`/`ash`/`fish`, reads a shell's heredocs, and refuses pipe-to-shell, nested backquotes and a substitution handed to an interpreter.
  - The hook header (`:20-24`) is accurate. The ADR is still unshipped, but it is marked `accepted`, so its text should be brought in line before merge or superseded.

## Not verified
- **BWK awk (macOS) and mawk; macOS `/bin/bash` 3.2.** Only gawk 5.4.1 and bash 5 are on this machine. A person should run `bash tests/run.sh bounds.test.sh` on macOS and on a mawk system.
- **Which shell runs the Bash tool's commands.** The user's login shell is zsh, and zsh differs on comments, `=cmd` and globbing. A person should confirm that Claude Code runs the commands through bash, or probe the zsh forms.
- **The refreshed hook on a real lane.** Only scratch repos and `cwd=/tmp` probes ran. After the next install refresh, run one implementer session that hits a refusal.
- **qa mode under the probe forms.** I checked only the first few cases in qa mode. qa shares the lexer, so the M1 forms are expected to pass there too.
- **Branch-moving gaps the ADR accepts** (`GIT_DIR=…`, `--git-dir`, `git fetch . HEAD:main`). They are accepted by design and I did not probe them.
- **Performance on large bodies.** I did not re-time it after the fix. The earlier review measured 0.04–0.21 s on 60 KB.

Max severity: major
Ship allowed: yes
