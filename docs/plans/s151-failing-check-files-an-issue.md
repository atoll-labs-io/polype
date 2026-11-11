---
validated: yes
---
# Plan — s151-failing-check-files-an-issue

[Story](../stories.md) · [Research](../research/s151-failing-check-files-an-issue.md)

Branch `story/s151-failing-check-files-an-issue`. Read `docs/research/s151-failing-check-files-an-issue.md` first; this plan builds on it without repeating it.

## Story
`po-intake --label <name> [--sensitive] -- '<command>'` runs a scheduled check from the repository root and passes its output and exit code through. A failure of a non-sensitive check files one issue `<name>: <fingerprint>` in `Issue tracker` (or comments on the open one with that title), its output scrubbed by a new `po-gate redact <file>` that reuses the secret scan's list and rule; a sensitive failure is never filed and goes to the person. Criteria: `intake_passes_through`, `sensitive_failure_goes_to_the_person`, `failure_files_one_issue`, `secrets_are_scrubbed`, `same_failure_not_filed_twice`, `tracker_values_hold`, `rules_name_po_intake` (`docs/stories.md`, s151).

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Secret matcher shared by `secret_scan` and `redact` | already in this repo: `SECRET_PATTERNS` (`po-gate.sh:235-240`) and the rule of `hit()` (`:266-275`), moved into one awk fragment both programs load | `hit()` only says yes/no for a line; redaction needs each qualifying match's place, so the rule is factored, never copied |
| `po-gate redact <file>` | new subcommand on the dispatcher (`:623-633`) | no mode prints a scrubbed file today |
| `po-intake.sh` argument parsing, `refuse` → 125, `bash -c` of one argument, exit passthrough | already in this repo: `po-run.sh:13-34`, `:52-55`, `:64`, followed as a model | `po-run` needs a story id and writes a record; it cannot be called for a scheduled check |
| Setting read | already in this repo: the `sed` of `po-gate.sh:313` | — |
| Filing, dedup, label, taskwarrior project | already specified: `/po-ship` Step 3 (`po-ship.md:94-97`), commands reused as written there | prose only, no function to call; `po-intake` runs those same commands on its own title and body |
| Output capture while passing it through | platform: `tee` per stream with process substitution, then `wait` | — |
| Env-value scrub, fingerprint extraction | platform: one `awk` each (`ENVIRON`, `index()` for literal values) | — |
| `docs/harnais.md` | new document (French) | does not exist (research) |

No option, setting or abstraction beyond these; no `--finding` mode (that is s154).

## Acceptance tests
Written by the planner before any code, run against a throwaway prototype outside the worktree (all seven passed, then the prototype was deleted). They go through `po-intake`, `po-gate redact` and the stubbed `gh`/`task` calls fixed in "Interfaces the oracle fixes" below; `gh` and `task` are stubs first on `PATH`.

| Oracle file | cksum |
| --- | --- |
| `tests/failing-check-files-an-issue.oracle.test.sh` | `2234325478 11863` |

| Criterion | Test |
| --- | --- |
| `intake_passes_through` | `test_intake_passes_through` |
| `sensitive_failure_goes_to_the_person` | `test_sensitive_failure_goes_to_the_person` |
| `failure_files_one_issue` | `test_failure_files_one_issue` |
| `secrets_are_scrubbed` | `test_secrets_are_scrubbed` |
| `same_failure_not_filed_twice` | `test_same_failure_not_filed_twice` |
| `tracker_values_hold` | `test_tracker_values_hold` |
| `rules_name_po_intake` | `test_rules_name_po_intake` |

