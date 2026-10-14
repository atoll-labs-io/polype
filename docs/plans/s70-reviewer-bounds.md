---
validated: yes
---
# Plan — s70-reviewer-bounds

[Story](../stories.md) · [Research](../research/s70-reviewer-bounds.md)

Branch `story/s70-reviewer-bounds`. Read `docs/research/s70-reviewer-bounds.md` first; this plan builds on it without repeating it. The design is fixed by `docs/decisions/ADR-0047-le-reviewer-tenu-par-po-bounds-en-mode-reviewer.md`, which the planner wrote and the implementer commits with the code.

## Story
The `reviewer` subagent gets a PreToolUse hook, `po-bounds.sh reviewer`. The hook keeps the reviewer from pushing, committing, or writing outside the story it reviews. The edit, test, restore and `git diff --exit-code` loop of the bite proof, and the probes in throwaway repos under the temp dir, keep working.

Acceptance criteria:
- `reviewer_declares_a_pretooluse_hook` — the reviewer's frontmatter calls `po-bounds.sh reviewer` on Edit, Write and Bash. When the script cannot be launched, the hook exits 2.
- `reviewer_writes_only_in_its_story_or_temp` — in mode `reviewer`, Write and Edit pass only in the reviewed story's worktree or under the system temp dir.
- `reviewer_git_is_read_only_outside_restores` — in mode `reviewer`, only reading git verbs pass, plus the restore of a file of the story worktree (`git checkout -- <path>`, `git restore <path>`). The hook refuses `push`, `commit`, `reset`, `stash`, `branch`, `merge`, and any git command outside that worktree or outside a throwaway repo of the temp dir.
- `reviewer_bounds_fail_closed` — a story the hook cannot find, or input it cannot read, is refused.

Reading of AC3 (ADR-0047): the verb list holds in the story worktree. A throwaway repo of the temp dir takes any verb except `push`/`send-pack`. `push` is refused everywhere.

## Tasks
1. [x] **Mode `reviewer` in the dispatcher and the header** — `method/hooks/po-bounds.sh`.
   - Accept `reviewer` at `:548-551`. Update the deny text to "implementer, qa or reviewer".
   - Add `reviewer:Write|reviewer:Edit` to the `case` at `:558-573`. It reads `file_path` as the implementer branch does and calls `check_write_reviewer`.
   - Add `reviewer:Bash`. It reads `command` and `cwd` as `:567-570` does and calls `check_bash "$cmd" "$cwd" reviewer`. You may fold it into the existing `implementer:Bash|qa:Bash` arm.
   - Add a `po-bounds.sh reviewer` paragraph to the header comment (`:1-27`) that states the two zones and the global refusals in ADR-0047's terms.
   - Fails: `reviewer_writes_only_in_its_story_or_temp`, whose allowed cases get exit 2 while the mode is unknown.
2. [x] **Zone helpers** — same file, next to `story_of_dir` (`:36`). Add:
   - `try_story_of_dir <dir>`. It does what `:37-44` does, but returns 1 instead of denying. Rewrite `story_of_dir` as `try_story_of_dir "$2" || deny "$1"`, so implementer and qa behave exactly as before.
   - `temp_root`. It sets `TMP_ROOT` to the physical `${TMPDIR:-/tmp}` (`cd -P … && pwd -P`). It sets it empty when that dir does not exist or resolves to `/`.
   - `in_temp_zone <existing dir>`. The physical dir must equal `TMP_ROOT` or lie under it. If `git -C <dir> rev-parse --path-format=absolute --git-common-dir` succeeds, that common dir, resolved physically, must lie under `TMP_ROOT`. If `--show-toplevel` succeeds, the top level must too. A linked worktree of the real repo placed in the temp dir therefore fails.
   - Fails: `reviewer_writes_only_in_its_story_or_temp` (the `main-wt` and symlink cases) and `reviewer_bounds_fail_closed` (`TMPDIR=/`).
3. [x] **`check_write_reviewer <path>`** — next to `check_write_qa` (`:217`).
   - Call `resolve_path`.
   - If `try_story_of_dir "$NEAREST"` succeeds: `RESOLVED` must lie under `TOP`, and `rel` must not be `.git` or start with `.git/`. Then call `owns_line "$TOP" "$STORY"`; it denies a story absent from `docs/stories.md` at the fork point, or one without an Owns line. Then `exit 0`. The reviewer is not bound to Owns: the bite proof may touch any file of the worktree.
   - Otherwise, if `TMP_ROOT` is set, `RESOLVED` lies under it, and `in_temp_zone "$NEAREST"` → `exit 0`.
   - Otherwise deny, naming the path, "outside a story worktree and outside the temp dir" and the temp root.
   - Fails: `reviewer_writes_only_in_its_story_or_temp` and `reviewer_bounds_fail_closed` (the ghost case).
