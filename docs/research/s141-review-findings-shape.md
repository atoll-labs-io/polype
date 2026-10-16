# Research — s141-review-findings-shape

[Story](../stories.md)

## Structuring facts
- **False assumption: `/po-review` cannot run `po-gate`.** Its `allowed-tools` are Read, Glob, Grep, Agent, Write (`method/commands/po-review.md:4-9`), and `tests/review.test.sh:38` pins `lacks_tool "$CMD" Bash`, outside `Owns` and missing from the story's Notes; `AGENTS.local.md` (Conventions) says "Commands that must not write code do not get Write/Edit/Bash". `recording_runs_the_check` cannot hold as written without a choice on that tool contract → drafted in ADR-0094, plan marked `Technical choice: waiting for a human`.
- **Root cause (#112):** `method/commands/po-ship.md:86` takes only list items opening with a severity, and its net (`po-ship.md:87`) only catches list items and non-list lines *opening* with a severity; a heading `### F1: major. …` starts with `#`, so it is neither. Input: `docs/reviews/s137-modified-copy-survives-drop.md:65` and `:86`. Proof: the reproduction below classifies both as missed. Upstream, `method/templates/review.md:55` shows the finding line with no list marker, and nothing checks a review when it is recorded (`po-review.md:35-38`, `po-drive.md:135`).
- **Partly false: "/po-flow and /po-orchestrator inherit without change".** True in-session only if the stop lives inside `/po-review`'s `## Recording`, which both apply (`po-flow.md:89`, `po-orchestrator.md:70`). On a later run, `po-orchestrator.md:78` ("Any other blocked review → back to stage 5 as a fix run") would read the shape-blocked report as a fix run; that file is outside `Owns`.
- **Hidden requirement for "the stop survives a restart":** the `/po-drive` resume table routes any last `Ship allowed: no` to a fix run (`po-drive.md:63`); a new row is needed before it, keyed on the blocked report's `Next action:`.
- **Trap:** a blocked report with no `## Findings` fails the check by the criterion's own rule — both the one the recording context writes on a failed subagent (`po-review.md:38`) and the reviewer's own blocked answer (`reviewer.md:40-46` lists five lines, no Findings).

## Diagnostic
**Reproduction** (no file written in the worktree): the rules of `po-ship.md:86-87` applied with `grep -E` to the `## Findings` lines of both reviews.
- s137 → `HEADING-missed 65: ### F1: major. …`, `HEADING-missed 86: ### F2: minor. …`; no item, no net hit. Two findings silently dropped, as #112 reports.
- s138 → `ITEM 55`, `ITEM 56`: both read.

**Hypotheses**
1. *Step 3.2 does not take headings as findings* — refutation would be a clause of `po-ship.md:86` admitting `#`. None: "a list marker — `- `, `* ` or a number and a dot". **Kept.**
2. *The net does not catch headings either* — refutation: a clause of `po-ship.md:87` covering a line starting with `#`. None (list items, and lines opening with a severity). **Kept.**
3. *The reviewer drifted from a template that showed the list shape* — refutation: the template showing `- ` before the severity. `review.md:55` reads `<one per line: severity — file:line — the problem; …>`, no marker. **Discarded** as a sole cause: the template never showed the list shape (the issue's comment of 2026-10-16 says so too).
4. *Nothing checks the shape before ship* — refutation: a check after recording. `po-review.md:35-38` and `po-drive.md:135-137` check only the two verdict lines. **Kept.**

## Story
A review is filled on a template showing the exact finding line `- <critical|major|minor> — <path>:<line> — <the problem>`; `po-gate findings-shape <id>` checks the last review's `## Findings` right after recording; a failure is sent back to the reviewer once (same `Fix loop:`, no `Max attempts` unit), the new answer appended; a second failure becomes a blocked report for the person; `/po-ship`'s net also catches headings; ADR-0094 records why. Criteria: `template_shows_the_line`, `gate_checks_findings_shape`, `recording_runs_the_check`, `ship_net_catches_headings`, `adr_records_the_shape_check`.

## Current code
- `method/templates/review.md:54-55` — `## Findings` placeholder, no list marker; keeps "a finding never starts with `Ship allowed:`" (pinned by `tests/hooks-installer-docs-cleanup.test.sh:57`). Ends with `Max severity:` then `Ship allowed:` (`:60-61`, pinned `tests/review.test.sh:23`, `tests/review-lenses.test.sh:85-86`).
- `method/agents/reviewer.md:50-56` — "Structured like `templates/review.md`"; no word on the finding line. `:39-48` blocked report: five lines.
- `method/hooks/po-gate.sh:474-482` — dispatcher; `refuse()` `:28` prints on stderr and returns 1; `top()` `:27` is the cwd's toplevel, so the gate must run with the worktree as cwd. Header `:3-18` lists every subcommand. `ship_allowed` `:66-80` reads the last block through `^([-*] )?Ship allowed:` (`:69`, `:72`).
- `method/commands/po-review.md:35-38` Recording; `:40-44` Outcome; `:26` Fix loop rule.
- `method/commands/po-drive.md:134-141` verdict section, recording "through Bash" `:135`; `:44-80` Resuming table; `:18` Bash "records what a subagent handed you".
- `method/commands/po-ship.md:85-98` Step 3.2: `:86` which findings, `:87` the net, `:90-91` the `- title:` / `- body:` lines `cut_finding` executes (`tests/everything-in-issues.test.sh:128-139`).

## Attachment points
- `po-gate.sh`: new function beside `ship_allowed`, new header line, new `case` arm `findings-shape)`.
- `po-review.md` `## Recording` (the paragraph flow and orchestrator apply) and `## Outcome` (new bullet before "Any other").
- `po-drive.md` `## The verdict, and the fix runs` (after `:135`) and `## Resuming` (row before `:63`).
- `po-ship.md:87`, one clause inserted.
- `review.md:55`, `reviewer.md` `## Your answer` and `## When you cannot finish`.

## Verified interfaces
- Last block = lines after the previous `^([-*] )?Ship allowed:` up to the last one (`po-gate.sh:41-47` pairs values the same way).
- Shapes `/po-ship` reads: `- major —`, `- **major** —`, `1. **minor**:`, `* minor:` (`po-ship.md:86`; fixtures `tests/everything-in-issues.test.sh:144-150`). Title sed is lowercase-only (`po-ship.md:90`).
- Prototype of the three refused cases (awk, in `/tmp`, not in the worktree), run over the 139 files of `docs/reviews/`: s137 refused on `:65`, `:86`; s138 passes; older reviews refused for headings (`s47`, `s51`, `s52`, `s54`, `s79`, `s91`), bold non-list lines (`s36`, `s37`), `- **m1 (minor):**` items (`s63`, `s65`, `s67`, `s71`, `s75`, `s77`), `- **F1 — major** —` (`s26`), `- None. … Minor 1 …` (`s128:153`), `- Why I did not grade it critical:` (`s105:77`). Each is also a line `/po-ship`'s net sends to the person, so gate and net agree. Rewriting them is out of scope.
- `tests/lib.sh:27-29` — `has_tool` is `grep -qx` on each tool line: a line `Bash(…)` is not `Bash`.
- Only one blocked review was ever recorded (`s75`), and its last block is complete: no real fixture of a blocked report.

## Traps
- Tests outside `Owns` that pin changed files: `review.test.sh:23`, `:38` (no Bash), `:46`; `review-lenses.test.sh:85-86`; `hooks-installer-docs-cleanup.test.sh:57`; `everything-in-issues.test.sh:130`, `:181-184` (`- title:` / `- body:` lines, `'marked "not filed: shape not recognised"'`, `'a list item whose first line holds the word ... without opening with it'`); `final-leftovers.test.sh:7` (reviewer phrases); `qa-fleet.test.sh:110-121` (po-review and po-drive phrases, incl. `- Any other \`Ship allowed: no\` → "Ship blocked for <id>. Run /po-execute <id> (fix run)`); `resume.test.sh:11-36` ("No research, plan, record or review is overwritten", the fix-run row text); `fleet-wiring.test.sh:68` is po-status, untouched.
- `tests/overlap.test.sh`: new method text in our own words.
- Appending in `/po-review` goes through Write, which rewrites the whole file: earlier content must stay byte for byte.
- The re-ask is a new reviewer context: it must read its previous answer from the file, and take its tree again.
- `.claude/`, `.polype/` are installed copies: never edited.

## Open questions
- How `/po-review` runs the check (ADR-0094, three ranked options) — for the person.
- Does a narrowed `Bash(.polype/hooks/po-gate.sh findings-shape:*)` entry match `cd <worktree> && .polype/hooks/po-gate.sh findings-shape <id>` without a permission prompt? Command `allowed-tools` pre-approve rather than restrict (ADR-0027, Neutral), so a miss costs a prompt, not a failure.
- `po-orchestrator.md:78` on a later run (see Structuring facts): a follow-up for the tracker, not this story.
- `- Major — …` passes the gate (any case) while `po-ship.md:90`'s sed keeps `Major —` in the title: a cosmetic drift, left as is.

## Complexity
Story 3 → 4: six method files, an awk parser with five boundary rules, a resume row and a blocked-report rule the story leaves implicit, a tool-contract choice, and a flow/orchestrator inheritance that holds only through where the rule is written.

## Split
Not needed at 4.
