# Research — s127-hooks-installer-docs-cleanup

[Story](../stories.md)

## Structuring facts
- **Wrong assumption (AC 3):** "la borne de 30 s de `/po-qa`" lives in no `/po-qa` file: the phrase "wait at most 30 seconds of real time" is in the simulation driver, `method/skills/qa-drivers/simulation.md:30` (outside `Owns`, read only); the test to add pins it there, from `tests/qa-evidence-set-aside.test.sh` (owned).
- **Wrong assumption (Corrige vs AC):** triage row 96 (s99, `git_env_word` forks once per word, `method/hooks/po-bounds.sh:696`, `:711`) is a `HOLDS` row in an owned file that no criterion names and the M9 quinquies intro (`docs/stories.md:1914-1918`) does not exclude. The `Corrige` line takes it in; the plan closes it.
- **Root cause, framing secret scan (row 142):** `secret_scan` and `claude_md_check` diff the index against `HEAD` (`method/hooks/po-gate.sh:193`, `:202`, `:259`); `/po-setup` builds its temp index from `<base>` and calls `GIT_INDEX_FILE=<tmp> .polype/hooks/po-gate.sh pre-commit` with no base (`method/commands/po-setup.md:78-79`). Lines the commit adds over `<base>` but that `HEAD` already holds are never scanned (reproduced below: exit 0 on a commit adding a GitHub token).
- **Root cause, verdict block (row 80):** `paired_value` closes a block on any line matching `^([-*] )?Ship allowed:` (`po-gate.sh:68`, `:72`), so a findings bullet starting with those words cuts the last verdict from its `Review status:` and `Reviewed tree:` (reproduced: refusal). Fails safe, but refuses a sound review.
- Everything else is text, a message or a test that does not bite; each line `HOLDS` on the worktree at `553700b`, cited in `## Current code`.

## Diagnostic
Reproductions run in `mktemp -d` repositories, nothing written in the worktree.
- **Secret scan.** Repo: commit `f.md` = `a` (base), commit `f.md` += `token ghp_` + 36×`A` (HEAD). Temp index `read-tree <base>` + `add f.md`, then `GIT_INDEX_FILE=<tmp> po-gate.sh pre-commit` → exit 0, nothing printed; `git diff --cached <base> --stat` → `1 insertion`. Control, same token staged with HEAD = base → `po-gate: f.md:2: github-token (value not shown)`, exit 1.
  - H1 "the scan compares against HEAD, not `<base>`" — refuted if the control also passed. Kept: control refuses, only the reference differs.
  - H2 "`commit-tree` runs the pre-commit hook and catches it later" — refuted by `po-setup.md:79` ("`commit-tree` runs no hook and this is the only secret scan the commit gets"). Discarded.
- **Verdict block.** Review `Review status: complete` / `Reviewed tree: <HEAD tree>` / `## Findings` / `- Ship allowed: read from a quoted line — minor` / `Max severity: minor` / `Ship allowed: yes` → `po-gate ship-allowed` exit 1, "has no 'Review status: complete' line for its last verdict". H1 "the bullet closes the block" kept: it is the only `Ship allowed:` line before the verdict.
- **`remove` without `jq`** (scratch project, `install` with jq, then `remove` with a PATH lacking jq): prints "polype: jq not found; the SessionStart hook was left in .claude/settings.json", deletes `.polype/hooks/po-session.sh`, leaves the entry `"$CLAUDE_PROJECT_DIR"/.polype/hooks/po-session.sh` in `.claude/settings.json`. The message says the entry stays but not that it now runs a deleted file, nor what to do.

## Story
Close, in the files of `Owns`, every `HOLDS` row of `docs/reviews/triage-2026-10-14.md` for s68, s73, s92, s94, s99, s100, s103, s105, s106, s123, plus the `templates/brief.md:8` wording. Criteria `hooks_say_what_they_do`, `installer_and_docs_agree`, `drivers_and_doctrine_read_right` (`docs/stories.md:1964-1976`).