4. [x] **Git in mode reviewer** — `check_bash` (`:457-545`).
   - (a) Move the qa checks at `:491-515` (`--output`, `worktree list`, the allowlist, `symbolic-ref` forms) into a function `check_git_read <verb> <j>` that works on `vals`/`n`/`cmd`, or pass them as arguments. Mode qa calls it unchanged. The deny messages may say "mode $mode" instead of "mode qa", but must keep their meaning.
   - (b) Reviewer, for each simple-command line: deny when an unquoted (`u`) word starts with `GIT_DIR=` or `GIT_WORK_TREE=`.
   - (c) Reviewer, in the option loop `:481-488`: deny `--git-dir`, `--git-dir=*`, `--work-tree` and `--work-tree=*`, guarded by `[ "$mode" = reviewer ]` so the implementer is unchanged.
   - (d) Reviewer, per git call:
     - Deny `push` and `send-pack` first.
     - Compute `dir` from `cur` and `gdir` as at `:532-533`. It must exist, or deny.
     - If `try_story_of_dir "$dir"` succeeds: call `owns_line "$TOP" "$STORY"`. `checkout` passes only when `vals[j+1]` is `--` and a path follows. `restore` passes only with options among `-q --quiet -W --worktree --` and at least one path; any other option word (`--staged`, `--source=…`, `-S`…) is denied. Every other verb goes through `check_git_read`.
     - Else if `in_temp_zone "$dir"`, any verb passes.
     - Else deny, naming the directory and the temp root.
   - Call `temp_root` once before the loop, in mode reviewer only.
   - Do not touch `lex_command`.
   - Fails: `reviewer_git_is_read_only_outside_restores`. Mode qa's existing `test_qa_writes_are_bounded_by_the_hook` and `test_qa_allowlist_refuses_writing_forms` fail if (a) changes qa.
5. [x] **`method/agents/reviewer.md`**.
   - Add to the frontmatter, after `skills:`, the block from `implementer.md:8-13` with `reviewer` as the mode: `matcher: "Edit|Write|Bash"`, `command: '"$CLAUDE_PROJECT_DIR"/.polype/hooks/po-bounds.sh reviewer || exit 2'`. Leave `tools:` as it is: no Write.
   - In `## Limits`, add a few sentences:
     - The hook allows Edit only in the story worktree or under the temp dir.
     - In the worktree, git reads only, plus `git checkout -- <path>` and `git restore <path>`.
     - A throwaway repo goes under the temp dir, its path written literally (the hook does not expand a variable).
     - `push` is refused everywhere.
     - Exact phrase: "A po-bounds refusal is a stop: report what it refused, and never reach the same result by another route; if the review needs that gesture, the review is blocked."
   - Keep `git diff --exit-code` (`tests/review.test.sh:13`).
   - Fails: `reviewer_declares_a_pretooluse_hook`.
6. [x] **Tests** — `tests/bounds.test.sh`, a `# s70` section at the end, four functions named as the AC.
   - Helpers:
     - `reviewer_lane` calls `lane`, then sets `TMPROOT="$(mktemp -d)"`, `trap 'rm -rf "$SCRATCH" "$TMPROOT"' EXIT` and `export TMPDIR="$TMPROOT"`. It runs `git init -q "$TMPROOT/probe"` and `git -C "$SCRATCH" worktree add -q --detach "$TMPROOT/main-wt"`.
     - `rev_status` is `status_with "$(hook_input …)" reviewer`. The hook input's cwd is `$SCRATCH`, the main checkout.
   - **The temp root must not be inside `$SCRATCH`** (research, Traps).
   - The cases are listed below.

### Test cases (task 6)
- `reviewer_declares_a_pretooluse_hook`:
  - The frontmatter has `  PreToolUse:` and a matcher covering Edit, Write and Bash.
  - `hook_command "$REVIEWER"` contains `.polype/hooks/po-bounds.sh reviewer`.
  - Run the hook as in `:66-83`, with an allowed Edit in `$WT`: no script → 2, script without the exec bit → 2, executable script → 0.
  - `contains "$REVIEWER" 'A po-bounds refusal is a stop'`.
- `reviewer_writes_only_in_its_story_or_temp`:
  - 0: Edit `$WT/src/other.sh` (outside Owns), Write `$WT/src/app.sh`, Write `$TMPROOT/notes/deep/x.md`, Edit `$TMPROOT/probe/f`.
  - 2: Edit `$SCRATCH/src/app.sh`, Write `$TMPROOT/main-wt/x`, Edit `$WT/.git`, Write `$TMPROOT/../x`, and Write `$TMPROOT/link/src/x` where `link` → `$SCRATCH`.
