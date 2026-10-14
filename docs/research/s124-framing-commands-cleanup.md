# Research — s124-framing-commands-cleanup

[Story](../stories.md)

## Structuring facts
- Defect story (`Corrige` line, `docs/stories.md:1928`): eleven `HOLDS` rows of `docs/reviews/triage-2026-10-14.md` point into its `Owns` (rows 112-115, 119, 141, 143, 160, 161, 164, 177). All eleven reproduce on the worktree as it stands; each root cause is one line of text, listed in `## Diagnostic`.
- Wrong assumption: the rows' line numbers are stale. The fix-path "Next" is `method/commands/po-stories.md:62` (Finish) reached through `:56`; the Outcome overlap is `method/commands/po-stories-review.md:56-59`; `po-architect.md:72` is right.
- Three triage rows naming s106/s110/s121 are **not** this story's: the secret-scan row (142, `po-setup.md:79`) is claimed by s127's criterion `hooks_say_what_they_do`; the s110 plan checkbox (162) and the s121 realignment noise (186) are set aside by `docs/stories.md:1916-1917`.
- Moving "(ADR-0086)" inside the sentence it ends would break `tests/no-claude-md.test.sh:106-110`, which holds the whole sentence ending "go in `AGENTS.local.md`." and is not in `Owns`: the reference has to move into the preceding sentence instead.
- Two unowned tests freeze text this story edits: `tests/ship-follows-forge.test.sh:20-22` requires Step 1 of `po-setup.md` to keep `## The forge's review rule`; `tests/tech-choice-backstop.test.sh:57-74` mutates the exact sentences "A story with a `story/<id>` branch … it is not reopened here." and "never changed: a verdict is the subagent's … owner's.".

## Story
As project owner, the framing commands stop contradicting each other and their rules are held by tests. Criteria:
- `stories_paths_agree` — `/po-stories` fix path announces `/po-stories-review` next; a set-aside story re-runs "Before writing" on the others; a blocked `/po-stories-review` matches one Outcome only; `templates/prd.md` no longer asks to reread the whole document.
- `setup_landing_holds` — `/po-setup` reads the forge once `Target branch` is known; says what happens when `git merge --ff-only framing/<slug>` is refused in `local`; "never commits to `Target branch` directly and never pushes it" is held by a test.
- `framing_wording_is_clean` — "means not merged" held by a test; the order check of `test_root_realigns_after_a_merge` checks a real rule; no capital after a colon just for a test; "(ADR-0086)" inside its sentence in `/po-setup` and `/po-architect`.

## Diagnostic
Reproduction: each row was reread on the worktree (HEAD of `story/s124-framing-commands-cleanup`, same tree as main 6830ec4) and grepped in `tests/`. No command runs these texts; reading is the reproduction.

| Row | Root cause (`path:line`) | Proof |
| --- | --- | --- |
| 113 | `po-stories.md:56` sends the fix path to "Finish", whose only finish line `:62` says "Next: /po-research <first story id>" | `po-stories-review.md:58` asks "Run /po-stories <ids>, then /po-stories-review again" |
| 114 | `po-stories.md:54` runs "Before writing" only on a rewritten story; Set aside has no rerun | main sequence does it, `po-stories.md:36` "runs again on what remains, since a dependency may now be broken" |
| 115 | `po-stories-review.md:40` writes a blocked review with `Stories ready: no`; `:58` (`Stories ready: no`) and `:59` (blocked) both match it | no bullet excludes the other |
| 112 | `templates/prd.md:9` "`status` stays `draft` until the user has read the whole document" | `po-prd.md:33` "the commit asks for no rereading", `:56` sets approved without reading |
| 119 | `po-setup.md:27` reads the forge in Step 1, before question 1 (`:32`) gives `Target branch` | `po-ship.md` forge rule: CODEOWNERS "read … from `origin/<Target branch>`", protection "on `Target branch`" |
| 141 | `po-setup.md:95` `git merge --ff-only framing/<slug>` then `git branch -d`, no refusal case | `pr` mode has one at `:68` and `:90` ("A refusal is reported") |
| 143 | `po-setup.md:61` "It never commits to `Target branch` directly and never pushes it." | `grep -rF 'never pushes it' tests/` → nothing |
| 160 | `po-setup.md:71` "Any other state, or no pull request from that branch, means not merged." | `tests/framing-second-landing.test.sh:22-24` lists five strings, not this one |
| 161 | `tests/framing-second-landing.test.sh:53-55` compares `**The commit, built beside the checkout**` with `read-tree <base>` | both sit in that block's fixed layout (`po-setup.md:77-78`): the test cannot fail while the realignment (`:68`) moves |
| 164 | `po-setup.md:71` "→ stop: Ancestry is never the proof" | `tests/framing-second-landing.test.sh:24` greps the capitalised phrase |
| 177 | `po-setup.md:56` and `po-architect.md:72` end "…go in `AGENTS.local.md`. (ADR-0086)" | reference stands outside any sentence |

