# Stories review — Polype, M21: s176, the reworked s172, and the move of s153 to s155

Stories reviewed: `/home/lecrabe/dev/atoll/polype/docs/stories.md` (working tree, l.2588, l.2775–2807, l.2827–2829), `/home/lecrabe/dev/atoll/polype/docs/stories-reportees.md` (untracked) and `/home/lecrabe/dev/atoll/polype/AGENTS.local.md` l.72. There is no PRD or brief (`Entry mode: —`). As in `docs/reviews/stories-m21*.md`, the scope reference is `docs/direction.md`, the `## M21` introduction, the owner's answers d-0016, d-0017 and d-0018 as your message gives them, and the planner's findings in `.worktrees/s172-commands-read-po-state/docs/research/s172-commands-read-po-state.md`. `Platform: cli`. This review was done in a context that did not write the stories.

Review status: complete

**Verdict: no critical finding, so the stories are ready.** There are no majors either, only nine minors. The first one matters most: s172 does not say what the hook prints when `po state` adds warnings or returns `ready: null`. The planner flagged exactly that, so it could stop the plan again.

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| One reading of the state, in code (`po state`), #203 in part | direction.md "Ce qui est déterministe devient du code"; M21 Objectif | s176, s172 | yes |
| An external agent reads in `po state` what the session shows | direction.md "Ce qu'est Polype"; M21 Objectif | s176 (c1–c4) | yes |
| d-0017 c: first extend `po state` and its contract, then rewire the three commands | owner's answer | s176 → s172 (`Dépend de`) | yes |
| d-0018 a: the hook reads the JSON with `jq` and says so when `jq` is missing | owner's answer | s172 c1, c2 | yes |
| d-0016 a: s153 to s155 stay postponed, and the hold no longer rests on s170 | owner's answer; direction.md "Ce qu'on ne fait plus" | stub l.2829, `stories-reportees.md`, `AGENTS.local.md` l.72 | yes (stale note, see minor 5) |
| Finding 1a: framing per item | research, false assumption 1 | s176 `framing_items_are_listed` | yes |
| Finding 1b: lane path | research | s176 `lanes_carry_their_path` | yes |
| Finding 1c: every stop of a lane, with the fix-loop count | research | s176 `every_stop_of_a_lane_is_listed` | yes |
| Finding 1d: the `CLAUDE.md` / install-mode hint | research, open question 2 | stays in the hook: s176 c4 leaves it out, s172 c1 keeps it | yes (reading 1) |
| Finding 1e: `ready` without `Parallel`, and the Owns check | research H2 | s172 c1 (the ready line may change) | partly: the `null` case is not said (minor 1) |
| Finding 2: 16+ test files outside `Owns` | research table l.34–65 | s172 `Owns`. All 20 files of the table plus `session-and-gate-checks` are present; `state-as-json.test.sh` is shared with s176 along the dependency chain | yes |
| Finding 2b: the suite's empty `CLAUDE_CONFIG_DIR` | research | s172 `Owns` `tests/lib.sh`, `tests/run.sh`, and its notes | yes |
| Finding 3: `/po-retro` keeps what `po state` lacks | research, open question 3 | s172 c3 (reading 3), with `po-retro.test.sh` and `commands-and-texts.test.sh` in `Owns` | yes (minor 3) |
| Word count of `method/` does not grow | direction.md "Ce qu'on ne fait plus" | s172 c3 (fewer words in both files); s176 touches no `method/` file | yes |

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| s153, s154, s155 (audit, other models, spike) | direction.md "Ce qu'on ne fait plus" | none: moved out of the file `po` reads | no |
| A prose rule added without removing as many words | direction.md | none | no |
| A test that looks for a phrase no script reads | direction.md; `AGENTS.local.md` `## Direction` | none: s172 c1 tests what the hook outputs, c3 counts words, s176 c5 is judged in review | no |

