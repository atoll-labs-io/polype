# Review — s37-global-install

[Story](../stories.md) · [Plan](../plans/s37-global-install.md) · [Verification](../verif/s37-global-install.md)

Diff reviewed: `git diff m5-distribution...story/s37-global-install`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 1

## The previous review's findings, one by one

Each critical was reproduced against the current code in a `mktemp -d` with `HOME` **and** `CLAUDE_CONFIG_DIR` redefined inside it, not taken from the fix report.

| Finding (loop 0) | Verdict | How I established it |
| --- | --- | --- |
| critical — global install destroys its own payload | **closed** | `install --global` from the clone (82 files), then `~/.claude/polype/bin/polype install --global`: exit 0, 85 files before and after, manifest byte-identical, payload's `bin/polype` and `method/AGENTS.md` intact, no leftovers. Went further: simulated a chezmoi sync (a command changed, one added, one deleted, `POLYPE_VERSION` bumped, the running script itself rewritten) then ran the documented self-install — the new command landed, the dropped one was removed, the changed one was refreshed, the running script kept its own inode, `check --global` clean. The rename-over-destination is what makes replacing the live script safe; `cp` in place would have truncated the inode bash is still reading. |
| critical — the documented symlink makes every run destructive | **closed** | Through `~/.local/bin/polype -> ~/.claude/polype/bin/polype`: `install --global` → 82 files, commands intact; `init <projet>` → exit 0, 17 files, `AGENTS.md` 10495 bytes (was 0). A two-hop **relative** chain (`~/bin2/polype -> ../.local/bin/polype`) also resolves. |
| major — missing source directory → silent zero-file install | **closed for a missing directory**, open for an empty one — finding 1 below. A payload with `method/skills` deleted now stops `install` and `update` at exit 1, writes nothing, and the home keeps its 85 files. `init` correctly still runs (it ships neither skills nor commands) but the doc says otherwise — finding 3. |
| major — unsound `lay_down` unlink | **closed** | `update --global` from the payload no longer dies on `bin/ks-overlap`; write-aside-then-rename means a file that is its own source is read before it is replaced. |
| minor — three decided rules no test guards | **closed** | All three now bite; see Tests. |
| minor — stray word in the header usage | **closed** (`bin/polype:4`). |
| minor — `POLYPE_VERSION` stale | **closed** (`0.2.0`), though see finding 2 for what the freshness signal then tells the user to do. |
| minor — `mkdir -p "$home"` before the subcommand is known | **closed**; `target_is_the_user_home` no longer creates anything, and `installer_global_check_does_not_create_the_user_home` fails if it does. |

The s36 `has_drifted` major is untouched, as the plan requires, and is not re-reported.

## Scope (`Owns`)
`Owns`: `bin/polype`, `tests/global-install.test.sh`, `docs/installation.md`. The diff touches exactly those three plus the story's own evidence (`docs/research/`, `docs/plans/`, `docs/verif/`, `docs/reviews/`). Nothing outside. `git worktree list` shows this lane alone; `git branch --no-merged m5-distribution` lists only `story/s37-global-install`, so no path is contested.

## Evidence reused
- [x] `bash .polype/hooks/po-gate.sh verif-current s37-global-install` → exit 0. `Tree: 4406f47` matches HEAD (`6b60309`) outside `docs/`. `Verification mode: record`, record complete, every exit code 0: unit suite reused, not rerun — 200 passed, 0 failed.
- `Typecheck`, `E2E` and `Build` are `—` in `AGENTS.local.md`: the project has none of these commands, and I substituted nothing.

## Plan
- [x] Tasks 1–8 all present. The fix commit touched neither `docs/plans/` nor `docs/research/` — no task was retroactively rewritten to fit the code.
- [x] Run interdicts, each checked with an empty `git diff --name-only` for its path: `method/`, `bin/polype-dev-install`, `docs/parite-killer-saas.md`, `docs/defauts.md`, `docs/stories.md`, `tests/installer.test.sh`, `tests/install.test.sh`.
- [x] The plan's pivot holds on all three of its own failure modes: the payload resolves `../method` with no hard-coded path, `check --global` names a drifted payload file, and the chezmoi section names `manifest`, `checksums` and `version` as machine-local.

