# Stories review, second pass: Polype, M21, s175-held-says-what-collides, the reworked s173-drive-executes-next and s170's `Dépend de`

> Note by the lead, 2026-11-14: this file holds the reviewer's second pass, word for word. Its first pass, on the same working tree before the fixes, ended `Max severity: critical` and `Stories ready: no`, with these findings, each of which the second pass names again under `## Earlier findings`: C1 (s175 and s170 overlapped in `Owns` with no dependency between them), M1 (the colliding path does not always exist, and `overlap.rs` computes none), M2 (s173 rated 3 where its research measured 4), m1 (a new `held[].reason` value and the contract number), m2 (the `Parallel` slot rule changed instead of moving), m3 (no carrier for the closed pull request), m4 (`/po-execute` without `po`), m5 (title against heading line), m6 (two word counts), m7 (s175 numbered above s173).

I re-read the current working tree of `/home/lecrabe/dev/atoll/polype/docs/stories.md`:
- the M21 introduction (l.2588);
- s175 (l.2723–2738);
- s170 (l.2740–2755), s171 (l.2757–2773) and s172 (l.2775–2789);
- s173 (l.2791–2807).

The scope references are the same as in the first pass: the M21 introduction, `docs/direction.md`, d-0008 to d-0010 as described, the s173 research and ADR-0120. I checked each fix against the file, not against the lead's message. `Platform: cli`, `Entry mode: —`.

Review status: complete

