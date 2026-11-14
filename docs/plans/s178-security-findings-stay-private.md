---
validated: yes
---
# Plan — s178-security-findings-stay-private

[Story](../stories.md) · [Research](../research/s178-security-findings-stay-private.md)

Branch `story/s178-security-findings-stay-private`. Read `docs/research/s178-security-findings-stay-private.md` first; this plan builds on it without repeating it.

The text of a security finding lives under the new setting `Private folder:` and the person removes it: [ADR-0123](../decisions/ADR-0123-le-texte-d-un-constat-de-securite-reste-hors-du-depot.md), `accepted` — option B chosen by the owner on 2026-11-14 (d-0020) against the proposed A, and the blocking rule of d-0021 b. The research's open question on the location and on `blocks` is settled by it; where the research assumed `XDG_STATE_HOME`, this plan wins.


## Story
A security finding found by a review stays on the machine, in the decision inbox; `docs/reviews/<id>.md` keeps only a count and the decision's id. Criteria: `security_findings_are_marked`, `recorded_review_holds_a_count_and_an_id`, `nothing_reaches_git`, `verdict_still_counts_them`, `earlier_reviews_read_the_same`, `fix_run_still_reads_them` (judged in review), `words_hold`.

Settled here (implementation; the setting's value and refusals are ADR-0123's):
- **The mark.** A security finding is the list item `- <critical|major|minor> — [security] — <path>:<line> — <the problem>` (also `* ` or `1. ` as the opener, exactly one space, em dashes), with its indented continuation lines. Any other occurrence of `[security]`, in any case, anywhere in the answer → refusal `security-shape`, exit 1, `"written": false`, `refused` holding `answer line <n>: …` with line numbers of the answer as given on stdin, never its text.
- **The count line.** `Security findings: <n> — decision <d-NNNN>`, a plain line (no list marker) right under `## Findings`, the marked items removed. `po-gate findings-shape` accepts it: a non-list line is refused only when its first word is a severity (`method/hooks/po-gate.sh:109,120`).
- **The decision.** `motive: security`, `sensitive: true`, question `<id>: <n> security finding(s) from its review wait for you`, options `fix-here` (recommended) / `hold` / `ship-later` as ADR-0123 words them, `why` one sentence, `reversible: true`, `context` the private file; `blocks: [<id>]` when a marked finding is `critical` or `major`, `[]` when all are `minor` (d-0021).
- **The setting** (ADR-0123): absolute, or starting with `~/` expanded from `HOME`; nothing else expanded (`$HOME/…` reads as relative). Resolved path relative, or inside the repository by `place()` (`po/src/inbox/add.rs:114-141`, root, `.git` and other worktrees) → `private-folder-unusable`, exit 1. Missing or `—` while the answer carries a mark → `no-private-folder-setting`, exit 2. Both: `"written": false`, message naming `Private folder`, nothing written anywhere. Without a mark, the setting is not read. Files under `<Private folder>/<Project::name()>/`, missing folders created 0700, an existing one left as is, file `<id>-<UTC %Y%m%dT%H%M%SZ>-<pid>.md` `create_new` 0600. Template value: `~/.local/state/polype/private/`.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| A decision posted from `po record` without printing | Already here: the body of `po/src/inbox/add.rs:16-64` and `locate()` (`po/src/inbox/mod.rs:107-129`), split into a returning core and a printing shell | — |
| "Inside the repository" for the setting | Already here: `place()` (`po/src/inbox/add.rs:114-141`), made `pub(crate)` | — |
| Reading the setting | Already here: `Project::setting` (`po/src/project.rs:54-67`) | — |
| Splitting the answer's `## Findings` | New code, `po/src/record/security.rs` | `po-gate findings-shape` (`po-gate.sh:98-136`) reads a file on disk: checking the answer there would first write the text into the worktree; its section rule is reused as the spec |
| Folder 0700, file 0600, never overwritten | Platform: `std::fs::DirBuilder` + `std::os::unix::fs::{DirBuilderExt, OpenOptionsExt}`, `create_new` | — |
| `~/` expansion | Platform: `std::env::var_os("HOME")` | no crate needed for one prefix |
| File stamp | Dependency installed: `chrono` (`po/Cargo.toml`) | — |
| Fixture version that follows `po` | Already here: `stamp()` of `tests/driver-next-action.oracle.test.sh:20` | — |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/security-findings-stay-private.oracle.test.sh` | `1977356923 8551` |

| Criterion | Test |
| --- | --- |
| `security_findings_are_marked` | `test_security_findings_are_marked` |
| `recorded_review_holds_a_count_and_an_id` | `test_recorded_review_holds_a_count_and_an_id` |
| `nothing_reaches_git` | `test_nothing_reaches_git` |
| `verdict_still_counts_them` | `test_verdict_still_counts_them` |
| `earlier_reviews_read_the_same` | `test_earlier_reviews_read_the_same` (`po state` trust signals: `po/src/state/`, `po/src/trust/` keep an empty diff, `tests/trust-signals.oracle.test.sh` stays green) |
| `fix_run_still_reads_them` | — a rule read by a model: judged in review; candidate for a `po-eval` control arm (#208) |
| `words_hold` | `test_words_hold` |

The oracle sources the s167 fixture (`tests/record-writes-reports.oracle.test.sh`, as `tests/record-writes-reports.test.sh:6` does), sets `Private folder:` to an absolute path in its scratch dir and `HOME` there too. Against `po` 0.2.0: the three new behaviours fail; `verdict_still_counts_them`, `earlier_reviews_read_the_same`, `words_hold` pass (they guard what must not move).

### Oracle changes
| Date | Change | Old cksum | New cksum |
| --- | --- | --- | --- |
| 2026-11-14 | Planner, before any code, for ADR-0123 option B: `secure_fixture` writes `Private folder: <scratch>/private/` instead of exporting `XDG_STATE_HOME`; `test_recorded_review_holds_a_count_and_an_id` also checks the text lies under that folder | `3648821969 8398` | `1977356923 8551` |

## Tasks
1. [x] **Inbox: a returning add.** In `po/src/inbox/mod.rs`, split `locate()` into a quiet core returning `Result<(Project, PathBuf), Refused>` (code, error, message) and the printing wrapper every verb keeps. In `add.rs`, move validate + sensitive check + `kept_out_of_git` + `write` into `pub(crate) fn post(project, dir, NewDecision) -> Result<Decision, Refused>`, same codes and messages; `main` keeps reading stdin and printing. Export what `record` needs (`NewDecision`, `Choice`, `Motive`, `post_decision`, `place`/`Place`). No behaviour of `po inbox …` changes. Test: `tests/decision-inbox.oracle.test.sh` green as is.
2. [x] **Record: read the mark.** New `po/src/record/security.rs`: from the stripped answer, find `## Findings` (first line equal to it, up to the next `## ` line or a `Max severity:`/`Ship allowed:` line, a leading `- `/`* ` allowed), take each marked item whole with its indented continuation lines and its severity, collect every other `[security]` line as malformed (numbers relative to stdin: add the lines `strip_own_header` dropped). Return the public body with a placeholder for the count line, the private text, the count, the highest severity. Test: `test_security_findings_are_marked`.
3. [x] **Record: move the text out, then write.** In `po/src/record/mod.rs`, for `Kind::Review` without `--composed`, between the strip (`:182`) and the oracle insertion (`:183`): malformed → `security-shape`. Count > 0 → (a) resolve `Private folder` as `## Story` settles, refusing `no-private-folder-setting` / `private-folder-unusable` before any write; (b) create the folder and the file; (c) `post_decision` with `blocks` per d-0021 — refused → remove the file, refuse with the inbox's `error` and code, `written: false`; (d) render the count line, then the oracle line, write, `findings-shape` as today. A write failing after (c) refuses `unwritable` naming the decision id. `Written` gains an optional `decision` field, absent when nothing moved. Tests: `test_recorded_review_holds_a_count_and_an_id`, `test_nothing_reaches_git`, `test_verdict_still_counts_them`, `test_earlier_reviews_read_the_same`.
4. [x] **Own tests**, `tests/security-findings-stay-private.test.sh`, sourcing the oracle inside each test (never at top level, as `tests/record-writes-reports.test.sh:6` does) to reuse `secure_fixture`:
   - `test_private_text_is_owner_only`: file `-perm 0600`, created folder `-perm 0700`.
   - `test_missing_private_folder_refuses_before_writing`: line removed, then `—` → `no-private-folder-setting`, exit 2, `written: false`, no review, no decision, the witness nowhere under the scratch dir but the answer's folder; an answer with no mark still records.
   - `test_unusable_private_folder_is_refused`: `Private folder:` set to a relative path, to `$HOME/x` literally, to a folder under `$F`, under `$F/.git` → `private-folder-unusable`, nothing written.
   - `test_tilde_is_expanded_from_home`: `~/p/` → the file lies under `$HOME/p/<project name>/`.
   - `test_only_critical_or_major_holds_the_lane`: a `minor` mark alone → `blocks == []`; a `major` → `blocks == ["s01-a"]`.
   - `test_no_inbox_refuses_before_writing`: no `Decision inbox` → `no-inbox-setting`, `written: false`, no file left under the private folder.
