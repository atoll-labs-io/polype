# Review: s74-reviewer-bounds-bypasses

Reviewed tree: 0706c1dae28182a50cbe44d48cb0fd6e7f7bc5d1
Fix loop: 0
Worktree: /home/lecrabe/dev/atoll/polype/.worktrees/s74-reviewer-bounds-bypasses (branch `story/s74-reviewer-bounds-bypasses`, commit cf3a9de)
Scope: `git diff main...story/s74-reviewer-bounds-bypasses`
Lenses run: Security (`method/hooks/po-bounds.sh`: the hook decides what may write and where, which makes it a permission policy)

## Scope check (Owns)
Owns: `method/hooks/po-bounds.sh`, `method/agents/reviewer.md`, `tests/bounds.test.sh`
- `method/hooks/po-bounds.sh`, `method/agents/reviewer.md`, `tests/bounds.test.sh`: inside Owns.
- `docs/research/…`, `docs/plans/…`, `docs/verif/…` for s74: the story's own evidence, in scope by definition.
- `docs/decisions/ADR-0051-…md`: added (status A) and named by the plan, so in scope.
- `docs/decisions/ADR-0047-le-reviewer-tenu-par-po-bounds-en-mode-reviewer.md`: modified (frontmatter `superseded-by` only). An existing ADR that the diff modifies is never covered. **Outside Owns, see M3.** It is not in s75's Owns (s75 is the other running lane), so it is not critical.

## Evidence reused
- `po-gate verif-current s74-reviewer-bounds-bypasses` exited 0. `Verification mode: record`. The record (`docs/verif/s74-reviewer-bounds-bypasses.md`) shows `bash tests/run.sh` with exit 0 on this code, so I did not rerun the full suite.
- Its "Not proven here" section: no E2E or build exists, the `\036` marker was not run under BWK awk, and the `cd` scope gap is deferred.
- The project has no `Typecheck`, `E2E` or `Build` command (all `—`).
- `po-gate floor-guard s74-reviewer-bounds-bypasses main` exited 0: no checks were lowered.
- I also ran `tests/overlap.test.sh`: it passes.

## Plan conformance
- Tasks 1 to 7 are all present and match the plan: the lexer `SM` marker in `opensub`/`BEGIN`, `step_dir`, chained `-C`, `--attr-source`/`--config-env` in the skip-two list, `check_config_key` plus the `GIT_CONFIG_PARAMETERS=`/`GIT_CONFIG_COUNT=` assignments, `check_temp_paths`, the reviewer.md Limits paragraph, the header comment, the ADR-0047 frontmatter line and six tests.
- Run interdicts:
  - In `lex_command`, only the opensub line, BEGIN and the comment changed.
  - `QA_GIT_VERBS` and the listed functions are unchanged.
  - No existing test lines changed.
  - No `.claude/`, `.polype/` or s75-owned paths are touched.
  - The reviewer.md frontmatter is untouched.
- Every reference I opened exists: `step_dir`, `check_temp_paths`, `check_config_key`, `resolve_path`, `under_temp`, `TMP_ROOT`, `RESOLVED`, `deny`, and the dynamically scoped `n`/`vals`/`cmd`. `gdir` is fully gone, and `join_dir` is now reached only through `step_dir` and `check_temp_paths`.
- The `merge-base --is-ancestor story/<id> <Target>` advice in reviewer.md is correct: exit 1 means not an ancestor.

## Test bite
I disabled two rules and ran only `bash tests/run.sh bounds.test.sh` each time:
1. `-C` steps from `$cur` instead of chaining from `$dir` (po-bounds.sh:670): 1 failure (`chained_git_dirs_are_folded`). Undone; `git diff --exit-code method/hooks/po-bounds.sh` is clean.
2. The `check_temp_paths "$dir" "$j"` call is replaced by `:` (po-bounds.sh:704): 1 failure (`temp_zone_verbs_keep_their_paths_in_temp`). Undone; `git diff --exit-code` is clean, and `git status --porcelain` is empty at the end.

Six tests were added, within the budget of 25. They sit at the policy layer and feed the hook JSON only. None of the six "prove nothing" patterns applies.