## When blocked
- Failure cause: none
- Missing: none
- Required adaptation: none
- Next action: none

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| d-0008 (b): `/po-execute` runs `po next` through a permission naming only that verb | owner answer; ADR-0120 | s173 `execute_refuses_a_shape_blocked_fix`, with `bin/po-lint` and the three shell tests in `Owns` | yes |
| d-0009: a story missing from the start point gets no lane, now computed in `po next` | owner answer | s175 `story_off_the_start_point_is_held` (reason `framing`, start point in `ref`, keeps its `Parallel` slot), `routing_cases_follow` | yes |
| d-0009: a closed pull request goes to a human. It stays in prose now and joins `po next` once `po next` reads the forge | owner answer | now: s173 `drive_executes_what_it_reads`. Later: issue #286, cited by s175, s173 and the introduction | yes (I did not check that #286 exists) |
| d-0009: a failed ship goes back to a fix run, kept in prose | owner answer | s173 `drive_executes_what_it_reads` | yes |
| d-0010 (a): `po next` returns the colliding path (#280) | owner answer | s175 `owns_collision_names_the_path`, with `null` when no common path can be named | yes |
| Finding 1: test files outside `Owns` pin phrases the story removes | research | s173 `Owns` | yes |
| Finding 2: `/po-execute` has no shell | research | ADR-0120; s173 crit. 3, which now also says what happens without `po` | yes |
| Finding 3: three routing rules have no case | research | start point → s175; closed PR and failed ship → prose in s173 | yes |
| Finding 4: `held` has no colliding path | research | s175 crit. 1 | yes |
| The contract stays at `1` | `interface-agent.md` l.30 | s175 `contract_says_the_new_fields`, which now adds a rule for values added to a closed list | yes (n1) |
| Criteria sorted into the owner's three cases | `AGENTS.local.md` Direction | no change since the first pass; still sound | yes |

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| A test for a phrase no script reads | direction | none | no |
| A crate dependency beyond ADR-0118 | ADR-0118 | none: s175 notes say "Aucune dependance de plus" | no |
| `po` querying a forge without being asked | `interface-agent.md` l.33 | none: s175 reads the ref locally; the closed PR is deferred to #286 | no |
| `/po-orchestrator` and `/po-flow` rerouted | ADR-0109 | none | no |
| A technical choice settled alone | direction | none | no |

## Checks
- [x] **Exclusions.** No excluded item comes back.
- [x] **No technical layer dressed as a story.**
- [x] **Every criterion can be checked by one test.** s175 crit. 1 now says what is returned when no common path exists (n2 is a wording point).
- [x] **Dependency order after the move.**
  - In file order: s174 (2667) < s168 < s169 (2703) < s175 (2723) < s170 (2740) < s171 (2757) < s172 (2775) < s173 (2791).
  - s175 depends on s168 and s169, which are earlier.
  - s170 depends on s167, s169, s174 and s175, which are earlier.
  - s172 depends on s170, which is earlier.
  - s173 depends on s167, s168 and s175, which are earlier.
  - s171 depends on s165 and s169, which are earlier.
  - The introduction's order sentence matches every `Dépend de`.
- [x] **Complexity.**
  - s175 is rated 3, which fits the witness-path work and the start-point read.
  - s173 is rated 4 and names its risk (about twenty test files, and the narrowed permission that is not yet proven). It also keeps the split for more than ten tasks.
- [x] **Ids.** Both are well formed and unique. s175 is numbered above s170 and s173 but sits before them in the file, which is accepted (m7).
- [x] **Owns, check 8, against every story that can still open a lane.**
  - s175 against s170: they overlap on `po/src/context/` ⊇ `mod.rs` and on `docs/interface-agent.md`. s170 now depends on s175, so this is fine.
  - s175 against s169 (in flight): they overlap. s175 depends on s169, so this is fine.
  - s175 against s171: disjoint. s175 owns nothing under `bin/`, nor `docs/installation.md` or `docs/ci.md`.
  - s175 against s172: disjoint, and s172 reaches s175 through s170 anyway.
  - s175 against s173: s173 depends on s175.
  - s170 against s171, against s172 and against s173: all three pairs are disjoint (s172 depends on s170 in any case). s173 and s170 have no chain between them, but `method/commands/…` against `method/hooks/po-run.sh` and `method/templates/…` differ at the second segment, and their test files have different names.
  - s171 against s172 and s173: disjoint (`bin/po-release` and `bin/polype` against `bin/po-lint` are different plain names).
  - s172 against s173: disjoint.
  - s171 against s169: both own `docs/installation.md`; s171 depends on s169.
  - Both stories have their oracle file in `Owns`.
- [x] **Surface.** Both are `command`, which `cli` admits.
- [x] **Owned records.** Both `Corrige` lines name GitHub issues. ADR-0120 supersedes nothing.

## Earlier findings
- **C1 — settled.** s175 now sits at l.2723, before s170 at l.2740. s170 lists `s175-held-says-what-collides` under `Dépend de`. The introduction says "s171 après s169, s170 après s175" and "s175 … placée avant s170 qui partage ses fichiers et dépend d'elle". The cost: s170, and s172 behind it, now also wait for s175.
- **M1 — settled.** The criterion now gives `null` when a common path cannot be named. The note now says `overlap.rs` "dit seulement si deux entrées se recouvrent" and that the witness is built beside it. Complexity is now 3. A wording point remains (n2).
- **M2 — settled.** s173 is rated 4 with its risk named, and the notes ask for the split before validation if the plan exceeds ten tasks.
- **m1 — settled.** The reason is `framing` with the start point in `ref`. Crit. 3 adds the rule that a value added to a closed list keeps the contract number and that readers tolerate unknown values (n1).
- **m2 — settled.** The held story "garde sa place de `Parallel`, qu'aucune autre story ne vient remplir", as `po-drive.md` l.92 does today.
- **m3 — settled in the file.** s175, s173 and the introduction cite issue #286 instead of s170. I did not check that #286 exists.
- **m4 — settled.** s173 crit. 3 now says: without `po`, or on exit 2, `/po-execute` refuses the fix run, names the installer, and does not fall back to the old reading.
- **m5 — settled.** The criterion now reads "aucune ligne de titre (`## <id>` ou `### <id>`) ne nomme l'id".
- **m6 — settled.** It now says "5 356 avant".
- **m7 — left as is, as agreed.**

## Findings
- **minor** n1 — s175 — **The compatibility rule is new contract text.** "une valeur ajoutée à une liste fermée ne change pas ce numéro" widens what `docs/interface-agent.md` promises to every external agent. It is not just a description of s175's fields. It is sound, and it cites the spirit of ADR-0117, but neither d-0010 nor any ADR approves it. If the lead treats a contract rule as the owner's to approve, it should go through the inbox. Also, `ref` now holds a git ref for `framing`, where elsewhere it holds a story or a decision id. Crit. 3 should say that in the contract.
- **minor** n2 — s175 — **The parenthesis reads as the only `null` case.** "(deux jokers dans le même segment)" is one case where the overlap is kept without a common path. Two others exist:
  - `**/x.md` against `src/y.md` overlaps by the rule that everything after `**` counts, yet no path matches both;
  - so does `**/*.md` against `**/*.ts`.

  The general clause before the parenthesis already covers them. Write "par exemple" so the planner does not limit `null` to `*` against `*`.

## Per story
- **s175-held-says-what-collides:** ready to plan once s169 ships. n1 and n2 can be settled in the plan.
- **s170-trust-signals:** the new dependency is correct and the order holds.
- **s173-drive-executes-next:** ready to plan once s175 ships.
- **ADR-0120:** unchanged since the first pass; still coherent with d-0008 and with s173.

## Not verified
- **Whether issues #286 and #280 exist.** I have no shell, so I could not query the tracker.
- **The inbox decisions d-0008 to d-0010, and any owner approval of the new contract rule (n1).** I did not read them.
- **Whether ADR-0120 changed since the first pass.** I did not re-read it, because the message lists no change to it.
- **`docs/interface-agent.md` beyond l.95, and the rest of `po-drive.md` past l.100.** Not read.
- **s153 to s155 `Owns`.** Not reread; they reach these stories through s170.
- **Whether s173 fits under ten plan tasks.** It is still judged from the text only; the split instruction covers the risk.
- **The shipped and in-flight status of s164 to s169 and s174.** Taken from the brief.

Max severity: minor
Stories ready: yes

> Answered by the lead in the same landing, 2026-11-14. n1: the contract rule is put to the owner as inbox decision d-0012, which holds s175 until he answers; criterion 3 now says that `ref` then carries a git ref. n2: the parenthesis reads "par exemple" and names a second case. Issues #280 and #286 exist. Stories ready: yes.
