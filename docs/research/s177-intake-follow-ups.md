# Research — s177-intake-follow-ups

[Story](../stories.md)

## Structuring facts
- Root cause (redact): `method/hooks/po-gate.sh:289-295` rewrites `line` in place and calls `next_secret(line, i, from)` on the rewritten text, so each later match, and each later pattern, is judged against `[redacted]` instead of the original characters. Proof in `## Diagnostic`: on one line the scan flags `aws-access-key` only, and redact erases a second string as well; on another, the scan flags `anthropic-key` whole, and redact leaves most of it in place.
- **False assumption (from the s151 review):** "This errs only towards over-redaction, never under." It also under-redacts: an earlier pattern (`aws-access-key`, row 2 of `po-gate.sh:238-243`) erases a match inside a longer one (`anthropic-key`, whose class holds `-`), and what is left of the longer one is then too short to qualify. Its remaining characters reach the issue body that `po-intake.sh:82` files. The story's criterion ("efface exactement ce que le contrôle signale") covers both cases. Its text names only the "juste après" case.
- **Incomplete assumption:** "the hook's account" equals "the account `gh auth status` reports" only when `po-intake.sh` and `/po-intake` run under the same `gh` login, as in the systemd and cron examples (`docs/harnais.md:73,93,111-118`). The GitHub Actions example files with `GH_TOKEN: ${{ github.token }}` (`docs/harnais.md:55-57`), so the workflow's bot account is the author, and a `/po-intake` run elsewhere will hold those issues for the person. The criterion as written fails closed in that case. The plan keeps it and says so in `docs/harnais.md`.
- Pending-PR block (s152 major): `po-setup.md:85` leaves `docs/stories.md` and the review file staged in the root until the framing PR merges. `po-intake.md:25` stops on any `git status --porcelain -- docs/stories.md` output, so every later run stops before the citation guard at `po-intake.md:34`.
- Numbering (s152): `po-intake.md:46` counts "the next free `s<n>`" from the root file only. The pending branches that `po-intake.md:34` already enumerates are not counted.

## Diagnostic
**Reproduction** (scratch repo in `mktemp -d`, nothing written in the worktree; witness strings assembled at run time). Line A = `x <aws20><ghp40> y` (an AWS-shaped string directly followed by a GitHub-shaped one). Line B = `x sk-ant-…-<aws20><26 lowercase> y` (an AWS-shaped string inside an Anthropic-shaped one). Line C = `x <aws20> y`.
- `po-gate redact` printed: A → `x [redacted][redacted] y`; B → `x sk-ant-abcdefghij-[redacted]abcdefghijklmnopqrstuvwxyz y`; C → `x [redacted] y`.
- `po-gate pre-commit`, each line staged alone, reported: A → `aws-access-key` only; B → `aws-access-key` and `anthropic-key`; C → `aws-access-key`.
- The oracle `tests/intake-follow-ups.oracle.test.sh` reproduces A and B. Run once on the current code: its scan-verdict assertions pass and `test_redact_follows_the_scan_rule` fails on A.