5. [x] **Version 0.3.0** in `po/Cargo.toml:3`, `po/Cargo.lock:165`, `bin/polype:27` (ADR-0122). Replace the literal `0.2.0` written as a fixture `.polype/version` at `tests/state-carries-session-lines.oracle.test.sh:83,204` and `tests/project-lead.test.sh:103` by the version `bin/polype` carries (`stamp()` of `tests/driver-next-action.oracle.test.sh:20`). Leave `tests/trust-signals.oracle.test.sh:76,168` and `tests/commands-read-po-state.oracle.test.sh:59,69,131,134`: fixture text compared with itself. Tests: those two files green.
6. [x] **The reviewer marks.** `method/templates/review.md` `## Findings` note: a finding bearing on security opens `- <severity> — [security] — `, `po record` keeping its text off the repository. `method/skills/review-lenses/SKILL.md:26`: a Security lens finding carries that mark. `method/agents/reviewer.md` `## Your answer`: any finding bearing on security carries the mark whatever found it, its text appears nowhere else in the answer; on a fix loop, a `Security findings:` line of the previous review names a decision whose text `po inbox <id>` and its `context` give: say each one lifted, by the decision id, or mark it again, never copying it. Tests: `tests/review-findings-shape.test.sh`, `tests/review-header-recorded.oracle.test.sh`, `tests/review.test.sh`, `tests/wiring.test.sh`, `tests/review-lenses.test.sh`, `test_words_hold`.
7. [x] **`/po-review` records it.** `method/commands/po-review.md` `## Recording`: `po record` moves marked findings to the inbox and leaves the count line; `security-shape` (nothing written) takes the exit-1 path — the reviewer re-asked once with its `refused` answer lines, nothing appended — then the same blocked report; any other `"written": false` refusal stops with its `error` (`no-private-folder-setting` and `private-folder-unusable` go to the person: the setting is theirs). Keep every phrase `tests/review-findings-shape.test.sh:74-84,130-133` and `tests/review-header-recorded.oracle.test.sh:23` pin. Tests: those files, `tests/record-writes-reports.test.sh` (`test_commands_lose_words`), `test_words_hold`.
8. [x] **The fix run reads it.** `method/agents/implementer.md` `## Fix runs` (`:30`): a `Security findings:` line names a decision; its text is the file `po inbox <id>` gives as `context`; fix it, never copying that text into the repository, a commit message, the record or a test — a test uses a meaningless witness. `method/commands/po-execute.md`: change only a sentence the rule makes false (`:54` defers to the agent file and may stay). Keep `implementer.md:24` (`tests/execute.test.sh:43`), the record sentence (`tests/run-ledger.test.sh:150`), `po-execute.md`'s "A fix run follows the same rule…" (`tests/model-routing.test.sh:61`). Check once that `po-bounds` lets the implementer and the reviewer run `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/polype/po" inbox <id>`; a refusal is a stop and a gap of the story. Tests: those files, `test_words_hold`.
9. [x] **Setting, docs and ADRs.**
   - `method/templates/agents-local.md`: `Private folder:     ~/.local/state/polype/private/` after `Decision inbox:` in the block, and a row in the values table (where `po` keeps the text of security findings, off the repository; absolute or `~/`; `—` refuses them; ADR-0123), the file's word count not growing (`test_words_hold`, 1115): trim elsewhere, keeping every phrase the tests listed under `## Run interdicts` pin.
   - This repository's `AGENTS.local.md`: `Private folder:     ~/.local/state/polype/private/` after `Decision inbox:`, and no other line.
   - `docs/interface-agent.md`: the `record review` row (`:265`) says security findings go to a `sensitive` decision under `Private folder` and the review keeps the count line; the two refusals; `contract` stays `1`.
   - ADR-0090's frontmatter becomes `superseded-by: [ADR-0099, ADR-0123]`, body untouched (cksum `3744232405 4583`); the assertion at `tests/intake-issue-becomes-a-story.oracle.test.sh:116-122` follows that line only.
   - Tests: `tests/structure.test.sh`, `tests/setup-modes.test.sh`, `tests/leftovers.test.sh`, `tests/platform-setting.test.sh`, `tests/installer.test.sh`, `tests/claude-md-setting.test.sh`, `tests/lint.test.sh`, `tests/intake-issue-becomes-a-story.oracle.test.sh`, `test_words_hold`.
