# Research — s195-ship-files-open-findings

[Story](../stories.md)

## Structuring facts
- Root cause of #84: the title command of `/po-ship` Step 3 (`method/commands/po-ship.md:59`) runs `sed -E` under `LC_ALL=C.UTF-8`; where that locale is not installed, glibc falls back to `C` without a word. `.` and the bracket `[—:-]` then match bytes, not characters. Input: any finding whose first line has an em dash separator or a multibyte character near column 80. Proof: `## Diagnostic`.
- The story's line numbers are stale: s192–s194 shortened `po-ship.md` to 1 993 words (`LC_ALL=C wc -w`). The filing is now `po-ship.md:54-67` (1 035 words), the `sed` lines `:59-60`, the proof `:53`, the cleanup `:68-69`. Their content matches what the story describes.
- The landing proof to reuse is `land::landing_by_subject` (`po/src/ship/land.rs:490-495`). It finds the newest commit of the base whose subject is exactly `<id>: <title>`, outside `story/<id>`. Under `pr` the base is `refs/remotes/origin/<target>` right after `git fetch -q origin` (`land.rs:302-316`): this is origin's branch, and a rebase merge that rewrote the sha still matches. `push.rs:528-531` and `land.rs:548-551` already treat it as "landed".
- ADR-0130 names the step `po ship file <id>` and its input: "la liste des constats retenus". The model keeps its judgement on unmarked security findings and on "marked fixed" (ADR-0124, criterion `unmarked_security_stays_with_the_model`). The command parses, proves, deduplicates and files.
- `gh issue create` takes its title only through `--title <text>`, an argument. To keep a finding's text out of every argument, a file has to reach `gh api --hostname github.com --method POST repos/<o>/<r>/issues --input <file>` (JSON `{title, body}`). On the taskwarrior side, `task import <file>` does the same job (checked on task 3.5.0 in a throwaway `TASKRC`).

## Diagnostic
**Reproduction** (outside the worktree, on the exact `sed` of `po-ship.md:59`, GNU sed 4.10). Locales on this machine: `C`, `C.utf8`, `en_US.utf8`, `fr_FR.utf8`. A missing locale is played by `zz_ZZ.UTF-8`.
- `- major — Le relevé décrit élégamment …` under `C.UTF-8` → `Le relevé décrit…`, valid UTF-8. Under `zz_ZZ.UTF-8`, and under `C`, the title starts with the bytes `\200\224`. The bracket ate only the first byte of `—`; `iconv` reports "illegal input sequence at position 0".
- `- minor: ` + 79 `a` + `é tail` → under `C.UTF-8`, `…aé` (80 characters). Under `zz_ZZ.UTF-8`, `…aa\303`: the cut lands inside `é`.

**Hypotheses**
1. *The title `sed` counts bytes once the locale is missing.* Refutation sought: valid UTF-8 cut at 80 characters under `zz_ZZ.UTF-8`. Observed: invalid bytes at both ends. **Kept**.
2. *The deduplication `grep -qxF -f title open` (`:64-65`) misses under a missing locale.* Refutation sought: an identical UTF-8 title matched under `zz_ZZ.UTF-8`. Observed: it matches, since `-F -x` compares bytes. **Discarded**.
3. *The body `sed -n '<first>,<last>p'` (`:60`) changes text under a missing locale.* Refutation sought: `cmp` equal. Observed: equal. **Discarded**.

The duplicate #84 predicts follows from 1: a rerun under another locale computes another title, and the exact comparison misses the issue already open. The fix removes locale from the cut altogether: Rust counts `char`s, whatever `LC_ALL` says.

## Story
`po ship file <id>` takes over filing the open findings (Step 3.2). It runs only once the landing is proven, files each finding of the last review block once, passes title and body through files, and keeps every `[security]`-marked finding back, returned by its decision id alone. A failed listing, or one that reaches 1 000 titles, files nothing. It handles `github`, `taskwarrior` and `—`, and reads the same in every locale. `/po-ship` keeps the judgement and loses ≥ 400 words. The version goes up. Criteria: `nothing_before_the_proof`, `open_findings_are_filed_once`, `security_findings_are_never_filed`, `failed_listing_files_nothing`, `every_tracker_value_is_handled`, `findings_read_in_any_locale`, `unmarked_security_stays_with_the_model` (judged in review), `version_goes_up`.

