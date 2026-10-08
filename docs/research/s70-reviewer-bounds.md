# Research — s70-reviewer-bounds

## Structuring facts
- No false assumption, but two that need a reading. AC3 lists `commit`, `reset`, `branch`, `merge` as refused, while the Notes ask that the M6/M7 probes in throwaway repos under `/tmp` keep working, and those probes commit and branch. The only reading that keeps both: the verb list holds **in the story worktree**; a throwaway repo of the temp dir takes any verb except `push` (ADR-0047).
- The reviewer has no Write tool (`method/agents/reviewer.md:4`, guarded by `tests/review.test.sh:11` `lacks_tool "$AGENT" Write`). AC1/AC2 still name Write: the matcher covers it and the mode bounds it, but `tools:` must not gain Write.
- `po-bounds.sh` knows two modes, `implementer` and `qa` (`method/hooks/po-bounds.sh:547-551`). Any other mode is denied, so a project whose `.polype/hooks/po-bounds.sh` predates s70 refuses **every** Edit and Bash call of the new reviewer until `polype init` refreshes it.
- The hook gets no story id. It finds the story from the worktree that holds the path (`story_of_dir`, `:36-45`, ADR-0024). "The story being reviewed" can only mean "a linked worktree on a `story/<id>` branch whose story `docs/stories.md` holds at the fork point".
- The tests' scratch repo lives under `mktemp -d`, so under `/tmp` (`tests/lib.sh:46-47`). A temp rule built on `/tmp` would make every fixture a "throwaway repo". The rule must read `${TMPDIR:-/tmp}` so a test can point it elsewhere.

## Story
The reviewer must not be able to push, commit, or write outside the story it reviews, so a probe that escapes can never touch the main checkout. Incident: during the s62 review (loop 1), a probe heredoc closed too early and `git push` ran six times in the main checkout (`docs/reviews/s62-bounds-scan.md:12-17`).
AC: `reviewer_declares_a_pretooluse_hook`, `reviewer_writes_only_in_its_story_or_temp`, `reviewer_git_is_read_only_outside_restores`, `reviewer_bounds_fail_closed`.
Owns: `method/hooks/po-bounds.sh`, `method/agents/reviewer.md`, `tests/bounds.test.sh`. Complexity 4 (main risk: the edit-then-restore of the bite proof).

## Current code
`method/hooks/po-bounds.sh` (574 lines):
- `:1-27` header comment, one paragraph per mode. A third mode must be described there.
- `:30` `deny` exits 2. `:33` the EXIT trap turns any status other than 0/2 into 2.
- `:36-45` `story_of_dir <msg> <dir>` sets TOP and STORY, or **denies**. It cannot be used to *try* a zone; it needs a non-denying twin.
- `:49-64` `resolve_path`: absolute path required, symlink at the path refused, physical `RESOLVED` and `NEAREST` (deepest existing dir).
- `:94-117` `owns_line <top> <id>`: reads the story's Owns line at the fork point. It denies when the story is missing (`:113`) or has no Owns line (`:112`). This is the "story found" check AC4 needs.
- `:119-137` `check_write` (implementer: `docs/` free, else Owns). `:217-225` `check_write_qa`.
- `:227` `join_dir`. `:229` `QA_GIT_VERBS`, the read allowlist (ADR-0026).
- `:234-455` `lex_command`, the awk lexer (ADR-0039). Each simple command becomes a line of `\037`-separated words, typed `c`/`q`/`u`. Here-documents fed to a shell, and the quoted arguments of `sh -c`/`eval`, are lexed again as commands (`:281-282`, `:331`).
- `:457-545` `check_bash <cmd> <cwd> <mode>`. It tracks `cd` (`:474-477`). It finds unquoted `git` (`:479`) and walks the global options (`:481-488`: `-C` kept as `gdir`, `-c`/`--git-dir`/`--work-tree`/`--namespace` skipped with their value, other `-*` skipped). The qa branch is `:490-515`: `--output` refused, `worktree list` only, the allowlist, `symbolic-ref` read forms only. The implementer branch is `:516-537`, and its directory check is `:532-535`.
- `:547-574` the dispatcher: mode check, `jq` check, `tool_name`, then a `case "$mode:$tool"`. Edit is refused in mode qa through the default branch `:572`.

`method/agents/reviewer.md` (48 lines): no `hooks:` block (`:1-11`). `tools: Read, Grep, Glob, Bash, Edit` (`:4`). Limits (`:26-27`): it may edit only to disable the rule of step 4, undoes the edit and proves it with `git diff --exit-code`. "You write no file".

`tests/bounds.test.sh` (372 lines): `lane` (`:10-32`) builds `$SCRATCH` with worktrees `s01-demo`, `s02-bare` (no Owns), `s03-en`, `s99-ghost` (absent from stories.md). The helpers are `hook_input` (`:34-37`, cwd = `$SCRATCH`), `status_with <input> <mode>` (`:40`), `expect` (`:47`) and `hook_command [agent]` (`:49-52`). `qa_status` (`:156`). The "script cannot run" pattern is at `:66-83` and `:180-189`.

