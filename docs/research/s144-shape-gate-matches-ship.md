# Research — s144-shape-gate-matches-ship

[Story](../stories.md)

## Structuring facts
- Root cause #126: `opens()` at `method/hooks/po-gate.sh:94` accepts a severity in any case followed by *any* non-word character, and only `- `, `* `, `<n>. ` count as items (`:104`); every other line goes to `bad = opens(l)` (`:105`), so `+ major — x`, `1) major — x`, `> major`, `• major` are tested against the same loose `opens()`. Step 3.2 of `/po-ship` opens only lowercase `critical|major|minor`, bare or bold, then `—`, `:` or `-` (`method/commands/po-ship.md:86`, title `sed` at `:90`). Proof: all eight lines the story wants refused exit 0 today (Diagnostic below).
- Root cause #127 (gate side): the dispatch `findings_shape "${2:?story id required}"` (`method/hooks/po-gate.sh:515`) dies with exit **1** under `set -euo pipefail` when the id is missing — the very exit `/po-review` reads as "malformed review". Proof: `bash method/hooks/po-gate.sh findings-shape; echo $?` → `ligne 515: 2: story id required`, `exit=1`. An awk failure also leaves through `refuse` with 1 (`:114`), as do a missing review file (`:89`) and a review with no verdict block (`:90-91`).
- Root cause #127 (prose side): `/po-review` `## Recording` handles exit 1 only (`method/commands/po-review.md:39`); `/po-drive` likewise (`method/commands/po-drive.md:138`), and its resume row says only "failed their shape twice" (`:63`). An exit 2 (unknown subcommand from an old installed gate, `po-gate.sh:519`) has no rule.
- No assumption of the story is false. Minor: the story cites `tests/fleet-wiring.test.sh:68` as pinning `po-review.md`/`po-drive.md`; that line reads `po-status.md`'s Fleet step — harmless, nothing to keep there.

## Diagnostic
**Reproduction** (scratch repo in `mktemp -d`, review `## Findings` holding one line, then `po-gate findings-shape s01-a`), exit code per line:
- should be refused, all `0` today: `- major. a.sh:1 x` · `- major (a.sh:1) x` · `- MAJOR x` · `- Major — x` · `+ major — x` · `1) major — x` · `> major — x` · `• major — x`
- must pass, all `0` today: `- **major:** x` · `- **major**: x` · `- major — x` · `1. **minor**: y` · `* minor: z` · `None.` · `No critical or major finding.` · `- the majority of cases` · `- major-ish thing` (step 3.2 opens it: severity then `-`).
- missing id: exit 1 with bash's `${2:?}` message (above). `floor-guard` without args exits 2 through `unverifiable` (`po-gate.sh:366`) — the existing pattern for "cannot run".

**Hypotheses**
1. *The gate's item regex is right and only the case is loose.* Refutation: `+ major — x` and `1) major — x` are not items for the gate at all yet pass. Discarded — the marker set is also involved.
2. *`opens()` accepts any non-word char after the severity, wider than step 3.2's `—`, `:`, `-`, and is case-insensitive (`tolower`, `:94`) where step 3.2 is not.* Refutation would be a separator other than `—:-` being refused. `- major. a.sh:1 x` and `- major (a.sh:1) x` pass; `- MAJOR x` passes. **Kept.**
3. *Non-item lines are judged by the same `opens()`* (`:105`), so any prefix that is not a recognised marker but still starts with the severity (`> `, `• `, `+ `, `1) ` start with a non-letter, so `opens()` fails…). Checked: `opens()` anchors at `^(\*\*)?` — `+ major` does not open with the severity, so `bad = 0`. **Kept** as the second half of the cause: a non-item line is refused only when it *opens* with a severity, never when a symbol precedes it.

