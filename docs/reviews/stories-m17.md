# Stories review: Polype, milestone "M17 — Le harnais : chaque gain d'autonomie se paie par un vérificateur" (s147–s155)


A one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). Done on 2026-11-10 by the `stories-reviewer` subagent, in a context that did not write the stories. The findings and verdicts are recorded verbatim; the reading lists are shortened.

- **Scope source:** the milestone's Objectif paragraph, plus issues #151 to #156, with the owner decisions of 2026-11-10. The issue texts reached the reviewer as the caller's summaries.
- **Platform:** `cli`.

## Loop 1

Review status: complete

**What I read:** the M17 section (2322–2479), `AGENTS.local.md`, `method/AGENTS.md`, `docs/reviews/stories-m16.md`, the method files each story owns or cites, ADR-0012, ADR-0083, ADR-0090, and the tests that pin inventories (`structure.test.sh`, `everything-in-issues.test.sh`, `model-routing.test.sh`, `pilot.test.sh`, `adr-directory.test.sh`, `lint.test.sh`, `review-lenses.test.sh`).

**Code claims of the Objectif, checked:** all true (`po-architect.md:57`, `profile.md:24-35`, `testing-doctrine/SKILL.md:17-25`, `planner.md:55`, `review-antihallu/SKILL.md:44`, `review-lenses/SKILL.md:21`, `method/AGENTS.md:125` with ADR-0090:25), as are the notes' lines, except `bin/polype:187`, which is `must_be_executable`: hooks are shipped by the `method/hooks:.polype/hooks` pairs at `:135` and `:138`. Commit c5ad4ec not checked.

### Findings
- **major — s151 — the new hook breaks `tests/structure.test.sh` (`test_rules_list_every_installed_hook`, :73-83).** Every file under `method/hooks/` must be named in `## Installed files` of `method/AGENTS.md`; s151 does not own it. Fix: own it and name `po-intake` there.
- **major — s154 — the same test breaks for `method/hooks/po-audit-model.sh`.** Fix: own `method/AGENTS.md`.
- **major — s149 — the oracle files contradict Law 4, and Law 4 is not owned.** Law 4 (`method/AGENTS.md:105`) lists only `docs/` paths as legitimate uncommitted work; the planner's state check (`planner.md:22`) stops on a resumed lane; the expected-work prompts of `po-execute.md:50` and `po-orchestrator.md:62` have no oracle equivalent. Fix: own and amend them, and add a `Depends on` edge (e.g. s151 → s150) or the overlap on `method/AGENTS.md` becomes critical.
- **major — s149 × s150 — the oracle unit does not fit Polype's own convention.** One test file per story, one function per criterion, up to 7 criteria, against a per-file sum and "trois tests au plus": every further test changes the sum. Fix: decide what the oracle is and reconcile the cap with the number of criteria.
- **major — s150 — the sums sit in a file the implementer edits and commits.** An oracle rewritten with its sum passes. Fix: say the gate guards against errors only (as ADR-0052 says of `po-bounds`), or record the sums where the implementer does not write.
- **major — s151 — automatic filing has no security sort (Law 7, ADR-0090 option D, `po-ship.md:98`).** A fuzz crash is often a security finding, and the output tail may hold secrets, filed to a possibly public tracker before s152 can sort it. Fix: an owner decision (ADR-0077).
- **major — s152 — `intake_stories_reviewed_first` cannot pass as written.** The `stories-reviewer` judges the whole file against a PRD or brief: blocked with `Entry mode: —`, and any existing gap blocks every intake. Fix: say what the reviewer receives (the new stories, the issue as their scope source) and own that change.
- **major — s153 — `findings_go_to_intake` relies on a `po-intake` entry point that does not exist, in a file s153 does not own.** Fix: own `method/hooks/po-intake.sh` and define the mode for filing one finding and its title.
- **major — s154 — which key goes to which endpoint is left to the implementer.** One key sent to every endpoint breaks ADR-0083. Fix: name the variable per endpoint and say a key never goes to another host.
- **major — s155 — `Spike` reaches the full track only through `planner.md`.** `/po-orchestrator` Stage 1 (`po-orchestrator.md:41`) and the escalation signals of `po-flow.md` do not know the line. Fix: own `po-flow.md` and `po-orchestrator.md`.
- **minor — Objectif and s151 notes — `bin/polype:187`.** Cite `:135` and `:138`.
- **minor — s151 notes — the wrong filing path.** Step 3 of `/po-ship` files with `gh issue create`, "no direct HTTP call" (`po-ship.md:95`); the `gh api` / `curl` fallback is for reading.
- **minor — s151 — the `polype-intake` label.** `gh issue create --label` fails on a missing label; the `taskwarrior` mapping is not said.
- **minor — s151 — `failure_files_one_issue`.** "Le premier test en échec" depends on the runner's format. Name the formats, or when it falls back to the exit code.
- **minor — s151 — Law 7 says the lead files.** A script filing is not covered.
- **minor — s153 — the auditor must not preload `review-lenses`** (`tests/review-lenses.test.sh:70-76`). Say it reads the skill without preloading it.
- **minor — s153 — `adr_records_the_audit` names `Audit models` "de s154".** Move the clause to s154 or define the setting in s153.
- **minor — s154 — `Audit models` missing from an older `AGENTS.local.md`.** Say the reading rule applies: stop and name the setting.
- **minor — s147 — `every_profile_fills_strictness` is only partly testable, and complexity 3 looks low.** Consider splitting the profiles from the rule.
- **minor — s149 — `planner_writes_oracle_files`.** "Vérifie ce qu'un appelant observe" is a judgement; a bash test checks only the text.
- **minor — s148 — `long_campaigns_run_outside_stories`.** Once s151 lands the row should name `po-intake`; no story updates it.