## Findings
- **major (M1)**, `method/hooks/po-bounds.sh:604-606` (`check_temp_paths`, case `-[A-Za-z]?*) cands+=("${a:2}")`). Clustered short options get past the temp-zone path rule.
  - git's parse-options accepts clusters such as `-zf<path>` and `-ko<dir>`. The hook only strips two characters, so the remaining text (`f/abs/path`, `o/abs/dir`) becomes a relative word under the probe dir and passes.
  - I fed both to the story's hook (reviewer mode, temp root outside the "main" repo). Both exit 0:
    - `git -C <tmp>/probe config -zf<main>/.git/config core.hooksPath hooks`
    - `git -C <tmp>/probe format-patch -ko<main> HEAD -1`
  - I checked on git that both clustered forms really write to the attached path (`config -zf<file>` wrote the file, `format-patch -ko<dir>` wrote the patch). The `config` one writes the main repository's `.git/config`, for example `core.hooksPath` or `core.worktree`.
  - This defeats the AC `temp_zone_verbs_keep_their_paths_in_temp` and the ADR-0051 consequence that "`git config core.worktree <checkout>` … sont refusés depuis une sonde".
  - Graded major to match the identical-class M1 to M3 in s70's review.
  - Fix direction: for a single-dash word, check every suffix after position 1 (or refuse any clustered short option whose tail resolves outside the zone). Also record the rule in a new ADR, since ADR-0051's "ce qui suit les deux premiers caractères" is the flawed decision.
- **major (M2)**, `method/hooks/po-bounds.sh:600-617`. A legitimate probe is now refused because redirection targets are read as git path words.
  - `git -C <tmp>/probe log 2>/dev/null` (and the same piped to `| head`) now exits 2 with "git log names /dev/null, which lies outside the temp dir". On `main` the hook accepted it (checked: exit 0).
  - The story says each fix "doit laisser passer les sondes légitimes des revues". ADR-0051's "Bad" list names `-m '/x'` and `$`, but not redirections.
  - Incidentally, `> <main>/out.txt` is now refused, which is welcome, but `/dev/null` is not a write target that matters.
  - It fails closed and is contained.
  - Fix direction: drop redirection operators and their targets from the candidates (or allow `/dev/null`), and document the rule.
- **major (M3)**, `docs/decisions/ADR-0047-le-reviewer-tenu-par-po-bounds-en-mode-reviewer.md`. This file is outside the story's Owns (`method/hooks/po-bounds.sh`, `method/agents/reviewer.md`, `tests/bounds.test.sh`).
  - The change is the frontmatter line `superseded-by: [ADR-0051]`, announced in plan task 6 and following the ADR-0024 precedent.
  - No written rule of AGENTS.md requires the link edit; Law 6 only says a new ADR supersedes. So the scope rule makes this major rather than minor.
  - Choose one: widen s74's Owns to that file on purpose, or drop the line.
  - The change itself is harmless and the body is untouched.

## Not verified
- I did not run anything under BWK awk or mawk. The `\036` marker and `SM = sprintf("%c", 30)` were only exercised with the Linux awk, as the record also says. Someone with macOS should run `bash tests/run.sh bounds.test.sh` there.
- I did not mutate the `core.worktree` lower-casing or the `GIT_CONFIG_*` patterns. Their tests exist, but whether they bite is unproven.
- For clusters, I checked git's real behaviour only for `config -zf` and `format-patch -ko` (git on this machine). I did not enumerate every other subcommand with an attached-value short option.
- The ADR-0051 claim that `core.worktree` via `-c` does not move `checkout`/`reset` under git 2.56.0 was not re-tried.
- The `cd`-scope gap (subshell, `&`, pipeline, `pushd`/`popd`), git aliases and hooks of a throwaway repo, and `GIT_CONFIG_GLOBAL` are acknowledged gaps in ADR-0051, not covered here.
- I did not exercise the implementer-mode effect of the new rules on real implementer sessions beyond the existing test suite. A substitution-held word now makes the directory unknown in implementer mode too, which refuses `cd "$(git rev-parse --show-toplevel)" && git commit`.

Max severity: major
Ship allowed: yes
