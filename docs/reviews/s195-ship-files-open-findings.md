# Review — s195-ship-files-open-findings

[Story](../stories.md) · [Plan](../plans/s195-ship-files-open-findings.md) · [Verification](../verif/s195-ship-files-open-findings.md)

Method version: 0.6.1
Recorded: 2026-11-20T11:55:28+01:00

Diff reviewed: `git diff main...story/s195-ship-files-open-findings`, in a context that did not write it. Findings rated critical, major or minor.

Review status: complete
Fix loop: 0
Reviewed tree: 622f45ea9a3cab65534cc7543324a47cf58fd712

## When blocked
Not blocked.

## Ownership
Diff listed with `git diff --name-only main...story/s195-ship-files-open-findings`. Each path was held against the story's `Owns` using the overlap rule of the `review-antihallu` skill.
- [x] Every path is inside `Owns`. `po/src/ship/{file,forge,mod,push}.rs`, `po/Cargo.toml`, `po/Cargo.lock`, `bin/polype`, `docs/interface-agent.md`, `method/commands/po-ship.md` and the four test files are all listed. `docs/research/`, `docs/plans/` and `docs/verif/` for the story are pipeline evidence.
- [x] Nothing is outside `Owns`.
- [x] Nothing is inside another running story's `Owns`. s196 shares `po/src/ship/` and `po-ship.md`, but it depends on s195 and has no lane running in parallel.
- [x] The story has an `Owns` line.

## Evidence reused
- [x] `po-gate verif-current s195-ship-files-open-findings` exits 0, so the record is reused. Per `Verification mode: record`, the unit suite `bash tests/run.sh` (exit 0) was not rerun. The project has no type check command (`Typecheck: —`). I read the record's "Not proven here" list and judged each item below.
- [x] `po-gate qa-current`: not required, because `QA stage: —` sends no story to QA.

## Plan
- [x] Tasks 1–8 are present. The named departures match the code and `docs/interface-agent.md`: `not-landed` has no `pending`, the bare listing returns more fields, `no-review` has extra cases, findings that share a title get one header, `/po-ship` stops on `not-landed`, and the body names the landed commit instead of the PR URL. Nothing is outside the plan.
- [x] Run interdicts checked:
  - `po-gate.sh`, `method/AGENTS.md`, `po-intake.md`, `po-setup.md`, `po-drive.md`, `record/`, `trust/`, `.claude/`, `.polype/`, `docs/decisions/` and `ship-files-the-other-findings.oracle.test.sh` are not in the diff.
  - In `po-ship.md`, only Step 3 item 2 changed.
  - `push.rs` changes visibility only, and `forge.rs` only adds `tracker_project`.
  - No `gh issue create` and no `task add`/`annotate` in `po/`. No new crate, no direct HTTP call, no cleanup code.

## References
- [x] Every call target was confirmed by name and signature:
  - `land::{worktree, setting, title, base, landing_by_subject, read, is_id}`
  - `push::{Gh, gh, json, text}` (now `pub(super)`)
  - `forge::{github_repo, origin_url, host_and_path}`
  - `output::{reply, error, REFUSED, UNREADABLE}`
- [x] Values checked:
  - The 1 000 limit equals `--limit 1000`; refusal at ≥ 1 000 and filing at 999 are both tested.
  - The `0700` folder and `0600` files: probe, below.
  - The uuid v4 bits are set at `file.rs:355-356`.
  - The `%Y%m%dT%H%M%SZ` entry format was accepted by a real Taskwarrior 3.5.0 (probe).

## Rules
- [x] `AGENTS.md` conventions are respected: English method text, version raised in three places (0.11.0), no Killer SaaS phrasing seen.
- [x] No accepted ADR is contradicted:
  - ADR-0083: every `gh` call carries `--repo github.com/<o>/<r>` or `--hostname github.com`, and the repo comes from origin's configured URL.
  - ADR-0090, 0123, 0124 and 0130 hold.
