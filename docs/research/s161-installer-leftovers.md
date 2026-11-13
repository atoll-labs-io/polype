# Research — s161-installer-leftovers

[Story](../stories.md)

## Structuring facts
- **Partly false assumption (`interrupted_run_leaves_a_named_trace`):** each `--set-aside` move is already named as it happens (`bin/polype:261-264`, `polype: set aside: <old> -> <new>`). What is missing is a trace *at the stop*: a later failure (`mkdir` at `bin/polype:815`, any `set -e` exit) ends the run with a raw error as its last line, and the files are left moved while no manifest records them. The criterion holds once the stop itself repeats the list; a test that only looks for the per-move line would pass on today's code.
- Root cause, #143: `cmd_remove` holds a payload path's `.before-polype` in `$root/.polype-restore.$$` (`bin/polype:977`, `:992-998`) and puts it back only at `:1013-1017`, after `rm -rf "$state_dir"` (`:1009`). Any exit between the two (`move_out_of_payload` `exit 1`, `:382-383`, or a `set -e` failure) strands it unnamed. The script has no `trap` at all (`grep -n 'trap ' bin/polype` → nothing).
- Root cause, orphan aside: `absorb_agents_md` (`bin/polype:475-498`) takes `AGENTS.md.before-polype` as a source whenever it is a regular file (`:477`), whatever `AGENTS.md` is, appends it to `AGENTS.local.md` and runs `rm -f "$aside"` (`:490`); the message names only `AGENTS.md` (`:491`). The `rm` also hits an aside that was never a source (a dangling link, review s130 Not verified).
- Root cause, #137: `is_payload_state_file` (`bin/polype:270-275`) matches `*.next|*.polype-next` on the path relative to the payload, at any depth; its only caller, `refuse_foreign_payload_files` (`:340`), then skips the file, and `remove --global` deletes it with `rm -rf "$state_dir"` (`:1009`). ADR-0095 (Decision Outcome, "tout `*.next` et tout `*.polype-next`") wrote that rule: narrowing it needs ADR-0112 to supersede ADR-0095 on that one point, and ADR-0095's frontmatter is outside `Owns`.
- The oracle gate admits a criterion with no test: `po-gate oracle-intact` reads only the `Oracle file` table of `## Acceptance tests` (`method/hooks/po-gate.sh:608`) and never the criterion table; no agent or command requires one test per criterion (`grep` of `implementer.md`, `reviewer.md`, `po-execute.md`, `po-review.md`). The M20 rule's precondition holds; the lane carries on.

## Diagnostic
Reproduced in throwaway `HOME`/`CLAUDE_CONFIG_DIR` under `mktemp -d`, nothing written in the worktree.

| Defect | Run | Seen |
| --- | --- | --- |
| #143 | `install --global`; `polype/bin/polype.before-polype` added by hand; `polype/method/AGENTS.md` edited; a `mv` shim on `PATH` refusing any destination under `polype.kept/`; `remove --global` | exit 1, "could not move … nothing more written"; `.polype-restore.<pid>/polype/bin/polype` left, never named |
| #79 set-aside | project with `.claude/agents/reviewer.md` = `mine` and `.polype` a plain file; `install <p> --set-aside` | line 1 `set aside: …reviewer.md -> …reviewer.md.before-polype`, last line the raw `mkdir` error, exit 1; file left moved, no manifest |
| #79 orphan | project with `AGENTS.local.md` and `AGENTS.md.before-polype`, no `AGENTS.md`; `install <p>` | aside deleted, its text appended under `## Notes moved from AGENTS.md`, message `AGENTS.md moved into AGENTS.local.md` |
| #137 | `install --global`; `polype/method/notes.next` added; `update --global`; `remove --global` | update exit 0 without a word; remove deletes it and says "The files you put there yourself were left alone." |
| #144 | `grep -n 'could not move\|is not a directory' docs/installation.md` | nothing: the two s146 stops are undocumented |
| #132 | `method/AGENTS.md` `## Installed files`, last sentence | "stops the installer unless `--set-aside` moves it (ADR-0088)", no `polype/` exception |

