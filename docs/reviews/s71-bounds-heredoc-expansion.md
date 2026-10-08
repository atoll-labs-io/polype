# Review: s71-bounds-heredoc-expansion

Fix loop: 0
Reviewed tree: 37da3ac7d09443cec99eaceeb5819b9915963a9b
Branch: story/s71-bounds-heredoc-expansion (worktree /home/lecrabe/dev/atoll/polype/.worktrees/s71-bounds-heredoc-expansion), diff `git diff main...story/s71-bounds-heredoc-expansion`, one commit (291ffe0).
Lenses run: Security, triggered by `method/hooks/po-bounds.sh`. This is the permission hook that decides which git calls a subagent may run.

## Scope (Owns)
Owns: `method/hooks/po-bounds.sh`, `tests/bounds.test.sh`.

- `method/hooks/po-bounds.sh` and `tests/bounds.test.sh` are inside Owns.
- `docs/research/`, `docs/plans/` and `docs/verif/` files for s71 are the story's own evidence, so they are in scope.
- `docs/decisions/ADR-0050-…md` is added (status A), and the plan names it. It is in scope.
- `docs/decisions/ADR-0039-…md` is modified, and no Owns entry covers an existing ADR. See finding m1.
- No other story worktree is open (`git worktree list` shows only main and this one), so this diff cannot collide with another lane.

## Step 1: Reuse what is already proven
`po-gate verif-current s71-bounds-heredoc-expansion` exited 0. The record is complete, its `Tree:` is 3e553c50…, and the Unit suite row `bash tests/run.sh` exited 0 on code identical outside `docs/`. With `Verification mode: record` I relied on that run and did not rerun the full suite. The project has no Type check, E2E or Build command (`—`), so none of those ran. "Not proven here" says the lexer ran under gawk only; BWK awk and mawk were never run. I carry that into Not verified. The story has no screen, so QA does not apply.

## Step 2: References
- `unesc`, `CP` and `cmdpos` are defined inside the same awk program, and `endcmd` is the only caller of `cmdpos`.
- `US`, `WRAP`, `SHELLS` and `INTERP` are defined in `BEGIN`, which was not changed.
- `lex_command` is consumed only by `check_bash`. `check_bash` treats any word equal to `git` and not typed `q` as a git call, so having several `c` words is safe.
- In the tests, `lane`, `bash_status`, `qa_status`, `expect`, `require_file` and `contains` all exist in `tests/bounds.test.sh` and `tests/lib.sh`.

## Step 3: Diff against the plan
- Tasks 1 to 6 are all present and match the plan.
- The run interdicts hold:
  - The 21 existing tests are unchanged and the new ones are appended at the end.
  - `check_*`, the mode dispatch and the `BEGIN` lists are untouched.
  - No gawk-only construct is used.
  - `docs/installation.md`, `tests/installer.test.sh`, `.claude/` and `.polype/` have an empty diff.
  - ADR-0039 changes only in its `status:` and `superseded-by:` lines.
- No change was made that the plan did not ask for.
- The story's criterion 3 lists `bash <(…)` as an accepted gap. Research showed it is already refused (`po-bounds.sh:501`, together with the "substitution handed to an interpreter" refusal). The plan corrected the story on this point and ADR-0050 says so in its Neutral consequence. That deviation is justified.

## Step 4: Tests
- **Floor:** `po-gate floor-guard s71-bounds-heredoc-expansion main` exited 0. Nothing was lowered.
- **Tests that prove nothing:** none found.
  - Every case drives the real hook with real JSON input.
  - Case 6 (`cat > …docs/x.md <<EOF` with an escaped backquote) is correctly expected to pass: bash leaves that body as text.
  - The `qa` cases check the opposite direction: a quoted `git` used as an argument must not become a candidate command word.
- **Excess:** none. The story adds 3 tests (24 in the file), well within the Test budget of 25.
- **Bite:** I disabled each rule in turn and ran only `bounds.test.sh`. After each change I restored the file with `git checkout --` and confirmed `git diff --exit-code` was clean.

| Rule disabled | Tests that failed | Failing case |
| --- | --- | --- |
| Queue the raw body instead of the output of `unesc(body)` (task 1) | 1/24 | "escaped backquotes in a body bash reads" |
| Remove the keep-scanning line `if (po) { po = 0; continue }` in `cmdpos` (task 3) | 1/24 | `env -u X "git" push` |
| Restore `qi[qh - 1] \|\|` in the heredoc skip condition (task 2) | 1/24 | "a substitution the outer bash runs" |

