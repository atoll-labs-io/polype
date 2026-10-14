# Review — s103-project-lead

[Story](../stories.md) · [Plan](../plans/s103-project-lead.md) · [Verification](../verif/s103-project-lead.md)

Diff reviewed: `git diff main...story/s103-project-lead`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: a4cb4ea51d00d4ee769d3b1e01d134425b8d6dcf

## Ownership
The diff was listed with `git diff --name-only main...story/s103-project-lead` and each path checked against `Owns`.
- [x] Every path is inside `Owns`. `bin/polype`, `docs/installation.md`, `method/AGENTS.md`, `method/commands/po-help.md`, `method/hooks/po-session.sh` and `tests/project-lead.test.sh` are owned. The research, plan and verification record for this id are in scope by construction. No ADR was added.
- [x] Other running stories (`git worktree list`):
  - `story/s106-framing-through-pr` owns `po-setup/po-brief/po-prd/po-stories/po-stories-review/po-architect/po-design-system/po-research` and `tests/framing-through-pr.test.sh`. No overlap.
  - `story/reuse-ladder` is not merged into main and touches only `docs/stories.md`, which this story does not touch.
  - s104 and s105 share `method/AGENTS.md` and `po-help.md`. s105 is shipped (d50dd0b on main). s104 has no worktree. Neither is a running collision.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s103-project-lead` exits 0, so the record is reused.
  - `Tree: a564fb17…`, status complete.
  - One `Unit suite` row (`bash tests/run.sh`), exit 0. `Typecheck: —` (this project has none).
  - "Not proven here" says the hook was never run inside a real Claude Code session and that the PR line comes from local refs only.
  - I did not rerun the full suite. I ran only `bash tests/run.sh project-lead.test.sh` as a baseline for the bite step: 11 passed.
- [x] `po-gate qa-current`: not required. With `QA stage: —` the story does not go to QA.

## Plan
- [x] Tasks 1–8 are all there, as specified. Nothing outside the plan.
- [x] Run interdicts, one by one:
  - **Only `Owns` plus own evidence changed:** holds.
  - **`po-drive.md`, `po-status.md`, `po-ship.md` unchanged:** empty diff.
  - **`.claude/` and `.polype/` unchanged:** empty diff.
  - **No forbidden commands or writes in `po-session.sh`:** a grep finds no `git status`, `fetch`, `gh`, `curl`, `jq`, `mkdir`, `rm`, `mv`, `touch` or `tee`, and the only redirections go to `/dev/null`.
  - **No `settings.json` in global mode:** `wire_the_project` returns early for global.
  - **`## Law 2` unchanged and `method/AGENTS.md` additive only:** Law 2 is byte-identical, and both AGENTS.md hunks only insert text.
  - **No ADR written:** none.

## References
- [x] Every reference opened and confirmed:
  - In `bin/polype`: the call sites `wire_the_project` (used by install and update), `cmd_remove` (unwiring now runs before `prune_empty_dirs`), the `done_message` case, and `bin/polype-dev-install` (an alias of `install`).
  - The `Next action:` bullet and the top-level `Review status:` / `Fix loop:` in `method/templates/review.md`.
  - The line `Root cause: not found` (`method/agents/planner.md:39`, `po-research.md:54`).
  - `QA status:` in the QA template.
  - The `**Depends on**` label in `method/templates/stories.md`.
  - The resume table and the orphan definition in `po-drive.md`, and the shipped rule in `po-status.md`.
  - ADR-0076, which the change matches.
- [x] Values checked:
  - **Max attempts** fires when `Fix loop >= Max attempts`, matching "at most `Max attempts` fix runs" in `po-drive.md`.
  - **`Ship confirmation`** has its `(forge)`/`(chosen)` suffix stripped, as Law 1 / AGENTS.md:10 says.
  - **Symlinked project path:** probed in `/tmp/tmp.Fhd7Vj2wi4` with the repo reached through a symlink. The lane was matched, not reported as an orphan.

## Rules
- [x] `AGENTS.md` conventions respected: method text in English, `po-help.md` in French, and tests in `tests/<slug>.test.sh` using the `lib.sh` helpers.
- [x] No accepted ADR contradicted (ADR-0076, ADR-0052).

