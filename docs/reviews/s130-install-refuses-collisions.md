# Review — s130-install-refuses-collisions

[Story](../stories.md) · [Plan](../plans/s130-install-refuses-collisions.md) · [Research](../research/s130-install-refuses-collisions.md) · [Record](../verif/s130-install-refuses-collisions.md)

Review status: complete
Fix loop: 0
Reviewed tree: f84354521f701bbc16fa9018734779d9805b6a07
Lenses run: none. No changed path or content matches Security, Migration, Dependencies or Performance: the diff covers a local CLI installer, docs and bash tests.

## Scope
I ran `git diff --name-only main...story/s130-install-refuses-collisions` and checked each path against the story's `Owns` line.
- `bin/polype`, `method/AGENTS.md`, `method/commands/po-setup.md`, `tests/install-collisions.test.sh` and `docs/decisions/ADR-0088-l-installeur-s-arrete-sur-une-collision-et-absorbe-l-agents-md.md` are all in `Owns`. The ADR file matches the entry `docs/decisions/ADR-0088-*`, and the plan names it.
- `docs/research/`, `docs/plans/` and `docs/verif/` for s130 are the story's own evidence.
- No path falls outside `Owns`. `git worktree list` shows no other story worktree running, so no other lane can collide. s131 also owns `bin/polype`, but it depends on s130 and has no worktree.

## Evidence reused
- `po-gate verif-current s130-install-refuses-collisions` exits 0 (`Verification mode: record`). The `Unit suite` row (`bash tests/run.sh`) exited 0 on the code that `Tree:` names. I did not rerun the full suite.
- The project has no type check: `Typecheck: —`. It also has no E2E command and no Build command.
- The story does not go to QA (`QA stage: —`).
- The record's "Not proven here" says the installer never ran against a real `~/.claude/` and that `docs/installation.md` is stale (that file belongs to s132).

## Steps
1. **Reuse.** The record is current (see above).
2. **References.** Everything the diff calls exists with the right signature: `sum_of`, `collect_shipped`/`SHIPPED_LINES`, `$manifest`, `$marker`, `prune_empty_dirs` and `unwire_the_project`. The new helpers `refuse_collisions`, `drop_laid_file`, `hand_written_agents_md` and `absorb_agents_md` are defined before use. `frontmatter` is at `tests/lib.sh:13`. `bash -n bin/polype` passes.
3. **Plan.** Tasks 1 to 6 are all present and match the plan. The `## Reuse` rows are respected: the collision check goes through `sum_of`, the shape copies `absorb_claude_md`, the manifest is the list of set-aside files, and the hold uses no `mktemp`. Run interdicts:
   - `bin/polype` contains no `cmp`, `diff` or `mktemp`.
   - `docs/installation.md`, `README.md`, ADR-0086, `absorb_claude_md`, the hooks and the four existing installer tests are not in the diff.
   - `method/` names no `docs/decisions/` that this diff added.
4. **Tests.**
   - Floor: `po-gate floor-guard` exits 0, so no check was lowered.
   - Budget: 7 tests, within the budget of 25. I found none of the six kinds of test that prove nothing. Snapshots compare `cksum` of every path, the HOME guard is present, and a method copy is used to change what is shipped.
   - Bite: I made each change below in turn, ran only the test files named, then ran `git checkout -- bin/polype` and confirmed `git diff --exit-code bin/polype` was clean each time.
     - The preflight's `exit 1` changed to `return 0`: `install-collisions` gives 2 FAIL (`collision_stops_before_writing`, `collision_stops_before_writing_global`).
     - The put-back in `drop_laid_file` disabled: 2 FAIL (`set_aside_is_explicit_and_undone`, `set_aside_is_explicit_and_undone_global`).
     - The global hold in `cmd_remove` disabled: 1 FAIL (`set_aside_is_explicit_and_undone_global`).
     - `rm -f "$aside"` in `absorb_agents_md` disabled: 1 FAIL (`hand_written_agents_md_is_absorbed`).
     - The `absorb_agents_md` call in `wire_the_project` removed: 3 FAIL across `install-collisions`, `install` and `installer`.
     - The manifest exemption (`|| continue` changed to `|| true`): 6 FAIL across `installer`, `local-copy-checksums` and `global-install`.
   - Every rule the story depends on bites.
5. **Values.** `<path>.before-polype` reuses the existing name in `unwire_the_project`. Exit codes match the existing installer: 1 for a stop, 2 for usage. Messages go to stderr with the `polype:` prefix, as the existing ones do. Hold directory: `$root/.polype-restore.$$`, as the plan says.
6. **Neighbours.**
   - `bin/polype-dev-install` runs `install` on a repository that has a committed `.polype/manifest`, so it sees no collision.
   - `unwire_the_project` still restores `AGENTS.md.before-polype` after the `cp` became `mv`. Its tests (`install.test.sh`, `installer.test.sh`) stay green under the record.
   - No other caller of the changed functions exists.

