# Review — s36-installer

[Story](../stories.md) · [Plan](../plans/s36-installer.md) · [Verification](../verif/s36-installer.md)

Diff reviewed: `git diff m5-distribution...story/s36-installer`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0

## Evidence reused
- [x] `po-gate verif-current s36-installer` → exit 0; `git diff --quiet 173becf HEAD -- . ':(exclude)docs'` → tree matches. `docs/verif/s36-installer.md` is complete, all exit codes 0 (`bash tests/run.sh` → 185 passed). Unit suite **not** rerun wholesale; only the two focused files were rerun, for mutation counting.
- Type check, end-to-end and production build: **the project has none** (`Typecheck: —`, `E2E: —`, `Build: —` in `AGENTS.local.md`). Nothing covers them at a later stage either.
- Lint/formatting: the project has no lint command; `bin/po-lint` scans `method/` only, and the diff touches no `method/` file.

## Plan
- [x] The nine tasks of `docs/plans/s36-installer.md` are all present in the diff: dispatch + payload, version/checksums, forwarder, `check`, `update`, `remove`, `tests/installer.test.sh`, `docs/installation.md`, the `Owns` correction. Nothing outside the plan.
- [x] Run interdicts checked one by one: the installer was never run against this repository — `git diff --name-only` lists 8 files, none under `method/`, `.polype/`, and not `AGENTS.md`, `AGENTS.local.md`, `CLAUDE.md`, `.gitignore`, `README.md`, `bin/po-lint`, `bin/ks-overlap`, `docs/parite-killer-saas.md`, `docs/defauts.md`; every `tests/*.test.sh` except the new `tests/installer.test.sh` is untouched; `docs/stories.md` changed on exactly one line (539); `grep` finds no `init` subcommand, no `--global`, no `~/.claude` path in `bin/polype`; this worktree's `core.hooksPath` was not touched (all my runs targeted `mktemp -d` projects).

## References
- [x] Every path `bin/polype` reads was opened: the five source trees (`method/commands|agents|skills|templates|hooks`) and `method/AGENTS.md` with its `<!-- Assembled by Polype.` marker on line 1 all exist. External tools used — `cksum`, `find -delete`, `grep -qxF`, `sed`, `git config` — all present and used as the old script used them. `tests/installer.test.sh` calls only helpers that exist in `tests/lib.sh` (`scratch_repo`, `fail`, `require_file`). No `method/` path contains a space, so the whitespace-split `read -r crc size path` in `load_checksums` is safe.
- [x] CLI contract exercised directly, and it matches `docs/installation.md` line by line: no args → usage, exit 2; `help` → usage, exit 0; unknown option → message + usage, exit 2; missing directory → exit 2; `remove` with no install → exit 1; `check` clean → exit 0, drifted → exit 1.
- [ ] One value nothing confirms: `POLYPE_VERSION` (finding 5).

## Rules
- [x] `AGENTS.md` conventions respected: commit message in English, no co-author trailer, one commit on `story/s36-installer`, `git status --porcelain` clean, no environment file in the diff. Evidence (research, plan, record) travels on the branch. `bin/polype` mode 100755 is committed, as is the forwarder's.
- [x] No accepted ADR contradicted. ADR-0006 (no Killer SaaS text): `tests/overlap.test.sh` scans `method/` only, so `bin/` and `docs/installation.md` are out of its reach — I read `docs/installation.md` against the French descriptions in `docs/parite-killer-saas.md` and found no borrowed phrasing; it is original prose.
- The plan's "no ADR" call is right: H01 and ADR-0004 already fix the direction, and every choice here (manifest format, `cksum`, version constant) is reversible inside one file.

