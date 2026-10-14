---
validated: yes
---
# Plan — s132-readme-onboarding

[Story](../stories.md) · [Research](../research/s132-readme-onboarding.md)

Branch `story/s132-readme-onboarding`. Read `docs/research/s132-readme-onboarding.md` first; this plan builds
on it without repeating it.

## Story
The README alone lets a newcomer install Polype, start, update it, and know what it does to their own
configuration; a bash older than 4.2 is named instead of failing on `declare`. Criteria: `old_bash_is_named`,
`prerequisites_are_listed`, `quickstart_runs_as_written`, `existing_config_is_explained`,
`install_doc_tells_the_truth`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Bash version guard (two copies, `bin/polype`, `po-session.sh`) | new code, six lines each | nothing in the repo checks a version; the platform gives `BASH_VERSINFO`, used directly; a shared file would have to be sourced before the guard can run, and `po-session` ships alone in `.polype/hooks/` |
| Throwaway HOME for the quickstart test | already here: `scratch_repo` (`tests/lib.sh`), HOME/`CLAUDE_CONFIG_DIR` pattern of `tests/global-install.test.sh:8-25` | — |
| Section and fence extraction in the test | already here: the `awk` section idiom of `tests/docs-and-eval-cleanup.test.sh:10` | — |

## Tasks
1. [x] **Guard in `bin/polype`.** Right after `set -euo pipefail` (`:20`), one top-level block of this shape,
   using only `BASH_VERSINFO[0]` and `BASH_VERSINFO[1]` (the test renames that one word):
   ```
   if [ "${BASH_VERSINFO[0]}" -lt 4 ] || { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -lt 2 ]; }; then
     echo "polype: bash ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]} found, bash 4.2 or newer needed; nothing written (on macOS: brew install bash)" >&2
     exit 1
   fi
   ```
   The block starts with a line `if … BASH_VERSINFO …` and ends with the first `fi` alone on its line, so the
   test can cut it out. Exit 1 like an incomplete copy (`docs/installation.md:27-29`), not 2 (usage).
   Test: `test_old_bash_is_named`.
2. [x] **Guard in `method/hooks/po-session.sh`.** Same block after the story-worktree `case` (`:13`), before
   `local_md=` (`:15`): message on **stdout** (it is the session context), naming
   `po-session: bash X.Y found, bash 4.2 or newer needed`, then `exit 0`. Outside a Polype project the hook
   stays silent, as `:4` promises. Test: `test_old_bash_is_named`.
3. [x] **README.** Keep every phrase the existing tests quote (research, Traps) and the `## Installation`
   section; add, in French, before `## Installation`:
   - `## Prérequis`: Claude Code; git; bash 4.2 or newer, with the macOS path (`/bin/bash` is 3.2:
     `brew install bash`, open a new shell, `bash --version`), and the sentence that nothing beyond bash is
     promised on macOS (`find`, `sed`, `readlink` BSD); `jq`, which merges the `SessionStart` hook and without
     which the bounds hooks of `implementer`, `qa` and `reviewer` refuse every call; `gh` logged in, for a
     project whose forge is GitHub (`/po-ship` lands through a pull request).
   - `## Démarrage rapide`: a first ```` ```sh ```` block, exactly in this order:
     `git clone https://github.com/atoll-labs-io/polype.git ~/src/polype`,
     `~/src/polype/bin/polype install --global`, `mkdir -p ~/.local/bin`,
     `ln -s ~/.claude/polype/bin/polype ~/.local/bin/polype`, `export PATH="$HOME/.local/bin:$PATH"` (with a
     comment: put it in the shell profile), `cd ~/mon-projet` (comment: your git repository), `polype init .`.
     Then a separate ```` ```text ```` block of Claude Code commands: `/po-setup`, then `/po-brief` or `/po-prd`,
     `/po-stories`, `/po-stories-review`, `/po-architect`, `/po-design-system`, then `/po-drive`; one line says
     that `/po-setup` reruns the installer so `AGENTS.md` carries the settings. Then `### Mettre à jour` with a
     second ```` ```sh ```` block: `git -C ~/src/polype pull`, `~/src/polype/bin/polype update --global`,
     `cd ~/mon-projet`, `polype init .` — **never** `polype update .` on an `init` project, which would lay the
     commands into the project (research, Structuring facts).
   - `## Ce que Polype fait de ta configuration`: a file of the same name as one Polype lays down (an agent
     `reviewer.md`, a skill, in `~/.claude/` or `.claude/`) stops the install before any write, `--set-aside`
     moves each to `<chemin>.before-polype`, `remove` puts it back; a hand-written `AGENTS.md` goes to the end
     of `AGENTS.local.md` under `## Notes moved from AGENTS.md`, or waits as `AGENTS.md.before-polype` until
     `/po-setup` exists; a `CLAUDE.md` / `CLAUDE.local.md` follows `Project CLAUDE file`: `absorbed`, `kept`,
     line missing → untouched and named (bin/polype `handle_claude_md`); the size: one sentence holding exactly
     `environ <N> Ko` with N = `method/AGENTS.md` in Ko rounded (today 20), saying these rules plus the
     project's settings load at every session; the advice to try first on a throwaway clone with
     `polype install <clone>` and to take it back with `polype remove <clone>`.
   Tests: `test_prerequisites_are_listed`, `test_quickstart_runs_as_written`, `test_existing_config_is_explained`,
   plus the existing `tests/distribution-wiring.test.sh` (paths and commands named must exist).
