# Stories review: Polype, milestone "M11 — Polype s'installe chez quelqu'un d'autre" (s130–s132)

This is a one-off review, run outside `/po-stories-review` because Polype has no PRD or brief (`Entry mode: —`). It was done on 2026-10-14 by the `stories-reviewer` subagent, in a context that did not write the stories, against `docs/stories.md` lines 2012–2063 of the framing worktree. The answers are recorded verbatim, one loop after the other.

- **Scope source:** the milestone's own `Objectif` paragraph, decided with the owner on 2026-10-14.
- **Platform:** `cli`.
- **Shape:** follows `docs/reviews/stories-m9bis.md`.

## Loop 1

Review status: complete

### Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| A first install silently replaces a file of the same name (`lay_down`, `bin/polype:157`), in both global and project installs | Objectif | s130 (`collision_stops_before_writing`, `set_aside_is_explicit_and_undone`) | yes |
| Existing agents and skills of the user's Claude Code config are not lost | Objectif | s130 (both installs, all three commands) | yes |
| A hand-written `AGENTS.md` is set aside in `AGENTS.md.before-polype` and no longer read | Objectif | s130 (`hand_written_agents_md_is_absorbed`) | yes |
| The "no CLAUDE.md" rule stays the default and becomes a per-project setting | Objectif (owner decision) | s131 | yes, with the gaps in findings M3–M5 |
| The installer needs bash 4 without saying so; macOS ships 3.2 | Objectif | s130 (`old_bash_is_named`), s132 (`prerequisites_are_listed`) | yes, but the version threshold is wrong (M1) |
| The README gives prerequisites, how to get Polype and where to start | Objectif | s132 (`prerequisites_are_listed`, `quickstart_runs_as_written`) | yes |
| The README is enough to install it and use it, existing config included ("possible de charger du contexte custom ?") | Objectif | s132 (`existing_config_is_explained`) | yes |

Every story traces to an item; none is out of scope.

### Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| none: the Objectif lists no non-goal | Objectif | none | no |

