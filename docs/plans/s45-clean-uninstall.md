---
track: flow
validated: yes
---
# Plan (short track) — s45-clean-uninstall

[Story](../stories.md)

Written by `/po-flow`. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s45-clean-uninstall.md`.

## Verified facts
- The story's assumption holds: `unwire_the_project` (`bin/polype:361`) filters `@AGENTS.md` out of `CLAUDE.md` with `grep -vx` (`bin/polype:364`) and renames the result over it (`bin/polype:365`) — whatever is left, even nothing, stays as a file.
- `assemble_agents_md` creates `CLAUDE.md` with `touch` when it is absent (`bin/polype:178`), then appends `@AGENTS.md` once (`bin/polype:179`). A project that had no `CLAUDE.md` therefore ends with one holding only the import.
- The only other file the installer may create in a project is `.gitignore` (`touch`, `bin/polype:188`); it always receives two lines (`bin/polype:189-191`), so it is never empty, and remove must keep it (`tests/installer.test.sh`, `test_installer_remove_leaves_the_project_intact`). Temporary `*.polype-next` files are always renamed away (`bin/polype:175-176`, `:365`, lay_down `:158`).
- Global mode never touches `CLAUDE.md`: `unwire_the_project` returns first when `mode` is `global` (`bin/polype:362`).
- `cmd_remove` (`bin/polype:382-396`) calls `prune_empty_dirs` (`:389`) before `unwire_the_project` (`:390`); the change stays inside `unwire_the_project`.
- An existing test already covers the "other content survives" half: `test_installer_remove_restores_a_hand_written_agents_md` (`tests/installer.test.sh`) checks `# Project notes` stays and the import leaves.
- `docs/defauts.md:61` lists defect 31 as `ouvert (mineur)`.
- `docs/installation.md:173` says remove "retire la ligne `@AGENTS.md` de `CLAUDE.md`"; that file is not in the story's `Owns`, so it is left unchanged (see Run interdicts). No line of `docs/parite-killer-saas.md` concerns this story.
- Test helpers: `scratch_repo` (`tests/lib.sh:46`) gives an empty git repo; the test file's `project` and `polype` wrappers run the installer in it.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text, `docs/stories.md:669-679` | absent — `unwire_the_project`, no data format change |
| New screen | absent — story text | absent — CLI shell script only |
| Authorization or tenant scope | absent — story text | absent — `bin/polype` touches local files only |
| API contract | absent — story text | absent — subcommands, arguments and exit codes unchanged (`bin/polype:399-411`) |
| New dependency | absent — story text | absent — uses `grep`, `rm` already in use |

## Story
`polype remove <project>` must not leave an empty file behind.
- `remove_deletes_a_claude_md_it_created` — if `CLAUDE.md` held only Polype's import, it is deleted; if it held anything else, only the import line goes.
- `remove_leaves_no_empty_file_behind` — after uninstall, no empty file created by the installer remains.

## Tasks
1. [x] In `unwire_the_project`, after filtering the import out of `CLAUDE.md`, delete the file when nothing but blank lines remains; otherwise rename the filtered copy over it as today. No temp file may be left in either branch. Test able to fail: `test_remove_deletes_a_claude_md_it_created` (fails today: an empty `CLAUDE.md` stays).
2. [x] Add `test_remove_deletes_a_claude_md_it_created` to `tests/installer.test.sh`: a project with no `CLAUDE.md` → install → remove → `CLAUDE.md` absent; a project whose `CLAUDE.md` holds `# Project notes` → install → remove → file present, `# Project notes` kept, no `@AGENTS.md` line.
3. [x] Add `test_remove_leaves_no_empty_file_behind`: fresh scratch project, install, remove, then `find "$P" -path "$P/.git" -prune -o -type f -empty -print` lists nothing, and no `*.polype-next` file exists. Fails today on `CLAUDE.md`.
4. [x] `docs/defauts.md:61`: status of defect 31 becomes `corrigé par s45`.

## Run interdicts
- `docs/installation.md`, `method/`, `.claude/`, `.polype/` end with an empty diff (not owned; the doc gap is reported for a later story).
- Only `bin/polype`, `tests/installer.test.sh`, `docs/defauts.md` and this story's `docs/` evidence change.
- `cmd_remove`'s order, global mode and `.gitignore` handling stay as they are; existing installer tests are not modified.

## Files touched
`bin/polype`, `tests/installer.test.sh`, `docs/defauts.md`, `docs/plans/s45-clean-uninstall.md`, `docs/verif/s45-clean-uninstall.md`.

## Test strategy
Two integration tests in `tests/installer.test.sh`, driving the real installer in a scratch repo (the only layer where "file exists after remove" is observable). Both fail on the current code. Removing the new deletion branch makes both fail again — that is the proof they bite. Total: 2 tests, within `Test budget` (25). Focused run: `bash tests/run.sh installer.test.sh`; then `Full suite` at execute end: `bash tests/run.sh`.

## Done when
One commit on `story/s45-clean-uninstall`; the two tests and the full suite green; review with no open critical finding; squash-merged on `m4-catalogue`.
