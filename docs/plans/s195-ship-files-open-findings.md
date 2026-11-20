---
validated: yes
---
# Plan — s195-ship-files-open-findings

[Story](../stories.md) · [Research](../research/s195-ship-files-open-findings.md)

Branch `story/s195-ship-files-open-findings`. Read `docs/research/s195-ship-files-open-findings.md` first: this plan builds on it and does not repeat it.

## Story
A new sub-step, `po ship file <id> [--file] [--hold <line>]… [--fixed <line>]…`, named by ADR-0130, takes over `/po-ship` Step 3.2. It fixes #84, its root cause being the locale-bound `sed` of `po-ship.md:59`.
- A bare call proves the landing, reads the last review as it landed, and files nothing. It returns what `--file` would file.
- `--file` files each open finding once.
- `--hold` and `--fixed` carry the model's judgement, by line number only.

Criteria:
- `nothing_before_the_proof`
- `open_findings_are_filed_once`
- `security_findings_are_never_filed`
- `failed_listing_files_nothing`
- `every_tracker_value_is_handled`
- `findings_read_in_any_locale`
- `unmarked_security_stays_with_the_model` (judged in review)
- `version_goes_up`

No ADR. ADR-0130 settled the shape and its input, "the list of findings held". ADR-0083 settles the host, and ADR-0090/0123/0124 settle what is held. Passing through `gh api --input` and `task import` is a means inside those decisions: same tools, same host, no dependency. ADR-0131 stays unused.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Worktree, settings, title, base fetch, landing proof | Already here: `land.rs:134,208,257,302,490` (`worktree`, `setting`, `title`, `base`, `landing_by_subject`) | — |
| Running `gh` with its own login, JSON helpers | Already here: `push.rs:190-221` (`Gh`, `gh`, `json`, `text`), made `pub(super)` | — |
| github.com repository of `origin` | Already here: `forge.rs:446` `github_repo` | — |
| Taskwarrior project name | Already here: `forge.rs:63-83` `host_and_path`, `project.rs:73` `Project::name` | Only the composition is new (a few lines in `forge.rs`) |
| The shape the gate accepts (`ships`, `names`, `first`) | New code, mirroring `po-gate.sh:107-111` | A shell script cannot be called from Rust as a parser; the gate prints refused lines only |
| Owner-only temp folder, 0600 files, random uuid, UTC stamp | Standard library (`fs::DirBuilder` + `DirBuilderExt` as `record/security.rs` does, `/dev/urandom`) and `chrono` (installed) | Nothing in the repo writes temporary files |
| `file.rs`: parse, group by title, list, create | New code | No existing step reads findings or writes to a tracker |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/ship-files-open-findings.oracle.test.sh` | `199931352 16667` |

| Criterion | Test |
| --- | --- |
| `nothing_before_the_proof` | `test_nothing_before_the_proof` (pr, github): each case gives `not-landed`, with no create and no `issue list` call: no landing; a landing on the local `main` only; origin's `main` citing the subject in a body and carrying a longer subject. Once origin's `main` holds the landing, 4 issues. |
| `open_findings_are_filed_once` | `test_open_findings_are_filed_once`: one title already open. Near-misses do not count: a longer title open, an exact title closed. The second create fails: non-zero, and the run stops. The rerun files the rest; a third run files nothing, and `already_open` names the four. Each body holds the whole item (sub-bullet), `Fix loop: 1` and the review path. The earlier block is never filed. No finding text in any `gh` argument, nothing run by a shell, `TMPDIR` left empty, `api` calls bound to `--hostname github.com` and `repos/acme/widget/issues`. |
| `security_findings_are_never_filed` | `test_security_findings_are_never_filed`: the listing and `--file` give `security.decision == "d-0042"` and `security.lines == [<line>]`. The marked text reaches no argument, no stderr, no issue and no stdout. 4 issues are created. |
| `failed_listing_files_nothing` | `test_failed_listing_files_nothing`: `gh issue list` exiting 1 gives `listing-failed`, and 1 000 titles give `too-many-open`. Each case has exit 1, `pending` of 4 and no create. `task … export` failing gives `listing-failed` with no import. |
| `every_tracker_value_is_handled` | `test_every_tracker_value_is_handled`: under `github`, 4 issues with URLs. Under `taskwarrior`, 4 tasks in `project:widget` tagged `issue`, the body as the annotation, a uuid each, no text in a `task` argument, and no new import on a rerun. Under `—`, `state: no-tracker`, the 4 titles in `pending`, and no tracker call. |
| `findings_read_in_any_locale` | `test_findings_read_in_any_locale`: the listing under `LC_ALL` `C`, `C.UTF-8` and a missing `zz_ZZ.UTF-8` gives identical `findings` with titles cut by characters (79 `é`, trailing space trimmed). A bare call creates nothing. `--file` under the missing locale files the exact title. |
| `unmarked_security_stays_with_the_model` | — model rule, judged in review. Its word ceiling is checked by the task test `test_ship_words_go_down`. |
| `version_goes_up` | `test_version_goes_up`: three places equal, above 0.10.0. |

The interface the oracle fixes:
- Arguments, run from the worktree: `po ship file s01-a [--file]`.
- Replies: `findings[].title`, `filed[].url`/`.uuid`, `already_open[].title`, `pending[].title`, `security.{decision,lines}`, `state` (`no-tracker`), `error` (`not-landed`, `listing-failed`, `too-many-open`).
- gh through `PO_GH`: `issue list … --json title` → a JSON array; `api --hostname github.com … repos/<o>/<r>/issues --input <file>` with `{title, body}` → `html_url`.
- task first on `PATH`: `… project:<name> +issue status:pending export` and `… import <file>`, with `description`, `project`, `tags`, `annotations[0].description`.
- `TMPDIR` honoured.

All seven fail on today's code: `usage` from `po ship`, and the version still 0.10.0 (run on the main checkout's binary).

## Tasks
1. [x] **Share what exists.**
   - `push.rs`: `Gh`, `gh`, `json`, `text` become `pub(super)`, with no behaviour change.
   - `forge.rs`: add `pub(super) fn tracker_project(project:&Project) -> String`. It returns the last path segment of `origin_url` without `.git` (`host_and_path`, or the raw URL split on `/` and `:` for a local path). With no `origin`, it returns `Project::name()`, the folder of the main checkout, never the worktree.
   - Fails if wrong: `tests/ship-lands-through-a-pull-request*.sh` (s194), `test_every_tracker_value_is_handled` (`project:widget`), `test_local_mode_proves_on_target_and_names_the_project` (`project`, not `s01-a`).
2. [x] **`po/src/ship/file.rs`: the parser, pure, on the review text.**
   - The block runs from after the previous to the last line matching `^([-*] )?Ship allowed:`, as `po-gate.sh:111` does.
   - In it, `## Findings` ends at the next `## `, a `Max severity:` or the closing `Ship allowed:` (as `record/security.rs:117-120`).
   - The last `Fix loop:` line of the file up to that verdict is kept as written.
   - `Security findings: <n> — decision <d-NNNN>` gives `{count, decision}`. Any other tail gives `decision: null`.
   - An item opens at column 0 on `- `, `* ` or `<digits>. ` followed by `ships()` of `po-gate.sh:108`. It extends over every following line up to the next list-marker line at column 0, a line starting `#`, the section end, or a non-indented line after a blank. Trailing blanks are dropped.
   - Severity: `critical` goes to `critical`; `major`/`minor` go to `findings`.
   - Any line of the item holding `[security]` (lowercased; a `MARK` const in `file.rs`, since `record/` is outside `Owns`) puts the item in `security.lines` alone.
   - Title: `<id>: <severity> — <start>`. `<start>` is the first line with the marker stripped, then `^(\*\*)?sev(:)?(\*\*)? *[—:-]? *` stripped. It is cut to its first 80 `char`s, trailing spaces trimmed.
   - Net, `unrecognised[{line, text}]`, by `names()`/`first()` of `po-gate.sh:107,109`: a list line naming a severity without opening one, a `#` line naming one, a bare non-indented line whose first word is one. `text` is `null` when the line holds `[security]`.
   - Fails if wrong: `test_findings_read_in_any_locale`, `test_security_findings_are_never_filed`, `test_every_finding_shape_is_read`.