Hypotheses:
- Orphan, H1 "`remove` deletes it" — refuted: `unwire_the_project` moves it back to `AGENTS.md` when that is absent (`bin/polype:964-966`); repro with `remove <p>` left `AGENTS.md`. Discarded.
- Orphan, H2 "`absorb_agents_md` deletes it" — refutable by the aside surviving an `install`; it did not survive. Kept.
- Set-aside, H1 "moves are never named" — refuted by `bin/polype:263` and the repro's first line. Discarded; see the false assumption.
- Set-aside, H2 "the stop leaves no trace of the moves" — refutable by a polype line after the failure; the last line is `mkdir`'s. Kept.
- #143, H1 "the hold is lost only on a kill" (review s130) — the shim repro strands it on an ordinary `exit 1`. The kill case is the same leftover with no chance to report. Kept, wider than thought.
- #137, H1 "a deep `*.next` is laid by the installer itself" — `lay_down` writes `<dest>.polype-next` at any depth (`bin/polype:200`) but only after every refusal (`cmd_install:812` vs `:835`), so no in-run temp file is ever seen by the check. A deep one is a leftover or a person's file. Kept.

## Story
The installer's stops never leave a file of the person behind unnamed. Criteria: `failed_remove_names_held_files`, `interrupted_run_leaves_a_named_trace`, `orphan_before_polype_is_reported`, `state_pattern_stays_at_the_top`, `docs_describe_the_kept_copy_stops` (s146's two stops in `docs/installation.md`; `method/AGENTS.md` `## Installed files` names the ADR-0095 exception without growing). Fixes #143, #137, #144, #132 and the installer points of #79.

## Current code
- `bin/polype` (1041 lines), `set -euo pipefail` (`:21`); stops print `polype: …` on stderr and `exit 1`; usage errors exit 2 (`:72`).
- `refuse_collisions` (`:209-265`): every check before any write, then the moves with one line each (`:261-264`). Called by `cmd_install` (`:814`) and `cmd_update` (`:866`), before `mkdir -p "$root" "$state_dir"` (`:815`) and the drops/lays.
- `move_out_of_payload` (`:371-385`): `mv` to `polype.kept/`, or "could not move …; it stays in the payload, nothing more written" and `exit 1`.
- `refuse_taken_kept_copies` (`:400-423`): the other s146 stop, "`<parent>` is not a directory, so `<path>` cannot move to `<kept>`; nothing moved, nothing written" (`:412`), exit 1 before any write.
- `cmd_remove` (`:975-1027`): `held`/`hold` are **locals** (`:977`). Loop over the manifest (`:986-1005`), then state files removed (`:1006-1007`), `rm -rf "$state_dir"` (`:1009`), put back (`:1013-1017`), `rm -rf "$hold"` (`:1018`).
- `absorb_agents_md` (`:475-498`), called by `wire_the_project` (`:733`) before `assemble_agents_md` (`:734`). The marker test is `hand_written_agents_md` (`:468-470`, `$marker` `:48`).
- `docs/installation.md`: collisions `:246-271`, state files `:273-293`, kept copies `:337-371`, `remove` `:422-440`.
- `method/AGENTS.md` `## Installed files`: 516 words; whole file 3754 words (`wc -w`, both identical on `main` e0a43b8).

## Attachment points
- One `EXIT` trap set in `main` (`:1029-1039`), reporting only on a non-zero status, fed by two **global** arrays: what `refuse_collisions` moved (`:261-264`) and what `cmd_remove` holds (`:997-998`). Locals are invisible to an `EXIT` trap fired by `set -e` (checked: `bash -c 'set -e; t(){ echo "${held[*]-unset}"; }; trap t EXIT; f(){ local held=(a); false; }; f'` prints `unset`).
- `absorb_agents_md` for the orphan; `is_payload_state_file` for the pattern.

