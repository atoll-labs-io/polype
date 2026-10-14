---
validated: yes
---
# Plan — s74-reviewer-bounds-bypasses

[Story](../stories.md) · [Research](../research/s74-reviewer-bounds-bypasses.md)

Branch `story/s74-reviewer-bounds-bypasses`. Read `docs/research/s74-reviewer-bounds-bypasses.md` first; this plan builds on it without repeating it. The decisions are in `docs/decisions/ADR-0051-le-reviewer-juge-la-commande-git-que-git-executera.md`, written with this plan. It supersedes ADR-0047 in part.

## Story
In mode `reviewer`, `po-bounds` judges the git command git will really run, so that no probe writes into the main checkout by a detour. Acceptance criteria:
- `chained_git_dirs_are_folded` — every `-C` is chained as git chains them before the zone is decided; `git -C <main> -C . commit` from a throwaway repo is refused.
- `config_worktree_override_is_refused` — in mode `reviewer`, a `-c` that sets `core.worktree` is refused, like `--work-tree`.
- `temp_zone_verbs_keep_their_paths_in_temp` — in a throwaway repo, `worktree add`, `clone` and `init` are accepted only when their destination is under the temp dir too.
- `reviewer_knows_how_to_check_merged` — `method/agents/reviewer.md` says how to check that a branch is not merged without `git branch --merged`.

Scope added by the research (ADR-0051), because each is the same detour as M1: a word whose value the hook cannot know is a directory the hook cannot know; and `--attr-source`/`--config-env` hide the verb. **Out of scope:** the scope of `cd` (subshell, substitution, `&`, pipeline, `pushd`/`popd`). It needs a lexer output change and gets its own story.

## Tasks
All code tasks edit `method/hooks/po-bounds.sh`; all tests go at the end of `tests/bounds.test.sh`, after `:504`. Probes are **hook inputs** (`rev_bash`, `bash_status`, `rev_status`), never commands the test runs.

1. [x] **Lexer: a word that held a substitution says so.**
   - In `BEGIN` (`:520-527`), define `SM = sprintf("%c", 30)`.
   - In `opensub` (`:304`), inside the existing `if (t[sp] != "hd")` branch, append it to the word: `wv[f] = wv[f] SM`.
   - Extend the comment above `lex_command` (`:290-292`) by one clause: a word that held a `$(…)`, `` `…` ``, `$((…))`, `<(…)` or `>(…)` carries a `\036` byte where the substitution stood.
   - No other line of `lex_command` changes.
   - Test that fails if wrong: `chained_git_dirs_are_folded`, through its `-C "$(echo …)"` and `cd "$(echo …)"` cases.
2. [x] **One directory, followed as bash and git follow it.**
   - Add a helper after `join_dir` (`:286`): `step_dir <dir> <word>` prints the directory reached from `<dir>` by `cd <word>` or `-C <word>`, and empty means unknown.
     - A word holding `$'\036'` or `$`, or starting with `~`, gives unknown.
     - An absolute word gives itself.
     - An unknown `<dir>` stays unknown for a relative word.
     - Otherwise it gives `join_dir "$1" "$2"`.
     - It always returns 0. `join_dir` is never called with an empty first argument: `join_dir ""` gives `/<rel>`.
   - The `cd` case (`:608-611`) becomes `cur="$(step_dir "$cur" "${vals[i+1]}")"`, except in two cases where `cur=""`: a `cd` with no next word, and a next word starting with `-` (`cd -`, `cd -P`).
   - The option loop (`:614-628`) starts from `dir="$cur"`:
     - `-C) dir="$(step_dir "$dir" "${vals[j+1]-}")"; j=$((j + 2))`. Every `-C` chains, and `gdir` disappears;
     - `--config-env|--attr-source` join the skip-two list at `:624`.
   - The reviewer branch drops `:634-635` and uses that `dir`. The refusal at `:636` says `runs in an unknown or missing directory`.
   - The implementer branch drops `:665-666` and uses the same `dir`; its refusal is unchanged.
   - Tests that fail if wrong: `chained_git_dirs_are_folded` and `global_option_values_are_not_verbs`.