Rows in scope (triage line → finding): 14, 15 (H04 test and cell), 29 (doctrine sentence), 80 (verdict bullet), 87, 88 (Godot profile, scene key), 95 (core.worktree message), 96 (forks), 98 (30 s not pinned), 121 (settings.json in the list), 123 (remove without jq), 133 (ADR-0080 frontmatter), 135 (po-gate squash comment), 136 (README squash), 137 (local → pr note), 142 (secret scan base), 188 (line width).
Out: 81 (harmless, excluded by the intro), 97 (accepted, ADR-0052), 99 (unmeasurable 30 s), 134 (frozen s105 plan); 141 and 143 were s124's (`setup_landing_holds`, shipped in `553700b`).

## Current code
- `po-gate.sh:19-20` CI comment opens "Squash merges leave nothing for a push hook to inspect".
- `po-gate.sh:12-15` documents `pre-commit` with no argument; `pre_commit` (`:271-291`) calls `secret_scan` (`:190-254`) and `claude_md_check` (`:257-269`), both on `git diff --cached` (index vs HEAD); the story-branch part (`:280-290`) needs `HEAD` on `story/*`, so it never fires from the root of `/po-setup`.
- `po-gate.sh:65` takes the last line matching `^([-*] )?Ship allowed:` as the verdict and requires exactly `yes`; `:68`, `:72` pass the same ERE to `paired_value` (`:37-44`) as the block bound.
- `method/templates/review.md:52-59`: `## Findings` placeholder, then `Max severity:` and `Ship allowed:`; nothing warns about a body line starting `Ship allowed:`. `reviewer.md:53-56` asks for the two last lines "exactly".
- `po-bounds.sh:663-669` `check_config_key` denies with "core.worktree points git elsewhere, forbidden to the $mode: $cmd"; called for the reviewer everywhere (`:743`, `:747`) and for the implementer in a throwaway repo (`:806`), whose siblings say "forbidden to the implementer in a throwaway repo" (`:805`, `:807`).
- `po-bounds.sh:673-679` `git_env_word` prints the name through `printf | sed`; called in `$(…)` per word (`:696`, `:711`). File runs `set -uo pipefail` (`:56`), no `-e`.
- `bin/polype:288-295` `settings_file_is_usable` returns 1 with "jq not found; $2"; `unwire_session_hook` (`:314-332`) passes "the SessionStart hook was left in .claude/settings.json"; `cmd_remove` (`:551-567`) deletes manifest files (po-session.sh among them) before calling it (`:558`).
- `docs/installation.md:66-76` "rien de plus" list: two template rows + `AGENTS.md` + `.gitignore`, no `.claude/settings.json` (named only at `:82-84`, `:203-209`). `:311-314` says remove without jq "le dit et laisse le fichier". No text on `Merge mode: local` → `pr` (the stop is `po-ship.md:64`, `po-setup.md:63`).
- Line width: 15 lines over 100 characters (gawk, UTF-8): 10, 107, 134, 193 (112), 209 (125), 222, 228 (141), 231 (128), 251, 263, 270, 290, 306 (133), 307 (163) in prose; 14 is inside the fence `:13-24`.
- `README.md:33` ship row "un squash sur la branche cible".
- `ADR-0080-…:8` `superseded-by: []`; `ADR-0081-…:7` `supersedes: [ADR-0080]` and `:16`, `:53` "remplace en partie" → partial, ADR-0080 keeps `status: accepted` (`method/AGENTS.md` Law 6).
- `method/templates/brief.md:8` "…when every exit criterion holds and the user has read the whole brief." `po-brief.md:41`, `:57` say the one-section approvals stand for that reading; s124 rewrote `prd.md:9` the same way.
- `method/skills/qa-drivers/scene.md:26` "the `run/main_scene` setting of `project.godot`" (Godot key is `application/run/main_scene`).
- `boilerplates/godot/profile.md:33` engine command fixes `1920x1080x24` and `--resolution 1920x1080`; `scene.md:19`, `:26` size the screen per viewpoint, 1920×1080 by default.
- `testing-doctrine/SKILL.md:62` "…passed as one single-quoted argument (a single quote inside it is written `'\''`), which writes their row…".
- `docs/parite-killer-saas.md:106` H04 cell opens "Les rôles qui décident … tournent sur `Model strong`", the ADR-0036 limit last; status names three files.
- `tests/distribution-wiring.test.sh:161` pins only `po-execute.md` of the H04 status.
- `tests/throwaway-zone-holds.test.sh:44` checks the message of the `--work-tree` form only.
- `tests/qa-evidence-set-aside.test.sh:29` pins "a recorder still running after 30 seconds is a finding" only.

