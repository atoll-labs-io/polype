---
validated: yes
---
# Plan — s144-shape-gate-matches-ship

[Story](../stories.md) · [Research](../research/s144-shape-gate-matches-ship.md)

Branch `story/s144-shape-gate-matches-ship`. Read `docs/research/s144-shape-gate-matches-ship.md` first; this plan builds on it without repeating it. Defect story (#126, #127): root causes are `method/hooks/po-gate.sh:94`, `:104-105` (loose `opens()`, non-item lines judged by it) and `:515` (`${2:?}` exits 1).

## Story
`po-gate findings-shape` accepts a finding only in a shape step 3.2 of `/po-ship` opens; any other gate failure stops the recording in writing. Criteria: `gate_accepts_only_ship_shapes`, `other_gate_failures_stop`, `adr_narrows_the_shape` (full text in `docs/stories.md`).

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Ship-shape motif in the awk of `findings_shape` | already in this repository: the shape of `method/commands/po-ship.md:86` and its title `sed` `:90`, transcribed as one ERE; `names()` `po-gate.sh:93` reused unchanged | — (first rung holds) |
| Exit-2 helper for "cannot run" | already in this repository: the `unverifiable` pattern `po-gate.sh:366` (echo to stderr, `exit 2`) | `unverifiable` itself names "the floor of", so a sibling one-liner with the findings wording is needed |
| Three test functions | already in this repository: `findings_block`, `shape`, `refused`, `accepted`, `holds`, `section_of` in `tests/review-findings-shape.test.sh:10-31`; `scratch_repo` in `tests/lib.sh:46` | — |

## Tasks
1. [x] **Gate motif** (`method/hooks/po-gate.sh`, `findings_shape`). Replace `opens()` (`:94`) with one function `ships(s)` on the whole raw line, case-sensitive, gawk ERE, `—` only inside an alternation:
   `s ~ /^([-*] |[0-9]+\. )(\*\*(critical|major|minor):\*\*|((critical|major|minor)|\*\*(critical|major|minor)\*\*) *(—|:|-))/` — the `**major:**` form carries its separator inside the bold. Checked by the planner with gawk 5.4.1 under UTF-8 and `LC_ALL=C` against every case of the story and of s141. Add `first(s)`: strip leading characters that are not letters (`sub(/^[^A-Za-z]+/, "", s)`), then `tolower(s) ~ /^(critical|major|minor)([^a-z0-9_]|$)/`. New branch logic, in this order: heading (`^#`) → `bad = names(l)`; blank or indented → `bad = 0`; item (`^([-*] |[0-9]+\. )`) → `bad = names(item) && !ships(l)`; any other line → `bad = first(l)`. Update the comment above `findings_shape` (`:84-86`) to cite ADR-0096 and say the motif is step 3.2's, one sentence. Test: `test_gate_accepts_only_ship_shapes` (refuses the eight #126 lines, `- Major — x` among them, which would pass if `ships` were case-insensitive or kept the old separator set) and the unchanged `test_gate_checks_findings_shape` (`- see the major point` still refused, s137 headings still quoted, s138 still accepted).
2. [x] **Exit 2 when the check cannot run** (`method/hooks/po-gate.sh`). Add `shape_unreadable() { echo "po-gate: cannot check the findings of ${1:-<id>}: $2" >&2; exit 2; }` next to `findings_shape`. Use it for: empty id (`usage: po-gate findings-shape <id>`), review file missing (`:89`), no `Ship allowed:` line (`:90-91`), awk exit other than 0, 1, 2 (`:114`). A missing `## Findings` stays exit 1 (`:112`, s141). Dispatch `:515` becomes `findings_shape "${2:-}"`. Header `:17-18`: add "2 when it cannot run (no id, no review, no verdict block)". Test: `test_other_gate_failures_stop` asserts exit **2** for no id and for a missing review file (exit 1 from `${2:?}` would fail it).
3. [x] **`/po-review` `## Recording` and `## Outcome`** (`method/commands/po-review.md:39`, `:46`). Keep every existing sentence of `:39`. After "A second exit 1 → … That stop goes to the person at once.", insert: "Any other exit — 2 when the check cannot run, such as a missing id or a `.polype/hooks/po-gate.sh` older than `findings-shape` answering `unknown subcommand` — is not a malformed review: the reviewer is not dispatched again, and the same blocked report is appended, with `Failure cause:` the gate's exit and its message, `Missing:` a shape check that ran, `Required adaptation:` a person runs the check or repairs the installed gate, `Next action: a person runs po-gate findings-shape <id> — the check could not run (exit <n>)`, then `Max severity: critical` and `Ship allowed: no`." Rewrite the `:46` bullet keeping its prefix: `- \`Ship allowed: no\` with \`Review status: blocked\` and a \`Next action:\` naming \`po-gate findings-shape\` → "Review of <id> stopped: <the cause its Next action: gives — the reviewer's findings failed their shape twice, or the check could not run (exit <n>)>. A person settles it; no fix run is spent."`. Test: `test_other_gate_failures_stop` (phrases below) and the unchanged `test_recording_runs_the_check`.
4. [x] **`/po-drive`** (`method/commands/po-drive.md`). Row `:63`: keep its prefix `| \`Review status: blocked\` and a \`Next action:\` naming \`po-gate findings-shape\` | a human` and its place before the fix-run row; its cell becomes "a human — the cause its `Next action:` gives: the reviewer's findings failed their shape twice, or the check could not run (exit <n>); no fix run, no `Max attempts` unit". `:138`: append "Any other exit is not a malformed review: the reviewer is not asked again, the blocked report `/po-review` describes for a check that could not run is appended through Bash with the exit, and the lane goes to a human at once." `:140`: "Besides that shape stop" → "Besides those shape stops". No backquoted `` `cd `` anywhere (`tests/drive.test.sh:151`). Test: `test_other_gate_failures_stop`.
5. [x] **ADRs**. `docs/decisions/ADR-0096-le-controle-de-forme-suit-ce-que-po-ship-lit.md` is already written by the planner (`supersedes: [ADR-0094]`); check it still matches the code once tasks 1-2 are done. In ADR-0094 change only line 8 to `superseded-by: [ADR-0096]`; `status: accepted` stays (partial supersession, `method/templates/adr.md:4`). Test: `test_adr_narrows_the_shape`.
6. [x] **Tests** in `tests/review-findings-shape.test.sh` (existing functions untouched; add a `ADR96` path variable at the top):
   - `test_gate_accepts_only_ship_shapes`: `scratch_repo`, `mkdir -p "$SCRATCH/docs/reviews"`; `refused` on each of `- major. a.sh:1 x`, `- major (a.sh:1) x`, `- MAJOR x`, `- Major — x`, `+ major — x`, `1) major — x`, `> major — x`, `• major — x`, `### F1: major.` (one call each, so the failure names the line); check one refusal quotes `docs/reviews/s01-a.md:5: + major — x` (line 5 in `findings_block`); `accepted '- **major:** x' '- **major**: x' '- major — a.sh:1 — plain' '- **major** — b' '1. **minor**: c' '* minor: d' '- major-ish thing' 'None.' 'No critical or major finding.'`.
   - `test_other_gate_failures_stop`: in a scratch repo, `bash "$GATE" findings-shape` exits exactly 2; with no `docs/reviews/s01-a.md`, `findings-shape s01-a` exits exactly 2; `holds` on `section_of "$REVIEW_CMD" Recording`: `Any other exit`, `is not a malformed review: the reviewer is not dispatched again`, `` `Next action: a person runs po-gate findings-shape <id> — the check could not run (exit <n>)` ``; on Outcome: `or the check could not run (exit <n>)`; on the `po-drive` verdict section: `Any other exit is not a malformed review: the reviewer is not asked again`; the `po-drive` row line (grep of the prefix) holds `the check could not run (exit <n>)`.
   - `test_adr_narrows_the_shape`: `require_file "$ADR96"`; `frontmatter` holds `supersedes: [ADR-0094]` (`grep -qx`); ADR-0094 frontmatter holds `superseded-by: [ADR-0096]` and still `status: accepted`; ADR-0096 `contains` `**B. Garder « toute casse » et apprendre à \`/po-ship\` les autres formes.** Écartée`; `git diff main -- <ADR-0094>` is out of test scope (reviewer checks it, see interdicts).
   Then run `bash tests/run.sh review-findings-shape.test.sh`, and once at the end the full suite through `po-run --story s144-shape-gate-matches-ship --label test -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff for: `.claude/`, `.polype/` (installed copies), `method/commands/po-ship.md`, `method/templates/review.md`, `method/agents/reviewer.md`, `method/commands/po-orchestrator.md`, `method/commands/po-flow.md` (s145's lane), every `docs/reviews/*.md`.
- ADR-0094: the diff is exactly one line, `superseded-by: [] → [ADR-0096]`.
- `po-gate.sh`: only `findings_shape`, its header lines `:17-18`, its comment `:84-86` and dispatch `:515` change; the other subcommands' code has an empty diff.
- Existing test functions in `tests/review-findings-shape.test.sh` keep every assertion; only new functions and one path variable are added. No other test file changes.
- `po-review.md` frontmatter unchanged (no `Bash` tool, narrowed permission line intact); every sentence of `:39` that `tests/review-findings-shape.test.sh:78-83` quotes stays word for word.

## The pivot
One motif, the one step 3.2 opens, decides acceptance; everything else that names a severity is refused. Ways it could be wrong:
- **The motif diverges from step 3.2.** Compare the ERE with `po-ship.md:86` and the title `sed` `:90`: `- major-ish thing` and `- **major:** x` must pass, `- Major — x` and `- major. x` must not. A bracket class holding `—` would match its bytes one by one in gawk: alternation only.
- **The first-word rule over-refuses prose.** "No critical or major finding." and "Two major findings below" start with a non-severity word and pass; `**minor** — x` and `Critical: x` (s141's refusals) start with one and stay refused.
- **Exit 2 reaches a case that should be 1.** A missing `## Findings` is a malformed review (s141 AC): it must stay 1, and the existing test at `review-findings-shape.test.sh:48-50` only checks non-zero, so the reviewer checks `:112` by reading.

## Files touched
- `method/hooks/po-gate.sh`
- `method/commands/po-review.md`
- `method/commands/po-drive.md`
- `docs/decisions/ADR-0096-le-controle-de-forme-suit-ce-que-po-ship-lit.md` (written at planning)
- `docs/decisions/ADR-0094-la-forme-d-une-revue-se-controle-a-l-enregistrement.md` (one frontmatter line)
- `tests/review-findings-shape.test.sh`
- `docs/research/s144-shape-gate-matches-ship.md`, `docs/plans/s144-shape-gate-matches-ship.md`

## Test strategy
Three new bash tests, one per criterion, in the story's existing test file (budget 25). Bite: `test_gate_accepts_only_ship_shapes` fails if `ships` is made case-insensitive, accepts any non-word separator, or non-item lines go back to "opens with a severity"; `test_other_gate_failures_stop` fails if `:515` keeps `${2:?}` (exit 1) or a missing review falls back to `refuse`; prose assertions fail if the "could not run" sentences are dropped. Existing `test_gate_checks_findings_shape` and `test_recording_runs_the_check` stay as they are and keep s141's cases. No visual check (no screen).

## Done when
One commit on `story/s144-shape-gate-matches-ship` with code, tests, research, plan, ADRs; `bash tests/run.sh` green through `po-run`; review with no open critical; landed through a pull request; #126 and #127 closed by the landing.
