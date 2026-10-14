# Research — s36-installer

[Story](../stories.md)

## Structuring facts
- **Owns is incomplete.** `docs/stories.md:539` lists `bin/polype`, `tests/installer.test.sh`, `docs/installation.md`, but `docs/stories.md:549` orders keeping `bin/polype-dev-install` as an alias — a path outside Owns. Owns must gain `bin/polype-dev-install`; no other running lane claims it.
- **The manifest format is frozen by a test this story may not edit.** `tests/install.test.sh:72` appends a bare path line to `.polype/manifest` and expects the next run to delete that ghost. Checksums cannot replace the one-path-per-line format; they need their own file.
- **Both scripts must locate themselves from `$0`.** `tests/install.test.sh:20-26` copies `bin/` and `method/` into a temp dir and runs the copy; `bin/polype-dev-install:11` already does `dirname "$0"/../method`. The alias must resolve `bin/polype` the same way.
- **No version source exists**: `git tag` is empty, there is no `VERSION` or `package.json`, and Owns allows no new file outside `bin/polype`. The stamp must be produced by `bin/polype` itself.
- **`.claude/` is untracked here only by the user's global ignore** (`~/.config/git/ignore:7`), while `.polype/` is tracked (18 files, incl. `.polype/manifest`). `remove` must not assume either state.

## Story
Replace the development script with a real installer `bin/polype` carrying four subcommands.
- `installer_supports_install_update_check_and_remove` — `install <project>`, `update`, `check`, `remove` exist and do what they announce.
- `installer_update_leaves_no_ghost` — update deletes files of a previous version no longer shipped, never a file the project added.
- `installer_check_reports_drift` — `check` lists installed files modified in place and exits non-zero when there are any.
- `installer_stamps_a_version` — the installed version is written to `.polype/version` and shown by `check`.
- `installer_remove_leaves_the_project_intact` — `remove` takes back what it laid down, keeps `AGENTS.local.md`, the project's documents and its `.gitignore`.

## Current code
- `bin/polype-dev-install` (88 lines, `set -euo pipefail`) is the whole current installer. Its shape:
  - `:11` resolves `method/` from `dirname "$0"`; `:13-21` parses one positional project dir plus `--hooks` in any position, rejecting other `-*` with exit 2.
  - `:25-27` deletes every path of the previous `.polype/manifest`, then `:29` opens `manifest.next`; `:31-42` `install_file`/`install_tree` copy and record; `:44-48` ship `commands`, `agents`, `skills` → `.claude/`, `templates`, `hooks` → `.polype/`; `:49` `chmod +x` the hooks; `:50` swaps the manifest in; `:51` prunes empty dirs.
  - `:53-64` backs up a hand-written `AGENTS.md` to `AGENTS.md.before-polype` (detected by the marker on line 1 of `method/AGENTS.md`), then rebuilds `AGENTS.md` = method rules + `---` + `AGENTS.local.md`.
  - `:66-67` appends `@AGENTS.md` to `CLAUDE.md` exactly once; `:69-77` appends the configured `Worktree root` and `.env*` to `.gitignore` once each; `:79-86` sets `core.hooksPath` only when unset or already `.polype/hooks`.
- `tests/install.test.sh` (11 tests, all green on `m5-distribution`) pins every one of those behaviours.
- `docs/installation.md` does not exist. `README.md` exists but belongs to s39.

## Attachment points
- New `bin/polype` — the only file the four subcommands live in. No registry: `bin/` is not copied into projects (`docs/research/s25-method-lint.md:23`).
- `bin/polype-dev-install` becomes a thin forwarder to `bin/polype install "$@"`, keeping its usage and its exit-2 contract so `tests/install.test.sh` stays green untouched.
- New `tests/installer.test.sh`, discovered automatically by `tests/run.sh:6` (`*.test.sh`), using `scratch_repo` (`tests/lib.sh:46`) like the existing installer tests.
- New `docs/installation.md`.

## Verified interfaces
- `tests/lib.sh:46-53` `scratch_repo` → sets `SCRATCH`, `git init -b main`, neutralises global git config (`GIT_CONFIG_GLOBAL=/dev/null`, `:9`). `fail` (`:11`), `contains` (`:43`, exact `grep -qF`), `require_file` (`:41`).
- `tests/run.sh:17` runs each `test_*` under `set -eu` in its own process.
- `.polype/manifest` today: one relative path per line, sorted per tree (`bin/polype-dev-install:41`). 18 `.polype/` files are tracked by git in this repository.
- `.polype/hooks/pre-commit:4` execs `po-gate.sh pre-commit`; `core.hooksPath` is **unset** in this worktree (`git config --get core.hooksPath` is empty), so the gate does not fire on the story commit here.
- `method/AGENTS.md:1` carries `<!-- Assembled by Polype.` — the marker `bin/polype-dev-install:23,54` relies on. The root `AGENTS.md` carries it too, so a reinstall does not overwrite the backup.
- `docs/parite-killer-saas.md:103` (H01) asks for: project install, global install, per-project `init`, manifest update with no ghosts and untouched custom commands, unmodified templates refreshed and modified ones reported, version stamp, drift check. `:104` (H02) is already `fait — bin/polype-dev-install`.

## Traps
- **Run interdict.** `.polype/` and the root `AGENTS.md` are tracked; running the new installer on this repository would rewrite files outside Owns. Every previous story recorded that interdict (`docs/reviews/s35-fleet-design.md:20`). Install only into `scratch_repo` temp dirs.
- **The eleven legacy tests are the regression net** for the alias. They must pass unmodified; `bash tests/run.sh install.test.sh` is the cheap proof after every step.
- **`bin/polype` needs its executable bit committed** (`git update-index` records mode 100755) — `bin/polype-dev-install` is `-rwxr-xr-x`.
- **`set -euo pipefail` + `grep -c`**: `grep -c` returning 0 matches exits 1 and would kill the script; the current code sidesteps it with `grep -qx ... ||`. Keep that idiom.
- **`remove` and `.gitignore`**: the criterion says the project's `.gitignore` is kept, so the two lines the installer appended stay — deleting them could un-ignore a worktree folder still in use.
- `tests/overlap.test.sh` only scans `method/`; `bin/` and `docs/` are out of its reach, but ADR-0006 still forbids Killer SaaS wording.
- s37 also declares `bin/polype` and `docs/installation.md` in its Owns (`docs/stories.md:556`): the two lanes must never run together. s37 is not started.

## Open questions
- **Does s36 update `docs/parite-killer-saas.md`?** The convention says a story updates the matrix lines it implements, and s36 declares H01/H02 — but `docs/stories.md:570` puts that file in s39's Owns with a criterion covering H01–H04. Recommendation for the plan: leave the matrix to s39 and say so in the record, rather than write a file another story owns.
- **What does `update` do with a drifted file?** H01 asks for unmodified files refreshed and modified ones reported; the acceptance criteria only require drift reporting under `check`. The plan must choose: refresh everything silently, or skip and report drifted files.
- **Where does the version string come from** with no tag and no version file? Candidates: a constant in `bin/polype`, or `git -C <method repo> describe --always` with a fallback when the method is not a git checkout (the temp-dir test case). The plan decides and the test pins the shape, not the value.
- **Is `install` on an already-installed project an error, or the same as `update`?** The criteria distinguish the two names but not their behaviour.

## Complexity
Story's score 3 → **3**. Four subcommands over several states (fresh, installed, drifted, removed) is "business logic or several states"; the extra weight is the legacy compatibility net, not new territory. No split.

## Split
Not required.