## Findings
1. **minor**: `usage` in `bin/polype` puts `[--set-aside]` on the `install|update|check|remove` line, but `check` and `remove` accept the option and ignore it without a word. The research left this open on purpose. Only the synopsis is misleading.
2. **minor**: in a project the earlier installer already set up, an `AGENTS.md.before-polype` it left behind is appended to `AGENTS.local.md` and deleted by the next `update` that finds `AGENTS.local.md`. The criterion `hand_written_agents_md_is_absorbed` covers this. But ADR-0088 only says "Un projet déjà installé ne voit aucune collision à son update"; it never names this one-time migration of an old backup. That backup may hold notes the person already moved by hand, so they would now appear twice. One line in a later ADR or in `docs/installation.md` (s132) would make it visible.
3. **minor**: a destination that is a symlink to content identical to the shipped file is taken over silently, as the criterion asks. However, `lay_down`'s `mv -f` replaces the link with a regular file, and `remove` then deletes it, so the person's link does not come back. I confirmed this in a throwaway HOME at `/tmp/tmp.E60ta8fGZ1`: `~/.claude/agents/reviewer.md` linked into a dotfiles folder became a regular file, and after `remove --global` the `agents/` folder was empty. The target file in the dotfiles folder survived, so no content is lost.
4. **minor**: when a hand-written `AGENTS.md` and an `AGENTS.md.before-polype` exist without an `AGENTS.local.md`, the preflight stops but does not say what to do next. It stops even when the two files are byte-identical, and `--set-aside` does not apply to this stop. Adding "run /po-setup first" to the message would close it.

No critical or major finding.

## Not verified
- **A real `~/.claude/`.** Every run was in a throwaway HOME, `CLAUDE_CONFIG_DIR` or repository, as in the record. To cover it, a person should run `polype install --global` on a machine whose `~/.claude/agents` or `skills` already holds same-named files, then run `--set-aside` and `remove --global`, and check each file comes back.
- **A `~/.claude/` or `.claude/agents` that is itself a symlinked directory** (dotfiles managers). This was never exercised. A person should try install and remove against such a layout.
- **An interrupted global `remove`** (killed between `rm -rf "$state_dir"` and the put-back) could leave `.polype-restore.<pid>` behind. I did not test it, and nothing recovers it automatically. A person can check for such a folder under `~/.claude/` after a failed remove.
- **A set-aside install that fails after the moves** (for example during `wire_the_project`) leaves the files moved without the manifest being written. I did not probe this.
- **`docs/installation.md`** (`:186`, `:320-322`) still describes the old backup behaviour. That is planned for s132 and not reviewed here.

Max severity: minor
Ship allowed: yes

---

# Review — s130-install-refuses-collisions

[Story](../stories.md) · [Plan](../plans/s130-install-refuses-collisions.md) · [Research](../research/s130-install-refuses-collisions.md) · [Record](../verif/s130-install-refuses-collisions.md)

Review status: complete
Fix loop: 1
Reviewed tree: 5db587120e9c0a6e318ebd8203b9ed70b66b0a5d
Lenses run: none. No changed path or content matches Security, Migration, Dependencies or Performance. The diff is a local bash CLI installer, method docs, an ADR and bash tests.

## Scope
I ran `git diff --name-status main...story/s130-install-refuses-collisions`. It lists `bin/polype`, `method/AGENTS.md`, `method/commands/po-setup.md` and `tests/install-collisions.test.sh`. All four are in the story's `Owns` line.
- `docs/decisions/ADR-0088-l-installeur-s-arrete-sur-une-collision-et-absorbe-l-agents-md.md` has status `A`, matches `docs/decisions/ADR-0088-*`, and the plan names it.
- The research, plan, verif and review files under `docs/` for s130 are the story's own evidence.
- No path falls outside `Owns`.
- `git worktree list` shows only main and this worktree. s131 and s132 also own `bin/polype`, but neither has a worktree, so no running lane collides.

## Evidence reused
- `po-gate verif-current s130-install-refuses-collisions` exits 0 (`Verification mode: record`). The record's `Tree: 49f36de…` matches HEAD outside `docs/`. The last `Unit suite` row (`bash tests/run.sh`) exited 0. I did not rerun the full suite.
- The project has no type check, E2E or build command (`Typecheck: —`, `E2E: —`, `Build: —`).
- The story does not go to QA (`QA stage: —`).
- The record's "Not proven here" points to throwaway HOMEs only, untested symlinked directories, interrupted remove and failed set-aside installs, and the stale `docs/installation.md`. All are carried into `## Not verified`.

## Steps
1. **Reuse.** The record is current (see above).
2. **References.** The fix commit `c468456` changes the following, and everything it calls exists:
   - In `bin/polype`: the `usage` lines, the symlink condition and the `AGENTS.md` copy check in `refuse_collisions` (`bin/polype:174-196`). It calls `sum_of` (`:116`), `hand_written_agents_md` (`:228`) and `$project`.
   - In the test file: three additions, using `stops`, `says`, `ok` and `new_project`.
   - `bash` ran the test file cleanly: 7 passed.
   - The new synopsis drops `[--hooks]` from `check|remove`. That is accurate: `$hooks` is only read by `set_hooks_path` (`:312`), on the install path.
