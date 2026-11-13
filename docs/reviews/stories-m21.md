# Stories review: Polype, milestone "M21 — L'interface" (s164 to s173)

Stories reviewed: `docs/stories.md` (M21, l.2586–2774). I wrote none of these stories. This is a one-off review because there is no PRD or brief (`Entry mode: —`, Platform `cli`). The scope source is these files, read together:
- the M21 Objectif (l.2588);
- `docs/direction.md`;
- `docs/interface-agent.md` (contract v1);
- ADR-0106, 0107, 0108, 0115, 0116 and 0117, all `accepted`;
- the three-case rule in `AGENTS.local.md`, "Direction".

I read s153–s163 (and s156–s158 for `Owns`) only for dependencies and overlaps. I read `method/commands/po-drive.md` l.40–119 to see how a lane opens today.

Review status: complete

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| Polype is driven by one command, a Rust binary `po`, that returns JSON | Objectif; ADR-0106; ADR-0107; ADR-0117 | s164 | yes |
| New M21 code goes into the binary; the hooks stay in bash | ADR-0116 | s164–s170 (one `po/src/<verb>/` folder each); s170 and s172 edit hooks in bash | yes |
| One `po` per machine, found at one path | ADR-0117 | s164 (installer, path in `docs/installation.md`), s165 (`## Installed files`) | yes |
| `po` warns on a version mismatch and still answers | ADR-0117 cond. 1 | s164 `po_warns_on_another_version`, s172 shows the warning | yes |
| Older outputs stay readable; anything unreadable is `null` | ADR-0117 cond. 2; contract | s170 `unknown_is_null_never_guessed` | yes |
| An upgrade cleans what it cannot keep, and says so | ADR-0117 cond. 3 | s171 | yes |
| Built from sources, then prebuilt with a verified checksum, sources as fallback | ADR-0115 | s164, s171 | yes |
| Platforms and checksum location go to the owner | ADR-0115 "Restent à fixer" | s171 (two `Technical choice` lines) | yes |
| Inbox: local files, location is a setting, never in git | ADR-0107 | s164, s165 (`no-inbox-setting`, `inbox-not-ignored`) | yes |
| Common rules: one JSON object, exit codes 0/1/2, error shape, < 1 s, no model, no forge unless asked | contract | s164 (all verbs), s165 (`inbox` < 1 s, exit 1), s170 (`--remote`) | yes |
| `state` with every contract field | contract `## state` | s164 + s168 (`next`, `ready`, `held`), s169 (`session`, `bounds`), s170 (`shipped`), all through the s164 hand-off | yes |
| `inbox`, `inbox <id>`, decision shape, `sensitive` | contract `## inbox` | s165 | yes |
| `answer` takes only a listed option and launches nothing; the lead consumes the answer | contract `## answer` | s166 | yes |
| `run` and `continue` via `claude --bg`, one session, the three refusals, no free text | ADR-0107; contract | s169 | yes (minor m4) |
| Reports written by code (#202 and the issues it closes) | Objectif; ADR-0108 rule 3 | s167 | yes |
| Next action computed (#203); a review blocked on shape asks (#139) | Objectif; ADR-0106 | s168, s173 | yes (minor m3) |
| Trust signals (#205) | Objectif; contract | s170, s167 (version stamp, oracle line) | yes |
| `po-session`, `/po-status` and the agent read one state | ADR-0106; ADR-0116 Bad | s172 | yes |
| `/po-drive` only runs what the automaton says | ADR-0106 Neutral | s173 | yes (major M1) |
| `interface-agent.md` updated for `po`, `warnings`, the setting, the loop, the lead verbs, `track`/`--all` | Objectif; ADR-0107/0116/0117 | s164, s169, s170 | yes |
| No technical choice made by an agent alone | direction | s164 (crate dependencies), s171 | yes |
| Build order of the Objectif | Objectif | the `Depends on` lines match it exactly | yes |
| Word count of `method/` does not grow | Objectif; ADR-0108 rule 2 | s165, s166, s167, s172, s173; the rest is left to review | partly (minor m7) |
| Criteria sorted into the three cases | AGENTS.local.md | marked in s165–s167, s169, s171–s173 | yes |

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| Automaton in bash/jq; Agent SDK; MCP server, HTTP daemon or forge as inbox; `claude -p` | ADR-0106, ADR-0107 | none | no |
| Inbox tracked in git; copying decisions to a shared memory | ADR-0107 | none; s165 refuses it | no |
| Hooks rewritten in Rust | ADR-0116 opt. 3 | none (s170 and s172 edit `po-run.sh` and `po-session.sh` in bash) | no |
| Binary per project, launcher per project, binary committed | ADR-0117, ADR-0115 | none | no |
| Prebuilt only, or sources only | ADR-0115 | none | no |
| A model transcribing a report; a test for a phrase no script reads | direction | none | no |
| Removing `/po-orchestrator` and `/po-flow` (ADR-0109 `proposed`) | direction | none; s173 leaves them alone | no |
| s153–s155 | direction | none | no |

## Checks
- [x] **Exclusions.** No story revives an excluded item.
- [x] **No technical layer dressed as a story.** s164 is a contract that can be tried (`po state`) and has eight dependants.
- [x] **Every criterion can be checked by one test.**
  - Every story has seven criteria or fewer.
  - Rules read by a model have no oracle test, as the three-case rule says.
  - Minor m1 and m2 are wording that the planner could read two ways.
- [x] **Dependency order.** Every `Depends on` names an earlier, existing id.
- [x] **Complexity.** No story is a 5. Each 4 (s164, s168, s169, s171) names its risk.
- [x] **Ids.** s164–s173 are well formed, unique and grow in file order. Outside my scope: s153–s155 sit after s173, so the file as a whole does not number in order. The earlier review chose that placement.
- [x] **Owns.**
  - Within M21, the pairs with no dependency are disjoint: s165/s167, s166/s167, s167/s168, s167/s169, s167/s171, s169/s173, s170/s171, s170/s173, s171/s172, s171/s173, s172/s173.
  - Against M20, s164 now depends on s159 and s161. Through it, every M21 story that shares `bin/polype`, `method/AGENTS.md`, `AGENTS.local.md`, `docs/installation.md`, `.github/workflows/` or `docs/ci.md` reaches them.
  - s154 and s155 reach s159 and s161 again through s170.
  - I applied check 8 only to stories that can still open a lane: M21 and s153–s155. Read literally across the whole file, `bin/polype` or `po-drive.md` would overlap dozens of shipped stories from M1–M19, and no story could ever pass.
  - One observation, not rated: s167 takes over files of s156 and s158 (`po-drive.md`, `po-qa.md`, `po-review.md`, both templates, s158's oracle) without depending on them. Both have shipped (`po-drive.md:107` already transcribes the QA report). s164 follows the opposite pattern.
- [x] **Surface.** All ten say `command`, which `cli` admits.
- [x] **Owned records.** Every `Corrige` line names GitHub issues. No story says its ADR supersedes another. s165 owns the `docs/a-trancher.md` it deletes.

## Findings
- **major** M1 — s173 — **Its suite criterion cannot be met within its `Owns`.**
  - `phrase_tests_give_way_to_cases` says "la suite passe" once `po-drive.md` drops from 5 470 to 2 500 words and loses every routing rule.
  - Its `Owns` holds four test files, and its notes name no test outside them, unlike every other M21 story.
  - Earlier stories owned `po-drive.md` together with tests that this cut will very likely break:
    - `tests/resume.test.sh`, `tests/grouped-validation.test.sh`, `tests/model-routing.test.sh`, `tests/qa-fleet.test.sh`;
    - `tests/ship-follows-forge.test.sh`, `tests/escalation-contract.test.sh`, `tests/short-subject-shipped.test.sh`;
    - `tests/defect-and-routing-paths.test.sh`, `tests/ship-and-fleet-cleanup.test.sh`, `tests/owns-overlap.test.sh`;
    - `tests/everything-in-issues.test.sh`, `tests/review-findings-shape.test.sh`.
  - As written, the lane stops on the first of them.
  - Fix: after a search of `tests/` for phrases of `po-drive.md`, list those tests in `Owns`, or name them as staying unchanged.
  - I rate this major because it is the same kind of gap as the earlier M1 (work outside `Owns`): it costs a lane, not a milestone.
- **minor** m1 — s164 — **The expected `stage` has no reference that a script can apply.** `lane_stage_follows_the_gates` says "celui que `po-gate` donnerait", but `po-gate` checks gates and names no stage. Name the reference: the derivation in `po-session.sh`, which the risk line already cites, or the table of `po-drive.md` `## Resuming`. Say also how the current `milestone` is chosen. s170 relies on it too ("jalon en cours").
- **minor** m2 — s166, s168 — **The state "answered but not yet consumed" is routed two ways.**
  - `ready_and_held_say_why` holds a story for `decision` only while the decision is `pending`, so an answered decision makes the story ready.
  - `answered_decision_releases_its_lanes` releases it only once the decision is "répondue et consommée".
  - Say which one wins. The contract ("écrit ce que chacune produit … puis reprend les lanes") suggests: held until consumed.
- **minor** m3 — s168 — **The case "evidence commit without a new walk" (`po-drive.md:58`) has no action of its own.**
  - The action list is closed ("La liste des actions du contrat ne change pas").
  - Under s173, a `qa` action names the subagent, which would run a new walk.
  - Say which action and `reason` carry this case, so that s173 does not walk again.
- **minor** m4 — s169 — **A project in framing gets `nothing-to-do`.**
  - `run_refuses_when_nothing_to_do` refuses when there is "no ready story, no lane, no answered decision". That is always true before the stories exist.
  - Yet `run_starts_one_lead_session` launches "l'étape de cadrage manquante".
  - Add "framing done" to the refusal condition.
- **minor** m5 — s167 — **Two gaps in `po record`.**
  - (i) Where it writes: `record_refuses_the_wrong_branch` reads the current branch, and `/po-drive` never runs `cd` (`po-drive.md:87`). Say that `po record` resolves `<Worktree root><id>` from the id, as s165 says for the inbox, or how the coordinator calls it.
  - (ii) Later writes: no criterion covers the second write (a fix loop, or a `blocked` report the command composes), which s158 defines as "keeps its header, appends the new block".
- **minor** m6 — s167 — **s156's oracle file is missing from `Owns`.** s156's notes put its criteria in `tests/qa-report-returned-as-text.oracle.test.sh` once s149 has landed. Those criteria fix the heredoc transcription that s167 removes. `Owns` holds only `tests/qa-report-returned-as-text.test.sh`. If the oracle file exists, add it.
- **minor** m7 — s164, s167, s170, s173 — **The word rule still has no criterion for some files.**
  - `templates/agents-local.md` (s164);
  - `templates/review.md` and `qa.md` (s167);
  - `templates/verification-record.md` (s170);
  - `po-execute.md`, which gains a rule (s173).
  - These are left to review, as the Objectif says. The reviewer must count them.
- **minor** m8 — s164, s165 — **Polype's own `Decision inbox` line.**
  - s164 owns `AGENTS.local.md`, but no criterion sets `Decision inbox:` in it.
  - Without that line, `po inbox add` exits with `no-inbox-setting` on this repo. The lead then cannot re-post what `docs/a-trancher.md` still held, as `provisional_inbox_is_gone` plans.
  - Also, between the s165 and s169 ships, `interface-agent.md` l.5 links to a deleted file.
- **minor** m9 — s172 — **The list of tests outside `Owns` looks short.** Earlier stories that owned `po-session.sh` or `po-status.md` held tests such as `tests/short-subject-shipped.test.sh`, `tests/project-lead.test.sh`, `tests/update-keeps-mode.test.sh` and `tests/pilot.test.sh`. Have the research confirm which ones read the bash derivation.

**Findings of the previous review (`docs/reviews/stories-m21.md`), checked against the current text:**
- **C1 answered.** s164 depends on s159 and s161; every chain listed there is repaired, including s154 and s155.
- **M1 answered.** s164's notes say `state` asks `next/`, `run/` and `trust/` for their fields through a function that returns `null`, and that each verb's arguments, `--all` and `--remote` included, are read in the owning folder.
- **M2 answered.** `po inbox add` with no setting exits with `no-inbox-setting` and writes nothing; `polype update` reports the missing line.
- **M3 answered.** A ready story, or a lane with no research, gets `plan`. This matches `po-drive.md:51` and `:104`, where the planner does research, track and plan. A neighbouring case remains (m3 above).
- **m1 answered.** "Une date avec son décalage horaire" is on the dependency list.
- **m2 answered.** s159's oracle is named, and `ci.yml` changes only if the runner lacks `cargo`.
- **m3 answered.** The question is now one line of at most 200 characters.
- **m4 answered.** "Tout verbe … un seul objet JSON … 0, 1 ou 2"; s165's refusals exit 1; `inbox` must answer in under 1 s.
- **m5 answered.** s169 lists the lead verbs on their own.
- **m6 answered.** The path is in `docs/installation.md`, and `## Installed files` names `po`.
- **m7 still open** (now m7, the same list).
- **m8 answered in part.** s165 owns `AGENTS.local.md` and updates it. The `interface-agent.md` link is open between s165 and s169 (m8).
- **m9 answered.** The lead tells the person anyway when `po` is missing or refuses.
- **m10 answered.** The notes now exclude the test that `Owns` holds.
- **m11 answered.** A project-only install is always `unproven`; nothing is to be invented.

## Per story
- **s164-state-as-json:** can be planned as written (m1, m8 to clarify).
- **s165-decision-inbox:** can be planned as written.
- **s166-answer-comes-back:** can be planned as written; m2 is settled together with s168.
- **s167-record-writes-reports:** can be planned; settle m5 and m6 first, or its lane may stop at the coordinator or at s156's oracle.
- **s168-driver-next-action:** can be planned; m2 and m3 are cases for its table.
- **s169-run-from-outside:** can be planned; fix the m4 condition.
- **s170-trust-signals:** can be planned as written.
- **s171-po-prebuilt-and-verified:** can be planned as written, with two owner choices in its plan.
- **s172-commands-read-po-state:** can be planned; the research should widen the test list (m9).
- **s173-drive-executes-next:** can be planned, but its lane will very likely stop on tests outside its `Owns` (M1). Fix `Owns` before the plan.

## Not verified
- **Test contents (out of scope: no code read).** Which tests pin phrases of `po-drive.md`, `po-status.md` or `po-session.sh` (M1, m9). Whether `tests/qa-report-returned-as-text.oracle.test.sh` exists (m6). Whether a link test fails on the deleted `docs/a-trancher.md` (m8). The research of s167, s172 and s173 should check these.
- **The rest of `po-drive.md`.** I read only l.40–119. I did not match every other routing rule against s168's action list; m3 is the one gap I found there.
- **Other unconfirmed points:**
  - whether `/po-qa` itself commits the evidence without walking again (m3);
  - what `.polype/version` holds;
  - the "presumed" lines of `po-session` and their equivalent in `po state`;
  - how to tell that a `claude --bg` session is still running.
- **Shipped status of s156–s163.** Taken from `docs/direction.md` and `po-drive.md:107`, not from git.
- **Overlaps with M1–M19.** Not rated (see Checks, Owns).
- **Files I did not read:**
  - issue bodies #139, #172–#193, #202–#205, #209: coverage is judged against the Objectif's summary of them;
  - ADR-0109 and ADR-0110 (`proposed`);
  - `docs/a-trancher.md` (D5–D10);
  - the "Limite de confiance" section of `docs/installation.md`.

Max severity: major
Stories ready: yes