## References
- [x] `tests/lib.sh` helpers used by the new file (`$ROOT`, `$SCRATCH`, `scratch_repo`, `fail`, `require_file`, `contains`) all exist with the semantics assumed.
- [x] Every path the tests assert on exists in `method/`; `bash -n bin/polype` clean.
- [x] Values confirmed by running, not by reading: exit 2 for `--global` with a project and for a missing target, exit 1 for an incomplete payload and for `check`/`remove` with no install, exit 0 for a clean `check --global`.

## Rules
- [x] `AGENTS.md` conventions respected: bash tests, one file per story, French doc, English code comments, commit message English with no trailer.
- [x] ADR-0004 is the architecture implemented, and — unlike loop 0 — its promise now actually works: I ran the cross-machine procedure single-machine, end to end, with a payload genuinely replaced underneath the installer.

## Tests
- [x] Assertions pin the four acceptance criteria; none of the six empty shapes (real filesystem, real installer runs, no mock, no absorbing `catch`).
- [x] 15 tests against `Test budget: 25`. The eight added beyond the plan's seven are the review's findings turned into guards — justified.
- Bite (each mutation undone immediately, `git diff --exit-code -- bin/polype` clean after each, whole worktree proved clean at the end):
  - symlink resolution of `$0` removed → **1 failing** (`installer_runs_through_a_symlink`).
  - `require_payload` call dropped → **1 failing** (`installer_refuses_an_incomplete_payload`), and the mutant reproduced the old symptom exactly: `cd: .../method/skills: No such file` on stderr, "installed (68 files)", exit 0.
  - `lay_down` back to `rm -f` then `cp` → **2 failing** (`..._install_from_the_payload_keeps_it_whole`, `..._runs_through_a_symlink`).
  - `cmd_install` deleting every manifest path first → **2 failing** (same two).
  - `prune_mindepth=1` → `0` → **1 failing** (`..._remove_keeps_the_standard_directories`) — was 0 at loop 0.
  - `must_be_executable` → `return 1` → **1 failing** (`..._makes_the_gate_executable_from_a_stale_payload`) — was 0.
  - `warn_without_a_global_install` → hard stop → **1 failing** (`..._init_warns_without_a_global_install`) — was 0.
  - eager `mkdir -p "$home"` restored → **1 failing** (`..._check_does_not_create_the_user_home`).
- [x] No test weakened to let a finding close: every guard the fix added is a new assertion, and the eight tests of loop 0 are unchanged.

## Neighbours
- [x] `bin/polype-dev-install` still `exec`s `polype install "$@"`; its tests (`install.test.sh`, `installer.test.sh`) are green and untouched. Project mode is unchanged in behaviour — I re-ran `install <projet>` and got the same 29 files.
- [x] No other doc claims the global install does not exist; the only remaining occurrences of that sentence are in this story's own research and plan, quoting it.

## Findings

**major — `bin/polype:127` — a source directory that exists but is *empty* passes the guard and silently deletes what was installed from it.**
`require_payload` tests `[ -d "$from" ]` only, and `collect_shipped` refuses just a *total* of zero files. A payload whose `method/skills/` exists but is empty therefore installs happily: the skills are absent from `SHIPPED`, so the old manifest's entries are removed as ghosts. Run in global mode — `install --global` reports "installed in … (68 files)", exit 0, and `~/.claude/skills/` drops from full to **0 files**. Same in project mode with an empty `method/commands/`: `.claude/commands/` goes from 18 files to 0, exit 0, success message. This is the failure mode the loop-0 major described, one notch down, and the guard's own comment claims to catch "an incomplete copy of Polype". A partially-applied `chezmoi apply` or an interrupted rsync produces exactly this. Contained and recoverable by re-running from a complete payload, which is why it is major and not critical — but it is silent, and the natural guard is per-directory (`find "$from" -type f` non-empty), not per-total.