4. [x] **`docs/installation.md`.** Rewrite `:3-5` (the installer never touches the project's settings and
   documents; a file of its own it did not lay down stops it, `--set-aside` aside); `:9-11` keeps
   `ni \`CLAUDE.local.md\` : Claude Code ne lit` and `ceux qu'il trouve (ADR-0086)` but says it is under
   `Project CLAUDE file: absorbed`, with `kept` (ADR-0089); add a `### Les collisions` subsection under
   `## Ce qui est posé dans un projet` (refusal, `--set-aside`, an existing `.before-polype` stops, a symlink
   always collides, the same holds in `~/.claude/`, `remove` puts back, ADR-0088), and adjust `:59-62`;
   replace `:186` (hand-written `AGENTS.md` absorbed under `## Notes moved from AGENTS.md`, whatever the
   setting; `.before-polype` only without `AGENTS.local.md`); make `:187-196` conditional on `absorbed`, keeping
   `même privé` and `qui est commité`, and describe `kept` and the missing line. Prose lines ≤ 100 characters.
   Tests: `test_install_doc_tells_the_truth`, plus the existing docs tests listed in the research.
5. [x] **`tests/readme-onboarding.test.sh`**, five functions named after the criteria (details in Test
   strategy). Then `po-run --story s132-readme-onboarding --label full-suite -- 'bash tests/run.sh'`.

## Fix run 1 (review findings, owner asked for all four)
6. [x] **major** — `docs/installation.md` sends an `init` project to `polype init .`, never
   `polype update .`; the lead lifts the guard-only interdict for the stderr hint of `handle_claude_md`
   in `bin/polype`, which now names the pose in use. Test: `test_setup_hint_names_the_pose`.
7. [x] **minor** — the `ln` line follows `CLAUDE_CONFIG_DIR` and uses `-sf` (README and installation doc).
   Test: `test_quickstart_runs_as_written` (non-default `CLAUDE_CONFIG_DIR`, link line rerun).
8. [x] **minor** — the throwaway-clone try comes before the first block, so before any `--global`.
   Test: `test_quickstart_runs_as_written` (intro before the first fence).

## Fix run 2 (loop-1 findings; finding 2, the po-session hint, left to the lead)
9. [x] **major** — the lead widens the permission to every `bin/polype` stderr hint naming
   `polype update .`: the hand-written `AGENTS.md` hint (`absorb_agents_md`) names `polype init .` under
   `init`, by the same `$mode` switch. Test: `test_setup_hint_names_the_pose` (now also an `AGENTS.md`).
10. [x] **minor** — the clone gets its own one-line `sh` block; the throwaway-clone try sits between it and
   the `install --global` block. Test: `test_quickstart_runs_as_written` (clone block alone, try between).

## Scene viewpoints
—

## Run interdicts
- `git diff main...story/s132-readme-onboarding` touches only `README.md`, `docs/installation.md`,
  `bin/polype`, `method/hooks/po-session.sh`, `tests/readme-onboarding.test.sh` and this story's `docs/`.
- In `bin/polype` and `po-session.sh`, the diff is the guard block alone: no other line changes, no
  variable, function or environment hook added for the test (no seam).
- No existing test file changes; every phrase they quote from `README.md` and `docs/installation.md` survives.
- No `.claude/` or `.polype/` file edited (installed copies); no new ADR.
- The quickstart test never writes outside its `mktemp -d` directory: `HOME` and `CLAUDE_CONFIG_DIR` both
  point inside it before the block runs.
