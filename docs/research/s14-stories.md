# Research — s14-stories

## Structuring facts
- `po-help` must list every command: `tests/pilot.test.sh:38-46` fails when `method/commands/po-stories.md` exists without `/po-stories` in `method/commands/po-help.md`. That file is outside Owns; s12 and s13 each added one line there (`method/commands/po-help.md:13-14`). s14 needs the same one-line exception.
- The two sources are contracts written by earlier stories: `docs/prd.md` has frontmatter `mode: <replace | adapt>`, `status: draft|approved` and the sections `## Core loop`, `## Graveyard`, `## Angle` (`method/templates/prd.md:1-35`); `docs/brief.md` has `status: interviewing|approved` and `## Wedge & non-goals`, `## Premises`, `## Gap map` (`method/templates/brief.md:1-88`). `/po-prd` writes `approved` only after a full read (`method/commands/po-prd.md:52`), `/po-brief` only after its exit criteria (`method/commands/po-brief.md:33-41`).
- `Entry mode` values are `replace` · `adapt` · `new` · `—` (`method/templates/agents-local.md:23,46`); both sibling commands stop on `—` without guessing (`po-prd.md:23`, `po-brief.md:25`). `/po-stories` must map `replace`/`adapt` → `docs/prd.md` (missing → `/po-prd`), `new` → `docs/brief.md` (missing → `/po-brief`).
- The output format already exists: `method/templates/stories.md:1-18` defines the id, the complexity scale (1–5, "A 4 names its main risk. A 5 is split before anyone plans it."), `Depends on`, `Owns` and "Notes for the agent" (which already mentions "the screen or flow to imitate"). The command fills it; it does not change it (not in Owns).
- Killer SaaS has an `agentic-stories` mechanism (C05, `docs/parite-killer-saas.md:40`) and its sources are present locally, so `tests/overlap.test.sh` runs for real: the skill must be written in our own words from the French description of C05.

## Story
`/po-stories` turns the PRD or the brief into deliverable stories that an agent can build without guessing. Criteria:
- `stories_reads_prd_or_brief_by_entry_mode` — source `docs/prd.md` (`replace`, `adapt`) or `docs/brief.md` (`new`, approved); missing source → stop and point to the right command.
- `agentic_stories_skill_rejects_technical_layers` — the skill requires usable vertical slices (never "create the table"), with a bad / good example.
- `agentic_stories_skill_requires_owns_and_contracts_first` — each story declares `Owns`; an interface shared by two stories becomes an earlier story (contract first).
- `stories_split_complexity_five_and_order_dependencies` — a 5 is split at once, a 4 states its risk, no story depends on a later one.
- `stories_never_revive_the_graveyard` — in `replace`/`adapt`, nothing from the graveyard becomes a story; each story can point to the target's equivalent screen.

## Current code
- `method/commands/`: eleven `po-*.md`, no `po-stories.md`. Closest models: `po-prd.md` and `po-brief.md` (frontmatter `description`, `argument-hint`, `allowed-tools` Read/Glob/Grep/Write/Bash/AskUserQuestion; `Reads settings: \`Entry mode\`, \`Target branch\``; sections Checks / … / Finish; commit on `Target branch` from the repository root after checking `git status --porcelain` for environment files) (`po-prd.md:1-55`, `po-brief.md:1-50`).
- `method/skills/`: `codebase-analysis`, `interrogation`, `review-antihallu`, `testing-doctrine`; each `SKILL.md` with frontmatter `name`, `description` (`method/skills/interrogation/SKILL.md:1-4`). No `agentic-stories/`. Installed recursively (`bin/polype-dev-install:46`, `tests/install.test.sh:9-25`).
- Both sibling commands end with "Next: write the stories in docs/stories.md." (`po-prd.md:55`, `po-brief.md:50`); `po-setup.md:46` and `po-help.md:15` say the same. Not in Owns.
- Downstream readers of `docs/stories.md`: `/po-research`, `/po-plan`, `/po-execute`, `/po-ship` match ids in it (`po-research.md:21` etc.); `/po-status` reads the complexity (`po-status.md:17`); `/po-orchestrator` stage 0 needs it. The format must stay the template's.
- Parity C05 description (`docs/parite-killer-saas.md:40`): vertical slice, each criterion becomes a test, agent notes (files, constraints, pitfalls), ordered dependencies, size ≤ ~10 tasks, scored complexity (4 names risk, 5 split), target pointed as reference, stable `s<n>-<slug>` id; Polype adds declared ownership and contracts first. Status today: `partiel`.

## Attachment points
- New: `method/commands/po-stories.md`, `method/skills/agentic-stories/SKILL.md`, `tests/stories.test.sh`.
- One line in `method/commands/po-help.md` « Mise en place », after `/po-brief` (outside Owns, forced by `pilot.test.sh:38`).
- Matrix: status cell of C05 in `docs/parite-killer-saas.md:40` (`partiel — …` → `fait — …`).

## Verified interfaces
- `tests/lib.sh`: `contains FILE PHRASE` (fixed string, case-sensitive), `require_file`, `needs_tool`/`lacks_tool`, `settings_read_by FILE`, `frontmatter FILE`, `fail`.
- `tests/brief.test.sh:9`: `section_of FILE HEADING` idiom (awk) to scope an assertion to one `## ` section — reusable by copy (it is local to that file, not in `lib.sh`).
- `tests/structure.test.sh:147-157`: every command needs a `Reads settings:` line with template settings only → `Entry mode`, `Target branch` are valid.
- `tests/run.sh`: focused run `bash tests/run.sh stories.test.sh`. Baseline on `story/s14-stories`: 91 passed, 0 failed.

## Traps
- `tests/overlap.test.sh`: 8+ consecutive words shared with Killer SaaS fail the suite; write fresh prose, especially for the skill whose Killer SaaS counterpart has the same name.
- `tests/pilot.test.sh:38` — see above.
- Method files in English; `po-help` in French.
- `/po-stories` writes `docs/stories.md` and commits it → needs Write and Bash, like `po-prd`/`po-brief`; it does not write code.
- A graveyard leak is easy to miss when a story bundles a buried feature under another name; the skill should make the check explicit (each story traced to a core-loop line or the angle).
- No migration, no code outside `method/`, `tests/`, `docs/`.

## Open questions
- Does the PRD source also require `status: approved`? The criterion says "approved" only for the brief; mirroring it for the PRD is consistent (`/po-prd` has the same lifecycle). The plan decides.
- Existing `docs/stories.md` (e.g. more stories after a first batch): append new stories with the next free numbers, or stop? The plan decides; renumbering existing ids must be forbidden (ids are reused by branches and files).
- Human validation: stories are shown before writing, like the PRD sections? Probably show the whole list, get agreement, then write and commit.
- The four "Next: write the stories in docs/stories.md." lines outside Owns could point to `/po-stories`; changing them is not required by any criterion. Leave them (Owns) unless the plan argues otherwise.
- Contract-first stories: an interface shared by two stories (API shape, schema, event) becomes its own earlier story — is that a vertical slice? The skill must say it is the one allowed exception, with a test or a caller that makes it observable.

## Complexity
Story 3 → 3. Three new files and one help line; the effort is ~80 lines of skill prose in our own words and tests that pin rules without overfitting.

## Split
Not needed.
