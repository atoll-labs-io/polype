# Profile — next-forge

## Identity and licence

- Name: next-forge
- Origin: https://github.com/vercel/next-forge
- Licence: MIT
- Commit profiled: f189de79ceef7c1ef69f61f12e272f99b4cdb699

Package version 6.0.2, commit dated 2026-05-28. A Bun and Turborepo monorepo of Next.js applications sharing one package per concern.

## Platform

- Platform: web

## QA driver

- QA driver: browser

## Commands

```
Install:           bun install
Test:              bun run test
Typecheck:         —
E2E:               —
Build:             bun run build
Dev:               bun run dev
```

`Test` runs the tests of every workspace through Turbo and does **not** accept paths, unlike what the template asks: to run a single file, go into `apps/app/` or `apps/api/`, the only two workspaces with tests, and run `bunx vitest run <file>` there. `Typecheck` is `—` because neither the root `package.json` nor `turbo.json` defines a type-check task; each workspace carries its own `typecheck` script instead. There is no end-to-end tooling at all. `bun run dev` runs `turbo dev`, every app at once, the product (`apps/app/`) on port 3000. Two other root scripts matter to a project: `bun run check` (Biome, driven by Ultracite) for lint and format, and `bun run migrate` for Prisma migrations in `packages/database/`.

## Code map

- `apps/app/` — the product itself: the signed-in SaaS on port 3000, its pages under `apps/app/app/`, server actions under `apps/app/app/actions/`, tests under `apps/app/__tests__/`.
- `apps/web/` — the public marketing site, translated, with pages under `apps/web/app/[locale]/`.
- `apps/api/` — a separate Next.js server on port 3002 for webhooks and scheduled calls, tested under `apps/api/__tests__/`.
- `apps/email/` — a local preview of the email templates kept in `packages/email/`.
- `apps/docs/` — the documentation site of the product.
- `apps/storybook/` — Storybook for the shared components.
- `apps/studio/` — Prisma Studio, to browse the database locally.
- `packages/` — shared code, one workspace per concern, imported by the apps as `@repo/<name>`. Most of them validate their environment in a `keys.ts` file.
- `packages/auth/` — sign-in, sessions and the request middleware, on Clerk.
- `packages/database/` — the Prisma schema, its migrations and the shared client.
- `packages/design-system/` — the component library and theme used by every app.
- `packages/email/` — email templates and the sending client.
- `packages/internationalization/` — translation dictionaries and locale detection.
- `packages/observability/` — error reporting, logging and the status widget.
- `packages/payments/` — the billing client.
- `packages/rate-limit/` — request throttling.
- `packages/storage/` — file upload and storage.
- `packages/next-config/` — the Next.js configuration every app extends.
- `packages/typescript-config/` — the TypeScript presets every workspace extends.

## Ownership granularity

The code is split as one package per capability, so a story may own one `packages/<name>/` alone, or one route group of an app such as `apps/app/app/(authenticated)/<feature>/`. Some paths are read by every workspace, and a story touching any of them must run alone: `packages/design-system/`, `packages/next-config/`, `packages/typescript-config/`, the root `package.json`, `bun.lock`, `turbo.json`, `apps/app/proxy.ts`, and `packages/database/prisma/schema.prisma`, the single schema file that holds every model.

## Where each rule lives

- Access: the Clerk middleware defined in `packages/auth/proxy.ts` and mounted by `apps/app/proxy.ts`; pages outside `apps/app/app/(authenticated)/` are public.
- Tenant filter: the organisation id Clerk returns with the session, read in each action as in `apps/app/app/actions/users/search.ts`; no query of the database filters by tenant.
- Validation: environment variables are checked by the zod schema of each package's `keys.ts`; input validation has no dedicated home and is written inside each action.
- Business rules: server actions under `apps/app/app/actions/`.
- Data model: `packages/database/prisma/schema.prisma`.

## Capabilities