- `reviewer_git_is_read_only_outside_restores`:
  - 0, story worktree: `git -C $WT status`, `cd $WT && git diff --exit-code src/app.sh`, `git -C $WT checkout -- src/app.sh`, `git -C $WT restore src/app.sh`, `git -C $WT restore --worktree -- src/app.sh`, `git -C $WT worktree list`.
  - 0, temp repo: `git -C $TMPROOT/probe commit -m x`, `cd $TMPROOT/probe && git branch x && git reset --hard`, `cd $TMPROOT && git init other`.
  - 2, in `$WT`: `push`, `commit -m x`, `reset --hard`, `stash`, `branch x`, `merge main`, `checkout main`, `checkout -b x`, `checkout --`, `restore`, `restore --staged src/app.sh`, `restore --source=main src/app.sh`, `diff --output=x`.
  - 2, main checkout: `git status` with cwd `$SCRATCH`, and `git -C $SCRATCH log`.
  - 2, temp: `git -C $TMPROOT/probe push`, `git -C $TMPROOT/main-wt commit -m x`, `GIT_DIR=$SCRATCH/.git git -C $TMPROOT/probe log`, `git --git-dir=$SCRATCH/.git -C $TMPROOT/probe log`, `cd "$(mktemp -d)" && git init`.
  - 2, the s62 incident shape: a quoted heredoc to a file, closed, then `git push` on the next line.
- `reviewer_bounds_fail_closed`:
  - 2: Edit in `s99-ghost`; `git -C <s99-ghost> status`; Edit in `s02-bare`; `not json`; empty input; Edit without `file_path`; Bash without `command`; a relative path; `NotebookEdit`; Bash `git status` with no `cwd` field (an absolute `-C` needs no cwd, so do not test that one).
  - 2: Write `$TMPROOT/x` with `TMPDIR=/`, and again with `TMPDIR=$TMPROOT/missing`.

## Run interdicts
- `lex_command` (`method/hooks/po-bounds.sh:234-455` today) ends with no changed line. s71 rewrites the lexer, so keep this diff out of it.
- Modes `implementer` and `qa` behave exactly as before. Every existing test of `tests/bounds.test.sh` stays byte-identical (`git diff main...story/s70-reviewer-bounds -- tests/bounds.test.sh` shows only additions after `:372`) and green.
- `method/agents/reviewer.md`'s `tools:` line is unchanged: no Write (`tests/review.test.sh:11`, `tests/lint.test.sh:80-83`).
- These have an empty diff: `method/AGENTS.md`, `docs/installation.md`, `tests/structure.test.sh`, `method/skills/review-antihallu/`, `method/agents/implementer.md`, `method/agents/qa.md`, `.claude/`, `.polype/`, and ADR-0039.
  - The stale po-bounds sentences in `method/AGENTS.md:123` and `docs/installation.md:80-103` are reported, not fixed: they lie outside Owns.
- No new dependency: jq and POSIX tools only, and no `realpath`.
- No change to `tests/lib.sh`. The temp-root fixture lives in `tests/bounds.test.sh`.

## The pivot
**The two-zone reading of AC3**: read and restore only in the story worktree; any verb but push in a throwaway repo of `${TMPDIR:-/tmp}`. It could be wrong in three ways.
- **The author meant `commit`/`branch` refused even in throwaway repos.** Compare with the probes of `docs/reviews/s62-bounds-scan.md` and `s69-owns-overlap-globs.md`, which build lanes in `/tmp` with commits and worktrees. If the reviewer of this story reads AC3 literally, it's the ADR it should contest, not the code.
- **`TMPDIR` in a real reviewer session is not where the reviewer writes.** Under a Claude Code sandbox it may be a per-session dir, and `/tmp/x` would then be refused. That fails closed, and the first real review shows it (Not verified).
- **"Story found" through `owns_line`** also refuses a story whose Owns line is missing. That is stricter than the AC asks, and deliberate: such a story cannot pass the review's scope check anyway.

## Files touched
- `method/hooks/po-bounds.sh`
- `method/agents/reviewer.md`
- `tests/bounds.test.sh`
- `docs/decisions/ADR-0047-le-reviewer-tenu-par-po-bounds-en-mode-reviewer.md` (written by the planner, named here so the review counts it in scope)
- `docs/research/s70-reviewer-bounds.md`, `docs/plans/s70-reviewer-bounds.md` and `docs/verif/s70-reviewer-bounds.md`

## Test strategy
- Four bash tests in `tests/bounds.test.sh`, one per AC, all at the hook's layer: feed JSON to the script, read the exit code. This is within `Test budget` (25).
  - Each test fails if its rule is removed. Allowing everything in mode reviewer breaks the 2-cases. Refusing everything breaks the 0-cases: the bite-proof restores and the temp-repo commit.
  - The frontmatter test fails if the `hooks:` block or `|| exit 2` goes away.
- The qa refactor is guarded by the existing qa tests. No new qa test.
- During the tasks, run `bash tests/run.sh bounds.test.sh`. At the end, run the full suite once through `po-run --story s70-reviewer-bounds --label "Unit suite" -- "bash tests/run.sh"` (`Full suite: execute-end`). There is no type check (`Typecheck: —`).
- No visual check: no screen.

## Done when
- The four AC tests and the whole suite are green, recorded by `po-run`, and the interdicts above hold.
- One commit carries the code, the tests, ADR-0047, the research, the plan and the record.
- A review leaves no open critical. Ship is a squash on `main`.