- [x] Model rule `unmarked_security_stays_with_the_model`, judged by reading `po-ship.md` Step 3.2. It sets the order: a bare call, then the model's judgement, then `--file`.
  - The model holds each finding whose text bears on security with `--hold <line>` ("whatever lens ran", "not filed: security (ADR-0077)").
  - It names what the last block marks fixed with `--fixed <line>`.
  - It quotes the `Security findings:` line as written, without opening the decision.
  - Each old rule either moved into code or stayed in prose:
    - shapes, extent and net → parser;
    - title, body and shared titles → `title_of` and the grouping;
    - exact compare, failed listing and 1 000 limit → `open_titles`;
    - github host → `github_repo`;
    - no text in an argument → files only;
    - the taskwarrior `<name>` sentence is kept;
    - the PR URL became the landed commit (a named departure).
  - One wording loss: "quotes its error" on a failed listing became "says why". That is acceptable, since `po` returns the message.
  - 1 250 words against a cap of 1 593.

## Tests
- Oracle: `po-gate oracle-intact s195-ship-files-open-findings` → exit 0
- [x] Floor: `po-gate floor-guard s195-ship-files-open-findings main` exits 0. `po-gate oracle-intact` exits 0.
- [x] Assertions pin the criteria. The doubles keep issues as JSON and log argv. The listing failures and the limit are markers set by the tests, not conditions the doubles reproduce. None of the six empty shapes found.
- [x] 12 tests, within the budget of 25.
- [x] Bite (each mutation built, then only the named test functions run in a throwaway folder):
  - Dropping the filter that skips marked items from `pending` (`file.rs:505`) → 3 failing (`test_security_findings_are_never_filed`, `test_open_findings_are_filed_once`, `test_every_tracker_value_is_handled`).
  - Disabling the dedupe `open.contains(&group.title)` (`file.rs:573`) → 2 failing (`test_open_findings_are_filed_once`, `test_every_tracker_value_is_handled`).
  - Replacing the landing proof with the story's HEAD (`file.rs:476`) → 2 failing (`test_nothing_before_the_proof`, `test_local_mode_proves_on_target_and_names_the_project`).
  - All undone with `git checkout -- po/src/ship/file.rs`. `git diff --exit-code` is clean, and the binary was rebuilt from the committed source.
- [x] Removed tests each fell with prose the code now carries, and the behaviour is tested elsewhere:
  - `test_ship_files_on_each_tracker_value` → oracle `every_tracker_value_is_handled` and `failed_listing_files_nothing`. The `--search` ban is moot because the code lists exactly.
  - `cut_finding`, `test_every_finding_shape_is_read`, `accented`, `review_fixture` → the new `test_every_finding_shape_is_read` (it runs the gate on the same shapes) and oracle `findings_read_in_any_locale`.
  - `test_finding_text_never_enters_a_command` (prose part) → the oracle's argv, shell and `TMPDIR` checks. The Law 7 phrase is kept.
  - `test_ship_net_catches_headings` → the net assertions of the new shapes test (`### F1: major.`, `- see the major point`, `Critical: x`).

## Neighbours
- [x] `push.rs` and `forge.rs` callers are unchanged apart from visibility. `tracker_project` has one caller, and I traced its URL forms by reading: scp, https, bare path, `file://`. `po-intake.md:24` still finds the `<name>` sentence it cites. `method/AGENTS.md:129` is left to the lead, as the brief says.

