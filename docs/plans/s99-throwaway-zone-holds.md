---
validated: yes
---
# Plan — s99-throwaway-zone-holds

[Story](../stories.md) · [Research](../research/s99-throwaway-zone-holds.md)

Branch `story/s99-throwaway-zone-holds`. Read `docs/research/s99-throwaway-zone-holds.md` first. This plan builds on it without repeating it, and its root cause and reproduction table are the starting point.

## Story
In implementer mode, the throwaway repo must refuse the ways of pointing git at another tree, the same ones the reviewer mode refuses. That makes ADR-0072's "rien n'en sort vers le worktree" true.

The story fixes the major and the two minors of `docs/reviews/s98-bounds-messages.md`. Its criteria:
- `throwaway_refuses_another_work_tree`
- `story_worktree_is_judged_first`
- `implementer_knows_the_file_url`

## Tasks
1. [x] **Share the reviewer's two checks with the implementer** (`method/hooks/po-bounds.sh`).
   - Add a helper `git_env_word <typed word>` next to `check_config_key`. When the word is `[uq]` and its value starts with `GIT_DIR=`, `GIT_WORK_TREE=`, `GIT_CONFIG_PARAMETERS=` or `GIT_CONFIG_COUNT=`, it prints the variable name and returns 0; otherwise it returns 1.
   - Rewrite the reviewer scan at `:687-692` on top of it. Its message stays byte for byte the same.
   - In `check_config_key` (`:665`), replace "forbidden to the reviewer" with "forbidden to the $mode". `$mode` is `check_bash`'s local, which the helper sees through dynamic scope.
   - No other reviewer logic changes.
   - Test that would fail: `tests/bounds.test.sh` `test_config_worktree_override_is_refused`, an existing test that freezes the reviewer's exit codes.
2. [x] **Record the pointers in the implementer's option loop, and refuse them in the throwaway repo** (`method/hooks/po-bounds.sh`).
   - *Command-wide scan.* In implementer mode, before the main loop of `check_bash`, run `git_env_word` once over every word of every lexed line and keep the first name in a local `envpoint`. The scan covers the whole command so that an `export` in an earlier simple command is caught (research, "The `export` row").
   - *Option loop.* Reset two locals at each git call (`j=$((i + 1))`): a string `pointer` and an array `cfgs`.
     - At `:713-718`, `--git-dir`/`--work-tree` keep their reviewer deny. In the other modes they set `pointer` to the option name, unless it is already set.
     - At `:719-724`, `-c`/`--config-env` keep their reviewer call to `check_config_key`. In the other modes they append their value to `cfgs`.
   - *Throwaway block.* At `:779`, before `check_temp_paths`, when `throwaway=yes`, run the checks in this order:
     - deny `git <pointer> points git elsewhere, forbidden to the implementer in a throwaway repo: $cmd`;
     - call `check_config_key` on each `cfgs` entry;
     - deny `<envpoint> points git elsewhere, forbidden to the implementer in a throwaway repo: $cmd`.
   - *Header.* Update the header comment `:9-14` to say that, in the throwaway repo, `--git-dir`, `--work-tree`, a `-c`/`--config-env` setting `core.worktree`, and a word starting with one of the four `GIT_*=` names are refused, as for the reviewer.
   - Bash 3.2 rules: no `${x,,}`, no associative array.
   - Test that would fail: `throwaway_refuses_another_work_tree` (task 4).
3. [x] **Say how to clone a local source** (`method/agents/implementer.md:23`).
   - Add one sentence after the ADR-0072 sentence: a local source is cloned from the temp dir as ``git clone file://<path> <dir>``, because a bare local path lies outside the temp dir and is refused.
   - Keep the frozen phrases `never checkout, switch or stash in the story worktree` and ``clone it under the temp dir, where `git checkout` is allowed``.
   - Test that would fail: `implementer_knows_the_file_url`.
4. [x] **Write `tests/throwaway-zone-holds.test.sh`** with its own lane helper.
   - The helper copies the shape of `msg_lane`/`msg_input`/`msg_status`/`msg_stderr` from `tests/bounds-messages.test.sh:9-27`, under new names (`zone_*`), since a test file cannot source another one.
   - `test_throwaway_refuses_another_work_tree`. Clone `$SCRATCH` into `$LANE_TMP/clone`, then:
     - Expect exit 2 in implementer mode for each of:
       - `--work-tree=$WT`
       - `--work-tree $WT`
       - `--git-dir=$SCRATCH/.git`
       - `-c core.worktree=$WT`
       - `-c Core.WorkTree=$WT`
       - `--config-env core.worktree=HOME`
       - `--config-env=core.worktree=HOME`
       - `GIT_WORK_TREE=$WT git …`
       - `GIT_DIR=$WT/.git git …`
       - `GIT_DIR="$WT/.git" git …` (quoted value, still an assignment)
       - `export GIT_WORK_TREE=$WT; git …`

       Each runs on `git -C $LANE_TMP/clone checkout main -- .`. One stderr is checked for the string `forbidden to the implementer in a throwaway repo`.
     - Expect exit 0 for these controls:
       - `git -C <clone> -c user.name=x checkout -q main`, which shows that the config check refuses only the key;
       - `git -C <clone> checkout -q main`.
     - Expect exit 0 for `GIT_DIR=$SCRATCH/.git git -C $WT log` in implementer mode. The story worktree keeps the behaviour that ADR-0050:48 accepts, so the refusal does not leak out of the throwaway repo.
   - `test_story_worktree_is_judged_first`.
     - Build the lane, then `export TMPDIR="$SCRATCH"`, so that the story worktree `$WT` and its common git dir both lie under the temp dir and `in_temp_zone "$WT"` is true.
     - Expect exit 2 for `git -C $WT checkout main` in implementer mode, with stderr holding `forbidden to the implementer outside a throwaway repo`.
     - Control: `git clone -q "$SCRATCH" "$SCRATCH/tmpclone"`, then `git -C $SCRATCH/tmpclone checkout -q main` exits 0. This proves that the same TMPDIR does yield a throwaway repo, so the refusal above comes from the story check at `:754` and not from a broken temp root.
   - `test_implementer_knows_the_file_url`: `contains "$METHOD/agents/implementer.md" 'file://<path>'`.
   - Run only `bash tests/run.sh throwaway-zone-holds.test.sh bounds.test.sh bounds-messages.test.sh`.