Hypotheses on the cluster, each refuted or kept:
- H1 "a later story already fixed some of them" — refuted: every row reproduces at the cited text above (s121 rewrote `po-setup.md` Base but kept `:71` and `:95`).
- H2 "existing tests hold the untested clauses under other words" — refuted: `grep -rF` for 'never pushes it', 'Any other state', 'means not merged' in `tests/` returns nothing.
- H3 "the overlaps are deliberate" — refuted for 113/115: `po-stories-review.md:58` explicitly expects the review to run again, which the fix path never announces.

## Current code
- `method/commands/po-stories.md` — `## A story sent back by the review` (`:51-56`) rewrites or removes sent-back stories; it reuses `## Finish` (`:58-62`) for the commit and finish line.
- `method/commands/po-stories-review.md` — `## Recording` (`:37-40`) writes the blocked fallback; `## Outcome` (`:56-59`) three bullets keyed on `Stories ready:` and "A blocked review".
- `method/templates/prd.md:9` — status rule of the PRD.
- `method/commands/po-setup.md` — Step 1 (`:21-29`), Step 2 Ship confirmation follow-up (`:40`), Step 3 item 4 (`:56`), `## Landing the framing` (`:60-97`): Base `:65-75`, commit `:77-81`, `pr` `:83-90`, `local` `:92-95`.
- `method/commands/po-architect.md:72` — commit item of Approval and commit.
- `tests/framing-second-landing.test.sh` — three tests on the Base block (`base_block` `:10-13`).

## Attachment points
- Fix-path finish line: `po-stories.md:56`.
- Set-aside rerun: new bullet in `po-stories.md:51-56`.
- Outcome exclusivity: `po-stories-review.md:57-59`.
- PRD status: `templates/prd.md:9`.
- Forge timing: `po-setup.md:27` and `:40`.
- Local refusal: `po-setup.md:95`.
- ADR-0086: `po-setup.md:56`, `po-architect.md:72`.
- New tests: `tests/framing-commands-cleanup.test.sh` (in `Owns`); edits: `tests/framing-second-landing.test.sh:22-24`, `:51-55`.

## Verified interfaces
- `tests/lib.sh`: `fail`, `contains <file> <exact>`, `require_file`, `$METHOD` = `<repo>/method` (`tests/lib.sh:5-11`).
- Local idiom `section_of` / `holds` / `offset`: `tests/framing-second-landing.test.sh:6-15`, `tests/framing-through-pr.test.sh:18-22`.
- Runner: `bash tests/run.sh <file>` runs every `test_*` (`tests/run.sh:1-30`).
- Review status values: `complete | blocked` (`method/templates/stories-review.md:5`).

## Traps
- `tests/no-claude-md.test.sh:106-110` holds the CLAUDE.md sentence with its final `.` in `method/AGENTS.md`, `po-setup.md`, `po-architect.md` — do not alter that sentence.
- `tests/ship-follows-forge.test.sh:20-22`: Step 1 of `po-setup.md` must keep the literal `## The forge's review rule`; `:23-25` Step 2 keeps an unnumbered "AskUserQuestion call for `Ship confirmation`" and "`automatic (chosen)` (suggested) and `human (chosen)`".
- `tests/platform-setting.test.sh:75-79`: Platform follow-up stays unnumbered and before the catalogue offer.
- `tests/framing-through-pr.test.sh:39-44`: no line of a framing command may match `commit[^.]* on (\`Target branch\`|the target branch)` (case-insensitive) or carry a `git push` without `framing/<slug>`; `:51-55` the landing keeps `git merge --ff-only framing/<slug>` and `AskUserQuestion`.
- `tests/tech-choice-backstop.test.sh:57-74` mutation anchors listed in Structuring facts.
- `tests/conversational-framing.test.sh:14-27`: no "read the whole" in the six commands; `:56-65` phrases of po-stories-review / po-stories (`/po-stories <ids>`, `sent back by \`/po-stories-review\``, `keeps its id`, `has already started`).
- `tests/framing-realign-and-orchestrator-log.test.sh` and `tests/framing-through-pr.test.sh` read the same landing section; run them after the edits.
- `tests/overlap.test.sh`: new wording must be original (ADR-0006).
- No migration; nothing installed (`.claude/`, `.polype/`) is edited.

## Open questions
- `method/templates/brief.md:8` carries the same "the user has read the whole brief" rule as `prd.md:9`, but it is not in `Owns` and no triage row names it. Left out; a person may open a story or issue for it.
- When a set-aside story breaks a story that was not sent back, the fix path today may rewrite only sent-back stories (`po-stories.md:52`). The plan widens that to the stories the removal breaks, through the one-story question; see its pivot.
- s127's secret-scan criterion may need `po-setup.md:79`, inside this story's `Owns`: the two lanes then cannot run at once (Owns overlap rule), or s127 limits itself to `po-gate.sh`.

## Complexity
Story: 2 → after reading: 2. Eleven one-line text fixes in five owned files, two test edits and one new test file; the only judgement calls are the set-aside rerun scope and the local refusal behaviour.

## Split
—
