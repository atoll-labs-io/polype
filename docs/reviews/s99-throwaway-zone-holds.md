# Review: s99-throwaway-zone-holds

[Story](../stories.md) · [Plan](../plans/s99-throwaway-zone-holds.md) · [Verification](../verif/s99-throwaway-zone-holds.md)

Reviewed tree: ea5b8c07cd7bb30ccc34a33a6544ed09d472eea8
Fix loop: 0
Branch: `story/s99-throwaway-zone-holds` (commit 6491849), worktree `/home/lecrabe/dev/atoll/polype/.worktrees/s99-throwaway-zone-holds`
Scope: `git diff main...story/s99-throwaway-zone-holds`
Lenses run: Security (`method/hooks/po-bounds.sh`, a permission and policy hook that decides which git calls a subagent may make)

## Scope check (Owns)
Changed paths: `method/hooks/po-bounds.sh` (M), `method/agents/implementer.md` (M), `tests/throwaway-zone-holds.test.sh` (A), and `docs/research|plans|verif/s99-throwaway-zone-holds.md` (A).
- Every code path is an exact file entry of the story's `Owns` line. The three docs files are the story's own pipeline evidence.
- No overlap with the other running story, `s100-qa-evidence-set-aside`, whose `Owns` covers only `method/agents/qa.md`, `method/skills/qa-drivers/*` and its own two tests.
- The run interdicts hold: `.claude/`, `.polype/`, `docs/decisions/`, `tests/lib.sh`, `tests/bounds.test.sh` and `tests/bounds-messages.test.sh` are untouched, and the lexer is unchanged.

## What was relied on
- `po-gate verif-current s99-throwaway-zone-holds` exits 0. `docs/verif/s99-throwaway-zone-holds.md` is complete, and its Unit suite row (`bash tests/run.sh`) exits 0 on code equal to this tree. With `Verification mode: record` I did not rerun the full suite.
- The project has no type check, E2E or build command (`Typecheck: —`, `E2E: —`, `Build: —`).
- I did run the three touched test files myself as the baseline for the bite step: 39 passed, 0 failed.
- `QA stage: —`, so this story has no QA and needs none.

## Step results
1. **Record:** current (see above).
2. **References:** all resolve.
   - `check_config_key` uses `$mode` and `$cmd`, which it reads from `check_bash`'s locals through dynamic scope.
   - `git_env_word` is new and called in two places (the reviewer scan and the implementer's command-wide scan).
   - `try_story_of_dir`, `in_temp_zone`, `check_temp_paths` and `check_redirects` are unchanged and called with their existing signatures.
   - The sentence added to `implementer.md` is true: from a temp-dir cwd, `check_temp_paths` refuses a bare local source path, and `file:///…` resolves as a relative word under the temp dir. ADR-0072:34 says the same.
3. **Plan:** tasks 1–5 are all present, with nothing unrequested.
   - The reviewer messages are byte-identical. With `$mode=reviewer`, `check_config_key` still prints "forbidden to the reviewer".
   - Pointers are refused only when `throwaway=yes`. That keeps ADR-0050:48 (`GIT_DIR=` before `commit`/`reset` in a story worktree) as it is, and the exit-0 control `GIT_DIR=… git -C $WT log` checks it.
4. **Floor and bite:**
   - `po-gate floor-guard s99-throwaway-zone-holds main` exits 0: nothing was lowered.
   - 3 tests, within `Test budget` 25. None of the six kinds of test that prove nothing: the fixtures are real repos, and the hook gets real JSON input.
   - Bite, running only `throwaway-zone-holds.test.sh`, `bounds-messages.test.sh` and `bounds.test.sh`, and restoring after each with `git checkout -- method/hooks/po-bounds.sh` plus `git diff --exit-code` (clean every time):
     - A. Dropped the `pointer` deny (line 805): 1 test failed (`throwaway_refuses_another_work_tree`).
     - B. Dropped the `cfgs` → `check_config_key` loop (line 806): 1 failed (same test).
     - C. Dropped the `envpoint` deny (line 807): 1 failed (same test).
     - D. Removed `! try_story_of_dir "$dir" &&` from the throwaway condition (line 779): 1 failed (`story_worktree_is_judged_first`). This closes s98's m2.
5. **Values:**
   - The four `GIT_*=` names match the reviewer set exactly.
   - `core.worktree` is lowercased before the comparison (the test has a `Core.WorkTree` row).
   - git's top-level `--work-tree`, `--git-dir` and `-c` take no abbreviated forms, so exact matching is enough.
6. **Neighbours:**
   - The qa mode now records `pointer` and `cfgs` but never reads them, so qa behaviour is unchanged (`bounds.test.sh` is green and untouched).
   - The reviewer branch keeps its deny-first order.
   - Other ways to point git elsewhere were checked:
     - A `.git` file, or a `core.worktree` written into the clone's config by a non-git command, is already caught by `in_temp_zone` (common dir and top level must lie under the temp dir).
     - Verbs other than `checkout` in the throwaway repo go through the same new block.
     - `reset`/`commit` there still require a `story/*` worktree.

## Findings
- **minor** — `method/hooks/po-bounds.sh:806`. In a throwaway repo, `-c core.worktree=…` / `--config-env` is refused with `check_config_key`'s message, "core.worktree points git elsewhere, forbidden to the implementer". The two sibling refusals (lines 805 and 807) end with "…in a throwaway repo". The wording is inconsistent, and it gives the implementer less context than the other two. No test pins either form.
- **minor** — `method/hooks/po-bounds.sh:697` (implementer prescan) and `:710` (reviewer scan). `git_env_word` is called through `$(…)`, which forks a subshell for every word of every command. In implementer mode this happens until a match; in reviewer mode, for every word of every line. The old reviewer scan was a fork-free `case`. Potential impact: hook latency grows with command length, on every Bash call of those two subagents. A `case` inline, or a function that sets a variable instead of printing one, would avoid the fork. Not measured (see Not verified).
- **minor** — the over-refusal accepted in the plan's pivot. The command-wide scan also matches a quoted argument that starts with `GIT_DIR=`, e.g. `grep 'GIT_DIR=' f; git -C <clone> checkout x`, and refuses the throwaway call. This follows ADR-0052 (a guard against mistakes) and costs one rewrite. Recorded so it stays visible, not as a defect.

Security lens: nothing beyond the above. The story narrows a write path; it opens none. The bypasses still open, and not covered by this story — a script run by `bash`, `bash -c "…"`, a `GIT_DIR` exported by an earlier call, `GIT_CONFIG_GLOBAL` — are the ones ADR-0050:45-49 and ADR-0052:35-37 already list and accept.

## Not verified
- **Hook latency on long commands.** My timing probe, which piped JSON into the old and new hooks, was refused by po-bounds ("a shell reading its commands from a pipe"). I stopped there and tried no other route. A person can time `printf '%s' "$input" | bash method/hooks/po-bounds.sh implementer` on a 400-word command against `main`'s version to put a number on the second minor.
- **Bash 3.2 and non-gawk awks.** Not run, as the record's "Not proven here" says. Only GNU bash and gawk ran. Someone with macOS should run `bash tests/run.sh throwaway-zone-holds.test.sh bounds.test.sh` under `/bin/bash`.
- **The installed copies.** `.claude/` and `.polype/` still hold the old hook until the post-ship refresh. Until then, the live implementer is not protected by this change.
- **The real git write.** That `--work-tree` / `GIT_WORK_TREE` actually write into another tree under git 2.56.0 comes from the research's sandbox run; I did not repeat it.

Max severity: minor
Ship allowed: yes