## Attachment points
- Dispatcher `po-bounds.sh:548-551` (accepted modes) and `:558-573` (new cases `reviewer:Write|reviewer:Edit`, `reviewer:Bash`).
- A new `check_write_reviewer`, next to `check_write_qa` (`:217`).
- `check_bash` per-git-call branch `:490`: the qa read checks become a shared function, called by qa and by the reviewer's story zone.
- `reviewer.md` frontmatter (`:1-11`) gets the `hooks:` block in the exact form of `implementer.md:8-13`, plus a sentence in Limits (`:26-27`).

## Verified interfaces
- Hook wiring form, `method/agents/implementer.md:8-13`: `matcher: "Edit|Write|Bash"`, `command: '"$CLAUDE_PROJECT_DIR"/.polype/hooks/po-bounds.sh implementer || exit 2'`. `qa.md:8-13` uses the same form with `qa`.
- The refusal sentence: `implementer.md:55` "A po-bounds refusal is a stop: …" and `qa.md:53`. `tests/bounds.test.sh:63` asserts the implementer's.
- Bite proof, `method/skills/review-antihallu/SKILL.md:42`: disable a rule, run only the test files that exercise it, undo it, confirm with `git diff --exit-code <file>`. The undo may be an Edit back, `git checkout -- <file>` or `git restore <file>`. All three must pass in the story worktree.
- Scope check, `review-antihallu/SKILL.md:11-14`: `git diff --name-only`, `git worktree list`, "branch not merged". These are reads. `git branch --merged` will be refused (AC3 names `branch`); `merge-base --is-ancestor` and `log` remain.
- `/po-review` dispatches `subagent_type: reviewer` (`method/commands/po-review.md:29`). `/po-drive` uses the same prompt (`method/commands/po-drive.md:97`). The reviewer's session cwd is the caller's, usually the repository root, so git calls without `-C <worktree>`/`cd <worktree>` land in the main checkout. Its own file already asks for `-C` (`reviewer.md:19`).
- `bin/po-eval:161` runs `claude -p --agent reviewer` with cwd = the eval worktree. Its repo is built with `polype install` (`evals/lib.sh:149`), so `.polype/hooks/po-bounds.sh` exists there and `CLAUDE_PROJECT_DIR` is the worktree.
- Existing tests that read `reviewer.md`: `review.test.sh:11-13` (no Write, has Edit, contains `git diff --exit-code`), `lint.test.sh:80-83` (a mutant adding Write is flagged), `wiring.test.sh`, `ownership.test.sh`, `review-lenses.test.sh`, `qa-gate.test.sh:113` (reads `QA stage`). None checks that a `hooks:` block is absent.

## Traps
- **Scratch under /tmp.** A temp root inside `$SCRATCH` would sit inside the scratch repo's work tree. A "throwaway repo" check that asks git for the enclosing repo would then reject it. The test temp root must be a separate `mktemp -d`, with the EXIT trap widened to remove it.
- **Linked worktree of the real repo placed in the temp dir.** It sits under the temp dir, but its common git dir is the real one, so its commits land in the real repository. The temp rule must require the enclosing repo's common dir (and top level) to lie under the temp dir too.
- **TMPDIR `/` or unset-and-weird.** A temp root resolving to `/` would cover everything, so it must be refused. A TMPDIR that does not exist disables the temp zone.
- **Variables are not expanded** by the lexer. `cd "$(mktemp -d)" && git init` gives `cd` an empty or literal word, which resolves to the cwd → refused. Probes need literal paths. The shell forgets variables between calls anyway, so the reviewer reads `mktemp -d`'s output and reuses it literally.
- **Bash writes are not seen.** Redirections, `cp`, `sed -i` and scripts that run git (`bash tests/run.sh`) are outside the hook, as for the implementer (`docs/installation.md:92-96`). A test suite that commits in its own scratch repos must keep running.
- **Upgrade.** The new `reviewer.md` with an old `po-bounds.sh` refuses everything (`:550`). `docs/installation.md:100-103` documents this for the implementer only, and it lies outside this story's Owns.
- **Doc drift outside Owns.** `method/AGENTS.md:123` says po-bounds holds "the `implementer` and `qa` subagents", and `tests/structure.test.sh:82` pins that phrase. Both lie outside Owns (`method/AGENTS.md` is in s72's Owns). Leave them alone and report them.
- **s71 depends on s70** and owns the same hook and test file. Keep the lexer (`:234-455`) untouched so its diff stays readable.
- No migration, no new dependency (jq is already required, ADR-0024).

## Open questions
- Does `claude -p --agent <name>` honour frontmatter hooks the way an Agent-tool dispatch does? The next `po-eval` run shows it. Not settled here.
- Should a reviewer of s70 be stopped from editing another lane's worktree? The hook cannot know the id. The plan accepts the gap (ADR-0047).

## Complexity
Story: 4 → after reading: 4. Two zones with different rules, a refactor of the qa branch that must keep qa unchanged, and the temp-dir fixture trap. It fits one story without a split.

## Split
Not needed (below 5).
