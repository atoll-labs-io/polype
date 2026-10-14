---
validated: yes
---
# Plan — s130-install-refuses-collisions

[Story](../stories.md) · [Research](../research/s130-install-refuses-collisions.md)

Branch `story/s130-install-refuses-collisions`. Read `docs/research/s130-install-refuses-collisions.md` first; this plan builds on it without repeating it. Decision record: `docs/decisions/ADR-0088-l-installeur-s-arrete-sur-une-collision-et-absorbe-l-agents-md.md` (`accepted`, written with this plan; it records the contract the story fixes, framed with the owner on 2026-10-14).

## Story
The installer stops before replacing a file it did not lay down, `--set-aside` moves such files out of the way and `remove` puts them back, and a hand-written `AGENTS.md` is absorbed into `AGENTS.local.md`. Criteria: `collision_stops_before_writing`, `set_aside_is_explicit_and_undone`, `hand_written_agents_md_is_absorbed`, `adr_records_the_contract`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Collision test (exists, not in manifest, differs) | this repository: `sum_of` `bin/polype:111`, `SHIPPED_LINES` `:140-144`, the assoc-array pattern of `SHIPPED` `:425-426` | — |
| `AGENTS.md` absorption | this repository: copy the shape of `absorb_claude_md` `:251-280` (aside file, `mv`, newline guard, heading) | — |
| Restore of a set-aside file | this repository: the manifest itself is the list (`:562`), and the `.before-polype` name already used by `unwire_the_project` `:548-550` | no new state file is needed |
| Global hold around `rm -rf` | new code (a few lines), `mkdir`/`mv` only | no existing helper; `mktemp` is off the reduced `PATH` of `tests/hooks-installer-docs-cleanup.test.sh:79` |

## Tasks
1. [x] **Option.** In `parse_target` (`bin/polype:57-66`) add `--set-aside) set_aside=yes ;;` before the `-*)` arm; declare `set_aside=no` with the other globals (`:34`). In `usage` (`:38-51`) add `[--set-aside]` to both synopsis lines and one option line saying it moves each file Polype did not lay down to `<path>.before-polype`, and `remove` puts it back. Test that fails if wrong: `test_set_aside_is_explicit_and_undone` (an unknown option exits 2).
2. [x] **Preflight.** New function `refuse_collisions`, called right after `collect_shipped` in `cmd_install` (before the `mkdir` at `:422`) and in `cmd_update` (after `collect_shipped` `:459`, before `load_checksums` and the ghost loop `:469`). It writes nothing until every check passed:
   - Read `$manifest` (when it exists) into a local assoc array. For each `SHIPPED_LINES` destination `t="$root/$dest"`: a collision when `dest` is not in the old manifest and (`-L "$t"` and not `-e "$t"`) or (`-e "$t"` and `sum_of "$t"` ≠ `sum_of "$src"`). Identical → no collision, no output.
   - Project mode only: a hand-written `AGENTS.md` (first line lacks `$marker`, as `:167`) while `AGENTS.md.before-polype` exists and `AGENTS.local.md` does not → also a stop, naming both (the assembly would otherwise lose one).
   - Collisions and `set_aside=no` → one stderr line per path `polype: not laid down by Polype, left untouched: <root>/<dest>`, then `polype: nothing written; rerun with --set-aside to move each one to <path>.before-polype`, `exit 1`.
   - `set_aside=yes` → first, any `<t>.before-polype` that already exists (`-e` or `-L`) → name it, `exit 1`, nothing moved. Then `mv "$t" "$t.before-polype"` for each, with `polype: set aside: <root>/<dest> -> <root>/<dest>.before-polype`.
   Test that fails if wrong: `test_collision_stops_before_writing`, `test_collision_stops_before_writing_global`.