3. [x] **Mode reviewer refuses `core.worktree` given on the command line.**
   - In the option loop, mode reviewer only:
     - the value of `-c`, and the value of `--config-env` (separate, or `--config-env=<value>`), is refused when its key is `core.worktree`. The key is the text before the first `=`, lower-cased with `tr '[:upper:]' '[:lower:]'` (macOS ships bash 3.2, which lacks `${key,,}`);
     - `-c core.worktree` without `=` is refused too.
   - In the assignment check (`:599-603`), the patterns `[uq]:GIT_CONFIG_PARAMETERS=*` and `[uq]:GIT_CONFIG_COUNT=*` join `GIT_DIR=`/`GIT_WORK_TREE=` with the same message.
   - Test that fails if wrong: `config_worktree_override_is_refused`.
4. [x] **In a throwaway repo, every path of the call stays under the temp dir.**
   - Add `check_temp_paths <dir> <j>`, called right after `in_temp_zone "$dir"` succeeds (`:646`). The verb sits at word `j`; for every word `a` after it, with `k` from `j + 1` to `n - 1`, build the candidates:
     - `a` itself when it does not start with `-`;
     - the text after the first `=` when `a` starts with `--` and holds `=`;
     - `${a:2}` when `a` is a single-dash short option longer than two characters whose second character is a letter (`-o/x`).
   - Each candidate holding `$'\036'` or `$`, or starting with `~`, is refused: "a path the reviewer cannot read".
   - Otherwise `resolve_path "$(join_dir "$dir" "$cand")"`, then `under_temp "$RESOLVED"` or deny with the word and `TMP_ROOT` in the message.
   - Push and send-pack keep their earlier refusal at `:633`.
   - Test that fails if wrong: `temp_zone_verbs_keep_their_paths_in_temp`.
5. [x] **`method/agents/reviewer.md`, Limits paragraph (`:35`).** After the sentence on throwaway repos, add two sentences:
   - every path a probe's git command names stays under the temp dir, and the real repository is cloned as `file://<path>`;
   - in the story worktree, `git branch --merged` is refused, so the check that a branch is not merged into `Target branch` uses `git -C <worktree> merge-base --is-ancestor story/<id> <Target branch>` (exit 1: not an ancestor) or `git -C <worktree> log --oneline <Target branch>..story/<id>`.

   The frontmatter stays untouched. Test that fails if wrong: `reviewer_knows_how_to_check_merged`.
6. [x] **Texts that cite the rules.**
   - Rewrite the mode `reviewer` paragraph of the header (`:19-28`): cite ADR-0047 and ADR-0051, and add the chained `-C`, the unknown directory, the refusal of `core.worktree`/`GIT_CONFIG_*`, and the rule that paths in the temp zone stay there.
   - In `docs/decisions/ADR-0047-le-reviewer-tenu-par-po-bounds-en-mode-reviewer.md`, change only the frontmatter line `superseded-by: []` to `superseded-by: [ADR-0051]`. `status: accepted` and the body stay; this is a partial supersession, as for ADR-0024.
   - Test that fails if wrong: `reviewer_rules_are_written_in_adr_0051`.
7. [x] **Tests.** These are the six functions below. Run them with `bash tests/run.sh bounds.test.sh`, then run the full suite once through `po-run`.

