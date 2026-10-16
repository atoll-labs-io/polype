---
validated: yes
---
# Plan — s141-review-findings-shape

[Story](../stories.md) · [Research](../research/s141-review-findings-shape.md)

Branch `story/s141-review-findings-shape`. Read `docs/research/s141-review-findings-shape.md` first; this plan builds on it without repeating it.

Technical choice settled by the owner on 2026-10-16: option 1, a Bash permission narrowed to `.polype/hooks/po-gate.sh findings-shape`; ADR-0094 accepted. The tasks below already follow it.

The choice: how `/po-review`, which has no shell (`po-review.md:4-9`, pinned by `tests/review.test.sh:38`), runs `po-gate findings-shape`. Drafted in `docs/decisions/ADR-0094-la-forme-d-une-revue-se-controle-a-l-enregistrement.md` (`status: proposed`), options ranked: (1) a Bash permission narrowed to that one call, (2) full Bash for `/po-review`, which needs `tests/review.test.sh` added to `Owns`, (3) `/po-review` applies the rules itself with Grep. The tasks below are written for option 1. Under option 2, task 3's frontmatter line becomes `  - Bash`, and `tests/review.test.sh:38` plus the `AGENTS.local.md` convention change, after the story's `Owns` is corrected; under option 3, task 3 drops the frontmatter line and the gate call in `/po-review` only.

## Story
Fixes #112. The review template shows the exact finding line `/po-ship` reads; `po-gate findings-shape <id>` checks the last review's `## Findings` as soon as it is recorded; a bad shape goes back to the reviewer once, then to the person through a blocked report that survives a restart; `/po-ship`'s net also catches headings; ADR-0094 says why. Criteria: `template_shows_the_line`, `gate_checks_findings_shape`, `recording_runs_the_check`, `ship_net_catches_headings`, `adr_records_the_shape_check`.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| `findings_shape()` in `po-gate.sh` | new code, built on `top()` `:27`, `refuse()` `:28` and the verdict ERE `^([-*] )?Ship allowed:` of `:69`/`:72`, in one awk program like `paired_value` `:41-47` | no subcommand reads `## Findings` today; `paired_value` returns one value, not the lines of a section |
| Test fixtures | `docs/reviews/s137-modified-copy-survives-drop.md` and `docs/reviews/s138-mode-hint-cleanup.md`, copied into `scratch_repo` (`tests/lib.sh:46`) | — |
| Text in five method files and the ADR | no new code | — |

## Tasks
1. [x] **`po-gate findings-shape <id>`** in `method/hooks/po-gate.sh`: a function `findings_shape` beside `ship_allowed`, a `findings-shape)` arm in the `case` (`:474-482`, `"${2:?story id required}"`), and a header line in `:3-18` (`po-gate findings-shape <id>  0 when ## Findings of the last review holds no line that names a severity outside the shape /po-ship reads`). Behaviour:
   - No `docs/reviews/<id>.md` → `refuse`, exit 1. No line matching `^([-*] )?Ship allowed:` → `refuse "… has no verdict block"`, exit 1.
   - The block: lines after the previous verdict line, up to the last one. Inside it, `## Findings` (exact heading, trailing blanks allowed) runs to the next line starting with `## `; a `###` line stays inside. No such section → exit 1, message naming `## Findings`.
   - A severity is `critical|major|minor` as a whole word, any case: on `tolower(line)`, `(^|[^a-z0-9_])(critical|major|minor)([^a-z0-9_]|$)` (the `grep -w` word set; POSIX classes only, as the header of the floor guard asks, `:305-307`).
   - Each line of the section, in this order: starts with `#` → refused if it holds a severity; starts with a blank or tab, or is empty → continuation, accepted; starts with `- `, `* ` or `[0-9]+. ` → strip the marker, refused if the rest holds a severity and does not open with `(\*\*)?<severity>` followed by a non-word character or the end; any other line → refused if it opens with `(\*\*)?<severity>` likewise.
   - Each refused line is reported through `refuse` on stderr as `docs/reviews/<id>.md:<n>: <line>`, then a summary `po-gate: the findings of <id> are not in the shape of templates/review.md — …` and exit 1. Otherwise exit 0, silent. The location `<path>:<line>` is never checked.
   Test: `test_gate_checks_findings_shape`.