## Current code
- `po/src/ship/mod.rs:15-17` (`USAGE`) and `:82-87` dispatch `land` and `push`. Anything else falls to `forge`'s parser, which answers `usage`.
- `land.rs` exposes `pub(super)` helpers: `is_id` `:81`, `is_sha` `:91`, `worktree` `:134-160` (cwd on `story/<id>`, else `wrong-branch`), `setting` `:208-220`, `title` `:257-267`, `base` `:302-316`, `git_failed` `:294`, `read` `:484-486`, `landing_by_subject` `:490-495`.
- `push.rs:196-213`: `gh()` runs `program("PO_GH","gh")` with `GH_PROMPT_DISABLED=1`, stdin optional, stdout captured and stderr inherited. It is private to `push.rs` and returns `Gh::Ran{ok,stdout}` or `Unstartable`. `push.rs:215-221` holds `json`/`text`.
- `ship/forge.rs:441-449`: `origin_url` (configured URL, before `insteadOf`) and `github_repo` (`<owner>/<repo>` when the host is `github.com`). `host_and_path` `:63-83` and `owner_repo` `:86-93` stay private.
- `ship/git.rs`: the writing git launcher (`LC_ALL=C`, `GIT_TERMINAL_PROMPT=0`). `project::git` (`project.rs:20-34`) is read-only.
- `output.rs:31-44`: one JSON object per run. Exit 0 ok, 1 refused, 2 unreadable.
- `po-gate.sh:98-128` `findings_shape`: the last block runs from the previous to the last `^([-*] )?Ship allowed:` (`:111`). Its `## Findings` goes up to the next `## `. `ships()` `:108` is the only accepted opener: `- `/`* `/`<n>. `, then `**sev:**`, or `sev`/`**sev**`, then spaces and `—`, `:` or `-`. Refused: a list item naming a severity (`names()` `:107`, word-bounded, any case) without opening with one, a heading naming one, and a bare line whose first word is one (`first()` `:109`).
- `record/security.rs`: `MARK = "[security]"` `:15`. Any other line holding it, lowercased, is refused (`:83`). `closes_section` `:117-120` ends `## Findings` at `## `, `Max severity:` or `Ship allowed:`. `record/mod.rs:268` writes `Security findings: <n> — decision <d-NNNN>` right after `## Findings`, with the text kept off the repository (ADR-0123).
- `po-ship.md:54-67` describes the filing as prose: which findings, the net for lines nobody read, title/body cut through `sed`, the folder from `mktemp -d`, dedupe with `grep -qxF`, `gh issue list --limit 1000`, `gh issue create --title "$(cat …)"`, and `task add`/`annotate`. `:67` holds back marked and security-bearing findings. `:71`: the finish names what was filed, skipped and held.

## Attachment points
- `po/src/ship/file.rs` (new) and `mod.rs` (`mod file;`, dispatch `Some("file")`, `USAGE`).
- `push.rs`: make `gh`, `Gh`, `json`, `text` `pub(super)`, or move them to `mod.rs`.
- `forge.rs`: a `pub(super)` taskwarrior project name built from `origin_url` and `host_and_path`.
- `record/security.rs`: `MARK` could be `pub(crate)`. `closes_section` is reused in spirit (the ship reads a block that ends with `Ship allowed:`).
- `docs/interface-agent.md:272`: the `ship forge` row lists the steps in its `usage` refusal (`forge`, `land` et `push`). A new `ship file` row follows `:274`.
- `po/Cargo.toml:3`, `po/Cargo.lock:165`, `bin/polype:28`: 0.10.0 → 0.11.0.