### Interfaces the oracle fixes
- `po-intake --label <name> [--sensitive] -- '<command>'`: exactly one command argument, run with `bash -c` from `git rev-parse --show-toplevel`. stdout carries the command's stdout and nothing else; every `po-intake` message goes to stderr. Exit code: the command's, whatever happens to the filing; a refusal before the command runs (bad arguments, not in a git work tree) → 125, as `po-run`.
- `po-intake` calls `po-gate.sh` found beside itself (`$(dirname "${BASH_SOURCE[0]}")/po-gate.sh`).
- `po-gate redact <file>`: prints the scrubbed text on stdout, leaves the file unchanged; exit 0, or 2 when the file cannot be read. Each qualifying match → `[redacted]`; a qualifying `private-key` line → the lines from it through the next line matching `-----END[A-Z ]*PRIVATE KEY`, or through the end of the file, become one `[redacted]` line.
- Fingerprint: from the scrubbed output, the first line (in output order) matching `^not ok [0-9]+ ` → the rest of the line; `^FAILED ` → the rest; `^test (.+) \.\.\. FAILED$` → the name; `^  FAIL  ` → the rest; none → the exit code. Title `<label>: <fingerprint>`, trailing blanks and `\r` trimmed.
- Body: `Check: <label>`, `Command: <command>`, `Commit: <full sha of HEAD>`, `Exit code: <code>`, a blank line, then the last 200 lines of the scrubbed output inside a four-backtick fence. The assembled body goes through the scrub once more (the command text may hold a secret).
- `github`: `gh auth status --hostname github.com`; `gh issue list --repo github.com/<owner>/<repo> --state open --limit 1000 --json number,title --jq '.[] | "\(.number)\t\(.title)"'`; an exact title match → `gh issue comment <number> --repo … --body-file <file>`; else `gh label list --repo … --limit 1000 --json name --jq '.[].name'`, `gh label create polype-intake --repo …` when no line is exactly `polype-intake`, then `gh issue create --repo … --title "$(cat "$d/title")" --body-file "$d/body" --label polype-intake`.
- `taskwarrior`: `task project:<name> +issue status:pending _uuids`, then `task _get <uuid>.description` per uuid compared to the title in the shell; a match → `task <uuid> annotate -- "$(cat "$d/comment")"`; else `task rc.verbose=new-uuid add project:<name> +issue +polype-intake -- "$(cat "$d/title")"`, the first uuid-shaped token of its output, then `task <uuid> annotate -- "$(cat "$d/body")"`.
- Comment (both trackers): the full commit sha, the UTC date-time (`date -u +%FT%TZ`) and the exit code.
- `—`: the title then the body, scrubbed, on stderr.
- `--sensitive` failure: report (label, command, commit, exit code, raw output) written to `report.md` in a fresh `mktemp -d` under `${TMPDIR:-/tmp}`, mode 600, kept; stderr names its absolute path as a whitespace-delimited token, never the output.

## Tasks
1. [x] **`po-gate.sh`: one matcher, two programs.** Move the `SECRET_PATTERNS` parsing (`:280-287`) and the boundary/min-length rule of `hit()` (`:266-275`) into one awk fragment held once in the script (e.g. a shell variable of awk functions), with a function that finds the next qualifying match of pattern `i` from a position; `secret_scan` keeps `hit()`'s yes/no on top of it, unchanged in output and behaviour. `SECRET_PATTERNS` keeps its name, its `'<rule>|<min>|<ERE>` format starting with `SECRET_PATTERNS='` and its rows. Add `redact)` to the dispatcher and a usage line to the header (`:3-27`), with the contract above. POSIX ERE classes only, as the floor guard's comment asks (`:355-356`). Test that fails if wrong: `tests/gate.test.sh` (secret scan, unchanged), `test_secrets_are_scrubbed` (redact, list read once, probe line).
2. [x] **`po-intake.sh`: run and pass through.** New executable `method/hooks/po-intake.sh`, header usage like `po-run.sh:1-10`, `set -euo pipefail`. Parse `--label` (non-empty, no newline), `--sensitive`, `--`, one command; `cd` to the top; work dir `mktemp -d` removed on exit; run with stdout and stderr each `tee`d to one capture file and passed to their own stream, `wait` before reading; exit 0 → exit 0, nothing else runs. On a sensitive failure, write and name the report as fixed above and exit with the code. Tests: `test_intake_passes_through`, `test_sensitive_failure_goes_to_the_person`.
3. [x] **`po-intake.sh`: scrub, fingerprint, title and body.** Scrub the **whole** capture first: `po-gate.sh redact`, then an awk that replaces, with `index()` (literal, never a regex), each value of at least 8 characters of an environment variable whose name contains `TOKEN`, `KEY`, `SECRET` or `PASSWORD` (case-insensitive) by `[redacted]`. Only then extract the fingerprint and cut the last 200 lines. Title, body and comment are written to files with `printf` of trusted values (label, command, sha, code, date) and file copies of output text; no output text in a shell argument, no `eval`. `redact` failing → nothing filed, a message on stderr, the command's code. Read `Issue tracker` with the `sed` of `po-gate.sh:313`; `—` → report on stderr; line missing or a value other than `github`/`taskwarrior`/`—` → stderr names the setting and its value, nothing filed. Tests: `test_failure_files_one_issue`, `test_secrets_are_scrubbed`, `test_tracker_values_hold` (the `—` part).
4. [x] **`po-intake.sh`: file on `github` and `taskwarrior`, no duplicate.** The commands fixed above, following `po-ship.md:95-96`: `github` only when `origin` is on `github.com` and `gh auth status --hostname github.com` passes; `<owner>/<repo>` from `origin` (`https://github.com/o/r(.git)`, `git@github.com:o/r(.git)`, `ssh://git@github.com/o/r(.git)`). A listing that fails, or returns 1000 lines, files nothing and says so on stderr with the scrubbed report. The taskwarrior project name exactly as `po-ship.md:96` computes it. No `curl`, `wget`, `gh api` or `jq` binary. Tests: `test_tracker_values_hold`, `test_same_failure_not_filed_twice`, `test_failure_files_one_issue`.
5. [x] **Rules and documents.** `method/AGENTS.md:149` — after the `po-run` sentence: `` `.polype/hooks/po-intake.sh`, called `po-intake`, runs a scheduled check from the repository root and passes its output and exit code through; when the check fails, it files one issue with its output scrubbed of secrets, or comments on the open one with the same title, and the failure of a check marked `--sensitive` goes to the person instead. `` Law 7 (`:127`), after "The findings a shipped review leaves open are filed by `/po-ship`, once the merge is proven.": `` `po-intake` files, as the lead does, the failure of a scheduled check that is not sensitive. `` `testing-doctrine/SKILL.md:75` — the row keeps its four frozen phrases and becomes:
   ```
   | Long fuzzing or simulation campaign | outside any story's cycle, on a schedule, through `po-intake`; its failure goes to `Issue tracker` as Law 7 says, except that a fuzzing campaign, or any check that exercises a decoder of input from outside, runs with `--sensitive` and its failure goes to the person — the story runs only the short version | — |
   ```
   New `docs/harnais.md`, French, titled `# Le harnais`: what `po-intake` does, `--sensitive` and why, the three `Issue tracker` values; a GitHub Actions workflow (`on:` / `schedule:` / `- cron:`, `permissions: issues: write`, `GH_TOKEN: ${{ github.token }}`, `.polype/hooks/po-intake.sh --label nightly -- 'bash tests/run.sh'`) and a systemd `.service` + `.timer` (`[Timer]`, `OnCalendar=`) with the equivalent crontab line; a sensitive check runs on a machine the person controls, since its report stays in that machine's temp dir. Tests: `test_rules_name_po_intake`, `test_sensitive_failure_goes_to_the_person` (doctrine row), `tests/structure.test.sh`, `tests/tests-beyond-examples.test.sh`, `tests/everything-in-issues.test.sh`, `tests/readme-onboarding.test.sh` (size).
