# Stories review: Polype, milestone "M14 — L'installeur ne perd rien de ce que la personne a modifié" (s137, s138)


A one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). Done on 2026-10-14 by the `stories-reviewer` subagent, in a context that did not write the stories. The answer is recorded verbatim.

- **Scope source:** the milestone's Objectif paragraph and the done-criteria of issues #89, #95, #96 and #102 (owner decisions of 2026-10-14); #97 closed by the owner without a story.
- **Platform:** `cli`.

## Loop 1

Review status: complete

What I read: `docs/stories.md` (M13 and M14) and `docs/reviews/stories-m13.md`; all of `bin/polype`; `method/hooks/po-session.sh:225-259`; all of `tests/update-keeps-mode.test.sh`; in `tests/installer.test.sh` the ghost, modified-file and remove tests; in `tests/install-collisions.test.sh` the ghost and set-aside/remove tests; `docs/installation.md:350-374`, plus a search of the file for `remove` and `modifi`; a search of `README.md` for remove/delete wording; ADR-0088, the lines that mention `remove`; the ADR numbering (the highest is ADR-0091, so ADR-0092 is free); the count of `method/templates/` + `method/hooks/` (18 + 5 = 23, so the "23 fichiers" claim holds).

Code claims of the Objectif, checked: `drop_laid_file` is at `bin/polype:236` and runs `rm -f` without comparing any sum (line 238); it is called from `cmd_install:598` (its read loop starts at 597), from the ghosts of `update:639` and from `cmd_remove:742`; `has_drifted` is at `:560`; `cmd_install` (586-618) does not call `load_checksums`; the global branch of `cmd_remove` is at `:733-741`; the stale header at `bin/polype:15-19` reads "Three sit next to each other … A project has a fourth"; the stale comment at `po-session.sh:241` reads "update on an init project would lay the commands"; `tests/update-keeps-mode.test.sh:100-101` and `:121-122` hold the same `printf`.

### Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| No installer command deletes a copy the person modified | Objectif | s137 (`init_keeps_a_modified_copy`, `update_ghost_keeps_a_modified_copy`, `remove_keeps_a_modified_copy`), with the protection placed in `drop_laid_file`, the only deletion point | yes (global `remove` of the payload: see minor 4) |
| Close the minor findings left by s135 and s136 | Objectif | s137 (#96), s138 (#95, #102) | yes |
| #89: a dropped copy whose sum differs from the recorded one is kept and reported, as `update` does for a modified copy | issue #89 | s137 (`init_keeps_a_modified_copy`, `update_ghost_keeps_a_modified_copy`: line `polype: modified, kept: <chemin>`) | yes |
| #89: a test covers full install → init with a modified copy | issue #89 | s137 (`init_keeps_a_modified_copy`, `tests/drop-keeps-modified.test.sh`) | yes |
| #89 owner choice: kept in place, becomes the person's file, `remove` included | issue #89, Objectif | s137 (`kept_copy_becomes_the_persons`, `remove_keeps_a_modified_copy`, `adr_records_the_choice`) | yes |
| #96: the `bin/polype` header counts `.polype/mode` | issue #96 | s137 (`header_lists_the_mode_file`) | yes |
| #95: the `po-session.sh:241` comment gives the real reason (`polype init .` is advised and repairs) | issue #95 | s138 (`session_comment_says_why`) | yes |
| #102: one helper writes the `AGENTS.local.md` of the two tests | issue #102 | s138 (`absorbed_settings_helper`) | yes (but see major 1) |

### Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| #97 (wording gap), closed without a story | Objectif, owner decision | none | no |
| Setting a modified copy aside under a new suffix, or stopping the command (options turned down) | #89 owner choice | none: they are only listed as rejected options in `adr_records_the_choice` | no |

### Checks
- [x] **Exclusions:** no story revives #97 or a rejected option.
- [x] **No technical layer dressed as a story:** both stories can be tried from the command line. s138 has nothing to try, which is a Surface question (minor 6), not a layer.
- [x] **Criteria:** every criterion names an input, an action and what is seen, except major 1 and minor 5. s137 has 7 criteria, which is at the limit. s138 has 2.
- [x] **Dependency order:** both depend on `s136-session-hint-infers-init`, which exists and comes earlier in the file.
- [x] **Complexity:** s137 is 3, s138 is 1. There is no 4 or 5 to examine.
- [x] **Ids:** `s137-modified-copy-survives-drop` and `s138-mode-hint-cleanup` are unique, well formed and follow s136.
- [x] **Owns (s137 against s138):** every pair is disjoint; the two stories can run in parallel. Overlaps with older stories are all inside each story's `Depends on` chain (s137 meets s135 on `bin/polype` and `docs/installation.md`; s138 meets s136 on `tests/update-keeps-mode.test.sh`). No existing test outside s137's `Owns` breaks when modified copies are protected: the ghost tests (`installer.test.sh:58`, `install-collisions.test.sh:90`) and the remove tests use copies that are unmodified or have no recorded sum. No test quotes the header lines or the `## Ce que remove garde` sentences.
- [x] **Surface:** `command` is admitted by `cli` for both stories (see minor 6 for s138).
- [ ] **Owned records:** the `Corrige` lines name GitHub issues (`Issue tracker: github`), so no file is due in `Owns`. Superseded ADR: see major 2.

### Findings
- **major — s138 — `absorbed_settings_helper` (criterion that no test can satisfy).** The criterion asks that both tests "échouent toujours quand la branche de déduction de `po-session` est désactivée". `test_hints_say_init` keeps `.polype/mode` (= `init`), so `po-session.sh:244` takes `[ "$recorded" = init ]` and never reaches the inference branch. Disabling that branch cannot make this test fail. Only `test_session_hint_infers_init_without_mode` holds the mutation. The criterion should say so, and say that `test_hints_say_init` keeps checking the recorded-mode path.
- **major — s137 — `modified_copy_over_a_set_aside_file` against ADR-0088 (check 10 ii).** ADR-0088 says: "`remove`, et `update` quand il retire un fichier qui n'est plus livré, remettent ce fichier en place". The new criterion leaves the `.before-polype` where it is when the copy is modified. So ADR-0092 overrules part of an accepted ADR. The story does not say that ADR-0092 supersedes ADR-0088 in part, and does not own `docs/decisions/ADR-0088-*`, whose `superseded-by` line would change.
- **minor — s137 — Notes, `load_checksums`.** `cmd_remove` (729-763) does not call `load_checksums` either, and it deletes the sum files at 745-746. Without the call, `has_drifted` finds no `RECORDED` entry and the protection silently does nothing in `remove`.
- **minor — s137 — global `remove` and the payload.** A modified payload file under `~/.claude/polype/` that has no `.before-polype` reaches `drop_laid_file` at `:742`. It would be kept and reported "kept", and then `rm -rf "$state_dir"` at `:748` deletes it. The report line would lie. The story should say what global `remove` does with a modified payload file, and `docs/installation.md:356` should then match.
- **minor — s137 — modified copies with no recorded sum.** Since ADR-0087, the sums of the `.claude/` copies live only in the uncommitted `.claude/.polype-checksums`. On a fresh clone a hand-modified committed `.claude/` copy has no recorded sum, and `init` still deletes it without a word. Git keeps the file, and the Notes state the rule, but nothing says why this is acceptable; the ADR should name it.
- **minor — s138 — `session_comment_says_why` against the project convention.** `AGENTS.local.md` says that an acceptance criterion's name is the name of its test function. The criterion can be checked by a grep. Either make it a test, or say why this is an exception to the convention.
- **minor — s138 — Surface.** The story changes a comment and a test helper; a person runs nothing new. `—` describes it better than `command`.

### Not verified
- The text of issues #89, #95, #96, #97 and #102: taken from the caller's message, not from the tracker.
- That the test suite stays green after s137: no shell.
- That `test_session_hint_infers_init_without_mode` fails under the mutation after the helper refactor: the execute or review stage repeats it.
- Whether ADR-0087 or ADR-0091 also state that dropped copies are deleted.
- Whether s137 renames `recorded_mode`, which s138's new comment refers to.
- `docs/installation.md` outside lines 350-374 and the lines the search matched.

Max severity: major
Stories ready: yes

> Answered at the next revision, 2026-10-14. Major 1: `absorbed_settings_helper` now asks only `test_session_hint_infers_init_without_mode` to fail under the mutation, and `test_hints_say_init` to keep the recorded-mode path. Major 2: `modified_copy_over_a_set_aside_file` says ADR-0092 supersedes ADR-0088 in part on that one case, and `docs/decisions/ADR-0088-*` joins s137's `Owns` for its `superseded-by` line only. Minor 3: the Notes name `cmd_remove` beside `cmd_install`. Minor 4: at a global `remove`, a payload file under `polype/` is never reported kept, since its directory goes whole; the ADR and `docs/installation.md` say so. Minor 5: `adr_records_the_choice` names the no-recorded-sum limit and why it is acceptable (git keeps the edit on a fresh clone). Minor 6: `session_comment_says_why` is checked by a test that reads the comment; s138's `Surface` is `—`. Not verified: the five issues were read through `octo` on 2026-10-14 (#89 is an issue, not a pull request); ADR-0087 and ADR-0091 say nothing of deleting dropped copies (checked by search); s137's Notes forbid renaming `recorded_mode`. Stories ready: yes.