3. [x] **`file.rs`: the run up to the listing.**
   - Order: arguments → `worktree` → settings → `title` → `base` → proof → review → line checks.
   - Arguments: the id; `--file` once; `--hold N` and `--fixed N` repeatable, N a positive integer. A line given twice, or under both options, → `usage`. Any other option → `unknown-option` (exit 2).
   - Settings: `Target branch` (not `—`); `Merge mode` `pr`|`local`; `Issue tracker` `github`|`taskwarrior`|`—`, else `unreadable-setting`.
   - Proof: `landing_by_subject(base)`; none → `not-landed` (1), before the review is read and before any tracker call.
   - Review: `git show <sha>:docs/reviews/<id>.md`; missing → `no-review` (2).
   - Line checks: each `--hold`/`--fixed` line must be the first line of an item of the last block (finding, critical or marked), else `unknown-finding` (2), nothing filed.
   - Without `--file`: `state: listed` with `landed`, `tracker`, `findings[{line,last,severity,title}]`, `critical`, `security`, `unrecognised`. Exit 0, no tracker call.
   - Fails if wrong: `test_nothing_before_the_proof`, `test_hold_and_fixed_are_checked`, and the zero-create assertion of `test_findings_read_in_any_locale`.
4. [x] **`file.rs`: filing.**
   - Pending: the findings less `--hold`/`--fixed`, grouped by title in review order (one issue per title, bodies joined by a blank line).
   - Body: `Story: <id>`, `Review: docs/reviews/<id>.md`, the `Fix loop:` line, `Severity: <sev>`, `Landed: <sha>`, a blank line, then every line of each item as written.
   - Temp: one folder `po-ship-file-<pid>-<nanos>` under `std::env::temp_dir()`, mode `0700`, `create_dir` (never reused). Files are `0600`, written by `OpenOptions::create_new`. A guard removes the folder on every return.
   - `—` → `state: no-tracker`, `pending`, exit 0.
   - `github`:
     - `github_repo` none, or `gh` unstartable → `tracker-unavailable` (1).
     - List with `gh issue list --repo github.com/<r> --state open --limit 1000 --json title`. Non-zero exit, output that is not a JSON array of objects with a string `title`, or no output → `listing-failed`. Length ≥ 1000 → `too-many-open`.
     - Each pending title absent from the list (exact, whole string) is created: a file `{title, body}` sent by `gh api --hostname github.com --method POST repos/<r>/issues --input <file>`, its `html_url` read.
   - `taskwarrior`:
     - `task` unstartable → `tracker-unavailable`.
     - List with `task rc.confirmation=off project:<name> +issue status:pending export`. Non-zero exit or not a JSON array → `listing-failed`; `description` is compared.
     - Create with a file `{uuid (v4 from 16 bytes of /dev/urandom), description, project, tags:["issue"], status:"pending", annotations:[{entry: UTC %Y%m%dT%H%M%SZ, description: body}]}` sent by `task rc.confirmation=off import <file>`.
   - A create that fails stops at once → `file-failed` (1), with `filed` so far and `pending`.
   - Success: `state: filed`, `filed[{lines,title,url|uuid}]`, `already_open[{lines,title}]`, `held`, `fixed`, plus `critical`, `security`, `unrecognised`.
   - Every refusal of exit 1 carries `pending`. No finding text enters an argument, an environment variable or stderr; a tool's stdout is captured, never echoed.
   - Fails if wrong: `test_open_findings_are_filed_once`, `test_every_tracker_value_is_handled`, `test_failed_listing_files_nothing`, `test_listing_guards_tell_apart`.