5. [x] **Record.**
   - Write `docs/verif/s99-throwaway-zone-holds.md` from `templates/verification-record.md`.
   - Run the full suite once: `.polype/hooks/po-run.sh --story s99-throwaway-zone-holds --label "Unit suite" -- 'bash tests/run.sh'`. There is no type check (`Typecheck: —`).
   - The record's "Not proven here" must say that `.claude/` and `.polype/` still hold the old hook until the post-ship refresh, and that only gawk ran.

## Scene viewpoints
—

## Run interdicts
- Each of these ends with an empty diff:
  - `.claude/`, `.polype/`;
  - `docs/decisions/` (ADR-0072 is unchanged, as the story says; ADR-0073 is not used);
  - `docs/installation.md`;
  - `docs/parite-killer-saas.md`;
  - `tests/lib.sh`, `tests/bounds.test.sh`;
  - `tests/bounds-messages.test.sh`. It is in `Owns`, but no change is needed: its frozen phrases stay true.
- The lexer `lex_command` (`po-bounds.sh:320-…`) is unchanged: `git diff` shows no line inside the awk program.
- The reviewer branch `:733-750` keeps its logic. Outside `check_config_key`'s wording, the reviewer's refusal messages are unchanged.
- The qa branch and qa behaviour are unchanged: `tests/bounds.test.sh` still passes untouched.
- Outside a throwaway repo, the implementer's rules are unchanged. No new refusal fires when `throwaway=no`; check the control in task 4.
- No file outside `Owns` and `docs/research|plans|verif/s99-throwaway-zone-holds.md`.
- No `git checkout`, `switch` or `stash` in the story worktree.

## The pivot
The fix refuses the tree-pointing forms **only when the call runs in a throwaway repo**, and it decides this after the option loop. The forms are recorded in that loop and judged once `throwaway` is known. Three ways this could be wrong:
- **Too narrow.** A git call outside the throwaway repo could still write into the story worktree through `--work-tree`. Compare with the implementer branch: `checkout`, the only verb this story opened, still requires `throwaway=yes`. `commit`, `reset` and the others require a `story/*` dir, which is ADR-0050's accepted bypass and outside this story.
- **Too wide.** The `GIT_*=` scan covers the whole command, so an `export GIT_DIR=…` placed *after* a throwaway git call, or in an unrelated subshell, is refused too. That is accepted: the hook guards against mistakes (ADR-0052), and over-refusing costs one rewrite.
- **The ordering is wrong.** The new refusals must run before `check_temp_paths`, so that their own message wins. The `cfgs` values are checked with the reviewer's `check_config_key`, not a copy. Compare with the story's note.

## Files touched
- `method/hooks/po-bounds.sh`
- `method/agents/implementer.md`
- `tests/throwaway-zone-holds.test.sh` (new)
- `docs/research/s99-throwaway-zone-holds.md`, `docs/plans/s99-throwaway-zone-holds.md`, `docs/verif/s99-throwaway-zone-holds.md`

## Test strategy
Three new tests, one per criterion, within `Test budget` 25. All three sit at the hook's own layer: real JSON piped into `po-bounds.sh`, with real repositories as fixtures.
- `throwaway_refuses_another_work_tree` bites when task 2's throwaway checks are removed, and only one of its rows needs to fail. Its exit-0 controls bite when the checks are made blanket: one refusal for every `-c`, or a refusal outside the throwaway repo.
- `story_worktree_is_judged_first` bites when `! try_story_of_dir "$dir" &&` is removed from `:754`: the checkout then passes. This closes review minor m2 (bite E).
- `implementer_knows_the_file_url` bites when the sentence is removed.
- No test replays the reviewer's forms: `tests/bounds.test.sh` already owns them.

Visual checks: none.

## Done when
- The three criteria's tests pass.
- `bash tests/run.sh` is green through `po-run`.
- The record is complete.
- There is one commit on `story/s99-throwaway-zone-holds`.
- The review has no open critical finding.
