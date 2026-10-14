# Verification — s37-global-install

[Story](../stories.md) · [Plan](../plans/s37-global-install.md)

Tree: 4406f473a307d700f4ba722ccc4f5b1f076b01c6

Second run: the review of 2026-09-22 blocked the story (two criticals, two majors, four minors).
The table below is the fix run; the first run's results are kept underneath it.

| Check | Command | Outcome | Time (UTC) |
| --- | --- | --- | --- |
| Unit suite | `bash tests/run.sh` | exit 0 · 200 passed · 0 failed · 0 skipped | 2026-09-22T15:02Z |
| Type check | — | no such command in this project (`Typecheck: —`); `bash -n bin/polype` exit 0 after the last edit | 2026-09-22T15:04Z |
| End to end | — | no such command in this project (`E2E: —`, `E2E stage: —`) | — |
| Build | — | no such command in this project (`Build: —`, `Build stage: —`) | — |

Focused runs of the fix run, in this order:

| Finding closed | Command | Outcome |
| --- | --- | --- |
| Criticals 1–2, majors 3–4 (installer reworked) | `bash tests/run.sh global-install.test.sh installer.test.sh install.test.sh` | exit 0 · 29 passed · 0 failed (the 8 tests of the first run, unchanged, plus the two existing installer files) |
| The seven added tests | `bash tests/run.sh global-install.test.sh` | exit 0 · 15 passed · 0 failed |
| Documentation reworded | `bash tests/run.sh global-install.test.sh` | exit 0 · 15 passed · 0 failed |

Hand-run of the procedure `docs/installation.md` prescribes, in a `mktemp -d` with `HOME` **and**
`CLAUDE_CONFIG_DIR` redefined inside it — the exact sequence the review ran to find criticals 1
and 2:

| Step | Result |
| --- | --- |
| `bin/polype install --global` from the clone | exit 0 · 82 files · payload laid down |
| `~/.local/bin/polype install --global` through the documented symlink | exit 0 · 82 files, payload and commands intact (was: 0 files, payload destroyed, exit 0) |
| `~/.claude/polype/bin/polype update --global` from the payload | exit 0 · 82 files, `bin/ks-overlap` still there (was: `cp: cannot stat …ks-overlap`, exit 1) |
| `check --global` afterwards | exit 0 · "82 installed files, none modified" |
| `init <projet>` through the symlink | exit 0 · 17 files · `AGENTS.md` 10462 bytes (was: 17 files deleted, `AGENTS.md` truncated to 0 bytes, exit 1) |
| leftovers | no `*.polype-next`, no `manifest.next`, no `checksums.next` |

First run (kept for the record, tree `998dcd6a96d5d8fc9bda14bbafa7f638d5158aac`): `bash tests/run.sh`
exit 0 · 193 passed · 0 failed at 2026-09-22T14:46Z, focused runs per task on
`installer.test.sh install.test.sh` (21 passed) and `global-install.test.sh` (8 passed).

## Not proven here
- **No screen**: this story ships a shell installer and a French document; there is nothing to open in a browser.
- **No type check, no end-to-end, no production build**: `Typecheck`, `E2E` and `Build` are `—` in `AGENTS.local.md`. `bash -n bin/polype` (exit 0) is the closest equivalent and was run after the last edit of the script.
- **The real `~/.claude` was never written to.** Every test of `tests/global-install.test.sh` redefines `HOME` **and** `CLAUDE_CONFIG_DIR` inside its `mktemp -d`, and `guard_home` refuses to start any installer when `CLAUDE_CONFIG_DIR` is not inside that directory. The hand-run above did the same. Checked after the run: `~/.claude/polype` does not exist on this machine.
- **Not exercised: a global install synchronised by chezmoi across two machines.** The single-machine half of the procedure is now run end to end (table above), but no dotfiles sync between two hosts was performed.
- **Not exercised: Claude Code actually loading `~/.claude/commands/`.** That `CLAUDE_CONFIG_DIR` is its convention comes from the research; it was never checked against a real session, since no test may write into the developer's configuration. A person should do one real `install --global` and confirm a `/po-*` command appears.
- **Not exercised: `update <projet>` on a project activated by `init`.** There is no init-flavoured `update`, so refreshing such a project re-adds `.claude/commands|agents|skills`. Read from the code, not run; the review filed it as a decision for a later story, not a finding.
- **The s36 `has_drifted` major** (a file with no recorded checksum counts as intact) is untouched, as the plan's run interdicts require.
- Formatting and lint: no such commands in this project.

Verification status: complete
