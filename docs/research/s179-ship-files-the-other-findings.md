# Research — s179-ship-files-the-other-findings

[Story](../stories.md)

## Structuring facts
- **Root cause:** `method/commands/po-ship.md:99` withholds every finding of a review whose `Lenses run:` line names the security lens ("has none of its findings filed"). A model applying Step 3 to such a review files nothing. Proof: 0 issues carry the ids of s170, s173, s177 or s178, whose reviews ran the lens, while s168, s171, s172, s174 and s175, which ran no lens, have 2 to 5 each (listing of `gh issue list --state all`, below).
- **The story assumes the owner already decided to file these findings again (D7 b). An accepted ADR still says the opposite.** `docs/decisions/ADR-0090-tout-ce-qui-est-a-traiter-devient-une-issue.md:28` (accepted) reads: "Un constat d'une revue dont la lentille Security a tourné, ou dont le texte touche la sécurité, n'est jamais déposé seul". ADR-0123 replaces ADR-0090 on one point only and adds "Le reste de l'ADR-0090 tient" (`ADR-0123-…:67`). `docs/decisions-log.md:272` records that the lead *announced* the refiling as a consequence of D7 b and that the owner "had not answered". Lifting the hold therefore needs a new ADR that supersedes ADR-0090 on that point. That is ADR-0124, and the owner has to decide it (security, ADR-0077).
- **`Owns` misses two files.** A partial supersede adds the new ADR to the old one's `superseded-by` (Law 6; ADR-0123 did it). `docs/decisions/ADR-0090-…md:8` is not in s179's `Owns`. Neither is `tests/intake-issue-becomes-a-story.oracle.test.sh:122`, which pins that line as exactly `superseded-by: [ADR-0099, ADR-0123]`.
- What s178 leaves in a recorded review: under `## Findings`, a line `Security findings: <n> — decision <d-NNNN>` in place of the marked items (`po/src/record/mod.rs:268`, `po/src/record/security.rs:33-35`). The line is not a list item and does not open with a severity word, so Step 3's net (`po-ship.md:88`) neither files it nor quotes it today.
- The `po` installed on this machine does not split. `strings ~/.claude/polype/po` holds no "none kept, this answer fails findings-shape", and the s178 review lists the installed 0.2.0 under "Not verified". A review recorded by an older `po` can therefore still carry a `- <severity> — [security] — …` item in public text. Step 3 has to hold such an item by its mark, not only by reading its text.

## Diagnostic
**Reproduction** (read-only, nothing created in the worktree):
- I listed every issue title with `gh issue list --state all --limit 1000 --json title`, then counted the titles starting `<id>-`:
  - Reviews that ran the security lens: s178 0, s177 0, s173 0, s170 0, s166 3.
  - Reviews whose `Lenses run:` starts with `none`: s172 5, s171 4, s175 2, s168 3, s174 3.
- The s177 review (`docs/reviews/s177-intake-follow-ups.md:61`, `:65`, `:71`) has an open major and an open minor that do not bear on security. No issue exists for either.

**Hypotheses:**
1. *Step 3's lens hold (`po-ship.md:99`) withholds them.* Refuted if a lens review had its ordinary findings filed by `/po-ship`. s166 has 3 issues, but decision d-0006 (`.polype/inbox/d-0006.json`, motive `security`, answer `a`) shows that the person had them filed by hand: "les huit constats des revues de s165, s166 et s167, retenus parce que la lentille sécurité a tourné". So the s166 issues confirm the hold rather than refute it. **Kept.**
2. *The findings' shape is not recognised by "Which findings" (`po-ship.md:87`).* Refuted by the shape itself: s177's items read `- major — method/commands/po-intake.md:25 — …`, the plain shape that line 87 lists. **Discarded.**
3. *The tracker could not be reached (`gh` missing, wrong forge).* Refuted by the same tracker taking 2 to 5 issues per non-lens story in the same weeks (`AGENTS.local.md`: `Issue tracker: github`). **Discarded.**

