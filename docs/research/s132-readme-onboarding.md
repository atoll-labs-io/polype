# Research — s132-readme-onboarding

[Story](../stories.md)

## Structuring facts
- No assumption of the story is false. Bash 4.2 is the right floor: `declare -gA` at `bin/polype:504` needs 4.2;
  `po-session` only needs 4.0 (`declare -A`, `method/hooks/po-session.sh:106`) but the story asks 4.2 for both.
- `docs/installation.md` was not updated by s130 or s131: it still says the installer never touches files one
  added (`:3-5`), backs a hand-written `AGENTS.md` up instead of absorbing it (`:186`) and absorbs every
  `CLAUDE.md` unconditionally (`:9-11`, `:187-196`). The code (`bin/polype:174-256`, `:408-424`) says otherwise.
- Trap for the quickstart: `polype update <projet>` on a project activated with `init` lays `.claude/commands`,
  `agents`, `skills` down (checked: 23 files after `init`, 65 after `update .`), because `update` takes the
  full project PAIRS (`bin/polype:106-111`, `mode=init` only for `init`, `:747`). The README's update step
  must be `polype update --global` then `polype init .`, as `docs/installation.md:112` already says.
- The guard is a plain top-level `if` on `BASH_VERSINFO`: bash reads a script one top-level command at a time,
  so an early `exit` runs before any later function body is even parsed.
- The quickstart test clones the repo with `git clone file://$ROOT`: that clone holds the committed tree of
  `story/<id>`, not the working tree (checked: HEAD of a clone of this worktree is `story/s132-readme-onboarding`).

## Story
A newcomer reads the README alone and can install Polype, start, update, and knows what it does to their
configuration; an old bash says so clearly. Criteria: `old_bash_is_named`, `prerequisites_are_listed`,
`quickstart_runs_as_written`, `existing_config_is_explained`, `install_doc_tells_the_truth` (see stories).