5. [x] **Wire it.**
   - `mod.rs`: add `mod file;`, `Some("file") => file::main`, and `USAGE` plus the header comment name `file`.
   - `docs/interface-agent.md`: the `ship forge` row says `forge`, `land`, `push` et `file`. A new `ship file` row after `:274`, in the shape of the `push` row: order, replies, refusals by exit, what it writes, what it refuses.
   - Fails if wrong: every oracle test (`usage` otherwise).
6. [x] **`po-ship.md` Step 3.2 becomes the judgement.** Replace `:54-67` with one item of about 280 words.
   - Keep: the line starting `2. File the open findings`; the sentence "the review is not lost with the worktree, since Step 1 committed it and it lands with the story's commit"; `"not filed: security (ADR-0077)"`; the taskwarrior sentence defining `<name>` ending "never the worktree folder" (`po-intake.md:24`); "through files, never in an argument" (`AGENTS.md:129`).
   - Say:
     - first the bare call;
     - the model holds each finding whose text bears on security (a secret or a token, an authorization or tenant check, an injection), whatever lens ran, with `--hold <line>`, and decides what the block marks fixed with `--fixed <line>`;
     - then `--file`;
     - `security` is quoted by its count and decision only, and the `Security findings:` line as written, never opening it;
     - `unrecognised` lines go to the person marked "not filed: shape not recognised";
     - each `state` and refusal maps to its finish line, and a rerun files only what is missing.
   - `:53`, `:68-69` and the finish `:71` keep their text, being s196's.
   - Fails if wrong: `test_ship_words_go_down`, `tests/ship.test.sh`, `tests/ship-through-pr.test.sh`, the kept parts of `tests/everything-in-issues.test.sh`.