**minor — `bin/polype:335` + `docs/installation.md:13`, `:97-99` — the tool advises `update`, the chezmoi procedure requires `install`.**
`check --global` on a machine whose stamp is stale prints "this installer ships 0.2.0: run polype update". But after a dotfiles sync every tracked file was rewritten by chezmoi, so `update --global` sees each one as hand-modified: it leaves them in place, keeps the *old* checksum, and the synced method never reaches `~/.claude/commands/`. Reproduced: `update --global` after a simulated sync → "modified, left as it is: commands/po-execute.md", and `check --global` then reports those files as `modified:` indefinitely. Nothing is destroyed and the user is told on stderr, which keeps this minor; but the command table presents `update --global` as "rafraîchit la pose globale" with no caveat, while the chezmoi section (correctly) prescribes `install --global`. One sentence saying which command follows a sync, and why, would close it.

**minor — `docs/installation.md:24-27` — the incomplete-copy sentence is false for `init`.**
"Une copie de Polype incomplète — un répertoire source manquant — arrête `install`, `update` et `init` en **1**". A payload missing `method/skills` (or `commands`, or `agents`) does not stop `init`: verified, exit 0, project laid down. The *behaviour* is right — `init` ships neither — but the doc generalises to all three commands. `init` does stop for what it actually needs (`method/templates` missing → exit 1; `method/AGENTS.md` missing → exit 1, project untouched).

**minor — `bin/polype:23-27` — the symlink resolution loop has no cycle guard.** A symlink loop at the entry point makes the script hang before it does anything (verified: `timeout 5` returns 124). A hop counter, or `readlink -f` where available, bounds it. Pathological and self-inflicted, and the symptom is a visible hang rather than damage.

**minor — `bin/polype:153-159` — `*.polype-next` leftovers are never cleaned and never reported.** A run interrupted between `cp` and `mv` leaves `po-execute.md.polype-next` beside the real file; `check` does not list it (it is not in the manifest) and no later run removes it. `installer_global_install_from_the_payload_keeps_it_whole` checks for stray `manifest.next`/`checksums.next` but not for these.

**minor — `tests/global-install.test.sh:89`, `:212` — two remove tests that could be one.** `installer_global_remove_leaves_the_user_home_intact` and `installer_global_remove_keeps_the_standard_directories` each perform a full 82-file global install then a remove, and share two assertions (`[ -d "$H" ]`, an installed command gone). The file now takes ~17s for 15 tests; merging them loses no bite. Well within budget, named only for the CI time.

## Not verified
- **No screen.** This story ships a shell installer and a French document; there is no design artefact and nothing to open.
- **`Typecheck`, `E2E`, `Build` are `—`**: the project has no such commands, and I substituted none of my own. `bash -n bin/polype` is recorded by the implementer and I re-ran it after each mutation.
- **The real `~/.claude` was never written to.** Every run of mine was in a fresh `mktemp -d` with `HOME` *and* `CLAUDE_CONFIG_DIR` redefined inside it, and I checked the guard before each. Consequence: I still have **no** proof that Claude Code loads commands from `~/.claude/commands/`, nor that `CLAUDE_CONFIG_DIR` is really its convention — both come from the research. A person should do one real `install --global` on a machine and confirm a `/po-*` command appears in a session; that is the one claim the whole story rests on and that no test here can reach.
- **No chezmoi sync between two real machines.** I simulated one by rewriting the payload in place (new, changed and deleted files, plus the running script) and running the documented command, which exercises the interesting half; the dotfiles round trip — what chezmoi actually tracks, whether the `.chezmoiignore` for `manifest`/`checksums`/`version` works — was not run. A person should track `~/.claude/polype/` on two hosts once and check the state files stay local.
- **`update <projet>` on a project activated by `init`** was read, not run: there is still no init-flavoured `update`, so refreshing such a project re-adds `.claude/commands|agents|skills` it deliberately did not want. Carried over from loop 0 as a decision for a later story, not a finding.
- **The payload ships `bin/` whole**, so `ks-overlap` and `po-lint` — repository-development tools — land in every user's `~/.claude/polype/bin/`. That is what the plan decided; I note it rather than file it.
- **`check --global` exits 0 on a version mismatch.** That is s36 behaviour, unchanged by this diff (confirmed as context in the hunk) and consistent with the documented exit rules; not re-reported here.

Max severity: major
Ship allowed: yes