### Not verified
Issue texts #151–#156 (summaries only; #156 may be wider than s147's default); commit c5ad4ec and cross-milestone `Owns`; test runs; how `po-bounds` treats planner writes; `docs/installation.md`'s hook list; `gh` on a missing label; the FoundationDB reference; the full prose of `po-drive.md`, `po-flow.md` and `po-ship.md`.

Max severity: major
Stories ready: yes

## Loop 2

Review status: complete

**What I read:** the revised M17 section (2322–2482), Loop 1, `docs/decisions-log.md:135-139`, `AGENTS.local.md`, `method/AGENTS.md` (Laws 4, 6, 7, `## Installed files`), `stories-review`, and to check the fixes: `planner.md`, `implementer.md`, `po-orchestrator.md:30-69`, `po-execute.md`, `po-ship.md:88-102`, `po-architect.md:50-62`, `po-bounds.sh:1-40`, `po-gate.sh` (1-40, 220-239, 370-381, 505-527), `review-antihallu`, `testing-doctrine`, the profiles, `bin/polype:135,138,540-564`, `tests/run.sh`, and the inventory tests.

**How each Loop 1 finding was answered:** every major answered (s151 and s154 own `method/AGENTS.md` and name their hook; s149 owns Law 4 and the expected-work prompts, the edge s151 → s150 holds the chain; the oracle lives in its own files, one test per criterion; the sum check guards against error, as ADR-0052; `--sensitive` and the scrub by the owner; the intake review mode; `po-intake --finding`; one key variable per endpoint; `Spike` in every track choice). Every minor answered.

**Check 8, re-run:** s148 ← s149 ← s150 ← s151 ← s152 ← {s153 ← s154, s155 (also ← s150)}, s147 standalone; every shared entry sits along one chain; the pairs without a dependency are disjoint. No critical.

### Findings
- **major — s149 (and s150–s155) — oracle files sit outside the story's `Owns`, so po-bounds and the review refuse them.** `po-bounds.sh:5`, `:198`; `review-antihallu/SKILL.md:13`, `:18`. Fix: s149 says the oracle files lie inside the story's `Owns`, the planner reporting a gap rather than writing outside them; widen s150–s155 to their `.oracle.test.sh` path.
- **major — s151 — the scrub rests on a false premise and duplicates an existing secret list.** `po-gate.sh:224-234` holds `SECRET_PATTERNS`, which Law 6 (`method/AGENTS.md:121`) relies on; a second list will drift, and a bare `sk-` would redact `disk-`. Fix: reuse `SECRET_PATTERNS` (own `po-gate.sh`), skip empty or very short env values, correct the note and the log line.
- **major — s153 against the Objectif — is the audit a sensitive check?** The Objectif lists "audit" among sensitive checks, while s153 files every non-security finding. Goes to the person.
- **minor — s151 — the doctrine row names fuzzing only.** The decision also names input decoders.
- **minor — s151 `failure_files_one_issue` — the `FAILED` extraction is undefined for cargo** (`test <name> ... FAILED`, name before the marker).
- **minor — s149 — likely more than about ten plan tasks** (14 `Owns` entries). A natural cut: the oracle and its writes, then the expected-work wiring.
- **minor — s149 — "que seul le planner écrit"** contradicts `implementer_keeps_the_oracle`.
- **minor — s152 — intake review and branch names collide within a day**, and Law 6's framing files do not name the intake review.
- **minor — s155 `ship_lands_only_the_report` — the tag push** has no remote under `Merge mode: local`.

