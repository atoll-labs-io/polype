---
validated: yes
---
# Plan — s41-capability-bricks

[Story](../stories.md) · [Research](../research/s41-capability-bricks.md)

Branch `story/s41-capability-bricks`. Read `docs/research/s41-capability-bricks.md` first; this plan builds on it without repeating it.

Validated autonomously (`Plan validation: autonomous`): no human reviewed this plan.

## Story
One document guides the choice of a brick, so architecture stops reinventing it per project.
- `skill_lists_the_capabilities_and_their_default_bricks` — skill `capability-bricks` carries ADR-0020's table (capability, default brick, alternatives) and says when to switch.
- `skill_defines_what_a_contract_test_must_prove` — per capability: nominal behaviour, expected refusal, observable data effect, for any brick.
- `architect_chooses_bricks_and_records_the_gaps` — `/po-architect` compares the profile's bricks with the defaults, keeps one choice per capability, records each gap as a project ADR.
- `self_hosted_edition_has_no_payment_brick` — the skill says the self-hosted edition has no payment brick and the managed offer carries subscription and usage.

## Tasks
1. [x] **Skill, defaults and editions.** Create `method/skills/capability-bricks/SKILL.md`, in English, frontmatter shaped like `method/skills/codebase-analysis/SKILL.md:1-4`: `name: capability-bricks`, a `description:` ending with who reads it ("Read by /po-architect and by whoever writes a boilerplate profile."). Body, in this order:
   - `# Capabilities and their bricks`, then two or three sentences: a capability is an interface, a brick implements it, the default is chosen self-hostable first so an edition users host themselves needs no third-party account; the table comes from Polype's ADR-0020 and stands alone in a project that does not carry it.
   - `## Default bricks` — one table, header exactly `| Capability | Default brick | Alternatives | Switch when |`, twelve rows whose first cell is **exactly** the profile template's names in its order (`method/templates/profile.md:40-51`): Database, Auth, Authorization, Multi-tenancy, Files, Jobs, Email, Payment, Cache and rate limiting, Observability, i18n, Deployment. Default and Alternatives cells translate ADR-0020 rows `:27-38` (research, "Verified interfaces"), keeping every brick name as written there (PostgreSQL, Better Auth, Clerk, Garage, Vercel Blob, pg-boss, Inngest, Trigger.dev, SMTP, Resend, Stripe, Polar, Lemon Squeezy, Valkey, Upstash, OpenTelemetry, Sentry, mustelinet). Alternatives of Authorization, Multi-tenancy and i18n is `—`. The Payment default cell says, with the words `self-hosted edition`, that this edition has no payment brick. `Switch when` is filled on every row: for a row with alternatives, the condition that justifies the switch (the host provides a managed equivalent and the project accepts depending on it; the load outgrows Postgres for Cache; B2C VAT for Payment's Merchant of Record); for a `—` row, say that the rule stays in the application whatever the host.
   - One paragraph under the table: a switch is a configuration change behind the capability's interface, never a rewrite of application code (ADR-0009), and it is recorded as a project ADR.
   - `## Two editions` — contains, verbatim, the sentences `The self-hosted edition is built without any payment brick.` and `The managed offer carries subscription and usage billing.`, plus one sentence on why (users host it themselves, no paid service may be required; usage billing needs usage meters — `ADR-0011:27`).
   Test able to fail: `skill_lists_the_capabilities_and_their_default_bricks` and `self_hosted_edition_has_no_payment_brick` (task 4).
