# Review — s161-installer-leftovers

[Story](../stories.md) · [Plan](../plans/s161-installer-leftovers.md) · [Verification](../verif/s161-installer-leftovers.md)

Review status: complete
Fix loop: 0
Reviewed tree: 67c4b12996b380df5c406fde5395eaf4ab54df98
Lenses run: none (the diff touches no auth, migration, lockfile or server-side path, and none of their content triggers)

## Scope
`git diff --name-only main...story/s161-installer-leftovers` lists 9 paths. These are inside `Owns` (`docs/stories.md:2541`): `bin/polype`, `docs/installation.md`, `method/AGENTS.md` and `tests/installer-leftovers.oracle.test.sh`. These are in scope by construction: the research, the plan and the verif record of this story, plus `docs/decisions/ADR-0112-…` (added, status `A`, and the plan names it). One path is outside `Owns`: `docs/decisions/ADR-0095-…`, which only changes its frontmatter line to `superseded-by: [ADR-0112]` (see the findings). No other running lane overlaps: `story/s162-defects-seen-on-products` touches none of these paths. `.claude/` and `.polype/` are untouched, and no existing test file changed.

## Evidence relied on
- `po-gate verif-current s161-installer-leftovers` exits 0. Under `Verification mode: record`, `docs/verif/s161-installer-leftovers.md` is complete, and its last `Unit suite` run (`bash tests/run.sh`) exited 0 on this code. I did not rerun the full suite. `Typecheck: —`: the project has none.
- The oracle checksum is unchanged (`3010334706 5377`, as in the plan), and `## Oracle changes` is empty. All 5 oracle tests pass on this branch.
- `po-gate floor-guard s161-installer-leftovers main` exits 0: no check was made easier to pass.
- Word rule of M20: `## Installed files` went from 516 to 505 words, and the whole of `method/AGENTS.md` from 3754 to 3743.
- The story does not go to QA (`QA stage: —`).

## Bite proof (each mutation undone, `git diff --exit-code bin/polype` clean afterwards)
| Mutation | Tests run | Failed |
| --- | --- | --- |
| Removed the `*/*) return 1` branch from `is_payload_state_file` | oracle + `payload-refuses-foreign-files` | 1 (`state_pattern_stays_at_the_top`) |
| Removed `trap report_the_stop EXIT` | oracle + `payload-kept-outside` + `install-collisions` | 2 (`failed_remove_names_held_files`, `interrupted_run_leaves_a_named_trace`) |
| Made the aside a source whenever it is a file (the old rule) | oracle + `install-collisions` + `install` | 1 (`orphan_before_polype_is_reported`) |
| Dropped the "nothing already at the target" guard of the trap's put-back | oracle + `payload-kept-outside` + `install-collisions` | **0** |

## Findings
- **major** — The kept orphan `AGENTS.md.before-polype` is kept for one run only.
  - At `bin/polype:510-517` the orphan is kept and named. Then the same run's `assemble_agents_md` lays down Polype's `AGENTS.md`, which carries the marker.
  - On the next `update`, the aside counts as the waiting copy of ADR-0088: it is absorbed into `AGENTS.local.md` and deleted.
  - I reproduced this in a scratch HOME and project. First run: `kept as it is: … move its notes into AGENTS.local.md or delete it`. Second run: `AGENTS.md.before-polype moved into AGENTS.local.md …, then deleted`.
  - So `docs/installation.md` ("il n'est ni absorbé ni supprimé") and ADR-0112 describe a lasting state the code does not keep.
  - A person who follows the message, moves the notes by hand and then reruns gets them twice in `AGENTS.local.md`.
  - Nothing is lost silently, and the criterion as worded is met. The plan's pivot accepted this one-shot behaviour, but neither the doc nor the message tells the person about it.
- **minor** — The rule that the trap never overwrites a file is not tested.
  - In `report_the_stop` (`bin/polype:83`) the guard `[ ! -e "$target" ] && [ ! -L "$target" ]` protects a person's file. Removing it fails no test (last row of the table above).
  - The plan listed this guard as a way the change could be wrong and left its test optional. The verif record lists it under "Not proven here" as checked by hand.
  - A regression here would silently overwrite a file at `<path>.before-polype` or `<path>`.
- **minor** — `docs/installation.md` (new paragraph "Deux arrêts gardent la copie dans la charge utile (ADR-0112)") credits the two kept-copy stops to ADR-0112.
  - Those stops came from s146 (`bin/polype:412`, `:442`). ADR-0112 says nothing about kept copies.
  - The plan's "Each new rule cites ADR-0112" caused this. The paragraph documents existing stops and is not a new rule.
- **minor** — `docs/decisions/ADR-0095-la-charge-utile-se-signe-et-n-accueille-aucun-fichier-etranger.md` is outside `Owns`.
  - `Owns`: `` `bin/polype`, `docs/installation.md`, `method/AGENTS.md`, `tests/installer-leftovers.oracle.test.sh`, `tests/installer-leftovers.test.sh` ``.
  - The change is the `superseded-by` link that AGENTS.md Law 6 allows on a superseded ADR ("only its frontmatter links, `supersedes` and `superseded-by`, ever change"), and the plan names it. This is a gap in the story's `Owns`, not a breach by the implementer.

## Plan conformity
- All 7 tasks are present and ticked. Task 5's sentence is in `## Installed files`, and that section got shorter.
- Task 6 covers each point it lists in French, and the two stop messages it quotes match `bin/polype:412` and `:442` word for word.
- The only caller of `is_payload_state_file` is `bin/polype:370`. Every state file the installer writes into the global payload sits at its root, so the depth rule breaks no current writer.
- Exit codes are unchanged: the trap returns at once on 0 and never calls `exit`.
- Read, not tested (case 3 of the plan): the `## Installed files` sentence and the new text of `docs/installation.md`. Both are faithful to the code, apart from the major and the attribution minor above.
- The sentence in `method/AGENTS.md` is a candidate for a `po-eval` control arm (#208).

## Not verified
- I did not run the full unit suite myself; I relied on the verif record, whose tree matches.
- The trap's "still held in" branch: I did not inject a failing put-back. The implementer says it checked this by hand, and no test covers it.
- An exit by signal (`kill -9`) skips the trap, as ADR-0112 accepts. `.polype-restore.<pid>` may then stay unnamed, and nothing covers that case.
- A `remove --global` that fails after the payload is gone but before the success-path put-back has finished. I checked it by reading only (the target becomes `<path>`), never by running it.
- Nothing ran against a real `~/.claude`. Every probe used a scratch HOME under `/tmp/tmp.jbWDNgcbHG`.
- To cover these, a person can run `remove --global` in a scratch HOME with a `mv` shim that also refuses the put-back, and check that the "still held" line appears and that the file stays in `.polype-restore.<pid>`.

Max severity: major
Ship allowed: yes