- `polype update` behaviour on an `init` project is not changed here (research, Open questions).

## The pivot
The README's shell blocks are the test's input, run as written. It could be wrong three ways:
- The test rewrites more than the clone URL (a path, a `polype` call): compare the substituted text with
  the block — the only `sed` allowed replaces `https://github.com/atoll-labs-io/polype.git` by `file://$ROOT`,
  and the test fails if that URL is absent from the block.
- The block depends on the developer's environment (an inherited `CLAUDE_CONFIG_DIR`, a `polype` already on
  the `PATH`, as on this machine): the test drops from `PATH` every directory holding a `polype` before the
  block runs, so `polype` resolves only through the `~/.local/bin` link the block creates — the reviewer can
  delete the `ln -s` line and see the test fail.
- The clone holds the committed tree, not the working tree (research): the installer under test is the one on
  `story/<id>` at commit time; acceptable because the test proves the procedure, not the guard.

## Files touched
`README.md`, `docs/installation.md`, `bin/polype`, `method/hooks/po-session.sh`,
`tests/readme-onboarding.test.sh`, `docs/research/s132-readme-onboarding.md`,
`docs/plans/s132-readme-onboarding.md`, `docs/verif/s132-readme-onboarding.md`.

## Test strategy
Five tests, within `Test budget: 25`, one per criterion, in `tests/readme-onboarding.test.sh`.
- `test_old_bash_is_named`: static — in each of the two files, the line number of the guard's `if` is lower
  than the first line matching `declare -|mapfile|readarray`, and in `bin/polype` lower than the first
  `mkdir`/`cp`/`mv` command line. Dynamic — cut the block with `sed -n '/^if .*BASH_VERSINFO/,/^fi$/p'`,
  replace the word `BASH_VERSINFO` by `FAKE_VERSINFO`, run it in `bash -c 'FAKE_VERSINFO=(…); <block>; echo
  reached'` for `(3 2)` and `(4 1)`: polype exits 1, names `3.2` (resp. `4.1`) and `4.2` on stderr, no
  `reached`; po-session exits 0, names them on stdout, no `reached`; for `(4 2)` and `(5 0)`: `reached`.
  Bites if the guard is moved after a `declare`, removed, or compares the minor alone.
- `test_prerequisites_are_listed`: the `## Prérequis` section names `Claude Code`, `git`, `4.2`,
  `brew install bash`, `jq`, `SessionStart`, `gh`, and the BSD caveat.
- `test_quickstart_runs_as_written`: in a scratch dir, `HOME` and `CLAUDE_CONFIG_DIR=$HOME/.claude` exported,
  `git init` of `$HOME/mon-projet`; the ```` ```sh ```` blocks of `## Démarrage rapide` (update block included)
  in order; check order inside the first block (clone < `install --global` < `ln -s` < `polype init`), the
  Claude Code block between the two `sh` blocks and holding `/po-setup` then `/po-drive`, and no `/po-`
  inside a `sh` block; run them with `bash -e` after the URL substitution; end with `polype check --global`
  and `polype check "$HOME/mon-projet"`, both exit 0 and printing `none modified`; assert
  `$HOME/mon-projet/.claude/commands` does not exist after the update.
- `test_existing_config_is_explained`: the section names `--set-aside`, `.before-polype`, `AGENTS.md`,
  `Notes moved from AGENTS.md`, `CLAUDE.md`, `Project CLAUDE file`, `absorbed`, `kept`, `polype install`;
  extract N from `environ N Ko`, compute `wc -c < method/AGENTS.md` / 1024 and require N within ±25 %.
- `test_install_doc_tells_the_truth`: `docs/installation.md` holds `--set-aside`, `.before-polype`,
  `Notes moved from AGENTS.md`, `Project CLAUDE file`, `kept`, `ADR-0088`, `ADR-0089`; with its lines joined
  by spaces, it lacks `ni aux fichiers qu'on a ajoutés` and `écrit à la main est d'abord sauvegardé`; the
  paragraph holding `ceux qu'il trouve (ADR-0086)` also holds `Project CLAUDE file`.
No visual check: no screen.

## Done when
The five tests and the full suite pass through `po-run`, the README blocks run as written, one commit on
`story/s132-readme-onboarding`, a review with no open critical finding, shipped through a pull request.
