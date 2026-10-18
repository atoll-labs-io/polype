# Stories review: Polype, milestone "M16 — La charge utile ne relivre rien, la forme de revue se tient partout" (s142–s146)


A one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). Done on 2026-10-17 and 2026-10-18 by the `stories-reviewer` subagent, in a context that did not write the stories, over three loops. The findings and verdicts are recorded verbatim; the reading lists and coverage tables are kept short.

- **Scope source:** the milestone's Objectif paragraph, plus issues #115, #118 to #121, #123 and #125 to #127, with the owner decisions of 2026-10-17 and 2026-10-18. The issue texts come from the findings of `docs/reviews/s139-payload-kept-outside.md` and `docs/reviews/s141-review-findings-shape.md`.
- **Platform:** `cli`.

## Loop 1

Review status: complete

**What I read:** the M16 section (then four stories, s142–s145); `docs/reviews/stories-m15.md`; the findings of the s139 and s141 reviews; `bin/polype` (1-323, 600-859); `method/hooks/po-gate.sh` (header, `findings_shape` 85-117, dispatch 515-519); `po-ship.md` 84-93; `po-review.md` 36-47; `po-orchestrator.md` 60-86; `po-flow.md` 86-91; the `findings-shape` lines of `po-drive.md`; ADR-0088, ADR-0093, ADR-0094; `docs/installation.md` 160-181; tests `install-collisions.test.sh:160-184`, `payload-kept-outside.test.sh:120-180`, `global-install.test.sh:85-222`, `drop-keeps-modified.test.sh:120-135`, `drive.test.sh:149-153`; searches of `tests/`.

**Code claims of the Objectif, checked:** `drop_laid_file` puts a `.before-polype` back at the payload path (`bin/polype:301-303`), and a run from the payload lists it again (`:143`, `:112-113`) — #118. Run from the payload, `cmd_update` takes source and destination to be the same file, so `has_drifted && sum(dest) != sum(src)` (`:731`) is false and the edit is recorded as intact and laid onto the active copy (`:737-738`) — #115. `opens()` (`po-gate.sh:94`) accepts any non-word character after the severity, any case; `+ major — x` and `1) major — x` pass — #126. The gate exits 2 only on an unknown subcommand (`:519`), and `po-review.md:39` handles exit 1 alone — #127. `po-orchestrator.md:70` records "the way `/po-review` does", `:78` and `po-flow.md:90` send any other blocked review to a fix run — #123, #125.

### Findings
- **critical — s142 — `foreign_payload_file_stops_install`: the owner's rule is covered only where nothing gets shipped again.** The criterion catches a file "absent du manifeste et différent du fichier livré". A run from the payload never sees a foreign file: `src` is the very file at `$root/polype/…` (`bin/polype:112-113`, `:143`), so it never differs and `refuse_collisions` (`:201`) lets it through. A file at a path Polype does not ship has no "fichier livré" to compare with; the next run from the payload ships it. `old_set_aside_never_put_back_in_payload` is limited to paths "plus livrés"; a `.before-polype` at a still-shipped path stays under `polype/method/` and is laid to `commands/<x>.before-polype`. On a second machine after a dotfiles sync, the newer payload's new files are absent from that machine's manifest (`docs/installation.md:169-172`), so a literal "absent du manifeste" would stop the documented sync path; the rule must also leave out the state files under `polype/`. This is an incoherence between the 2026-10-17 decision and the ADR-0004 sync path.
- **major — s143 — the rule covers `update`, but the ADR states it for every run, and the sync path is not addressed.** `cmd_install` lays every shipped file unconditionally (`bin/polype:684-689`), so `install --global` from the payload still spreads an edit. "Comparer à la somme enregistrée" cannot tell an edit from a payload synced from another machine. `init <project>` from an edited payload spreads the edit into `.polype/` (`tests/global-install.test.sh:204-210`); the story does not say whether that is in scope.
- **major — s144 — `gate_accepts_only_ship_shapes` overrules ADR-0094 without an ADR.** ADR-0094 (line 30) sets "mot entier, **toute casse**" and three refused cases; s144 refuses `- Major — x`, `- MAJOR x`, `+ major — x`, `1) major — x` and narrows the separators. Fix: a new ADR that replaces ADR-0094 on this point, owned in full, or an argument for why ADR-0094 still holds.
- **minor — s142 — `adr_records_the_payload_rule`: "les `superseded-by` des ADR remplacées", plural.** Only ADR-0088 is named; and ADR-0095 states #115's rule, which only s143 implements.
- **minor — s142 — Notes: tests that change and text that becomes false.** `tests/payload-kept-outside.test.sh:165-169` also becomes a stop; the usage line of `--set-aside` (`bin/polype:57-58`) becomes false for `polype/`.
- **minor — s144 — the colon inside the bold.** Step 3.2 takes `**major:**`; the criterion does not say `- **major:** x` passes.
- **minor — s144 — no general rule for lines that are not list items.** `> major — x` and `• major — x` are left to the implementer.
- **minor — s144 — `other_gate_failures_stop`: the stop is written in no file.** A restarted driver could ship a review that ends `Ship allowed: yes` unchecked.
- **minor — s145 — "au lieu de « the way `/po-review` does »" breaks `tests/pilot.test.sh:19` and `tests/model-routing.test.sh:113`.** Only the recording needs "as `/po-review` says"; `tests/qa-fleet.test.sh:162` pins the po-flow line.
- **minor — s143 — `fresh_source_still_updates` tests `install`, which s143 does not change.** Use `update --global` from a repository.