| Capability | Brick | Notes |
| --- | --- | --- |
| Database | PostgreSQL through Prisma, Neon serverless adapter | client in `packages/database/index.ts`, schema in `packages/database/prisma/schema.prisma` |
| Auth | Clerk | `packages/auth/` |
| Multi-tenancy | Clerk organisations | organisation id taken from the session, e.g. `apps/app/app/actions/users/search.ts` |
| Files | Vercel Blob | `packages/storage/` re-exports the Blob SDK |
| Email | Resend, React Email templates | `packages/email/` |
| Payment | Stripe | `packages/payments/`, webhooks received by `apps/api/` |
| Cache and rate limiting | Upstash Redis | `packages/rate-limit/` |
| Observability | Sentry and BetterStack | `packages/observability/` |
| i18n | JSON dictionaries per locale | `packages/internationalization/`, used by `apps/web/` |
| Deployment | Vercel | one config per app, e.g. `apps/app/vercel.json` |

Gaps against the default bricks (ADR-0020):

- Database — Neon serverless adapter instead of self-hosted PostgreSQL: replace the adapter in `packages/database/index.ts` with the plain Postgres one and keep Prisma.
- Auth — Clerk instead of Better Auth: rewrite `packages/auth/`; next-forge ships a migration guide at `docs/content/docs/migrations/authentication/better-auth.mdx`.
- Multi-tenancy — Clerk organisations instead of organisations stored in the database: write the organisation models and a tenant filter in each repository, together with the auth swap.
- Authorization — absent instead of application policies: write the policies and their access matrix.
- Files — Vercel Blob instead of S3 on Garage: rewrite `packages/storage/` against the S3 API.
- Jobs — absent instead of pg-boss: add a new package that runs the queue inside PostgreSQL.
- Email — Resend instead of SMTP: replace the sender in `packages/email/` with an SMTP transport, keeping the templates.
- Cache and rate limiting — Upstash instead of Postgres or Valkey: rewrite `packages/rate-limit/`.
- Observability — Sentry and BetterStack instead of OpenTelemetry: rewrite `packages/observability/` to export to a collector.
- Deployment — Vercel instead of a container image: turn on standalone output in `packages/next-config/` and write a Dockerfile, following `docs/content/docs/deployment/docker.mdx`.

Payment (Stripe) and i18n already match the defaults; Payment is left out of the self-hosted edition. The other packages — analytics, CMS, feature flags, collaboration, notifications, security, webhooks, AI and SEO — cover no capability of the list and may be deleted by a project that does not need them.

## UI inventory

- `packages/design-system/components/ui/` — shadcn/ui components, among them accordion, alert-dialog, avatar, badge, button, card, dialog, dropdown-menu, form, input, select, sheet, sidebar, table, tabs, textarea and tooltip.
- `packages/design-system/components/mode-toggle.tsx` — the light and dark theme switch.
- `apps/storybook/stories/` — one story per shared component, to browse them before drawing a new one.
- `packages/email/templates/` — the React Email templates, previewed by `apps/email/`.

## Known traps

- The package manager is Bun, not pnpm or npm: `bun.lock` is the lockfile and scripts run with `bun run`.
- `bun run test` takes no path; a focused run happens inside the app with `bunx vitest run <file>`.
- No root type check exists; run the `typecheck` script of the workspace you changed.
- `turbo build` depends on `test`, so a failing test also fails the build.
- The Prisma client is generated into a `generated` folder next to the `prisma` folder of the database package: it is missing from a fresh clone, must never be edited, and is rebuilt by `bun run build` or `bun run migrate`.
- Each app and several packages ship a `.env.example` to copy before the first start.
- Every package checks its environment through its `keys.ts`, so a missing key stops the app at start rather than at the first call.
- A new package is created with `turbo gen init`, which writes its `package.json` and `tsconfig.json`.
- `packages/database/prisma/schema.prisma` is shared by every feature: two stories adding models conflict on it.
