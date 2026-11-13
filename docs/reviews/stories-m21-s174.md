# Stories review: Polype, M21, one-off review of s174-verbs-read-project-context

I reviewed the working-tree `docs/stories.md` (`/home/lecrabe/dev/atoll/polype/docs/stories.md`), which has uncommitted changes. I wrote none of these stories. There is no PRD or brief (`Entry mode: —`; `Platform: cli`, from `AGENTS.local.md`). So, as in `docs/reviews/stories-m21.md`, I took the scope from these sources:
- the M21 introduction (l.2588);
- `docs/direction.md`;
- findings #248 and #249 in `docs/reviews/s164-state-as-json.md`;
- ADR-0118 (accepted);
- the three-case criteria rule in `AGENTS.local.md`, `## Direction`.

My scope was only these: s174 (l.2667–2681), s168's new `Depends on`, and the two sentences added to the introduction. I read s164 to s173 only to check what the three clients need, and for dependencies and overlaps.

Review status: complete

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| #249: the hand-offs (`lane_next`, `ready`, `held`, `session`, `bounds`, `shipped`) get the project root, lane paths, parsed stories, the shipped set, the settings and the worktree listing | s164 review, Findings, 2nd major | s174 `verbs_receive_one_context` | yes |
| #249: nothing the later verbs need stays private to `po/src/state/` | same | s174 `verbs_receive_one_context` ("Plus rien de cela n'est privé") | partly (M1) |
| s168 can be built inside `po/src/next/` (fix from a lane's review; ready and held from stories, shipped set, lanes, `Owns`, `Parallel`; serial ships; decisions) | #249; d-0005 | s174, plus s168 `Depends on` | yes, except whether an answered decision has been consumed (M1) |
| s169 can be built inside `po/src/run/` | #249 (client named in s174's notes) | s174 | partly: the framing stage is missing (M1) |
| s170 can be built inside `po/src/trust/` | #249 (client named in s174's notes) | s174 | partly: the current milestone and the landed commit are missing (M1) |
| #248: the rule "landed → `ship`" is tested, and the test fails when the rule is removed | s164 review, Findings, 1st major | s174 `landed_lane_reports_ship_whatever_its_review` | yes |
| The refactor leaves `po state` output unchanged, still read-only, no lock, under 1 s | s174 risk line; s164 rules | s174 `state_output_does_not_move` | yes (m1) |
| No new crate dependency | ADR-0118 Neutral | s174 notes | yes |
| Criteria sorted into the three cases | `AGENTS.local.md` Direction | crit. 1 and 2 by script, crit. 3 judged in review with no phrase test | yes |
| d-0005: a small story before s168 | introduction | s174 placed before s168; s168 depends on it; the introduction's order sentence matches | yes |

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| A test for a phrase no script reads | direction | none (crit. 3 is judged in review, with no test) | no |
| A crate dependency beyond ADR-0118 | ADR-0118 | none ("Aucune dépendance de plus") | no |
| s174 doing the clients' work (filling `next/`, `run/`, `trust/`) | s168, s169, s170 `Owns` | none: the notes keep it to signatures that return `None`, and the verbs stay `not-built` | no |
| Hooks rewritten in Rust; a technical choice made alone | ADR-0116; direction | none | no |

## Checks
- [x] **Exclusions.** No excluded item comes back.
- [x] **No technical layer dressed as a story.** s174 has no end user. It is allowed as a contract story:
  - its contract is observable, because `state` is rebuilt on it and the s164 oracle exercises it;
  - it has three consumers.
  - Only s168 names it directly (m2).
- [x] **Every criterion can be checked by one test.**
  - It has three criteria.
  - Crit. 2 names an input (a landed lane whose review is missing or stale), an action and an expected stage, and it asks for a test that fails when the rule is removed.
  - Crit. 3 is a code-structure rule judged by reading, as the owner's rule allows.
  - Crit. 1 is testable on the fixtures, but on "ce dépôt" it has nothing fixed to compare against (m1).
- [x] **Dependency order.** s174 depends on s164 and s166, both earlier and shipped. s168 depends on s174, which comes earlier in the file. s169 and s170 reach s174 through s168.
- [x] **Complexity.** s174 is rated 3 and its risk line names the risk. The scope fits well under ten tasks.
- [x] **Ids.** `s174-verbs-read-project-context` is well formed and unique. Its number is higher than s168's, which is known and accepted (m5).
- [x] **Owns.**
  - s174 shares files with s168 (`po/src/next/`), s169 (`po/src/run/`) and s170 (`po/src/trust/`), and with s165 to s170 on `tests/state-as-json.oracle.test.sh`. Each of these pairs has a dependency chain: s168→s174, s169→s168→s174, s170→s169→s168→s174, and s174→s166→s165.
  - s174 and s167 share `tests/state-as-json.oracle.test.sh` and have no chain between them. s167 has shipped (commit 173ac1d), so no lane can open for it. As in the earlier review, I applied check 8 only to stories that can still open a lane.
  - s171, s172 and s173 do not overlap s174: none of them owns anything under `po/src/` or `tests/state-as-json*`.
  - s153 to s155 reach s174 through s170.
  - Its oracle file, `tests/verbs-read-project-context.oracle.test.sh`, is in `Owns`.
- [x] **Surface.** `—` is admitted by `cli`, and it fits a story whose output must not change.
- [x] **Owned records.** The `Corrige` line names GitHub issues #249 and #248, so no `Owns` entry is needed. s174 supersedes no ADR.

## Findings
- **major** M1 — s174 — **The context list leaves out what s169, s170 and part of s168 must compute.** Criterion `verbs_receive_one_context` lists exactly what the context carries and what stops being private: root, settings, stories with dependencies and `Owns`, the shipped set, lanes with path and stage, and decisions with `status` and `blocks`. Against the clients' criteria, that list misses four things:
  - (i) **The framing stage.** s169 `run_starts_one_lead_session` launches "l'étape de cadrage manquante". Per m4 of the earlier review, its `nothing-to-do` refusal depends on framing too. `framing` is derived in `state/` (the s164 review says `mod framing;` is private).
  - (ii) **The current milestone, and the milestone of each story.** s170 `shipped_stories_carry_trust` reports the shipped stories "du jalon en cours", and all of them only with `--all`.
  - (iii) **The landed commit of each shipped story.** s170 `checks_are_read_only_on_request` reads the forge checks "sur le commit atterri". A set of ids does not carry it.
  - (iv) **Whether an answered decision has been consumed.** s168 `answered_decision_releases_its_lanes` releases a lane only once the decision is "répondue et consommée". If s166 records consumption outside `status`, the listed fields do not show it.

  The notes ask for "ce que leurs critères demandent de calculer", which softens this. But the reviewer judges crit. 3 against its list, and s169 and s170 each forbid touching any other folder of the crate. Left as is, the s169 or s170 lane could stop at `po/src/state/`, which is the defect #249 describes. Fix: add these four to the list, or say the list is a minimum and the three clients' criteria are the reference. Rated major, not critical, because it costs a lane, not a milestone (same reasoning as M1 in `stories-m21.md`).
- **minor** m1 — s174 — **`state_output_does_not_move` has nothing fixed to compare against on "ce dépôt".**
  - "le même objet qu'avant la story, champ pour champ" needs a saved output from before the change, and nothing names one.
  - On this repository, `commit` (and `lanes`, while work moves) differ from one run to the next anyway.
  - Say what is compared: for example, the binary from `main` and the binary from the branch, run on the same fixture and the same commit. Or keep the field-by-field comparison to the s164 oracle fixtures.
- **minor** m2 — s169, s170 — **They use s174's context but do not list s174 under `Depends on`.** They reach it through s168, so the order is safe. "Owns and contracts first", however, asks every user of a contract to list it.
- **minor** m3 — s174 — **`Owns` may be too narrow.**
  - The decisions in the context (`status`, `blocks`) are read by code in `po/src/inbox/`, which s174 does not own. If s165's reader is private, or its narrow view lacks `blocks`, the lane stops.
  - The criteria also do not say that the hand-off signatures must let s168 return its reasons (`dependency`, `owns`, `parallel`, `decision`, `ref`) without editing `state/`. That matters if the output types are defined there.
  - The research should check both points (see Not verified).
- **minor** m4 — introduction — **Two wording gaps.**
  - The new sentence names #249 but not #248, which s174 also fixes.
  - "un dossier par verbe, pour que deux stories ne tiennent jamais le même fichier" now has an exception: s174 edits `next/mod.rs`, `run/mod.rs` and `trust/mod.rs`. The dependency chain covers it, but one clause would say so.
- **minor** m5 — s174 — **Its id number (174) is higher than that of s168, which depends on it.** Known and accepted (ids never change); the file order is correct.

## Per story
- **s174-verbs-read-project-context:** can be planned. Widen or open up the context list (M1) before the plan, otherwise s169 or s170 will hit the same wall later. Settle m1 in the plan.
- **s168-driver-next-action:** the new dependency is correct and the order holds. Whether a decision has been consumed is part of M1.

## Not verified
- **The code** (out of scope: no code read). These points rest only on the s164 review and should be checked by s174's research:
  - what is private today in `po/src/state/`, `po/src/project.rs` and `po/src/inbox/`;
  - where the output types of `ready`, `held` and `lanes[].next` are defined;
  - whether the "landed → `ship`" rule is still at `lanes.rs:209`.

  These points decide m3, and whether crit. 1 and crit. 2 can both hold (I read #248 as "the rule exists but is untested", so the output should not change).
- **`docs/interface-agent.md` and s166's code.** I did not read them, so I do not know how a consumed decision is recorded: a `status` value or a separate field. That is M1 (iv).
- **Whether s174 fits under ten plan tasks.** Judged from the text only.
- **s153 to s155 `Owns`.** Not read. They reach s174 through s170 in any case.
- **Shipped status of s164 to s167.** Taken from the brief and the git log in the session context (s166 and s167 commits); s164 and s165 not confirmed in git.
- **The inbox decision d-0005.** I did not read it. Its content is taken from the brief and the introduction.

Max severity: major
Stories ready: yes

> Answered by the lead in the same landing, 2026-11-13. M1: the criterion's list now also names the framing stage, each story's milestone and the current one, the landed commit of each shipped story and a decision's `consumed` field (how s166 records consumption), and says it is a minimum, the criteria of s168, s169 and s170 being the reference. m1: the field-by-field comparison is between the story's `po` and the one of `Target branch` on the s164 oracle fixtures; on this repository only the read-only and one-second rules are checked. m2: s169 and s170 list s174 under `Dépend de`. m3: `po/src/inbox/` joins `Owns`, for opening the decision reader only, and the notes keep the output types in the verbs' folders. m4: the introduction names #248 and the exception to one folder per verb. m5: accepted as is. Stories ready: yes.