### Checks
- [x] Exclusions: no story revives an excluded item (none is listed)
- [x] No technical layer dressed as a story: each of the three can be tried by a person
- [ ] Every criterion can be checked by one test: mostly yes; see m4 and m6
- [x] Dependency order: s131 → s130 and s132 → s131, both earlier ids that exist
- [x] Complexity: no 5 and no 4 (but see m3 on s130's size)
- [x] Ids: `s130`–`s132` follow `s129`, well formed and unique
- [x] Owns: every story declares one. s130 and s131 share `bin/polype`, `tests/install.test.sh` and `tests/installer.test.sh`, but s131 depends on s130, so no critical. s132 is disjoint and dependent anyway

### Findings
- major (M1) — s130, s132 — The bash threshold is wrong for the installer as it is today. `bin/polype:359` runs `declare -gA RECORDED=()`, and `declare -g` needs bash 4.2, not 4. `old_bash_is_named` ("plus ancien que 4") and `prerequisites_are_listed` ("bash 4 ou plus") would both pass while bash 4.0 and 4.1 still crash at `load_checksums`. Both criteria should say 4.2, or the code should drop `-g`.
- major (M2) — s130 — s130 makes rule texts false that it does not own. After `hand_written_agents_md_is_absorbed`, the installer also writes `AGENTS.md` notes into `AGENTS.local.md`. Two rule texts and one code comment still say it only does so for a `CLAUDE.md`: `method/AGENTS.md:4`, `method/commands/po-setup.md:17`, the header comment of `bin/polype:12` (owned, so fixable). s130 owns neither method file. s131 owns both, but none of its criteria fixes those sentences, so the method contradicts the installer from s130 onwards.
- major (M3) — s131 — `method/hooks/po-session.sh` is not owned and no criterion covers it. ADR-0086 has `po-session` flag any remaining `CLAUDE.md`: `po-session.sh:236-238` prints "Claude Code reads it instead of AGENTS.md → polype update . moves it into AGENTS.local.md", and `tests/no-claude-md.test.sh:98` pins that text. Under `kept`, every session would list the kept file as waiting for a human. When the setting is missing, `update` no longer moves the file, so the message becomes false. s131 should own `po-session.sh` and add a criterion for it.
- major (M4) — s131 — `kept` can still hide `AGENTS.md`. `kept_keeps_and_imports` only makes sure the root `CLAUDE.md` starts with `@AGENTS.md`. ADR-0073 and ADR-0086 record that Claude Code skips `AGENTS.md` when either `CLAUDE.md` or `CLAUDE.local.md` exists. A project with only a `CLAUDE.local.md`, kept and never imported, loses every rule in silence: that is exactly the nautile failure ADR-0086 was written for. The criterion should name that case, and also say whether `kept` creates a `CLAUDE.md` when none exists.
- major (M5) — s131 — When the line is missing, the behaviour does not match the default the scope announces. The scope says the rule "reste le défaut". `missing_setting_changes_nothing` says that without the line the installer touches no `CLAUDE.md`. That is consistent with ADR-0043 and Law "never fills a missing setting". But every project already installed whose `AGENTS.local.md` lacks the new line (only Polype's own file gets it) silently stops absorbing at its next `update`, while the pre-commit still refuses. That is a behaviour change for existing projects. The owner should confirm it, and the new ADR should state it.
- major (M6) — s131, s132 — Docs and pinned texts are left stale, or sit outside the Owns: s131 changes the rule in `docs/installation.md:9-11` and `:184-203` ("l'installeur absorbe ceux qu'il trouve"); s132's `install_doc_tells_the_truth` covers only collisions and `--set-aside`, so the install doc would keep describing unconditional absorption, and keep saying a hand-written `AGENTS.md` is only backed up (`:186`). `method/commands/po-architect.md:72` and `po-setup.md:56` both say "Never commit a `CLAUDE.md` (ADR-0086)", and `tests/framing-commands-cleanup.test.sh:42` pins that sentence; neither `po-architect.md` nor that test is in s131's Owns, yet under `kept` the sentence no longer holds unconditionally.
- minor (m1) — s130, s131 — Both have `Surface: —`, yet both change what `polype install`, `update`, `check` and `remove` print and their exit codes. `command` (which `cli` admits) describes them better. `QA stage: —` means no routing consequence.
- minor (m2) — s130 — Several cases are left open: absorbing `AGENTS.md` must happen before `assemble_agents_md` overwrites it; the criterion does not say whether `AGENTS.md.before-polype` stays after absorption, and a later `update` could absorb it a second time; `AGENTS.md` is a destination outside the manifest, and the text should say it is not a "collision"; stopping "sans rien écrire" also forbids today's ghost removals (`bin/polype:429-433`, `:469-471`).
- minor (m3) — s130 — Rated 3, but it has four distinct behaviours across install, init, update and remove in both installs, plus a set-aside record that `remove` must read back, in the global install too, where `remove` runs `rm -rf "$state_dir"`. That is near the ten-task limit. It could be a 4 with its risk named, or the bash guard could be split out.
- minor (m4) — s130 — `old_bash_is_named`: there is no bash 3 on the dev machine and `BASH_VERSINFO` is read-only. The notes should say how the test reaches the guard.
- minor (m5) — s130 — `tests/hooks-installer-docs-cleanup.test.sh:80` runs `remove` with a PATH limited to a fixed list of tools. Collision detection should use `cksum`, as `sum_of` does, not `cmp` or `diff`.
- minor (m6) — s132 — "le poids des règles chargées à chaque session" names no unit; `quickstart_runs_as_written` runs the shell commands of a block that also holds slash commands and needs a convention a test can parse; "la récupération du dépôt public" assumes the repository is public.
- minor (m7) — s131 — Owning the whole `docs/decisions/` is broader than needed. The new ADR's path plus ADR-0086's file would do.
- minor (m8) — s130 — Extending absorption to `AGENTS.md` and refusing on collisions change the installer's contract recorded by ADR-0086 (option B, stopping, was rejected there for `CLAUDE.md`). No ADR is asked for; the reasoning is unrecorded.

### Not verified
- Whether `atoll-labs-io/polype` is public.
- Whether macOS works beyond the bash version: BSD `find -delete`, `sed`, `readlink` and `tail -c` in `bin/polype`.
- `method/hooks/po-session.sh` uses `declare -A` (lines 105, 141, 142), so the SessionStart hook would fail under macOS bash 3.2 too.
- Whether a global `~/.claude/CLAUDE.md` also stops Claude Code from reading a project's `AGENTS.md`.
- Whether an `AGENTS.md` assembled by an older Polype, before the `<!-- Assembled by Polype.` marker existed, would be taken for a hand-written one.
- Owns overlaps against stories outside M11.
- Whether `bin/po-lint` or the structure tests demand a `Reads settings:` entry for the new setting.

Max severity: major
Stories ready: yes

> Answered at the next revision, 2026-10-14. M1: the threshold is 4.2, and the guard moves to s132 with `po-session`. M2: s130 owns `method/AGENTS.md` and `/po-setup` and its criterion rewrites the three sentences; s130 also writes ADR-0088 (m8). M3, M4, M6: s131 owns `po-session.sh`, `/po-architect` and `tests/framing-commands-cleanup.test.sh`, covers a lone `CLAUDE.local.md` under `kept` by creating a root `CLAUDE.md` holding `@AGENTS.md`, and s132 rewrites the install doc for absorption and the setting. M5, settled by the lead: a missing line changes nothing, as the rule on missing settings requires; the ADR says so, Polype gets the line in s131, pecten and nautile in their refresh pull request. Minors: `Surface: command`, the open cases of s130 and its risk in its notes, the guard test, `cksum`, a `sh` block for the quickstart, the size in Ko, ADR paths narrowed to ADR-0088, ADR-0089 and ADR-0086. The repository is public (`gh repo view`: PUBLIC).

## Loop 2

Review status: complete

The rewrite resolves every critical and major point from loop 1, and only three minor findings remain. The lead decided M5 (a missing line changes nothing, as the rule on missing settings requires), and the review takes that decision as given.

### Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| A first install silently replaces a file of the same name (`lay_down`), in both global and project installs | Objectif | s130 (`collision_stops_before_writing`, `set_aside_is_explicit_and_undone`) | yes |
| The user's existing agents and skills are not lost | Objectif | s130 (both installs, ghost removals included, round trip through `remove`) | yes |
| A hand-written `AGENTS.md` is set aside and no longer read | Objectif | s130 (`hand_written_agents_md_is_absorbed`) | yes |
| The "no CLAUDE.md" rule stays the default and becomes a setting | Objectif (owner decision) | s131 | yes |
| bash 4.2 is needed without being said (`bin/polype:359`, `po-session`) | Objectif | s132 (`old_bash_is_named`, `prerequisites_are_listed`) | yes |
| The README gives prerequisites, how to get Polype and where to start | Objectif | s132 (`prerequisites_are_listed`, `quickstart_runs_as_written`) | yes |
| Existing configuration explained ("possible de charger du contexte custom ?") | Objectif | s132 (`existing_config_is_explained`, `install_doc_tells_the_truth`) | yes |

Every story traces to an item of the Objectif.

### Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| none: the Objectif lists no non-goal | Objectif | none | no |

### Checks
- [x] Exclusions: no story revives an excluded item; none is listed.
- [x] No technical layer dressed as a story: each story is a command a person can run.
- [x] Every criterion can be checked by one test. The loop 1 points m4 and m6 are fixed. See m-b for a remaining drift risk.
- [x] Dependency order: s131 depends on s130 and s132 on s131. ADR-0088 and ADR-0089 do not exist yet, so there is no number clash.
- [x] Complexity: three stories at 3. s130 now names its risk (losing a file in `~/.claude/`) and the test that guards against it.
- [x] Ids: well formed, unique, in file order.
- [x] Owns: every story declares one, and every entry is well formed. The shared paths (`bin/polype`, `method/AGENTS.md`, `method/commands/po-setup.md`, `tests/install.test.sh`, `tests/installer.test.sh`, `method/hooks/po-session.sh`) are all between stories linked by a dependency, so there is no critical.
- [x] Surface: `command` for all three, which `cli` admits.
- [x] Owned records: s131 supersedes ADR-0086 in part and owns its file; s130's ADR-0088 is set against ADR-0086's option B without superseding it; no story carries a `Corrige` line.

### Loop 1 findings: what became of them
- **M1:** fixed. The threshold is 4.2, and s132 now guards both `bin/polype` and `po-session`.
- **M2:** fixed. s130 owns `method/AGENTS.md` and `po-setup.md` and its criterion rewrites the three sentences.
- **M3:** fixed. s131 owns `po-session.sh`, and `kept_keeps_and_imports` and `missing_setting_changes_nothing` say what it prints.
- **M4:** fixed. ADR-0089 has to state that it partly supersedes ADR-0086's "never writes a CLAUDE.md"; `adr_records_the_choice` covers this.
- **M5:** settled by the lead and written into the criterion and the ADR; consistent with ADR-0043.
- **M6:** fixed; one leftover pin is m-a below.
- **m1–m8:** fixed.

### Findings
- minor (m-a), s132: `tests/docs-and-eval-cleanup.test.sh:15-18` pins phrases of `docs/installation.md`, among them `ceux qu'il trouve (ADR-0086)`, in exactly the sentence `install_doc_tells_the_truth` asks to make conditional. s132 does not own that test: keep the phrase and add the condition after it, or add the test to s132's `Owns`. A note would save a blocked run.
- minor (m-b), s132: `existing_config_is_explained` asks for "le poids en Ko" of the assembled `AGENTS.md`, a number that changes with every edit to the rules. The test should compute the size and accept a tolerance, or the README should give an order of magnitude.
- minor (m-c), s132: `tests/hooks-installer-docs-cleanup.test.sh:108` refuses prose lines over 100 characters in `docs/installation.md`; worth a line in the notes.

### Not verified
- The repository's public visibility, taken from the coordinator's message.
- The other hooks' compatibility with bash 3.2 beyond `declare -A`, `declare -g`, `mapfile`, `readarray`, `${x,,}` and `[[ -v`.
- macOS beyond bash, and whether the README says it is not promised.
- Whether Claude Code applies `@AGENTS.md` imported from a `CLAUDE.md` created next to a `CLAUDE.local.md`.
- Whether an `AGENTS.md` assembled by an older Polype would be absorbed as hand-written.
- `Owns` overlaps with stories outside M11, and `bin/po-lint` against the new setting.

Max severity: minor
Stories ready: yes

> Answered at the next revision, 2026-10-14. m-a and m-c: s132's notes name both tests and what each pins. m-b: the README gives an order of magnitude, which the test recomputes within ±25 %. Stories ready: yes.

## Loop 3 — s133-any-harness-docs

Added to M11 on 2026-10-14 at the owner's request. Reviewed alone, in a context that did not write it. Scope source: the owner's request quoted in the story's notes, plus ADR-0005. Platform `cli`.

Review status: complete

### Coverage
| Scope item | Source section | Covered by | Covered |
| --- | --- | --- | --- |
| "c'est pour Claude Code et tous les autres types d'agent/harness": the docs say Polype targets any agent or harness | owner's request (story notes) | s133 (`docs_name_any_harness`, `portable_and_specific_parts_are_named`) | yes |
| "le demander en issue si pas disponible": a way to request an unsupported harness | owner's request (story notes) | s133 (`harness_issue_template_exists`, last clause of `docs_name_any_harness`) | yes |
| Codex comes next, the rest is deferred | ADR-0005 | s133 (`docs_name_any_harness`) | yes |

### Exclusions
| Excluded item | Source section | Revived by | Revived |
| --- | --- | --- | --- |
| Claiming support that does not exist (the Codex port itself) | story notes and ADR-0005 (Codex deferred) | none: the notes keep the port out of this story | no |

### Checks
- [x] Exclusions: no story revives an excluded item, under any name
- [x] No technical layer dressed as a story. It is a documentation slice that a reader can try.
- [ ] Every criterion can be checked by one test. See major findings 1 and 2.
- [x] Dependency order: `s132-readme-onboarding` exists and comes earlier (line 2048).
- [x] Complexity: 2, nothing to split.
- [x] Ids: `s133-any-harness-docs` is well formed, appears once and follows s132.
- [x] Owns: declared. `README.md` and `docs/installation.md` overlap with s132, but s133 depends on s132, so this is allowed. `method/commands/po-help.md` and `.github/ISSUE_TEMPLATE/` overlap with no unshipped M11 story (s130 and s131 own neither). Older stories that own `po-help.md` or `README.md` (s39, s48 and others) come from shipped milestones.

### Findings
- **major** — s133 — `portable_and_specific_parts_are_named` requires the README to say that `AGENTS.md`, the `SKILL.md` standard and the shell/git gates "sert déjà tout harness". That goes beyond ADR-0005 and beyond what the code does. The ADR says only that these choices keep a later port cheap ("pour que ce portage reste bon marché"). It does not say they work under another harness today. On the page: skills are installed under `.claude/skills/` or `~/.claude/skills/`, which another tool does not read; the `AGENTS.md` rules name subagents (`implementer`, `reviewer`) and `/po-*` commands; the story's own decision-log line (`docs/decisions-log.md:71`) notes that "24 method files rely on Claude Code subagents, hooks and AskUserQuestion". This breaks the notes' own rule "Ne rien promettre au-delà de ce que le code fait". The criterion should say "conçu pour être portable" or "lu par d'autres outils, sans garantie", not "sert déjà".
- **major** — s133 — In `docs_name_any_harness`, the sentence "Aucune phrase ne présente Polype comme réservé à Claude Code, ni n'annonce une prise en charge qui n'existe pas. Un test le tient." is a negative universal that no single test can check. It names neither the phrases to forbid nor where to look: the three owned files only, or also `method/AGENTS.md` and `docs/conception.md` (`| Multi-outil | ... | Claude Code d'abord |`), which the story does not own. It should name the files and the exact phrases the test refuses, or drop the clause and keep the positive statements.
- **minor** — s133 — `Surface: —` says nothing a person sees or runs changes. But `/po-help` prints the new text, and the README is what an outside person reads. `command` fits at least the `/po-help` part, and Platform `cli` admits it. With `QA stage: —` this has no effect on routing.
- **minor** — s133 — The `H03` line of `docs/parite-killer-saas.md:105` ("tableau honnête de ce qui se dégrade", status `partiel`) is partly delivered by `portable_and_specific_parts_are_named`. The repository convention asks a story that implements a parity line to update its status cell, but s133 does not own `docs/parite-killer-saas.md`. The story should either own it and update H03, or say in its notes why H03 stays as it is.
- **minor** — s133 — The notes protect the tests that quote the README and `docs/installation.md` word for word. They say nothing about tests that quote `method/commands/po-help.md`, such as the wiring tests of older stories that own it (s05/s20/s32-era Owns lines 116, 303, 466). The implementer should be warned to keep those phrases too.
- **minor** — M11 — The milestone introduction (line 2016) still says "Les trois stories ... passent l'une après l'autre", but M11 now has four stories. s133 is chained after s132, so the serial order holds and only the wording is stale.
- **minor** — s133 — Under `docs_name_any_harness`, "prévu ensuite, Codex (ADR-0005)" is consistent with the ADR. But the ADR's date ("vers mi-octobre 2026") is today, so the docs should not repeat a date that is about to pass. The notes could say so.

### Not verified
- **Whether issues are open on the public GitHub repository `atoll-labs-io/polype`.** The template and a relative link can exist while the forge refuses issues, and I read no code or forge state. A person should check on GitHub that issues are enabled.
- **Whether `.github/` already exists, and its `ISSUE_TEMPLATE/config.yml`.** The code is out of scope. If a `config.yml` turns off blank issues or points elsewhere, the new template could clash with it.
- **`Issue tracker: —` against "ouvrir une issue".** The setting governs defects (Law 7), not harness requests, so I read no contradiction. The owner may still want to confirm that pointing outsiders to GitHub Issues is intended while the project declares no issue tracker.
- **Every sentence in `README.md`, `docs/installation.md` and `po-help.md` that might say "Claude Code only".** I did not read those files, since the code and docs are out of scope. That is the reason major finding 2 asks the story to name the phrases.
- **Other harnesses' file layouts** (where Codex looks for skills, and whether it reads `AGENTS.md` and `SKILL.md`). I judged major finding 1 from ADR-0005 and the decisions log only, not from outside sources.

Max severity: major
Stories ready: yes

> Answered at the next revision, 2026-10-14. Major 1: the criterion now says "conçu pour se porter vers un autre outil", never that it works elsewhere already. Major 2: the test holds the three positive statements in the three owned files and refuses two named phrases there; `method/AGENTS.md` and `docs/conception.md` are left alone, as the notes say. Minors: `Surface: command`; the story owns `docs/parite-killer-saas.md` and updates H03; the notes protect `/po-help` quotes; the milestone says four stories; the ADR-0005 date is not repeated. Not verified: issues are enabled (`gh repo view`: `hasIssuesEnabled` true) and no `.github/` exists yet. Stories ready: yes.
