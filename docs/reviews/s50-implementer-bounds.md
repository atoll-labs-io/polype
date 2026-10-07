# Review: s50-implementer-bounds

Diff reviewed: `git diff main...story/s50-implementer-bounds`, in a context that did not write it. Findings are rated critical, major or minor.

Review status: complete
Fix loop: 0

## Ownership
I listed the diff with `git diff --name-only main...story/s50-implementer-bounds` and held each path against the story's `Owns`: `method/agents/implementer.md`, `method/hooks/po-bounds.sh`, `bin/polype`, `docs/installation.md`, `tests/bounds.test.sh`.
- [x] `method/agents/implementer.md`, `method/hooks/po-bounds.sh`, `docs/installation.md` and `tests/bounds.test.sh` are inside `Owns`. `docs/research/`, `docs/plans/` and `docs/verif/s50-implementer-bounds.md` are the story's own evidence, so they are in scope by construction. `bin/polype` is in `Owns` but its diff is empty. The research and the plan say why: the installer already ships every file of `method/hooks/` and marks it executable (`bin/polype:98`, `:101`, `:143`), and I confirmed this.
- [x] Outside `Owns`: `docs/decisions/ADR-0024-po-bounds-trouve-la-story-par-son-worktree.md`. A written rule of `AGENTS.md` requires this path (Law 6: "Structural decisions are ADRs in `<ADR directory>NNNN-<slug>.md`"), so it is a gap in the story's `Owns`, not a breach by the implementer. Reported as **minor**.
- [x] Inside another running story's `Owns`: none. The only other unmerged lane is `story/s47-review-tree`, and its diff shares no path with this one.
- [x] The story has an `Owns` line (`docs/stories.md:755`).

## Evidence reused
- [x] `po-gate verif-current s50-implementer-bounds` passes (rc=0). `git diff --quiet 3f3052fc… HEAD -- . ':(exclude)docs'` is clean too. The record is complete, and every exit code in it is 0:
  - `bash tests/run.sh bounds.test.sh`: 7 passed
  - `bin/po-lint`: no breach
  - `bash tests/run.sh`: 241 passed

  I reused those results and did not rerun the suite. `Typecheck: —`: the project has no type check. `E2E: —` and `Build: —`: the project has neither. No routing or manifest changed. I read the record's "Not proven here" section: no live Claude Code session was run, nothing on macOS, and the trust limit is documented but untested.

## Plan
- [x] Tasks 1 to 6 are all present. Nothing is outside the plan except ADR-0024, which the plan itself says it writes.
- [x] Run interdicts, checked one by one:
  - These files have an empty diff: `bin/polype`, `bin/po-lint`, `method/hooks/po-gate.sh`, `method/hooks/pre-commit`, `method/AGENTS.md`, `method/skills/review-antihallu/`, `.claude/`, `.polype/`, `docs/stories.md` and `docs/parite-killer-saas.md`.
  - No hook was added to any `settings.json`, and no existing test file changed.
  - `po-bounds.sh` uses only builtins, `git`, `jq`, `awk`, `grep` and `dirname`. It does not use `python3` or `realpath`, and it reads no setting.
  - The script exits only with 0 or 2. An EXIT trap turns any other status into 2.
  - The tests stay inside `$SCRATCH` and `mktemp -d`, and the install test guards `CLAUDE_CONFIG_DIR`.

## References
- [x] I opened and confirmed every helper and installer reference:
  - `tests/lib.sh`: `frontmatter`, `contains`, `scratch_repo`, `ROOT` and `METHOD`.
  - `bin/polype`: `target_is_a_project`, `must_be_executable` and `lay_down`.
  - `bin/polype-dev-install`, which runs `polype install`.
  - `method/templates/stories.md` and the heading format of `docs/stories.md`.
- [ ] Claude Code facts: exit 2 is the only blocking code, the hook input carries `tool_name`, `tool_input.file_path`, `tool_input.command` and `cwd`, subagent frontmatter accepts `hooks:`, and `$CLAUDE_PROJECT_DIR` is exported. I took these from the research's citations of `code.claude.com` and did not reopen those pages (see Not verified).
- [ ] Some values only look right. The way `Owns` is parsed (backtick-quoted literal prefixes only) matches neither the template nor a real Polype project (finding 2).

## Rules
- [x] `AGENTS.md` conventions are respected:
  - The `Reads settings` rule is not affected: the script reads no setting.
  - The method file is in English, and `docs/installation.md` is in French.
  - Each test is named after its criterion.
  - There is one commit, in English.
- [x] No accepted ADR is contradicted. ADR-0022 is followed: frontmatter hooks, failing closed, no `settings.json`. ADR-0024 is followed as written, but its claim that `Owns` cannot be widened during a run only holds for an uncommitted edit (finding 1).

## Tests
- [x] The assertions pin down all seven criteria. The fixtures are sound:
  - `docs/stories.md` is committed in `lane()`, so the "uncommitted widening" case proves something.
  - The wrapper test reads the command from the frontmatter rather than retyping it.

  None of the six empty test shapes is present.
