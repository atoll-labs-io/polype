---
validated: yes
---
# Plan — s177-intake-follow-ups

[Story](../stories.md) · [Research](../research/s177-intake-follow-ups.md)

Branch `story/s177-intake-follow-ups`. Read `docs/research/s177-intake-follow-ups.md` first. This plan builds on it without repeating it.

## Story
Close the open findings of the s151 and s152 reviews (owner decision D6 b). `po-gate redact` judges each match on the original line, so it erases exactly what the pre-commit scan flags. Under `github`, `/po-intake` takes in only issues authored by the login `gh auth status` reports. A pending `framing/intake-*` pull request no longer stops later runs. Numbering counts the pending intake branches. `po-intake.md` stays at 1550 words or fewer. Criteria: `redact_follows_the_scan_rule`, `only_the_hook_account_is_taken_in`, `pending_intake_does_not_block`, `numbering_sees_pending_branches`, `intake_holds_in_its_words`.

**Word baseline:** `LC_ALL=C wc -w method/commands/po-intake.md` → **1550**, taken on `story/s177-intake-follow-ups` before any change.

## Reuse
| New code | Rung that holds | Why each rung above fails |
| --- | --- | --- |
| Span marking in `redact` (awk, ~10 lines) | already in this repository: `next_secret` (`po-gate.sh:258-269`) decides every match, called on the original line | — (the new lines only stop rewriting the text the rule reads; no new matcher, no new pattern list) |
| Prose in `po-intake.md` | already in this repository: the ref enumeration of `po-intake.md:34` is reused for numbering and for the pending-branch check | — |

## Acceptance tests
| Oracle file | cksum |
| --- | --- |
| `tests/intake-follow-ups.oracle.test.sh` | `1498109804 2215` |

| Criterion | Test |
| --- | --- |
| `redact_follows_the_scan_rule` | `test_redact_follows_the_scan_rule`: pins the scan's current verdicts on two witness lines, then requires `redact` to erase exactly those spans (a string right after a match survives; a value flagged whole leaves nothing). It fails on today's code. |
| `only_the_hook_account_is_taken_in` | — rule read by a model: no oracle and no phrase test; judged in review; `po-eval` control-arm candidate |
| `pending_intake_does_not_block` | — same regime; `po-eval` candidate |
| `numbering_sees_pending_branches` | — same regime; `po-eval` candidate |
| `intake_holds_in_its_words` | `test_intake_holds_in_its_words`: `LC_ALL=C wc -w` ≤ 1550 |

