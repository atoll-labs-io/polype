# Stories review: Polype, milestone "M15 — Les suites de M14" (s139, s140, s141)


A one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). Done on 2026-10-16 by the `stories-reviewer` subagent, in a context that did not write the stories. The answers are recorded verbatim.

- **Scope source:** the milestone's Objectif paragraph, plus issues #107, #108, #110, #111 and #112, with the owner decisions of 2026-10-15 and 2026-10-16.
- **Platform:** `cli`.

## Loop 1

Review status: complete

**What I read** (paths are relative to the framing copy): `docs/stories.md` (the M15 section, 2177-2233, and the `Owns` lines of M13 and M14); `docs/reviews/stories-m14.md`; all of `bin/polype`; `method/hooks/po-session.sh:220-263`; in `method/hooks/po-gate.sh` the header, `ship_allowed` and the dispatch (474-482); all of `method/templates/review.md`; `method/commands/po-ship.md` Step 3 (83-102); the lines of `po-review.md`, `po-drive.md`, `po-flow.md` and `po-orchestrator.md` that record a review; the lines of `method/agents/reviewer.md` that mention findings; ADR-0090 and ADR-0092 (the highest, so 0093 and 0094 are free); all of `tests/drop-keeps-modified.test.sh` and `tests/update-keeps-mode.test.sh`; `tests/everything-in-issues.test.sh:126-200`; `docs/reviews/s137-…` and `s138-…`, the findings sections; `docs/installation.md:306-324`; searches of `tests/` for phrases that pin `docs/installation.md`, the review template, `reviewer.md`, `po-ship`, `po-review`, `po-drive` and the `remove --global` output; a search of `docs/reviews/` for what real reviews write under `## Findings` when they have nothing to report.

