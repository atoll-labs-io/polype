# Review: s76-bounds-guard-against-mistakes

[Story](../stories.md) · [Plan](../plans/s76-bounds-guard-against-mistakes.md) · [Verification](../verif/s76-bounds-guard-against-mistakes.md)

Reviewed tree: 861b7af31ff8dd2f541b46bb938bc9cc1f48af33
Fix loop: 0
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s76-bounds-guard-against-mistakes
Scope: `git diff main...story/s76-bounds-guard-against-mistakes` (one commit, 0c89ec0)
Lenses run: Security (content: the diff changes `po-bounds`, the hook that decides what the reviewer, qa and implementer subagents may write and run. Its new `check_redirects` decides which paths a git call may write to.)

## Scope check
- All 13 changed paths are covered by the story's `Owns` line, or are in scope for another stated reason. Files on that line: `method/hooks/po-bounds.sh`, the three test files, `docs/installation.md`, and the front matter of ADR-0034, ADR-0041, ADR-0047 and ADR-0051.
- ADR-0052 was added (status `A`) and the plan names it by its file name, so it is in scope as well.
- The story's own research, plan and verification record are pipeline evidence.
- `git worktree list` shows no other running story, so no other story's `Owns` can overlap.
- Each changed ADR has exactly one changed line, in its front matter (`supersedes` or `superseded-by`). No body text and no `status:` line changed. This matches the story note and the plan's run interdicts.

## Evidence relied on
- `po-gate verif-current` exits 0. The record `docs/verif/s76-bounds-guard-against-mistakes.md` is marked complete. Its unit-suite row is `bash tests/run.sh` with exit 0, on tree 0f9dc98. That tree's code outside `docs/` is identical to both the record's `Tree:` (c6aa77e) and HEAD; I checked each with `git diff --quiet … -- . ':(exclude)docs'`.
- With `Verification mode: record`, the full suite counts as proven by that record, and I did not rerun it. That suite includes `tests/overlap.test.sh`.
- The project has no type check, E2E or build command (all set to `—`), so none was run.
- I read the record's "Not proven here" section: it notes the hook was never run in a live session, and that it was not run under BWK awk or mawk.
- `po-gate floor-guard s76-bounds-guard-against-mistakes main` exits 0, so nothing in the diff lowers the test floor.
- This story has no screen, so there is no QA stage and no design check.
- I also ran the story's own test files: `bash tests/run.sh bounds.test.sh installer.test.sh post-m7-texts.test.sh` gives 53 passed, 0 failed.

## Plan conformity
- **Task 1 (ADR links):** the exact front-matter lines the plan asks for. Two existing test checks changed, and the plan announced both: `bounds.test.sh:589` and `post-m7-texts.test.sh:36`.
- **Task 2 (lexer):**
  - It keeps a redirection state per frame (`rd[]`) and marks redirection targets per word (`R[]`).
  - An all-digit fd number before `<`/`>` is dropped, as are the targets `N`, `N-` and `-` after `<&`/`>&`.
  - It adds `&>`/`&>>` before the `;`/`&` branch, outputs the new type letter `r`, and makes `cmdpos`, the interpreter/shell detection and the queueing of quoted text skip `r` words.
  - The order of the heredoc and process-substitution branches is unchanged, and the comment at `:311` lists `c/q/u/r`.
- **Task 3:** `check_bash` moves `r` words into `redirs` before indexing, so every later index is unchanged. `check_redirects "$cur"` is called only in the temp-zone branch, as planned.
- **Task 4:** the header comment covers the redirection rule, says redirections are not words, and frames the hook as a guard against mistakes (ADR-0052).
- **Task 5:** the « et … ni » sentence is split into two sentences. The `### Le mode reviewer` section is rewritten and contains all eight required phrases. The pinned phrases and both section headings are kept.
- **Task 6:** four new tests, the number the plan sets (the test budget is 25). `p` is now declared local.
- **Interdicts:**
  - `step_dir`, `check_temp_paths`, `check_config_key`, `check_git_read`, `check_restore`, `QA_GIT_VERBS` and the implementer branch are unchanged.
  - `method/agents/reviewer.md`, `method/AGENTS.md`, `.claude/`, `.polype/`, the root `AGENTS.md`, `tests/leftovers.test.sh` and `tests/global-install.test.sh` are absent from the diff.
  - No new test file was added.
- The diff contains no unrequested change.