## Tasks
1. [x] **Fix `redact`** (`method/hooks/po-gate.sh:289-295`, root cause in the research). For each line, keep the original text. For each non-private-key pattern `i`, walk `next_secret(orig, i, from)` with `from = SM_START + SM_LEN`, marking positions `SM_START … SM_START+SM_LEN-1`. Then print the line with each maximal run of marked positions replaced by one `[redacted]`. Rewrite the comment at `:272-273` to say each match is judged on the original line. Leave `SECRET_PATTERNS`, `SECRET_MATCHER` (`next_secret` included), `secret_scan` and the private-key branch `:279-288` byte-for-byte. Name no pattern in a comment: `failing-check-files-an-issue.oracle.test.sh:162` counts lines holding `gh[pousr]_`. Tests that fail if it is wrong: oracle `test_redact_follows_the_scan_rule`; existing `test_redact_keeps_near_miss_and_erases_each_token` (`tests/failing-check-files-an-issue.test.sh:40`, two separate tokens stay two `[redacted]`); `test_secrets_are_scrubbed` (`tests/failing-check-files-an-issue.oracle.test.sh:141`). Run: `bash tests/run.sh intake-follow-ups.oracle.test.sh failing-check-files-an-issue.test.sh failing-check-files-an-issue.oracle.test.sh gate.test.sh`.
2. [x] **Author filter** (`po-intake.md` `## The issues to take in`, `:28-30`, and `## Finish`). Under `github`, the listing adds `author`: `--json number,title,author`. The login is the one `gh auth status --hostname github.com --active --json hosts` reports for `github.com`. Check 7's pass/fail stays the plain call, since `--json` exits 0 even when logged out. Only an issue whose author login equals it is taken in. Any other labelled issue is listed in the finish with its number, marked "held: author", at every run. `taskwarrior` unchanged. Keep verbatim the pinned phrase `the open issues labelled \`polype-intake\` that no \`Fixes\` or \`Corrige\` line of \`docs/stories.md\` cites`. Judged in review (criterion 2).
3. [x] **A pending intake branch does not block** (`po-intake.md` check 8 `:25`, `## Landing` `:72`, `## Finish` `:80`). Check 8 keeps its first two sentences and the pinned phrase `` `docs/stories.md` differing from `origin/<Target branch>`, or holding an uncommitted change ``. It adds the exception. Both the working copy and the index of `docs/stories.md` must equal `docs/stories.md` of one `framing/intake-*` ref (the refs `## The issues to take in` reads). That ref must descend from `origin/<Target branch>`, checked with `git merge-base --is-ancestor`, and under `local` from `Target branch`. When both hold, that pending pull request carries the difference and the run goes on. Any other difference stops, with a message that names the real reason: the root holds stories that no pending intake branch carries. The run's stories are then appended to that copy, so the new branch carries the pending stories too. The landing therefore also commits the `docs/reviews/stories-intake-*.md` files the root holds staged. The finish names the pending pull request the new one supersedes, so a person merges the newer one and closes the older one. The run closes nothing. Judged in review (criterion 3).
4. [x] **Numbering** (`po-intake.md:46`). After the pinned phrase `numbered from the next free \`s<n>\``, the ids taken on every ref that `## The issues to take in` reads count as taken too, so two intake pull requests never carry the same `s<n>`. Judged in review (criterion 4).
5. [x] **Words**: bring `po-intake.md` back to 1550 words or fewer. Tasks 2-4 add roughly 90-110 words. Cuts available, none of them pinned: `:15` "It runs unattended, … through its finish." (25 words; keep "it asks nothing" somewhere); `:65` first sentence "Only the new stories, … when it was written." (24; the pinned lowercase phrase lives in the prompt at `:63`); `:34` last sentence "A framing pull request still waiting … written twice." (17; task 3 restates it); `:15` "It is the one exception Law 7 names (ADR-0099)." (9). Keep every heading `section_of` reads (`Checks`, `The issues to take in`, `Writing the stories`, `The review`). Test: oracle `test_intake_holds_in_its_words`, plus `bash tests/run.sh intake-issue-becomes-a-story.oracle.test.sh intake-issue-becomes-a-story.test.sh overlap.test.sh`.
6. [x] **`docs/harnais.md:98`**: one sentence for the author rule. `/po-intake` takes in only the issues its own `gh` login filed. Under the GitHub Actions example, the workflow's bot account files them, so a `/po-intake` run elsewhere holds them for the person. `:17` ("même liste, même règle") stays as it is, since the story makes it truer. Keep the pinned lines (`# Le harnais`, `po-intake --label`, `schedule:`, `cron:`, `[Timer]`, `OnCalendar=`, and the `po-intake.sh --label … claude -p '/po-intake'` line). Check: `bash tests/run.sh failing-check-files-an-issue.oracle.test.sh intake-issue-becomes-a-story.oracle.test.sh`.

Then the full suite once through `po-run --story s177-intake-follow-ups --label full-suite -- 'bash tests/run.sh'`, on committed code (see Traps of the research: `readme-onboarding` clones HEAD). The project has no type check (`Typecheck: —`).

## Scene viewpoints
—

## Run interdicts
- `method/hooks/po-intake.sh`: empty diff. The account need not be read or written there.
- `method/hooks/po-gate.sh`: diff confined to `redact()` and its comment (`:272-299`). `SECRET_PATTERNS`, `SECRET_MATCHER`, `secret_scan` and every other function stay byte-for-byte.
- `tests/intake-issue-becomes-a-story.oracle.test.sh` and `tests/intake-issue-becomes-a-story.test.sh`: empty diff. Every phrase they pin is kept verbatim (list below).
- Out of `Owns`, empty diff: `tests/failing-check-files-an-issue.oracle.test.sh`, `tests/intake-title-bounded.oracle.test.sh`, `po/`, `README.md`, ADR-0090, ADR-0099, `.claude/`, `.polype/`.
- The issue title bound (s151 major, fixed by s160) is not touched. No issue is filed or closed, and no pull request is closed.
- `tests/intake-follow-ups.oracle.test.sh` keeps its cksum, unless a row in `## Oracle changes` of the record names the change.

