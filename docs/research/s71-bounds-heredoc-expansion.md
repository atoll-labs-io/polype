# Research — s71-bounds-heredoc-expansion

[Story](../stories.md)

## Structuring facts
- **Story assumption false:** `bash <(…)` is not an accepted gap, it is refused today: `<(` marks the word as holding a substitution (`method/hooks/po-bounds.sh:479`, `:302`) and a substitution handed to an interpreter fails (`:336`). Probed: `bash <(cat f)` → exit 2. The real member of that family that passes is `source <(cat f)` (exit 0): `source` and `.` are not interpreters (`:500-502`). The ADR must say so; `docs/stories.md` needs the same correction by a human.
- **Second gap, not in the story:** a heredoc a shell reads is lexed only as the inner shell sees it; the substitutions the *outer* bash runs while building the body are skipped (`:390`, `qi[qh-1]` jumps past the `hd` frame). Probed: `bash <<EOF` + `echo '$(git push)'` + `EOF` → exit 0, yet bash runs `git push` before `bash` starts. The same fix family closes it.
- M1 confirmed: `heredocs()` queues the raw body (`:388`), so `` echo \`git push\` `` in an unquoted body fed to `bash` → exit 0.
- m1 / AC2 confirmed: `cmdpos()` (`:310-317`) stops at the first word that is not an assignment, option, count or wrapper, so in `env -u X "git" push` the command word is `X` and the quoted `git` is typed `q`, which `check_bash` ignores (`:591`). Probed: exit 0 for `env -u X` and `sudo -u x`.
- Both fixes stay inside the awk lexer; prototypes on a temp copy closed every probe above and kept the 21 tests of `tests/bounds.test.sh` green.

## Story
`po-bounds` must read the body of an unquoted heredoc handed to a shell after the expansion bash applies, so a `` \`git push\` `` no longer slips through. Fixes M1 and m1 of `docs/reviews/s62-bounds-scan.md`. Complexity 3, depends on s70, Owns `method/hooks/po-bounds.sh`, `tests/bounds.test.sh`.
- `unquoted_heredoc_is_expanded_before_reading` — `` \` ``, `\$`, `\\` rendered as bash renders them before re-reading; `` echo \`git push\` `` refused.
- `quoted_git_after_a_wrapper_option_is_caught` — `env -u X "git" push` and `sudo -u x "git" push` refused.
- `accepted_gaps_are_written_in_an_adr` — an ADR superseding ADR-0039 describes what the reader really does (shell heredocs, pipe-to-shell refusal, recognised interpreters) and lists the accepted gaps.

## Current code
`method/hooks/po-bounds.sh` (689 lines), mode dispatch `:658-689`; Bash goes to `check_bash` (`:560-656`), which runs `lex_command` (`:291-512`, one awk program) and walks its output.
- Lexer output: one simple command per line, words joined by `\037`, each prefixed `c` (command word), `q` (some part quoted) or `u` (`:328`). A line `!reason` refuses the whole command (`:564-566`).
- `check_bash` treats a word as a git call when it is `git`/`*/git` and not typed `q` (`:591`): unquoted `git` anywhere counts, quoted only as the command word.
- `endcmd()` (`:322-343`): `cp = cmdpos(f)`; `ip` when an unquoted word or the command word is in `INTERP` (`:330`); `si` when the command word is in `SHELLS` (`:331`); refusals for a substitution handed to an interpreter (`:336`) and a shell reading a pipe without `-c` (`:337`); quoted words of an interpreter queued as work (`:338`); a shell's heredocs marked `qi` (`:339`).
- `opener()` (`:345-373`) reads the delimiter; `qq` = delimiter quoted.
- `heredocs()` (`:377-395`): collects each body line by line (tabs stripped for `<<-`), queues it whole when `qi` (`:388`), then skips the body when `qi || qq || empty` (`:390`), else pushes an `hd` frame that reads only `$((`, `$(` and backquotes and skips `\x` pairs (`:416-423`).
- `END` lexes the command, then every queued work string as a fresh command (`:507-510`). `lex()` replaces `\037` by a space first (`:397`), so `\037` never occurs in a body.
- Lists (`BEGIN`, `:498-505`): `SHELLS`/`INTERP` = `sh bash zsh dash ksh mksh ash fish`; `INTERP` adds `eval watch su`; `WRAP` = `env command exec builtin time nice nohup timeout stdbuf sudo doas xargs setsid ionice ! { if then else elif do while until`.
- Header comment `:30-34` and `:290` cite ADR-0039.

`tests/bounds.test.sh` (468 lines, 21 tests, all green): helpers `lane` `:10`, `hook_input` `:34`, `bash_status` `:45` (implementer mode, cwd = scratch repo), `expect` `:47`, `rev_bash` `:388`. s62 tests `:306-347`, s70 section from `:374`, last test ends `:468`.

## Attachment points
- `heredocs()` `:388` (queue an unescaped body when `!qq[qh]`) and `:390` (do not skip the `hd` frame for a shell-read unquoted body).
- A new awk function beside `heredocs()` for the unescape.
- `cmdpos()` `:310-317` and its three uses in `endcmd()` `:328`, `:330`, `:331-332`.
- Header comment `:30-34`, `:290`.
- New ADR `docs/decisions/ADR-0050-…` (reserved number); frontmatter of ADR-0039.
- New tests appended after `:468`.

## Verified interfaces
- `bash_status "<cmd>"` → exit code as text; `expect <got> <want> <label>` (`tests/bounds.test.sh:45-47`).
- `require_file`, `contains <file> <exact phrase>` (`tests/lib.sh`); `$ROOT` = repository root.
- ADR frontmatter habit for full replacement: `status: superseded`, `superseded-by: [ADR-0018]` (`docs/decisions/ADR-0003-…md`), and `supersedes: [ADR-0003]` on the successor (`ADR-0018-…md`). ADR-0039 is `accepted`, both lists empty.
- Bash semantics (manual, "Here Documents"): with an unquoted word, `\newline` is ignored and `\` quotes only `\`, `$` and `` ` ``; quotes are not special, so `'$(…)'` in the body is run by the outer shell.

## Traps
- **Portability:** the lexer must run under BWK awk and mawk (`:290`); only gawk 5.4.1 is on this machine. Building the unescaped body one character at a time by concatenation is quadratic in BWK/mawk on large bodies; a `gsub` pass with `\037` as placeholder for `\\` (safe, `:397`), then `split` and rejoin, is linear. Backslashes in a `gsub` replacement string differ between awks: rejoin with `split` rather than writing `"\\\\"` as a replacement.
- **Order of escapes:** `\\` must be resolved first, as bash pairs backslashes left to right: body `\\\$X` becomes `\$X` (a literal backslash, then `$X`), never `\\X`.
- **Two readings now:** a shell-read unquoted body gets the `hd` frame (outer substitutions) *and* the unescaped work string (inner commands). The work string still holds the outer substitutions unexpanded; an odd outer substitution can make it unreadable → refusal, never a pass.
- `\newline` before the delimiter line joins it in bash; the lexer matches the delimiter per raw line, so it may end the body earlier and read more as commands — over-refusal only. Out of scope.
- Marking several words `c`: the reviewer's `GIT_DIR=` check matches only `[uq]` (`:578-579`); an assignment must therefore never become a `c` candidate. Assignments stay skipped in `cmdpos`, so they never do.
- `tests/installer.test.sh:186` requires `ADR-0039` in `docs/installation.md:92`; both are outside Owns, so that reference stays (stale but true: ADR-0039 is superseded, not deleted).
- No migration, no screen, no dependency, no API contract. The hook is an access guard; the story already takes the full track.

## Open questions
- Should a shell-read unquoted heredoc holding any substitution be refused, as `bash -c "$(…)"` is (`:336`)? Its output becomes commands nobody read. The plan keeps it allowed and lists it as a gap; the reviewer may judge otherwise.
- Option-argument ambiguity: a word after a wrapper's option may be the option's value or the command. Reading both is fail-closed but refuses rare forms (`env -i grep "git" docs` in mode `qa`). Is that acceptable? The plan says yes.
- macOS awk and mawk remain unproven, as for s62.

## Complexity
3 → 3. Two local changes in the awk lexer and one ADR; the second gap found here rides on the same lines (`:390`).

## Split
Not needed.