### Not verified
Issue texts (from the two reviews and the caller's summary); test runs (no shell); ADR-0004's text; the full prose of `po-drive.md`, `po-review.md` and `docs/installation.md`; `cmd_remove`'s `rm -rf "$state_dir"` (`:840`) deleting a foreign file under `polype/`; `po-gate findings-shape` with no id exiting 1; macOS bash and other awk versions.

Max severity: critical
Stories ready: no

> The owner settled the critical on 2026-10-18: option A, the payload signs itself (`polype/payload.sums`), synced with it; and s144 goes through a new ADR-0096 that replaces ADR-0094 on the severity rule. The section was rewritten: s142 holds the signature and the foreign-file stop on every channel, #119–#121 moved to a new s146.

## Loop 2

Review status: complete

**What I read:** the rewritten M16 section (2234-2321), `tests/review-findings-shape.test.sh` (`###`, `F1`), searches of `tests/` for runs from the payload and the final messages of `install` and `update`; what Loop 1 read.

**How each Loop 1 finding was answered:** critical 1 answered by option A (major 1 below remains); major 1 fixed (install, update, init from the payload; the synced payload handled by `payload.sums`); major 2 fixed (ADR-0096 named in full, `ADR-0094-*` owned — which causes the new critical); minors 1–7 fixed. #119–#121 moved to s146; `remove --global`'s `rm -rf` now covered.

### Findings
- **critical — s142 × s144 — `Owns`: `docs/decisions/ADR-0088-*` against `docs/decisions/ADR-0094-*` (check 8).** Both match up to their third segment and both third segments hold `*`; neither story reaches the other. Fix: name both files in full.
- **major — s142 — `foreign_payload_file_stops_install`: the definition of a foreign file leaves out the manifest.** Read by path, a laid file the new version no longer ships becomes "foreign" and the upgrade stops where s139 moves it out; read by content, every upgrade stops. Neither clearly stops the reproduced #118 case (a person's file at a shipped path, first install, `--set-aside`). A file this machine's manifest holds that a synced payload no longer lists would stop the command. `remove --global` collects no shipped files (`bin/polype:812-816`). Fix: foreign = absent from this machine's manifest and neither shipped by the source (repository run) nor listed in `payload.sums` (payload run); manifest files keep the drop and move-out rules; a first-install collision under `polype/` stops; say which source `remove` reads.
- **major — s144 — the new rule for lines outside a list no longer refuses `### F1: major.`, the #112 case.** Its first word is `F1`. `tests/review-findings-shape.test.sh:39-44` and `:56-58` require that heading refused. Fix: keep the heading rule next to the first-word rule.
- **minor — s142 — complexity 3 for seven criteria and a new mechanism.** A 4 with its risk named (the sync channel, existing unsigned installs) would be more honest.
- **minor — s142 — `unsigned_payload_says_so`: which commands it covers.** `check --global` and `remove --global` are not said; `*.polype-next` is not matched by `*.next`.
- **minor — s143 — `install`'s final message has no "left modified" count** (`done_message`, `bin/polype:656`).
- **minor — s144 — `other_gate_failures_stop`: the person reads the wrong cause.** `po-review.md:46` and `po-drive.md:63` say the findings failed their shape twice.

### Not verified
Test runs; `${2:?…}` exiting 1; how chezmoi handles deleted files; how a payload run is told apart (assumed `base` = `$root/polype`); issue texts; pinned prose of `po-drive.md` and ADR-0094; macOS bash and other awk versions.

Max severity: critical
Stories ready: no

## Loop 3

Review status: complete

**What I read:** the revised M16 section (2234-2321), checked against `bin/polype` (`refuse_collisions` 192-234, `done_message` 656, `cmd_remove` 812-858), `po-gate.sh:85-117`, `po-review.md:39-47`, `po-drive.md:63`, `tests/review-findings-shape.test.sh:39-58`.

**How each Loop 2 finding was answered:** critical fixed (every `docs/decisions/` entry is a full file name); major 1 fixed (foreign = absent from the manifest and not shipped / not in `payload.sums`; first-install collision under `polype/` stops; manifest files keep the s137/s139 rules; `remove` reads only the manifest and `payload.sums`; payload run = `base` is `<root>/polype`); major 2 fixed (`### F1: major.` named as refused); minors 1–4 fixed.

### Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| A file Polype did not lay under `~/.claude/polype/` stops the command on every channel | Objectif, #118 | s142 (`foreign_payload_file_stops_install`, `remove_stops_on_foreign_payload_file`, `old_set_aside_never_put_back_in_payload`) | yes (minor 1) |
| The payload signs itself; a synced payload still installs; an unsigned payload says so | Objectif, decision of 2026-10-18 | s142 (`payload_signs_itself`, `synced_payload_still_installs`, `unsigned_payload_says_so`) | yes |
| #115: a still-shipped payload edit is reported and spread nowhere | Objectif, #115 | s143 | yes |
| #119, #120, #121 | the three issues | s146 | yes |
| An ADR records the payload rules | Objectif | s142 (`adr_records_the_payload_rule`) | yes |
| #126 and the narrowing through an ADR that replaces ADR-0094 | Objectif, #126 | s144 (`gate_accepts_only_ship_shapes`, `adr_narrows_the_shape`) | yes |
| #127 | #127 | s144 (`other_gate_failures_stop`) | yes |
| #123 and #125 | #123, #125 | s145 | yes |

### Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| Trusting a payload run from itself; requiring a repository as source; putting a foreign file in `polype.kept/`; spreading the edit while saying so | s142 ADR, options turned down | none | no |
| `--set-aside` under `polype/` | Objectif, #118 | none (but see minor 1) | no |
| Keeping "toute casse" and teaching `/po-ship` the other shapes | s144 ADR, option turned down | none | no |

### Checks
- [x] Exclusions; no disguised layer; criteria 7, 4, 3, 2 and 3 (s142 at the limit); dependency order (s142 → s139, s143 → s142, s146 → s143, s144 and s145 → s141); complexity 4 (risk named), 2, 2, 2, 2; ids; `Owns` (`bin/polype`, `docs/installation.md`, `tests/payload-kept-outside.test.sh` held only along s142 → s143 → s146; s144 and s145 disjoint; all ADR entries full names); surfaces admitted by `cli`; owned records (ADR-0088 by s142, ADR-0094 by s144).

### Findings
- **minor — s142 — `foreign_payload_file_stops_install`: the collision under `polype/` stops only "à la première install".** A later version may ship a new path under `polype/` where the person already has a file the manifest does not know; it would fall to `refuse_collisions` and `--set-aside` (`bin/polype:221-233`). Writing "à toute install ou mise à jour" would make it certain.
- **minor — s144 × s145 — the person's message for an exit-2 report under `/po-orchestrator` and `/po-flow`.** The routing is right either way; only the wording could say "failed their shape twice" for an exit 2.

### Not verified
Test runs; sync deletions (no longer decisive); `${2:?…}` exiting 1; pinned ADR text; issue texts; unread prose of `po-drive.md`; macOS bash and other awk versions.

Max severity: minor
Stories ready: yes

> Answered at the next revision, 2026-10-18. Minor 1: the collision under `polype/` stops "à toute install ou mise à jour". Minor 2: s145's notes say the person's message takes the cause the report writes ("the check could not run" for an exit other than 0 and 1). Stories ready: yes.
