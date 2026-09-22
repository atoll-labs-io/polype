# Research — s42-next-forge-profile

Clone read: `git clone --depth 1 https://github.com/vercel/next-forge` into `/tmp/nextforge.uQ1I/next-forge`, commit `f189de79ceef7c1ef69f61f12e272f99b4cdb699` (2026-05-28), package version 6.0.2. `NF:` below means a path of that clone.

## Structuring facts
- **The story assumes pnpm-like commands; next-forge runs on Bun** (`NF:package.json:50` `"packageManager": "bun@1.3.10"`, lockfile `bun.lock`). Every command of the profile is a `bun`/`bunx` command.
- **No root command accepts test paths**: root `test` is `turbo test` (`NF:package.json:23`); only `apps/app` and `apps/api` define `test: NODE_ENV=test vitest run` (`NF:apps/app/package.json:9`, `NF:apps/api/package.json:10`). The template requires a `Test` that accepts paths (`method/templates/profile.md:22`) — the plan must settle this.
- **No root typecheck**: every workspace has a `typecheck` script, but neither the root `package.json` nor `NF:turbo.json:6-33` defines a `typecheck` task.
- The lint already checks every `boilerplates/*/profile.md` (`bin/po-lint:215-252`), and `tests/lint.test.sh:45-48` runs it on the real tree: a profile breaking the template turns an existing test red.
- The "grounded" criterion needs the network (a clone); the suite's precedent for an external source is to skip with a message when it is absent (`tests/overlap.test.sh:10-15`).

## Story
A real profile of next-forge at `boilerplates/next-forge/profile.md`, plus `tests/next-forge-profile.test.sh`. Criteria:
- `next_forge_profile_passes_the_lint` — `bin/po-lint` accepts it.
- `next_forge_profile_is_grounded_in_the_real_repository` — every command, path and capability cited is checked in a clone, the commit recorded in the profile.
- `next_forge_profile_states_its_gaps_against_adr_0020` — names the capabilities whose default brick differs from ADR-0020 (auth, database, files at least) and what must be written to replace them.
- `next_forge_profile_declares_ownership_granularity` — which path a story can own alone, from the package split.
Notes: clone in a temporary folder, never in the repository; describe, never copy a file of the boilerplate.

## Current code
- `boilerplates/` does not exist yet; this story creates it. `bin/po-lint:190-191` looks for it at `method/../boilerplates`.
- `method/templates/profile.md` — the format: eight `## ` sections (`:5-61`), a Commands fence of exactly `Install Test Typecheck E2E Build` (`:14-20`), a capability table `| Capability | Brick | Notes |` with twelve fixed names (`:38-51`), keep only the rows provided (`:53`).
- `method/skills/capability-bricks/SKILL.md:9-22` — the default bricks (ADR-0020 in English); the profile's gaps are measured against it.
- `docs/catalogue.md` — French doc of the catalogue; not owned by this story (s43 owns it).

## Attachment points
- New file `boilerplates/next-forge/profile.md` (English, like method files? — see open questions).
- New file `tests/next-forge-profile.test.sh`, helpers of `tests/lib.sh` (`require_file`, `contains`, `fail`, `ROOT`).