10. [x] **Full suite, around issue #254.** `tests/readme-onboarding.test.sh` clones the committed HEAD and rebuilds `po` into the shared `CARGO_TARGET_DIR`: commit the story first (code, tests, research, plan, ADR, oracle), then `po-run --story s178-security-findings-stay-private --label suite -- 'bash tests/run.sh'`, then `git commit --amend` adding only `docs/verif/s178-security-findings-stay-private.md` (the code tree does not move, so the record's `Tree:` holds). Typecheck: `—`.

## Owns
`AGENTS.local.md` joined the story's `Owns` on `main` (e566fe4), for the `Private folder` line alone: `tests/leftovers.test.sh:20-26` and `tests/platform-setting.test.sh:115-121` run `bin/polype check` on this repository and fail on any `missing setting:` (`bin/polype:603-627`). Checked and not needed: `method/commands/po-setup.md` (five questions pinned by `tests/setup-modes.test.sh:29-36`; "every other setting … keeps the template's value", `po-setup.md:52`), the settings tests and `bin/po-lint` (additive or derived from the template), `docs/installation.md` and `docs/ci.md` (no settings catalogue), any `Reads settings:` line (`po` reads the setting, not a command).

## Scene viewpoints
—

## Run interdicts
- Empty diff: `method/hooks/po-gate.sh`, `method/hooks/po-bounds.sh`, `method/AGENTS.md`, `method/commands/po-ship.md`, `po-drive.md`, `po-retro.md`, `po-orchestrator.md`, `po-flow.md`, `po-setup.md`, `po/src/state/`, `po/src/trust/`, `po/src/next/`, `po/src/context/`.
- `git diff --name-only main...story/s178-security-findings-stay-private -- docs/reviews/` lists nothing but this story's own review.
- `AGENTS.local.md`: the `Private folder` line is its only change.
- ADR-0090: only its `superseded-by` line moves. ADR-0123 is not edited by the implementer.
- `po record review --composed` and `po record qa` behave as before: no scan, no decision, no setting read.
- `[dependencies]` of `po/Cargo.toml` unchanged; `contract` stays `1`; `po inbox add`'s outputs and error codes unchanged.
- `po` never deletes a private text, and never changes the mode of a folder it did not create.
- No file of the repository, test included, describes how to exploit anything; fixtures use a meaningless witness string.
- No test writes under the developer's real `HOME`: each security record runs with `HOME` and `Private folder` inside its scratch dir.
- Every test file changed is in `Owns`; phrases pinned by `tests/review.test.sh`, `tests/wiring.test.sh`, `tests/review-header-recorded.oracle.test.sh`, `tests/execute.test.sh`, `tests/run-ledger.test.sh`, `tests/model-routing.test.sh`, `tests/setup-modes.test.sh`, `tests/ship-follows-forge.test.sh`, `tests/claude-md-setting.test.sh`, `tests/everything-in-issues.test.sh`, `tests/ci-on-every-pr.oracle.test.sh`, `tests/ship-through-pr.test.sh`, `tests/qa-drivers.test.sh` stay byte for byte.
- `LC_ALL=C wc -w` of each method file `Owns` lists does not grow (`test_words_hold`); `templates/review.md` ≤ 558 and `po-review.md` < 1244 without touching `tests/record-writes-reports.test.sh`.