7. [x] **Tests.**
   - `tests/everything-in-issues.test.sh`:
     - drop the phrases `:37-41`;
     - delete `test_ship_files_on_each_tracker_value`, `test_every_finding_shape_is_read`, `cut_finding`, `accented`, `review_fixture`;
     - `test_finding_text_never_enters_a_command` keeps only `:165-166`.
   - `tests/review-findings-shape.test.sh`: delete `test_ship_net_catches_headings`.
   - Write `tests/ship-files-open-findings.test.sh`, in the oracle's setup shape (copy the helpers; the oracle file is not sourced), with the five tests of the strategy.
8. [x] **Version 0.11.0** in `po/Cargo.toml`, `po/Cargo.lock`, `POLYPE_VERSION` of `bin/polype`. Fails if wrong: `test_version_goes_up`.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `method/hooks/po-gate.sh`, `method/AGENTS.md`, `method/commands/po-intake.md`, `po-setup.md`, `po-drive.md`, `po/src/record/`, `po/src/trust/`, `.claude/`, `.polype/`, `docs/decisions/`, `tests/ship-files-the-other-findings.oracle.test.sh`.
- In `po-ship.md`, only Step 3 item 2 changes. The heading `## Step 3 — Cleanup, only after proof`, the `1. Proof.` line, items 3–4 and the finish stay byte for byte (s196).
- `land.rs`, `push.rs` and `forge.rs` keep their behaviour: only visibility and the new `tracker_project` change. The s193/s194 tests stay green.
- No `gh issue create` and no `task add`/`annotate` in `po/`. No `Command` gets a title, body or item line as an argument or an environment value. Every `gh` call is bound to github.com.
- No new crate. No direct HTTP call. No token is read or passed.
- No cleanup code (worktree, branches): s196.

## The pivot
The command files exactly what `po-gate findings-shape` let through, and only after `landing_by_subject` on origin's branch. The judgement it cannot make arrives as line numbers. How it could be wrong:
1. **The parser drifts from the gate.** A finding the gate accepted would be silently skipped, the very #112/#126 failure. Compare `file.rs` with `po-gate.sh:107-111`. `test_every_finding_shape_is_read` runs the gate on the accepted-shapes fixture of `review-findings-shape.test.sh:52-54` and needs every opener listed.
2. **The proof errs.** A false positive files a story's findings before it landed. Ids are never reused, the subject must be exact, and the oracle covers citing and extending commits. A false negative (a squash that appends `(#N)`) files nothing and says `not-landed`, the safe direction. Compare with `push.rs:528`.
3. **The hold travels by the model.** A model that skips the bare call and `--hold` files an unmarked security-bearing finding. That residual risk is ADR-0124's, accepted. The command's part is that it never files a `[security]` mark, files nothing bare, and refuses a line it does not know.
4. **`gh api --input` is not exercised against GitHub.** The method, path and `--hostname` are fixed by the oracle; their meaning is read in `gh api --help`.