## Run interdicts
- In `lex_command` (`:293-534`), only the `opensub` line, the `BEGIN` constant and the comment above the function differ in `git diff main...story/s74-reviewer-bounds-bypasses -- method/hooks/po-bounds.sh`.
- `check_git_read`, `check_restore`, `check_write`, `check_write_qa`, `check_write_reviewer`, `resolve_path`, `in_temp_zone`, `temp_root`, `under_temp`, `owns_line`, `story_base`, `parse_owns`, `check_entry` and `entry_matches` have no changed line.
- `QA_GIT_VERBS` (`:288`) stays unchanged.
- No existing line of `tests/bounds.test.sh` changes: the diff only adds lines after `:504`. Every existing test stays green unchanged, including `'cd "$(mktemp -d)" && git init'` (refused) and `cd $TMPROOT && git init other` (accepted).
- `tests/lib.sh`, `tests/structure.test.sh`, `method/AGENTS.md`, `docs/installation.md` (owned by s75), the skills, `implementer.md`, `qa.md`, `.claude/` and `.polype/` are not in the diff.
- `reviewer.md`: the `tools:` line and the `hooks:` block are unchanged.
- ADR-0047 differs from `main` by its `superseded-by` line only. ADR-0050 is untouched. No ADR other than ADR-0051 is added.
- No new dependency: no `realpath` and no `readlink -f`, only bash, jq and POSIX awk.
- No test executes a probe command. Every probe goes through `rev_bash`, `rev_status` or `bash_status`, which only feed JSON to the hook.
- Nothing is done about `cd` scope (subshells, `pushd`): it is a reported gap, not part of this diff.

## The pivot
**The temp-zone rule is uniform: every word after the verb must resolve under the temp dir, with no table of verbs that take a destination.** It covers `init`, `clone`, `worktree add`, and also `archive -o`, `bundle create` and `config core.worktree`, because git takes a `file://…` destination as a relative path (checked on git 2.56.0). Three ways it could be wrong:
1. **It refuses a probe a real review needs.** A clone or fetch of the real repository by absolute path, `diff --no-index` against a worktree file, and a commit message starting with `/` or holding `$` are all refused. Compare against the probes in `docs/reviews/*.md`: none clones the real repository by path. The `git clone --shared` of `docs/verif/s48-floor-guard.md:18` is an implementer's, and `--shared` does not work through `file://`. If a reviewer needs it, the fallback is a narrower rule for `clone`, `fetch` and `remote` sources, written in a new ADR.
2. **`resolve_path` denies too eagerly.** A word that is a symbolic link, or that holds a `..` segment that does not exist yet, ends the call with exit 2. A legitimate `git -C <probe> add link` is refused. That is fail-closed and accepted; the reviewer should check that no existing reviewer test case hits it.
3. **The `\036` marker shifts another mode.** Implementer and qa words that held a substitution now carry it. Compare the full `bounds.test.sh` before and after: every implementer and qa test must pass unchanged, and `x=$(git stash)` must still be read as a git call (`test_bounds_still_catch_real_verbs`).

## Files touched
- `method/hooks/po-bounds.sh` — lexer marker, `step_dir`, option loop, assignment check, `check_temp_paths`, header comment.
- `method/agents/reviewer.md` — the Limits paragraph only.
- `tests/bounds.test.sh` — six new functions after `:504`.
- `docs/decisions/ADR-0047-…md` — frontmatter `superseded-by` only.
- Already written, committed with the code: `docs/decisions/ADR-0051-…md`, `docs/research/s74-reviewer-bounds-bypasses.md`, this plan; `docs/verif/s74-reviewer-bounds-bypasses.md` at execute.