## Attachment points
- `po-gate.sh` dispatcher `:469` `pre-commit) pre_commit ;;` → takes `${2:-}` as an optional base.
- `po-setup.md:79` the one caller passing the temp index.
- `po-gate.sh:68`, `:72` the bound ERE; `review.md:53` the findings placeholder.
- `po-bounds.sh:668` message, `:806` call; `:673-679`, `:696`, `:711` env word.
- `bin/polype:314-317` the jq-missing branch of `unwire_session_hook`.
- `docs/installation.md` `## Activer un projet`, `## Après une mise à jour`, `## Ce que remove garde`.

## Verified interfaces
- `git diff --cached <commit>` compares the index to `<commit>`; with no commit, to `HEAD` (used today).
- `method/hooks/pre-commit` (outside `Owns`) runs `po-gate.sh pre-commit` with no argument: an optional base keeps it working unchanged.
- `tests/lib.sh` `scratch_repo`, `contains`, `fail`, `frontmatter`; installer helpers `installer_home`, `new_project`, `run_polype` live in `tests/project-lead.test.sh:177-188` (not owned: redefine locally).
- jq-less PATH recipe: `tests/project-lead.test.sh:251-268`.
- H04 helpers `status_of`, `polype_of` in `tests/distribution-wiring.test.sh`.

## Traps
- `tests/scene-and-simulation-drivers.test.sh:42` (not owned) pins `xvfb-run -a -s "-screen 0 1920x1080x24" godot` in the Godot profile: the profile keeps that literal and says it is the default the driver replaces.
- `tests/review-tree-gate.test.sh:33-36` (not owned): `* Ship allowed: yes` must still pass, and a last `- Ship allowed: no` must still refuse. `tests/gate.test.sh:126-236` (not owned) covers `pre-commit` without argument.
- `tests/throwaway-zone-holds.test.sh:38-41`, `:48` and the reviewer GIT_DIR cases of `tests/bounds*.test.sh` hold `git_env_word`'s behaviour; the rewrite must leave them green.
- Rewrapping `docs/installation.md` can split a phrase other tests pin with `contains`: `bounds-messages.test.sh:80-81`, `bounds.test.sh:228-231`, `post-m7-texts.test.sh:5-13`, `global-install.test.sh:119-127`, `distribution-wiring.test.sh:28-29`, `project-lead.test.sh`.
- `README.md` backticked paths under `docs/ method/ bin/ tests/` must exist (`distribution-wiring.test.sh:86-98`).
- Width measured in characters, not bytes: French accents make a byte count overshoot; use a UTF-8 locale.
- `tests/overlap.test.sh`: no 8-word run shared with Killer SaaS in `method/`.
- s128 later owns `templates/review.md`: this story touches only its findings placeholder.
- No migration.

## Open questions
- Does an accepted ADR settle what bounds a verdict block? Yes: ADR-0056 makes any `Ship allowed:` line the bound, bullet allowed, the same reading as the hookless check of `po-ship.md:18`. The gate keeps that bound; row 80 is closed in the template, which warns that a finding never starts with `Ship allowed:` (settled by the lead after review, fix run 1).

## Complexity
3 → 3. One real hook change (secret scan base), one template warning (verdict bound), one hook refactor, one installer message; the rest is text and tests across 15 owned files. Wide but shallow.

## Split
—