## Current code
- `README.md` (67 lines): pitch, entry points, cycle, fleet, `## Installation` (`:43-56`, a plain ``` block
  listing four commands, link to `docs/installation.md`), repo layout, inspiration. No prerequisites, no
  quickstart, nothing on existing configuration.
- `bin/polype` (754 lines): `set -euo pipefail` at `:20`, then globals `:22-37` (bash 3 arrays only), functions,
  `main "$@"` at `:754`. First bash-4 constructs: `mapfile` `:147`, `declare -A` `:175`, `declare -gA` `:504`,
  `declare -A` `:571`, `:609`. No version check anywhere.
- `method/hooks/po-session.sh` (268 lines): `set -u` `:5`; silent exit outside a Polype project or in a
  `story/*` worktree (`:8-13`); header echo `:18`; `declare -A` at `:106`, `:142`, `:143`; always `exit 0`
  (`:268`). Output goes to stdout (session context).
- `docs/installation.md` (334 lines): see Structuring facts for the false sentences; collisions and
  `--set-aside` are not described at all; `Project CLAUDE file` appears nowhere.

## Attachment points
- Guard in `bin/polype`: right after `set -euo pipefail` (`:20`), before `POLYPE_VERSION` (`:22`).
- Guard in `po-session.sh`: after the story-worktree `case` (`:13`), before `local_md=` (`:15`): stays silent
  outside Polype projects, as `:4` promises, and precedes `declare -A` at `:106`.
- README: a prerequisites section, a quickstart section, a configuration section; keep `## Installation`.
- `docs/installation.md`: `:3-5`, `:9-11`, `:186-196`, a collision paragraph in `## Ce qui est posé dans un
  projet` and in `## Installation globale` (`:59-62`).
- Test file `tests/readme-onboarding.test.sh` (owned, new).

## Verified interfaces
- Collisions (`bin/polype:174-216`): a shipped destination absent from the old manifest whose content differs,
  or any symlink, stops the run before any write (exit 1, `polype: not laid down by Polype, left untouched:`
  per file, then `rerun with --set-aside`). With `--set-aside`: each moved to `<path>.before-polype`; an
  existing `.before-polype` stops everything. Applies to `--global` too (`~/.claude/agents/...`).
- `remove` puts set-aside files back (`drop_laid_file`, `:219-226`; payload case `:710-718`).
- Hand-written `AGENTS.md` (`:235-256`): absorbed into `AGENTS.local.md` under `## Notes moved from AGENTS.md`
  whatever `Project CLAUDE file` says; without `AGENTS.local.md`, kept as `AGENTS.md.before-polype`. Edge:
  stops (`:189-195`) when both a hand-written `AGENTS.md` and a different `.before-polype` exist without
  `AGENTS.local.md`.
- `Project CLAUDE file` (`:408-424`): `absorbed` → `absorb_claude_md` (`:351-378`, notes go to `## Notes moved
  from CLAUDE.md`); `kept` → `keep_claude_md` (`:382-405`, `@AGENTS.md` first line, creates `CLAUDE.md` when only
  `CLAUDE.local.md` exists); missing/other → touches nothing, names the setting on stderr.
  Template default `Project CLAUDE file: absorbed` (`method/templates/agents-local.md:38`, values `:71`).
- `missing_settings` (`bin/polype:298-322`) names missing settings on stderr; never writes.
- `check` (`:655-686`): exit 0 and `N installed files, none modified` when nothing drifted.
- `jq`: needed to merge the SessionStart hook (`bin/polype:432-455`, skipped with a stderr line without it);
  `po-bounds` refuses every call without it (`method/hooks/po-bounds.sh:830`), so implementer, qa and reviewer
  cannot work without `jq`.
- `gh`: `/po-ship` reads the forge through `gh` or `curl` with a token (`method/commands/po-ship.md:29`).
- Rules size: `method/AGENTS.md` is 20806 bytes (~20 Ko); the assembled `AGENTS.md` adds the project's
  `AGENTS.local.md` (template 6343 bytes; this repo's assembled file 23470 bytes).
- Quickstart dry run, done in a throwaway HOME: clone (file://), `~/src/polype/bin/polype install --global`,
  `mkdir -p ~/.local/bin`, `ln -s ~/.claude/polype/bin/polype ~/.local/bin/polype`,
  `export PATH="$HOME/.local/bin:$PATH"`, `cd ~/mon-projet && polype init .`, then `git -C ~/src/polype pull`,
  `~/src/polype/bin/polype update --global`, `polype update .`: both `check` runs exit 0.

## Traps
- `tests/distribution-wiring.test.sh:84-107`: every backticked `docs/`, `method/`, `bin/`, `tests/` token of the
  README must exist (placeholders `<…>` skipped), every `/po-…` must be a command; `:62-81` quote README
  phrases that must survive (`'`bin/polype` pose la méthode'`, `'polype init <projet>'`, the install link…).
- `tests/qa-fleet.test.sh:99-105`, `tests/surface-routing.test.sh:88-89`, `tests/hooks-installer-docs-cleanup
  .test.sh:51` (no « squash ») also read the README.
- `docs/installation.md` is read by many tests: `docs-and-eval-cleanup.test.sh:13-20` keeps `ceux qu'il trouve
  (ADR-0086)`, `ni `CLAUDE.local.md` : Claude Code ne lit`, `même privé`, `qui est commité`;
  `hooks-installer-docs-cleanup.test.sh:99-110` refuses prose lines over 100 characters and checks two
  sections; also `bounds-messages:80-81`, `bounds:228-233`, `global-install:119-128`, `installer:175-205`,
  `post-m7-texts:5-14`, `local-copy-checksums:156`, `project-lead:293`. None is owned: keep their phrases.
- `BASH_VERSINFO` is read-only and this machine has bash 5.3 only: the guard is tested statically and by
  running the extracted block with a substituted array name, never through a seam in shipped code.
- The version comparison must not refuse 5.0/5.1 (minor < 2 but major > 4): test 4.1 refused, 4.2 and 5.0 pass.
- A quickstart test with `CLAUDE_CONFIG_DIR` inherited from the developer would write into the real config:
  the test must export `HOME` and `CLAUDE_CONFIG_DIR` inside its scratch dir (pattern `global-install.test.sh:8-25`).
- Bash 4.2/4.3 treat `"${arr[@]}"` of an empty array under `set -u` as unbound; reading found every such use
  guarded (`bin/polype:148`, `:191`, `:244`, `:719`), but no bash 4.2 is available to prove it.
- No migration, no dependency, no ADR: the floor documents what the code already needs.

## Open questions
- `polype update <projet>` turning an `init` project into a full install looks like a defect of `bin/polype`
  outside this story (Law 7: `Issue tracker: —`); the plan only steers the README around it.
- Whether to promise anything on macOS beyond bash: the story says no (BSD `find`, `sed`, `readlink`).

## Complexity
Story 3 → 3: five documentation-heavy criteria, two small guards, one executable test of the README block.

## Split
—
