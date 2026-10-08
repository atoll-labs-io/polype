---
track: flow
validated: yes
---
# Plan (short track) — s73-text-leftovers

Written by the planner on the short track (`Story track: auto`, complexity 1 ≤ `Flow threshold: 2`). This file stands in for both the research and the plan: there is no `docs/research/s73-text-leftovers.md`. Validated autonomously (`Plan validation: autonomous`): no human reviewed it.

## Verified facts
No assumption of the story proved false. The ADR file names in `Owns` match `docs/decisions/` exactly.

**Testing doctrine**
- `method/skills/testing-doctrine/SKILL.md:62` shows `po-run --story <id> --label <check> -- "<command>"`: double quotes, the leftover named by m1 of `docs/reviews/s67-record-text.md:54`.
- The implementer already passes the command between single quotes, with `'\''` for an inner quote: `method/agents/implementer.md:42`. The gate's hint builds `ql`/`qc` single-quoted: `method/hooks/po-gate.sh:122-124`.
- Existing tests reading this file: `tests/run-ledger.test.sh:143` (`contains … 'po-run --story'`, still true after the change) and `tests/plan.test.sh:32-45` (section headings and two phrases, none on line 62). No test checks the double-quoted form.

**ADR frontmatter**
- Link format used by the repository: `superseded-by: [ADR-0018]` (`docs/decisions/ADR-0003-…md:9`), list form `[ADR-xxxx]`; `supersedes:` on the successor (`ADR-0015-…md:8`, `ADR-0044-…md:7`).
- `ADR-0024-po-bounds-trouve-la-story-par-son-worktree.md:4,9`: `status: accepted`, `superseded-by: []`. Partly replaced by:
  - ADR-0038 — "Ce point d'ADR-0024 est remplacé ici" (reading `Owns` at `HEAD`): `ADR-0038-…md:14`;
  - ADR-0039 — "Ce point d'ADR-0024 est remplacé ici (remplacement partiel…)" (Bash analysis in words): `ADR-0039-…md:14`.
- `ADR-0029-po-qa-committe-les-preuves-qa.md:4,9`: `status: accepted`, `superseded-by: []`. Partly replaced by ADR-0037, whose context says "seule sa conséquence neutre change": `ADR-0037-…md:14` (m5 of `docs/reviews/s60-gate-parsing.md:69`). ADR-0034 cites ADR-0029 (`ADR-0034-…md:15,20,21`) but adds the driver's commit without replacing any clause: not a successor.
- `ADR-0037-qa-current-exige-une-preuve-qa-committee.md:3,8`: `status: accepted`, `superseded-by: []`; its frontmatter has no `tags:` line (lines 1-9). Partly replaced by:
  - ADR-0041 — replaces "la conséquence « Bad » d'ADR-0037 sur `po-drive.md`": `ADR-0041-…md:35`;
  - ADR-0044 — `supersedes: [ADR-0037]` (`ADR-0044-…md:7`), replaces the "fichiers ignorés" point: `ADR-0044-…md:14`.
- Accepted ADRs are never edited in their body (Law 6, `AGENTS.md`); only the `superseded-by:` line of each frontmatter changes.

