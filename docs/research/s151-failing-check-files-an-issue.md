# Research — s151-failing-check-files-an-issue

[Story](../stories.md)

## Structuring facts
- **`docs/harnais.md` does not exist** (`ls docs/`, no file, no git history): this story creates it; s152 and s154 then extend it. The story's note reads as if it were already there.
- **Line references are off**: `SECRET_PATTERNS` is `method/hooks/po-gate.sh:235-240` (its comment `:230-234`), not `:224-234`; `hit()` is `:266-275`, not `:260-268`. `/po-ship` Step 3's filing rules are `po-ship.md:94-97` (`:93` is a body-building sub-bullet). Same code, shifted lines; nothing in the story's intent changes.
- The secret list and its boundary rule live **inside one awk program** of `secret_scan` (`po-gate.sh:259-304`): `hit()` only answers "is there a qualifying match", so a `redact` mode must share a matcher with the scan, not call `hit()` — `po-gate.sh` gets a small refactor so both programs read one list and one rule.
- No hook wraps a command with tracker filing today; the nearest model is `po-run` (`method/hooks/po-run.sh:1-64`): argument parsing, `refuse` → exit 125, `bash -c` of a single argument, exit code passed through (`:52-64`).
- Filing, dedup and tracker handling are already specified for review findings in `/po-ship` Step 3 (`method/commands/po-ship.md:85-97`), but only as prose: there is no shell function to call, so `po-intake` re-implements those commands for its own title and body.

## Story
A long check run outside stories (fuzzing, simulation, nightly suite) is wrapped by `po-intake --label <name> [--sensitive] -- '<command>'`. Success files nothing. A sensitive failure is never filed: a report is kept outside the repository and goes to the person. A non-sensitive failure files one issue `<name>: <fingerprint>` with command, commit, exit code and the scrubbed last 200 lines of output; the same open title gets a comment instead. Scrubbing reuses `po-gate`'s secret detection through a new `po-gate redact <file>` mode, plus env values of `*TOKEN*|*KEY*|*SECRET*|*PASSWORD*` variables. `github` goes through `gh` with a `polype-intake` label, `taskwarrior` through `task`, `—` to stderr. Rules and docs name it.
Criteria: `intake_passes_through`, `sensitive_failure_goes_to_the_person`, `failure_files_one_issue`, `secrets_are_scrubbed`, `same_failure_not_filed_twice`, `tracker_values_hold`, `rules_name_po_intake` (`docs/stories.md`, s151).

## Current code
- `method/hooks/po-gate.sh` (633 lines): subcommands dispatched at `:623-633`; header usage block `:3-27`; `secret_scan` `:243-307` parses `SECRET_PATTERNS` rows `<rule>|<min length>|<ERE>` in awk `BEGIN` (`:280-287`), checks each added diff line with `hit()` (`:266-275`: a match counts when it does not start with a word char after a word char, and is at least `plen` long; non-qualifying matches are skipped past), prints `po-gate: <file>:<line>: <rule> (value not shown)` (`:276-279`). `claude_md_check` reads a setting with `sed -n 's/^Project CLAUDE file:[[:space:]]*\(.*[^[:space:]]\)[[:space:]]*$/\1/p'` (`:313`).
- `method/hooks/po-run.sh`: the pattern for a command wrapper (see above); output not captured.
- `method/AGENTS.md`: Law 6 secret bullet `:121`; Law 7 `:123-127` (second paragraph is one line, `:127`); `## Installed files` `:145-153`, hook sentences on line `:149`. 22 215 bytes (README says "environ 20 Ko", `tests/readme-onboarding.test.sh:135-139` tolerates ±25 %).
- `method/skills/testing-doctrine/SKILL.md:75`: row `| Long fuzzing or simulation campaign | outside any story's cycle, on a schedule; its failure goes to \`Issue tracker\` as Law 7 says — the story runs only the short version | — |`.
- `bin/polype:135`, `:138`: `method/hooks:.polype/hooks` pairs install every hook file, so `po-intake.sh` ships without touching `bin/polype` (confirmed).

## Attachment points
- New file `method/hooks/po-intake.sh` (executable, like the others: `ls -l method/hooks`).
- `po-gate.sh`: a `redact` case in the dispatcher (`:623-633`), a header usage line, and the shared matcher extracted from `secret_scan`'s awk.
- `method/AGENTS.md:127` (Law 7 sentence) and `:149` (Installed files sentence).
- `testing-doctrine/SKILL.md:75` (one table row).
- New `docs/harnais.md` (French).

