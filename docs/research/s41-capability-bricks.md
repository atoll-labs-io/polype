# Research — s41-capability-bricks

## Structuring facts
- No story assumption is false. Nothing exists yet under `method/skills/capability-bricks/` or `tests/capability-bricks.test.sh`; the skill is new, `po-architect.md` and `docs/catalogue.md` are amended.
- ADR-0020's table is in French (`docs/decisions/ADR-0020-briques-par-defaut-des-capacites.md:25-38`) but method files are in English (AGENTS.local.md, Conventions): the skill "reproduces" it translated, and its capability names must be the twelve English names the profile template already fixes (`method/templates/profile.md:40-51`), which `bin/po-lint:203-250` enforces for profiles.
- A new skill needs no registration: the installer copies every file under `method/skills/` (`bin/polype:86`, `bin/polype:100`, `shipped_pairs` `bin/polype:111-119`); `po-lint` only reads `commands/` and `agents/` (`bin/po-lint:76`); no test enumerates skills.
- `po-architect.md` Step 3 already drafts one ADR per capability (`method/commands/po-architect.md:43`) but never compares with a default table; the gap and the comparison are what this story adds.
- `po-architect.md:58` forbids this command from swapping a brick: a gap resolved in favour of the default is recorded, and a later story swaps it.

## Story
As a developer, one document guides the choice of a brick, so architecture stops reinventing it per project.
- `skill_lists_the_capabilities_and_their_default_bricks` — skill `capability-bricks` carries ADR-0020's table (capability, default brick, alternatives) and says when to switch to an alternative.
- `skill_defines_what_a_contract_test_must_prove` — per capability, what a contract test proves of any brick: at least nominal behaviour, expected refusal, observable data effect.
- `architect_chooses_bricks_and_records_the_gaps` — `/po-architect` compares the profile's bricks with ADR-0020's, keeps one choice per capability, records each gap as a project ADR.
- `self_hosted_edition_has_no_payment_brick` — the skill says a self-hosted edition is built without a payment brick and that the managed offer carries subscription and usage.
Owns: `method/skills/capability-bricks/`, `method/commands/po-architect.md`, `tests/capability-bricks.test.sh`, `docs/catalogue.md`. Matrix: B02 (bricks), C07 (capabilities).

## Current code
- `method/commands/po-architect.md` (66 lines). Step 1 (`:23-33`) looks for `boilerplates/<name>/profile.md` when Polype's repository is at hand, otherwise analysis only. Step 2 (`:35-38`) applies `codebase-analysis`. Step 3 (`:40-46`) drafts ADRs: stack, "each capability the project needs — database, authentication, …, deployment — naming the brick in use as the default and the bricks that could replace it" (`:43`), integrations (`:44`), numbering and `scope: framing` (`:46`). "Never rewrite the base" (`:57-58`). Approval drafts `docs/architecture.md` with its capability table (`:61`).
- `method/templates/architecture.md:24-29` — capability table `| Capability | Brick | Alternatives | ADR |`. Not owned by this story.
- `method/templates/profile.md:36-53` — `## Capabilities`, `| Capability | Brick | Notes |`, rows Database, Auth, Authorization, Multi-tenancy, Files, Jobs, Email, Payment, Cache and rate limiting, Observability, i18n, Deployment; "The names are fixed" (`:53`). Not owned.
- `docs/catalogue.md` (21 lines, French): the profile (`:5-11`), whose capability table "ne reprend que les noms de la liste d'ADR-0020" (`:10`), and the three boilerplate levels (`:13-21`). Nothing about default bricks or contract tests.
- Existing skills (`method/skills/*/SKILL.md`): frontmatter `name:` + `description:` ending with who uses it (e.g. `codebase-analysis/SKILL.md:2-3`), then `# Title` and `## ` sections; 20-86 lines each.

## Attachment points
- `method/skills/capability-bricks/SKILL.md` — new file, same frontmatter shape as `method/skills/codebase-analysis/SKILL.md:1-4`.
- `method/commands/po-architect.md:40-46` (Step 3) — where the skill is read, the profile compared, the gap recorded. Commands name skills in backticks: "Apply the `codebase-analysis` skill" (`:36`).
- `docs/catalogue.md` — a French section after `## Le profil` pointing at the skill.