**Assertions that pin `po-intake.md`, one by one: none moves.** `intake-issue-becomes-a-story.oracle.test.sh`:
- `test_intake_writes_defect_stories`: the phrases at `:28` (task 2) and `:46` (task 4) are kept verbatim; the other five are untouched.
- `test_intake_stories_reviewed_first`: `:61` keeps `subagent_type` and `Model strong` on one line; `only the new stories, each with its issue as its scope source` lives at `:63` (task 5 cuts `:65`, not `:63`); the other three phrases are untouched.
- `test_intake_lands_as_framing`: five phrases, of which task 3 edits `:72` without touching `landed as \`## Landing the framing\` of \`/po-setup\` says` or `on the branch \`framing/intake-<timestamp>\``.
- `test_security_issue_goes_to_the_person`: untouched.
- `test_law_7_names_the_exception`: harnais line kept (task 6).

`intake-issue-becomes-a-story.test.sh`:
- `test_root_brought_level_before_reading`: its three phrases are kept (task 3).
- `test_refused_review_puts_the_copy_back` and `test_no_tracker_or_failed_listing_stops`: untouched.
- `test_pending_framing_branches_cite_too`: `:34` keeps both phrases (task 5 cuts only its last sentence).

## The pivot
**A run that goes on over a pending intake branch writes onto the root's copy, so its pull request supersedes the pending one; it does not try to keep two separate PRs mergeable.** `po-setup.md:81-85` builds the commit from the root's working copy over `origin/<Target>`. In a scratch repo, two intake commits that both append at the end of `docs/stories.md` conflicted on rebase. Ways it could be wrong:
- The pending copy came from a merged branch, and newer stories reached `Target branch`. The `--is-ancestor origin/<Target branch>` condition rules that out, since a rebase-merged branch no longer descends from the new tip. The reviewer should confirm this from the text of task 3.
- Once the older PR is merged first, the root's staged copy (older + newer) blocks `git merge --ff-only`, and check 8 stops on "refused fast-forward". That is the existing stop, kept on purpose. The finish of the superseding run tells the person to merge the newer PR, which avoids it.
- The author rule: the login `gh auth status` reports is the hook's account only when both run under one login. Under the Actions example the issues are held, not taken in, which fails closed. Task 6 documents it.

## Files touched
`method/hooks/po-gate.sh`, `method/commands/po-intake.md`, `docs/harnais.md`, `tests/intake-follow-ups.oracle.test.sh` (written by the planner), `docs/research/s177-intake-follow-ups.md`, `docs/plans/s177-intake-follow-ups.md`, `docs/verif/s177-intake-follow-ups.md`. `tests/intake-follow-ups.test.sh` is created only if the implementer adds a test: `tests/run.sh` fails a file that holds none.

## Test strategy
- Automated: 2 oracle tests (above) of `Test budget` 25. `redact` is a shell function behind one subcommand, so its test calls `po-gate redact` and `po-gate pre-commit` on a scratch repo, with witness strings assembled at run time. The verdicts pinned are today's, so "the pre-commit gives the same verdicts as before" is checked in the same test. No implementer test is required. One extra redact case (e.g. two flagged spans touching) may go in `tests/intake-follow-ups.test.sh` if the implementer wants it.
- Existing tests that guard the change: `test_redact_keeps_near_miss_and_erases_each_token`, `test_secrets_are_scrubbed`, `tests/gate.test.sh` (pre-commit verdicts), the two `intake-issue-becomes-a-story*` files (pinned phrases), and `tests/overlap.test.sh` (prose).
- Judged in review, no test (direction of 2026-11-13): criteria 2, 3 and 4. All three are candidates for a `po-eval` control arm (#208).

## Done when
The story is one commit with the code, oracle, research, plan and record; the full suite is green through `po-run`; the review has no open critical finding; then it lands through a pull request as `s177-intake-follow-ups: <title>`.
