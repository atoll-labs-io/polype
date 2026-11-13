---
validated: yes
---
# Plan — s167-record-writes-reports

[Story](../stories.md) · [Research](../research/s167-record-writes-reports.md)

Branch `story/s167-record-writes-reports`. Read `docs/research/s167-record-writes-reports.md` first; this plan builds on it without repeating it. Root cause (research, `## Structuring facts`): the recording is one procedure restated in prose in five commands, with no executable owner. The fix gives it one: `po record`.

## Story
`po record review <id>` and `po record qa <id>` read the subagent's answer on stdin and write the report themselves — template header, `Method version:` stamp, the answer verbatim, the shape check (review) or the `QA status:` check (qa), the oracle line (review) — and refuse off `story/<id>`. The five commands pipe the answer into `po record`, lose their transcription prose and words, and the two #180 resume paths re-record the report on disk. Criteria: `record_writes_header_then_answer`, `record_stamps_the_method_version`, `record_checks_the_shape`, `record_refuses_the_wrong_branch`, `record_notes_the_oracle_gate`, `commands_call_po_record`, `resume_paths_reuse_the_report`.

## The interface these tasks fix
- Run **inside the story worktree**: `po record review <id> [--composed]`, `po record qa <id>`; the answer on stdin. The worktree is `git rev-parse --show-toplevel` of the current directory (never `Project::root`, which is the main checkout, `po/src/project.rs:38-48`).
- Files written: `<worktree>/docs/reviews/<id>.md`, `<worktree>/docs/qa/<id>/report.md`.
- Layout of a first write: template title line, blank, link line, blank, `Method version: <v>`, blank, the answer. Appending to an existing review: one blank line, `Method version: <v>`, blank, the answer. A QA report is always rewritten whole.
- `<v>` is the first line of `<worktree>/.polype/version`, trimmed.
- Header from `<worktree>/.polype/templates/<review|qa>.md`: its first two non-empty lines, `<id>` replaced; a link `[Label](target)` whose target does not exist relative to the report's folder is dropped with its ` · ` separator; a link line left empty is omitted.
- The answer's own header is dropped before writing: its leading lines, as long as each is blank, a title starting `# Review` or `# QA`, a line starting `[Story](`, or a line starting `Method version:`. The first other line and everything after it are kept byte for byte.
- Review, without `--composed`: the line ``- Oracle: `po-gate oracle-intact <id>` → exit <n>`` then each line the gate printed (stdout, then stderr), indented by two spaces, inserted right after the answer's first `## Tests` line; no `## Tests` line → a `## Tests` section holding them is inserted before the first `## Findings` line; neither → before the first `Max severity:` line; none of these → at the end. Gate script missing → ``- Oracle: `po-gate oracle-intact <id>` → not run: .polype/hooks/po-gate.sh is missing``.
- Gates run as `bash <worktree>/.polype/hooks/po-gate.sh <sub> <id>`, `current_dir` the worktree, stdin null, as `po/src/state/lanes.rs:120-131` does.
- Replies (one JSON object, `output::reply`): success `{"contract":1,"path":"docs/…","method_version":"<v>"}`, exit 0. Refusals carry `error`, `message`, `written`:

| `error` | exit | written | when |
| --- | --- | --- | --- |
| `usage` / `unknown-option` | 2 | no | kind not `review`/`qa`, no id, an id holding `/` or starting with `.`, `--composed` on `qa`, any other argument |
| `not-a-project` | 2 | no | `Project::find` gives `None` |
| `wrong-branch` | 2 | no | HEAD of the worktree is not `story/<id>` |
| `no-method-version` / `no-template` | 2 | no | `.polype/version` or the template missing or unreadable in the worktree |
| `empty-answer` | 1 | no | stdin holds only whitespace |
| `no-qa-status` | 1 | no | qa answer with no line starting `QA status:` |
| `findings-shape` | 1 | yes | the gate exits 1; adds `refused`, the gate's stderr lines |
| `findings-shape-unrunnable` | 2 | yes | the gate exits 2, any other code, or cannot start; `message` carries its stderr |

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Project check, settings-free | in repo: `Project::find` (`po/src/project.rs:38`) | — |
| Worktree root, branch | in repo: `project::git` (`po/src/project.rs:20`) | — |
| JSON replies | in repo: `output::reply`, `output::error` (`po/src/output.rs:67,72`) | — |
| Running a gate with its output | new code in `po/src/record/` | `state::lanes::gate` (`lanes.rs:120`) is private, discards output, and lives in a folder this story may not touch; std `process::Command` holds the rest |
| Atomic write (temp file in the same folder, then rename) | std `fs::write` + `fs::rename` | no helper in the crate writes a file yet |
| Header strip, link drop, oracle insertion | new code, line operations on `&str` | no regex crate (`po/Cargo.toml`, ADR-0118) and none needed |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/record-writes-reports.oracle.test.sh` | `2236172868 10865` |

| Criterion | Test |
| --- | --- |
| `record_writes_header_then_answer` | `test_record_writes_header_then_answer` |
| `record_stamps_the_method_version` | `test_record_stamps_the_method_version` (also re-records a QA report onto itself, the #180 resume path) |
| `record_checks_the_shape` | `test_record_checks_the_shape` |
| `record_refuses_the_wrong_branch` | `test_record_refuses_the_wrong_branch` |
| `record_notes_the_oracle_gate` | `test_record_notes_the_oracle_gate` |
| `commands_call_po_record` | — rule read by a model: judged in review; `tests/record-writes-reports.test.sh` only checks word counts; candidate for a `po-eval` control arm (#208) |
| `resume_paths_reuse_the_report` | — same regime; candidate for a `po-eval` control arm |

The oracle launches the built `po` on a scratch project whose gate and templates are copies of `method/`; it was run against a throwaway mock of the interface above (5/5) and against five broken mocks (each caught), never against code in this tree.

## Tasks
1. [x] **Arguments and refusals** — `po/src/record/mod.rs`: parse `review|qa <id> [--composed]`; `Project::find` on the current directory; worktree from `git rev-parse --show-toplevel`; `git rev-parse --abbrev-ref HEAD` must equal `story/<id>`; read `.polype/version` and the template; read all of stdin. Every refusal of the table above that writes nothing happens before any write. `output.rs` stays as it is, its `#[allow(dead_code)]` on `REFUSED` included. Test: `test_record_refuses_the_wrong_branch`.
2. [x] **Composition and the QA report** — header, link drop, own-header strip, stamp, layout and atomic write as `## The interface` says; `po record qa` refuses `no-qa-status`, creates `docs/qa/<id>/`, rewrites the report whole. Tests: `test_record_writes_header_then_answer`, `test_record_stamps_the_method_version`, and the qa half of `test_record_checks_the_shape`.
3. [x] **Review: oracle line, shape check, `--composed`** — run `oracle-intact` before writing and insert its line; write (first write or append); then run `findings-shape` and map its exit as the table says. `--composed` (a blocked report the coordinator wrote) skips both gates and exits 0 once written. Tests: `test_record_notes_the_oracle_gate`, the review half of `test_record_checks_the_shape`; in `tests/record-writes-reports.test.sh`: `test_composed_report_is_not_checked` (a blocked report with no `## Findings` exits 0, holds no `- Oracle:` line), `test_missing_link_is_dropped` (no `docs/verif/<id>.md` → the review's link line has no `[Verification]`).
4. [x] **`/po-review`** — `## Recording` becomes: pipe the answer, whole, into `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" record review <id>` run in the worktree, through a quoted heredoc whose delimiter no line of the answer equals; `po record` writes the header, the stamp and the oracle line, runs `.polype/hooks/po-gate.sh findings-shape <id>` and exits with its code; the blocked reports this context composes go through `po record review <id> --composed` and are never checked; `po` missing, or a refusal with `"written": false` → stop, name `polype install`, write nothing by hand. Re-ask and blocked-report rules stay, shorter. Add `  - Bash("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" record review:*)` to `allowed-tools`, keeping the `findings-shape` line. Test: `test_commands_lose_words` (below).
5. [x] **`/po-qa` and the QA paths of `/po-drive`** — `po-qa.md` `## The evidence commit`: step 1 (branch) stays first, step 2 pipes the answer into `po … record qa <id>` (exit 1 → no report, no commit); with no new walk and a report on disk (a resume path), step 2 pipes that report back, `< <path>/docs/qa/<id>/report.md` (#180); `:17` and the `description` say "the record and the evidence commit". `po-drive.md:107` drops its own heredoc, branch order and "as you do a review" (#181, #193): the answer goes through `/po-qa`'s evidence commit as written; `po-drive.md:58` row: `po record qa` on the report on disk, then that commit, without a new walk. Test: `test_commands_lose_words`.
6. [x] **`/po-drive` verdict section, `/po-orchestrator`, `/po-flow`** — `po-drive.md:136-140` keeps only what `po record review` does not do (re-ask, blocked stops, verbatim duty) and names `po record review`; `po-orchestrator.md:70` names the record step of `/po-qa` and reads "no report" as an answer without a `QA status:` line (#172), `:77` re-records then commits (#180); `po-flow.md:89` records "as `/po-review` says" in fewer words. Test: `test_commands_lose_words`.
7. [x] **Template and owned tests** — `method/templates/review.md:5`: the note says `po record` writes the two header lines, the `Method version:` line and the `Oracle:` line under `## Tests` (#186), without the file gaining a word (558). In `tests/review-header-recorded.oracle.test.sh` remove the phrase assertions that froze the old mechanism: `test_recorder_writes_the_header` and `test_drive_writes_the_header` whole, and in `test_template_marks_the_header` the `holds` on the note's old wording (its position check stays, on the new note's first words). In `tests/qa-report-returned-as-text.test.sh` remove from `test_po_qa_records_the_report` the heredoc assertions (`<<'`, `no line of the answer equals it`, the `cat >` line and its order) and from `test_drive_records_the_report` `word for word into …report.md` and `quoted heredoc`. No new phrase assertion replaces them (`AGENTS.local.md:74`). In `tests/state-as-json.oracle.test.sh` (s164's oracle, in `Owns` since PR #252), `test_state_prints_one_json_object` loops `for verb in … ; do` (`:151`) and asserts `.error == "not-built"` with exit 2 for each (`:152-155`): take `record` out of that verb list, whatever the list holds by then (s165 ships first and will already have taken `inbox` out), and change nothing else in the file. Without this, the test fails as soon as `po record` exists. Test: `test_state_prints_one_json_object` itself, still checking the verbs that remain unbuilt.
8. [x] **Words, and the full suite** — `tests/record-writes-reports.test.sh` `test_commands_lose_words`: `LC_ALL=C wc -w` below 1244 (`po-review.md`), 724 (`po-qa.md`), 1908 (`po-orchestrator.md`), 1572 (`po-flow.md`), 5470 (`po-drive.md`), and at most 558 for `templates/review.md`. Then `po-run --story s167-record-writes-reports --label suite -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff: everything under `po/` except `po/src/record/` (`main.rs`, `output.rs`, `project.rs`, `state/`, `inbox/`, `next/`, `run/`, `trust/`, `Cargo.toml`, `Cargo.lock`).
- Empty diff: `method/hooks/po-gate.sh`, `method/agents/`, `method/skills/`, `method/templates/qa.md`, `docs/interface-agent.md`, `.polype/`, every ADR.
- Empty diff: every test file outside `Owns`. In `tests/state-as-json.oracle.test.sh`, the only change is `record` leaving the verb list at `:151`; each phrase the research lists under `## Traps` stays in its section, and `bash tests/run.sh` passes whole.
- `po-review.md` keeps `  - Bash(.polype/hooks/po-gate.sh findings-shape:*)` and gets no bare `Bash`; `po-qa.md` gets no Write or Edit.
- `po record` never commits, never stages, and runs no git command that writes; it runs only the two gates.
- No new crate dependency; no new ADR (ADR-0102 and ADR-0104 keep their rules: the coordinator records, the judging subagent writes nothing).
- The oracle file changes only through `## Oracle changes` of the verification record.

## The pivot
`po record` writes where the coordinator stands — the worktree found from the current directory, refused unless HEAD is `story/<id>` — and fixes the review's layout that s170 will read (one stamp per recorded block, the oracle line under that block's `## Tests`). How it could be wrong:
- Resolving the path through `Project::root` writes into the main checkout: `test_record_writes_header_then_answer` reads the file in the worktree.
- The own-header strip eats a real first line of an answer, or misses a header the qa subagent writes: compare with `method/agents/qa.md:61` (the qa answer starts at its title) and `reviewer.md:53` (the review answer starts below), and with `in_order` in the oracle.
- A composed blocked report run through `findings-shape` would turn every subagent failure into a shape stop (`po-gate.sh:127`): `test_composed_report_is_not_checked`.
- The narrowed `Bash(...)` rule may not match a command starting with a parameter expansion (research, `## Open questions`): the cost is a permission prompt in `/po-review`, not a failure; the reviewer checks the line is there, not that it matches.

## Files touched
`po/src/record/mod.rs` (and submodules under `po/src/record/`), `method/commands/po-review.md`, `po-qa.md`, `po-drive.md`, `po-orchestrator.md`, `po-flow.md`, `method/templates/review.md`, `tests/record-writes-reports.oracle.test.sh` (written), `tests/record-writes-reports.test.sh` (new), `tests/review-header-recorded.oracle.test.sh`, `tests/qa-report-returned-as-text.test.sh`, `tests/state-as-json.oracle.test.sh` (one word out of a verb list), `docs/research/…`, `docs/plans/…`, `docs/verif/…`.

## Test strategy
- Oracle (5): the binary on a scratch project, through its arguments, stdin, exit code, stdout and the files it writes — the only layer where these rules live.
- Implementer (3, `tests/record-writes-reports.test.sh`): `test_composed_report_is_not_checked`, `test_missing_link_is_dropped`, `test_commands_lose_words`. The last one is the word-count check the story asks for criteria 6 and 7, not a phrase test.
- Changed (3 files): assertions removed as task 7 lists, plus `record` out of the `not-built` loop of s164's oracle; no test added there.
- Total new: 8, within `Test budget` 25. No Rust unit tests: the rules are observable through the binary, and testing them twice buys nothing.
- No visual check (no screen).

## Done when
One commit on `story/s167-record-writes-reports` holding the code, the tests, the research, the plan and the record; `bash tests/run.sh` green through `po-run`; a review with no open critical finding; shipped through a pull request that closes #202, #172, #180, #181, #186, #191 and #193.