**Code claims of the Objectif, checked:** `shipped_pairs` is at `bin/polype:137` and lists every file under `$base/method` through `find` (`:143`), so a copy kept under `polype/method/` is shipped again from the payload (#111, as reproduced in `docs/reviews/s137-…:70-74`); `drop_laid_file` (`:238-254`) keeps a modified copy in place; the `## Findings` placeholder at `method/templates/review.md:55` has no list marker; `/po-ship` 3.2 (`po-ship.md:86-87`) only opens list items, and its "not filed: shape not recognised" fallback does not catch a `### F1: major.` heading, since the line opens with `###`; the comment at `po-session.sh:241-242` says "advise" twice.

### Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| A modified file of the global payload that Polype no longer ships leaves the payload for `~/.claude/polype.kept/` | Objectif, #111 | s139 (`payload_copy_moves_out`, `moved_copy_is_not_shipped`) | yes |
| The kept copy disappears once a version ships an identical file at the same path | Objectif, #111 | s139 (`kept_copy_removed_once_shipped`) | yes |
| #111: no kept payload copy comes back as live method on the next run from the payload | #111 | s139 (`moved_copy_is_not_shipped`) | yes |
| #110: `test_update_ghost_keeps_a_modified_copy` also checks `.polype/checksums` | #110 | s139 (`update_test_checks_all_state`) | yes |
| #107: a test separates the recorded-mode branch from the inferred-mode branch (inflated init project) | #107 | s140 (`session_hint_trusts_recorded_mode`) | yes (line number: minor 3) |
| #108: the po-session comment no longer says "advise" twice, and its `.` no longer reads like a sentence end | #108 | s140 (`session_comment_reads_once`) | yes (half the criterion cannot be tested: major 3) |
| A review follows a fill-in template aligned with `/po-ship` | Objectif, #112 owner decision | s141 (`template_shows_the_line`) | yes (but see major 1) |
| The shape is checked as soon as the review is recorded, and the reviewer is asked again | Objectif, #112 owner decision | s141 (`gate_checks_findings_shape`, `recording_runs_the_check`) | yes (`/po-flow` and `/po-orchestrator`: minor 4) |
| #112: a malformed review that reaches the ship is never ignored silently | #112 | s141 (`ship_net_catches_headings`) | yes (but see major 2) |

### Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| #111: delete the edit and report it; keep the copy until the person deletes it; extend the `polype/` exemption of `cmd_remove` (options turned down) | Objectif, `adr_records_the_kept_payload`, s137 review F1 | none: they appear only as options turned down | no |
| #112: template alone; a refusal at ship through `po-gate ship-allowed` (options turned down) | `adr_records_the_shape_check` | none | no |
| Rewriting reviews already recorded | s141 Notes | none | no |

### Checks
- [x] **Exclusions:** no option turned down comes back.
- [x] **No technical layer dressed as a story:** s139 and s141 can be tried from the command line (`polype … --global`, `po-gate findings-shape`); s140 has nothing to try, and its `Surface: —` says so.
- [ ] **Criteria:** majors 1, 2 and 3 are not settled by their wording. s139 has 7 criteria, at the limit; s140 has 2 and s141 has 5.
- [x] **Dependency order:** s139 → s137, s140 → s138, s141 → s134 (`docs/stories.md:2090`); each exists and comes earlier.
- [x] **Complexity:** 3, 1 and 3.
- [x] **Ids:** s139, s140 and s141 are unique, well formed and follow s138.
- [ ] **Owns:** see critical 1. Every other pair is disjoint; overlaps with older stories stay inside each `Depends on` chain (s139–s137 on `bin/polype`, `docs/installation.md`, `ADR-0092-*`, `tests/drop-keeps-modified.test.sh`; s141–s134 on `po-ship.md` and `po-drive.md`; s140–s138 on `tests/update-keeps-mode.test.sh`). No existing test outside s139's `Owns` checks for a kept copy under `polype/`; `global-install.test.sh:94-100` only requires that `$H/polype` is gone.
- [x] **Surface:** `command` (s139, s141) admitted by `cli`; `—` (s140) admitted everywhere.
- [x] **Owned records:** the `Corrige` lines name GitHub issues; s139 says its ADR supersedes ADR-0092 in part and owns `ADR-0092-*`; s141's ADR does not overrule ADR-0090, whose line 26 already sends to the person any line naming a severity outside the expected shape.

### Findings
- **critical — s139 × s141 — `Owns`: `docs/decisions/ADR-0093-*` against `docs/decisions/ADR-0094-*` (check 8).** Both entries are equal up to their third segment, and both third segments hold `*`; the rule of check 8 counts that as overlapping. s139 and s141 have no dependency between them. No file can match both, but `/po-drive` decides sharing by this same rule. Fix: name the exact ADR file in each `Owns`, or make one story depend on the other.
- **major — s141 — `gate_checks_findings_shape`: the lines it accepts and the lines it refuses do not line up, and "cette forme" is open.** A line with no severity (`None.`, written in `s47:68`, `s54:72`, `s84:68`, `s122:222`) or a plain sentence is left undecided. Whether `<chemin>:<ligne>` is checked is unclear; if it is, the "well formed" s138 review fails (`s138:55`), and so does `s134:74` (`- minor — ADR-0090 option D — …`). The criterion does not say whether the shapes `/po-ship` accepts (`- **major** —`, `1. **minor**:`, `* minor:`) pass.
- **major — s141 — `ship_net_catches_headings` against `po-ship.md:87`.** Read literally, "une ligne qui contient une sévérité sans l'ouvrir" catches the sentence Step 3.2 explicitly leaves alone ("No critical or major finding."), which reviews write regularly (`s67:60`, `s71:81`, `s112:75`, `s124:55`). The criterion should say whether that exemption goes; the gate should match. The net's sentence is pinned outside `Owns` by `tests/everything-in-issues.test.sh:184`.
- **major — s140 — `session_comment_reads_once`: half of it cannot be tested.** "Ne coupe pas sa phrase sur le `.` de `polype init .`" names no visible form; the criterion should name it, for example the command in backticks.
- **minor — s139 — Notes, order of the checks.** `refuse_collisions` runs before `load_checksums` in `cmd_install` (`bin/polype:599-600`) and `cmd_update` (`:640-641`); deciding whether `polype.kept/<chemin>` is taken needs `RECORDED`. `existing_kept_copy_never_overwritten` does not say what happens when the existing kept copy has the same content.
- **minor — s139 — `remove_leaves_kept_copies` and a payload file that is still shipped.** A modified payload file is still deleted by `remove --global` (`bin/polype:754-756`), yet the new ADR rejects deletion because the payload is not in git; the story should say why `remove` differs. "Le dit en une ligne" gives no text to pin.
- **minor — s140 — line number.** The condition `[ "$recorded" = init ]` is at `po-session.sh:245`; line 244 sets `recorded`.
- **minor — s141 — `recording_runs_the_check`: who records, and how.** `/po-flow` (`po-flow.md:89`) and `/po-orchestrator` (`po-orchestrator.md:70`) also record reviews; the story should say whether they inherit the check. Unstated: whether the second answer replaces or follows the malformed block; what the gate does without `## Findings`.
- **minor — s141 — Notes, tests outside `Owns` that pin the six files:** `tests/hooks-installer-docs-cleanup.test.sh:57`, `tests/review.test.sh:23` and `:46`, `tests/review-lenses.test.sh:85-86`, `tests/everything-in-issues.test.sh:130` and `:181-184`, `tests/final-leftovers.test.sh:7`, `tests/fleet-wiring.test.sh:68`, `tests/qa-fleet.test.sh:110-121`, `tests/resume.test.sh`.
- **minor — s139 — Notes, tests that pin `docs/installation.md`:** besides the two named, `tests/installer.test.sh:175`, `tests/local-copy-checksums.test.sh:156`, `tests/global-install.test.sh:119`, `tests/readme-onboarding.test.sh:143`, `tests/post-m7-texts.test.sh:5`.

### Not verified
- The text of issues #107, #108, #110, #111 and #112: taken from the caller's message.
- Whether the suite stays green and the s140 test bites: no shell.
- How `/po-drive` computes overlaps in practice: the written rule of check 8 was applied.
- Whether ADR-0094 supersedes ADR-0090 in part: judged not.
- `po-review.md` (except 36), `po-drive.md` (except 133-142), `reviewer.md`, `docs/installation.md` outside 306-324 and the matched lines.
- A still-shipped modified payload file laid onto `commands/` by a run from the payload: outside #111's scope.
- macOS bash.

Max severity: critical
Stories ready: no

## Loop 2

Review status: complete

**What I read:** the revised M15 section of `docs/stories.md` (2177-2233); against it, the fixture reviews `docs/reviews/s137-modified-copy-survives-drop.md:63-88` and `docs/reviews/s138-mode-hint-cleanup.md:54-56`, `method/hooks/po-session.sh:241-245`, `bin/polype` in `cmd_remove:741-779` (`load_checksums` at `:744`) and `:599-600`, `:640-641`, `tests/drop-keeps-modified.test.sh:112-129`, `docs/installation.md:321-324`, the Bad consequences of ADR-0092.

**How each Loop 1 finding was answered:** critical 1 fixed (both stories name their ADR file in full; the pairs are disjoint). Major 1 fixed (three refused cases and a missing section; location not checked; `None.` and the `/po-ship` shapes pass; s137 fails on `### F1: major.`, s138 passes). Major 2 fixed (headings only; the "No critical or major finding." exception and the net's words stay, so `tests/everything-in-issues.test.sh:184` holds). Major 3 fixed (backtick form named; see minor 3). Minors 1 to 6 answered.

### Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| A modified payload file that Polype no longer ships leaves the payload for `~/.claude/polype.kept/` | Objectif, #111 | s139 (`payload_copy_moves_out`, `moved_copy_is_not_shipped`; `remove_leaves_kept_copies` extends it to `remove --global`) | yes |
| The kept copy disappears once a version ships an identical file at the same path | Objectif, #111 | s139 (`kept_copy_removed_once_shipped`, `existing_kept_copy_never_overwritten` for the same-content case) | yes |
| #111: no kept copy comes back as live method on a run from the payload | #111 | s139 (`moved_copy_is_not_shipped`) | yes |
| #110: the update test also checks `.polype/checksums` | #110 | s139 (`update_test_checks_all_state`) | yes |
| #107: a test separates the recorded branch from the inferred branch | #107 | s140 (`session_hint_trusts_recorded_mode`, `:245`) | yes |
| #108: the comment says "advise" once, and its `.` no longer reads like a sentence end | #108 | s140 (`session_comment_reads_once`) | yes (see minor 3) |
| A fill-in review template aligned with `/po-ship` | Objectif, #112 | s141 (`template_shows_the_line`) | yes |
| The shape is checked at recording, and the reviewer is asked again | Objectif, #112 | s141 (`gate_checks_findings_shape`, `recording_runs_the_check`) | yes |
| A malformed review that reaches the ship is never ignored silently | #112 | s141 (`ship_net_catches_headings`) | yes |

### Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| #111: delete the edit and report it; keep the copy until the person deletes it; extend the `polype/` exemption of `cmd_remove` | Objectif, `adr_records_the_kept_payload`, s137 review F1 | none; the new `remove --global` moves files out, the opposite of that exemption | no |
| #112: the template alone; a refusal at ship through `ship-allowed` | `adr_records_the_shape_check` | none | no |
| Rewriting reviews already recorded | s141 Notes | none | no |

### Checks
- [x] Exclusions, no disguised layer, criteria (gaps under Findings; 7, 2 and 5 criteria), dependency order, complexity 3/1/3, ids, `Owns` now disjoint among the three stories, surfaces admitted by `cli`, owned records (s139 owns `ADR-0092-*`).

### Findings
- **minor — s139 — `adr_records_the_kept_payload` says "sur ce point seul", but there are now two.** With `remove_leaves_kept_copies`, ADR-0093 also overrules ADR-0092's Bad consequence "`remove --global` emporte la charge utile … même modifiée", written too at `docs/installation.md:321-324`, which no test pins. The criterion should name both points and say that the sentence at `:323-324` goes.
- **minor — s139 — `remove --global` against a copy already in `polype.kept/`.** `existing_kept_copy_never_overwritten` does not say whether `remove --global` stops too, nor how this mixes with the `held` path (`bin/polype:748-753`).
- **minor — s140 — `session_comment_reads_once`: is `advise` matched as a word or as text?** Line 242 reads "the advised command"; `grep -c advise` counts "advised" too. Say "the word `advise`" (`grep -w`), or forbid "advised" too.
- **minor — s141 — `gate_checks_findings_shape`: four points left to the implementer.** Whole word and case ("majority", `### Major refactor`); where the section ends (it must be the next `## ` heading, or a `###` line is never inside it); whether an indented sub-bullet naming a severity is an allowed continuation or a refused item (`/po-ship` has the same open point).
- **minor — s141 — `recording_runs_the_check`: the stop after a second failure is not written in any file.** If the last malformed block ends with `Review status: complete` and `Ship allowed: yes`, a driver that starts again sees a review `po-gate ship-allowed` accepts; the stop does not survive a restart (the `/po-ship` net would still bring the bad lines to the person).

### Not verified
- Whether the suite stays green and each mutation bites: no shell.
- The text of the issues: the caller's summary.
- The full prose of `po-review.md`, `po-drive.md`, `po-flow.md` and `po-orchestrator.md`: whether "as `/po-review` says" carries the check into `/po-flow` and `/po-orchestrator` without editing them.
- Whether moving still-shipped payload files out at `remove --global` breaks a test outside `Owns`: by search, `global-install.test.sh:94-100` and `install-collisions.test.sh:172-176` do not look at `polype.kept/`.
- macOS bash.

Max severity: minor
Stories ready: yes

> Answered at the next revision, 2026-10-16. Minor 1: `adr_records_the_kept_payload` names both points and says the sentence of `docs/installation.md:323-324` goes. Minor 2: `remove_leaves_kept_copies` stops on a kept copy already taken with other content, like `install` and `update`, and a modified file over a `.before-polype` goes to `polype.kept/` while the `.before-polype` comes back by the `held` path. Minor 3: the word `advise`, whole word (`grep -w`), once. Minor 4: a severity is a whole word, any case; the section runs to the next `## ` heading; an indented sub-bullet is a continuation line. Minor 5: on a second failure the lead appends a blocked report (`Review status: blocked`, `Next action:` naming the person, `Max severity: critical`, `Ship allowed: no`), so the stop survives a restart. Not verified: the five issues were read through `octo` on 2026-10-15 and 2026-10-16; `/po-flow` and `/po-orchestrator` record "as `/po-review` says", left to the planner of s141 to confirm. Stories ready: yes.
