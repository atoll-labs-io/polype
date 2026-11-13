# Research — s167-record-writes-reports

[Story](../stories.md)

## Structuring facts
- **Root cause (diagnostic, the story carries `Corrige`):** the recording of a review or QA report is a procedure restated in prose in five command files, each copy executed by a model, with no executable owner. Each fix of one copy (s156, s158) left the others diverging: `method/commands/po-drive.md:107` transcribes the QA answer before confirming the branch while `method/commands/po-qa.md:41-42` confirms first (#181); `po-drive.md:107` sends the QA transcription to "as you do a review", which now also writes a review header (#193); `po-qa.md:40` runs the evidence commit only on a fresh answer, yet `po-drive.md:58` and `po-orchestrator.md:77` send there with no answer (#180); `po-orchestrator.md:70` lists `/po-qa`'s steps without the transcription (#172); the QA header is whatever the subagent typed (`method/agents/qa.md:61`, from its title) (#191); `method/templates/review.md:42-43` has no line for `po-gate oracle-intact` (#186).
- `po record` exists only as a stub: `po/src/record/mod.rs:5-7` returns `not-built`; `po/src/main.rs:25` already routes `record` to it. Nothing else in the crate needs to change.
- `Project::find` resolves to the **main checkout**, never the worktree (`po/src/project.rs:38-48`, `--git-common-dir`). `po record` must write into the worktree, so it takes the worktree from `git rev-parse --show-toplevel` of the current directory, not from `Project::root`.
- A coordinator can only hand a multi-line answer to `po` through stdin, i.e. a quoted heredoc: `/po-qa` and `/po-drive` have no Write (`po-qa.md:4-9`, `po-drive.md:4-10`). The heredoc stays (one line), the header, ordering and checks leave the prose.
- About 25 test files outside `Owns` freeze phrases inside the very sections this story shortens (see `## Traps`); `tests/review-findings-shape.test.sh:74` even freezes po-review's `allowed-tools` line.

## Story
`po record review <id>` and `po record qa <id>` read the subagent's answer on stdin and write `docs/reviews/<id>.md` or `docs/qa/<id>/report.md`: template title and link line with `<id>` replaced, then the answer verbatim, never a doubled header (`record_writes_header_then_answer`); a `Method version:` line from `.polype/version`, written by `po` (`record_stamps_the_method_version`); review → runs `po-gate findings-shape` on what it wrote and exits with its code, qa → refuses an answer without `QA status:` and writes nothing (`record_checks_the_shape`); off `story/<id>` → exit 2, nothing written (`record_refuses_the_wrong_branch`); review → adds under `## Tests` the result of `po-gate oracle-intact <id>`, run by itself (`record_notes_the_oracle_gate`). Model-read: the five commands record through `po record` and lose their transcription prose, each file fewer words (`commands_call_po_record`); the two #180 resume paths rerun `po record qa` on the report on disk or say why not (`resume_paths_reuse_the_report`).

## Diagnostic
Reproduction: by reading, no file created. Each issue's text quotes the lines above; all lines were opened at commit `c96349e` (the lane was fast-forwarded to `553160a` since, which changes only `docs/stories.md`) and still say what the issues report (`po-drive.md:107` order, `po-orchestrator.md:70` "No report → stop", `po-drive.md:58` resume row, `templates/review.md:43` Floor line alone under `## Tests`).

| Hypothesis | Observation that would refute it | Result |
| --- | --- | --- |
| H1 — six independent wording slips, each fixable in its file | the fixes of s156/s158 left no new divergence | **discarded**: #180, #181 came from s156's own review, #193 from s158's, each fix spawning the next slip |
| H2 — the subagents omit or mangle the header, the coordinator is fine | a QA report header written by the coordinator | **discarded**: no command writes a QA header at all (`po-qa.md:42` writes "the answer whole"), and review headers broke when the coordinator wrote them (#168, ADR-0104) |
| H3 — a missing gate: `po-gate` should refuse a malformed header | ADR-0104 kept a gate refusal | **discarded** as the fix: ADR-0104 turned that option down (every slip becomes a stop for the person); the shape gate exists only for findings |
| H4 — one procedure, five prose copies, no executable owner | a single file that every command delegates to and that holds the procedure | **kept**: no such file exists; `po-review.md:37-43`, `po-drive.md:107,136-140`, `po-qa.md:39-46`, `po-orchestrator.md:70-77`, `po-flow.md:89` each restate or point at parts of it |

## Current code
- `po/src/main.rs:10-35` — verb dispatch; `record` → `record::main(&rest)`.
- `po/src/output.rs:38-87` — `CONTRACT`, `OK`/`REFUSED`/`UNREADABLE`, `reply(body, code)` (flattens a `Serialize` body beside `contract`), `error(code, error, message)`, `not_built`. `REFUSED` carries `#[allow(dead_code)]` (line 41): first user may be record.
- `po/src/project.rs:20-33` `git(dir, args)` read-only git helper (pub); `:38` `Project::find`; `:86` `method_version()` reads the **root's** `.polype/version`.
- `po/src/state/lanes.rs:119-131` — private `gate()` runs `bash <lane>/.polype/hooks/po-gate.sh <name> <id>` with `current_dir(lane)`, `GIT_OPTIONAL_LOCKS=0`. Not reachable from `record/` (private, inside `state/`, which the story forbids touching).
- `method/hooks/po-gate.sh:97-132` `findings_shape`: reads `$(top)/docs/reviews/<id>.md`; checks only the last verdict block (between the last two `Ship allowed:` lines); exit 0 kept, 1 with each refused line on **stderr** as `<rel>:<n>: <text>`, 2 when it cannot run; a block with no `## Findings` → exit 1 (`:127`).
- `po-gate.sh:594-664` `oracle_intact`: reads plan, oracle files and record **from the commit `story/<id>`**, never the work tree; exit 0 silent when intact, 0 with a stdout line `po-gate: <id> has no oracle: …` when none, 0 with stdout lines for logged changes, 1 with stdout lines per unlogged change, 2 on stderr when it cannot run.
- `po-gate.sh:211-237` `qa_current` reads `docs/qa/<id>/report.md`: last `QA status:` and its paired `Tree:`; it ignores everything else in the file.
- `method/templates/review.md:1-3` title, blank, link line (3 links: `../stories.md`, `../plans/<id>.md`, `../verif/<id>.md`); `:5` the note excluded from the reviewer's answer (`method/agents/reviewer.md:53`); `:42-47` `## Tests` checklist.
- `method/templates/qa.md:1-3` title, blank, link line (`../../stories.md`, `../../plans/<id>.md`). The qa subagent returns its report from that title on (`method/agents/qa.md:52,61`); the reviewer starts below the header (`reviewer.md:53`).
- `method/commands/po-review.md:10` narrowed `Bash(.polype/hooks/po-gate.sh findings-shape:*)`; `:36-43` `## Recording` (header, verbatim, shape check, re-ask, blocked reports); `:32` the delegation prompt.
- `po-qa.md:39-46` `## The evidence commit`: branch check, heredoc into `report.md`, `git add`, commit with pathspec; `:17` "Bash serves exactly two uses".
- `po-drive.md:57-58` resume rows (blocked QA, `is current but` → evidence commit without a walk); `:107` QA stage item; `:136-140` verdict section.
- `po-orchestrator.md:70` stage 6, `:73` stage 7 records "as `/po-review` says", `:77` blocked on QA evidence.
- `po-flow.md:89` records "as `/po-review` says".

## Attachment points
- `po/src/record/mod.rs` — `pub fn main(args: &[String]) -> i32`, signature fixed by `main.rs:25`; submodules go under `po/src/record/`.
- `<worktree>/.polype/hooks/po-gate.sh` (subcommands `findings-shape`, `oracle-intact`), `<worktree>/.polype/templates/{review,qa}.md`, `<worktree>/.polype/version` — all committed in a Polype project (`git ls-files .polype` here lists hooks and templates).
- How commands call `po`: `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po` (`docs/installation.md:76-79`, `docs/interface-agent.md:10-12`). No method file calls `po` yet: s167 is the first.

## Verified interfaces
- Crate deps: `serde`, `serde_json`, `chrono` only (`po/Cargo.toml`, ADR-0118); everything record needs is in `std` (`process::Command`, `fs`, `io::Read`).
- Tests: `tests/lib.sh:7` defines `PO`; `tests/run.sh:19-23` builds `po` once before the suite; `tests/lib.sh:29` `lacks_tool` matches a whole tool line, so narrowed `Bash(...)` entries do not count as `Bash`. Fixture pattern of an oracle that launches `po`: `tests/state-as-json.oracle.test.sh:9-60` (`need_po`, `po_in`, `one_object`, `fixture` copying `method/hooks/po-gate.sh` into `.polype/hooks/`).
- Word counts at `c96349e` (`LC_ALL=C wc -w`): `po-review.md` 1244, `po-qa.md` 724, `po-orchestrator.md` 1908, `po-flow.md` 1572, `po-drive.md` 5470, `templates/review.md` 558, `templates/qa.md` 278.

## Traps
- **Frozen phrases outside `Owns`** (kept verbatim, whatever is cut around them):
  - `tests/review-findings-shape.test.sh:74-92,136-142`: po-review frontmatter line `  - Bash(.polype/hooks/po-gate.sh findings-shape:*)` and no bare `Bash`; `## Recording` holds `.polype/hooks/po-gate.sh findings-shape <id>`, ``at the same `Fix loop: <n>` ``, `appended after the malformed block, which stays byte for byte`, `This re-ask spends no fix loop.`, both `Next action:` strings, `never checked`, `Any other exit`, `is not a malformed review: the reviewer is not dispatched again`; po-drive verdict section holds ``checked through Bash with `po-gate findings-shape <id>` on that lane's worktree``, ``no `Max attempts` unit is spent; its new answer is appended after the malformed block``, `Any other exit is not a malformed review: the reviewer is not asked again`, and the findings-shape resume row before the fix-run row.
  - `tests/drive.test.sh`: po-drive keeps ``recorded **verbatim** into `docs/reviews/<id>.md` ``, `You transcribe it, you do not author it`, `no severity is yours to choose, no finding yours to soften or drop`, ``answers without both verdict lines is recorded as `Review status: blocked` ``, `` `Max severity: critical` and `Ship allowed: no` ``, `You have neither Write nor Edit, so you write no code and decide no verdict`.
  - `tests/qa-fleet.test.sh`, `qa-gate.test.sh`, `qa.test.sh`, `resume.test.sh`, `resume-shape-stop.test.sh`, `model-routing.test.sh`, `pilot.test.sh`, `surface-routing.test.sh`, `execute.test.sh`, `floor-guard.test.sh`, `review.test.sh`, `review-lenses.test.sh`: phrases in po-orchestrator stage 6-7, po-qa (`This command never authors a report`, ``commit -m "<id>: QA evidence" -- docs/qa/<id>/``, `` rev-parse --abbrev-ref HEAD` must print `story/<id>` ``), po-drive `:57-58,73,107`, the template's `## Tests` Floor line (`templates/review.md:43`). The phrase map was computed by script; it may miss phrases checked through unusual helpers, so `grep -rlF '<fragment>' tests/` before deleting any sentence.
- **Owned tests that freeze the old mechanism**: `tests/review-header-recorded.oracle.test.sh` (s158's oracle; `test_recorder_writes_the_header`, `test_drive_writes_the_header`, the note phrase in `test_template_marks_the_header`) and `tests/qa-report-returned-as-text.test.sh` (`test_po_qa_records_the_report`, `test_drive_records_the_report`: heredoc into `report.md`, `quoted heredoc`, line order). `tests/review-header-recorded.test.sh` does not exist.
- **s164's oracle pins `record` to `not-built`**: `tests/state-as-json.oracle.test.sh:151-156`, in `test_state_prints_one_json_object`, loops over `next inbox answer record run continue` and requires each verb to exit 2 with `"error": "not-built"` (`:155`). Once `po record` is built it answers `usage` there (no arguments), so that test fails whatever the code does. PR #252 (`553160a`) put the file in this story's `Owns` (and in s165, s166, s168, s169's). s165 ships first and takes `inbox` out of the same loop, so the loop will have changed again before s167 is implemented.
- `oracle-intact` reads the **commit** `story/<id>`: at review time the code is committed, but an oracle line taken on an uncommitted plan says `exit 2`.
- `findings-shape` writes its refused lines on stderr, not stdout; `po` must capture them, since `po`'s stdout is one JSON object (`docs/interface-agent.md:28`).
- A blocked report the coordinator composes (failure, second shape refusal, gate unrunnable) has no `## Findings`: `findings-shape` would refuse it (`po-gate.sh:127`), and `/po-review` says it is never checked (`po-review.md:41`). `po record review` needs a way to record it unchecked.
- Re-recording a report onto itself (`po record qa <id> < report.md`, the #180 resume path) reads and writes the same file: read all of stdin first, write through a temp file and rename.
- The direction rule (`AGENTS.local.md:74`, "Do not"): no new phrase test, and an owned template must not grow in words.
- `.polype/` in this repository is an installed copy: `po record` here reads `.polype/templates/review.md`, not `method/templates/review.md`, until the next `bin/polype-dev-install`.
- No migration; no dependency added.

## Open questions
- Whether a `Bash(...)` rule in `allowed-tools` matches a command that starts with `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po"` (a parameter expansion) without a permission prompt was not verified against Claude Code's documentation. If it does not match, `/po-review` asks for permission once per recording; nothing breaks.
- Whether s170 prefers a classification word (`intact`, `changed-with-reason`, `none`) on the oracle line over the gate's exit and output: the plan records exit and output, from which the three values follow.

## Complexity
Story 3 → **4** after reading: the binary part is small, but the prose part cuts five files under about 25 phrase-freezing tests outside `Owns`, and the review recording has four distinct paths (first write, append, re-ask, composed blocked report). No split: about eight tasks.

## Split
— (score below 5)