## Tests
- [x] The ten assertions in `tests/installer.test.sh` pin the five acceptance criteria, each on a `scratch_repo` throwaway project. None of the six empty shapes: no test re-implements the installer, no `catch` swallows anything, the fixtures carry no identifier that answers for the check, and `installer_update_refreshes_an_untouched_file` works against a *copy* of `method/` it then modifies — a real source of truth, not a mock of one.
- [x] Within `Test budget: 25` — 10 new, and `tests/install.test.sh` (11 tests) is unchanged and still covers the install payload through the forwarder. No duplication between the two files.
- [x] Bite — 13 rules disabled one at a time, each rerun against only the file that exercises it, each undone and proved undone:

  | Rule disabled | File rerun | Failing tests |
  | --- | --- | --- |
  | `update`: never treat a file as drifted (`bin/polype:175`) | installer.test.sh | 1 (`update_preserves_a_modified_file`) |
  | `check`: never set a non-zero status on drift (`:231`) | installer.test.sh | 1 (`check_reports_drift`) |
  | `update`: do not delete ghosts (`:168`) | installer.test.sh | 1 (`update_leaves_no_ghost`) |
  | `stamp_version` does nothing (`:112`) | installer.test.sh | 5 |
  | `remove`: do not restore the backup (`:251`) | installer.test.sh | 1 |
  | `remove`: leave `@AGENTS.md` in `CLAUDE.md` (`:243`) | installer.test.sh | 1 |
  | `prune_empty_dirs` → `rm -rf .claude .polype` (`:62`) | installer.test.sh | 10 |
  | **`remove`: delete `AGENTS.md` whatever line 1 says (`:247`)** | installer.test.sh | **0 — finding 3** |
  | `install`: back up `AGENTS.md` even when marked (`:73`) | install.test.sh | 1 |
  | `install`: overwrite an existing `core.hooksPath` (`:105`) | install.test.sh | 1 |
  | `install`: append `@AGENTS.md` unconditionally (`:86`) | install.test.sh | 1 |
  | `install`: ignore the configured `Worktree root` (`:93`) | install.test.sh | 1 |
  | `install`: do not delete the previous manifest's files (`:134`) | install.test.sh | 1 |

  `git status --porcelain` empty and `git diff --exit-code` clean after the last one — no mutation left behind.
- [x] No test was made useless by the story; the eleven legacy tests keep their value through the forwarder, which is exactly why the plan kept them unmodified.

