---
validated: yes
---
# Plan — s115-no-claude-md

[Story](../stories.md) · [Research](../research/s115-no-claude-md.md)

Branch `story/s115-no-claude-md`. Read `docs/research/s115-no-claude-md.md` first; this plan builds on it without repeating it. Decision record: `docs/decisions/ADR-0086-l-installeur-absorbe-le-claude-md-dans-agents-local-md.md` (`accepted`, the person's choice of 2026-10-13, written with this plan); it supersedes ADR-0073.

## Story
No `CLAUDE.md` in a Polype project: the installer absorbs the one it finds into `AGENTS.local.md`, the pre-commit refuses one, the rules say so, `po-session` flags one.
- `installer_absorbs_claude_md` — `init`, `install`, `update` move a root `CLAUDE.md` / `CLAUDE.local.md`, minus `@AGENTS.md`, to the end of `AGENTS.local.md` under `## Notes moved from CLAUDE.md`, delete it and report it; import-only → deleted, nothing added; nothing lost.
- `precommit_refuses_claude_md` — refused on every branch when added or modified at any depth; a deletion passes.
- `rules_say_no_claude_md` — `AGENTS.md`, `/po-setup`, `/po-architect` say it in the same words.
- `session_flags_a_claude_md` — listed under "Waiting for a human" with `polype update .`.

**Decided here, from `bin/polype`** (story notes ask the plan to say it): the installer never creates `AGENTS.local.md` (`bin/polype:12`; `/po-setup` refuses to run when it exists, `po-setup.md:17`). With no `AGENTS.local.md`, a `CLAUDE.md` holding more than the import is **left byte-identical**, the installer says so on stderr, and the rest of the command runs and exits 0. Only the absorption stops: aborting the command would leave a fresh project without `.polype/templates/agents-local.md`, which `/po-setup` copies.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Absorbing function in `bin/polype` | Already in this repository: it replaces `drop_legacy_claude_md_import` (`bin/polype:224-232`) for the three install commands, reusing its `grep -vx '@AGENTS.md'` and blank test, and the write-aside-then-`mv` of `assemble_agents_md` (`bin/polype:168-176`) | — (first rung holds; the function grows, no new helper) |
| Pre-commit path check | Already in this repository: the basename `case` over `git diff --cached --name-only --no-renames --diff-filter=d -z` of `secret_scan` (`po-gate.sh:181-189`) | — |
| `po-session` lines | Already in this repository: `lines+=` in `waiting_for_a_human` (`po-session.sh:189-225`) | — |
| Test file `tests/no-claude-md.test.sh` | Already in this repository: `scratch_repo` (`tests/lib.sh:46`), the patterns of `tests/gate.test.sh:6-15,171`, `tests/project-lead.test.sh:15-29`, `tests/global-install.test.sh:9-16`, copied as small local helpers since test files do not source each other | `tests/lib.sh` is not in `Owns`, so no shared helper is added there |

## Tasks
1. [x] **Installer absorbs.** In `bin/polype`, write `absorb_claude_md` and call it **first** in `wire_the_project` (`:287`), before `assemble_agents_md`, so the notes reach `AGENTS.md` in the same run; drop the `drop_legacy_claude_md_import` call at `:290`. Global mode already returns at `:288`: `~/.claude/CLAUDE.md` is never reached. For `CLAUDE.md` then `CLAUDE.local.md` at `$project/` (regular files only): the content without the exact line `@AGENTS.md`;
   - nothing non-blank left → delete the file, stderr `polype: <name> held only the @AGENTS.md import; deleted`;
   - otherwise, no `$project/AGENTS.local.md` → leave the file untouched, stderr `polype: <name> left in place: no AGENTS.local.md to move it into; run /po-setup, then polype update .`;
   - otherwise collect it. When something was collected: write `AGENTS.local.md.polype-next` = `AGENTS.local.md` as is (plus a newline if its last byte is not one), a blank line, `## Notes moved from CLAUDE.md`, a blank line, then the `CLAUDE.md` content, then for `CLAUDE.local.md` a line ``From `CLAUDE.local.md`:`` and its content; `mv -f` it over `AGENTS.local.md`; **only then** delete the absorbed sources, each with stderr `polype: <name> moved into AGENTS.local.md under ## Notes moved from CLAUDE.md, then deleted`.
   Keep `drop_legacy_claude_md_import` for `unwire_the_project` (`:448`) only, and rewrite the comment at `:221-223` to say why `remove` keeps it (ADR-0086). Update `test_install_drops_the_legacy_claude_md_import` (`tests/install.test.sh:56-65`): its second half now asserts that, without `AGENTS.local.md`, a `CLAUDE.md` with notes and the import is left byte-identical (cksum) — the clause it checked is the one this story changes. Test that fails: `test_installer_absorbs_claude_md` (task 2).
2. [x] **Test the absorption** in `tests/no-claude-md.test.sh` (header comment `# s115 — no CLAUDE.md in a project.`), `test_installer_absorbs_claude_md`, three phases in throwaway dirs:
   - `install <P>` with `AGENTS.local.md` = `Merge mode:        local`, `CLAUDE.md` = `# Project notes\n@AGENTS.md\n`, `CLAUDE.local.md` = `local note\n`: both files gone; `AGENTS.local.md` still starts with the settings line, holds the line `## Notes moved from CLAUDE.md`, `# Project notes`, `local note`, and no line `@AGENTS.md`; `AGENTS.md` holds `# Project notes` (ordering); the output (2>&1) names `CLAUDE.md` and `CLAUDE.local.md`.
   - `update <P>` on that project after writing `CLAUDE.md` = `@AGENTS.md\n`: file gone, `AGENTS.local.md` cksum unchanged.
   - throwaway `HOME`/`CLAUDE_CONFIG_DIR` under `$SCRATCH` (as `tests/global-install.test.sh:9-16`), `$CLAUDE_CONFIG_DIR/CLAUDE.md` written first: `install --global` then `init <P2>` with `AGENTS.local.md` and a `CLAUDE.md` holding `# Init notes` → absorbed; the global `CLAUDE.md` cksum unchanged.
   Run: `bash tests/run.sh no-claude-md.test.sh install.test.sh installer.test.sh global-install.test.sh`.
3. [x] **Pre-commit refuses.** In `method/hooks/po-gate.sh` `pre_commit`, after the secret refusal and before the branch test (`:252`), list staged paths with `--diff-filter=d --no-renames -z`; a basename `CLAUDE.md` or `CLAUDE.local.md` prints `po-gate: <path>: CLAUDE.md staged — Claude Code reads AGENTS.md only while none exists; put its notes in AGENTS.local.md` and the commit is refused (`refuse … || return 1`). It is **not** part of `secret_scan` nor of its count. Add the clause to the header comment (`:11-13`). Test `test_precommit_refuses_claude_md`: a gate sandbox; `git add -f` (the author's global gitignore excludes both names, research Traps) of `CLAUDE.md` → refused naming it; `docs/sub/CLAUDE.local.md` → refused; on `feature/x` → refused; then commit one with `--no-verify`, modify it and stage → refused; `git rm -q` it → `passes pre-commit`. Run: `bash tests/run.sh no-claude-md.test.sh gate.test.sh`.
4. [x] **po-session flags.** In `method/hooks/po-session.sh` `waiting_for_a_human`, after the `ORPHANS` append, for each of `CLAUDE.md`, `CLAUDE.local.md` present at `$top/`: `lines+=("<name>: Claude Code reads it instead of AGENTS.md → polype update . moves it into AGENTS.local.md")`. No other change: the hook stays read-only and the no-`AGENTS.local.md` case (`:20-23`) still prints only "setup missing". Test `test_session_flags_a_claude_md`: a project built as `polype_repo` (`tests/project-lead.test.sh:18-26`, with `Max attempts: 2`, `Merge mode: pr`, `Ship confirmation: automatic`), committed, `CLAUDE.local.md` written at the root → the output holds the line `- CLAUDE.local.md: …` with `polype update .` (exact full line); after removing it, `Waiting for a human: nothing`. Run: `bash tests/run.sh no-claude-md.test.sh project-lead.test.sh`.
5. [x] **Rules and commands, same words.** The sentence, verbatim in all three files:
   ```
   The only `CLAUDE.md` is the user's global one: no agent creates a `CLAUDE.md` or a `CLAUDE.local.md` in a project, and the project's notes go in `AGENTS.local.md`.
   ```
   - `method/AGENTS.md`: line 4, `which the installer leaves alone and appends at the end of this file` → the same clause saying the installer only reads it, except to append the notes it moves out of a `CLAUDE.md`, and appends it at the end of this file. In `## Installed files`, before "Never edit an installed file", a paragraph: the sentence, then that the installer absorbs a root `CLAUDE.md` or `CLAUDE.local.md` into `AGENTS.local.md` and the pre-commit refuses one at any depth (ADR-0086).
   - `method/commands/po-setup.md`: `:17` end → the installer never creates it and writes in it only to append the notes it moves out of a `CLAUDE.md`; `:56` replace "Never commit a `CLAUDE.md`: … (ADR-0073)." with "Never commit a `CLAUDE.md`. " + the sentence + " (ADR-0086)".
   - `method/commands/po-architect.md` step 4 (`:72`): add "Never commit a `CLAUDE.md`. " + the sentence + " (ADR-0086)".
   Test `test_rules_say_no_claude_md`: `contains` the sentence in the three files, and `contains "$METHOD/AGENTS.md" 'the pre-commit refuses one at any depth'`. Run: `bash tests/run.sh no-claude-md.test.sh structure.test.sh gate.test.sh overlap.test.sh`.
6. [x] **Docs and ADR link.** `docs/installation.md` (French): replace `:185-187` with the absorption (heading, deletion, import-only case, the no-`AGENTS.local.md` case left in place, the global `CLAUDE.md` never touched), say at `:273` that `remove` still only drops the old import, and add one line on the pre-commit refusal. `docs/decisions/ADR-0073-plus-de-claude-md-claude-code-lit-agents-md.md`: frontmatter only, `status: superseded` and `superseded-by: [ADR-0086]`. Check: `git diff` of ADR-0073 touches those two lines only.
7. [x] **Full suite**, once, after the last edit: `po-run --story s115-no-claude-md --label test -- 'bash tests/run.sh'`. No type check exists (`Typecheck: —`).

## Scene viewpoints
—

## Run interdicts
- `.claude/` and `.polype/` of this repository end with an empty diff (installed copies, `AGENTS.local.md` Conventions).
- `bin/polype` global mode (`wire_the_project` early return, `:288`) and `cmd_remove`/`unwire_the_project` behaviour unchanged: `git diff` shows no edit to `cmd_remove` and only the comment in front of `drop_legacy_claude_md_import`.
- The installer never creates `AGENTS.local.md`: no `cp`/`>` to it outside the `.polype-next` + `mv` of task 1, and only when the file exists.
- `secret_scan` and `SECRET_PATTERNS` unchanged; the secret count message unchanged.
- `po-session.sh` stays read-only: no write, no git lock, no new git call.
- Accepted ADRs other than ADR-0073's two frontmatter lines untouched; past stories, plans and reviews mentioning `CLAUDE.md` untouched.
- No run of `polype` against the real `~/.claude` or this repository; every installer test uses a scratch dir.

## The pivot
Placing the absorption **before** `assemble_agents_md` and **deleting the sources only after `AGENTS.local.md` has been replaced**. It could be wrong in three ways:
- Order: run after assembly, `AGENTS.md` lacks the notes until the next install — the `AGENTS.md` holds `# Project notes` assertion of task 2 catches it.
- Loss: a `rm` before the `mv` (or a missed final newline gluing the heading to the last setting) loses or corrupts content — compare the head of `AGENTS.local.md` to the original settings line, and the heading as an exact line.
- The skip branch: if "stop" in the story notes meant aborting the whole command, a person may disagree; ADR-0086 records why the command goes on (fresh project deadlock), and the research marks it as the plan's decision.

## Files touched
`bin/polype`, `method/hooks/po-gate.sh`, `method/hooks/po-session.sh`, `method/AGENTS.md`, `method/commands/po-setup.md`, `method/commands/po-architect.md`, `docs/installation.md`, `docs/decisions/ADR-0073-…md` (frontmatter), `tests/install.test.sh`, `tests/no-claude-md.test.sh` (new); plus `docs/research/`, `docs/plans/`, `docs/decisions/ADR-0086-…md` from this stage.

## Test strategy
Four new tests, one per acceptance criterion, named after it, in `tests/no-claude-md.test.sh`; one existing test changed (`tests/install.test.sh` legacy import, second half). Five, within `Test budget` 25.
- Installer behaviour runs the real `bin/polype` in scratch dirs (no mock); it fails if the absorption, its order, the import filter, the deletion or the global guard is removed.
- Pre-commit runs the real `po-gate.sh pre-commit` on a staged index with `git add -f`, so the global gitignore cannot make it pass empty; deleting the new `case` turns it red, deleting `--diff-filter=d` turns the deletion phase red.
- `po-session` runs the real hook; the exact full line is checked.
- Rule texts: fixed-string `contains` of the shared sentence in three files.
No visual checks (`Surface: —`). The full suite runs once at task 7.

## Done when
All seven tasks ticked; the four acceptance tests and the full suite green through `po-run`; ADR-0086 accepted and ADR-0073 marked superseded by it; one commit on `story/s115-no-claude-md` carrying the code, the tests, this plan, the research and the ADRs; review with no open critical finding.