## Bite (each mutation undone; `git diff --exit-code method/hooks/po-bounds.sh` clean after each)
1. I disabled the `r` marking in `endcmd` (`R[f, k] ? "r"` became `0 ? "r"`). Running `bounds.test.sh` gave **1 failure**, `redirections_are_not_git_paths`, on the `2>/dev/null` case.
2. I replaced the `check_redirects "$cur"` call with a no-op. **1 failure**, on the `> $SCRATCH/out.txt` case, which should be refused.
3. I resolved redirection targets from git's directory instead of the shell's (`check_redirects "$dir"`). **1 failure**, on the relative `> out.txt` case run from the main checkout.

## Values and neighbours
I fed 28 commands to `method/hooks/po-bounds.sh` through a probe script under the temp dir, against a real throwaway repo. I ran them with gawk, and again with `gawk --posix` in place of `awk`; both runs gave the same results.

Refused, as they should be:
- `>&`, `>>`, `>|`, `&>>` and `<` aimed at the main checkout;
- `2>&1 > <checkout>/x`;
- a target containing `/tmp/…/../`;
- `> >(cat)`;
- `2>/dev/null git … push`;
- in implementer mode, `git branch 2>&1 -D foo`. Before this change, the `&` in `2>&1` split the command and let this through, so this is a tightening.

Allowed, matching bash's own reading:
- `2>&-`, `1>&2` and `"2">/dev/null`;
- `-n2>/dev/null`, where `-n2` stays an argument;
- `cd <probe> && git log > "out.txt"`;
- `bash -c '… 2>/dev/null'`;
- the heredoc `cat > …/docs/x.md <<'X'` and `echo hi > /tmp/x`, which stay allowed for the implementer.

`lex_command` has a single caller, `check_bash` at `po-bounds.sh:666`, and no other code reads its output. I checked the redirection words that `check_bash` now removes in every mode, and dropping them only tightens checks. For example, `git checkout -- 2>/dev/null` in the story worktree no longer counts `2` and `/dev/null` as paths.

## Findings
- **minor m1** — `method/hooks/po-bounds.sh`, `check_redirects`: when a target contains a substitution, the refusal message prints the raw `\036` byte. The result reads `git log redirects to , a path the reviewer cannot read` (seen with `> >(cat)`). The refusal itself is correct; only the message is unreadable. `check_temp_paths` prints the whole word `$a` and avoids this.
- **minor m2** — `method/hooks/po-bounds.sh`, `check_redirects`: `>/dev/fd/1` (or `/dev/fd/2`) is refused with only `po-bounds: /dev/fd/1 is a symbolic link`, which comes from `resolve_path`. Failing closed is acceptable, but `/dev/fd/N` has the same meaning as the allowed `/dev/stdout` and `/dev/stderr`, and the message does not say which rule refused it.
- **minor m3** — `method/hooks/po-bounds.sh`, lexer: a bash named-fd redirection `{fd}>/dev/null` is read as the argument `{fd}` plus a redirection. In the temp zone, `{fd}` then resolves as a relative path under the probe and passes. This is harmless and no more permissive than before.

No critical or major findings.

## Security lens
- The change makes the hook less strict in exactly one case: redirection targets of git calls are no longer read as git paths. In their place, `check_redirects` now refuses redirection targets that resolve outside the temp dir, judged from the shell's real directory. The old reading allowed one of these, `git -C <probe> log > out.txt` run from the main checkout.
- A redirection in a story-worktree git call or in a non-git command is still not read, as before. ADR-0047 accepted this gap and ADR-0052 restates it.
- I found no new way for an agent to get past the hook by mistake.

## Not verified
- **The hook in a live Claude Code session.** The installed copy `.polype/hooks/po-bounds.sh` is still the pre-story version; it is refreshed only after ship. All probes fed JSON to `method/hooks/po-bounds.sh`. *To cover:* after the refresh commit, run a review with `git -C <probe> log 2>/dev/null` and confirm it passes.
- **BWK awk and mawk.** Neither is installed here; I only ran gawk, with and without `--posix`. *To cover:* run `bash tests/run.sh bounds.test.sh` on macOS (BWK awk) or with mawk first in `PATH`.
- **Accepted deliberate bypasses.** I did not try to prove that `config -zf<chemin>`, `GIT_CONFIG_GLOBAL`, `pushd` or aliases still pass. The plan's interdict on unchanged functions is met, and ADR-0052 accepts these bypasses by design. *To cover:* nothing needed, unless a person wants that list re-exercised.
- **`method/agents/reviewer.md`.** Its "Limits" paragraph does not yet carry the guard-against-mistakes framing, or the rule that a deliberate-bypass finding goes to an ADR rather than a fix. The file is outside this story's `Owns`, the research listed it as an open question, and it is not a line of this diff. *To cover:* a person decides whether a later story aligns it.
- **The full suite.** I did not rerun it myself and relied on the `po-run` record.

Max severity: minor
Ship allowed: yes