## Lenses
Lenses run:
- security (an outbound tracker call through `gh api`, temporary files holding review text, and the handling of marked findings);
- dependencies (`po/Cargo.lock` changed, but only `po`'s own version moved: no dependency added, removed or bumped).

Probes, all run in a `mktemp -d` folder with the oracle's doubles for `gh` and `task`. One run used a real `task` 3.5.0 with a throwaway `TASKRC`/`TASKDATA`, `hooks=off` and a scratch `HOME`. Everything was removed afterwards.
- Marked items in every variant asked for: upper case, bold, on an indented continuation line, on a non-indented lazy line, after a blank line then an indented line, and a capitalised opener the gate would refuse.
  - Every one went to `security.lines` or to an `unrecognised` entry with `text: null`.
  - Their text never reached stdout, stderr, the `gh`/`task` argv logs, an issue or a task.
  - `--hold` or `--fixed` on a marked opener only echoes a number. On a line inside a marked item, the reply is `unknown-finding` with nothing filed.
  - A non-indented line after a blank that follows a marked item is quoted in `unrecognised`. That matches the recorder's extent (`record/security.rs:63-74`), which leaves such a line in the public review.
- Idempotence:
  - Two findings sharing a title give one issue holding both bodies.
  - A failure on the first create, then on the second, then a clean run, then another run gave each title filed exactly once, with `already_open` naming the rest.
  - Real Taskwarrior: two tasks with exact descriptions, and a rerun imported nothing.
- Listing: exit 0 with empty output, `[{"title":null}]`, `{}` and `["a"]` each gave `listing-failed` with 0 creates. `[]` files.
- Option and block guards:
  - `--file` given twice, `--hold 0`, the same line under both options, and `--hold` with no number each give `usage` (exit 2). An unknown option gives `unknown-option`.
  - `## Findings` ends at `Max severity:`.
  - `Fix loop:` is read up to the last verdict only: a later `Fix loop: 9` is ignored.
  - The temporary folder is `700` and its files `600`, and `TMPDIR` was left empty.
- #84: titles were byte-identical under no `LC_ALL`, `C`, `POSIX`, a missing `zz_ZZ.UTF-8` and `tr_TR.UTF-8`.
  - The cut counts Unicode scalars: 78 `é` + emoji + combining mark is kept whole at 80. Filing under the missing locale stored the exact title.
  - The dedupe compares exactly the title it sent with the title the tracker lists. The one gap is a tracker that normalises a title on its side: see the second finding.

## Findings
- minor — po/src/ship/file.rs:165 — `## Findings` ends at a `Max severity:` line, while `po-gate findings-shape` reads on to the next `## `.
  - A well-shaped finding written after a `Max severity:` line inside the section passes the gate, yet `po ship file` neither files it nor lists it in `unrecognised` (probe: `- minor — after max severity` dropped silently).
  - This is unlikely under `templates/review.md`, where a later section closes `## Findings` first. Still, it is the drift the plan's pivot names. Either stop only at `## `, or report lines past that point in `unrecognised`.
- minor — po/src/ship/file.rs:186 — the title trims trailing spaces only. When the 80th character is a tab, or the first line ends in other whitespace, the title keeps it (probe: 79 `x` + tab → title ends in `\t`).
  - If the tracker stores a trimmed title, the exact compare on a rerun misses it and files a second issue.
  - The old `sed` did the same, and I did not confirm GitHub's trimming. Trimming all trailing whitespace would close it.

## Not verified
- A real GitHub call. `gh issue list --json title` and `gh api --hostname github.com --method POST repos/<o>/<r>/issues --input <file>` only ran against doubles, as the lane requires. To cover it, a person should run `po ship file <id> --file` once on a throwaway GitHub repository and check the issue, then rerun it to check it is not filed twice.
- Whether GitHub trims or normalises a title it stores (trailing tab, NBSP). This bears on the second finding. Covered by the same throwaway-repo run with such a title.
- `gh`'s stderr on a failed create is passed through. I did not see what a real 4xx/5xx prints there. Its known shape is a status line, not the request body. A person can confirm on the throwaway repository with an oversized title.
- The model side of Step 3.2: that a live `/po-ship` makes the bare call, holds the security-bearing ordinary findings with `--hold`, and marks fixed ones with `--fixed`. I judged it by reading only. No model-read rule of M21 bis or M22 has run on a live project yet (s206, a `po-eval` candidate).
- The full unit suite was not rerun: the record was reused (tree current, exit 0). Only the oracle and task test functions named above were run, against the rebuilt binary.
- An interruption by a signal: the temporary folder is then not removed. It holds only ordinary findings, mode `0600`. This was checked by reading; the case was not replayed.

Max severity: minor
Ship allowed: yes