Each rule fails a test when it is removed.

## Step 5: Values that merely look right
- **Unescape order.** `\\` is turned into US first, then `\<newline>`, `\$` and `` \` `` are handled, then the text is split on US and rejoined with `\`. This matches how bash renders a heredoc. I reasoned through `\\\$X` → `\$X` and `\\<newline>` (the newline is kept). The record says the implementer compared the output with bash's own rendering.
- **Option detection.** An option counts as taking a value only if it follows a wrapper and has no `=`. I probed:
  - `env --unset=X "git" push`, `sudo -uroot "git" push`, `nice -n -5 "git" push`, `timeout -k 5 10 "git" push` and `xargs -I {} "git" push` are all refused, as intended.
  - `rev_bash 'sudo -E "GIT_DIR=/x" git log'` is still refused.
  - In `qa` mode, `sudo -u x grep "git" docs` is still allowed.
  - `env -i grep "git" docs` is now refused in `qa` mode. This is a false refusal, but ADR-0050 records it as an accepted cost and it fails closed.
- **Heredoc probes.** I built all of these as hook input data, never as commands.
  - Refused: `gi\<newline>t push` in a body bash reads, `"\$(git push)"`, `\\\\` followed by a backquoted push, and `sudo -u x "bash" <<EOF` with a push in the body.
  - Allowed: a nested heredoc in a body bash reads, `` `date` ``, and `echo ok`.

## Step 6: Neighbours
`cmdpos`'s first candidate (`cp`) is still what the `-c` test uses, so `sudo -u x "bash" -c "git push"` is refused, as the test checks. The interpreter test and the shell test now accept any candidate. That widens the pipe refusal: `echo x | sudo -u bash ls` is now refused. The plan accepts this and it fails closed. `check_bash` was not modified.

## Findings
- **m1 (minor): an accepted ADR modified outside Owns.** The file is `docs/decisions/ADR-0039-po-bounds-lit-les-commandes-hors-guillemets-et-heredocs.md`, and no Owns entry covers an existing ADR.
  - Only the frontmatter changed: `status: superseded`, `superseded-by: [ADR-0050]`. The body is unchanged, and plan task 5 asked for this edit.
  - The method's written supersession rule requires it. `method/commands/po-architect.md:48` says "the old one gets `superseded-by` and `status: superseded`."
  - So this is a gap in the story's Owns line, not a breach by the implementer. I left the code alone.
  - A stricter reading of the scope rule ("an existing ADR the diff modifies is never covered") would grade this major. I graded it minor because the method itself requires the edit.
- **m2 (minor): installation doc still cites the superseded ADR.** `docs/installation.md:92` still points to ADR-0039, and `tests/installer.test.sh:186` checks for that string.
  - The plan kept both out of scope on purpose, because they are outside Owns.
  - Now that ADR-0050 replaces ADR-0039, a later story should point the doc to ADR-0050.
- **Security lens:** nothing to report. The diff only makes the guard refuse more, and every new reading fails closed. ADR-0050 lists the gaps that remain (script written then run, `source <(…)`, `$VAR`/alias, `GIT_DIR=` in the implementer and qa modes, what a substitution expands to inside a heredoc). None of those gaps is new in this diff.

No critical or major finding.

## Not verified
- **BWK awk (macOS) and mawk.** The lexer, including the new `unesc` and `split("", CP)`, ran under gawk only. A person on macOS should run `bash tests/run.sh bounds.test.sh`, and someone with mawk installed should repeat the run under mawk.
- **The full suite and the side-by-side comparison with bash.** I did not rerun the full suite; I relied on the po-run row in the record. I checked the unescape order by reasoning and with hook probes, but did not compare its output against bash myself.
- **The live hook.** I never exercised it through Claude Code itself, only through the test harness's JSON input. The installed `.polype/hooks/po-bounds.sh` will only change after ship and a reinstall.
- **Bypasses outside the probes.** The hook's guarantees go no further than the cases listed above. Wrapper options that take two values, and shells or wrappers not on the lists, were not explored.

Max severity: minor
Ship allowed: yes