**Settings**
- `method/templates/agents-local.md:21` declares `QA stage:          —` (between `Build stage` and `Issue tracker`); `:78` declares `Dev:               —` (after `Build`).
- Polype's `AGENTS.local.md` has neither: Pipeline block `:7-34` goes `Build stage` (`:18`) → `Issue tracker` (`:19`); Commands block `:38-45` ends at `Build:` (`:44`).
- `bin/polype` `missing_settings` (`bin/polype:195-211`) prints `missing setting: <Name>: <value>` for each template name absent from `AGENTS.local.md`; `cmd_check` calls it on stdout and it never changes the exit status (`bin/polype:378-379`, ADR-0043).
- Live run today, `bash bin/polype check <worktree>` from `/tmp`: first line `Polype 0.2.0 installed in …`, then `missing:` lines for `.claude/…` (the worktree has no `.claude/`, ignored by the user's global git ignore), then `missing setting: QA stage: —` and `missing setting: Dev: —`; exit status 1 because of the `.claude/` files. `.polype/manifest` and `.polype/checksums` are tracked, so `check` runs in any clone.
- `AGENTS.md` (tracked, installed) carries a copy of `AGENTS.local.md` (`AGENTS.md:143`, `:179`); it is refreshed on `main` after ship by a separate commit (`25f4ebb Refresh the installed method with s72`), not by a story.

**Tests**: bash, `tests/<slug>.test.sh` defining `test_<criterion>` (`tests/run.sh`), helpers `contains`, `frontmatter`, `fail`, `require_file` in `tests/lib.sh`.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text and `Owns`: text and frontmatter only | absent — no data, only markdown and one settings file |
| New screen | absent — story text | absent — Polype has no UI |
| Authorization or tenant scope | absent — story text | absent — `po-bounds.sh` and its modes untouched (not in `Owns`) |
| API contract | absent — story text | absent — `bin/polype` output format unchanged; only the input file `AGENTS.local.md` gains two lines |
| New dependency | absent — story text | absent — tests use bash, grep, `bin/polype` already present |

## Story
As a developer, I want the last texts lagging behind the method aligned, so that a reader does not follow a stale instruction.
- `testing_doctrine_single_quotes_po_run` — the testing doctrine shows `po-run … -- '<command>'` in single quotes, like the implementer and the gate.
- `replaced_adrs_point_to_their_successor` — the frontmatter of ADR-0024, ADR-0029 and ADR-0037 points (`superseded-by`) to the ADRs that replace part of them, body untouched; status stays `accepted` since the replacement is partial.
- `polype_declares_every_template_setting` — Polype's `AGENTS.local.md` declares `QA stage: —` and `Dev: —`, and `polype check .` no longer reports any missing setting there.

## Tasks

1. [x] **Doctrine.** In `method/skills/testing-doctrine/SKILL.md:62`, change `-- "<command>"` to `-- '<command>'` and add, in the same sentence, that a single quote inside the command is written `'\''` (wording of `implementer.md:42`, in your own sentence). Nothing else in the file changes. Test able to fail: `test_testing_doctrine_single_quotes_po_run` (the single-quoted form present, `-- "<command>"` absent).
2. [x] **ADR links.** Change only line 9 of ADR-0024 to `superseded-by: [ADR-0038, ADR-0039]`, line 9 of ADR-0029 to `superseded-by: [ADR-0037]`, line 8 of ADR-0037 to `superseded-by: [ADR-0041, ADR-0044]`. `status: accepted` stays on all three. Test able to fail: `test_replaced_adrs_point_to_their_successor`.
3. [x] **Settings.** In `AGENTS.local.md`, insert `QA stage:          —` after `Build stage:` (`:18`) and `Dev:               —` after `Build:` (`:44`), aligned as in the template (`agents-local.md:21,78`). Test able to fail: `test_polype_declares_every_template_setting`.
4. [x] **Tests.** Create `tests/leftovers.test.sh` with the three functions below, then run `bash tests/run.sh leftovers.test.sh run-ledger.test.sh plan.test.sh`.
   - `test_testing_doctrine_single_quotes_po_run`: `contains "$METHOD/skills/testing-doctrine/SKILL.md" "-- '<command>'"` and `! grep -qF -- '-- "<command>"' …`.
   - `test_replaced_adrs_point_to_their_successor`: for each of the three files (under `$ROOT/docs/decisions/`), `frontmatter` holds the exact line `superseded-by: [...]` of task 2 and the exact line `status: accepted` (`grep -qx`).
   - `test_polype_declares_every_template_setting`: `grep -qx` for `QA stage:          —` and `Dev:               —` in `$ROOT/AGENTS.local.md`; then `out="$(bash "$ROOT/bin/polype" check "$ROOT" 2>&1 || true)"` (exit status ignored: a worktree lacks `.claude/`); require `out` to contain `installed in` so a crashed `check` cannot pass, and fail if it holds any line starting `missing setting:`.
5. [x] **Full suite** once, through `po-run` as the implementer contract says, then the record and the single commit.

## Run interdicts
- The body of ADR-0024, ADR-0029 and ADR-0037 ends unchanged: `git diff main...story/s73-text-leftovers -- docs/decisions/` shows exactly three changed lines, each a `superseded-by:` line; no `status:` line changes.
- No diff on ADR-0034, ADR-0038, ADR-0039, ADR-0041, ADR-0044 (outside `Owns`), nor on any other ADR; no new ADR (ADR-0049 stays unused).
- No diff on `AGENTS.md`, `.claude/`, `.polype/` (installed copies, refreshed on `main` after ship), `bin/polype`, `method/templates/agents-local.md`, `method/agents/implementer.md`, `method/hooks/po-gate.sh`.
- In `AGENTS.local.md`, only the two added lines: no other setting's value changes.
- In `testing-doctrine/SKILL.md`, only the sentence of line 62 changes.
- No existing test file is modified.

## The pivot
Which ADRs count as "replacing part" of each target. The choice rests on each successor's own words ("remplacé ici", "remplace … la conséquence", `supersedes:`), cited above. It could be wrong if ADR-0034 is read as replacing ADR-0029's "/po-qa commits alone" (it adds a second committer, the driver, in a lane): the reviewer may judge that ADR-0029 should also list ADR-0034. It could also go stale: the s71 lane writes an ADR replacing ADR-0039, which concerns the ADR-0024 point now carried by ADR-0039; ADR-0024 links to ADR-0039 and the chain continues from there.

## Files touched
- `method/skills/testing-doctrine/SKILL.md`
- `docs/decisions/ADR-0024-po-bounds-trouve-la-story-par-son-worktree.md`
- `docs/decisions/ADR-0029-po-qa-committe-les-preuves-qa.md`
- `docs/decisions/ADR-0037-qa-current-exige-une-preuve-qa-committee.md`
- `AGENTS.local.md`
- `tests/leftovers.test.sh` (new)
- `docs/plans/s73-text-leftovers.md`, `docs/verif/s73-text-leftovers.md`

## Test strategy
Three tests, one per criterion, well within `Test budget: 25`. Each bites on its rule: reverting line 62 fails the first; emptying any `superseded-by:` or flipping a status fails the second; removing either setting fails the third twice (exact line, then `check`'s `missing setting:` line, which runs the real `missing_settings` of `bin/polype` rather than a re-implementation). The `installed in` guard keeps a broken `check` from passing with empty output. "Body untouched" is not a test: it is a run interdict the reviewer checks on the diff.

## Done when
The three tests and the full suite pass through `po-run`, the record is complete, one commit on `story/s73-text-leftovers` carries the code, the plan and the record, and the review has no open critical finding.