## Verified interfaces
- `landing_by_subject(top:&Path, base:&str, id:&str, subject:&str) -> Option<String>` (`land.rs:490`).
- `base(top:&Path, mode:&str, target:&str) -> Result<String,i32>` (`land.rs:302`), which fetches under `pr`.
- `forge::github_repo(&Project) -> Option<String>` (`forge.rs:446`).
- `trust::forge::program(var, default) -> OsString` (`trust/forge.rs:20`).
- `task 3.5.0`: `task import <file>` takes a JSON object or array carrying `uuid`, `description`, `project`, `tags`, `status`, `annotations[{entry,description}]` and prints ` add <uuid> <description>` (stdout). `task … export` prints a JSON array, exit 0 even when empty.
- `gh api`: `--input <file>` sends the file as the request body (`gh api --help`). `gh issue list --limit` defaults to 30.
- Test doubles: s194's oracle `tests/ship-lands-through-a-pull-request.oracle.test.sh:41-170` gives the form (origin as a github.com URL rewritten by `insteadOf` to a bare repository, `PO_GH`). The `gh issue`/`task` stubs of `tests/failing-check-files-an-issue.test.sh:14-24` and `tests/intake-title-bounded.oracle.test.sh:17-32` only log.

## Traps
- **References outside `Owns` must stay true.** `method/AGENTS.md:129` ("reaches the tracker through a file … as Step 3 of `/po-ship` does"). `po-intake.md:24` ("Its project `<name>` is the one Step 3 of `/po-ship` computes"): Step 3 has to keep the sentence that defines `<name>`. `po-setup.md:74-75`. `tests/ship.test.sh:16-17` reads `Cleanup, only after proof` and ``prints exactly `MERGED` `` (3.1, which is s196's). `tests/ship-through-pr.test.sh:23-30` wants every `git push` of `po-ship.md` to name `story/<id>`. `tests/everything-in-issues.test.sh:83-93` wants `Issue tracker` in `Reads settings`.
- `AGENTS.md:129`'s parenthesis ("given as `--body-file` or expanded inside double quotes") describes today's shell means. With `--input <file>` and `import <file>` its claim, "through a file", holds; the example goes slightly out of date. It is outside `Owns`: report it, do not edit.
- **Phrase tests that fall** (in `Owns`):
  - `everything-in-issues.test.sh:37-41`: 5 Step 3 phrases.
  - `:54-73`: the whole of `test_ship_files_on_each_tracker_value`.
  - `:153-197`: `test_finding_text_never_enters_a_command` keeps only its Law 7 assertion `:165-166`; `test_every_finding_shape_is_read` goes, with `cut_finding`/`review_fixture`/`accented` `:123-151`.
  - `review-findings-shape.test.sh:88-95` (`test_ship_net_catches_headings`).
  - Still true: the ordering check `:45-49`, `:42`, `test_security_goes_to_the_person` `:75-81`.
- `ship-files-the-other-findings.oracle.test.sh:9` caps `po-ship.md` at 2 700: untouched.
- Reruns: titles of open issues are compared exactly. An interruption between two issues leaves the first open, and the rerun skips it. A GitHub create that fails after the issue was made is caught by the next listing.
- A body taken from the landed commit (`git show <sha>:docs/reviews/<id>.md`) is what is public on `Target branch`. Line numbers match the worktree copy, which Step 1 committed (`land.rs:427-447`).
- `/tmp` lives in memory: the temporary files stay small, live in one `0700` folder and are removed on every path, normal and error alike.
- ADR-0122: each `po/` story raises the version. s196 changes the same files after this one.

## Open questions
- The pull request URL that today's body names (`:60`). The command has no reliable source for it after a hand merge without asking the forge again by branch name. The plan names the landed commit instead (GitHub links a sha). The reviewer judges this.
- A `[security]` item still in the review's text (a `po` older than ADR-0123) carries no decision of its own. The plan returns its line number with the review's decision, never its text.

## Complexity
4 → 4. A strict parser equal to the gate, two trackers fed by files, and a proof already written. The risk the story names (tracker writes cannot be undone) stays, and idempotence carries it.

## Split
—