## Verified interfaces
- ADR-0020 rows (`ADR-0020…md:27-38`): Database = self-hosted PostgreSQL, versioned migrations by the profile's ORM / host's managed Postgres. Auth = Better Auth, sessions and accounts in our database / Clerk or the profile's auth. Authorization = application policies, matrix tested once / —. Multi-tenancy = organisations in the database, tenant filter checked at the repository / —. Files = S3 API, self-hosted Garage / host's S3, Vercel Blob. Jobs = queue in Postgres (pg-boss or the profile's equivalent) / Inngest, Trigger.dev. Email = SMTP, relay of choice / Resend or equivalent. Payment = Stripe for the managed offer, no brick in the self-hosted edition / Merchant of Record (Polar, Lemon Squeezy) when B2C VAT justifies it. Cache and rate limiting = Postgres, or self-hosted Valkey if load requires / Upstash. Observability = OpenTelemetry to a self-hosted collector / Sentry. i18n = the profile framework's library / —. Deployment = container image; mustelinet on managed Kubernetes or VM / chosen host's platform.
- Switch conditions available in the ADRs: managed alternative "quand un hébergeur ou une charge le justifie" (`ADR-0020:19`); MoR when B2C VAT justifies (`:34`, `ADR-0011:28`); Valkey when load requires (`:35`).
- Self-hosted / managed editions: `ADR-0011:27` — self-hosted edition runs without a payment brick; managed offer carries subscription **and** usage billing (usage meters). `ADR-0020:41`.
- Contract tests: `ADR-0009:27` — each capability pays an interface and a contract test set every brick must pass. Gaps: `ADR-0009:28`, `ADR-0020:43` — the gap with the table is settled at architecture, brick by brick, as a project ADR.
- Test helpers: `contains`, `require_file`, `fail` (`tests/lib.sh:11,41,43`); `section_of` pattern (`tests/architect.test.sh:8`); table-cell parsing pattern (`bin/po-lint:203-213`).

## Traps
- `tests/architect.test.sh` reads `po-architect.md`: Step 3 must keep the words `stack`, `capability`, `integration` (`:40-43`), the sentence 'Each structural choice becomes one ADR in `docs/decisions/` from `templates/adr.md`' (`:39`), the never-rewrite sentence (`:48`), the Step 2 → Step 3 heading order (`:27-30`). `tests/wiring.test.sh:27` only needs `/po-architect` named.
- `tests/overlap.test.sh` runs for real here: the Killer SaaS sources exist at its default path, so no line of the new skill may share 8+ consecutive words with them (ADR-0006). Write from ADR-0020/0009/0011, not from any other source.
- `po-lint` rejects a command's `Reads settings:` unknown setting (`bin/po-lint:98-115`); the architect's line (`po-architect.md:14`) needs no change — no new setting.
- The skill's capability names must equal the profile template's (`profile.md:40-51`) or s42/s43 profiles and notes will not line up; a test comparing the two lists catches drift.
- Not owned, so out of reach: `docs/parite-killer-saas.md` (B02 `:28`, C07 `:42` — their status cells are s44's job, stories.md:667), `method/AGENTS.md`, `method/commands/po-help.md`, `po-setup.md`, `method/templates/*`.
- Baseline: `bash tests/run.sh architect.test.sh profile.test.sh overlap.test.sh` → 11 passed.
- No migration, no screen, no dependency, no API contract; authorization and tenancy appear only as table rows of a document.

## Open questions
- Does a capability whose chosen brick equals the default still get its own ADR? Step 3 says yes today (`po-architect.md:43`) and ADR-0009:28 says the project's brick choice is recorded as a project ADR; the plan keeps that and adds the gap inside it.
- What "expected refusal" means for i18n, Observability and Deployment, which have no access rule — the plan settles one each.
- Project repos do not carry Polype's `docs/decisions/`: the skill cites ADR-0020 as origin but must stand alone.

## Complexity
3 → 3. One new document of about 60-80 lines, one step of one command, one test file; the only coupling is the architect tests and the profile's capability names.

## Split
Not needed.