3. [x] **Put back.** New helper `drop_laid_file <dest>`: `rm -f "$root/$dest"`, then when `$root/$dest.before-polype` exists (`-e` or `-L`), `mv` it back and say `polype: put back: <root>/<dest>`. Use it in the ghost loops of `cmd_install` (`:431`) and `cmd_update` (`:470`) and in the manifest loop of `cmd_remove` (`:562`). Global `remove`: before `rm -rf "$state_dir"` (`:566`), every `polype/…` path of the manifest whose backup exists is moved into `$root/.polype-restore.$$/<dest>` (`mkdir -p` its parent, no `mktemp`) instead of being restored in place; after the `rm -rf`, each is moved to `$root/<dest>` (`mkdir -p` its parent) and the hold directory removed. The manifest is read before any state file goes. Test that fails if wrong: `test_set_aside_is_explicit_and_undone`, `test_set_aside_is_explicit_and_undone_global`.
4. [x] **Absorb `AGENTS.md`.** New function `absorb_agents_md`, called in `wire_the_project` between `absorb_claude_md` and `assemble_agents_md` (`:345-346`); delete the `cp` block of `assemble_agents_md` (`:165-170`, and its comment). Sources, in this order: `AGENTS.md.before-polype` when it exists, then `AGENTS.md` when hand-written and not a byte copy (`cksum`) of the first.
   - `AGENTS.local.md` exists → build `AGENTS.local.md.polype-next` as `absorb_claude_md` does (`:266-275`): the file, the newline guard, `\n## Notes moved from AGENTS.md\n\n`, then each source; `mv` it over; then `rm -f` the `.before-polype`; say `polype: AGENTS.md moved into AGENTS.local.md under ## Notes moved from AGENTS.md`.
   - No `AGENTS.local.md` and a hand-written `AGENTS.md` → `mv` it to `AGENTS.md.before-polype` (the preflight guaranteed none exists) and say `polype: AGENTS.md kept as AGENTS.md.before-polype: no AGENTS.local.md to move it into; run /po-setup, then polype update .`.
   - Nothing to absorb → no output, no write. `unwire_the_project` `:548-550` stays as it is.
   Test that fails if wrong: `test_hand_written_agents_md_is_absorbed`.
5. [x] **Sentences.** `method/AGENTS.md:4`: "…which the installer only reads, except to append the notes it moves out of a `CLAUDE.md` or a hand-written `AGENTS.md`, and appends at the end of this file." `method/commands/po-setup.md:17`: end "…writes in it only to append the notes it moves out of a `CLAUDE.md` or a hand-written `AGENTS.md`." `bin/polype:11-12`: "…except to append the notes moved out of a CLAUDE.md or a hand-written AGENTS.md." In `method/AGENTS.md:149`, after the `CLAUDE.md` sentence, add: "A hand-written root `AGENTS.md` is absorbed the same way, under `## Notes moved from AGENTS.md`, and a file Polype did not lay down stops the installer unless `--set-aside` moves it (ADR-0088)." Leave the sentence `tests/no-claude-md.test.sh:106` quotes intact. Test that fails if wrong: `test_hand_written_agents_md_is_absorbed_in_the_rules`.
6. [x] **Tests.** Write `tests/install-collisions.test.sh` (seven tests below), run it, then the full suite once through `po-run`. ADR-0088 is already on the branch; check it against `test_adr_records_the_contract` and leave its text alone unless the test shows a gap.

## Scene viewpoints
—