## Verified interfaces
- Foreign line: `polype: not laid down by Polype, inside the payload: <path>` (`bin/polype:356`), `<path>` being `find "$payload_dir"` output, `$payload_dir` = `$(cd "$home" && pwd)/polype` (`:41-42`).
- Manifest order in global mode follows `PAIRS` (`:122-123`): commands, agents, skills, `polype/bin/*`, `polype/method/*`, each sorted; so every `polype/bin/` path is handled before `polype/method/AGENTS.md`.
- `refuse_foreign_payload_files remove` lets a `.before-polype` of a manifest path through (`:342-343`), so a hand-made `polype/bin/polype.before-polype` reaches the hold.
- Exit status survives an `EXIT` trap that does not call `exit` (checked: a trap after `exit 1` leaves `rc=1`; after success, `rc=0`).
- Test helpers: `scratch_repo`, `fail`, `require_file` (`tests/lib.sh`); `tests/run.sh` sources `lib.sh` and one file per process, `set -eu`.

## Traps
- **Pinned phrases** in `## Installed files`, from existing tests: "`bin/polype` is the installer", "`polype install <project>` does both at once inside a single repository", "the commands, the subagents and the skills in `~/.claude/`", "the templates, the gate and the assembled `AGENTS.md`", "`polype init <project>` then activates one repository", "a reference to `templates/<name>.md` means `.polype/templates/<name>.md`", "called `po-gate` in these rules", "committed on `Target branch`", "Never edit an installed file", "the pre-commit refuses one at any depth", "with `kept`, both stay, the installer makes the root `CLAUDE.md` start with `@AGENTS.md`", "A hand-written root `AGENTS.md` is absorbed the same way, under `## Notes moved from AGENTS.md`", "unless `--set-aside` moves it (ADR-0088)" (`tests/install-collisions.test.sh:235`). Cuts must spare these.
- Tests that read `bin/polype` behaviour: `installer`, `install`, `install-collisions`, `payload-refuses-foreign-files`, `drop-keeps-modified`, `payload-kept-outside`, `global-install`, `payload-edit-not-spread`, `local-copy-checksums`, `update-keeps-mode`, `claude-md-setting`, `no-claude-md`, `hooks-installer-docs-cleanup`, `readme-onboarding`, `project-lead`, `distribution-wiring`, `leftovers`, `platform-setting`, `bounds`. `install-collisions.test.sh:190-230` exercises the absorb paths: the designed flow (aside left by a first run without `AGENTS.local.md`, then absorbed by `update`) has Polype's `AGENTS.md` in place and must keep working.
- `tests/payload-refuses-foreign-files.test.sh:65` only checks that `payload.sums` lists no `.next` file; it pins no depth (answers the stories review's open question).
- `docs/installation.md` is read by 16 test files; new text adds, it never rewrites a pinned sentence.
- A failure-injection test cannot rely on `chmod` (a root runner ignores it); a `mv` shim first on `PATH` is deterministic, and `bin/polype` calls `mv` by name.
- No migration. No other running M20 lane owns `bin/polype`, `docs/installation.md` or `method/AGENTS.md`; s165 and s166 (M21) depend on this story for `method/AGENTS.md` and `docs/installation.md`.
- For s165's open question: the foreign-file check never runs on a project's `.polype/` (`bin/polype:328` returns unless global or from the payload), so `.polype/inbox/` is not flagged.

## Open questions
- "Remet à leur place": the place before the run (`<path>.before-polype` while the payload still exists) or the final place (`<path>`, once it is gone)? The plan picks by whether `$state_dir` still exists.
- After an orphan aside is kept, the run assembles Polype's `AGENTS.md`, so the *next* run sees the designed waiting flow and absorbs it (announced). Acceptable reading of "le garde et le dit", or should an orphan stay out until the person moves it? The plan keeps the designed flow intact.
- `remove <project>` leaves an aside silently when a hand-written `AGENTS.md` sits there (`:964`): not deleted, so out of the criterion; noted, not planned.
- `docs/installation.md` is read by a person, not by an agent: under the owner's three cases it is a case 3 with no natural `po-eval` arm.

## Complexity
Story 3 → 3. One code file, four small mechanisms sharing one trap, docs and one ADR; the cost is in failure-injection tests, not in the code.

## Split
—