2. [x] **Template and reviewer.** `method/templates/review.md:55` becomes the fill-in line `- <critical|major|minor> — <path>:<line> — <the problem>`, followed by a placeholder line (in angle brackets, not starting with a severity or a list marker) saying: one finding per item, its continuation lines indented, never a heading, `none` when there is none, and keeping verbatim "a finding never starts with `Ship allowed:`". In `method/agents/reviewer.md` `## Your answer`, one sentence: each finding is one list item of `## Findings` in the shape `templates/review.md` shows, never a heading, because `po-gate findings-shape` checks it when the answer is recorded and `/po-ship` files only that shape. In `## When you cannot finish`, add that the blocked report keeps a `## Findings` section, `none` when empty. Every phrase pinned by `tests/final-leftovers.test.sh:7` and `tests/review.test.sh:50` stays. Test: `test_template_shows_the_line`.
3. [x] **`/po-review`** (`method/commands/po-review.md`). Frontmatter: add `  - Bash(.polype/hooks/po-gate.sh findings-shape:*)` (option 1; no bare `Bash` line). `## Recording`, a paragraph after `:36`, before the failure paragraph: once a reviewer's answer is written verbatim, run `cd <worktree> && .polype/hooks/po-gate.sh findings-shape <id>`; never on a blocked report this context wrote itself. Exit 1 → dispatch the reviewer once more, same model, the `## Delegation` prompt with the same `Fix loop: <n>` plus: "Your previous answer, recorded in docs/reviews/<id>.md, fails po-gate findings-shape <id> at: <the lines it quoted>. Answer again with the same Fix loop, each finding one list item `- <critical|major|minor> — <path>:<line> — <the problem>` as templates/review.md shows, never a heading." The new answer is added after the malformed block, which stays byte for byte (Write rewrites the whole file: keep everything before it); the re-ask spends no fix loop. A second exit 1 → append a blocked report: `Review status: blocked`, the same `Fix loop:`, `Failure cause:` quoting the refused lines, `Missing:` findings in the shape of `templates/review.md`, `Required adaptation:` a person rewrites or files them, `Next action: a person settles the findings shape — po-gate findings-shape <id> refused the reviewer twice`, then `Max severity: critical` and `Ship allowed: no`; the stop goes to the person at once. One sentence says that any command recording "as `/po-review` says" applies this check and its stop before its own fix-loop rules. `## Outcome`: a bullet before "Any other", for a blocked review whose `Next action:` names `po-gate findings-shape` → "Review of <id> stopped: the reviewer's findings failed their shape twice. A person settles them; no fix run is spent." Keep `:26`, `:38`, `:41-44` phrases (`tests/qa-fleet.test.sh:110-112`, `tests/review.test.sh:39-46`). Test: `test_recording_runs_the_check`.
4. [x] **`/po-drive`** (`method/commands/po-drive.md`). In `## The verdict, and the fix runs`, after `:135`: the same check through Bash on each recorded answer, the same single re-ask at the same `Fix loop:` with the quoted lines, no `Max attempts` unit spent, the answer appended after the malformed block; a second failure → the blocked report of task 3 appended through Bash, the lane handed to a human at once, the fleet carrying on. In `## Resuming`, a row inserted right before ``| review whose last `Ship allowed:` is `no` | a fix run, at loop `Fix loop:` + 1 |`` (`:63`): ``| `Review status: blocked` and a `Next action:` naming `po-gate findings-shape` | a human — the reviewer's findings failed their shape twice; no fix run, no `Max attempts` unit |``. Keep every phrase `tests/resume.test.sh` and `tests/qa-fleet.test.sh:118-121` pin. Test: `test_recording_runs_the_check`.
5. [x] **`/po-ship` net** (`method/commands/po-ship.md:87`): insert a clause into the list of lines that go to the person — a heading, a line starting with `#`, that holds the word `critical`, `major` or `minor`, in any case — without rewording any existing word of the sentence (`tests/everything-in-issues.test.sh:181-184`); "No critical or major finding." stays exempt; `:86`, `:90-91` unchanged. Test: `test_ship_net_catches_headings`.
6. [x] **ADR-0094**: once the person has chosen, `/po-plan` sets `status: accepted` and the "Comment `/po-review`…" paragraph records the option chosen; the implementer only aligns the ADR with the code if a detail moved. Test: `test_adr_records_the_shape_check`.
7. [x] **Tests**: `tests/review-findings-shape.test.sh`, five functions named after the criteria (strategy below); run it alone, then the full suite once with `po-run`.