### Not verified
Issue texts; the owner's meaning of "audit" (third major); commit c5ad4ec and test runs; inventories in `distribution-wiring.test.sh` and `wiring.test.sh`; `docs/installation.md`'s hook list; full prose of `po-drive.md`, `po-flow.md`, `po-setup.md`, `stories-reviewer.md`; how `/po-review` invokes `po-gate oracle-intact`; `cksum` against tick edits; ADR-0083 and ADR-0090 beyond the Laws; the FoundationDB reference.

Max severity: major
Stories ready: yes

> Owner's answer of 2026-11-10 to the third major: only the audit's security findings are sensitive; its other findings are filed. Folded at the next revision.

## Loop 3

Review status: complete

**What I read:** the M17 section (2322–2483); Loops 1 and 2 and the owner's answer; `docs/decisions-log.md:135-140`; `AGENTS.local.md`; `method/AGENTS.md` (Laws 4, 6, 7, `## Installed files`); `po-gate.sh:215-301`; `po-bounds.sh` (5, 155-198, 279-290); `tests/run.sh`; `bin/polype:186-188`; a grep of `tests/` for inventories touched by the new hooks.

**How each Loop 2 finding was answered:** the oracle files sit inside the `Owns` (s150–s155 own their `.oracle.test.sh`; `po-bounds.sh:5`, `:188`, `:198` confirm an `Owns` entry is enough); the scrub reuses `SECRET_PATTERNS` (citations `po-gate.sh:224-234` and `method/AGENTS.md:121` accurate), with a hole below; the audit's sensitivity answered by the owner and matched by s153; every minor answered.

**Check 8, re-run:** s148 ← s149 ← s150 ← s151 ← s152 ← {s153 ← s154, s155 (also ← s150)}, s147 standalone; every shared entry sits along one chain; the pairs without a dependency are disjoint. No critical.

### Findings
- **major — s151 — `secrets_are_scrubbed` swaps a detector for a scrubber, so a PEM private key's body would still be filed.** The `private-key` row matches only the `BEGIN` header (`po-gate.sh:229`). Fix: a `private-key` match redacts the whole block through its `END` line, or the rest of the tail without one; the test files a full PEM block.
- **minor — s151 — exposing "the list" still copies the rule.** The minimum length and the word boundary live in `hit()` (`po-gate.sh:260-268`). Fix: expose the matcher, e.g. a redact mode; test `desk_live_` + 24 characters left as is (no row matches a bare `sk-`).
- **minor — s151 notes — `po-gate.sh` is owned, but the tests that pin it are not named.** Name `tests/gate.test.sh` and `tests/session-and-gate-checks.test.sh`.
- **minor — s149 — an empty `<slug>.test.sh` fails the suite** (`tests/run.sh:15`). The convention should say the file exists only when it holds a test.
- **minor — s155 against s149 — the reason given for `—` in `## Acceptance tests`.** s149's `—` clause names visual stories only. Fix: add a `Spike` story to it.

### Not verified
Issue texts; commit c5ad4ec and test runs; whether `po-gate.sh` can be sourced without its dispatcher; inventories for `auditor`, `/po-intake`, `/po-audit`; `docs/installation.md`'s hook list; full prose of `po-drive.md`, `po-flow.md`, `po-setup.md`, `stories-reviewer.md`; how `/po-review` invokes `oracle-intact`; duplicates of audit findings whose `path:line` shifts between runs; ADR-0083 and ADR-0090 beyond the Laws; the FoundationDB reference.

Max severity: major
Stories ready: yes

> Answered at the next revision, 2026-11-10, without a fourth loop. Major: `po-gate redact <file>` applies the secret scan's own matcher, and a `private-key` match erases the whole block through `END`, or the rest of the output; the test files a full PEM block. Minors: the matcher is exposed, not the list, and the boundary case is `desk_live_` + 24 characters; s151's notes name the tests that pin `po-gate.sh`; Polype's convention says `tests/<slug>.test.sh` exists only when it holds a test; s149's `—` clause names a spike story. Left for the planner of s153: duplicates of an audit finding whose line moves between runs. Stories ready: yes.