## Checks
- [x] **Exclusions.** No story brings back an excluded item, under any name. s176 writes docs and Rust only; s172 shrinks two command files.
- [x] **No technical layer dressed as a story.** s176 is a slice for the external agent: you can try it with `po state`. It is also a contract with a real consumer (s172), and its oracle runs the binary.
- [x] **Every criterion can be checked by one test**, or is classed under the owner's rule: s176 c5 and s172 c3 are judged in review, and c3 only has a word-count test. See minors 1 and 2 for two loose wordings.
- [x] **Dependency order.**
  - s176 depends on s170 and s175, both earlier and shipped.
  - s172 depends on s170 and s176; s176 sits before it in the file.
  - Nothing still in `docs/stories.md` depends on s153 to s155.
- [x] **Complexity.**
  - s176 is a 3 and names a risk anyway.
  - s172 is a 4 and names its risk (twenty test files, `po` missing from the suite). Its notes plan the cut if the plan goes past ten tasks.
- [~] **Ids.** Both ids are well formed and unique. s176 sits before s172 and the numbers do not grow in file order. You accepted this; it is minor 9.
- [x] **Owns.**
  - Check 8: the only pair that can still open is s176 against s172. They share `tests/state-as-json.test.sh`, and s172 depends on s176, so there is no critical.
  - Each story owns its oracle file.
  - s176 reaches everything its criteria change:
    - framing per item lives in `po/src/context/framing.rs`;
    - the stops and the fix-loop count live in `po/src/context/lanes.rs`;
    - the lane `path` is serialised in `po/src/state/mod.rs`;
    - it also owns `docs/interface-agent.md` and the oracles of s164 (`state-as-json.oracle`) and s174 (`verbs-read-project-context.oracle`, which pins `lanes` and `framing` exactly, l.75–124).
  - The other oracles that read `po state` (`held-says-what-collides.oracle:99`, `driver-next-action.oracle:265`, `state-as-json.oracle:132,330`) only check fields s176 does not change, or check them by key.
- [x] **Surface.** Both stories say `command`, which `cli` admits.
- [x] **Owned records.** `Corrige` names #203 in the tracker, so no `Owns` entry is needed for it. No ADR is superseded.

## The three readings the lead made alone
1. **The `CLAUDE.md` / install-mode hint stays in bash.** Sound. It is install health, not project state, and the contract of `po state` describes the project. It also keeps the three tests that pin it (`no-claude-md`, `claude-md-setting`, `update-keeps-mode`) stable. s176 c4 and s172 c1 say the same thing.
2. **The ready line may change.** Sound, and it follows from d-0017: the line "Owns not checked: /po-drive decides" becomes false once `po` checks `Owns` and `Parallel`. What is missing is the case of the existing fixtures with no `Parallel`, where `ready` is `null` (minor 1).
3. **`/po-status` and `/po-retro` read what `po state` carries and keep reading files for the rest, naming it.** Sound, and it answers false assumption 3. The list in brackets is shorter than what `po-status` actually reads outside `po state`, and the Sources rule of `/po-retro` is not settled (minor 3).

## The move of s153 to s155
It is coherent:
- `po` reads only `docs/stories.md` (`po/src/context/stories.rs:94`, `start.rs:20`), and so does `po-bounds` (`po-bounds.sh:162`).
- No story, test, script, `method/` file or `po/src/` file still expects them in `docs/stories.md`. The only matches are prose in `direction.md`, `decisions-log.md`, the M20 and M22 introductions and older reviews, which are evidence.
- `tests/state-as-json.test.sh:96` builds its own `## Reportées` fixture, so the move does not affect it.
- `milestone` only reads `## M…` headings, so the stub holds no milestone.

## Findings
All nine are minor:

1. **s172 — what the hook prints for warnings and for `ready: null` is not said.** c1 says the existing cases print the same thing "sauf la ligne des stories prêtes". But `po state` adds warnings the hook never printed: `missing-setting` for `Decision inbox`, and `no-gate` for fixtures without `po-gate.sh`. And the fixtures of `project-lead.test.sh` and `short-subject-shipped.test.sh` have no `Parallel`, so `ready` is `null`. The research flagged both (Traps, l.79; table l.38, l.42). The notes do not say which `warnings` codes the hook shows, where it shows them, or what the ready line says for `null`. A planner may stop on this a second time.
2. **s176 `every_stop_of_a_lane_is_listed` — "ce que `po-session` en dit aujourd'hui" leaves the shape open.** It does not say whether each stop carries the printed text or only the detail values (`Fix loop:`, `Max attempts`), and it names no field. c4 still tests it on the fixtures, so the plan can fix the names.
3. **s172 `status_and_retro_read_po_state` — the list in brackets is incomplete.**
   - It names only findings per severity, the cause of a blocked review, and a story still in flight. `/po-status` also reads, outside `po state`, the complexity, the track, the columns research/design/plan/record/QA/review, the plan ticks, and a next step for a story with no lane (research l.26).
   - The `path:line` Sources rule of `/po-retro` (`po-retro.md:49-51`, pinned by `tests/po-retro.test.sh`) does not say how to cite a figure taken from `po state`.
   - The fetch `po-status` runs today (`po-status.md:13`) is not mentioned either.