## The pivot
Everything rests on `po record review` splitting the answer **before** anything is written, and on a mark a script reads. Ways it could be wrong:
1. **A refusal after the write leaks the text.** Today's shape refusal returns `written: true` (`po/src/record/mod.rs:219-229`); the security refusals (mark, setting, inbox) come before `write_atomic`, the private file and the decision. Compare: the oracle and task 4 grep the whole scratch dir for the witness.
2. **The setting resolves inside the repository.** A `~/` value on a machine whose `HOME` holds the clone, or a symlink: `place()` resolves the nearest existing ancestor; compare `test_unusable_private_folder_is_refused`.
3. **The reviewer does not mark a finding that bears on security.** Its text lands in the review as before s178; `/po-ship` Step 3 still holds it back for the person (`po-ship.md:99`, s179). Model rule: judged in review, `po-eval` candidate.
4. **The count line breaks a reader.** `findings-shape` (`po-gate.sh:109,120`, `first()`), `/po-ship`'s finding parser (list items opening with a severity only) and s179's retro count; compare against the awk of `po-gate.sh:106-127`.
5. **`agents-local.md` cannot take the setting without growing.** If no cut keeps the pinned phrases, stop and report: neither the ceiling nor a pinning test is relaxed.

## Files touched
`po/src/inbox/mod.rs`, `po/src/inbox/add.rs`, `po/src/record/mod.rs`, `po/src/record/security.rs` (new), `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `method/templates/review.md`, `method/templates/agents-local.md`, `method/agents/reviewer.md`, `method/skills/review-lenses/SKILL.md`, `method/commands/po-review.md`, `method/agents/implementer.md`, maybe `method/commands/po-execute.md`, `AGENTS.local.md` (the setting line), `docs/interface-agent.md`, `docs/decisions/ADR-0090-…md` (frontmatter), `docs/decisions/ADR-0123-…md` (written here), `tests/security-findings-stay-private.oracle.test.sh` (written here), `tests/security-findings-stay-private.test.sh`, `tests/state-carries-session-lines.oracle.test.sh`, `tests/project-lead.test.sh`, `tests/intake-issue-becomes-a-story.oracle.test.sh`, `docs/research/…`, `docs/plans/…`, `docs/verif/…`.

## Test strategy
- Oracle (6, process level through `po record review`, `po inbox <id>` and `po-gate`). The layer is the binary's interface: `po` has no unit tests and the suite is bash (`AGENTS.local.md`).
- Own (6, task 4): modes, the two setting refusals, `~/`, the blocking rule, the inbox refusal. One test per rule `po` owns; the `place()` cases share one test.
- Changed, not added: the version fixtures of task 5, the ADR-0090 assertion of task 9.
- 12 new tests, within `Test budget` 25.
- Not by test: `fix_run_still_reads_them` and the reviewer's marking rule, read by a model — judged in review, `po-eval` candidates; `docs/interface-agent.md`, judged in review.
- Full suite once, at the end (task 10, `Full suite: execute-end`).

## Done when
One commit `s178-security-findings-stay-private: …` landed through a pull request with `po` 0.3.0; the oracle and the suite green; a review with no open critical finding; `Private folder` in the template and in this repository's settings; ADR-0090's `superseded-by` naming ADR-0123.