## Story
`/po-ship` files a review's open ordinary findings even when the security lens ran. It cites the security findings only by the count and decision id the review gives. Nothing private reaches a PR body, an issue, `docs/decisions-log.md` or the `/po-drive` report. `/po-retro` counts security findings from the count line and says it does not know their severities one by one. The four method files do not grow.
- `other_findings_are_filed_again`, `nothing_private_in_what_ship_writes` and `retro_counts_what_it_cannot_read` are model-read: they get no oracle test, the review judges them, and each is a `po-eval` candidate (#208).
- `words_hold` is checked by script.

## Current code
- `po-ship.md:75` (Step 2): the PR body gets "the review verdict (max severity and a summary of the findings)".
- `po-ship.md:86-99` (Step 3.2): which findings, the net (`:88`), title and body, never in a command, no duplicate, the trackers, and the security hold (`:99`).
- `po-ship.md:103`: the finish names the issues filed and "the findings held for the person, with why". `po-ship.md` does not write `docs/decisions-log.md`.
- `po-drive.md:103`: the rows of the decisions log. `:110`: the report "…the findings not filed and why, and the security findings held for the person". `:74` and `:112` both say that autonomous plans were approved without a human reading them.
- `po-retro.md:37`: the severities row ("a finding with no severity word counts as unrated"). `:49`: the output columns "findings critical/major/minor of the last review". `:14`: Bash is limited to `git rev-parse`, `git worktree list`, `git show` and `po state --all`, so the retro cannot open a decision. `:25`: two examples of the milestone match.
- `method/AGENTS.md:129` (Law 7): "A security finding or a security idea is never filed on its own: it goes to the person … (ADR-0077, ADR-0090)". This stays true after the story, because a marked finding reaches the person through its decision. `:71`: `## What goes to the person`, unchanged.

## Attachment points
- `po-ship.md:99`: replace the lens hold. Hold an item that carries `[security]` or whose text bears on security. Quote the `Security findings:` line as written.
- `po-ship.md:75`: the PR body carries that line as written.
- `po-drive.md:103`: in the log, a security finding appears only as its decision id. `:110`: the report quotes the line.
- `po-retro.md:37` and `:49`: count from the line, severities unknown.
- `docs/decisions/ADR-0124-…`: supersedes ADR-0090 on the lens point. ADR-0090's `superseded-by` is outside `Owns`.

## Verified interfaces
- Count line: `Security findings: {count} — decision {posted}` (`po/src/record/mod.rs:268`). The variant `Security findings: {count} — none kept, this answer fails findings-shape` is at `:250`.
- With `Ship allowed: yes`, the last block can only hold the `decision` variant. A refused shape is either re-asked or ends in a composed blocked report with `Ship allowed: no` (`po-review.md:42`). A gate that could not run also ends blocked (`po-review.md:42`), and `po` rewrites the line to `decision` before exiting 2 (`mod.rs:257-268`).
- The line sits right after `## Findings`, because `Split::public` puts it between `head` and `tail` (`security.rs:33-35`).
- `[security]` mark shape: `- <severity> — [security] — <path>:<line> — <the problem>` (`templates/review.md:58`, `security.rs:123-138`).

## Traps
- Word baselines (`LC_ALL=C wc -w`, the same under `fr_FR.UTF-8`):

  | File | Words | Room under its ceilings |
  | --- | --- | --- |
  | `po-ship.md` | 3302 | no ceiling test |
  | `po-drive.md` | 2483 | ≤ 2500 (`tests/drive-executes-next.oracle.test.sh:13`) |
  | `po-retro.md` | 976 | `-lt 977` (`tests/commands-read-po-state.test.sh:36`): no room |
  | `method/AGENTS.md` | 3739 | ≤ 3741 (`tests/answer-comes-back.test.sh:133`) and ≤ 3743 (`tests/decision-inbox.test.sh:106`) |
  | `## What goes to the person` | 378 | ≤ 378 (`tests/decision-inbox.test.sh:102`): no room |

- Phrases pinned outside `Owns` that the edits must keep:
  - `tests/review-findings-shape.test.sh:91-94` pins the net of `po-ship.md:88`.
  - `tests/everything-in-issues.test.sh` (in `Owns`) has `cut_finding` (`:127`), which runs the title/body commands of `po-ship.md:91-92`.
  - `tests/drive.test.sh:66`, `:103-104` and `:120` pin wave/ship/report phrases.
  - `tests/grouped-validation.test.sh:29` and `:45` pin `po-drive.md:84` and `:112`.
  - `tests/po-retro.test.sh` and `tests/commands-and-texts.test.sh:13-24` pin the retro's measures and Scope steps; they do not pin the `Correctifs hors jalon` example.
  - None of these pin `po-ship.md:75`, `:99` (other than `everything-in-issues`), `po-drive.md:74` "the wave report says that no human read it", or `po-drive.md:110` "held for the person".
- Phrases that change, in `Owns`: `tests/everything-in-issues.test.sh:78-79` pins 'A review whose `Lenses run:` line names the security lens' and 'a line that starts with `none` does not'. `:80` (`"not filed: security (ADR-0077)"`) and `:81-82` (Law 7) stay.
- `tests/ship.test.sh`, `tests/ship-through-pr.test.sh` and `tests/drive-executes-next.oracle.test.sh` pin no sentence these edits touch; the last one holds only the 2500 ceiling.
- This story does not touch `po/`: no version bump (ADR-0122), and #254 does not bite.

## Open questions
Both questions are settled. On 2026-11-14 the owner chose option A of ADR-0124 (d-0023), so ADR-0124 is now accepted. The two missing paths were added to `Owns` on main in commit cdf8e7b.

## Complexity
The story says 2. After reading the code, I score 2 for the edits (three prose rewrites, one test edit, one oracle) and 3 counting ADR-0124 and the `Owns` gap it opens.

## Split
Not needed.