2. [x] **Skill, contract tests.** Append `## Contract tests` to the same file: the sentence `A contract test is written against the capability, never against one brick: every brick that implements it must pass the same tests.`, then one table with header exactly `| Capability | Nominal behaviour | Expected refusal | Observable data effect |`, the same twelve names in the same order, no empty cell and no `—` in the three last columns. Settled refusals for the capabilities without an access rule: i18n — a missing key in a supported locale fails the check instead of rendering the key; Observability — an unreachable collector never fails the user's request (the telemetry is dropped, the request succeeds); Deployment — the image refuses to start when a required setting is missing. Data effects stay observable from outside the brick (row written, object readable back, job state recorded, message captured by a test SMTP server, meter incremented…). Test able to fail: `skill_defines_what_a_contract_test_must_prove`.
3. [x] **`/po-architect` Step 3.** In `method/commands/po-architect.md`, Step 3 (`:40-46`) only:
   - Before the bullet list, add: `Read the `capability-bricks` skill before drafting them.`
   - Rewrite the capability bullet (`:43`) so it keeps the twelve capabilities and the no-ADR rule for an unneeded capability, and names the brick **retained** as the default of the project with the bricks that could replace it.
   - After the list, add a paragraph containing verbatim: `For each capability, compare the brick the profile declares with the default brick of the skill` (without a profile: the brick the code of step 2 shows; with an empty repository: the default applies), `retain exactly one brick per capability`, and `each gap is recorded in the project ADR of that capability, which names the profile's brick, the default, the brick retained and the switch condition that justifies it.` Define a gap in that paragraph: a capability whose profile brick differs from the skill's default. Add: `A gap is never settled in silence.` and that retaining the default over the profile's brick records the choice only — the swap is a later story, as "Never rewrite the base" says.
   - Keep untouched: the sentence `Each structural choice becomes one ADR in `docs/decisions/` from `templates/adr.md``, the words `stack` and `integration` bullets, `:46`, and every other section.
   Test able to fail: `architect_chooses_bricks_and_records_the_gaps`; the existing `tests/architect.test.sh` stays green.
4. [x] **Tests.** Create `tests/capability-bricks.test.sh` (header comment `# s41 — the capability catalogue: default bricks, contract tests, the architect's gaps.`), `SKILL="$METHOD/skills/capability-bricks/SKILL.md"`, `ARCHITECT="$METHOD/commands/po-architect.md"`, `PROFILE="$METHOD/templates/profile.md"`. Helpers: `section_of` as in `tests/architect.test.sh:8`; `table_rows <file> <heading>` printing each data row of the first table of that section as tab-separated trimmed cells (header and separator dropped, parsing as `bin/po-lint:203-213`). Four functions:
   - `test_skill_lists_the_capabilities_and_their_default_bricks` — `require_file`; the header line is present; the first cells of `## Default bricks` equal, in order, the capability names of the profile template's `## Capabilities` table (so the two lists cannot drift); per row, the default cell and the alternatives cell hold: Database `PostgreSQL`/`Postgres`; Auth `Better Auth`/`Clerk`; Files `Garage`/`Vercel Blob`; Jobs `pg-boss`/`Inngest`; Email `SMTP`/`Resend`; Payment `Stripe`/`Polar`; Cache and rate limiting `Valkey`/`Upstash`; Observability `OpenTelemetry`/`Sentry`; Deployment `container image`; Authorization, Multi-tenancy, i18n alternatives exactly `—`; every `Switch when` cell non-empty.
   - `test_skill_defines_what_a_contract_test_must_prove` — header line present; first cells equal the same twelve names; no cell of columns 2-4 is empty or `—`; the "never against one brick" sentence present.
   - `test_architect_chooses_bricks_and_records_the_gaps` — within `section_of "$ARCHITECT" 'Step 3 — Structural decisions'`, grep the four verbatim clauses of task 3 (`capability-bricks`, `compare the brick the profile declares with the default brick of the skill`, `retain exactly one brick per capability`, `each gap is recorded in the project ADR of that capability`) and `A gap is never settled in silence.`
   - `test_self_hosted_edition_has_no_payment_brick` — the two verbatim sentences of `## Two editions`, checked inside that section; and the Payment row's default cell names the self-hosted edition having no brick.
   Run `bash tests/run.sh capability-bricks.test.sh architect.test.sh`.
