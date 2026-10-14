# Research — s99-throwaway-zone-holds

[Story](../stories.md)

## Structuring facts
- **Root cause.** In implementer mode, a git call in a throwaway repo is checked only after its verb. `check_temp_paths` starts at word `j + 1` (`method/hooks/po-bounds.sh:626`). The global options that point git at another tree are refused only when `$mode` is `reviewer`: see `--git-dir`/`--work-tree` at `:713-718`, `-c`/`--config-env` at `:719-724`, and the `GIT_*=` assignment scan at `:686-693`. In implementer mode the option loop skips over them, and the throwaway block (`:779-782`) never looks at them. The input that reaches this code is `git -C <clone> --work-tree=<WT> checkout main -- .`. The proof is the reproduction below, which exits 0 in implementer mode and 2 in reviewer mode, and a sandbox run of git 2.56.0 showing that `--work-tree` and `GIT_WORK_TREE` really write into the other tree.
- **The story's assumptions hold.** `check_config_key` exists and can be reused (`:662-666`). Its message hard-codes "forbidden to the reviewer" (`:665`), so the wording has to change if the implementer reuses it. The rule "a story worktree is judged first" exists (`:754`), and with no test behind it, the review's bite E took nothing down.
- **ADR-0072 needs no change.** It already promises "rien n'en sort vers le worktree", and the hook will make that true. ADR-0050:48 accepts `GIT_DIR=`/`--git-dir` before `reset`/`commit` in implementer mode. Those verbs never pass in a throwaway repo (`:774-777` requires a `story/*` worktree), so refusing these forms *only in the throwaway repo* contradicts no accepted ADR.
- **`-c core.worktree` does not actually move `checkout` under git 2.56.0.** The sandbox run left `wt4` empty, which matches ADR-0051:52. The story still asks for it to be refused, as the reviewer mode does.

## Diagnostic
**Reproduction.** I ran it outside the worktree, in `mktemp -d` dirs, with `TMPDIR` set to the dir holding the clone. The inputs were the hook fed real JSON: `{tool_name: Bash, command, cwd}`.

| Command (clone under TMPDIR, `WT` = story worktree outside it) | implementer | reviewer |
| --- | --- | --- |
| `git -C <clone> --work-tree=<WT> checkout main -- .` | 0 | 2 |
| `git -C <clone> --work-tree <WT> checkout main -- .` | 0 | 2 |
| `git -C <clone> -c core.worktree=<WT> checkout main -- .` | 0 | 2 |
| `git -C <clone> --config-env=core.worktree=HOME checkout main -- .` | 0 | 2 |
| `GIT_WORK_TREE=<WT> git -C <clone> checkout main -- .` | 0 | 2 |
| `GIT_DIR=<WT>/.git git -C <clone> checkout main -- .` | 0 | 2 |
| `git -C <clone> --git-dir=<repo>/.git checkout main -- .` | 0 | 2 |
| `export GIT_WORK_TREE=<WT>; git -C <clone> checkout main -- .` | 0 | 2 |
| `git -C <clone> config core.worktree <WT>` | 2 | 2 |
| `TMPDIR=<repo>`, `git -C <WT> checkout main` (WT under TMPDIR) | 2 | — |

Sandbox, git 2.56.0: `git -C c --work-tree=<dir> checkout HEAD -- .` wrote `f` into `<dir>`, and so did `GIT_WORK_TREE=<dir>`. `-c core.worktree=<dir>` wrote nothing.

**Hypotheses.**
1. *The implementer's option loop never refuses the tree-pointing options, and the throwaway block does not check them.* What would refute it: a refusal reached for `--work-tree` in implementer mode. **Kept.** `:714`, `:717`, `:720` and `:723` all start with `[ "$mode" != reviewer ] ||`, and the table above shows exit 0.
2. *`check_temp_paths` should already catch `--work-tree=<WT>` as an `--opt=value` path.* What would refute it: the loop starting after the verb. **Discarded.** `:626` starts at `k = j + 1`, and options placed before the verb are never candidates.
3. *The clone is not judged a throwaway repo, so the checkout passes by another route.* What would refute it: a plain `git -C <clone> checkout main -- <WT>/f` refused with the throwaway path message. **Discarded.** `tests/bounds-messages.test.sh:69` exercises that route and it passes as a refusal, so the clone is judged throwaway (`:754`), and only the options before the verb slip through.

**The `export` row.** The lexer prints one simple command per line (`:315-317`), and the reviewer scan is per line (`:686-693`). It refuses `export GIT_WORK_TREE=…` because the word itself starts with `GIT_WORK_TREE=`, wherever git runs. An implementer check placed only on the git line would miss an `export` in an earlier simple command of the same call. The Bash tool keeps no env between calls, so scanning the whole command is enough.

## Story
Make the implementer's throwaway zone refuse the ways of pointing git at another tree, as the reviewer zone does, so that ADR-0072's "nothing leaves it" holds. The story fixes the major and the two minors of `docs/reviews/s98-bounds-messages.md`.
- `throwaway_refuses_another_work_tree`: in implementer mode, in a throwaway repo, these are refused: `--work-tree`, `-c core.worktree=…`, `--config-env` to that key, and a `GIT_WORK_TREE=` or `GIT_DIR=` assignment.
- `story_worktree_is_judged_first`: a story worktree placed under the temp dir is judged as a story worktree.
- `implementer_knows_the_file_url`: `method/agents/implementer.md` says that a local source is cloned from the temp dir with `file://<path>`.

