---
validated: yes
---
# Plan — s170-trust-signals

[Story](../stories.md) · [Research](../research/s170-trust-signals.md)

Branch `story/s170-trust-signals`. Read `docs/research/s170-trust-signals.md` first. This plan builds on it and does not repeat it. This is a defect story (`Corrige` #205). The root cause is in `## Structuring facts` of the research: `trust::shipped` always returns `None`, `po state` refuses `--all` and `--remote`, and `po-run` writes no duration.

Both test files the criteria change, `tests/run-ledger.test.sh` and `tests/state-as-json.oracle.test.sh`, are in the story's `Owns` since 20ba6e6 (framing pull request 300); tasks 1 and 7 change one clause in each (research, false assumptions 1 and 2).

## Story
For each story of the current milestone that has shipped, `po state` gives `shipped[]` with `story`, `commit` and `trust`. `--all` gives every shipped story. `--remote` alone reads the forge's `checks`. A value that cannot be read is `null` and never a default. `po-run` notes each check's duration, from which `duration_s` is derived. `cost_usd` stays `null`.

- `shipped_stories_carry_trust`: oracle.
- `unknown_is_null_never_guessed`: oracle.
- `checks_are_read_only_on_request`: oracle.
- `duration_comes_from_the_record`: oracle.

## Reuse

| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Option parsing `--all` / `--remote` | `trust::state_options` already exists (`po/src/trust/mod.rs:31`), and `state` already turns its `Err` into `unknown-option` (`po/src/state/mod.rs:35-38`) | — (extend in place) |
| Selecting the shipped stories | `Stories.list` in file order, `Story.milestone`, `Landed::commit` and `Context.milestone` (`po/src/context/`) | already there: only the filter is new |
| Reading the landed files in one call | `git cat-file --batch` from git itself, launched like `project::git` (`po/src/project.rs:20-33`) but with piped stdin | `Project::on_target` (`project.rs:92`) costs one process per file: about 500 for `--all` here |
| Parsing review, plan and record | new code in `po/src/trust/` | no parser of these lines exists in the crate: `po-gate`'s awk is bash, out of reach and not to be changed |
| Times | `chrono::DateTime::parse_from_rfc3339`, already a dependency (ADR-0118) | the standard library parses no dates |
| Forge reading | the `gh api --hostname github.com` rule of `po-ship.md:27-29` (ADR-0083); the double variable follows `PO_CLAUDE` (`po/src/run/session.rs:39-44`) | no HTTP crate may be added, and `gh` already holds the token for its own host |
| Duration in `po-run` | bash's `SECONDS` | `date -d @…` is GNU-only |

## Acceptance tests

| Oracle file | cksum |
| --- | --- |
| `tests/trust-signals.oracle.test.sh` | `4269644301 10934` |

| Criterion | Test |
| --- | --- |
| `shipped_stories_carry_trust` | `test_shipped_stories_carry_trust` |
| `unknown_is_null_never_guessed` | `test_unknown_is_null_never_guessed` |
| `checks_are_read_only_on_request` | `test_checks_are_read_only_on_request` (forge double through `PO_GH`) |
| `duration_comes_from_the_record` | `test_duration_comes_from_the_record` (runs the real `po-run`, then reads a landed record) |

The oracle ran on the code of `Target branch` on 2026-11-14 with 0 passed and 4 failed, each test failing for the defect it names. It sources s164's fixture builders (`tests/state-as-json.oracle.test.sh`), as s174's oracle does.

## Tasks
1. [x] **`po-run` notes the duration.**
   - In `method/hooks/po-run.sh`, set `SECONDS=0` right before the command runs (`:51-53`). The Time cell of the row (`:61`) becomes `<UTC end time> (<SECONDS>s)`, for example `2026-11-14T10:00:30Z (30s)`.
   - The header, the other cells and their order do not move, so `po-gate` (`:175-178`) reads the same exit, tree and command.
   - The header comment (`:8-9`) names the duration without growing past its 130 words (`sed -n 1,10p | wc -w`).
   - In `tests/run-ledger.test.sh:48`, the regex becomes `^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \([0-9]+s\)$`. The story changes that clause; say so in the record.
   - Tests: `test_duration_comes_from_the_record`, plus `tests/run-ledger.test.sh` and `tests/gate.test.sh` staying green unchanged elsewhere.
2. [x] **Options and types.**
   - In `po/src/trust/mod.rs`, `StateOptions { pub all: bool, pub remote: bool }`. `state_options` accepts `--all` and `--remote` in any order, a repeat being harmless. Any other argument → `Err("po state takes no option <arg>")`.
   - `Trust` gains `pub track: Option<String>` after `method_version`, and `duration_s` becomes `Option<u64>`.
   - Drop the module's "filled by a later story" comment and its `#![allow(dead_code)]` once nothing is dead.
   - Test: `test_state_refuses_an_unknown_option` (task tests).
3. [x] **Landed files, one read.**
   - In a new `po/src/trust/landed.rs`, `fn read_blobs(project, specs: &[String]) -> HashMap<String, String>`. It runs one `git cat-file --batch` in `project.root` with `GIT_OPTIONAL_LOCKS=0` and writes `<full commit>:docs/reviews/<id>.md`, `…:docs/plans/<id>.md` and `…:docs/verif/<id>.md` for every selected story to its stdin.
   - It parses `<oid> blob <size>\n<content>\n`, skips `<spec> missing`, and keeps only UTF-8 blobs.
   - A failed launch gives an empty map, so every value is `null` and nothing errors.
   - Files are read **at the story's landed commit** (`Landed::commit`), never at the tip of `Target branch`.
   - Tests: the four oracle tests; `tests/state-as-json.oracle.test.sh` `test_state_reads_only_files_and_git` (no forbidden git verb, under a second here).
4. [x] **Parsers.** In a new `po/src/trust/signals.rs`, pure functions over text.
   - **Review block**: the text after the last line starting `Method version:`, or the whole file when there is none.
     - `method_version`: the value of that last line, trimmed, and `null` when it is empty or there is no such line.
     - `fix_loops`: the last `Fix loop:` of the block, parsed as `u32`, else `null`.
     - `max_severity`: the last `Max severity:` of the block, first word, one of `none` `minor` `major` `critical`, else `null`.
     - `not_verified`: the last `## Not verified` of the block, up to the next `## ` heading or a line starting `Max severity:` or `Ship allowed:`. It is the number of lines starting `- ` at column 0. When there are none, it is `0` if the body is blank, `none` or `—`, else `null`. With no section, `null`.
     - `oracle`: `null` when the file has no `Method version:` line. Otherwise, take the **first** line of the block starting ``- Oracle: `po-gate oracle-intact `` (the one `po record` wrote, research trap) and its following lines indented by two spaces. `→ exit 0` with an indented line containing `has no oracle` gives `none`. `→ exit 0` with one containing `: changed, logged in ## Oracle changes` gives `changed-with-reason`. `→ exit 0` with neither gives `intact`. Anything else (exit 1, 2, `not run`, no line) gives `null`.
   - **Track**: the plan's frontmatter, from a first line `---` to the next `---`. `track: flow` gives `flow`. No `track:` line gives `full`. Any other value, no frontmatter, or no plan gives `null`.
   - **Duration**: the run rows of `## Runs`, read as `po-gate` does (at least 5 cells, exit all digits, tree 40 hex, the time in the last cell). The time cell is `<rfc3339>` with an optional ` (<n>s)`. `duration_s = end(last) − (end(first) − n(first))` in whole seconds. It is `null` when there is no row, a time does not parse, the first row has no duration, or the result is negative.
   - `cost_usd` is always `null`.
   - Tests: `test_shipped_stories_carry_trust`, `test_unknown_is_null_never_guessed`, `test_duration_comes_from_the_record`.
5. [x] **Forge, on request only.**
   - In a new `po/src/trust/forge.rs`, public so a later story (#286) reuses it. It reads `git config --get remote.origin.url` and recognises `github.com` in `https://github.com/<o>/<r>[.git]`, `git@github.com:<o>/<r>[.git]` and `ssh://git@github.com/<o>/<r>[.git]`. Any other host or no origin → `checks: null`, no call.
   - The program is `PO_GH` when set and non-empty, else `gh`. Per story, it runs `<gh> api --hostname github.com repos/<o>/<r>/commits/<full sha>/check-runs?per_page=100` with stdin null.
   - Mapping:
     - a launch failure, a non-zero exit, unparsable JSON, or `total_count` above the runs listed → `null`;
     - `total_count` 0 → `none`;
     - any run not `completed` → `null`;
     - any `conclusion` among `failure`, `cancelled`, `timed_out`, `action_required`, `startup_failure` or `stale` → `failed`;
     - otherwise → `passed`.
   - It never runs without `--remote`. `po` reads no token and makes no HTTP call of its own (ADR-0083).
   - Tests: `test_checks_are_read_only_on_request`; `test_remote_reads_only_github` and `test_unfinished_checks_are_null` (task tests).
6. [x] **`shipped`.**
   - `trust::shipped` returns `None` when `context.stories` or `context.landed` is `None`.
   - Otherwise, it takes the stories of `Stories.list` in file order that `Landed::contains`: all of them with `--all`, else those whose `milestone` equals `context.milestone`'s `id` (`[]` when no milestone is current).
   - Each gives `Shipped { story, commit: Some(first 7 hex of the landed commit), trust: Some(…) }`, built from task 3's one batch, then task 5 when `--remote`.
   - `po/src/state/` does not change.
   - Tests: the four oracle tests.
7. [x] **s164's oracle follows.** In `tests/state-as-json.oracle.test.sh:136-137`, the assertion that `shipped` is `null` becomes `.shipped == []`: that fixture lands no story. The story changes that clause; say so in `## Oracle changes` of the record. Test: `test_state_prints_one_json_object`.
8. [x] **The contract.** In `docs/interface-agent.md`:
   - `:33`: the second bound holds without `--remote`.
   - `:89`: `shipped` leaves the "null until built" list.
   - `### Les signaux de confiance` (`:92-106`): `shipped` lists the current milestone's shipped stories in `docs/stories.md` order, every shipped story with `state --all`, and is `null` when the stories or the landed set cannot be read. `commit` is the short landed commit. The table gains `track` (`full`, `flow`, read in the plan's frontmatter).
   - Each source is read at the landed commit. `oracle` is the line `po record` wrote, `null` for a review it did not record. `checks` is GitHub only, through `gh`, `null` elsewhere or while a check runs. `duration_s` runs from the start of the first `po-run` check to the end of the last. `cost_usd` stays `null` because no file carries it.
   - The JSON example gains `track`.
   - Judged in review together with the criteria.
9. [x] **Full suite.** Run `po-run --story s170-trust-signals --label 'Unit suite' -- 'bash tests/run.sh'` once every task is done. It builds `po`, which is the crate's type check.

## Scene viewpoints
—

## Run interdicts
- `method/hooks/po-gate.sh`, `tests/execute.test.sh` and `method/templates/verification-record.md` end with an empty diff. The header and cell positions of `## Runs` stay as they are, and the template gains no word (#241 m7).
- `method/hooks/po-run.sh` lines 1-10 count no more than 130 words. Only `:51-61` change otherwise.
- `po/Cargo.toml` and `po/Cargo.lock` end with an empty diff (ADR-0118).
- `po/src/context/`, `po/src/state/`, `po/src/next/`, `po/src/run/`, `po/src/record/` and `po/src/inbox/` end with an empty diff.
- `po state` without `--remote` launches neither `gh` nor `PO_GH`. With it, the only forge call is `gh api --hostname github.com …`: no `curl`, no token read by `po`.
- `tests/run-ledger.test.sh` changes only its line 48, and `tests/state-as-json.oracle.test.sh` only its lines 136-137.
- No closed pull request rule (#286), no ship order change (#278). `docs/decisions/` gets no file, and ADR-0122 stays unused.

## The pivot
**Reading a shipped story's files at its landed commit, in the last review block that `po record` wrote.** Ways it could be wrong:
- A review corrected on `main` after landing is not seen. Compare `git log --format=%s -- docs/reviews/` on this repository: besides story commits, only link-line backfills touch reviews today (`docs: add the link line to the s156 review`), and those change no signal.
- A story landed under the bare `s<n>:` subject has its files under the full id. `Landed::commit` resolves both (`lanes.rs:91-94`), and the paths are built from the id of `docs/stories.md`.
- Taking the first `- Oracle:` line of the block relies on `insert_oracle` placing `po`'s line right after `## Tests` (`compose.rs:76-104`). Check this against `docs/reviews/s169-run-from-outside.md:134-138`, where the last line would lie.

## Files touched
`po/src/trust/mod.rs`, `po/src/trust/landed.rs`, `po/src/trust/signals.rs`, `po/src/trust/forge.rs` (new), `method/hooks/po-run.sh`, `docs/interface-agent.md`, `tests/trust-signals.test.sh` (new), `tests/run-ledger.test.sh` and `tests/state-as-json.oracle.test.sh` (one clause each, in `Owns`), plus the oracle, this plan, the research and `docs/verif/s170-trust-signals.md`.

## Test strategy
Every test is bash, run through the `po` binary or `po-run`. The layer is the verb's output, where the rule lives.
- **Oracle**: 4 tests (above).
- **Task tests** in `tests/trust-signals.test.sh`: `test_state_refuses_an_unknown_option` (`--bogus` → exit 2 `unknown-option`; `--remote --all` accepted), `test_remote_reads_only_github` (an origin on another host → `checks` null, the double never called), `test_unfinished_checks_are_null` (one run `in_progress` → `null`).
- **Changed**: `tests/run-ledger.test.sh:48` and `test_state_prints_one_json_object`.
- **Total new**: 7, within `Test budget` 25.
- **Bite checks**:
  - Removing the milestone filter fails `test_shipped_stories_carry_trust`.
  - Taking the last `- Oracle:` line fails it too (s03).
  - Defaulting an odd value fails `test_unknown_is_null_never_guessed`.
  - Calling the forge without `--remote` fails `test_checks_are_read_only_on_request`.
  - Dropping `(n s)` from `po-run` fails `test_duration_comes_from_the_record`.
- **Judged in review**: the contract text of task 8. It is a candidate for a `po-eval` control arm (#208), since an outside agent reads it.
- **Visual checks**: none.

## Done when
- The four criteria hold, and the oracle file keeps its sum.
- The full suite is green through `po-run`.
- The review has no open critical finding.
- The story lands as one commit `s170-trust-signals: Chaque story livrée dit à quel point on peut s'y fier`, closing #205.