## Verified interfaces
- Settings line format in `AGENTS.local.md`: `Issue tracker:     github` inside a fence (this repo's `AGENTS.local.md`); values `github`, `taskwarrior`, `—` (`po-ship.md:95-97`).
- GitHub filing per `po-ship.md:95`: origin on `github.com`, `gh auth status --hostname github.com`, `gh issue list --repo github.com/<owner>/<repo> --state open --limit 1000 …`, `gh issue create --repo … --title "$(cat "$d/title")" --body-file "$d/body"`; 1000 titles → refuse; failing listing → file nothing.
- Taskwarrior per `po-ship.md:96`: `project:<name>`, `<name>` = last path segment of `origin` without `.git`, or with no remote the folder of the main repository (parent of `git rev-parse --path-format=absolute --git-common-dir`); `task rc.verbose=new-uuid add project:<name> +issue -- "$(cat "$d/title")"`, then `task <uuid> annotate -- "$(cat "$d/body")"`.
- Test helpers: `scratch_repo`, `fail`, `contains`, `require_file` (`tests/lib.sh`); `lib.sh` exports `GIT_CONFIG_GLOBAL=/dev/null`. `tests/run.sh` runs every `*.test.sh`, so `*.oracle.test.sh` runs too.
- Real `gh`, `task` and `jq` are installed on this machine (`which`): tests must put stubs first on `PATH`. Polype avoids `jq` at run time (`tests/project-lead.test.sh:258`, `hooks-installer-docs-cleanup.test.sh:83`): `po-intake` must not need it (`gh --jq` is gh's own).

## Traps
- **Tests outside `Owns` that freeze touched files** (must stay green, unchanged): `tests/gate.test.sh` (secret scan `:170-236`, incl. `desk_live_` near-miss `:206` and PEM after `\n` `:211-217`), `tests/floor-guard.test.sh`, `tests/session-and-gate-checks.test.sh`, `tests/structure.test.sh:73-84` (every file of `method/hooks/` named in `## Installed files`, plus the exact po-gate and po-bounds phrases), `tests/tests-beyond-examples.test.sh:47-55` (the long campaign row keeps `on a schedule`, `` `Issue tracker` ``, `Law 7`, `the story runs only the short version`), `tests/everything-in-issues.test.sh:16-31` (Law 7 phrases), `tests/final-leftovers.test.sh:13`, `tests/readme-onboarding.test.sh:135-139` (AGENTS.md size). Baseline: gate, structure, tests-beyond-examples → 39 passed.
- **No literal secret in any committed file**: the pre-commit scan reads added lines on every branch; tests build keys at run time (`gate.test.sh:170`, `"gh""p_…"`). The new `END` pattern is not in `SECRET_PATTERNS` and an ERE like `-----BEGIN[A-Z ]*PRIVATE KEY` does not match itself.
- **Scrub before the tail**: cutting to 200 lines first can leave the body of a PEM block whose `BEGIN` line fell above the window. The whole output must be scrubbed, then cut.
- **The fingerprint is output text**: extracted from the scrubbed output (a secret can sit in a test name), and it travels by file only (Law 7, `method/AGENTS.md:127`).
- **Public logs**: a scheduler's stderr may end in a public CI log; the `—` report on stderr must be the scrubbed one, and a sensitive failure prints only the report path, never the output.
- **Process substitution for capture**: passing stdout and stderr through unchanged while capturing both needs `tee` per stream and a `wait` before reading the capture.
- `.polype/hooks/` and the root `AGENTS.md` are installed copies: not edited (refreshed by the lead after ship).
- Overlap test (`tests/overlap.test.sh`): new method text in own words.
- No migration, no new dependency (`gh`, `task` already used by `/po-ship`), no ADR needed: every choice is inside the story's criteria or an implementation detail.

## Open questions
- pytest's `FAILED <nodeid> - <message>`: the criterion takes the whole text after `FAILED `, message included, so a varying assertion message gives a new title. The plan follows the criterion literally; a cut at ` - ` would be a story change.
- Env-name match: the criterion lists `TOKEN`, `KEY`, `SECRET`, `PASSWORD`; the plan matches them case-insensitively (a lowercase `api_key` holds secrets too), which only redacts more.
- Taskwarrior duplicate lookup: `/po-ship` only lists descriptions; annotating needs the uuid. The plan uses `_uuids` then `_get <uuid>.description` compared in the shell, never a description filter that `task` would parse.
- The sensitive report is kept raw (the person needs the crashing input), mode 600, in `${TMPDIR:-/tmp}`; on an ephemeral CI runner it is lost, which `docs/harnais.md` says.

## Complexity
Story 4 → 4. One new ~150-line script, a careful refactor of the secret matcher every commit depends on, three trackers, three text files. The risk the story names (a secret on a public tracker) is real and sits in the refactor and the scrub order.

## Split
Not needed at 4.
