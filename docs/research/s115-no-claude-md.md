# Research — s115-no-claude-md

## Structuring facts
- **The installer never creates `AGENTS.local.md`, and must not start now.** `bin/polype` only reads it (`bin/polype:12`, `:171-174`, `:181-183`, `:194`); `/po-setup` creates it and refuses to run when it already exists (`method/commands/po-setup.md:15-17`). So the story's alternative "create it from `templates/agents-local.md`" would break `/po-setup`; the installer takes the other branch: no `AGENTS.local.md` → the absorption is skipped and said, the install goes on. Aborting the whole command instead would deadlock a fresh project, since `/po-setup` copies `templates/agents-local.md`, which is `.polype/templates/agents-local.md` laid down by `init` (`method/AGENTS.md:145`).
- **Two texts the story makes false**: `method/AGENTS.md:4` says the installer "leaves alone" `AGENTS.local.md`, and `method/commands/po-setup.md:17` says "the installer never writes it". Both must change in this story, or the rules contradict the installer.
- **The absorption must run before `assemble_agents_md`** (`bin/polype:162-177`), the only place `AGENTS.local.md` is copied into `AGENTS.md`; run after, the moved notes reach `AGENTS.md` only at the next install. Today `wire_the_project` calls `assemble_agents_md` first, then `drop_legacy_claude_md_import` (`bin/polype:287-295`).
- **The author's global gitignore excludes `CLAUDE.md` and `CLAUDE.local.md`** (`~/.config/git/ignore:5-6`): a test that stages one needs `git add -f`, or it tests nothing (the pre-commit sees an empty index and passes).
- ADR-0073 (`docs/decisions/ADR-0073-plus-de-claude-md-claude-code-lit-agents-md.md`) is superseded by ADR-0086, written with this plan as `accepted` (the person chose on 2026-10-13, story notes). Only ADR-0073's `status` and `superseded-by` change.

## Story
Polype forbids any `CLAUDE.md` in a project and absorbs the one it finds, so Claude Code always reads `AGENTS.md`.
- `installer_absorbs_claude_md` — `init`, `install`, `update` move a root `CLAUDE.md` / `CLAUDE.local.md`, minus the `@AGENTS.md` line, to the end of `AGENTS.local.md` under `## Notes moved from CLAUDE.md`, delete the file and report it; a file holding only the import is deleted with nothing added; nothing is lost.
- `precommit_refuses_claude_md` — the pre-commit refuses, on every branch, a `CLAUDE.md` / `CLAUDE.local.md` added or modified at any depth; a deletion passes.
- `rules_say_no_claude_md` — `AGENTS.md`, `/po-setup` and `/po-architect` say, in the same words, that the only `CLAUDE.md` is the user's global one, no agent creates one in a project, project notes go in `AGENTS.local.md`.
- `session_flags_a_claude_md` — `po-session` lists a root `CLAUDE.md` / `CLAUDE.local.md` under "Waiting for a human", with `polype update .`.

## Current code
- `bin/polype:221-232` `drop_legacy_claude_md_import`: when `CLAUDE.md` holds the exact line `@AGENTS.md`, rewrites it without that line through `CLAUDE.md.polype-next`, or deletes it when nothing non-blank is left; a `CLAUDE.md` without the line is untouched. It ignores `CLAUDE.local.md` and prints nothing.
- `bin/polype:287-295` `wire_the_project`: returns at once in global mode (so `~/.claude/CLAUDE.md` is never reached), then assemble → drop import → gitignore → hooks path → session hook → missing settings on stderr.
- `bin/polype:333-363` `cmd_install` and `:370-411` `cmd_update` both end with `wire_the_project`; `cmd_init` (`:365-368`) calls `cmd_install`; `cmd_update` without a manifest calls `cmd_install` (`:371`). One call site therefore covers the three commands.
- `bin/polype:446-462` `unwire_the_project` (remove) also calls `drop_legacy_claude_md_import`. The story does not name `remove`.
- Reports: informational lines go to stderr prefixed `polype: ` (`:165`, `:215`, `:408`); the closing summary goes to stdout (`done_message`, `:322-331`).
- `method/hooks/po-gate.sh:244-262` `pre_commit`: runs `secret_scan` on every branch (`:178-242`), whose path loop (`:181-189`) lists staged paths with `--diff-filter=d` (deletions pass) and matches on the basename; every hit is counted as a "secret" in the refusal (`:250`). Then the story-branch plan check.
- `method/hooks/pre-commit:4` execs `po-gate.sh pre-commit`.
- `method/hooks/po-session.sh:9-23` exits silently outside a Polype project or on `story/*`, and prints only "setup missing" when `AGENTS.local.md` is absent; `waiting_for_a_human` (`:189-225`) collects `lines+=(…)` per lane, appends `ORPHANS`, prints `Waiting for a human: nothing` or the list; it is called only when `Worktree root` is readable (`:241`).
- `method/commands/po-setup.md:56` "Never commit a `CLAUDE.md`: … (ADR-0073)"; `method/commands/po-architect.md:72` commit step, no word on `CLAUDE.md`; both list `CLAUDE.md` among Polype's own files for base detection (`po-setup.md:26`, `po-architect.md:24`).
- `docs/installation.md:185-187` and `:273` describe the ADR-0073 behaviour (import removed, other content kept).

