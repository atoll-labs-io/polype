# Research — s137-modified-copy-survives-drop

[Story](../stories.md)

## Structuring facts
- **Root cause**: `drop_laid_file` (`bin/polype:236-243`) runs `rm -f "$root/$dest"` with no check of the
  recorded sum; it is the only deletion point of `cmd_install` (`bin/polype:598`), the ghosts of
  `cmd_update` (`bin/polype:639`) and `cmd_remove` (`bin/polype:742`). Input: any manifest entry the
  current mode or version no longer ships (install, init, update) or every entry (remove).
  Proof: reproduced below, the edited copy is gone after each of the three commands.
- `cmd_install` and `cmd_remove` never call `load_checksums` (`bin/polype:524-531`), so `RECORDED`
  is undeclared there. `has_drifted` (`bin/polype:560-564`) indexes `RECORDED[$path]`: on an undeclared
  name, bash reads it as an indexed array and evaluates `.claude/commands/x.md` arithmetically, so
  calling it without loading first is an error, not a silent "unmodified".
- Callers run under `set -euo pipefail` (`bin/polype:20`): a function returning 1 as the last word of
  an `a || f` list (`bin/polype:598`) or as a plain command (`bin/polype:742`) aborts the run. A
  "kept" signal by return status needs every caller to test it inside an `if` or `|| true`.
- No story assumption is false: every line number cited by the story matches `main` (058d6a2).

## Diagnostic
Reproduction (throwaway `HOME`/`CLAUDE_CONFIG_DIR` under `mktemp -d`, worktree's `bin/polype`, no file
written in the worktree):
1. `install <p>`, append a line to `.claude/commands/po-architect.md`, `init <p>` → the file is gone,
   manifest 23 lines, no line on stderr about it.
2. `install <p>`, same edit, `remove <p>` → the file is gone.
3. `install <p>`, add a ghost `.claude/commands/gone.md` to the manifest with a recorded sum in
   `.claude/.polype-checksums` that differs from its content, `update <p>` → gone, "1 removed".

Hypotheses:
- H1 — `drop_laid_file` deletes unconditionally. Refuted if it compares a sum before `rm`. Read
  `bin/polype:236-243`: no comparison. **Kept.**
- H2 — the drift check exists but sums are missing in `cmd_install`/`cmd_remove`. Refuted if those
  functions load sums. `grep -n load_checksums` → only `bin/polype:629` (update) and `:690` (check).
  **Kept** as a second cause: fixing H1 alone would crash (see Structuring facts) in install/remove.
- H3 — `update` already protects ghosts like it protects shipped files. Refuted by reproduction 3 and
  `bin/polype:639`: the `modified` branch (`bin/polype:649-654`) only covers shipped lines. **Discarded.**