6. [x] **Own tests, then the full suite.** `tests/failing-check-files-an-issue.test.sh`, same stub technique as the oracle, at most 5 tests: `redact` keeps a near-miss shorter than the minimum length (`gh``p_` + 10 chars) and redacts two tokens on one line; `Issue tracker` line missing → stderr names `Issue tracker`, no tracker call, the command's code; `origin` not on `github.com` → nothing filed, the scrubbed report on stderr; a failing `gh issue list` → no `issue create`; a usage error → 125 and the command did not run. Then `po-run --story s151-failing-check-files-an-issue --label suite -- 'bash tests/run.sh'`.

## Scene viewpoints
—

## Run interdicts
- Empty diff: `.polype/`, `.claude/`, root `AGENTS.md`, `bin/polype`, `README.md`, `method/commands/`, `method/templates/`, `docs/parite-killer-saas.md`.
- Every test file outside `Owns` unchanged (`git diff main...story/s151-failing-check-files-an-issue --stat -- tests/` lists only the two s151 files); the oracle file unchanged unless `## Oracle changes` of the record says why.
- `SECRET_PATTERNS` rows byte-identical; `secret_scan`'s messages unchanged (`po-gate: <file>:<line>: <rule> (value not shown)`).
- `po-intake.sh` holds no pattern of the secret list, no `curl`, `wget`, `gh api`, `eval`, and no output text inside a shell argument other than `"$(cat <file>)"`.
- No real tracker reached by any test: `gh` and `task` are stubs first on `PATH`.
- No literal key, token or PEM header in any committed file (build them at run time, as `tests/gate.test.sh:170` does).

## The pivot
The secret matcher refactor in `po-gate.sh`: one list and one rule for both the pre-commit scan, which guards every commit of every project, and the new scrub. Ways it could be wrong:
- The scan's behaviour shifts (boundary, minimum length, a second match on a line after a non-qualifying one): compare against `tests/gate.test.sh:197-236` and the old `hit()` loop, which advances past a non-qualifying match rather than one character.
- `redact` misses what the scan flags: for each `SECRET_PATTERNS` row, a line the scan refuses must come out of `redact` without the value.
- The scrub runs on the 200-line tail instead of the whole output, leaving a PEM body whose `BEGIN` fell above the cut; or the fingerprint is taken from the raw output, carrying a secret into the title.

## Files touched
`method/hooks/po-gate.sh`, `method/hooks/po-intake.sh` (new), `method/AGENTS.md`, `method/skills/testing-doctrine/SKILL.md`, `docs/harnais.md` (new), `tests/failing-check-files-an-issue.test.sh` (new), plus `docs/research/`, `docs/plans/`, `docs/verif/` of the story.

## Test strategy
Automated, all bash in `tests/`: the 7 oracle tests (one per criterion) plus at most 5 own tests = 12, within `Test budget` 25. They drive the scripts end to end in a throwaway repository with `gh`/`task` stubs: the stubs record calls and hand back fixed listings, they reproduce no rule of `po-intake` (shape 6), and no real tracker exists to start. Existing tests that freeze touched files run in the full suite at the end. No visual check.

## Done when
All tasks ticked; the full suite green through `po-run`; the record complete; the reviewer's verdict allows shipping; one commit `s151-failing-check-files-an-issue: Un contrôle planifié qui échoue dépose une issue` landed through a pull request.