## Verified interfaces (next-forge at f189de7)
- Licence: MIT, `NF:license.md:1-3` ("Copyright (c) 2025 Vercel").
- Workspaces `apps/*`, `packages/*` (`NF:package.json:60`). Root scripts: `build: turbo build` (:19), `check: ultracite check` (:21, Biome lint), `test: turbo test` (:23), `boundaries: turbo boundaries` (:26), `migrate` (:29, Prisma in `packages/database`).
- `NF:turbo.json`: `build` depends on `^build` and `test`; tasks `test`, `analyze`, `dev`, `translate`, `clean`; no `typecheck`, no `lint`.
- Apps (`NF:apps/`): `app` (main SaaS, port 3000, Clerk-protected `(authenticated)` routes, `__tests__/sign-in|sign-up.test.tsx`), `web` (marketing site, `app/[locale]/`, i18n), `api` (port 3002, Stripe webhooks, `__tests__/health.test.ts`), `email` (react-email preview of `packages/email/templates`), `docs` (Mintlify), `storybook`, `studio` (Prisma Studio).
- Packages (`NF:packages/`), one per concern, each with a `keys.ts` env schema (16 of them): `ai`, `analytics` (PostHog, Vercel Analytics), `auth` (Clerk: `server.ts` re-exports `@clerk/nextjs/server`, `proxy.ts` the middleware), `cms` (BaseHub), `collaboration` (Liveblocks), `database` (Prisma, `prisma/schema.prisma` stub model `Page`, `index.ts:4,13` Neon serverless adapter), `design-system` (shadcn/ui, `components/ui/*.tsx`, ~50 components), `email` (Resend, `index.ts`), `feature-flags` (Vercel flags), `internationalization` (next-international style dictionaries `dictionaries/{en,fr,de,es,pt,zh}.json`, `languine.json`), `next-config`, `notifications` (Knock), `observability` (Sentry + BetterStack `@logtail/next`), `payments` (Stripe), `rate-limit` (Upstash Redis), `security` (Arcjet, Nosecone), `seo`, `storage` (`index.ts` = `export * from "@vercel/blob"`), `typescript-config`, `webhooks` (Svix).
- Multi-tenancy: Clerk organisations only — `orgId` from `auth()` in `NF:apps/app/app/api/collaboration/auth/route.ts:26` and `NF:apps/app/app/actions/users/search.ts:33`; nothing in the database.
- Deployment: `vercel.json` per app (`NF:apps/app/vercel.json`); a Docker guide exists (`NF:docs/content/docs/deployment/docker.mdx`) requiring `output: "standalone"` in `packages/next-config/index.ts` — not enabled by default.
- Upstream swap guides: `NF:docs/content/docs/migrations/authentication/better-auth.mdx`, `.../database/*` (drizzle, prisma-postgres…), `.../storage/*` (no S3/Garage guide), `.../payments/{lemon-squeezy,paddle}.mdx`.
- Package generator: `NF:turbo/generators/config.ts` (`turbo gen init` creates `packages/<name>/package.json` + `tsconfig.json`).
- No E2E tooling (no Playwright/Cypress in any `package.json`). No jobs package. No authorization package.
- CI: only `NF:.github/workflows/release.yml`.
- Local tools: `bun` is installed (`~/.bun/bin/bun`), pnpm is not.

## Gaps against ADR-0020 (raw material for the profile)
| Capability | next-forge brick | ADR-0020 default | Gap |
| --- | --- | --- | --- |
| Database | Prisma on Neon serverless adapter | self-hosted PostgreSQL | adapter to swap (`@prisma/adapter-pg`), Prisma kept (ADR-0010) |
| Auth | Clerk | Better Auth | package `auth` to rewrite; upstream guide exists |
| Authorization | none | app policies | to write |
| Multi-tenancy | Clerk organisations | orgs in DB, filter at repository | to write, tied to auth swap |
| Files | Vercel Blob | S3 on Garage | package `storage` to rewrite |
| Jobs | none | pg-boss | to add as a package |
| Email | Resend | SMTP | package `email` sender to swap |
| Payment | Stripe | Stripe (managed offer only) | none; excluded from self-hosted edition |
| Cache and rate limiting | Upstash | Postgres / Valkey | package `rate-limit` to rewrite |
| Observability | Sentry + BetterStack | OpenTelemetry collector | package `observability` to rewrite |
| i18n | dictionaries in `internationalization` | framework library | aligned |
| Deployment | Vercel | container image | standalone output + Dockerfile to write |

## Traps
- `tests/lint.test.sh` runs the lint on the real tree: the new profile is checked by every future run.
- `tests/distribution-wiring.test.sh:85` forbids the README from naming `boilerplates/`; the story does not touch the README, keep it that way.
- `tests/overlap.test.sh` covers `method/` only; the profile lives outside it.
- Capabilities outside ADR-0020's twelve (analytics, CMS, flags, collaboration, notifications, security, webhooks, AI, SEO) cannot be table rows (lint rejects them, `bin/po-lint:246-250`): they go in the code map or notes.
- Copying next-forge text is forbidden by the story note: describe in our own words.
- The capability table must keep the template's order (`docs/catalogue.md` says "dans le même ordre"), even though the lint only checks names.
- No migration.

## Open questions
1. `Test` value: `bun run test` (runs everything through turbo, no paths) vs. a per-app vitest command that takes paths. The template requires paths.
2. `Typecheck` value: no root task exists; `bun run --filter '*' typecheck`, or `—` plus a trap?
3. How the grounded test verifies without committing a clone: `NEXT_FORGE_SRC` env pointing to a checkout, else clone into `mktemp -d`, fetch the recorded commit, skip with a message when offline (overlap precedent)?
4. What "every path cited" means mechanically: every backticked token that looks like a repository path?
5. Language of the profile: the template is English; method files are English — keep English.

## Complexity
Story: 3 → research: 3. The profile is prose, but the grounded test (network, commit pinning, path extraction) carries the risk the story names.