5. [x] **Catalogue.** In `docs/catalogue.md` (French), add after `## Le profil` a section `## Capacités et briques` of three to five lines: the default bricks, their alternatives, when to switch and what a contract test proves live in `method/skills/capability-bricks/SKILL.md`, taken from ADR-0020; `/po-architect` compares a profile with it and records each gap as a project ADR; a profile's capability names are the same twelve. No test (documentation prose; the rules it restates are tested on the skill).
6. [x] **Closing checks**, once: `bash tests/run.sh` (full suite, `Full suite: execute-end`, including `overlap.test.sh`, which runs for real here), then `bin/po-lint` clean. An overlap hit is fixed by rewording the skill, never by widening `ALLOWED` in `tests/overlap.test.sh`.

## Run interdicts
- Empty diff on `docs/parite-killer-saas.md` (B02/C07 status cells belong to s44, `docs/stories.md:667`), `method/AGENTS.md`, `method/commands/po-help.md`, `method/commands/po-setup.md`, every `method/templates/*`, `bin/*`, every existing `tests/*.test.sh`, `docs/decisions/*`.
- Nothing under `.claude/` or `.polype/` (installed copies) and no `boilerplates/` folder: profiles and brick notes are s42 and s43.
- In `po-architect.md`, only Step 3 changes: `git diff` shows no hunk outside `## Step 3 — Structural decisions`; the `Reads settings:` line and the frontmatter are unchanged.
- No new setting, no ADR file (none is needed, see the pivot), no reference in the skill to any Killer SaaS file or wording.
- The skill stays in English; `docs/catalogue.md` stays in French.

## The pivot
**A gap is recorded inside the project ADR of its capability, which Step 3 already drafts for every capability, rather than in a separate "gap ADR", and the architect records the choice but never swaps the brick.** This follows `po-architect.md:43` (one ADR per capability), `ADR-0009:28` (the project's brick choice is a project ADR) and `ADR-0020:43` (the gap is settled brick by brick at architecture), so no new structural choice is made and ADR-0021 stays unused. How it could be wrong:
- The story means "one extra ADR per gap" — compare with `docs/stories.md:622` ("enregistre chaque écart en ADR de projet"): an ADR per capability that states the gap satisfies it; the reviewer checks the gap cannot be left unwritten (`A gap is never settled in silence.`).
- Retaining the default over the profile's brick could read as this command rewriting the base — compare with `po-architect.md:57-58`: the new paragraph must say the swap is a later story.
- The twelve capability names drift from the profile template — the first test compares the two lists instead of a hard-coded copy, so a rename on either side turns it red.

## Files touched
- `method/skills/capability-bricks/SKILL.md` (new)
- `method/commands/po-architect.md` (Step 3)
- `tests/capability-bricks.test.sh` (new)
- `docs/catalogue.md`
- `docs/research/s41-capability-bricks.md`, `docs/plans/s41-capability-bricks.md` (committed with the code)

## Test strategy
Automated, 4 tests of 25, one per acceptance criterion, each at the only layer there is: the document under test.
- `skill_lists_the_capabilities_and_their_default_bricks` — would fail if a row were dropped, renamed, reordered against the profile template, or its default/alternative changed, or a switch condition removed.
- `skill_defines_what_a_contract_test_must_prove` — would fail if a capability lost its contract row or any of the three columns were left empty or `—`.
- `architect_chooses_bricks_and_records_the_gaps` — would fail if Step 3 stopped reading the skill, comparing, retaining one brick, or recording the gap; scoped to Step 3 so a phrase elsewhere does not answer for it.
- `self_hosted_edition_has_no_payment_brick` — would fail if either edition sentence were removed from `## Two editions`.
Existing tests kept green, none changed: `architect.test.sh` (Step 3 wording), `overlap.test.sh` (ADR-0006), `profile.test.sh`. No visual check.

## Done when
- The four tests pass, the full suite passes and `bin/po-lint` reports no breach.
- One commit on `story/s41-capability-bricks` by the implementer, with `docs/verif/s41-capability-bricks.md`; a review with no open critical finding; squash-shipped to `m4-catalogue`.