- [x] 7 tests, within the budget of 25.
- [x] Bite. I made six mutations, ran only `tests/run.sh bounds.test.sh` after each, then undid it and confirmed with `git diff --exit-code <file>`. The tree was clean at the end (`git diff --exit-code` and an empty `git status --porcelain`).
  - Owns check `[ "$allowed" = yes ] || deny` → `true`: **2 failing** (`bounds_deny_writes_outside_owns`, `bounds_hook_blocks_when_the_script_cannot_run`). Undone, clean.
  - `story_of_dir` check on `git commit` → `true`: **1 failing** (`bounds_deny_forbidden_git_verbs`). Undone, clean.
  - `push` removed from the forbidden verbs: **1 failing**. Undone, clean.
  - `Owns` read from the working file instead of `HEAD:docs/stories.md`: **1 failing** (`bounds_deny_writes_outside_owns`). Undone, clean.
  - `|| exit 2` removed from the frontmatter command: **1 failing** (`bounds_hook_blocks_when_the_script_cannot_run`, "expected exit 2, got 127"). Undone, clean.
  - Linked-worktree guard `[ "$gitdir" != "$common" ] || deny` (`po-bounds.sh:25`) → `true`: **0 failing**. This guard is not tested (finding 4).
- [x] No test is made useless by the story.

## Neighbours
- [x] I read the other places that touch the changed code, and nothing is broken:
  - Readers of the implementer's frontmatter (`bin/po-lint`, `tests/fleet-design.test.sh`, `tests/execute.test.sh`): the `hooks:` block sits after `skills:` and is indented four spaces, and the suite and the lint are green in the record.
  - `tests/gate.test.sh`, which copies every hook, is harmless.
  - The git commands that `method/agents/implementer.md` and `method/commands/po-execute.md` tell the implementer to run all pass the hook: `git -C … rev-parse`, `status`, `add -A`, `write-tree`, and `cd <wt> && git commit`.

## Findings
1. **major** — `method/hooks/po-bounds.sh:80` and `:53`: the implementer can widen its own `Owns` by committing. Every path under `docs/` is writable, `git commit` is allowed on `story/*`, and `Owns` is read from the worktree's `HEAD:docs/stories.md`. So the implementer can edit `docs/stories.md`, commit it, and then write outside its original `Owns`. I reproduced this in a scratch repository: after the widening commit, a write to `lib/evil.sh` returned 0. ADR-0024 says reading the committed copy closes self-widening during a run; it only closes the uncommitted case. The review's ownership check still catches the `docs/stories.md` change, so the damage is contained. A sturdier anchor would be the `docs/stories.md` at the story's fork point (the merge-base with the branch the worktree came from) or a refusal of writes to `docs/stories.md`. That choice belongs to the planner.
2. **major** — `method/hooks/po-bounds.sh:86` and `:88-91`: `Owns` entries count only when they are backtick-quoted literal paths or directory prefixes, but no Polype rule requires either.
   - `method/templates/stories.md` writes `- **Owns**: <paths…>` without backticks. A story written that way gets every write refused ("lists no path"); reproduced.
   - The real Polype project `~/dev/atoll/nautile` (no story shipped yet) has `crates/*/Cargo.toml` and `crates/*/src/lib.rs` in the `Owns` of `s05-walking-skeleton`. It also has an inherited rule: a story owning `crates/x/src/` also owns `crates/x/tests/`. A write to `crates/core/Cargo.toml` was refused; reproduced. Once that project upgrades, its implementer will be blocked on legitimate writes.

   This fails closed, with the refused path and the `Owns` line in the message, so there is no silent damage. The fix is either to define the `Owns` syntax in the template and in `/po-stories`, or to support globs.
3. **minor** — `method/hooks/po-bounds.sh:111` and `:120-133`: a word-level scan can be steered so that a commit lands off a story branch while the hook allows it. Examples: `(cd <wt>); git commit` (the `cd` happens in a subshell, but the scan still records it) and `git --git-dir=<root>/.git commit` (the `--git-dir=` form is skipped as an option). Both returned 0 in my reproduction. These are exotic forms, and ADR-0024 accepted a word scan, but the scan gets the target wrong, not just too strict. Worth naming in the ADR's consequences or in `docs/installation.md`.
4. **minor** — `method/hooks/po-bounds.sh:25`: disabling the linked-worktree guard fails no test. The "main worktree" case in `bounds_fail_closed` is refused by the branch check, because the main worktree there is on `main`. A main worktree checked out on a `story/<id>` branch is never exercised.
5. **minor** — `docs/decisions/ADR-0024-po-bounds-trouve-la-story-par-son-worktree.md`: outside the story's `Owns`, but required by Law 6 of `AGENTS.md`. This is a gap in the story's `Owns`, not a fault of the implementer.

## Not verified
- **The hook firing inside a subagent.** No live Claude Code session showed the frontmatter `hooks:` block running in a subagent, nor the value of `$CLAUDE_PROJECT_DIR` there. Neither this review nor the record could show it, because the tests run the declared command under `sh -c`. A person should launch `/po-execute` on a throwaway story, attempt a write outside `Owns`, and confirm the refusal reaches the subagent with the `po-bounds:` message.
- **The trust limit.** That project-level `.claude/agents/` hooks are skipped without folder trust and in `claude -p` is documented, not tested. A person should run one `claude -p` implementer under `polype install <project>` and see whether writes outside `Owns` pass.
- **The Claude Code documentation.** I did not reopen the pages cited by the research (exit-code semantics, input fields, subagent `hooks:` support, `$CLAUDE_PROJECT_DIR`). I relied on the research's line citations. A person should check them against the current `code.claude.com` hooks and sub-agents pages.
- **macOS.** Neither the review nor the record ran macOS (bash 3.2, BSD tools, Apple git and its `--path-format=absolute` support). A person on a Mac should run `bash tests/run.sh bounds.test.sh`.
- **The upgrade path.** I did not exercise it end to end: a global update with the hook while a project's `.polype/hooks/` still lacks `po-bounds.sh`. This should be checked once on a real project after ship.

Max severity: major
Ship allowed: yes