## Run interdicts
- `docs/installation.md` and `README.md` end with an empty diff (s132 owns them; the doc's lines `:186` and `:320-322` stay stale until then).
- `absorb_claude_md`, `drop_legacy_claude_md_import`, `method/hooks/po-gate.sh`, `method/hooks/po-session.sh` unchanged: the `CLAUDE.md` rule is s131's.
- `docs/decisions/ADR-0086-*` and every other existing ADR: empty diff.
- No `cmp`, `diff` or `mktemp` in `bin/polype`; comparisons through `sum_of`.
- No new state file in `.polype/` or `~/.claude/polype/`: the manifest is the list of what was set aside.
- No edit under `.claude/`, `.polype/` or the root `AGENTS.md` of this repository (installed copies).
- `method/` text names no `docs/decisions/` (`tests/adr-directory.test.sh:20,27`).
- Existing tests unchanged: `tests/install.test.sh`, `tests/installer.test.sh`, `tests/global-install.test.sh`, `tests/local-copy-checksums.test.sh` must stay green as they are; if one needs a change, the implementer says which clause the story changed.
- A file in the manifest that the person edited keeps today's treatment (`update` keeps it, `install` replaces it); this story does not touch it.

## The pivot
"A collision is a shipped destination absent from the old manifest" carries everything. Ways it could be wrong:
- A checkout whose `.polype/manifest` came through git but whose `.claude/` copies did not (`.claude/` ignored) sees no file there, so no collision; one whose copies were committed has them in the manifest. Compare with `tests/local-copy-checksums.test.sh:65-152`, which must stay green.
- `init` straight over a project install deletes the `.claude/` entries as ghosts (`:429-433`); a following `install` then finds nothing. If the ghost loop restored a backup the person later edited, the next run would flag it as a collision — the intended answer.
- The global hold: if the manifest were read after `rm -f "$manifest"` (`:563`), or the hold sat under `$state_dir`, a set-aside payload file would be destroyed. `test_set_aside_is_explicit_and_undone_global` puts a user file at `polype/bin/polype` to prove it.

## Files touched
`bin/polype`, `method/AGENTS.md`, `method/commands/po-setup.md`, `tests/install-collisions.test.sh` (new); plus, from this stage, `docs/research/s130-install-refuses-collisions.md`, this plan and `docs/decisions/ADR-0088-l-installeur-s-arrete-sur-une-collision-et-absorbe-l-agents-md.md`.

## Test strategy
Layer: the installer run end to end in throwaway repositories and a throwaway `HOME`/`CLAUDE_CONFIG_DIR` (guard as `tests/global-install.test.sh:18-28`). "Nothing written" is a snapshot: `find <root> -path <root>/.git -prune -o -print | sort` plus `cksum` of each file, equal before and after. Seven tests, within `Test budget` 25:
1. `test_collision_stops_before_writing` — project: `.claude/agents/reviewer.md` = "mine", a byte copy of `method/agents/implementer.md` at `.claude/agents/implementer.md`; `install` exits 1, output names `.claude/agents/reviewer.md` and `--set-aside`, never `implementer.md`, snapshot equal, no `.polype/`. `init` with `.polype/templates/plan.md` = "mine" (throwaway global home): exit 1, snapshot equal. `update` on an installed project with a method copy shipping a new `method/agents/newcomer.md`, the project holding its own `.claude/agents/newcomer.md`, and a ghost line added to the manifest with its file: exit 1, ghost file still there, snapshot equal. Then remove only `reviewer.md`, keep the identical copy: `install` exits 0 and its output never names `implementer.md`.
2. `test_collision_stops_before_writing_global` — `$H/agents/reviewer.md` = "mine": `install --global` exits 1, `$H/polype` absent, snapshot equal; after a clean global install, a method copy shipping `method/skills/newcomer/SKILL.md` and `$H/skills/newcomer/SKILL.md` = "mine": `update --global` exits 1, snapshot equal.
3. `test_set_aside_is_explicit_and_undone` — project: `install --set-aside` with `.claude/agents/reviewer.md` = "mine": exit 0, `reviewer.md.before-polype` holds "mine", output says `set aside`; `remove`: `reviewer.md` holds "mine", no `.before-polype`. Also: a pre-existing `reviewer.md.before-polype` makes `install --set-aside` exit 1 with snapshot equal; a method copy that stops shipping `reviewer.md` puts "mine" back on `update`; `install --bogus` exits 2.
4. `test_set_aside_is_explicit_and_undone_global` — "mine" at `$H/agents/reviewer.md` and at `$H/polype/bin/polype`: `install --global --set-aside`, `remove --global`; both hold "mine", no `.before-polype`, no `.polype-restore.*` left in `$H`.
5. `test_hand_written_agents_md_is_absorbed` — with `AGENTS.local.md`: `install`; `AGENTS.local.md` still starts with its settings, holds `## Notes moved from AGENTS.md` and the notes; `AGENTS.md` starts with the marker and holds the notes; no `.before-polype`; output says it. Without: `install` leaves `AGENTS.md.before-polype` with the notes and says `run /po-setup`; write `AGENTS.local.md`, `update`: absorbed, `.before-polype` gone; `update` again: `cksum` of `AGENTS.local.md` and `AGENTS.md` unchanged. Hand-written `AGENTS.md` plus an existing `.before-polype` and no `AGENTS.local.md`: `install` exits 1, both intact.
6. `test_hand_written_agents_md_is_absorbed_in_the_rules` — `contains` the three new clauses (`method/AGENTS.md`, `method/commands/po-setup.md`, `bin/polype`), each with "hand-written" and `AGENTS.md`.
7. `test_adr_records_the_contract` — one `docs/decisions/ADR-0088-*.md`, frontmatter `status: accepted`; holds `--set-aside`, `## Notes moved from AGENTS.md`, `ADR-0086`, `Écartée`.
Bite check for the reviewer: drop the `exit 1` of the preflight (tests 1-2 fail), the restore in `drop_laid_file` (3), the global hold (4), the `rm -f` of the backup in `absorb_agents_md` (5).
No visual check: the story has no screen.

## Done when
All six tasks ticked; `tests/install-collisions.test.sh` and the full suite green through `po-run`; one commit on `story/s130-install-refuses-collisions` carrying the code, the tests, the research, this plan and ADR-0088; a review with no open critical finding.