What the command refuses when a caller hands it something it must not file:
- a `[security]`-marked item, whatever the options: never filed, never quoted;
- a call without `--file`: files nothing;
- no proof: no tracker call;
- a `--hold`/`--fixed` line that opens no item of the last block: `unknown-finding`, nothing filed;
- `critical` items and unrecognised lines: never filed;
- earlier review blocks: never read;
- a listing that failed or hit its limit, an `origin` off github.com, a missing tool: nothing filed;
- any finding text from the caller: there is no option that takes text.

## Files touched
`po/src/ship/file.rs` (new), `po/src/ship/mod.rs`, `po/src/ship/push.rs`, `po/src/ship/forge.rs`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, `method/commands/po-ship.md`, `tests/ship-files-open-findings.oracle.test.sh` (written here), `tests/ship-files-open-findings.test.sh` (new), `tests/everything-in-issues.test.sh`, `tests/review-findings-shape.test.sh`, plus `docs/research/` and `docs/plans/` of the story. `po/src/main.rs` is not expected to change.

## Test strategy
Twelve tests out of a budget of 25. The doubles are the only option for `gh` and `task`: no real tracker may be called (lane rule). They store issues and tasks as JSON and log argv. They reproduce no condition under test: listing failures and limits are markers the test sets.
- **Oracle (7)**, as listed above.
- **Task tests** in `tests/ship-files-open-findings.test.sh`:
  - `test_every_finding_shape_is_read`:
    - the five openers of the gate fixture give five `findings` with the titles of the old `cut_finding` cases (`bold dash shape`, `colon in bold`…), and the gate passes that fixture;
    - the item extent: a sub-bullet after a blank is kept, a bare line after a blank is cut;
    - a `critical` goes to `critical`;
    - the net lists `### F1: major.`, `- see the major point`, `Critical: x`, but not `No critical or major finding.` or `- the majority of cases`;
    - a `[security]` stray line has `text: null`;
    - two findings sharing a title give one issue holding both.
  - `test_hold_and_fixed_are_checked`:
    - `--hold` keeps a finding out and lists it in `held`;
    - `--fixed` removes a critical;
    - an unknown line gives `unknown-finding` (2) with no create;
    - a line given twice gives `usage`.
  - `test_listing_guards_tell_apart`:
    - `issue list` exiting 0 with non-JSON gives `listing-failed`, apart from the oracle's exit 1;
    - 999 open titles still file, apart from the 1 000 refusal;
    - `PO_GH` naming a missing program gives `tracker-unavailable`;
    - an `origin` off github.com gives `tracker-unavailable`.
  - `test_local_mode_proves_on_target_and_names_the_project`: under `local`, no remote, `taskwarrior`, a landing commit built but not on `main` gives `not-landed`; after the fast-forward, 4 tasks in `project:project`.
  - `test_ship_words_go_down`: `po-ship.md` holds at most 1 593 words (`LC_ALL=C wc -w`, 1 993 − 400), and keeps `## Step 3 — Cleanup, only after proof` and its `2. File the open findings` line.
- Full suite once at the end through `po-run`. No typecheck command (`Typecheck: —`); `cargo build --locked` by `tests/run.sh` stands in.

## Done when
- One commit on `story/s195-ship-files-open-findings`, every test of `bash tests/run.sh` green.
- `po-ship.md` ≤ 1 593 words, and version 0.11.0 in three places.
- A review with no open critical, then the ship by pull request.