## Current code
- `method/hooks/po-bounds.sh:668-790` is `check_bash`. It lexes the command (`:671`) and calls `temp_root` for every mode except qa (`:676`). Then it reads each simple command:
  - Lines `:686-693` run in reviewer mode only. Any `[uq]` word starting with `GIT_DIR=`, `GIT_WORK_TREE=`, `GIT_CONFIG_PARAMETERS=` or `GIT_CONFIG_COUNT=` is refused there, with the message "`<NAME>` points git elsewhere, forbidden to the reviewer".
  - Lines `:709-729` are the global option loop that finds the verb and the `-C` dir. Line `:725` repeats `--git-dir|--work-tree` and can never be reached.
  - Lines `:751-783` are the implementer branch. `throwaway` is computed at `:753-756`, `checkout` is allowed only when it is set (`:759-761`), and the paths and redirects are checked when it is set (`:779-782`).
- `check_config_key` (`:662-666`) lowercases the key with `tr` for bash 3.2, then denies `core.worktree`.
- `method/agents/implementer.md:23` says "clone it under the temp dir, where `git checkout` is allowed as long as every path and redirection stays under it (ADR-0072)". It does not mention `file://`.
- The header comment `:9-14` describes the implementer's throwaway rule. Lines `:34-38` list the reviewer's "Everywhere" refusals.

## Attachment points
- The option loop `:713-724`. In non-reviewer modes it must *record* the pointers instead of skipping them, because `throwaway` is only known after the loop, once `-C` has settled `dir`.
- The throwaway block `:779-782`. The new refusals go there, before `check_temp_paths`.
- The reviewer env scan `:687-692`. Its case pattern is the one to share.
- `method/agents/implementer.md:23`.
- The new `tests/throwaway-zone-holds.test.sh`.

## Verified interfaces
- `try_story_of_dir <dir>` (`:62-71`) sets `TOP` and `STORY` and returns 1 outside a linked `story/*` worktree.
- `in_temp_zone <dir>` (`:89-102`) requires the physical dir, the common git dir and the top level to all be under `TMP_ROOT`.
- `check_temp_paths <base> <j>` (`:623-642`) and `check_redirects <shelldir>` (`:646-658`) read the arrays `vals`, `n`, `redirs` and `j` of `check_bash` through dynamic scope.
- `deny` (`:56`) prints `po-bounds: <msg>` and exits 2.
- In the lexer output (`:315-319`), a word is prefixed `c`, `q`, `u` or `r` and words are separated by `\037`. An assignment before the command word is typed `u` or `q`, never `c` (`cmdpos` skips it, `:350`).
- Tests:
  - `tests/run.sh` runs each `test_*` in its own `bash -c` with `lib.sh`, which gives `scratch_repo`, `contains` and `fail`.
  - `tests/bounds-messages.test.sh:9-27` holds `msg_lane`, `msg_input`, `msg_status`, `msg_stderr` and `expect_exit`. A test file cannot source another one without running its tests twice, so the new file needs its own copy of the helper.
  - `scratch_repo` calls `mktemp -d` *before* `msg_lane` exports `TMPDIR`, so `$SCRATCH` lies outside `$LANE_TMP`.

## Traps
- **Frozen phrases.**
  - `tests/bounds-messages.test.sh:76-79` freezes `'never checkout, switch or stash in the story worktree'` and ``'clone it under the temp dir, where `git checkout` is allowed'`` in `implementer.md`. Both phrases must stay.
  - `tests/installer.test.sh:199` freezes ``'`file://<chemin>`'`` in a doc. Not this story's files.
- **Tests that freeze the reviewer.** `tests/bounds.test.sh:539-553` freezes reviewer exit codes for `core.worktree` and `GIT_CONFIG_*`. No test greps the text "forbidden to the reviewer" (grep over `tests/`), so the `check_config_key` message can name the mode.
- **The qa mode goes through the same option loop.** Recording pointers there is harmless, because the qa branch (`:731-732`) never reads them, but the qa behaviour must stay unchanged.
- **The story worktree keeps its ADR-0050 behaviour.** `GIT_DIR=`/`--git-dir` before `commit` in a story worktree stays accepted (ADR-0050:48). This story touches the throwaway repo only.
- **Not hook bugs.** A `git config core.worktree <WT>` written in a clone is already refused by `check_temp_paths` (table above). An `export` from an earlier Bash call is an accepted bypass (ADR-0052:37), and env does not persist between calls anyway.
- **Under gawk only.** The lexer is unchanged. Only bash changes, and it must stay bash 3.2 compatible: no `${x,,}`, no `declare -A`.
- **Out of Owns.** `docs/installation.md:87-90` already describes the throwaway rule without listing these options, and the hook change makes its "rien n'en sort" claim true. It is not in `Owns`.

## Open questions
- Does "comme en mode reviewer" cover `--git-dir`, `GIT_CONFIG_PARAMETERS=` and `GIT_CONFIG_COUNT=`, which the criterion does not name? The plan answers yes: the reviewer set is taken whole, since each of them can point git at another tree or carry a `-c`.
- Should a command-wide scan for `GIT_*=` words refuse an `export` placed *after* the git call? The plan answers yes, because the scan is simpler and over-refusing here only costs a rewrite. It is noted in the pivot.

## Complexity
Story: 2. After reading: 2. Every change is local to `check_bash` plus one sentence of text, with three tests.

## Split
— (not at 5)