## Tests
- [x] Floor: `po-gate floor-guard s103-project-lead main` exits 0, so nothing was lowered.
- [x] None of the six empty test shapes:
  - Every fixture lane has its own id.
  - The read-only test compares checksums and mtimes of every file, `.git` included.
  - The no-`jq` test builds a `PATH` without `jq` instead of uninstalling it.
- [x] 11 tests, within `Test budget: 25`.
- [x] Bite. Each mutation was run only against `tests/project-lead.test.sh`, then undone and proved undone with `git diff --exit-code`:
  1. **Dependency check removed** in `ready_stories` (the `for dep … ok=no` loop replaced by `:`): 1 test failed (`session_hook_reports_state_read_only`).
  2. **`-ge` changed to `-gt`** in the Max attempts condition: 1 failed (`session_hook_lists_human_escalations`).
  3. **In-flight lanes no longer excluded from ready** (`[ -n "${LANES[$id]-}" ] && continue` deleted): 1 failed (`session_hook_reports_state_read_only`).
  4. **Hook duplicates not dropped** in `bin/polype` (`… | not or true`): 2 failed (`installer_wires_the_session_hook`, `installer_unwires_the_session_hook`).

Lenses run: none. No path or content in the diff triggers one: no auth, routes or HTTP; no migration; no lockfile or manifest; no server-side code.

## Findings
1. **minor** — `docs/installation.md`, `## Activer un projet`. The sentence "dépose dans le dépôt ce qui doit y vivre, et rien de plus" and the "plus `AGENTS.md` et les deux lignes de `.gitignore`" list after the table still leave out `.claude/settings.json`, which `init` now creates. The new paragraph a few lines below mentions it, so the section partly contradicts itself.
2. **minor** — What the hook prints on Polype's own repository (I ran it with `CLAUDE_PROJECT_DIR=/home/lecrabe/dev/atoll/polype`):
   - It lists `s01-regles-et-reglages … s10-validation-m1` as ready, because those stories were shipped under subjects like `s10: …`, not `<id>:`.
   - It reports `.claude/worktrees/story-reuse-ladder` (`story/reuse-ladder`) as an orphan worktree.
   - Both follow the written rules: the shipped rule of `po-status.md` and the orphan definition of `po-drive.md`. So this is not an implementation defect. It is a misleading first picture for this repository's lead, worth a person's look.
3. **minor** — `remove` without `jq` deletes `.polype/hooks/po-session.sh` (it is in the manifest) but leaves the `SessionStart` entry in `.claude/settings.json`. Every later session then tries to run a missing script. This is documented ("sans lui, il le dit et laisse le fichier") and stderr says so, but the leftover state is a broken hook, not an inert one.

## Not verified
- **The hook inside a real Claude Code session**, with its stdout injected as SessionStart context. Only the script's output and the merged JSON are tested. A person should open a session on a project initialised with this build and check that the state block reaches the conversation.
- **The presumed-PR line.** It comes from local refs only. Whether the forge still shows the PR open, merged or closed was never asked. `po-drive`'s "closed without a merge → a human" case is not covered by design, because it needs `gh`. Confirm with `/po-drive status`.
- **macOS default bash 3.2.** The hook uses `declare -A`, which bash 3.2 lacks. `bin/polype` already relies on `declare -A` and `mapfile`, so the installer already needs bash 4. But this hook runs at every session start on every collaborator's machine. Nobody ran it under bash 3.2; someone on stock macOS should open a session once.
- **A review blocked for a non-QA cause (for example a reviewer crash) at `Fix loop == Max attempts`.** The hook would list it as "Max attempts reached". Before that row, `po-drive`'s table has "review blocked, Fix loop shows it judged an earlier commit → review stage". I did not build a fixture for this ordering; a person could compare against `/po-drive status` on such a lane.
- **`jq` versions other than the one on this machine** were not exercised.
- **The full suite** was not rerun here; I relied on the record's run (exit 0, tree matching).

Max severity: minor
Ship allowed: yes