## Neighbours
- [x] Callers of `bin/polype-dev-install`: `tests/install.test.sh:4,24` (both green through the forwarder, including the nested-skill test that runs a *copy* of `bin/` — the forwarder's `dirname "$0"` resolution holds) and prose references in `docs/research/*` and `docs/verif/*` that describe the old line numbers; those are historical records and are correctly left alone. `README.md:21` and `docs/parite-killer-saas.md` mention installation but belong to s39's `Owns`.
- [x] `bin/polype` is also declared in s37's `Owns` (`docs/stories.md:556`); s37 is not started — `git branch -a --no-merged m5-distribution` lists only `story/s36-installer`, and `git worktree list` shows no other story lane. No concurrent writer.
- [x] `remove` verified empirically to keep a project-added `.claude/commands/my-own.md`, a `.claude/settings.json`, `AGENTS.local.md`, `docs/`, the two `.gitignore` lines, and to unset `core.hooksPath` only when it is ours.

## Findings

**major — `bin/polype:122-126` (`has_drifted`) — an installed file with no recorded checksum is treated as intact, so the first `check` and the first `update` after upgrading from the previous installer are wrong.**
`has_drifted` returns "not drifted" whenever `RECORDED[$path]` is unset. Every project installed by the previous generation has a `.polype/manifest` but no `.polype/checksums` — including this repository. Reproduced in a `mktemp` project, installing with `git show abf9024:bin/polype-dev-install`, editing one installed file, then running the new installer:

```
--- new check on a legacy install ---
no version stamp: .polype/version is missing
47 installed files, none modified          <- a file IS modified
check exit=1
--- new update on a legacy install ---
Polype 0.1.0 updated in /tmp/... (47 files, 0 removed, 0 left modified).
EDIT SILENTLY OVERWRITTEN
```

`docs/installation.md:71-73` promises that the "N fichiers installés, aucun modifié" sentence means everything is intact, and `:61-64` promises that `update` leaves hand-modified files in place and names them on `stderr`. On this one transition, both promises are false and the overwrite is silent. Not critical, for three reasons I want on the record rather than assumed: `check` still exits 1 in that state (the missing version stamp), `AGENTS.md` already forbids editing an installed file, and the installer's own closing message tells the user to commit `.claude/` and `.polype/`, so the overwrite is recoverable from git. It is one-shot — after one run, checksums exist and behaviour is correct. Fix: in `has_drifted`, treat a path absent from `RECORDED` as drifted (or report it as `unknown:`), so the first update after an upgrade reports instead of overwriting.

**minor — `bin/polype:247` — the assembly-marker guard in `cmd_remove` is covered by no test.**
Replacing `if [ -f "$project/AGENTS.md" ] && head -n 1 ... | grep -qF "$marker"; then` with `if [ -f "$project/AGENTS.md" ]; then` leaves all ten tests green. That guard is what stops `remove` from deleting an `AGENTS.md` a project wrote after the install — the closest thing to data loss in the script. The code is right; the coverage is not. One test (write an unmarked `AGENTS.md` over the assembled one, `remove`, assert it survives) closes it.

**minor — `bin/polype:115-120` — `declare -gA` raises the required bash from 3.2 to 4.2, unannounced.**
The old script used no associative array and ran on bash 3.2; `bin/polype` needs 4.0 for `declare -A` and 4.2 for `-g`. On a machine whose `bash` is 3.2 — macOS's `/bin/bash`, which `#!/usr/bin/env bash` picks when no newer bash is earlier in `PATH` — `install` and `remove` still work while `check` and `update` die with `declare: -A: invalid option`, a failure mode that looks like a broken install. No portability requirement is written anywhere in the repository (I grepped `docs/`, `method/AGENTS.md`, `AGENTS.local.md`: nothing about macOS, darwin or bash versions), so this is a gap to close by decision, not a rule breach. I did **not** run bash 3.2 — this is read from the code and the bash manual. Either guard on `BASH_VERSINFO` with a clear message, or state the requirement in `docs/installation.md`.

**minor — `bin/polype:15` — `POLYPE_VERSION="0.1.0"` is confirmed by nothing and bumped by nothing.**
No tag, no changelog, no release step; `docs/installation.md` never says who raises it. The consequence is that `cmd_check`'s branch at `:210` (`this installer ships X: run polype update`) can only ever fire if a human edits the constant by hand, which nothing reminds them to do. The criterion only asks for a stamp that `check` shows, and that is met — but the stamp is inert until a release procedure names it (plausibly s37 or s39).

**minor — scope: two paths sit outside the `Owns` line as it stood on `m5-distribution`.**
`bin/polype-dev-install` and `docs/stories.md` itself. The `Owns` on the target branch reads `bin/polype`, `tests/installer.test.sh`, `docs/installation.md`; the lane added `bin/polype-dev-install` to it in the same commit (`docs/stories.md:539`). I rate this a gap in `Owns` rather than an implementer breach: the story's own notes (`docs/stories.md:549`) order keeping that alias, the research named the gap as its first structuring fact and the plan declared the widening as task 9 — the choice was made visible rather than hidden, and no other running lane claims either path. Worth naming anyway, because `docs/stories.md` is covered by no story's `Owns` while every lane reads it: under `/po-drive`, two lanes each amending their own `Owns` line write the same file concurrently. A rule about who may edit `docs/stories.md` mid-flight would settle it.

**minor — `docs/parite-killer-saas.md` H01/H02 not updated although s36 declares those matrix lines.**
The `AGENTS.local.md` convention says a story updates the status cell of the matrix lines it implements. The plan deferred it on purpose: that file is in s39's `Owns` (`docs/stories.md:570`) under criterion `parity_matrix_reflects_the_distribution` (`:588`), and the record names the deferral. Correct call — flagged only so it is not lost between the two stories.

## Not verified
- **The installer was never run against this repository**, per the plan's run interdict. Nothing here proves how `install`/`update` behave over this repo's *tracked* `.polype/` (18 tracked files), nor that the two new state files land cleanly in git. Finding 1 says they will not, on the first pass. Before anyone runs `bin/polype update .` for real, a person should run it on a scratch clone and read `git status` — expect `.polype/checksums` and `.polype/version` as new untracked files, and every locally-edited installed file silently overwritten.
- **bash 3.2 was never executed.** Finding 4 is read from the code, not observed; this machine only has bash 5.3.15. A person with macOS should run `/bin/bash bin/polype check <project>` once.
- **`cksum` collisions were not attempted.** It is CRC32 plus size, not a content hash. The record documents three hand-edit shapes detected manually; I re-verified the append case only. A same-length, same-CRC edit would read as intact. Low odds, zero cost to eliminate by moving to a hash if that ever matters.
- **The `--hooks` chaining advice was never exercised.** I only saw the "left unchanged" branch fire (the legacy test with `.husky`); nobody has actually chained `.polype/hooks/pre-commit` from a foreign hooks path to confirm that the message's instruction works.
- **No screen, no flow, no third party.** This story has no UI, so nothing was opened in a browser and `docs/design-system.md` does not apply; no external service is involved, so no mock stood in for one.
- **No type check, no end-to-end run, no production build** — the project defines none (`Typecheck: —`, `E2E: —`, `Build: —`). A type error is impossible here (bash), but nothing at any stage catches a syntax error in a path the tests never take; `bash -n bin/polype` would be a cheap addition to the suite.
- **The global install and `init` are absent by design** (s37), and `docs/installation.md:17-18` correctly says so rather than promising them.

Max severity: major
Ship allowed: yes