**Hypotheses (redact)**
1. *redact judges matches on its own rewritten line.* Refuted if the divergence also appears on a line where no replacement precedes the match. Line C (single match) agrees with the scan. A and B diverge only after a replacement: on A, `]` stands where the scan sees `H`; on B, `[redacted]` cuts the longer match. **Kept.**
2. *`next_secret` itself decides differently for redact than for the scan.* Refuted if both call it the same way on the same text. The scan calls `next_secret(s, i, 1)` on the original line (`po-gate.sh:325`), redact calls it with the same arguments on the first match (`:291`), and line C agrees. **Discarded.**
3. *The divergence only ever over-redacts (the review's reading).* Refuted by any flagged character left in the output. Line B keeps 44 characters of the value the scan flags. **Discarded.**

**s152 findings**: established by reading, not reproduced live (no forge, no pending pull request available). The chain is `po-setup.md:85` (staged copy) → `po-intake.md:25` (stop on porcelain). `po-intake.md:46` (root-only numbering) has no reference to `framing/intake-*`. `po-intake.md:28-29` reads no author.

## Story
`/po-intake` takes in only labelled issues authored by the account `gh auth status` reports (github only); a pending intake PR no longer stops later runs; numbering counts pending intake branches; `po-gate redact` follows the scan rule exactly; `po-intake.md` stays ≤ 1550 words. Criteria: `redact_follows_the_scan_rule`, `only_the_hook_account_is_taken_in`, `pending_intake_does_not_block`, `numbering_sees_pending_branches`, `intake_holds_in_its_words`. Sources: `## Findings` of `docs/reviews/s151-…md` (minor, redact) and `docs/reviews/s152-…md` (major, block + numbering; minor, author). The s151 major (title bound) was fixed by s160 and is out of scope.

## Current code
- `method/hooks/po-gate.sh:238-243` `SECRET_PATTERNS` (rule|min length|ERE). `:249-270` `SECRET_MATCHER`: `load_secret_patterns`, and `next_secret(s, i, from)`, which sets `SM_START`/`SM_LEN` on the first qualifying match at or after `from`, a non-qualifying one skipped whole. `:274-299` `redact`: private-key branch `:282-288` (unchanged by the story); token loop `:289-295` (the defect). `:302-350` `secret_scan` reports the first qualifying match per rule per added line (`:325-328`).
- `method/hooks/po-intake.sh:80-82` scrubs the output via `po-gate redact`. `:157` checks `gh auth status`, and `:183` files with the active login. Nothing to change there.
- `method/commands/po-intake.md` (83 lines, **1550 words**, `LC_ALL=C wc -w`): Checks `:17-25` (gh auth `:24`, root level `:25`); listing `:27-32` (`--json number,title` `:29`); citations over `framing/intake-*` refs `:34`; issue files `:36`; writing `:43-56` (numbering `:46`); review `:58-69`; landing `:71-76`; finish `:78-83`.
- `docs/harnais.md:17` "même liste, même règle" (stays true, more so); `:98` describes what `/po-intake` reads (no author clause).

## Attachment points
- Redact fix: inside the `{ … }` block of `redact`, `po-gate.sh:289-295` only.
- Author: `po-intake.md:28-29` (listing `--json number,title,author`), and a held reason in `## Finish` `:81`.
- Pending branch: check 8 `po-intake.md:25`; landing `:72` (the paths committed); finish `:80`.
- Numbering: `po-intake.md:46`.

## Verified interfaces
- `gh` 2.103.3 here: `gh auth status --hostname github.com --active --json hosts` gives `.hosts["github.com"][0].login` (keys: active, gitProtocol, host, login, scopes, state, tokenSource). With `--json`, gh exits 0 even when auth fails, so check 7's pass/fail stays the plain form `po-intake.md:24`. `gh issue list --json` accepts `author`.
- Tests run as `bash tests/run.sh <file>`, each function in `bash -c "set -eu; source lib.sh; …"` (`tests/run.sh:39`). `scratch_repo` at `tests/lib.sh:47`.

## Traps
- Tests outside `Owns` that reach what changes. `tests/failing-check-files-an-issue.oracle.test.sh:141-171` (`test_secrets_are_scrubbed`) calls `redact` on a PEM block and on a probe of `SECRET_PATTERNS`. It also requires `gh[pousr]_` on exactly one line of `po-gate.sh` (`:162`). It stays green if the private-key branch and `SECRET_PATTERNS` are untouched and no comment repeats a pattern. `tests/gate.test.sh` and others pin `pre-commit` verdicts, which `next_secret` and `secret_scan` decide, and the story leaves both alone. **No gap of `Owns` found.**
- Phrases pinned in `Owns` (`tests/intake-issue-becomes-a-story*.test.sh`). Each phrase a task touches can be kept verbatim, so no assertion needs to move (listed in the plan).
- `tests/readme-onboarding.test.sh` clones committed HEAD (#254). This story touches neither `po/` nor `README.md`, so that test is not hit. The full suite is meaningful only on committed code.
- Mechanics of a pending intake PR: the root holds the pending copy staged. A run that goes on writes its stories on that copy, so the new branch (built on `origin/<Target>`, `po-setup.md:73,81`) carries the pending stories too. In a scratch repo, two intake commits that both append at the end of `docs/stories.md` conflict on rebase. Either the new PR supersedes the pending one, or they conflict (the review's "contained" damage).
- `.claude/` and `.polype/` are installed copies: never edited.

## Open questions
- How `gh issue list --json author` renders the Actions bot (`app/github-actions`?) was not checked; it only matters for the wording of the held line.
- Should a superseded intake PR be closed by the run? The plan says no: the finish names it, and a person closes it.

## Complexity
3 → 3. The redact fix is local. The three prose rules sit in one command, under a word ceiling that needs about 100 words cut.

## Split
— (not at 5)
