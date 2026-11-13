# Stories review: Polype, milestone "M21 — L'interface" (s164 to s173)

Stories reviewed: `/home/lecrabe/dev/atoll/polype/.claude/worktrees/framing-d11-d12/docs/stories.md` (M21 at l.2586–2774). I wrote none of these stories. This is a one-off review because there is no PRD or brief (`Entry mode: —`). Platform: `cli`.

The scope source is these files, read together:
- the M21 Objectif (l.2588);
- `docs/direction.md`;
- `docs/interface-agent.md` (contract v1);
- ADR-0106, ADR-0107, ADR-0108, ADR-0115, ADR-0116 and ADR-0117, all `accepted`;
- the three-case rule in `AGENTS.local.md`, "Direction" (l.74).

I used `docs/reviews/stories-m20-m21.md` to check which earlier findings are now answered. I read s153–s163 only for dependencies and `Owns`.

Review status: complete

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| Polype is driven by one command that returns JSON, a Rust binary named `po` | M21 Objectif; ADR-0106; ADR-0107 transport; ADR-0117 name | s164 (`state_prints_one_json_object`) | yes |
| All new M21 code goes into the binary; the existing hooks stay in bash | ADR-0116 | s164–s170 each fill `po/src/<folder>/`; s170 and s172 edit `po-run.sh` and `po-session.sh` in bash | yes |
| One `po` per machine, in the user's Polype folder | ADR-0117 | s164 (`installer_builds_po_from_sources`) | yes (minor m6: how callers find it) |
| `po` warns when its version differs from the project's, and still answers | ADR-0117 condition 1 | s164 (`po_warns_on_another_version`) | yes |
| A newer `po` reads what older versions wrote; anything unreadable is `null` | ADR-0117 condition 2; contract | s170 (`unknown_is_null_never_guessed`) | yes |
| An upgrade cleans up what it cannot keep compatible, and says what it removed | ADR-0117 condition 3 | s171 (`upgrade_cleans_what_the_old_version_left`) | yes |
| Built from sources first, then prebuilt with a verified checksum and the source build as fallback | ADR-0115; M21 Objectif | s164 (sources), s171 (criteria 1–3, 5) | yes |
| Published platforms and the location of the expected checksum go to the owner | ADR-0115 "Restent à fixer"; direction | s171 notes (`Technical choice: waiting for a human`, twice) | yes |
| The inbox is local files outside git; its location is a setting, `.polype/inbox/` by default; it never enters git | ADR-0107 Boîte | s164 (`waiting_reads_the_inbox_setting`), s165 (`add_writes_one_decision_file`, `inbox_never_enters_git`) | yes, with a gap: `po inbox add` with no `Decision inbox` line (major M2) |
| `state` carries every contract field: `contract`, `project`, `commit`, `method_version`, `framing`, `milestone`, `session`, `bounds`, `waiting`, `lanes`, `ready`, `held`, `shipped` | contract `## state` | s164, s168, s169, s170 | partly: s168–s170 must change `po state` outside their `Owns` (major M1) |
| `state` and `inbox` launch no model, query no forge unless asked, and answer in under 1 s | contract, common rules | s164 (`state_reads_only_files_and_git`), s170 (`--remote`) | partly: nothing bounds `inbox` (minor m4) |
| Stdout is one JSON object even on failure; exit codes 0/1/2; error object shape | contract, common rules | s164 (for `state` and `not-built`), s166 (exit 1) | partly (minor m4) |
| `inbox`, `inbox <id>`, decision shape, validation, `sensitive` decisions | contract `## inbox` | s165 | yes |
| `answer` accepts only a listed option, uses the contract's error codes, launches nothing | contract `## answer`; ADR-0107 | s166 | yes |
| After an answer, the lead writes what it produces and cites its id | contract `## answer` | s166 (`answered_decisions_are_listed_until_consumed`, `rules_say_who_consumes`) | yes |
| `run` uses `claude --bg` from the root, one session at a time, with `bounds-unproven`, `nothing-to-do` and no free text | ADR-0107 Lancement; contract | s169 | yes |
| `continue` relaunches the lead after an answer | contract `## run et continue` | s169 (`continue_resumes_after_an_answer`) | yes (earlier C5 answered) |
| Reports are written by code (#202, closing #172, #180, #181, #186, #191, #193) | M21 Objectif; ADR-0108 rule 3; direction | s167 | yes |
| The next action is computed (#203); a review blocked on shape asks and never fixes (#139) | M21 Objectif; ADR-0106 | s168, s173 | yes, with a gap in the action list (major M3) |
| `held` with `dependency`, `owns`, `parallel` and `decision` + `ref` | contract | s168 (`ready_and_held_say_why`) | yes (earlier C4 answered) |
| Trust signals for every shipped story (#205) | M21 Objectif; contract | s170, s167 (method version, oracle gate) | yes (earlier m8 answered by `--all`) |
| `po-session`, `/po-status` and an external agent read one state | ADR-0106 Good; ADR-0116 Bad | s172 | yes |
| `/po-drive` is reduced to running what the automaton says | ADR-0106 Neutral; direction | s173 | yes |
| `interface-agent.md` updated for `po`, `warnings`, the inbox setting, the agent loop and `track`/`--all` | M21 Objectif; ADR-0107/0116/0117 | s164, s169, s170 | yes (minor m5: lead verbs undocumented) |
| An external agent goes only through `po` | direction "La façon de faire" | s169 | yes |
| No technical choice made by an agent alone | direction "Ce qui reste" | s164 (crate dependencies), s171 (two choices) | yes |
| Build order: s164 first; s165 ∥ s167; s166 → s168 → s169 → s170 ∥ s171; s172 after s170; s173 after s167 and s168 | M21 Objectif | `Depends on` lines match it exactly | yes |
| The word count of `method/` files does not grow | M21 Objectif; ADR-0108 rule 2 | s165, s166, s167, s172, s173 | partly (minor m7) |
| Criteria sorted into the three cases; criteria the reviewer judges are candidates for `po-eval` | AGENTS.local.md "Direction" | s165, s166, s167, s169, s171, s172, s173 mark them explicitly | yes |

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| Automaton in bash and jq (option 1) | ADR-0106 | none (s170 only adds a column to the existing `po-run.sh`) | no |
| Agent SDK program | ADR-0106 opt. 3; ADR-0107 | none | no |
| MCP server, HTTP daemon, or the forge as inbox | ADR-0107 (MCP #215 `parked`) | none | no |
| `claude -p` as the launch | ADR-0107 | none | no |
| Inbox tracked in git under `docs/` | ADR-0107 Boîte opt. 2 | none; s165 refuses it | no |
| Copying decisions to a shared memory | ADR-0107 (#216 `parked`) | none | no |
| Existing hooks rewritten in Rust | ADR-0116 opt. 3 | none | no |
| Binary per project, launcher per project, binary committed in the repo | ADR-0117 opt. 1–2; ADR-0115 opt. 4 | none | no |
| Prebuilt only, or source only | ADR-0115 opt. 2–3 | none; s171 keeps the fallback | no |
| A model transcribing a report | direction | none; s167 removes it | no |
| A phrase test that no script reads | direction; AGENTS.local.md | none; criteria the reviewer judges check only word counts | no |
| Removing `/po-orchestrator` and `/po-flow` (ADR-0109, still `proposed`) | direction | none; s173 says it leaves them alone | no |
| s153, s154, s155 | direction "Ce qu'on ne fait plus" | none | no |

## Checks
- [x] **Exclusions.** No story revives an excluded item.
- [x] **No technical layer dressed as a story.**
  - s164 is a contract but can be tried (`po state`), and it has many dependants.
  - s165, s167 and s168 are commands that a lead or an agent calls, and each has later consumers.
- [x] **Every criterion can be checked by one test.** All stories have 7 criteria or fewer. Criteria about a rule a model reads have no oracle test, as the three-case rule says. Minor m3 remains.
- [x] **Dependency order.** Every `Depends on` names an earlier, existing id.
- [x] **Complexity.** No story is a 5. Each 4 (s164, s168, s169, s171) names its risk.
- [x] **Ids.** s164 to s173 are well formed, unique and grow in file order. Outside my scope: s153–s155 sit after s173, so the file as a whole no longer numbers in order. The earlier review chose that placement.
- [ ] **Owns.**
  - Inside M21, every overlapping pair is linked by a dependency:
    - `po/` against each `po/src/<folder>/` (s164 with s165–s170);
    - `po/src/inbox/` (s165, s166);
    - `bin/polype` (s164, s165, s171);
    - `.gitignore` (s164, s165);
    - `method/AGENTS.md` (s165, s166);
    - `docs/interface-agent.md` (s164, s169, s170);
    - `docs/installation.md` (s164, s169, s171);
    - `po-drive.md` (s167, s173).
  - The pairs with no dependency are disjoint: s165/s167, s166/s167, s167/s168, s167/s169, s170/s171, s170/s173, s171/s172, s171/s173, s172/s173. In particular, `.github/workflows/ci.yml` and `.github/workflows/release.yml` are disjoint.
  - Against M20, the chain is broken (critical C1).
- [x] **Surface.** All ten say `command`, which `cli` admits.
- [x] **Owned records.** Every `Corrige` line names GitHub issues, so no record file is involved; s171 has no `Corrige` line. No ADR supersedes another. s165 owns the `docs/a-trancher.md` it deletes.

## Findings
- **critical** — s164 (and through it s165, s166, s169, s171; side effect on s154 and s155) — **`Owns` overlap with M20, and no dependency chain reaches it.** — owner: Fix (2026-11-13: s164 depends on s159 and s161)
  - s164 has `Dépend de : aucune`, yet it shares files with s159 and s161:
    - with s159: `method/templates/agents-local.md`, `AGENTS.local.md`, and `.github/workflows/ci.yml` (inside s159's `.github/workflows/`);
    - with s161: `bin/polype` and `docs/installation.md`.
  - Later stories reach neither s159 nor s161 through their chains:
    - s165 (`bin/polype`, `method/AGENTS.md`) and s166 (`method/AGENTS.md`) overlap s161;
    - s169 (`docs/installation.md`) overlaps s161;
    - s171 overlaps s161 (`bin/polype`, `docs/installation.md`) and s159 (`.github/workflows/`, `docs/ci.md`).
  - The rework also broke chains that used to go through s170: s154 against s159 and s161 (`agents-local.md`, `AGENTS.local.md`, `method/AGENTS.md`), and s155 against s159 (`method/commands/po-ship.md`).
  - The earlier review said this explicitly: "the story that adds it must depend on s159". The reworked stories dropped those dependencies.
  - s159 and s161 have already shipped (direction.md), so no lane can actually collide today. Check 8 still rates this critical, as the earlier review did for C7.
  - Fix, one line: `Dépend de : s159-ci-on-every-pr, s161-installer-leftovers` on s164. Both are earlier ids, and this repairs every chain listed above.
- **major** — s168, s169, s170 — **`po state` fields are written outside these stories' `Owns`.**
  - Criteria that change `po state`:
    - s168: `lanes[].next`, `ready`, `held` (`next_gives_one_action_per_lane`, `ready_and_held_say_why`);
    - s169: `session`, `bounds`;
    - s170: `shipped[].trust`, plus new `--all` and `--remote` flags on `state`.
  - Each of these stories owns only its own folder, and its notes say "tu ne touches à aucun autre dossier du crate". The `state` code (and probably the argument parsing in `main`) is s164's.
  - s164's notes say other stories' fields stay `null`. They do not say that `state` calls into `next/`, `run/` and `trust/` to fill them, or that `state`'s flags and each verb's sub-arguments (`inbox add`, `inbox consume`, `inbox --answered`) are parsed inside the verb's folder.
  - As written, each of the three lanes stops at the crate boundary. This is earlier finding M5, still open and now wider.
  - Fix, either way:
    - s164 states that hand-off as a criterion or note; or
    - s168, s169 and s170 add the state file to their `Owns`. They form one chain (s170→s169→s168→s164), so that creates no new overlap.
- **major** — s165 (with s164) — **`po inbox add` has no defined behaviour when `Decision inbox` is missing.**
  - s164 defines the missing line only for `state`: `waiting: null` plus a warning. s165 writes "sous le dossier que `Decision inbox` nomme" and says nothing about the case.
  - Every existing product's `AGENTS.local.md` lacks the line, and the installer never rewrites that file.
  - `rules_send_every_stop_to_the_inbox` sends every escalation through `po inbox add`. So the planner alone decides whether every escalation on every product fails or falls back to a default, and the rules forbid guessing a missing setting.
  - This is the same shape as earlier M2 on s159. Add a criterion.
- **major** — s168 — **The closed action list may not hold the opening of a lane.**
  - `next_gives_one_action_per_lane` fixes the action list to the contract's: `plan` … `ask`. It has no `research` and no short track (`Story track: auto`, `/po-flow`).
  - `every_routing_case_is_a_fixture` requires one case for each routing rule of `po-drive.md` "tel qu'il est". If `/po-drive` opens a lane with research, or picks the short track, the two criteria cannot both be met.
  - The planner would then have to change the contract (an enum value) alone.
  - Say how a ready story's first action is named (`plan` covering research? a new value?), and whether adding a value keeps `contract: 1`.
- **minor** m1 — s164 — **A dependency stop in s165 and s170 is foreseeable.**
  - The short dependency list ("lire et écrire du JSON, lire les arguments") is the only one allowed ("aucune story suivante n'en ajoute").
  - s165 must write `asked` as a timestamp with a local offset (`+01:00`). s166 writes `answer.at`, and s170 derives `duration_s` from timestamps. Rust's std library cannot give a local offset.
  - Put date/time on the list the owner is asked about, or the s165 lane will almost certainly stop on it.
- **minor** m2 — s164 — **The notes miss an M20 oracle and leave the CI change unexplained.** The notes do not list `tests/ci-on-every-pr*.test.sh`, s159's oracle, among the out-of-`Owns` tests. That oracle pins the workflow ("n'a qu'une étape de contrôle, qui appelle `bin/po-ci`"), and s164 edits `ci.yml`. Say what changes there, if anything, given that `tests/run.sh` already builds `po`.
- **minor** m3 — s165 — **"`question` d'une seule phrase" needs a definition a script can apply** (for example, no sentence-ending punctuation before the last character). Otherwise the test and the code each invent one.
- **minor** m4 — s164, s165 — **Common contract rules are only partly fixed.**
  - Only `state` gets the "one JSON object even on failure" rule and an exit code.
  - s165's refusals (`add_refuses_a_malformed_decision`, `inbox-not-ignored`) give no exit code; the contract says 1.
  - The under-1-second bound on `inbox` has no criterion.
- **minor** m5 — s166 (and the lead verbs in general) — **New lead verbs are not documented anywhere.**
  - s166 adds `po inbox --answered`, `po inbox consume <id> <ref>` and a consumed marker on the decision file.
  - `inbox add`, `next` and `record` are lead verbs too.
  - No story documents them, and s165 says not to extend the decision shape.
  - Say where they are written down, even outside the agent contract.
- **minor** m6 — s164 — **How commands find `po` is not stated.** s165's rule, s172's hook and s173's `/po-drive` all call `po`. s164 does not say how they find it (on `PATH`, or a documented path in `installation.md`). Nothing adds `po` to `## Installed files` of `method/AGENTS.md`, which s165 owns.
- **minor** m7 — s164, s167, s170, s173 — **The word rule has no criterion here.**
  - These edits add text to `method/` with no word-count criterion:
    - s164: `templates/agents-local.md`;
    - s167: `templates/review.md` and `qa.md`;
    - s170: `templates/verification-record.md`;
    - s173: `po-execute.md` gains a rule.
  - The Objectif leaves this to review ("s173 la chiffre" covers `po-drive.md` only). The reviewer must check it.
- **minor** m8 — s165 — **Deleting `a-trancher.md` leaves dangling text.**
  - `AGENTS.local.md` l.75 says pending decisions live in `docs/a-trancher.md`; s165 does not own that file.
  - `interface-agent.md` l.5 and the accepted ADR-0106/0107 link to it. s169 probably rewrites l.5 of `interface-agent.md`; the ADRs stay as written.
  - Name who updates `AGENTS.local.md`.
- **minor** m9 — s165 — **The rule does not say what happens when `po` is absent.** `rules_send_every_stop_to_the_inbox` says nothing about a machine with no `po`. That is possible until s171, since s164 installs without `cargo`. s172 and s173 define this case; s165 does not. The escalation must still reach the person.
- **minor** m10 — s167 — **The notes contradict the `Owns` line.** The notes list `tests/qa*.test.sh` as out-of-`Owns` tests that "gardent leurs phrases". That glob includes `tests/qa-report-returned-as-text.test.sh`, which s167 owns and must change.
- **minor** m11 — s169 — **The proof that bounds are held is not defined.** "rien ne prouve le dialogue de confiance accepté" does not say what would count as proof. Say that, with no known proof, a project-only install is always `unproven`, so the planner does not invent a security mechanism alone.

**Earlier M21 findings, checked:**
- Answered: C1 (Rust), C2 (s164 + s171), C3 (setting), C4 (s168 `decision`), C5 (s169 `continue`), C6/C7 (s153–s155 moved), M6 (installer ignores the inbox), m3 for s166, m7 (s168 split foreseen), m8 (`--all`), m9 (plan).
- Not answered: M5 (now major M1, wider).
- Re-opened by the rework: the dependency on s159 for the setting (now critical C1).

## Per story
- **s164-state-as-json:** cannot be planned as written. Add the dependency on s159 and s161 (C1). Say how `state` gathers the other folders' fields (M1). Add date/time to the dependency list (m1).
- **s165-decision-inbox:** can be planned once the behaviour with no `Decision inbox` line is a criterion (M2). It inherits C1 through s164.
- **s166-answer-comes-back:** can be planned as written, once C1 is fixed upstream.
- **s167-record-writes-reports:** can be planned as written; fix the m10 wording.
- **s168-driver-next-action:** can be planned once M1 and M3 are settled; otherwise its plan stops on the first fixture that opens a lane.
- **s169-run-from-outside:** can be planned once M1 is settled.
- **s170-trust-signals:** can be planned once M1 is settled (`--all`, `--remote`, `shipped`).
- **s171-po-prebuilt-and-verified:** can be planned as written, with two owner choices in its plan. It inherits C1 through s164.
- **s172-commands-read-po-state:** can be planned as written.
- **s173-drive-executes-next:** can be planned as written; it depends on M3 being settled in s168.

## Not verified
- **Code, tests and git history (out of scope).** These are questions for each story's research:
  - whether `.polype/version` exists and what it holds;
  - whether s159's oracle pins `ci.yml`;
  - whether a `tests/qa-report-returned-as-text.oracle.test.sh` exists outside s167's `Owns`;
  - whether `po-gate findings-shape` accepts a `Method version:` line;
  - whether `po-session`'s "presumed" lines have an equivalent in `po state`;
  - how `po-drive.md` opens a lane and picks the track today. I did not read `method/`, so M3 is a risk, not a confirmed gap.
- **Shipped status of s159–s163.** I took it from `direction.md`; I did not check it in git.
- **`docs/a-trancher.md` (D5–D10).** Not read, so I cannot say whether s165's plan will list everything still open.
- **Issue bodies #202–#205, #139, #172–#193, #209.** Not read. Coverage is judged against the M21 Objectif's summary of them, not their text.
- **ADR-0109 and ADR-0110.** Both are `proposed`; I did not read them and judged no story against them.
- **The "Limite de confiance" section of `docs/installation.md`.** Not read, so I cannot check s169's `bounds` against it.
- **How to tell that a `claude --bg` session is still running.** Left to s169's research; not checked.

Max severity: critical
Stories ready: no