## Attachment points
- `bin/polype`: replace the call at `:290` with an absorbing function called **first** in `wire_the_project`, before `assemble_agents_md`.
- `method/hooks/po-gate.sh` `pre_commit`: a path check beside the secret scan, before the branch test at `:252`, so it holds on every branch.
- `method/hooks/po-session.sh` `waiting_for_a_human`: two more candidate `lines+=` before the print.
- `method/AGENTS.md` `## Installed files` (`:143-149`) and line 4; `po-setup.md:17` and `:56`; `po-architect.md:72`.

## Verified interfaces
- Test helpers: `scratch_repo` (`tests/lib.sh:46-52`, sets `SCRATCH`, trap cleanup, `-b main`), `contains <file> <phrase>` (`tests/lib.sh:43`, fixed-string), `require_file`, `fail`.
- Gate sandbox pattern: `tests/gate.test.sh:6-15` (`sandbox`, `passes`), `refused_naming` (`:171`), `on_branch` (`:179`).
- Session pattern: `tests/project-lead.test.sh:15-29` (`session_in`, `polype_repo`, `has_line`).
- Installer pattern: `tests/installer.test.sh:4-7` (`POLYPE="$ROOT/bin/polype"`, `polype()` wrapper hiding output).
- ADR frontmatter links are bracket lists `superseded-by: [ADR-0086]` (`docs/decisions/ADR-0034-*.md:9`); `tests/final-leftovers.test.sh:13-18` pins the template, not ADR-0073.

## Traps
- **Existing tests that change**: `tests/install.test.sh:56-65` (`test_install_drops_the_legacy_claude_md_import`) expects, without any `AGENTS.local.md`, a `CLAUDE.md` with notes to lose its import and keep its notes. Under the skip branch it is left byte-identical, import included (the import is what still lets Claude Code read `AGENTS.md` while the file exists). Its second half changes. `tests/install.test.sh:47-54` (`test_install_writes_no_claude_md`) has no `AGENTS.local.md`, so it still passes unchanged.
- Tests still passing unchanged: `tests/installer.test.sh:103-130` (remove keeps the legacy import drop), `tests/global-install.test.sh:58`, `tests/install.test.sh:66-72` and `tests/installer.test.sh:85-100` (no `CLAUDE.md` there, so `AGENTS.local.md` untouched).
- `tests/project-lead.test.sh` prints `Waiting for a human: nothing` in several cases (`:88`, `:155-165`); none creates a `CLAUDE.md`, so a new line never appears there.
- Calling the pre-commit refusal a "secret" would mislead: it needs its own message and must not enter the secret count.
- `--no-renames` already turns a rename into D + A, so renaming a file **to** `CLAUDE.md` shows as an add and is refused, renaming one away passes.
- This repository runs the pipeline from `.polype/` and `.claude/`, installed copies: they stay untouched (`AGENTS.local.md`, Conventions). The installed pre-commit here keeps the old behaviour until a refresh.
- No migration, no dependency, no new screen, no API contract.

## Open questions
- Should `remove` absorb too, or keep dropping only the legacy import? The story names `init`, `install`, `update`; the plan keeps `remove` as it is.
- Should `po-session` flag a `CLAUDE.md` when `AGENTS.local.md` is missing? It prints only "setup missing" there today, and `polype update .` would not absorb it then; the plan leaves that case alone.
- Two files present: one heading or two? The plan puts both under a single `## Notes moved from CLAUDE.md`, `CLAUDE.local.md` introduced by a line naming it.

## Complexity
Story 3 → 3. Four small changes in three shell files plus texts, but the absorption carries the only data-loss risk and an ordering constraint, and one existing test changes.

## Split
—