## Story
A copy laid by Polype, edited by the person (recorded sum exists and differs), and no longer laid by
the current mode or version stays on disk byte for byte, leaves the manifest and both sum files,
and is reported `polype: modified, kept: <path>` on stderr — for `init`, `install`, `update` ghosts and
`remove`. Criteria: `init_keeps_a_modified_copy`, `update_ghost_keeps_a_modified_copy` (not counted in
"removed"), `remove_keeps_a_modified_copy`, `modified_copy_over_a_set_aside_file` (both stay, line
names both; ADR-0092 replaces ADR-0088 in part, only its `superseded-by` changes),
`kept_copy_becomes_the_persons` (next install shipping it stops on the collision, `--set-aside` moves
it), `header_lists_the_mode_file` (#96), `adr_records_the_choice` (+ `docs/installation.md`).

## Current code
- `drop_laid_file` (`bin/polype:236-243`): `rm -f`, then puts back `<dest>.before-polype` if present
  and prints `polype: put back: $root/$dest` (absolute path).
- `cmd_install` (`bin/polype:586-618`): `collect_shipped`, `refuse_collisions`, then drops every
  manifest entry not in `SHIPPED`, then rebuilds `manifest.next` and the sums from `SHIPPED_LINES` only
  (`start_sums`/`record_sum`/`finish_sums`, `bin/polype:536-558`). `init` is `cmd_install` with
  `mode=init` (`bin/polype:620-623`, `:770`).
- `cmd_update` (`bin/polype:625-676`): `load_checksums` at `:629`, ghosts dropped and counted at
  `:637-640`, final line `... $ghosts removed, ${#modified[@]} left modified` at `:675`.
- `cmd_remove` (`bin/polype:729-762`): per manifest line, global payload with a `.before-polype` is held
  aside (`:733-740`), else `drop_laid_file` (`:742`); then state files deleted (`:745-746`), global
  `rm -rf "$state_dir"` (`:748`).
- `finish_sums` (`bin/polype:549-558`): with no `.claude/` line recorded (init), deletes
  `.claude/.polype-checksums`. So a dropped or kept entry leaves both sum files without any change to
  the sum code: the new state lists only what this run laid.
- `refuse_collisions` (`bin/polype:165-216`): a shipped destination absent from the old manifest whose
  content differs, or a symlink, is a collision → exit 1, or moved with `--set-aside`; an existing
  `.before-polype` stops it. A kept copy is out of the manifest, so the next run shipping it again
  treats it as a collision with no new code.
- Header comment (`bin/polype:15-19`): "Three sit next to each other ... A project has a fourth,
  .claude/.polype-checksums" — `.polype/mode` (ADR-0091) is missing (#96).

## Attachment points
- `drop_laid_file` (`bin/polype:236`): the single place for the protection.
- `cmd_install`: `load_checksums` after `refuse_collisions`, before the drop loop (`bin/polype:595-600`).
- `cmd_update`: ghost counter at `bin/polype:639` must count only real deletions.
- `cmd_remove`: `load_checksums` before the loop (`bin/polype:731`); a global payload path under
  `polype/` must bypass the protection (it goes with `rm -rf`, `bin/polype:748`).
- Header `bin/polype:15-19`. `docs/installation.md` sections `### Les collisions` (`:231-243`),
  `## install ou update` (`:277-303`), `## Ce que remove garde` (`:354-377`).
- `docs/decisions/ADR-0088-*.md` frontmatter `superseded-by: []` (line 8). New
  `docs/decisions/ADR-0092-<slug>.md`, number reserved by the driver.

## Verified interfaces
- `has_drifted <path>` (`bin/polype:560`): returns 1 when no recorded sum, else compares
  `RECORDED[path]` with `sum_of "$root/$path"`; it does not check the file exists — callers guard with
  `[ -f ]` (`bin/polype:649`, `:693-695`). `sum_of` on a missing file prints a redirect error.
- `load_checksums` (`bin/polype:524`): `declare -gA RECORDED`, reads `$checksums` then `$local_sums`
  (set for every project, init included, `bin/polype:112`). Global: `$state_dir/checksums` under
  `~/.claude/polype/`, `local_sums` empty (`bin/polype:101`).
- `recorded_mode` (`bin/polype:94`): must keep its name (s138 refers to it).
- ADR frontmatter link format: `superseded-by: [ADR-0080]` (e.g. `ADR-0015-*.md:9`); an ADR replaced
  in part stays `status: accepted` (`templates/adr.md`), and `tests/install-collisions.test.sh:246`
  requires ADR-0088 to stay `accepted`.
- Test files define their own sandbox helpers (`tests/install-collisions.test.sh:8-61`,
  `copy_of_the_method` at `:53`); `tests/lib.sh` gives `scratch_repo`, `frontmatter`, `contains`, `fail`.

## Traps
- Tests that hold today and must stay green: `tests/installer.test.sh:58-66` (a ghost with **no**
  recorded sum is deleted — the "no sum → delete as before" limit keeps it green);
  `tests/install-collisions.test.sh:151-159` (unmodified ghost with `.before-polype` is put back);
  `:165-180` (global payload set aside then put back); `tests/local-copy-checksums.test.sh:52-62`
  (install → init deletes local sums; remove deletes them); `tests/global-install.test.sh:94-100`.
- `docs/installation.md`: prose lines ≤100 chars outside fences
  (`tests/hooks-installer-docs-cleanup.test.sh:111`); keep "ceux qu'il trouve (ADR-0086)" and the other
  phrases of `tests/docs-and-eval-cleanup.test.sh:13-22`.
- `cmd_update`'s existing message `modified, left as it is: <relative path>` (`bin/polype:673`) is for
  shipped files; the new line is a different one and must not replace it.
- Global install/update ghost under `polype/` that was modified would also be kept inside the payload;
  only `remove --global` is exempted by the story, the payload going whole.
- No migration; no dependency. `README.md` is not owned.

## Open questions
- Path form in the new line: absolute (`$root/$dest`, like `put back:` in the same function) or
  relative (like update's `modified, left as it is:`). The plan decides.
- Wording of the set-aside variant of the line (both paths). The plan decides.

## Complexity
Story 3 → 3. One deletion point, two missing `load_checksums`, an errexit-safe caller pattern,
docs and two ADR files. The set-aside and global-payload corners add care, not size.

## Split
—