## Scene viewpoints
—

## Run interdicts
- `.claude/` and `.polype/` end with an empty diff (installed copies).
- No file under `docs/reviews/` changes: existing reviews are not rewritten, even those the new gate would refuse (`s26`, `s36`, `s47`…, research `## Verified interfaces`).
- `method/commands/po-orchestrator.md` and `method/commands/po-flow.md`: empty diff.
- Under option 1, every test file other than `tests/review-findings-shape.test.sh` ends with an empty diff, `tests/review.test.sh` included.
- `ship_allowed`, `paired_value`, `pre_commit` and `floor_guard` of `po-gate.sh` keep an empty diff.
- The `- title:` and `- body:` lines of `po-ship.md:90-91` are byte-identical.
- `/po-review` gets no bare `Bash` line and no `Edit`.

## The pivot
The gate must refuse exactly what `/po-ship` step 3.2 cannot read, and nothing it can; ADR-0094 and the template rest on that alignment.
- Too strict: a shape step 3.2 reads gets refused. Compare against the shapes of `tests/everything-in-issues.test.sh:144-150`, notably `- **minor:** colon in bold` (opening `**minor` followed by `:`), and against s138.
- Too loose: a line step 3.2's net would hold passes. Compare against the three refused cases and s137 `:65`, `:86`; a `## ` heading after `## Findings` must close the section, a `###` must not.
- A blocked report with no `## Findings` (the reviewer's own, `reviewer.md:40-46`) would be re-asked, then sent to the person instead of back to QA: task 2 makes the reviewer keep the section, and task 3 never checks the report the recording context composed itself. The reviewer should check both sentences exist.

## Files touched
`method/hooks/po-gate.sh`, `method/templates/review.md`, `method/agents/reviewer.md`, `method/commands/po-review.md`, `method/commands/po-drive.md`, `method/commands/po-ship.md`, `docs/decisions/ADR-0094-la-forme-d-une-revue-se-controle-a-l-enregistrement.md`, `tests/review-findings-shape.test.sh`, plus this plan and the research.

## Test strategy
Five automated tests, within `Test budget: 25`, one file, conventions of `tests/lib.sh`; no visual check.
- `test_gate_checks_findings_shape` (the rule lives in the gate, so the bulk is here; runs `bash "$METHOD/hooks/po-gate.sh" findings-shape s01-a` in `scratch_repo`): the s137 fixture exits 1 and its output holds `:65:` and `### F1: major.`; s138 exits 0; refused, one at a time: `### F1: Major.`, `- see the major point`, `**minor** — x` outside a list, `Critical: x` outside a list, no `## Findings`; accepted: `- major —`, `- **major** —`, `1. **minor**:`, `* minor:`, `  - an indented major sub-bullet`, a blank line, `none`, `None.`, `No critical or major finding.`, `- the majority of cases`, a `## Not verified` heading followed by `### Critical` (outside the section); only the last block counts (a malformed block followed by a well-formed one → 0, the reverse → 1).
- `test_template_shows_the_line`: `review.md` holds `- <critical|major|minor> — <path>:<line> — <the problem>` inside its `## Findings` section and the word heading; `reviewer.md` names `po-gate findings-shape` or `templates/review.md` with heading, and the blocked report's `## Findings`.
- `test_recording_runs_the_check`: `po-review.md` holds the narrowed `Bash(` frontmatter line and no bare `Bash`, `findings-shape <id>`, the same `Fix loop:`, the appended answer, the `Next action:` text and its Outcome bullet; `po-drive.md`'s verdict section names the check and "no `Max attempts` unit", its resume table holds the new row **above** the fix-run row (line numbers compared).
- `test_ship_net_catches_headings`: the net sentence of `po-ship.md` holds the heading clause and still the phrases pinned at `everything-in-issues.test.sh:181-184` and "No critical or major finding.".
- `test_adr_records_the_shape_check`: ADR-0094 exists and names the check at recording, the template option and the refusal by `po-gate ship-allowed`, each with its reason.
Full suite: `po-run --story s141-review-findings-shape --label 'Full suite' -- 'bash tests/run.sh'`, once, at the end. `Typecheck: —`: none.

## Done when
The five criteria hold and their tests pass with the full suite green; one implementer commit carrying code, research, plan, ADR and record; a review with no open critical finding; shipped through a pull request that closes #112.
