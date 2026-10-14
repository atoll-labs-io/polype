---
track: flow
validated: yes
---
# Plan (short track) — s44-catalogue-wiring

[Story](../stories.md)

Written by `/po-flow`. On the short track this one file stands in for both the research and the plan: there is no `docs/research/s44-catalogue-wiring.md`.

## Verified facts
- **Story assumption to correct in wording, not in scope**: "enregistre le choix" cannot become a new setting — `method/templates/agents-local.md` is outside this story's `Owns` (and the "profil de boilerplate" setting belongs to parity line B02, not listed here). The choice is recorded as one line in the `## Conventions` section of `AGENTS.local.md`, which setup writes anyway.
- `method/commands/po-setup.md:21-27` — step 1 collects package manager, scripts, default branch; nothing about a base or a profile.
- `method/commands/po-setup.md:29-38` — step 2: five numbered questions, one design follow-up, then "Nothing else is asked beyond these five questions and that follow-up".
- `method/commands/po-setup.md:43` — step 3.1: "Leave the conventions placeholder as it is."
- `method/commands/po-setup.md:48` — closing line points to docs/stories.md and /po-research.
- `tests/setup-modes.test.sh:30-37` — step 2 must list exactly 5 lines matching `^[0-9]+\. ` and must contain `Nothing else is asked`. So the profile offer is a follow-up paragraph, never a numbered question.
- `tests/design-handoff.test.sh:43` — setup must not contain "in the same call".
- `tests/structure.test.sh:37-43` — keeps three exact setup phrases (do not touch them).
- `method/commands/po-architect.md:22-26` — "A base is detected when the repository holds a package manifest, or source files outside Polype's own files …"; "when Polype's repository is at hand, `boilerplates/<name>/profile.md` there describes a catalogued boilerplate". Setup reuses this definition and this wording.
- `method/commands/po-architect.md:51` — a first run replaces the conventions placeholder; a rerun keeps every rule already written. A setup-written line is therefore kept by the architect.
- `method/templates/profile.md:22` + `boilerplates/next-forge/profile.md:12-20` — the profile's `## Commands` block uses the setting names verbatim (`Install`, `Test`, `Typecheck`, `E2E`, `Build`); `Identity and licence` gives `Commit profiled:`.
- Profiles today: `boilerplates/next-forge/profile.md` only; `boilerplates/bricks/` holds brick notes, not profiles.
- `method/AGENTS.md:1-40` (Law 1, Framing) and `:111-117` (Installed files): no mention of `boilerplates/` or profiles.
- `method/commands/po-help.md:16,21` — `/po-setup` and `/po-architect` lines; no catalogue mention. French file; `tests/pilot.test.sh:35-45` checks every command is listed.
- `docs/parite-killer-saas.md:29` B03 `partiel — … ; pré-remplissage par /po-setup à venir`; `:36` C01 `partiel — … ; boilerplate en M4`; `:42` C07 `fait — … ; catalogue en M4`.
- `docs/catalogue.md:3` already says "le setup y prend les commandes du projet" — the design below matches it.

## Escalation signals

| Signal | Before reading the code | After reading the code |
| --- | --- | --- |
| Migration | absent — story text | absent — markdown method files only |
| New screen | absent — story text | absent — no UI in this repository |
| Authorization or tenant scope | absent — story text | absent — po-setup / AGENTS.md |
| API contract | absent — story text | absent — no settings added, template untouched |
| New dependency | absent — story text | absent — bash tests only |

## Story
En tant que développeur je veux que le setup et l'architecture proposent le catalogue afin qu'un nouveau projet en profite sans le connaître.
- `setup_offers_the_catalogue` — `/po-setup` propose les profils disponibles quand le projet démarre sans boilerplate, et enregistre le choix.
- `rules_name_the_catalogue` — les règles disent où vivent les profils et que l'architecture s'appuie dessus.
- `help_mentions_the_catalogue` — l'aide cite le catalogue en une ligne.
- `parity_matrix_reflects_the_catalogue` — B03, C01 et C07 passent à `fait — <chemin>` ou disent précisément ce qui reste.

