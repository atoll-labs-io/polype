# Stories review: Polype, milestones "M20 — Le ménage" (s159–s163) and "M21 — L'interface" (s164–s170)

This is a one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). It was done on 2026-11-13 in a context that did not write the stories.

- **Scope source:** the Objectif paragraphs of M20 and M21, `docs/direction.md`, ADR-0105 to ADR-0108 (all `accepted`), `docs/interface-agent.md`, `docs/a-trancher.md` (D5 to D12), and the issue text the caller dumped in `/home/lecrabe/.claude/jobs/2d6d034f/tmp/issues-m20-m21.md`. I read that dump as data. It held no instructions.
- **Platform:** `cli`.
- **Earlier milestones:** read only for their dependencies and `Owns` overlaps with s153–s155.
- **Recorded by the lead, 2026-11-13:** the answer below is the reviewer's, word for word; only the ` — owner:` ends of the critical findings are added, from the owner's answers. Folded into `docs/stories.md` the same day: s153 to s155 moved after M21 with the two missing dependencies; the `Surface` of s159, s162 and s163; a criterion for a missing `Forge checks:` line and the stale risk of s159; the plugin clause of s162; the #79 point set aside in s161. The incoherence on phrase tests went to the owner, whose answer (three cases) is in the Objectif of M20. The M21 findings wait for `/po-stories`. The other minors stay open here.

Files: `/home/lecrabe/dev/atoll/polype/docs/stories.md` (M20 at l.2547, M21 at l.2638, s153–s155 at l.2435–2484), `/home/lecrabe/dev/atoll/polype/docs/decisions/ADR-0105…0108-*.md`, `/home/lecrabe/dev/atoll/polype/docs/interface-agent.md`, `/home/lecrabe/dev/atoll/polype/docs/direction.md`, `/home/lecrabe/dev/atoll/polype/docs/a-trancher.md`.

Review status: complete

## Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| The full suite runs on every pull request and every push to `Target branch`, through one forge-neutral script | M20 Objectif; #201; ADR-0105 | s159 (`ci_entry_runs_the_suite`, `workflow_only_calls_the_entry`) | yes |
| `/po-ship` merges only when the forge checks pass on the landing commit | ADR-0105 ("Quelle que soit l'option"); #201 | s159 (`ship_waits_for_green_checks`) | yes, with a gap: an `AGENTS.local.md` with no `Forge checks:` line (major M2) |
| Making the check required is a gesture only the owner makes, and the docs say how | ADR-0105; #201; D8 | s159 (`docs_say_how_to_require_the_check`) | yes |
| The workflow uses a syntax Forgejo Actions also reads, so moving it needs no rewrite | ADR-0105 Decision Outcome | s159: notes only, as a paraphrase | partly (minor m2) |
| The suite never runs `po-eval` | ADR-0105 Consequences | s159 (`ci_entry_runs_the_suite`) | yes |
| #87: `/po-setup` refuses a Design skill that is not installed | M20 Objectif; #87 Expected 1 | s162 (`setup_refuses_a_missing_design_skill`) | yes |
| #87: the designer resolves skills that plugins provide | #87 Expected 2 | none (major M4) | no |
| #149: each QA lane gets its own browser and its own port | M20 Objectif; #149 | s163 (the port comes from the worktree instead of `/po-drive`, an acceptable equivalent) | yes |
| #184: the designer accepts the planner's oracle files | M20 Objectif; #184 | s162 (`designer_accepts_the_oracle_files`); Law 4 already lists them | yes |
| #166: a story's `Owns` lists its oracle file, and stories-review checks it | M20 Objectif; #166 | s162 (`owns_lists_the_oracle`) | yes (minor m5) |
| #197: the intake title is bounded and stable | M20 Objectif; #197 | s160 (criteria 1 to 3) | yes |
| #134: an unreadable review exits 2 | M20 Objectif; #134 | s160 (`unreadable_review_exits_2`) | yes |
| #143, #137, #144, #132 | M20 Objectif | s161 | yes |
| #79: the installer points | M20 Objectif; #79 | s161. The BOM and symlink test point under `kept` is neither taken nor set aside (minor m4) | partly |
| Pure-wording review findings are closed without a story | M20 Objectif | none of the five stories is wording-only | yes |
| No M20 story grows a file of `method/` | M20 Objectif ("jugée en revue") | s162 and s163 (`no_file_grows`), s161 (AGENTS.md section). s159 and s160 rely on review alone (minor m3) | yes |
| The five M20 `Owns` are disjoint and can run together | M20 Objectif | checked pairwise below | yes |
| M20 depends only on ADR-0105 | direction.md, "Par où reprendre" 1 | no M20 story cites a `proposed` ADR | yes |
| The automaton (state, next action) is a Rust binary; the existing hooks stay in bash | ADR-0106 Decision Outcome; M21 Objectif | none: s164, s168 and s170 write `method/hooks/po-state.sh` in bash (critical C1) | no |
| The binary is built and distributed, and the installer lays it down | ADR-0106 Consequences; D11 | none, and no M21 story owns `bin/polype` (critical C2) | no |
| Which M21 scripts go into the binary | ADR-0106; D12 | pending owner decision | no |
| Project state as one JSON object (`contract`, `framing`, `milestone`, `lanes`, `ready`, `held`, `waiting`…) | #203; #204; interface-agent.md `## state` | s164 | yes (bash-shaped) |
| `held[].reason` takes the value `decision`, with `ref` | interface-agent.md `## state` | none (critical C4) | no |
| `state` carries `session` and `bounds` | interface-agent.md; ADR-0107 | s169 criteria, but the file is outside its `Owns` (major M5) | partly |
| Decision inbox: `add`, `list`, `show`, shape, sensitive decisions | #204; interface-agent.md `## inbox` | s165 | yes |
| The inbox location is a project setting, `.polype/inbox/` by default, and never in git wherever it lives | ADR-0107 Decision Outcome | none: s164 and s165 hard-code `.polype/inbox/` (critical C3) | no |
| `answer` accepts only a listed option, with the contract's error codes; answering launches nothing | interface-agent.md `## answer`; ADR-0107 | s166 | yes |
| `run`: `claude --bg` from the root, one session at a time, `bounds-unproven`, `nothing-to-do`, no free text | ADR-0107; interface-agent.md `## run et continue` | s169 | yes |
| `continue` relaunches the lead after an answer | interface-agent.md `## run et continue` | none: s169 only tests its refusals (critical C5) | no |
| Reports are written by a script; closes #172, #180, #181, #186, #191, #193 | #202; ADR-0108 rule 3 | s167 | yes |
| The next action is computed, and a shape-blocked review never starts a fix run | #203; #139 | s168 | yes |
| Trust signals for each shipped story | #205 | s170 (current milestone only, minor m8), s167 (method version) | yes |
| An external agent goes only through `po-agent` | direction.md | s169 | yes |

## Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| s153, s154, s155 (audit, other models, spike) | direction.md "Ce qu'on ne fait plus"; M20 Objectif | none | no |
| Automaton in bash and jq beside the hooks (option 1, turned down) | ADR-0106 | s164, s168, s170; s165–s167 and s169 too under D12 option a (critical C1) | yes |
| Agent SDK program | ADR-0106 option 3; ADR-0107 | none | no |
| MCP server or HTTP daemon as the transport; the forge as the inbox | ADR-0107 (MCP postponed, #215 `parked`) | none | no |
| `claude -p` as the launch | ADR-0107 | none | no |
| Copying decisions to a shared memory | ADR-0107 (#216 `parked`) | none | no |
| A model transcribing a report | direction.md | none; s167 removes it | no |
| A test that looks for a phrase no script reads | direction.md; AGENTS.local.md "Direction" | at risk in most M20 criteria, which only prose can satisfy (major M3) | at risk |
| A prose rule added without removing another | direction.md; ADR-0108 rule 2 | s159 and s166 carry no word criterion (minor m3) | not shown |

## Checks
- [x] **Exclusions.** M20 revives nothing. M21 revives ADR-0106's turned-down option 1 (C1).
- [x] **No technical layer dressed as a story.** s164 and s165 are contract-like, but each is observable as a command and has at least two later dependants (s164: s168, s169, s170; s165: s166 and, through it, s168 and s169).
- [ ] **Every criterion can be checked by one test.** Every M20 criterion that only prose can satisfy needs a phrase test, which the direction forbids (M3).
- [ ] **Dependency order.** Every M20 and M21 dependency points earlier in the file. But s153 and s155, which sit before M18, depend on s170, a later id (C6).
- [x] **Complexity.** No 5. Each 4 (s159, s164, s168, s169) names its risk, though s159's risk is stale (m1).
- [x] **Ids.** s159 to s170 have the right form, are unique and grow in file order.
- [ ] **Owns.**
  - Inside M20, the pairs are disjoint (`bin/po-ci` against `bin/polype`; no shared file or folder).
  - Inside M21, every overlapping pair is linked by a dependency: s165/s166 through s165; s164/s168/s170 on `po-state.sh`; `interface-agent.md` across s164/s169/s170; s167/s168 on `po-drive.md`.
  - From M21 to M20, the links hold: s165, s166 and s169 reach s161 through `Depends on`, and s170 depends on s159.
  - From M20 to s153–s155: s154 and s155 reach s159 and s161 through s170. But **s160 ↔ s153** (`method/hooks/po-intake.sh`, `docs/harnais.md`) and **s162 ↔ s155** (`method/templates/stories.md`, `method/skills/agentic-stories/SKILL.md`, `method/skills/stories-review/SKILL.md`) have no dependency chain between them (C7).
- [ ] **Surface.** s159, s162 and s163 say `behaviour`, which `cli` does not admit (M1). The other stories say `command`, which it does.
- [x] **Owned records.** Every `Corrige` line names GitHub issues, so no file record is involved. No M20 or M21 story writes an ADR that supersedes another. s165 owns the `docs/a-trancher.md` it deletes.

## Findings
- **critical** — s164, s168, s170 (and s165, s166, s167, s169) — **They are written for bash.** Each writes `method/hooks/*.sh` with `jq`, the option ADR-0106 turned down. The decision is a Rust binary, and only the existing hooks stay in bash. — owner: Fix (2026-11-13: `/po-stories` reworks M21 once D11 and D12 are answered)
  - s164's own note says "si elle ne retient pas bash, arrête-toi", so its plan would stop at once.
  - s168 applies "le seuil de l'ADR-0106 … 800 lignes". That threshold belonged to the recommendation the owner overruled; it is not in the decision.
  - Every M21 `Owns` path changes once D12 says which scripts go into the binary. A shared crate (`Cargo.toml`, a crate folder) would also create overlaps that s164, s165 and s167 do not have today, so they could no longer run in parallel.
  - The Objectif already says none of these stories can be planned as written. The finding records it against the ADR.
- **critical** — M21 — **Nothing builds or ships the binary.** No story builds the binary, distributes it per platform, or makes the installer lay it down (ADR-0106 Consequences; D11 is open). No M21 story owns `bin/polype`. — owner: Fix (2026-11-13: `/po-stories` reworks M21 once D11 and D12 are answered)
- **critical** — s164, s165 — **The inbox location is hard-coded.** `waiting_reads_the_inbox_folder`, `add_writes_one_decision_file` and `inbox_never_enters_git` all fix it at `.polype/inbox/`. ADR-0107 makes the location a project setting, with `.polype/inbox/` as the default, and requires that the inbox never enter git wherever it is. — owner: Fix (2026-11-13: `/po-stories` reworks M21 once D11 and D12 are answered)
  - No story adds that setting.
  - Adding it touches `method/templates/agents-local.md`, which s159 owns, so the story that adds it must depend on s159.
- **critical** — s164 — **`held[].reason: decision` is never produced.** The contract has it, with `ref`. `held_says_why` lists only `dependency`, `owns` and `parallel`. s168's `answered_decision_releases_its_lanes` covers a lane's `wait` action, not a story that has not started and is held by a pending decision. — owner: Fix (2026-11-13: `/po-stories` reworks M21 once D11 and D12 are answered)
- **critical** — s169 — **`continue` has no criterion.** It is a verb of the contract ("relance une session arrêtée, après une réponse"), but only its refusals are tested (`already-running`, no free text). Nothing proves it launches anything. — owner: Fix (2026-11-13: `/po-stories` reworks M21 once D11 and D12 are answered)
- **critical** — s153-scheduled-audit, s155-spike-story — **They depend on a later id.** Both sit at l.2435–2484 and depend on s170-trust-signals, a later id (check 5). The note at l.2433 says this is on purpose, to keep them out of the fleet. Even so, the file breaks the ordering rule. — owner: Fix (2026-11-13: s153 to s155 move after M21, s153 depends on s160 and s155 on s162)
  - Fix: move them after M21, or M22, with the same dependencies, or take them out of `docs/stories.md` and keep only their `parked` issues.
- **critical** — s153 ↔ s160, s155 ↔ s162 — **`Owns` overlap with no dependency chain.** — owner: Fix (2026-11-13: s153 to s155 move after M21, s153 depends on s160 and s155 on s162)
  - s153 and s160 share `method/hooks/po-intake.sh` and `docs/harnais.md`.
  - s155 and s162 share `method/templates/stories.md`, `agentic-stories` and `stories-review`.
  - Neither pair reaches the other through `Depends on`: s170's chain goes through s159, s161 and s164–s169, never through s160 or s162.
  - In practice, s153 and s155 cannot open before s170 ships, so no M20 lane collides today. The fix belongs to s153 and s155 (see the finding above), not to M20.
- **major** — s159, s162, s163 — **Wrong `Surface`.** `Surface: behaviour` is admitted only by `robot`; the platform is `cli`. s159 has a command (`bin/po-ci`), so `command`. s162 and s163 change agent and skill text, so `—` or `command`.
- **major** — s159 — **A missing `Forge checks:` line has no defined behaviour.** `/po-ship` will read the new setting, but no criterion says what it does when an existing project's `AGENTS.local.md` has no such line, and that is every product today.
  - The rules forbid guessing a missing setting. So the planner decides, alone, whether every product's next ship stops (as s154 chose for `Audit models`) or carries on.
  - The story also does not say whether `/po-setup` must write the line. If it must, `po-setup.md` is owned by s162, and the two stories would need a dependency.
- **major** — M20: s159 (`ship_waits_for_green_checks`, `docs_say_how_to_require_the_check`), s161 (`docs_describe_the_kept_copy_stops`), s162 (criteria 1 to 3), s163 (criteria 1 to 3) — **Phrase tests against the direction.** No script reads these clauses; they can only be satisfied by prose in a command, agent, skill or doc. Polype's convention ("an acceptance criterion's name is its test function's name", tests "quoting short exact phrases") makes the planner write phrase tests for them. `direction.md` and AGENTS.local.md "Direction" forbid exactly that.
  - Two framing documents contradict each other here, so this is an incoherence for the owner or lead to settle once, before the first M20 plan. The options: allow phrase tests in M20 until M22's #207, give these criteria no oracle test with a recorded reason, or rewrite them so a script checks them.
- **major** — s162 — **A plugin skill still reaches a designer that may not load it.** `setup_refuses_a_missing_design_skill` accepts a skill "qu'un plugin activé fournit", but no criterion makes the designer resolve plugin-provided skills (#87, Expected 2). `designer.md` is in `Owns`.
  - If the designer only reads `.claude/skills/<name>/SKILL.md`, then lophelia's case (`frontend-design` is a plugin skill), once the plugin is enabled, passes setup and stops again at design.
  - Fix: add a designer criterion, or have setup accept only skills the designer can load today.
- **major** — s169 — **`state` must carry fields s169 cannot write.** `run_refuses_a_second_session` and `run_refuses_unproven_bounds` require `state` (`po-state`) to carry `session` and `bounds`. `one_command_five_verbs` requires `po-agent state` to return what `po-state` returns. But s169 does not own `po-state`.
  - s168 owns that file, and s168 and s169 have no dependency between them. Adding it to s169's `Owns` without one would create a critical overlap.
- **major** — s165 — **Other projects break every escalation.** `po-inbox add` refuses to write when the inbox is not git-ignored, and `rules_send_every_stop_to_the_inbox` sends every escalation through it. The only `.gitignore` in `Owns` is Polype's own, and nothing makes the installer ignore the inbox in other projects. So on every other project, every escalation would fail to post.
- **minor** — s159 — **The complexity risk is stale.** It still says the owner settles ADR-0105 "avant le plan", but ADR-0105 is accepted. The risk now is waiting for forge checks: the timeout, and three forges.
- **minor** — s159 — **Forgejo syntax is only in the notes.** ADR-0105 decides that the workflow "dans une syntaxe que Forgejo Actions lit aussi". Only the notes paraphrase it; no criterion holds it.
- **minor** — s159, s166 — **No word-count criterion.** Both add text to `method/` (a setting and a ship step; a consumption rule in `method/AGENTS.md`) and carry no criterion for the word rule, unlike s162, s163 and s165. The Objectif leaves this to review, so the reviewer must check it.
- **minor** — s161 — **One #79 point is unaccounted.** The BOM CLAUDE.md and symlinked root CLAUDE.md under `kept` are neither taken nor set aside. #79's "done" asks that each point be fixed or explicitly set aside in the decisions log.
- **minor** — s162 — **Three unrelated defects in one story.** Acceptable at complexity 2. But `owns_lists_the_oracle` must say what counts in a project with no oracle naming convention, or when an owned folder already covers the file. Otherwise the new major check cannot be judged mechanically.
- **minor** — s163 — **The port change may need files the subagent cannot write.** `reuseExistingServer` lives in the project's Playwright config, which the `qa` subagent may not edit: `po-bounds` keeps it inside `docs/qa/<id>/`. The notes should say how the port is moved and reuse is switched off without touching project files.
- **minor** — s168 — **The plan may run long.** "Un cas par règle de routage" over 5,470 words of `po-drive.md` may push the plan past ten tasks. The notes do not foresee a split.
- **minor** — s170 — **Trust covers the current milestone only.** #205 asks for every shipped story.
- **minor** — s165 — **Which report?** `provisional_inbox_is_gone` sends what is still open in `a-trancher.md` to "le rapport de la story" without saying which file: research, plan, verification record or review.

## Not verified
- **Code and tests.** My scope excludes the code and the git history, so these are open questions for the research stage of each story:
  - Does s151's oracle (`tests/failing-check-files-an-issue.oracle.test.sh`, outside s160's `Owns`) pin a pytest fingerprint that keeps ` - <message>`? #197 itself says the s151 criterion must be revisited.
  - Does `tests/payload-refuses-foreign-files.test.sh` (outside s161's `Owns`) pin deep `*.next` as state files?
  - Do s156's tests (`tests/qa-report-returned-as-text*.test.sh`, outside s167's `Owns`) pin the heredoc transcription that s167 removes?
  - How does `method/agents/designer.md` load a Design skill today (decides M4)?
  - How does `/po-setup` write settings, and does `bin/polype check` audit them (decides M2)?
  - Does the installer flag `.polype/inbox/` as a foreign file?
  - Does `bash tests/run.sh` need tools a hosted runner lacks besides `jq` (for example `git` identity, `cksum`, the `.claude/` copies)?
- **ADR-0109 and ADR-0110.** Both are `proposed` and cited only by direction.md. I did not read them, and I judged no story against them.
- **Issues not in the dump:** #75, #209, #210, #211, #215, #216, and the comments on every issue. I had only the bodies the caller quoted.
- **`docs/defauts.md`, and the "Limite de confiance" section of `docs/installation.md`.** I did not read them, so I could not check whether s169's `bounds` criterion matches what installation.md says today.
- **Earlier reviews of s153/s155.** I did not check whether `docs/reviews/stories-m17.md` already raised the dependency-order and overlap problems of C6/C7.
- **How to tell whether a `claude --bg` session is still running.** s169's notes defer this to Claude Code's docs, which I did not read.

## Per milestone
- **M20 ready: yes.** No critical finding sits in s159–s163. The two criticals they touch (C6, C7) belong to s153 and s155, which cannot open before s170. Before the first plan, one decision covers four stories: how M20's prose-only criteria are tested (M3).
  - **s159:** can be planned once a criterion says what `/po-ship` does when `Forge checks:` is missing, and whether `/po-setup` writes it (M2). Change `Surface` to `command`. As written, its planner would decide alone whether every product's next ship stops.
  - **s160:** can be planned as written. Research must confirm s151's oracle does not pin the old fingerprint.
  - **s161:** can be planned as written. m4 is a one-line addition to the notes.
  - **s162:** can be planned, but fix M4 first, or it ships only half of #87. Change `Surface`.
  - **s163:** can be planned as written. Change `Surface`; the research settles m6.
- **M21 ready: no.** All of s164–s170 are held back:
  - They are written for the bash automaton that ADR-0106 turned down (C1).
  - Nothing builds or lays the binary (C2); D11 and D12 are open.
  - The inbox location is fixed where ADR-0107 makes it a setting (C3).
  - `held: decision` is never produced (C4) and `continue` has no criterion (C5).
  - s169 needs `po-state` outside its `Owns` with no dependency on s168 (M5), and s165 would break escalation on other projects (M6).
  - As the Objectif says, `/po-stories` reworks them after D11 and D12, then `/po-stories-review` runs again.

Max severity: critical
Stories ready: no