## Test strategy
All tests sit at the policy layer, the hook itself fed real JSON (testing-doctrine: access rules are tested once, in the policy). Six tests, within the `Test budget` of 25. Each reuses `reviewer_lane`, whose temp root sits outside `$SCRATCH` (the main checkout, and the input's `cwd`).

| Test | Refused (exit 2) | Accepted (exit 0) | Bites when |
| --- | --- | --- | --- |
| `chained_git_dirs_are_folded` | <ul><li>`cd $TMPROOT/probe && git -C $SCRATCH -C . commit -m x`</li><li>`cd $TMPROOT/probe && git -C "$(echo $SCRATCH)" commit -m x`</li><li>`cd $TMPROOT/probe && cd "$(echo $SCRATCH)" && git commit -m x`</li><li>`cd $TMPROOT/probe && cd && git commit -m x` (the old code ignored a bare `cd`)</li><li>after `mkdir -p "$TMPROOT/probe/~"`: `cd $TMPROOT/probe && git -C ~ commit -m x`</li><li>implementer (`bash_status`): `cd $WT && git -C $SCRATCH -C . commit -m x`</li></ul> | `git -C $TMPROOT -C probe commit -m x` (refused by the old code: it joined `probe` to the cwd) | `-C` overwrites instead of chaining; the marker or `step_dir`'s unknown case is removed |
| `global_option_values_are_not_verbs` | <ul><li>`cd $TMPROOT/probe && git --attr-source HEAD push`</li><li>`cd $TMPROOT/probe && git --config-env x.y=HOME push`</li></ul> | `git -C $WT --attr-source HEAD status` (old: verb `HEAD`, refused) | `--attr-source`/`--config-env` leave the skip-two list |
| `config_worktree_override_is_refused` | <ul><li>`git -C $TMPROOT/probe -c core.worktree=$SCRATCH reset --hard`</li><li>`git -C $WT -c core.worktree=$SCRATCH checkout -- src/app.sh`</li><li>`git -C $TMPROOT/probe -c Core.WorkTree=$SCRATCH status`</li><li>`git -C $TMPROOT/probe --config-env core.worktree=HOME status`</li><li>`git -C $TMPROOT/probe --config-env=core.worktree=HOME status`</li><li>`GIT_CONFIG_COUNT=1 git -C $TMPROOT/probe status`</li><li>`GIT_CONFIG_PARAMETERS=x git -C $TMPROOT/probe status`</li></ul> | `git -C $TMPROOT/probe -c user.name=x commit -m x` | the key check, the lower-casing or the two assignment patterns are removed |
| `temp_zone_verbs_keep_their_paths_in_temp` | <ul><li>`cd $TMPROOT/probe && git init $SCRATCH/x`</li><li>`git -C $TMPROOT/probe clone $SCRATCH $SCRATCH/sub`</li><li>`git -C $TMPROOT/probe worktree add $SCRATCH/evil`</li><li>`git -C $TMPROOT/probe worktree add ../../$(basename "$SCRATCH")/evil`, written literally by the test</li><li>`git -C $TMPROOT init --separate-git-dir=$SCRATCH/g x`</li><li>`git -C $TMPROOT/probe archive -o$SCRATCH/a.tar HEAD`</li><li>`git -C $TMPROOT/probe config core.worktree $SCRATCH`</li><li>`git -C $TMPROOT/probe init '$X'/y`</li><li>after `ln -s "$SCRATCH" "$TMPROOT/link"`: `git -C $TMPROOT/probe init $TMPROOT/link/x`</li></ul> | <ul><li>`git -C $TMPROOT/probe worktree add $TMPROOT/wt2`</li><li>`git -C $TMPROOT clone file://$SCRATCH c`</li><li>`git -C $TMPROOT clone probe c2`</li><li>`git -C $TMPROOT/probe commit -m x`</li></ul> | `check_temp_paths` is skipped, or one of its three candidate forms is dropped |
| `reviewer_knows_how_to_check_merged` | `contains "$REVIEWER"` with `git branch --merged`, `merge-base --is-ancestor` and `file://` | — | the sentences are removed |
| `reviewer_rules_are_written_in_adr_0051` | ADR-0051 contains `supersedes: [ADR-0047]`, `**Répertoire**`, `core.worktree` and `la portée d'un \`cd\``. In ADR-0047's frontmatter, `grep -qx 'superseded-by: \[ADR-0051\]'` and `grep -qx 'status: accepted'` both match | — | the link or a rule paragraph disappears |

Visual checks: none, the story has no screen. Full suite: once, at the end, `po-run --story s74-reviewer-bounds-bypasses --label test -- 'bash tests/run.sh'`. No type check, E2E or build (`Typecheck: —`, `E2E: —`, `Build: —`).

## Done when
- The four acceptance tests and the two added ones pass, and so does the whole of `bash tests/run.sh`, recorded by `po-run`.
- The run interdicts hold.
- A single commit on `story/s74-reviewer-bounds-bypasses` carries the code, the tests, ADR-0051, the ADR-0047 frontmatter line, the research, this plan and the verification record.
- A review with no open critical finding, then a squash on `main`.