## Story
`po-gate findings-shape` accepts a finding only in a shape step 3.2 of `/po-ship` opens, and any other gate failure stops the recording in writing.
- `gate_accepts_only_ship_shapes` — an item naming a severity passes only as marker `- `/`* `/`<n>. `, lowercase severity bare or bold, colon inside or outside the bold, then `—`, `:` or `-`. Refused, quoted with its line number: a heading naming a severity anywhere (`### F1: major.`, #112), and any other line of `## Findings` outside an accepted item and outside an indented continuation whose first word, past non-letters, is a severity in any case (the eight lines above). s141's accepted cases still pass.
- `other_gate_failures_stop` — no id → exit 2; `/po-review` and `/po-drive` say a gate exit other than 0 and 1 is not a malformed review: no re-ask, the same blocked report as a second failure (`Review status: blocked`, a `Next action:` naming `po-gate findings-shape` and the exit, `Max severity: critical`, `Ship allowed: no`); the report and the `/po-drive` resume row say the check could not run, with the exit.
- `adr_narrows_the_shape` — new ADR supersedes ADR-0094 on the severity rule; option turned down: keep "any case" and teach `/po-ship` the other shapes. Only ADR-0094's `superseded-by` changes.

## Current code
- `findings_shape()` `method/hooks/po-gate.sh:87-117`: reads the block ending at the last `Ship allowed:` (`:96`), scans `## Findings` up to the next `## ` (`:100-101`); heading → `names()` (`:102`); blank or indented → pass (`:103`); item → `names(item) && !opens(item)` (`:104`); else `opens(l)` (`:105`). Awk exit 2 = no `## Findings` (`:108`, mapped to `refuse` → 1 at `:112`).
- `names()` `:93`: whole-word severity, any case. Keep: it is the "item naming a severity" and "heading naming a severity" test.
- Header comment `:17-18` documents exits 0 and 1 only.
- Dispatch `:511-520`; unknown subcommand → 2 (`:519`).
- `/po-review` `## Recording` `po-review.md:39` (exit 1 → one re-ask; second exit 1 → blocked report with `Next action: a person settles the findings shape — po-gate findings-shape <id> refused the reviewer twice`); `## Outcome` `:46` ("…failed their shape twice. A person settles them; no fix run is spent.").
- `/po-drive` `po-drive.md:138` (same, through Bash), `:140` ("Besides that shape stop, the single report you compose yourself…"), resume row `:63`.

## Attachment points
- `opens()` → replaced by one ship-shape motif on the whole first line (marker included); `:104` and `:105` change; a first-word rule for non-item lines.
- A local `exit 2` helper in the style of `unverifiable` (`po-gate.sh:366`) for: missing id, missing review file, no verdict block, awk failure. Dispatch `:515` passes `"${2:-}"`.
- `po-review.md:39` and `:46`; `po-drive.md:63`, `:138`, `:140`.
- New `docs/decisions/ADR-0096-le-controle-de-forme-suit-ce-que-po-ship-lit.md`; `superseded-by: [ADR-0096]` in ADR-0094 (`:8`).

## Verified interfaces
- Step 3.2 "Which findings" `po-ship.md:86`: marker `- `, `* ` or `1. `, severity bare or bold, then `—`, `:` or `-`, colon inside or outside the bold. Title `sed` `:90`: `s/^(\*\*)?(critical|major|minor)(:)?(\*\*)? *[—:-]? *//` — case-sensitive.
- Net `po-ship.md:87` already sends headings and mid-item severities to the person; it is not in `Owns` and does not change.
- Tests: `tests/review-findings-shape.test.sh` (in `Owns`) — helpers `findings_block`, `shape`, `refused`, `accepted` (`:14-31`); `test_gate_checks_findings_shape` refuses `- see the major point` (`:45`), accepts `- **minor:** colon in bold`, an indented sub-bullet, `- the majority of cases` (`:52-54`); `test_recording_runs_the_check` pins `po-review.md` phrases (`:78-84`, incl. the Outcome prefix `a \`Next action:\` naming \`po-gate findings-shape\` → "Review of <id> stopped`) and the `po-drive` row prefix and its order before the fix-run row (`:89-92`); `test_adr_records_the_shape_check` needs ADR-0094 `status: accepted` (`:106`).
- `scratch_repo`, `fail`, `contains`, `require_file`, `frontmatter`, `lacks_tool` from `tests/lib.sh`.
- gawk 5.4.1 here; `—` is multibyte, so in awk it goes in an alternation `(—|:|-)`, never a bracket class.

## Traps
- `- see the major point` is refused by s141's test (`:45`) and must stay refused: the AC's first sentence ("an item naming a severity passes only in a shape step 3.2 opens") covers it, even though the first-word rule alone would not.
- `- major-ish thing` passes step 3.2 (severity then `-`): the motif must accept it, or the gate refuses what ship reads.
- `- Major — x` must be refused (lowercase only), while the first-word rule for *other* lines is case-insensitive.
- Unchanged pinned phrases: `tests/qa-fleet.test.sh:112-124` (`po-review.md` QA lines, "Any other `Ship allowed: no` …", `po-drive.md` verdict lines); `tests/review.test.sh` (no `Bash` tool in `po-review.md`); `tests/drive.test.sh:151-152` (no backquoted `` `cd `` in `po-drive.md`); `tests/resume.test.sh:22-23`.
- s145 (parallel lane, `po-orchestrator.md`, `po-flow.md`) quotes this story's report and will say "the check could not run" for an exit other than 0 and 1: that exact phrase must appear in the `/po-review` blocked report.
- `.claude/` and `.polype/` are installed copies — never edited.
- No migration.

## Open questions
- Should a missing review file and a block with no `Ship allowed:` exit 2 rather than 1? Both are "the check cannot run" rather than a malformed finding, and the recording never checks a self-composed report. The plan decides: yes (exit 2), with `## Findings` missing staying 1 as s141's AC fixed.

## Complexity
Story: 2 → after reading: 2. One awk motif, one exit-code path, prose in two commands, one ADR; the tests file already has the helpers.

## Split
—
