# Stories review: Polype, milestone "M13 — La mise à jour garde le mode d'activation" (s135)


A one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). Done on 2026-10-14 by the `stories-reviewer` subagent, in a context that did not write the story. The answer is recorded verbatim.

- **Scope source:** the milestone's Objectif paragraph and the done-criteria of issue #73 (owner decision of 2026-10-14).
- **Platform:** `cli`.

## Loop 1

Review status: complete

What I read: `docs/stories.md` (M11, M12 and M13); `docs/reviews/stories-m11.md` and `docs/reviews/stories-m12.md`; `bin/polype` (all of it); `method/hooks/po-session.sh:241-248`; `method/commands/po-setup.md`; `method/AGENTS.md`; ADR-0004 and ADR-0087; the ADR numbering (the highest is 0090, so 0091 is free); `README.md:80-116`; `docs/installation.md:180-220`, plus a search of the file for `init` and `update`; the tests that quote `polype update .` or check `.polype/` state files.

### Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| A project activated by `polype init` stays an init project at every `polype update` | Objectif | s135 (`init_then_update_stays_init`, `mode_is_recorded`, `mode_inferred_without_state`) | yes |
| A project already inflated by the defect can go back to its project files only | Objectif | s135 (`init_shrinks_a_full_install`) | yes |
| Finding: only `init` sets `mode=init` (`bin/polype:754`), and no state file records the mode | Objectif | s135 (`mode_is_recorded`, `adr_records_the_mode`) | yes (checked: `bin/polype:39,110-115,754`; `.polype/` holds only `manifest`, `checksums`, `version`) |
| Finding: the pecten and nautile manifests list 65 files, 20 of them commands | Objectif | s135 provides the mechanism (`init_shrinks_a_full_install`); the repair itself is out of scope by owner decision (Notes) | yes |
| #73 done-criterion: `update` respects the activation mode, an init project stays at 23 files | issue #73 | s135 (`init_then_update_stays_init`) | yes (23 = 18 files in `method/templates/` + 5 in `method/hooks/`, checked) |
| #73 done-criterion: the po-session hint and `/po-setup` step 3 are corrected, with their tests updated | issue #73 | s135 (`hints_say_init`); `tests/no-claude-md.test.sh` and `tests/claude-md-setting.test.sh` are in `Owns` | yes |
| #73 done-criterion: a non-regression test runs init then update | issue #73 | s135 (`init_then_update_stays_init`, `tests/update-keeps-mode.test.sh`) | yes |

### Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| Protecting a hand-modified copy that `drop_laid_file` deletes (issue #89) | Notes, owner decision | none | no |
| Repairing pecten and nautile (done after the ship, by a PR in each repository) | Notes, owner decision | none | no |