3. **Plan, and the four loop-0 minors.**
   - Minor 1 (synopsis) is fixed: `check|remove` have their own line without the options.
   - Minor 2 (migrating the backup the old installer left) is fixed: ADR-0088 now has a bullet for it.
   - Minor 3 (a symlink replaced by a regular file) is fixed: any symlink destination is a collision, and `--set-aside` / `remove` move the link itself.
   - Minor 4 (no next step) is fixed: the stop now says `run /po-setup first …; --set-aside does not apply to AGENTS.md`.
   - Run interdicts still hold: there is no `cmp`, `diff` or `mktemp`, ADR-0086 is untouched, and so are `docs/installation.md`, `README.md` and the four existing installer tests.
4. **Tests.**
   - Floor: `po-gate floor-guard s130-install-refuses-collisions main` exits 0.
   - Budget: still 7 tests, within the budget of 25.
   - Fixtures: the symlink test points at a real file in a scratch `dotfiles/` folder with content identical to the shipped one, which is exactly the new case. The identical-copies test uses two real byte-identical files.
   - I found none of the six kinds of test that prove nothing.
   - Bite (only `install-collisions.test.sh` run each time; after each one, `git checkout -- bin/polype` and `git diff --exit-code bin/polype` came back clean):
     - Symlink rule put back to the old "dangling link only" form: 1 FAIL (`set_aside_is_explicit_and_undone_global`).
     - `AGENTS.md` stop made to ignore whether the copies are identical (any existing `.before-polype` stops): 1 FAIL (`hand_written_agents_md_is_absorbed`).
   - The loop-0 bites on the preflight exit, the put-back, the global hold, the absorb `rm -f` and the manifest exemption cover code this fix did not touch.
5. **Values.** The new messages go to stderr with the `polype:` prefix and `exit 1`, like the existing ones. Comparisons go through `sum_of` (`cksum`), as the story notes require.
6. **Neighbours.**
   - `absorb_agents_md` (`:234-255`) already handles two identical copies. It takes the aside once and skips `AGENTS.md` when it is a byte copy. Without `AGENTS.local.md`, its `mv` over an identical aside loses nothing.
   - `drop_laid_file` (`:219`) already tests `-L` on the backup, so a link that was set aside comes back as a link. The new test checks this with `readlink`.
   - Only files absent from the old manifest are checked for collisions, so an already-installed project or home sees no new stops from the symlink rule.

## The three deliberate departures
- **ADR-0088 body gained bullets.** The ADR is added by this story and is not on `main`, so no landed decision was rewritten. Law 6's "an accepted ADR is never rewritten" protects decisions that have landed. Still, the file already says `status: accepted`, and the plan said to leave its text alone unless a test showed a gap. Finding 1 records this.
- **A symlink counts as a collision even with identical content.** This is the safer behaviour, and it is recorded in ADR-0088. However, the criterion `collision_stops_before_writing` says "Un fichier identique au fichier livré est repris sans bruit", and a person could read that as covering a link to identical content. Finding 2 records this.
- **Two byte-identical `AGENTS.md` copies no longer stop the install.** This is consistent with the criterion: the stop only prevents losing one of two different texts, and identical copies lose nothing. It is tested and the rule bites. No finding.

## Findings
1. **minor**: `docs/decisions/ADR-0088-…md` gained three body bullets in the fix commit while its frontmatter says `status: accepted`. This goes against the plan's "leave its text alone unless the test shows a gap" and the letter of Law 6. No harm: the ADR has never landed on `Target branch`. Nothing to undo. If the project wants the letter kept, the person should state that an ADR's body is open until it first lands.
2. **minor**: the behaviour now goes against the plain reading of the criterion `collision_stops_before_writing` ("Un fichier identique … est repris sans bruit"). A symlink destination whose target is byte-identical now stops the install. ADR-0088 records the reason, which is to keep the person's link, but `docs/stories.md` was not updated. A person may want to add one clause to the criterion, e.g. "sauf un lien symbolique".

No critical or major finding.

## Not verified
- **A real `~/.claude/`.** Every run was in a throwaway HOME or `CLAUDE_CONFIG_DIR`. To cover it, a person should run `polype install --global`, then `--set-aside` and `remove --global`, on a machine whose `~/.claude/agents` or `skills` already holds same-named files, including links from a dotfiles manager. They should check each file comes back as it was.
- **A `~/.claude/` or `.claude/agents` that is itself a symlinked directory.** `[ -L "$t" ]` only tests the last path component, and this layout was never exercised. A person should try install and remove against it.
- **An interrupted global `remove`** (killed between `rm -rf "$state_dir"` and the put-back) could leave `.polype-restore.<pid>` behind. I did not test it.
- **A `--set-aside` install that fails after its moves** leaves the files set aside but not listed in the manifest. I did not probe this.
- **A dangling `AGENTS.md.before-polype` link when `AGENTS.local.md` exists.** It is removed silently by `rm -f "$aside"` without being absorbed (it has no content). I found this by reading the code and did not exercise it.
- **`docs/installation.md`** still describes the old backup behaviour and synopsis. s132 owns it; I did not review it.

Max severity: minor
Ship allowed: yes