4. **s176 / s172 — `docs/interface-agent.md:84` still says "Les règles sont celles de `po-session`".** Once s172 ships, that sentence is circular. s176 owns the file and could say that `po` is now the reference; s172 does not own it.
5. **`docs/stories-reportees.md` l.9 — the note contradicts d-0016 and the stub.**
   - It still says "leur dépendance à s170 les tient hors de la flotte d'ici là", the hold d-0016 drops.
   - It says "déplacées ici le 2026-11-13", while this file received them on 2026-11-14 (stub l.2829).
   - It says "leur place après M21 remet leurs dépendances dans l'ordre du fichier", which no longer applies in this file.
6. **s172 — `jq` becomes a dependency of the session hook, but `README.md:59` lists `jq` only for merging the `SessionStart` hook and for the bounds hooks.** Neither `README.md` nor `docs/installation.md` is in s172's `Owns`. c2 makes the hook say it when `jq` is missing, so this is documentation only.
7. **The move works only once it lands.** `po` reads `docs/stories.md` on `Target branch`, so until the framing pull request lands, `po state` still lists s153 as ready, and only d-0016 holds it.
8. **Root `AGENTS.md` l.237 is stale.** It is the assembled copy, and it does not yet carry the new `AGENTS.local.md` line. It was already behind before this change (it still names `docs/a-trancher.md`). Regenerate it with `bin/polype-dev-install .`; it is not edited by hand.
9. **Ids — s176 sits before s172.** Known and accepted (ids never change). This is a check 7 finding, minor.

## Not verified
- **The owner's answers d-0016, d-0017 and d-0018.** I took them from your message. The inbox is outside my scope (git-ignored), and `docs/decisions-log.md` l.263–264 records only the questions and the hold, not the options chosen.
- **The research's line citations** (`po/src/context/lanes.rs:278-330`, `po-session.sh:56-263`, the 20 rows of the test table). I did not reread them in the code; the code is outside my scope. I checked only that every file of the table is in s172's `Owns`.
- **The 16-file count.** I did not check that the research's table is complete. A test file that pins `po-session` or the two commands and is missing from the table would also be missing from `Owns`.
- **Ten tasks.** I did not check that s172 fits under ten plan tasks. Its notes leave that to the plan.
- **Shipped stories.** I did not check that every other M21 story has shipped, so I ran check 8 only on s176 against s172, as instructed.
- **Issue #244** (per-milestone stories reviews read as `stories review none`). It stays out of scope, so s176 c1 will reproduce that value on this repository.
- **ADR-0119, 0122 and 0123 reserved and never used.** Known; not checked.

Max severity: minor
Stories ready: yes

> Answered by the lead in the same landing, 2026-11-14. 1: s172 c1 now says what the ready line prints when `ready` is `null` and which warnings of `po state` the hook shows (those it showed already). 2: s176 names the field `stops`, each stop with its `code` and its values as fields, not as a sentence. 3: s172 c3 lists what `/po-status` and `/po-retro` keep reading in files, and says a figure taken from `po state` cites `po state`; the fetch of `/po-status` is left to the plan. 4: s176 c5 has the contract stop saying the rules are `po-session`'s. 5: the note of `docs/stories-reportees.md` is rewritten. 6: `README.md` joins s172's `Owns`, for that one line. 7: d-0016 is consumed only once this landing is proven. 8: the root `AGENTS.md` is regenerated by the next `bin/polype update .`, landed by its own pull request. 9: accepted as is. Stories ready: yes.