### Checks
- [x] Exclusions: no story revives an excluded item under any name. `init_shrinks_a_full_install` goes through the existing ghost removal and does not touch the protection for hand-modified copies (#89).
- [x] No technical layer dressed as a story. The `command` surface can be tried: `polype init`, then `polype update`, then count the files.
- [x] Every criterion can be checked by one test, except the minor gap about `check` below. There are 6 criteria.
- [x] Dependency order: `s134-everything-to-handle-is-an-issue` exists and comes earlier in the file.
- [x] Complexity: 2. There is no 4 or 5 to examine (but see the minor finding).
- [x] Ids: `s135-update-keeps-init-mode` is unique and follows s134.
- [x] Owns: declared. It overlaps s130, s131, s132 and s134, all in s135's `Depends on` chain (s134 → s133 → s132 → s131 → s130), so these overlaps are allowed. Older stories that own `bin/polype` or `docs/installation.md` come from shipped milestones; they are not flagged, as in the M11 and M12 reviews.
- [x] Surface: `command` is admitted on `cli`.
- [x] Owned records: `Corrige` names issue #73 on GitHub (`Issue tracker: github`). That record is not a file in the repository, so no `Owns` entry is due. No ADR is superseded. ADR-0087 only describes the state files ("quatre fichiers") and is not overruled by a new one.

### Findings
- minor — s135 — `hints_say_init` and `Owns`: after this fix, `README.md:114-115` and `docs/installation.md:211` give a reason that becomes false ("`update` y poserait aussi les commandes"). `README.md` and its pinning test `tests/readme-onboarding.test.sh:94` are not in `Owns`, and no criterion asks to fix the clause.
- minor — s135 — `mode_is_recorded`: "que `update` et `check` lisent" gives `check` nothing observable to do with the mode; `cmd_check` only reads the manifest and the sums (`bin/polype:662-693`).
- minor — s135 — `hints_say_init` and `mode_inferred_without_state`: (1) nothing says how `po-session` and `/po-setup` learn the mode when the state file is missing; (2) the installer's own hints, `absorb_agents_md` (`bin/polype:257-258`) and `handle_claude_md` (`bin/polype:415-416`), switch on `$mode = init`, and no criterion checks they say `polype init .` on an `update` of an init project.
- minor — s135 — Notes: they do not list the tests outside `Owns` that pin `docs/installation.md`: `tests/installer.test.sh:179`, `tests/docs-and-eval-cleanup.test.sh`, `tests/hooks-installer-docs-cleanup.test.sh` (100-character prose lines), `tests/readme-onboarding.test.sh`.
- minor — s135 — Complexity 2 looks low next to s130 (3); with `Light up to: 2`, it routes the execution to the light model.

### Not verified
- **The pecten and nautile manifests (65 files, 20 commands).** Other repositories, taken from the Objectif.
- **That #73 is an issue and not a pull request.** A person should confirm that `Corrige : issue #73` names the right item.
- **Whether a test outside `Owns` breaks once `.polype/` holds a fifth state file.** Nothing found that lists `.polype/` exactly; the suite was not run.
- **An inflated project with no state file running `polype update .` before its repair** records the full install; only `init` brings it back, the limit the ADR criterion names.
- **Ship status of stories older than M11 that own `bin/polype` or `docs/installation.md`.** Inferred from the git log, as in the M11 and M12 reviews.

Max severity: minor
Stories ready: yes

> Answered at the next revision, 2026-10-14. Minor 1: `README.md`, `tests/readme-onboarding.test.sh` and `tests/installer.test.sh` join `Owns`; `hints_say_init` now has both texts say that `update` keeps the mode, `polype init .` staying the advised command and the repair. Minor 2: `check` is dropped from `mode_is_recorded`. Minor 3: `po-session` applies the same inference rule; `update` sets `$mode` from the recorded mode, so the installer's own hints say `polype init .`, held by a test (`mode_inferred_without_state`). `/po-setup` runs before or right after the install, so it names the command per mode without reading state. Minor 4: the Notes list the pinning tests outside `Owns`. Minor 5: complexity raised to 3. Verified: #73 is an issue (read through `octo` on 2026-10-14), not a pull request. Stories ready: yes.

## s136-session-hint-infers-init (added 2026-10-14)

A one-off review of the story added to M13 from issue #94 (major finding of the s135 review), turned into a story by the owner. Same reviewer, fresh context; scope source: issue #94.

Review status: complete

### Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| A po-session case on an init project with `.polype/mode` removed, failing when the inference branch at `po-session.sh:244-245` is disabled (mutation d) | issue #94 | s136 (`session_hint_infers_init_without_mode`) | yes |
| The rule of `mode_inferred_without_state` ("po-session applique la même règle"), both outcomes | issue #94, quoting s135 | s136 (full install without mode → `polype update .`) | yes |

### Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| Stale comments (#95, #96) and the wording gap (#97) | story notes | none | no |

### Checks
- [x] Exclusions, no disguised layer, one testable criterion with input, action and exact output, dependency on s135, complexity 1, id unique, `Owns` overlaps only s135 (its dependency), surface `command` admitted by `cli`, `Corrige` names GitHub issue #94.

### Findings
none

### Not verified
- That the new test fails under mutation (d): no shell; the execute or review stage repeats it.
- That an uncommitted deletion of `.polype/mode` changes nothing: the hook reads the file tree, not git (`po-session.sh:243-245`).

Max severity: none
Stories ready: yes