## Tasks

1. [x] `method/commands/po-setup.md`:
   - Step 1: add a bullet — whether the repository has a base, using the architect's definition (package manifest, or source files outside Polype's own files).
   - Step 2: after the design follow-up paragraph, a new paragraph (not a numbered item): when step 1 found no base, list the profiles of Polype's catalogue (`boilerplates/*/profile.md` in Polype's repository, when it is at hand) in one AskUserQuestion, before question 5, each with its name and origin, plus an answer "no profile". A chosen profile's `## Commands` block becomes the suggestions of question 5, copied verbatim. Catalogue unreachable → say so and carry on without a profile; a base found → no offer.
   - Replace "these five questions and that follow-up" with wording that also covers the profile follow-up, keeping `Nothing else is asked`.
   - Step 3.1: the placeholder stays, unless a profile was chosen: then the conventions section holds one line naming `boilerplates/<name>/profile.md` and its `Commit profiled`, which `/po-architect` starts from.
   - Closing: when a profile was chosen, tell the person to bring the boilerplate in at that commit and commit it before `/po-architect`.
   — Test: `setup_offers_the_catalogue` fails if the offer, the no-base condition, the commands pre-fill or the recording line disappears.
2. [x] `method/AGENTS.md`: one short paragraph under "### Framing" (after the table) — profiles live in Polype's repository at `boilerplates/<name>/profile.md`; `/po-setup` offers them to a project with no base and records the one chosen in `AGENTS.local.md`'s conventions; `/po-architect` starts its reading from that profile and the project's code confirms or corrects it. — Test: `rules_name_the_catalogue`.
3. [x] `method/commands/po-help.md`: one French line (sub-bullet of `/po-setup` or extended `/po-setup` line) citing the catalogue `boilerplates/`. — Test: `help_mentions_the_catalogue`.
4. [x] `docs/parite-killer-saas.md`, lines B03, C01, C07 only: B03 → `fait — method/templates/agents-local.md, method/templates/profile.md, bin/po-lint, method/commands/po-setup.md`; C01 → `fait — method/commands/po-setup.md`; C07 → `fait — …` with `boilerplates/` and without "catalogue en M4". — Test: `parity_matrix_reflects_the_catalogue`.
5. [x] `tests/catalogue-wiring.test.sh`: the four tests above, exact short phrases from the files, helpers of `tests/lib.sh`. Then the full suite `bash tests/run.sh`.

## Run interdicts
- `method/templates/agents-local.md`, `method/commands/po-architect.md`, `bin/`, `.claude/`, `.polype/`, root `AGENTS.md` end with an empty diff.
- No new numbered question in po-setup step 2; the phrases checked by `setup-modes`, `structure`, `design-handoff` tests stay.
- Only lines B03, C01, C07 of the parity matrix change.
- No existing test edited.
- No Killer SaaS text (`tests/overlap.test.sh`).

## Files touched
`method/commands/po-setup.md`, `method/AGENTS.md`, `method/commands/po-help.md`, `docs/parite-killer-saas.md`, `tests/catalogue-wiring.test.sh`, plus this plan and `docs/verif/s44-catalogue-wiring.md`.

## Test strategy
Four contract tests on text (the only layer this repository has), one per criterion, named as the criterion; each quotes a clause that disappears if its rule is removed. For the matrix, the test reads the status cell of B03, C01, C07 and requires `fait — ` and the absence of "à venir" / "en M4". 4 tests, budget 25. Full suite once at the end of execute (`Full suite: execute-end`).

## Done when
One commit on `story/s44-catalogue-wiring`, full suite green, `docs/verif/s44-catalogue-wiring.md` complete, review without open critical finding.
