# Research — s103-project-lead

## Structuring facts
- **Tension, not a false assumption:** `/po-drive status` knows a PR "waiting for a human merge" only through `gh pr view story/<id> --json state` (`method/commands/po-drive.md:64-65`, `method/commands/po-status.md:31`), while the story's note limits `po-session.sh` to bash and git. The hook can therefore only *presume* such a PR from local state (favourable review + `Merge mode: pr` + `Ship confirmation` reading `human` + `refs/remotes/origin/story/<id>` + not shipped), and must say it did not ask the forge. The plan settles it that way; it does not contradict the story.
- Every project pose goes through `wire_the_project` (`bin/polype:235-242`), called by `cmd_install` (`:308`, hence `init` `:312-315` and `update` without manifest `:318`) and `cmd_update` (`:351`); it returns at once in global mode (`:236`). That is the one place to wire the `SessionStart` hook.
- `cmd_remove` prunes empty dirs (`bin/polype:418`) **before** `unwire_the_project` (`:419`): a `.claude/settings.json` deleted inside `unwire_the_project` would leave an empty `.claude/` behind. The hook must be unwired before the prune.
- `tests/structure.test.sh:73-84` requires `## Installed files` of `method/AGENTS.md` to name every file of `method/hooks/`: adding `po-session.sh` without naming `po-session` there breaks an existing test.
- Nothing in the repository reads or writes `.claude/settings.json` today (`grep -rn settings.json` hits only `tests/global-install.test.sh:93-97`, which checks that `remove --global` leaves the user's own `~/.claude/settings.json` alone).

## Story
The main session of a Polype project is its project lead (ADR-0076): it leads framing in conversation when framing is missing, then runs `/po-drive` wave after wave until the milestone is done, never writing a story's code; it answers the question asked first and relaunches the fleet only when the project is waiting. A `SessionStart` hook, `po-session.sh`, feeds it the state read from disk and git; the installer wires that hook into the project's `.claude/settings.json` with `jq`.

Acceptance criteria (test names): `rules_name_the_project_lead`, `lead_answers_before_driving`, `session_hook_reports_state_read_only`, `session_hook_silent_outside_polype`, `installer_wires_the_session_hook`, `help_says_no_command_needed`.

## Current code
- `method/AGENTS.md` (138 lines): Law 2 (`:59-61`) already says "The main context of a session plans, delegates and reports; it has no business editing source files during a story" — the lead's "no story code" rule restates it, it does not replace it. No section names a project lead. `## Installed files` (`:125-131`) names `po-gate`, `po-bounds`, `po-run` and the pre-commit. `### The fleet` (`:51-57`) describes `/po-drive` and the human-merge wait.
- `method/hooks/`: `po-bounds.sh`, `po-gate.sh`, `po-run.sh`, `pre-commit`. No `po-session.sh`. Hooks are laid into `.polype/hooks/` in both project poses (`bin/polype:98`, `:101`) and made executable (`:142-143`, `:157`).
- `bin/polype` (440 lines): writes aside then renames (`lay_down` `:153-159`, `assemble_agents_md` `:169-176`) — the convention for any file it writes. `done_message` (`:269-278`) tells `init` to commit `.polype/, AGENTS.md and .gitignore`; `install <project>` already says `.claude/`. `unwire_the_project` (`:393-409`) undoes AGENTS.md and `core.hooksPath`. No use of `jq` anywhere.
- `method/commands/po-help.md` (46 lines, French): `## Installation` `:11-13`, `## Outils` `:35-41`; nothing about opening a session.
- `docs/installation.md` (270 lines, French): `## Activer un projet` `:63-80`, `## Ce qui est posé dans un projet` `:168-190` (bullet list of what `init`/`install` add besides copies `:177-188`), `## Ce que \`remove\` garde` `:256-270`.

## Attachment points
- `method/AGENTS.md`: a new `## The project lead` section after Law 2 (`:61`), plus one sentence for `po-session` in `## Installed files` (`:129`).
- `method/hooks/po-session.sh`: new file, installed as `.polype/hooks/po-session.sh` with no installer change for the copy itself.
- `bin/polype`: a `wire_session_hook` called from `wire_the_project` (`:235-242`); an `unwire_session_hook` called in `cmd_remove` before `prune_empty_dirs` (`:418`) for project mode; `done_message` init line (`:274`) gains `.claude/settings.json`.
- `method/commands/po-help.md`: one line near the top (`:9`) or in `## Outils`.
- `docs/installation.md`: the bullet list `:177-188`, the `remove` section `:258-270`, and the session sentence.

## Verified interfaces
- Settings read as `Name: value`, text after the first colon trimmed (`method/AGENTS.md:8`); `Ship confirmation` may end with `(forge)`/`(chosen)`, not part of the value (`:10`). `bin/polype:182` reads a setting with `sed -n 's/^Worktree root:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*$/\1/p' | head -n 1` — reusable shape.
- Story header in this repo: `### s103-project-lead — …` (`docs/stories.md:1582`); template: `## <id> — <title>` (`method/templates/stories.md:7`). Dependencies: `- **Depends on**: <ids, or none>` (`templates/stories.md:11`) or `- **Dépend de** : …` / `aucune` in French (`docs/stories.md:1604`). Complexity line `- **Complexity**` / `- **Complexité**`.
- Shipped: a commit whose subject starts with `<id>:` on `Target branch` or `origin/<Target branch>` (`method/commands/po-status.md:31`, `po-drive.md:31`).
- Framing states (`po-status.md:16-21`): scope file per `Entry mode` (`replace`/`adapt` → `docs/prd.md`, `new` → `docs/brief.md`, `—` → stories by hand), approved = `status: approved` in its frontmatter (draft states: `status: draft` `templates/prd.md:4`, `status: interviewing` `templates/brief.md:3`); `docs/stories.md`; last `Stories ready:` of `docs/reviews/stories.md`; `docs/architecture.md`; `docs/design-system.md`. Read "on `Target branch`".
- Lanes in flight: worktree `<Worktree root><id>` whose branch is `story/<id>` (`po-status.md:34`). Orphan: other branch, detached HEAD, or `story/<id>` checked out elsewhere (`po-drive.md:88`, `po-status.md:36`).
- Escalations `/po-drive status` lists for a human (`po-drive.md:154`, resume table `:52`, `:56`, `:64-65`, `:134`): `Root cause: not found` in the research with no validated plan; last `QA status:` of `docs/qa/<id>/report.md` = `blocked` (`templates/qa.md:31`); `Max attempts` reached — last `Ship allowed: no` and `Fix loop: <n>` (`templates/review.md:6`, `:59`) with `n >= Max attempts`, since a review at loop n was preceded by n fix runs (`po-review.md:26`, `po-drive.md:134`); orphan worktree; PR waiting for a human merge. Dependencies and `Owns` collisions are waits, not escalations, and stay out per the AC.
- Claude Code `SessionStart` hook in `.claude/settings.json`: `{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"…"}]}]}}`; the command's stdout reaches the session as context; `$CLAUDE_PROJECT_DIR` is set to the project root.
- `jq` is at `/usr/bin/jq` on this machine; no test uses it yet.

## Traps
- `tests/structure.test.sh:73-84` (above): name `po-session` in `## Installed files`.
- `tests/global-install.test.sh:57-60`: after `init`, no `.claude/commands|agents|skills` and no `.claude/` line in `.polype/manifest` — `settings.json` must be merged, never `lay_down`-ed nor listed in the manifest. `:89-97`: `remove --global` must not touch `~/.claude/settings.json`; wiring/unwiring stays out of global mode.
- `tests/installer.test.sh:131-140`: no empty file and no `*.polype-next` after `remove`; the temp file of a jq merge must be cleaned on failure too, and an emptied `settings.json` deleted, not left as `{}`.
- `tests/fleet-wiring.test.sh` extracts `## ` sections of `method/AGENTS.md` (`section_of`, `:10`): a new `## The project lead` section must not split `## Law 1` (place it after Law 2).
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS; write new text from scratch.
- `.claude/settings.json` is committed in a project, so story worktrees carry it: a session opened in a worktree runs the hook too. ADR-0076 says worktrees are not concerned → the script stays silent on a `story/*` branch.
- Read-only: `git status` may rewrite the index; the script must not call it. `git fetch` changes refs → forbidden. Use `GIT_OPTIONAL_LOCKS=0` and only `rev-parse`, `log`, `show`, `worktree list --porcelain`, `for-each-ref`.
- s104 (depends on s103) also owns `method/AGENTS.md`; it will add escalation motives to the same area. Keep the lead section self-contained.
- `remove` cannot tell a `settings.json` that held `{}` before the install from one emptied by unwiring; both end deleted. Accepted, said in `docs/installation.md`.
- Performance: one `git log --format=%s` over `Target branch` and `origin/<Target branch>` for all shipped ids, not one per story.

## Open questions
- Should `po-session.sh` print a coarse stage per lane? Not required by the AC; the plan prints id and path only, leaving the stage to `/po-status`.
- Ready stories ignore `Owns` collisions (the overlap rule lives in a skill, not in bash); the plan names them "ready by dependencies", `/po-drive` keeps the final say.
- Framing read on `Target branch` via `git show` (as `/po-status`), so a framing file still on a framing branch (s106) reads as missing. Kept: it is not on the target yet.

## Complexity
Story: 3 → after reading: 3. One new read-only script with several derivations, an installer merge/unmerge, and rules text; no migration, no new structural choice beyond what the story and ADR-0076 settle (jq and project settings decided with the owner, 2026-10-13).

## Split
— (not at 5)
